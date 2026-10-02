class_name ChestOpening
extends Control
## The chest ceremony: the chest drops in, rattles as light leaks from the seams, the lid bursts
## open in a fountain of sparks, then each reward flies out and flips over. Legendary loot gets
## its own beam of light, a screen flash and a LEGENDARY call-out.
var game: Node
var reveal: Dictionary = {}
var on_done: Callable
var medal := "Gold"
var chest: Control
var lid: Control
var glow: FlowUI.Aura
var cards: Array = []
var opened := false

const MEDAL := {"Gold": "ffd36e", "Silver": "dfe8f0", "Bronze": "d9935a"}

class ChestBody extends Control:
	var band := Color("ffd36e")
	var lid := false
	func _draw() -> void:
		var w = size.x; var h = size.y
		var wood = Color("5a3418"); var dark = Color("2e1a0c")
		if lid:
			# Domed lid
			var pts = PackedVector2Array([Vector2(0, h)])
			for i in range(13):
				var a = PI + PI * i / 12.0
				pts.append(Vector2(w * 0.5 + cos(a) * w * 0.5, h + sin(a) * h))
			pts.append(Vector2(w, h))
			draw_colored_polygon(pts, wood)
			draw_polyline(pts, dark, 4, true)
			for x in [0.18, 0.5, 0.82]:
				draw_line(Vector2(w * x, h), Vector2(w * x, h - h * sin(acos(clampf((x - 0.5) * 2.0, -1, 1)))), band, 10, true)
		else:
			draw_rect(Rect2(0, 0, w, h), wood); draw_rect(Rect2(0, 0, w, h), dark, false, 4)
			for i in range(1, 4): draw_line(Vector2(0, h * i / 4.0), Vector2(w, h * i / 4.0), Color(dark, 0.5), 2)
			for x in [0.18, 0.5, 0.82]: draw_rect(Rect2(w * x - 6, 0, 12, h), band)
			draw_rect(Rect2(0, 0, w, 10), band)
			# Lock
			draw_rect(Rect2(w * 0.5 - 18, 6, 36, 40), band.darkened(0.2)); draw_circle(Vector2(w * 0.5, 24), 6, dark)

func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); mouse_filter = Control.MOUSE_FILTER_STOP
	medal = str(reveal.get("medal", "Gold")); var col = Color(MEDAL.get(medal, "ffd36e"))
	var shade = ColorRect.new(); shade.color = Color(0.01, 0.01, 0.03, 0.9); add_child(shade); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title = game.label(self, "%s CHEST" % medal.to_upper(), 44, col, false); title.position = Vector2(0, 120); title.size = Vector2(1600, 60); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(game.TITLE_FONT)); title.add_theme_color_override("font_outline_color", Color(0, 0, 0)); title.add_theme_constant_override("outline_size", 8)
	var sub = game.label(self, str(reveal.get("location", "")), 18, Color.WHITE, false); sub.position = Vector2(0, 178); sub.size = Vector2(1600, 30); sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glow = FlowUI.Aura.new(); glow.color = col; glow.strength = 0.0; glow.size = Vector2(700, 700); glow.position = Vector2(450, 160); add_child(glow)
	chest = Control.new(); chest.size = Vector2(260, 260); chest.position = Vector2(670, -300); chest.pivot_offset = Vector2(130, 200); add_child(chest)
	var body = ChestBody.new(); body.band = col; body.size = Vector2(260, 150); body.position = Vector2(0, 110); chest.add_child(body)
	lid = ChestBody.new(); lid.band = col; lid.lid = true; lid.size = Vector2(260, 80); lid.position = Vector2(0, 30); lid.pivot_offset = Vector2(0, 80); chest.add_child(lid)
	var hint = game.label(self, "Click to open", 18, Color(1, 1, 1, 0.6), false); hint.position = Vector2(0, 700); hint.size = Vector2(1600, 30); hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var t = create_tween()
	t.tween_property(chest, "position:y", 260.0, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): game.sound.cue("contest_lock"))
	t.tween_interval(0.6)
	t.tween_callback(open_chest)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and not opened: open_chest()

