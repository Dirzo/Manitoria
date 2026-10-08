class_name DraftBoard
extends RefCounted
## Draft views. GRID: big art cards where power, temperament, scaling and stat rolls pop.
## TABLE: one row per champion, every number colour coded, click a header to sort by it.
## opts per hero: {price, selected, on_select, on_scout, on_draft, draft_text, draft_disabled}

const TABLE_COLS := [
	["", "", 56], ["Champion", "Board", 200], ["Role", "Role", 104], ["Power", "Power", 74], ["Trait", "Ideal", 132],
	["Scale", "Scale", 84], ["HP", "hp", 54], ["DMG", "attack", 54], ["ARM", "armor", 54], ["AS", "haste", 54],
	["MOV", "speed", 54], ["AP", "potency", 54], ["Fit", "Fit", 200], ["Cost", "Price", 66], ["", "", 128],
]

static func view(game: Node) -> String:
	return str(game.desk_state.get("view", "Grid"))

## [Grid | Table] toggle plus the sort buttons.
static func view_bar(game: Node, parent: Node) -> HBoxContainer:
	var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 8); parent.add_child(row)
	for v in ["Grid", "Table"]:
		var b = game.button(row, ("▦ " if v == "Grid" else "☰ ") + v, func(): game.desk_state.view = v; game.render(), view(game) == v)
		b.custom_minimum_size.x = 104
	var gap = Control.new(); gap.custom_minimum_size.x = 18; row.add_child(gap)
	TraitUI.sort_bar(game, row)
	StatHex.help_button(game, row, {}, "?  Stats")
	return row

static func _badge(game: Node, parent: Control, text: String, color: Color, font: int, pos: Vector2, fill := Color(0.03, 0.03, 0.06, 0.82)) -> PanelContainer:
	var p = PanelContainer.new(); p.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(p); p.position = pos
	p.add_theme_stylebox_override("panel", game.style(Color(color.darkened(0.78), 0.88) if fill.a > 0.85 and fill.r < 0.1 else fill, color, 8, 6, 0))
	var l = game.label(p, text, font, color, false); l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_outline_color", Color.BLACK); l.add_theme_constant_override("outline_size", 4)
	return p

# ---------------------------------------------------------------- grid
static func card(game: Node, parent: Node, h: Dictionary, o: Dictionary, width := 286.0, art_h := 196.0) -> PanelContainer:
	var tier = League.tier(h.sp); var tc = Color(League.TIER_COLOR[tier]); var sel = o.get("selected", false)
	var frame = PanelContainer.new(); frame.custom_minimum_size.x = width; parent.add_child(frame)
	frame.add_theme_stylebox_override("panel", game.style(Color(.05, .08, .11, .96), game.GOLD if sel else tc.darkened(0.15), 10, 8, 4 if sel else 2))
	var box = VBoxContainer.new(); box.add_theme_constant_override("separation", 5); frame.add_child(box)
	# Art with power, role and ideal badges layered on top.
	var art_button = Button.new(); art_button.custom_minimum_size = Vector2(0, art_h); box.add_child(art_button)
	for st in ["normal", "hover", "pressed", "focus"]: art_button.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var art = SplashArt.new(); art.sp = h.sp; art.caption = HeroData.species[h.sp].n; art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_button.add_child(art); art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_button.mouse_entered.connect(func(): art.modulate = Color(1.12, 1.12, 1.12)); art_button.mouse_exited.connect(func(): art.modulate = Color.WHITE)
	var click = o.get("on_select", o.get("on_scout", Callable()))
	if click.is_valid(): art_button.pressed.connect(click)
	art_button.tooltip_text = HeroData.species[h.sp].ability_name + " · " + HeroData.species[h.sp].ability_description
	var pw = HeroData.power(h)
	var pb = _badge(game, art_button, "%d" % pw, TraitUI.power_color(h), 26, Vector2(width - 78, 6))
	pb.tooltip_text = "Power level"
	_badge(game, art_button, HeroData.species[h.sp].role.to_upper(), tc, 12, Vector2(8, 8))
	if Traits.is_ideal(h): _badge(game, art_button, "★ IDEAL", TraitUI.IDEAL, 12, Vector2(8, 42), Color(0.25, 0.17, 0.02, 0.9))
	# Name + scaling
	var row = HBoxContainer.new(); box.add_child(row)
	var nm = game.label(row, h.name, 19, game.WHITE, false); nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL; nm.clip_text = true
	var s = Traits.score(h)
	var sc = PanelContainer.new(); row.add_child(sc); sc.add_theme_stylebox_override("panel", game.style(TraitUI.scale_color(s).darkened(0.7), TraitUI.scale_color(s), 6, 4, 0))
	game.label(sc, "%s %d" % [Traits.scaling_type(s).to_upper(), int(round(s))], 12, TraitUI.scale_color(s), false)
	sc.tooltip_text = "%s scaler · %s" % [Traits.scaling_type(s), Traits.info(h.sp).calling]
	# Temperament
	var t = Traits.trait_of(h); var ideal = Traits.is_ideal(h)
	var tl = game.label(box, ("★ " if ideal else "") + t + "  ·  " + Traits.TRAITS[t].up, 13, TraitUI.IDEAL if ideal else Color("c9d6dc"), false)
	tl.clip_text = true; tl.mouse_filter = Control.MOUSE_FILTER_STOP; tl.tooltip_text = Traits.describe(h) + "\nIdeal: " + " · ".join(Traits.info(h.sp).ideal)
	# Stat rolls + fit
	var stats = HBoxContainer.new(); box.add_child(stats); stats.custom_minimum_size.x = width - 20
	TraitUI.roll_chips(game, stats, h, 12 if width >= 300 else 10, width < 260)
	var fi = TraitUI.fit_info(h)
	var fit = game.label(box, "%s FIT · %s" % [fi[0], TraitUI.fit_reason(h, true)], 12, fi[1], false); fit.clip_text = true
	fit.mouse_filter = Control.MOUSE_FILTER_STOP; fit.tooltip_text = TraitUI.fit_reason(h) + "\n%d/%d total stat points" % [HeroData.roll_total(h), HeroData.ROLL_MAX * 6]
	var evidence=RunDatabase.aggregate({"side":"player"}).champions.get(h.sp,{})
	var note="Your Atlas: %d appearances · %.1f%% team wins"%[int(evidence.get("n",0)),100.0*float(evidence.get("wins",0))/maxf(1,float(evidence.get("n",0)))] if not evidence.is_empty() else "Your Atlas: no personal data yet"
	if evidence.is_empty():
		var research=PlaytestDatabase.champions().get(h.sp,{})
		if not research.is_empty():note="Playtest 0.70: %d appearances · %.1f%% team wins"%[int(research.n),100.0*float(research.wins)]
	game.label(box,note,12,game.MUTED).tooltip_text="Press Atlas to compare recorded player and CPU builds. Team association, not isolated champion strength."
	# Actions
	if o.has("on_draft") or o.has("on_scout"):
		var actions = HBoxContainer.new(); actions.add_theme_constant_override("separation", 6); box.add_child(actions)
		if o.has("on_scout"):
			var sb = game.button(actions, "i", o.on_scout); sb.custom_minimum_size.x = 40; sb.tooltip_text = "Scout abilities and 3D model"
		if o.has("on_draft"):
			var db = game.button(actions, o.get("draft_text", "Draft · %d gold" % int(h.get("price", 0))), o.on_draft, true, o.get("draft_disabled", false))
			db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return frame

