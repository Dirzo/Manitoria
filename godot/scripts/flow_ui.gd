class_name FlowUI
extends RefCounted
## Less reading, more playing: icon + number chips for the run, one big call to action per
## screen, and short banners that announce each step of the loop (Shop → Fight → Result).

## A tiny procedurally drawn icon so the HUD needs no emoji font.
class Glyph extends Control:
	var kind := "coin"
	var on := true
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var s = minf(size.x, size.y); var c = size * 0.5
		match kind:
			"coin":
				draw_circle(c + Vector2(0, s * 0.04), s * 0.44, Color("6b4a12"))
				draw_circle(c, s * 0.44, Color("f3c34a")); draw_circle(c, s * 0.30, Color("ffdf7e"))
				draw_arc(c, s * 0.30, 0, TAU, 24, Color("c8952a"), maxf(1.0, s * 0.06), true)
			"heart":
				var pts = PackedVector2Array()
				for i in range(40):
					var t = TAU * i / 40.0
					pts.append(c + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * s * 0.027)
				draw_colored_polygon(pts, Color("ff5a6a") if on else Color(1, 1, 1, 0.14))
				var line = pts.duplicate(); line.append(pts[0])
				draw_polyline(line, Color("5a0e18") if on else Color(1, 1, 1, 0.35), maxf(1.0, s * 0.06), true)
			"trophy":
				var gold = Color("ffd36e")
				draw_rect(Rect2(c.x - s * 0.26, c.y - s * 0.40, s * 0.52, s * 0.36), gold)
				draw_circle(c + Vector2(0, -s * 0.06), s * 0.26, gold)
				draw_arc(c + Vector2(-s * 0.30, -s * 0.18), s * 0.12, PI * 0.5, PI * 1.5, 10, gold, s * 0.07)
				draw_arc(c + Vector2(s * 0.30, -s * 0.18), s * 0.12, -PI * 0.5, PI * 0.5, 10, gold, s * 0.07)
				draw_rect(Rect2(c.x - s * 0.06, c.y + s * 0.16, s * 0.12, s * 0.14), gold)
				draw_rect(Rect2(c.x - s * 0.24, c.y + s * 0.30, s * 0.48, s * 0.10), gold)
			"swords":
				for d in [-1.0, 1.0]:
					var a = c + Vector2(-d * s * 0.36, s * 0.36); var b = c + Vector2(d * s * 0.36, -s * 0.36)
					draw_line(a, b, Color("dfe6ee"), maxf(2.0, s * 0.11), true)
					var g = a.lerp(b, 0.24); var n = (b - a).normalized().orthogonal() * s * 0.16
					draw_line(g - n, g + n, Color("ffd36e"), maxf(2.0, s * 0.09), true)
			"roll":
				draw_arc(c, s * 0.32, 0.4, TAU - 0.4, 24, Color("c8ff9d"), maxf(2.0, s * 0.11), true)
				var tip = c + Vector2(cos(0.4), sin(0.4)) * s * 0.32
				draw_colored_polygon(PackedVector2Array([tip + Vector2(-s * 0.16, -s * 0.02), tip + Vector2(s * 0.14, -s * 0.04), tip + Vector2(0, s * 0.18)]), Color("c8ff9d"))

static func glyph(parent: Node, kind: String, px: float, on := true) -> Glyph:
	var g = Glyph.new(); g.kind = kind; g.on = on; g.custom_minimum_size = Vector2(px, px)
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER; parent.add_child(g); return g

## Icon + big number, like an auto-battler run bar.
static func chip(game: Node, parent: Node, kind: String, value: String, tip: String, color := Color.WHITE) -> HBoxContainer:
	var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 5); parent.add_child(row)
	row.mouse_filter = Control.MOUSE_FILTER_STOP; row.tooltip_text = tip
	glyph(row, kind, 24)
	var l = game.label(row, value, 21, color, false); l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85)); l.add_theme_constant_override("outline_size", 5)
	return row

