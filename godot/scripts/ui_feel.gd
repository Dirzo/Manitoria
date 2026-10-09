class_name UIFeel
extends Node
## Game-wide interface feel, in the spirit of Baldur's Gate 3 and Guildrun:
## * every button breathes on hover (lift + glow + a soft tick) and gives on press (squash + click);
## * tooltips become floating text boxes: a framed card that eases in beside the cursor, with a gold
##   title line, highlighted numbers and coloured status keywords, kept on screen and above dialogs;
## * dialogs float in (fade + settle) instead of snapping open.
## Native tooltips are switched off in project.godot (gui/timers/tooltip_delay_sec), so every
## Control's tooltip_text — including dynamic _get_tooltip() text — is shown here instead.

const GOLD := Color("e3c589")
const PARCH := Color("f1e6cc")
const MUTE := Color("b9ad98")
const SHOW_DELAY := 0.32
const MAX_W := 400.0

var game: Node
var layer: CanvasLayer
var tip: PanelContainer
var tip_text: RichTextLabel
var hovered: Control
var hover_time := 0.0
var shown_for: Control
var shown_text := ""
var last_tick := 0
static var enabled := true

static func attach(game_node: Node) -> UIFeel:
	var f = UIFeel.new(); f.game = game_node; f.name = "UIFeel"; game_node.add_child(f)
	return f

func _ready() -> void:
	layer = CanvasLayer.new(); layer.layer = 100; add_child(layer)
	tip = PanelContainer.new(); layer.add_child(tip); tip.visible = false; tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb = StyleBoxFlat.new(); sb.bg_color = Color(0.045, 0.036, 0.05, 0.96); sb.border_color = Color(GOLD, 0.75)
	sb.set_border_width_all(1); sb.set_corner_radius_all(9); sb.anti_aliasing = true
	sb.shadow_color = Color(0, 0, 0, 0.6); sb.shadow_size = 22; sb.shadow_offset = Vector2(0, 10)
	sb.content_margin_left = 16; sb.content_margin_right = 16; sb.content_margin_top = 12; sb.content_margin_bottom = 13
	tip.add_theme_stylebox_override("panel", sb)
	var box = VBoxContainer.new(); box.add_theme_constant_override("separation", 0); box.mouse_filter = Control.MOUSE_FILTER_IGNORE; tip.add_child(box)
	# A thin gold rule across the top edge: the "floating card" signature.
	var rule = ColorRect.new(); rule.color = Color(GOLD, 0.0); rule.custom_minimum_size = Vector2(0, 0); box.add_child(rule)
	tip_text = RichTextLabel.new(); tip_text.bbcode_enabled = true; tip_text.fit_content = true; tip_text.scroll_active = false
	tip_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; tip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_text.custom_minimum_size = Vector2(0, 0)
	tip_text.add_theme_color_override("default_color", PARCH)
	tip_text.add_theme_font_size_override("normal_font_size", 15); tip_text.add_theme_font_size_override("bold_font_size", 18)
	if ResourceLoader.exists("res://assets/fonts/ebgaramond.ttf"):
		var body = FontVariation.new(); body.base_font = load("res://assets/fonts/ebgaramond.ttf"); body.variation_opentype = {"wght": 520}
		var bold = FontVariation.new(); bold.base_font = load("res://assets/fonts/ebgaramond.ttf"); bold.variation_opentype = {"wght": 720}
		tip_text.add_theme_font_override("normal_font", body); tip_text.add_theme_font_override("bold_font", bold)
	box.add_child(tip_text)
	get_tree().node_added.connect(_on_node_added)

# ------------------------------------------------------------------ buttons
func _on_node_added(n: Node) -> void:
	if n is BaseButton and not n.has_meta("ui_feel"):
		n.set_meta("ui_feel", true)
		n.ready.connect(func(): _setup(n), CONNECT_ONE_SHOT)

func _amp(b: Control) -> float:
	if b.has_meta("feel_amp"): return float(b.get_meta("feel_amp"))
	if b is HudKit.Medallion: return 0.08
	var w = maxf(b.size.x, b.custom_minimum_size.x)
	return 0.045 if w < 200 else (0.03 if w < 380 else 0.015)

func _setup(b: BaseButton) -> void:
	if not is_instance_valid(b) or b.has_meta("no_feel"): return
	if b.mouse_default_cursor_shape == Control.CURSOR_ARROW: b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var center = func(): b.pivot_offset = b.size * 0.5
	center.call(); b.resized.connect(center)
	b.mouse_entered.connect(func():
		if b.disabled: return
		_to(b, 1.0 + _amp(b), 0.12, Tween.TRANS_BACK)
		_tick("ui_hover", -22.0))
	b.mouse_exited.connect(func(): _to(b, 1.0, 0.14, Tween.TRANS_SINE))
	b.button_down.connect(func():
		if b.disabled: return
		_to(b, 1.0 - _amp(b) * 1.2, 0.06, Tween.TRANS_SINE)
		_tick("ui_click", -15.0, true))
	b.button_up.connect(func(): _to(b, 1.0 + (_amp(b) if b.is_hovered() else 0.0), 0.16, Tween.TRANS_BACK))

func _to(b: Control, s: float, t: float, trans: int) -> void:
	if not is_instance_valid(b) or not b.is_inside_tree(): return
	if b.has_meta("feel_tween"):
		var old = b.get_meta("feel_tween")
		if old is Tween and old.is_valid(): old.kill()
	var tw = b.create_tween().set_trans(trans).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "scale", Vector2(s, s), t)
	b.set_meta("feel_tween", tw)