static func grid(game: Node, parent: Node, heroes: Array, opts: Callable, columns := 4, width := 286.0, art_h := 196.0) -> GridContainer:
	var g = GridContainer.new(); g.columns = columns; g.add_theme_constant_override("h_separation", 14); g.add_theme_constant_override("v_separation", 14); parent.add_child(g)
	for h in heroes: card(game, g, h, opts.call(h), width, art_h)
	return g

# ---------------------------------------------------------------- table
## Fixed-width cell: content can never push a column wider, so headers and rows line up.
static func _cell(parent: Node, w: float, h := 56.0) -> HBoxContainer:
	var holder = Control.new(); holder.custom_minimum_size = Vector2(w, h); holder.clip_contents = true; parent.add_child(holder)
	var c = HBoxContainer.new(); holder.add_child(c); c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.alignment = BoxContainer.ALIGNMENT_CENTER
	c.child_entered_tree.connect(func(n): if n is Control: n.size_flags_vertical = Control.SIZE_SHRINK_CENTER)
	return c

static func table(game: Node, parent: Node, heroes: Array, opts: Callable, columns: Array = TABLE_COLS) -> VBoxContainer:
	var list = VBoxContainer.new(); list.add_theme_constant_override("separation", 4); parent.add_child(list)
	var sort = str(game.desk_state.get("sort", "Board"))
	var head_panel = PanelContainer.new(); list.add_child(head_panel)
	head_panel.add_theme_stylebox_override("panel", game.style(Color(.03, .04, .06, .94), Color("aa8c60"), 6, 3, 2))
	var head = HBoxContainer.new(); head.add_theme_constant_override("separation", 4); head_panel.add_child(head)
	for col in columns:
		var c = _cell(head, col[2], 34)
		if col[1] == "Board": c.alignment = BoxContainer.ALIGNMENT_BEGIN
		if col[0] == "": continue
		if col[1] == "":
			game.label(c, col[0], 13, game.GOLD, false); continue
		var active = sort == col[1]
		var b = Button.new(); b.text = col[0] + (" ▼" if active else ""); b.flat = true; c.add_child(b)
		# Headers use the plain body face: the decorative title font turns short codes like DMG into glyphs.
		b.add_theme_font_override("font", b.get_theme_default_font())
		b.add_theme_font_size_override("font_size", 16); b.add_theme_color_override("font_color", game.GOLD if active else Color("dfe8ec"))
		b.add_theme_color_override("font_hover_color", game.GOLD)
		b.clip_text = false
		b.tooltip_text = "Sort by " + col[0]; var key = col[1]
		if StatHex.GUIDE.has(key): b.tooltip_text = "%s: %s\n%s\nClick to sort." % [StatHex.GUIDE[key].name, StatHex.GUIDE[key].does, StatHex.GUIDE[key].scale]
		b.pressed.connect(func(): game.desk_state.sort = key; game.render())
	# Best roll per stat among these heroes gets a gold ring.
	var best = {}
	for k in HeroData.ROLL_KEYS:
		best[k] = 0
		for h in heroes: best[k] = maxi(best[k], HeroData.roll_now(h, k))
	for h in heroes: _row(game, list, h, opts.call(h), columns, best)
	return list