## Gold · lives this cup · trophies · cup number.
static func run_bar(game: Node, parent: Node) -> void:
	var c: Campaign = game.campaign
	var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 16); parent.add_child(row)
	chip(game, row, "coin", str(int(c.state.gold)), "Gold", Color("ffdf7e"))
	if c.state.has("tour") and not c.state.roster.is_empty():
		var lost = WorldTour.losses(c, 0)
		var hearts = HBoxContainer.new(); hearts.add_theme_constant_override("separation", 2); row.add_child(hearts)
		hearts.mouse_filter = Control.MOUSE_FILTER_STOP
		hearts.tooltip_text = "Lives this cup: lose twice and you're out of the bracket.\nRecord %d W · %d L" % [int(c.state.tour.get("wins", 0)), lost]
		for i in range(2): glyph(hearts, "heart", 24, i >= lost)
	chip(game, row, "trophy", str(int(c.state.get("trophies", 0))), "Cups won", Color("ffd36e"))

## The one obvious next step. Big, green, gently pulsing.
static func cta(game: Node, parent: Node, text: String, callback: Callable, disabled := false, width := 360.0) -> Button:
	var b = game.button(parent, text, callback, true, disabled)
	b.custom_minimum_size = Vector2(width, 58); b.add_theme_font_size_override("font_size", 26)
	b.add_theme_stylebox_override("normal", game.style(Color("2b8a57"), Color("ffe7a6"), 6, 14, 3))
	b.add_theme_stylebox_override("hover", game.style(Color("36a86a"), Color("fff3cf"), 6, 14, 3))
	b.add_theme_stylebox_override("pressed", game.style(Color("1f6b43"), Color("ffe7a6"), 6, 14, 3))
	if not disabled:
		var t = b.create_tween().set_loops(); t.set_trans(Tween.TRANS_SINE)
		t.tween_property(b, "modulate", Color(1.14, 1.14, 1.06), 0.9); t.tween_property(b, "modulate", Color.WHITE, 0.9)
	return b

## A sweeping centre banner (SHOP, VICTORY…). Purely decorative; never blocks input.
static func banner(game: Node, text: String, color := Color("ffe9b8"), sub := "") -> void:
	var holder = Control.new(); holder.mouse_filter = Control.MOUSE_FILTER_IGNORE; holder.z_index = 50
	game.ui.add_child(holder); holder.position = Vector2(0, 360); holder.size = Vector2(1600, 170)
	var band = ColorRect.new(); band.mouse_filter = Control.MOUSE_FILTER_IGNORE; band.color = Color(0.02, 0.02, 0.05, 0.72); holder.add_child(band)
	band.position = Vector2(0, 22); band.size = Vector2(1600, 126)
	var l = game.label(holder, text, 78, color, false); l.position = Vector2(0, 14); l.size = Vector2(1600, 110)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", load(game.TITLE_FONT))
	l.add_theme_color_override("font_outline_color", Color("1a0f14")); l.add_theme_constant_override("outline_size", 12)
	if sub != "":
		var s = game.label(holder, sub, 22, Color.WHITE, false); s.position = Vector2(0, 112); s.size = Vector2(1600, 30)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.modulate.a = 0.0; holder.scale = Vector2(1, 0.6); holder.pivot_offset = Vector2(800, 85)
	var t = holder.create_tween(); t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(holder, "modulate:a", 1.0, 0.18); t.parallel().tween_property(holder, "scale", Vector2.ONE, 0.32)
	t.tween_interval(0.9); t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(holder, "modulate:a", 0.0, 0.35); t.tween_callback(holder.queue_free)

## A styled yes/no popup. on_yes runs only if the player confirms.
static func confirm(game: Node, title: String, body: String, yes_text: String, on_yes: Callable, no_text := "Cancel") -> void:
	var dialog = GearUI.modal(game, title, Vector2(720, 330))
	var l = game.label(dialog.box, body, 20, game.WHITE, true); l.custom_minimum_size.x = 660
	var spacer = Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL; dialog.box.add_child(spacer)
	var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 14); row.alignment = BoxContainer.ALIGNMENT_END; dialog.box.add_child(row)
	game.button(row, no_text, func(): dialog.root.queue_free()).custom_minimum_size = Vector2(170, 52)
	var yes = game.button(row, yes_text, func(): dialog.root.queue_free(); on_yes.call(), true); yes.custom_minimum_size = Vector2(240, 52)