func _tick(key: String, gain: float, always := false) -> void:
	if game == null or not ("sound" in game) or game.sound == null: return
	var now = Time.get_ticks_msec()
	if not always and now - last_tick < 60: return
	last_tick = now
	game.sound.play_sample(key, gain, 1, 0.0, randf_range(0.97, 1.04))

# ------------------------------------------------------------------ floating text boxes
func _process(dt: float) -> void:
	if not enabled: tip.visible = false; return
	var vp = get_viewport()
	var c: Control = vp.gui_get_hovered_control()
	var text := ""; var owner: Control = null
	var probe = c
	while probe != null and text.is_empty():
		var t = probe.get_tooltip(probe.get_local_mouse_position())
		if not t.strip_edges().is_empty(): text = t; owner = probe
		elif probe.mouse_filter == Control.MOUSE_FILTER_STOP and probe != c: break
		probe = probe.get_parent() as Control
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): text = ""
	if owner != hovered: hovered = owner; hover_time = 0.0
	if text.is_empty():
		_hide(); return
	hover_time += dt
	if hover_time < SHOW_DELAY: return
	if owner != shown_for or text != shown_text: _show(owner, text)
	_place(vp)

func _show(owner: Control, text: String) -> void:
	shown_for = owner; shown_text = text
	tip_text.text = format(text)
	# Width from the plain text's natural line length (RichTextLabel cannot measure before drawing).
	var f: Font = tip_text.get_theme_font("bold_font")
	var widest = 0.0
	for line in text.split("\n"):
		widest = maxf(widest, f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x)
	tip_text.custom_minimum_size.x = clampf(widest + 8.0, 120.0, MAX_W)
	tip.size = Vector2.ZERO
	tip.reset_size.call_deferred()
	if not tip.visible:
		tip.visible = true; tip.modulate.a = 0.0; tip.set_meta("rise", 8.0)
		var tw = tip.create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(tip, "modulate:a", 1.0, 0.14)
		tw.tween_method(func(v): tip.set_meta("rise", v), 8.0, 0.0, 0.18)

func _hide() -> void:
	if tip.visible: tip.visible = false
	shown_for = null; shown_text = ""

func _place(vp: Viewport) -> void:
	var view = vp.get_visible_rect().size
	var m = vp.get_mouse_position()
	var s = tip.size
	var p = m + Vector2(20, 24)
	if p.x + s.x > view.x - 10: p.x = m.x - s.x - 16
	if p.y + s.y > view.y - 10: p.y = m.y - s.y - 14
	p.x = clampf(p.x, 10, maxf(10, view.x - s.x - 10)); p.y = clampf(p.y, 10, maxf(10, view.y - s.y - 10))
	p.y += float(tip.get_meta("rise", 0.0))
	tip.position = tip.position.lerp(p, 0.55) if tip.modulate.a > 0.2 else p

## Plain tooltip text → a floating card: the first short line becomes a gold title, numbers and
## percentages are gilded, combat keywords take their status colour.
static func format(text: String) -> String:
	var t = text.replace("[", "(").replace("]", ")")
	var lines = t.split("\n")
	var out = ""
	var first = lines[0].strip_edges()
	var body_from = 0
	if lines.size() > 1 and first.length() <= 64:
		out = "[b][color=#e3c589]%s[/color][/b]\n" % first
		body_from = 1
	elif lines.size() == 1 and first.length() <= 40:
		return "[b][color=#e3c589]%s[/color][/b]" % first
	var body = "\n".join(lines.slice(body_from)).strip_edges()
	var rx = RegEx.new(); rx.compile("([+\\-−]?\\d+(?:[.,]\\d+)?(?:%|s\\b|x\\b)?)")
	body = rx.sub(body, "[color=#ffd98a]$1[/color]", true)
	for pair in [["stun", "ffb35c"], ["stuns", "ffb35c"], ["root", "8fdc6a"], ["roots", "8fdc6a"], ["silence", "c9a2ff"], ["slow", "86c8ff"], ["slows", "86c8ff"], ["shield", "9fe7ff"], ["heal", "8cff9a"], ["heals", "8cff9a"], ["lifesteal", "ff8a8a"], ["burn", "ff9a5c"], ["poison", "a4df80"], ["fear", "d0a0ff"], ["taunt", "ffcf6e"], ["taunts", "ffcf6e"]]:
		var kw = RegEx.new(); kw.compile("\\b(" + pair[0] + ")\\b")
		body = kw.sub(body, "[color=#%s]$1[/color]" % pair[1], true)
	return out + body

## Dialogs float in: the backdrop fades while the card rises a little and settles, with a soft open
## sound; closing plays the matching sound. Call right after building the dialog.
static func float_in(game_node: Node, shade: Control, card: Control) -> void:
	shade.modulate.a = 0.0
	var tw = shade.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(shade, "modulate:a", 1.0, 0.18)
	if card:
		card.pivot_offset = card.size * 0.5
		card.scale = Vector2(0.965, 0.965); var end_y = card.position.y; card.position.y += 14
		tw.tween_property(card, "scale", Vector2.ONE, 0.24); tw.tween_property(card, "position:y", end_y, 0.24)
	if game_node and "sound" in game_node and game_node.sound: game_node.sound.play_sample("ui_open", -17.0, 1)
	shade.tree_exiting.connect(func():
		if is_instance_valid(game_node) and game_node.is_inside_tree() and "sound" in game_node and game_node.sound: game_node.sound.play_sample("ui_close", -20.0, 1))