static func _row(game: Node, list: Node, h: Dictionary, o: Dictionary, columns: Array, best: Dictionary) -> void:
	var tier = League.tier(h.sp); var tc = Color(League.TIER_COLOR[tier]); var sel = o.get("selected", false); var ideal = Traits.is_ideal(h)
	var panel = PanelContainer.new(); list.add_child(panel)
	panel.add_theme_stylebox_override("panel", game.style(Color(.06, .09, .12, .95) if not sel else Color(.12, .11, .06, .95), game.GOLD if sel else (TraitUI.IDEAL.darkened(0.3) if ideal else tc.darkened(0.55)), 6, 3, 2))
	var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 4); panel.add_child(row)
	var r = HeroData.rolls(h); var w = HeroData.role_weights(h.sp)
	for col in columns:
		var c = _cell(row, col[2], 96)
		match col[1] if col[0] != "" or col[1] != "" else ("art" if c.get_parent().get_index() == 0 else "action"):
			"art":
				var b = Button.new(); b.custom_minimum_size = Vector2(52, 52); c.add_child(b)
				for st in ["normal", "hover", "pressed", "focus"]: b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
				var a = SplashArt.new(); a.sp = h.sp; a.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(a); a.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				var click = o.get("on_select", o.get("on_scout", Callable()))
				if click.is_valid(): b.pressed.connect(click)
				b.tooltip_text = "Inspect"
			"Board":
				c.alignment = BoxContainer.ALIGNMENT_BEGIN
				var v = VBoxContainer.new(); v.add_theme_constant_override("separation", -2); c.add_child(v)
				game.label(v, h.name, 17, game.WHITE, false)
				game.label(v, HeroData.species[h.sp].n + "  ·  " + tier, 12, tc, false)
			"Role":
				game.label(c, HeroData.species[h.sp].role, 14, tc, false)
			"Power":
				var p = HeroData.power(h); game.label(c, str(p), 24, TraitUI.power_color(h), false)
			"Ideal":
				var t = Traits.trait_of(h)
				var l = game.label(c, ("★ " if ideal else "") + t, 14, TraitUI.IDEAL if ideal else Color("c9d6dc"), false)
				l.mouse_filter = Control.MOUSE_FILTER_STOP; l.tooltip_text = Traits.describe(h)
			"Scale":
				var s = Traits.score(h)
				var l = game.label(c, "%s %d" % [Traits.scaling_type(s), int(round(s))], 14, TraitUI.scale_color(s), false)
				l.mouse_filter = Control.MOUSE_FILTER_STOP; l.tooltip_text = Traits.info(h.sp).calling
			"Fit":
				var fi = TraitUI.fit_info(h); var fv = VBoxContainer.new(); fv.add_theme_constant_override("separation", -2); c.add_child(fv)
				fv.mouse_filter = Control.MOUSE_FILTER_STOP; fv.tooltip_text = TraitUI.fit_reason(h)
				game.label(fv, fi[0], 14, fi[1], false).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				if c.get_parent().custom_minimum_size.x > 120:
					var why = game.label(fv, TraitUI.fit_reason(h, true), 11, fi[1].darkened(0.1), true); why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					fv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					why.custom_minimum_size = Vector2(col[2] - 12, 60)
					why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					why.clip_text = true
					why.name = "FitDescription"
			"Price":
				game.label(c, "%d" % int(h.get("price", 0)), 15, Color("ffdf7e"), false)
			"action":
				if o.has("on_draft"):
					var db = game.button(c, o.get("draft_text", "Draft"), o.on_draft, true, o.get("draft_disabled", false))
					db.custom_minimum_size.x = col[2] - 6; db.add_theme_font_size_override("font_size", 15)
				elif o.has("on_select"):
					var sb = game.button(c, "Selected" if o.get("selected", false) else "Select", o.on_select, o.get("selected", false))
					sb.custom_minimum_size.x = col[2] - 6
			_:
				if col[1] in HeroData.ROLL_KEYS:
					var v = HeroData.roll_now(h, col[1]); var color = HeroData.roll_color(v)
					var chip = PanelContainer.new(); c.add_child(chip); chip.custom_minimum_size = Vector2(44, 30)
					var top = v == best[col[1]] and v >= 16
					chip.add_theme_stylebox_override("panel", game.style(color.darkened(0.74), TraitUI.IDEAL if top else (color if w.has(col[1]) else color.darkened(0.6)), 5, 2, 2 if top else 1))
					var l = game.label(chip, str(v), 16, color, false); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					chip.tooltip_text = TraitUI.roll_tip(h, col[1]) + ("\nBest on the board" if top else "")
