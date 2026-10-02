class_name TourIntro
extends Control
## Arrival card for each World Tour stop: the region's art slowly pushes in, the tournament name
## slams down, then the eight guilds of the draw are presented before you step onto the board.
var game: Node
var on_continue: Callable
const FLAVOR := {
	"Forest": "Ancient groves, tangled roots and beasts that heal as fast as they bleed.",
	"Volcanic": "Molten stone and roaring crowds. Here the fire-born fight at home.",
	"Coastal": "Salt spray and storm-light. Tides turn quickly at Pearlreach.",
	"Glacial": "Thin air, hard ice. Only the stubborn last a whole bracket here.",
	"Desert": "Gold sand and old gods. The sun favours the patient.",
	"Astral": "The stars watch every bout. Shadows and tricksters thrive beneath them.",
}

func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); mouse_filter = Control.MOUSE_FILTER_STOP
	var c: Campaign = game.campaign; var r = WorldTour.region(c); var accent = Color(r.color)
	var bg = TextureRect.new(); add_child(bg); bg.texture = load("res://assets/ui/regions/%s.jpg" % str(r.theme).to_lower())
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size = Vector2(1600, 900); bg.pivot_offset = Vector2(800, 450); bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var zoom = create_tween(); zoom.tween_property(bg, "scale", Vector2(1.12, 1.12), 14.0).from(Vector2(1.0, 1.0))
	var shade = ColorRect.new(); add_child(shade); shade.size = Vector2(1600, 900); shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh = Shader.new(); sh.code = "shader_type canvas_item; uniform vec4 tint:source_color; void fragment(){ float v=smoothstep(0.15,0.85,UV.y); float e=length(UV-vec2(.5,.42)); COLOR=vec4(mix(vec3(0.0),tint.rgb*0.15,0.3), clamp(0.25+v*0.55+e*0.5,0.,0.92)); }"
	var m = ShaderMaterial.new(); m.shader = sh; m.set_shader_parameter("tint", accent); shade.material = m
	var tl = create_tween(); tl.set_parallel(true)
	var kicker = game.label(self, "WORLD TOUR  ·  CUP %d OF %d" % [int(c.state.tour.level), WorldTour.MAX_LEVEL], 22, accent.lightened(0.3), false)
	kicker.position = Vector2(0, 150); kicker.size = Vector2(1600, 34); kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.modulate.a = 0; tl.tween_property(kicker, "modulate:a", 1.0, 0.5).set_delay(0.2)
	var title = game.label(self, str(r.name).to_upper(), 104, Color("ffe9b8"), false)
	title.position = Vector2(0, 190); title.size = Vector2(1600, 140); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load(game.TITLE_FONT)); title.add_theme_color_override("font_outline_color", Color("1a0f14")); title.add_theme_constant_override("outline_size", 14)
	title.add_theme_color_override("font_shadow_color", Color(accent, 0.7)); title.add_theme_constant_override("shadow_offset_y", 0); title.add_theme_constant_override("shadow_outline_size", 30)
	title.pivot_offset = Vector2(800, 70); title.scale = Vector2(1.7, 1.7); title.modulate.a = 0
	tl.tween_property(title, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.55)
	tl.tween_property(title, "modulate:a", 1.0, 0.2).set_delay(0.55)
	tl.tween_callback(func(): game.sound.cue("contest_versus")).set_delay(0.75)
	var place = game.label(self, str(r.place), 34, Color.WHITE, false); place.position = Vector2(0, 330); place.size = Vector2(1600, 46); place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9)); place.add_theme_constant_override("outline_size", 6)
	place.modulate.a = 0; tl.tween_property(place, "modulate:a", 1.0, 0.5).set_delay(1.1)
	var flavor = game.label(self, FLAVOR.get(str(r.theme), ""), 20, Color("e8e2d2"), false); flavor.position = Vector2(0, 380); flavor.size = Vector2(1600, 30); flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9)); flavor.add_theme_constant_override("outline_size", 5)
	flavor.modulate.a = 0; tl.tween_property(flavor, "modulate:a", 1.0, 0.5).set_delay(1.4)
	var home = []
	for sp in r.roster: home.append(HeroData.species[sp].n)
	var hl = game.label(self, "Home favourites: " + ", ".join(home), 16, accent.lightened(0.2), false); hl.position = Vector2(0, 414); hl.size = Vector2(1600, 26); hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hl.modulate.a = 0; tl.tween_property(hl, "modulate:a", 1.0, 0.5).set_delay(1.6)
	# The draw: eight guild crests, yours glowing.
	WorldTour.ensure_bracket(c); var b = c.state.tour.bracket
	var row = HBoxContainer.new(); add_child(row); row.position = Vector2(80, 480); row.size = Vector2(1440, 220); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 14)
	for k in range(8):
		var team = int(b.seeds[k]); var col = VBoxContainer.new(); col.custom_minimum_size.x = 160; row.add_child(col)
		var crest = Crest.of_campaign(c) if team == 0 else Crest.default_for(WorldTour.team_name(c, team))
		var holder = CenterContainer.new(); holder.custom_minimum_size = Vector2(160, 120); col.add_child(holder)
		if team == 0: FlowUI.aura(holder, accent, Vector2(170, 170), 0.9)
		Crest.make(holder, crest, WorldTour.team_name(c, team), Vector2(88, 104))
		var nm = game.label(col, WorldTour.team_name(c, team), 15, Color("86dbf2") if team == 0 else Color.WHITE, false); nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		FlowUI.fit_label(nm, 160, 15, 10); nm.custom_minimum_size.x = 160
		var pw = int(b.get("ovr_%d" % team, 0))
		var p = game.label(col, "Seed %d  ·  %d power" % [k + 1, pw], 13, TraitUI.power_color(float(b.get("q_%d" % team, 70))), false); p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.modulate.a = 0; col.position.y = 30
		tl.tween_property(col, "modulate:a", 1.0, 0.3).set_delay(2.0 + k * 0.12)
	var holder2 = HBoxContainer.new(); add_child(holder2); holder2.position = Vector2(560, 760); holder2.size = Vector2(480, 64); holder2.alignment = BoxContainer.ALIGNMENT_CENTER
	FlowUI.cta(game, holder2, "Enter the tournament  ▶", func(): queue_free(); on_continue.call(), false, 480)

static func present(game_node: Node, then: Callable) -> void:
	var v = TourIntro.new(); v.game = game_node; v.on_continue = then; game_node.ui.add_child(v); v.build()