func open_chest() -> void:
	if opened: return
	opened = true
	var t = create_tween()
	# Rattle while the glow builds.
	for i in range(10):
		var k = 1.0 + i * 0.25
		t.tween_property(chest, "rotation", 0.05 * k * (1 if i % 2 == 0 else -1), 0.06)
		t.parallel().tween_property(glow, "strength", 0.08 * i, 0.06)
	t.tween_property(chest, "rotation", 0.0, 0.05)
	t.tween_callback(func():
		game.sound.cue("upgrade", true)
		var lt = create_tween(); lt.tween_property(lid, "rotation", -1.25, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		lt.parallel().tween_property(lid, "position:y", -10.0, 0.25)
		glow.strength = 1.4
		burst(Vector2(800, 380), Color(MEDAL.get(medal, "ffd36e")), 90)
		var flash = ColorRect.new(); flash.color = Color(1, 0.95, 0.8, 0.7); add_child(flash); flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ft = create_tween(); ft.tween_property(flash, "color:a", 0.0, 0.5); ft.tween_callback(flash.queue_free))
	t.tween_interval(0.35)
	t.tween_callback(deal_cards)

func burst(at: Vector2, col: Color, amount: int) -> void:
	var p = CPUParticles2D.new(); add_child(p); p.position = at; p.amount = amount; p.one_shot = true; p.explosiveness = 0.95; p.lifetime = 1.4
	p.direction = Vector2(0, -1); p.spread = 70; p.initial_velocity_min = 280; p.initial_velocity_max = 620; p.gravity = Vector2(0, 700)
	p.scale_amount_min = 3; p.scale_amount_max = 7; p.color = col; p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)

func deal_cards() -> void:
	var rewards: Array = reveal.get("rewards", [])
	var n = rewards.size(); var w = 210.0; var gap = 18.0
	var x0 = 800 - (n * w + (n - 1) * gap) * 0.5
	var t = create_tween()
	var any_legend = false
	for i in range(n):
		var rw = rewards[i]; var legend = false
		if rw.get("kind", "") == "item":
			legend = Forge.ITEMS.get(str(rw.item), {}).get("wild", false)
		if rw.has("species"): legend = true
		any_legend = any_legend or legend
		var card = PanelContainer.new(); add_child(card); card.size = Vector2(w, 300); card.position = Vector2(695, 340); card.pivot_offset = Vector2(w * 0.5, 150); card.scale = Vector2(0.2, 0.2); card.modulate.a = 0
		var edge = Color("ff9be0") if legend else (Color("ffd36e") if rw.get("kind", "") == "gold" else Color("9fd4c6"))
		card.add_theme_stylebox_override("panel", game.style(Color(0.06, 0.05, 0.1, 0.97), edge, 10, 12, 4 if legend else 2))
		var box = VBoxContainer.new(); box.alignment = BoxContainer.ALIGNMENT_CENTER; box.add_theme_constant_override("separation", 8); card.add_child(box)
		var art = CenterContainer.new(); art.custom_minimum_size = Vector2(0, 140); box.add_child(art)
		if legend: FlowUI.aura(art, Color("ffd36e"), Vector2(200, 200), 1.2)
		if rw.get("kind", "") == "item": GearUI.token(game, art, Forge.info(str(rw.item)), 120)
		elif rw.has("species"): HeadlinerUI.portrait(art, {"sp": rw.species}, 130)
		else: FlowUI.glyph(art, "coin", 90)
		if legend:
			var ll = game.label(box, "★ LEGENDARY ★", 18, Color("ffd36e"), false); ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var pulse = ll.create_tween().set_loops(); pulse.tween_property(ll, "modulate", Color(1.4, 1.2, 0.8), 0.4); pulse.tween_property(ll, "modulate", Color.WHITE, 0.4)
		var nm = game.label(box, str(rw.title), 20, edge, true); nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var d = game.label(box, str(rw.get("detail", "")), 12, Color("c9d6dc"), true); d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; d.max_lines_visible = 3
		card.tooltip_text = str(rw.title) + "\n" + str(rw.get("detail", ""))
		var target = Vector2(x0 + i * (w + gap), 430)
		var delay = 0.0 if i == 0 else 0.35
		t.tween_callback(func(): game.sound.play_sample("contest_reveal", -10, 2, 0.0, 1.0 + i * 0.07)).set_delay(delay)
		t.tween_property(card, "modulate:a", 1.0, 0.1)
		t.parallel().tween_property(card, "position", target, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.parallel().tween_property(card, "scale", Vector2(0.05, 1.0), 0.25)
		t.tween_property(card, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK)
		if legend:
			t.tween_callback(func():
				burst(target + Vector2(w * 0.5, 120), Color("ff9be0"), 60); burst(target + Vector2(w * 0.5, 120), Color("ffd36e"), 60)
				game.sound.cue("victory", true)
				FlowUI.banner(game, "LEGENDARY!", Color("ffd36e"), str(rw.title)))
			t.tween_interval(0.5)
		cards.append(card)
	t.tween_interval(0.3)
	t.tween_callback(func():
		var holder = HBoxContainer.new(); add_child(holder); holder.position = Vector2(600, 780); holder.size = Vector2(400, 64); holder.alignment = BoxContainer.ALIGNMENT_CENTER
		FlowUI.cta(game, holder, "Collect  ▶", collect, false, 400))

func collect() -> void:
	queue_free()
	if on_done.is_valid(): on_done.call()

static func play(game_node: Node, reveal_data: Dictionary, then: Callable) -> void:
	var v = ChestOpening.new(); v.game = game_node; v.reveal = reveal_data; v.on_done = then
	game_node.ui.add_child(v); v.build()