## Quick read of the last fight: result, damage race, carry, threat, and what to buy about it.
static func fight_insights(c: Campaign) -> Dictionary:
	var rep = c.state.get("report", {})
	if rep.is_empty() or not rep.has("rows"): return {}
	var ours = rep.rows.filter(func(r): return r.team == 0); var theirs = rep.rows.filter(func(r): return r.team == 1)
	var sum = func(rows, k): return rows.reduce(func(a, r): return a + float(r.get(k, 0)), 0.0)
	var dmg0 = sum.call(ours, "damage"); var dmg1 = sum.call(theirs, "damage")
	var heal0 = sum.call(ours, "healing"); var heal1 = sum.call(theirs, "healing")
	var deaths = ours.filter(func(r): return not r.alive).size()
	var carry = {}; var threat = {}
	for r in ours:
		if carry.is_empty() or r.damage > carry.damage: carry = r
	for r in theirs:
		if threat.is_empty() or r.damage > threat.damage: threat = r
	var tips = []
	if heal1 > maxf(heal0 * 1.5, dmg0 * 0.15): tips.append("They out-healed you (%d vs %d). Burst them: Sharpened Fang, Storm Glass, Ember Shard." % [heal1, heal0])
	if deaths >= 3: tips.append("%d of yours fell. Toughen up: Troll Hide, Bronze Plate, Holy Relic." % deaths)
	if not threat.is_empty() and dmg1 > 0 and threat.damage / dmg1 > 0.33: tips.append("%s did %d%% of their damage. Set Tactics → target their carry." % [threat.name, roundi(threat.damage / dmg1 * 100)])
	if not carry.is_empty() and dmg0 > 0 and carry.damage / dmg0 > 0.35: tips.append("%s carried (%d%% of your damage). Stack items on it." % [carry.name, roundi(carry.damage / dmg0 * 100)])
	if float(rep.get("duration", 0)) > 60: tips.append("Long fight (%ds): late scalers and healers shine." % int(rep.duration))
	if tips.is_empty(): tips.append("Even fight. Forge a finished item on your top damage dealer.")
	return {"won": rep.winner == 0, "opponent": rep.get("opponent", ""), "dmg0": dmg0, "dmg1": dmg1, "heal0": heal0, "heal1": heal1, "deaths": deaths, "carry": carry, "threat": threat, "tips": tips}

static func fight_summary(game: Node, parent: Node) -> void:
	var f = fight_insights(game.campaign)
	if f.is_empty(): return
	var panel = PanelContainer.new(); parent.add_child(panel); panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", game.style(Color(.04, .06, .09, .92), Color("ffd36e") if f.won else Color("ff8a7a"), 6, 6, 1))
	var box = VBoxContainer.new(); box.add_theme_constant_override("separation", 0); panel.add_child(box)
	var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 14); box.add_child(row)
	game.label(row, ("WON" if f.won else "LOST") + " vs " + str(f.opponent), 15, Color("ffd36e") if f.won else Color("ff8a7a"), false)
	var total = maxf(1.0, f.dmg0 + f.dmg1)
	var bar = ProgressBar.new(); bar.max_value = 1.0; bar.value = f.dmg0 / total; bar.show_percentage = false; bar.custom_minimum_size = Vector2(150, 10); bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER; row.add_child(bar)
	bar.add_theme_stylebox_override("background", game.style(Color("c0574a"), Color.TRANSPARENT, 4, 0, 0)); bar.add_theme_stylebox_override("fill", game.style(Color("5fb7d9"), Color.TRANSPARENT, 4, 0, 0))
	bar.tooltip_text = "Damage race: you %d · them %d" % [f.dmg0, f.dmg1]
	game.label(row, "%dk vs %dk dmg" % [roundi(f.dmg0 / 1000.0), roundi(f.dmg1 / 1000.0)], 13, game.WHITE, false)
	if not f.carry.is_empty(): game.label(row, "★ " + str(f.carry.name), 13, game.GOLD, false).tooltip_text = "Your top damage"
	var tip = game.label(box, "→ " + f.tips[0], 13, Color("c8ff9d"), false); tip.clip_text = true; tip.custom_minimum_size.x = 640
	panel.tooltip_text = "LAST FIGHT\n" + "\n".join(f.tips.map(func(t): return "• " + t))
