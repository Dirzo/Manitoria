class_name ScoutUI
extends RefCounted
## Full scouting report on the next rival: every champion's power, real stats (graded against every
## champion at its level), equipped items, skills and evolution, plus a one-line plan.

const ROWS := [["hp", "Health"], ["attack", "Damage"], ["armor", "Armor"], ["haste", "Attack speed"], ["speed", "Move speed"], ["potency", "Ability power"]]

static func open(game: Node, opponent: Dictionary, tip := "") -> void:
	var c: Campaign = game.campaign
	var dialog = GearUI.modal(game, "Scouting · " + str(opponent.get("name", "Rival")), Vector2(1440, 760))
	dialog.box.add_theme_constant_override("separation", 10)
	if tip != "": game.label(dialog.box, tip, 15, Color("c8ff9d"), true)
	var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 10); dialog.box.add_child(row)
	var q = c.quality() if c and not c.state.is_empty() else 1.0
	if c and c.state.has("tour"):
		game.label(dialog.box,"Cup %d · %s · Recruit between cups; participants earn 160 training XP when you qualify for the next cup."%[int(c.state.tour.level),str(c.state.difficulty)],13,Color("c8dcb1"),true)
	for h in opponent.get("roster", []): card(game, row, h, q)
	game.label(dialog.box, "Stats include their rivals' strength bonus at this difficulty. Grades compare each stat with every champion at the same level. Hover anything for details.", 12, Color("9fb0b8"), true)

static func card(game: Node, parent: Node, h: Dictionary, quality: float) -> void:
	var frame = PanelContainer.new(); frame.custom_minimum_size = Vector2(270, 0); parent.add_child(frame)
	frame.add_theme_stylebox_override("panel", game.style(Color(0.09, 0.05, 0.07, 0.95), Color("ff9989"), 10, 10, 1))
	var box = VBoxContainer.new(); box.add_theme_constant_override("separation", 4); frame.add_child(box)
	var top = HBoxContainer.new(); top.add_theme_constant_override("separation", 8); box.add_child(top)
	SplashArt.make(top, h.sp, Vector2(64, 80))
	var who = VBoxContainer.new(); who.add_theme_constant_override("separation", 0); top.add_child(who)
	var nm = game.label(who, h.name, 17, Color.WHITE, false); FlowUI.fit_label(nm, 180, 17, 11)
	game.label(who, "%s · %s" % [HeroData.species[h.sp].n, HeroData.species[h.sp].role], 12, Color("c9d6dc"), false)
	game.label(who, "Level %d · %s line" % [int(h.level), HeroData.line(h.sp)], 12, Color("9fb0b8"), false)
	game.label(who, "POWER %d" % HeroData.power(h), 15, TraitUI.power_color(h), false)
	var ev = HeroData.evolution_info(h)
	if not ev.is_empty(): game.label(box, "EVOLVED · " + str(ev.name), 12, Color(str(ev.get("color", "ffd36e")))).tooltip_text = str(ev.get("description", ""))
	# Stats: real numbers, coloured by how they compare at this level.
	var s = HeroData.stats(h, quality); var n = StatHex.normalized(h)
	var values = {"hp": "%d" % s.hp, "attack": "%d" % s.attack, "armor": "%d%%" % roundi(s.armor * 100), "haste": "%.2f/s" % (1.0 / maxf(0.05, s.interval)), "speed": "%.1f" % s.speed, "potency": "x%.2f" % HeroData.spell_factor(h)}
	var grid = GridContainer.new(); grid.columns = 3; grid.add_theme_constant_override("h_separation", 8); grid.add_theme_constant_override("v_separation", 1); box.add_child(grid)
	for r in ROWS:
		var k = r[0]
		var l = game.label(grid, r[1], 13, Color("dfe8ec"), false); l.custom_minimum_size.x = 96
		l.tooltip_text = StatHex.GUIDE[k].does; l.mouse_filter = Control.MOUSE_FILTER_STOP
		game.label(grid, values[k], 13, Color.WHITE, false).custom_minimum_size.x = 62
		game.label(grid, StatHex.grade(n[k]), 12, StatHex.grade_color(n[k]), false)
	# Items.
	var eq: Dictionary = h.get("equipment", {})
	game.label(box, "ITEMS · %d" % eq.size() if not eq.is_empty() else "ITEMS · none", 12, Color("ffd36e"), false)
	if not eq.is_empty():
		var items = HBoxContainer.new(); items.add_theme_constant_override("separation", 4); box.add_child(items)
		for v in eq.values():
			var info = Forge.info(str(v))
			var t = GearUI.token(game, items, info, 40); t.tooltip_text = "%s\n%s" % [info.name, Forge.stat_line(str(v)) if info.kind == "item" else info.get("short", "")]
	# Skills.
	game.label(box, "SKILLS", 12, Color("ffd36e"), false)
	for e in ChampionKit.entries(h):
		var sk = game.label(box, "%s · R%d" % [e.name, e.rank], 12, RarityStyle.color(e.rarity), false)
		sk.tooltip_text = e.description; sk.mouse_filter = Control.MOUSE_FILTER_STOP
