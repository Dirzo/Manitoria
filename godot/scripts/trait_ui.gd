class_name TraitUI
extends RefCounted
## Temperament and scaling readouts. The species' perfect role and ideal temperaments are gold;
## a champion whose own temperament is one of its ideals shows that in gold too.
const IDEAL := Color("ffd36e")

static func line(game: Node, parent: Node, hero: Dictionary, compact := false) -> void:
	var t = Traits.trait_of(hero); var data = Traits.TRAITS[t]; var ideal = Traits.is_ideal(hero)
	var box = VBoxContainer.new(); box.add_theme_constant_override("separation", 1); parent.add_child(box)
	var head = game.label(box, ("★ " if ideal else "") + t.to_upper() + ("  ·  IDEAL" if ideal else ""), 13, IDEAL if ideal else Color("c9d6dc"), false)
	head.tooltip_text = Traits.describe(hero)
	if not compact:
		game.label(box, "%s  /  %s" % [data.up, data.down], 12, Color("9fb0b8"), true)
	var s = Traits.score(hero)
	var curve = game.label(box, "%s scaler %d/10  ·  %s" % [Traits.scaling_type(s), int(round(s)), Traits.info(hero.sp).calling], 12, IDEAL, true)
	curve.tooltip_text = "Scaling: early scalers are strongest in the first cups and fade; late scalers start weaker and grow. At level %d this champion fights at %d%% of par." % [int(hero.level), roundi(Traits.curve(hero) * 100)]
	if not compact:
		game.label(box, "Ideal temperaments: " + " · ".join(Traits.info(hero.sp).ideal), 12, IDEAL, true)

static func species_line(game: Node, parent: Node, sp: String) -> void:
	var info = Traits.info(sp)
	game.label(parent, "%s  ·  %s" % [Traits.scaling_text(sp), info.calling], 13, IDEAL, true)
	game.label(parent, "Ideal: " + " · ".join(info.ideal), 12, IDEAL, true)

const ROLL_SHORT := {"hp": "HP", "attack": "DMG", "armor": "ARM", "haste": "AS", "speed": "MOV", "potency": "AP"}

## Colour for a Power number. Pass the champion (or a team's average quality): the colour reflects how
## good the champion is for its level (rarity, rolls, fit), not the raw number, which grows with level.
static func power_color(x) -> Color:
	var p = HeroData.power_quality(x) if x is Dictionary else float(x)
	if p >= 85: return Color("ffd36e")
	if p >= 76: return Color("6fe08a")
	if p >= 68: return Color("d6e86a")
	if p >= 60: return Color("ffa451")
	return Color("ff5e5e")

## Random stat genes, colour coded. Compact: one row of chips. Full: bars with grades.
## Stats the champion's role relies on are marked with a gold dot; only those raise its power.
static func rolls(game: Node, parent: Node, hero: Dictionary, compact := false) -> void:
	var r = HeroData.rolls(hero); var w = HeroData.role_weights(hero.sp)
	var total = HeroData.roll_total(hero); var p = HeroData.power(hero)
	var fit = HeroData.fit_score(hero)
	var head = HBoxContainer.new(); head.add_theme_constant_override("separation", 10); parent.add_child(head)
	var pw = game.label(head, "POWER %d" % p, 15, power_color(hero), false)
	pw.tooltip_text = "Power level: tier, level, abilities, how well the rolls suit a %s, temperament fit and scaling." % HeroData.species[hero.sp].role
	var tc = HeroData.roll_color(roundi(float(total) / HeroData.ROLL_KEYS.size()))
	game.label(head, "STATS %d/%d" % [total, HeroData.ROLL_MAX * HeroData.ROLL_KEYS.size()], 13, tc, false).tooltip_text = "Sum of all six stat rolls."
	var fit_text = "GREAT FIT" if fit >= 0.35 else ("GOOD FIT" if fit >= 0.1 else ("POOR FIT" if fit <= -0.25 else "OK FIT"))
	var fit_col = Color("6fe08a") if fit >= 0.1 else (Color("ff5e5e") if fit <= -0.25 else Color("d6e86a"))
	# Compact cards put the fit verdict on its own clipped line so it can never widen the card.
	var fl = game.label(parent if compact else head, fit_text + "  ·  " + fit_reason(hero, true), 13, fit_col, false); fl.mouse_filter = Control.MOUSE_FILTER_STOP
	fl.tooltip_text = fit_reason(hero)
	if compact:
		head.alignment = BoxContainer.ALIGNMENT_CENTER
		fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; fl.clip_text = true; fl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; fl.custom_minimum_size.x = 40
		var row = HFlowContainer.new(); row.add_theme_constant_override("h_separation", 4); row.add_theme_constant_override("v_separation", 3); row.alignment = FlowContainer.ALIGNMENT_CENTER; parent.add_child(row)
		for k in HeroData.ROLL_KEYS:
			var v = int(r[k]); var chip = PanelContainer.new(); row.add_child(chip)
			chip.add_theme_stylebox_override("panel", game.style(HeroData.roll_color(v).darkened(0.55 if w.has(k) else 0.8), HeroData.roll_color(v), 5, 3, 0))
			var l = game.label(chip, "%s%s %d" % ["•" if w.has(k) else "", ROLL_SHORT[k], v], 11, HeroData.roll_color(v), false)
			chip.tooltip_text = "%s roll %d/%d (%s)%s" % [HeroData.ROLL_NAMES[k], v, HeroData.ROLL_MAX, HeroData.roll_grade(v), "\nKey stat for this role" if w.has(k) else ""]
		return
	var grid = GridContainer.new(); grid.columns = 4; grid.add_theme_constant_override("h_separation", 8); grid.add_theme_constant_override("v_separation", 2); parent.add_child(grid)
	for k in HeroData.ROLL_KEYS:
		var v = int(r[k]); var c = HeroData.roll_color(v)
		var name = game.label(grid, ("● " if w.has(k) else "   ") + HeroData.ROLL_NAMES[k], 13, IDEAL if w.has(k) else Color("9fb0b8"), false)
		name.custom_minimum_size.x = 128
		var bar = ProgressBar.new(); bar.max_value = HeroData.ROLL_MAX; bar.value = v; bar.show_percentage = false; bar.custom_minimum_size = Vector2(150, 10); bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER; grid.add_child(bar)
		bar.add_theme_stylebox_override("background", game.style(Color("1d2a31"), Color.TRANSPARENT, 4, 0, 0))
		bar.add_theme_stylebox_override("fill", game.style(c, Color.TRANSPARENT, 4, 0, 0))
		game.label(grid, "%d" % v, 13, c, false).custom_minimum_size.x = 24
		var pct = roundi((HeroData.roll_mult(hero, k) - 1.0) * 100.0) if k != "armor" else roundi(HeroData.roll_norm(hero, k) * 3.0)
		game.label(grid, ("%s  %+d%%" % [HeroData.roll_grade(v), pct]) if k != "armor" else ("%s  %+d armor" % [HeroData.roll_grade(v), pct]), 12, c, false)

## Sort champions: "Power" (highest power level first) or "Ideal" (ideal temperament first, then
## best role fit of the stat rolls, then power). Anything else keeps the given order.
static func sorted(list: Array, mode: String) -> Array:
	var out = list.duplicate()
	if mode == "Power":
		out.sort_custom(func(a, b): return HeroData.power(a) > HeroData.power(b))
	elif mode == "Ideal":
		out.sort_custom(func(a, b):
			var ia = Traits.is_ideal(a); var ib = Traits.is_ideal(b)
			if ia != ib: return ia
			var fa = HeroData.fit_score(a); var fb = HeroData.fit_score(b)
			if absf(fa - fb) > 0.001: return fa > fb
			return HeroData.power(a) > HeroData.power(b))
	elif mode in HeroData.ROLL_KEYS:
		out.sort_custom(func(a, b): return int(HeroData.rolls(a)[mode]) > int(HeroData.rolls(b)[mode]))
	elif mode == "Stats":
		out.sort_custom(func(a, b): return HeroData.roll_total(a) > HeroData.roll_total(b))
	elif mode == "Fit":
		out.sort_custom(func(a, b): return HeroData.fit_score(a) > HeroData.fit_score(b))
	elif mode == "Scale":
		out.sort_custom(func(a, b): return Traits.score(a) > Traits.score(b))
	elif mode == "Price":
		out.sort_custom(func(a, b): return int(a.get("price", 0)) < int(b.get("price", 0)))
	elif mode == "Role":
		out.sort_custom(func(a, b): return str(HeroData.species[a.sp].role) < str(HeroData.species[b.sp].role))
	return out

## A "Sort:" row of toggle buttons bound to game.desk_state.sort.
static func sort_bar(game: Node, parent: Node, modes: Array = ["Board", "Power", "Ideal"]) -> void:
	var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 8); parent.add_child(row)
	game.label(row, "SORT", 14, IDEAL, false)
	var names = {"Board": "Default", "Power": "Power level ▼", "Ideal": "★ Ideal trait"}
	for m in modes:
		var b = game.button(row, names.get(m, m), func(): game.desk_state.sort = m; game.render(), game.desk_state.get("sort", "Board") == m)
		b.tooltip_text = {"Board": "Original order", "Power": "Highest power level first", "Ideal": "Champions with their ideal temperament first, then the best role fit of their stat rolls"}.get(m, "")

## Just the six colour-coded stat chips (key stats for the role marked with a dot).
static func roll_chips(game: Node, parent: Node, hero: Dictionary, font := 11, flow := false) -> Container:
	var r = HeroData.rolls(hero); var w = HeroData.role_weights(hero.sp)
	var row: Container = HFlowContainer.new() if flow else HBoxContainer.new()
	row.add_theme_constant_override("separation" if not flow else "h_separation", 3)
	if flow: row.add_theme_constant_override("v_separation", 3); row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	for k in HeroData.ROLL_KEYS:
		var v = int(r[k]); var chip = PanelContainer.new(); row.add_child(chip)
		chip.add_theme_stylebox_override("panel", game.style(HeroData.roll_color(v).darkened(0.55 if w.has(k) else 0.8), HeroData.roll_color(v), 5, 3, 0))
		game.label(chip, "%s%s %d" % ["•" if w.has(k) else "", ROLL_SHORT[k], v], font, HeroData.roll_color(v), false)
		chip.tooltip_text = "%s roll %d/%d (%s)%s" % [HeroData.ROLL_NAMES[k], v, HeroData.ROLL_MAX, HeroData.roll_grade(v), "\nKey stat for this role" if w.has(k) else ""]
	return row

static func scale_color(s: float) -> Color:
	return Color("ffa451") if s <= 3.5 else (Color("c99bff") if s >= 6.5 else Color("7fe0d0"))

static func fit_info(hero: Dictionary) -> Array:
	var fit = HeroData.fit_score(hero)
	if fit >= 0.35: return ["GREAT", Color("ffd36e")]
	if fit >= 0.1: return ["GOOD", Color("6fe08a")]
	if fit <= -0.25: return ["POOR", Color("ff5e5e")]
	return ["OK", Color("d6e86a")]

## Why a champion is a good or poor fit: the role's key stats and how they rolled.
static func fit_reason(hero: Dictionary, short := false) -> String:
	var w = HeroData.role_weights(hero.sp); var r = HeroData.rolls(hero); var role = HeroData.species[hero.sp].role
	var keys = w.keys(); keys.sort_custom(func(a, b): return w[a] > w[b])
	var highs = []; var lows = []
	for k in keys:
		if w[k] < 0.2: continue
		if int(r[k]) >= 22: highs.append(HeroData.ROLL_NAMES[k])
		elif int(r[k]) <= 10: lows.append(HeroData.ROLL_NAMES[k])
	var tf = Traits.temper_fit(hero); var tname = Traits.trait_of(hero)
	var temper = ("%s is ideal" % tname) if Traits.is_ideal(hero) else (("%s suits a %s" % [tname, role]) if tf >= 0.15 else (("%s works against a %s" % [tname, role]) if tf <= -0.15 else ""))
	if short:
		var bits = []
		if not highs.is_empty(): bits.append("strong " + ", ".join(highs.slice(0, 2)))
		if not lows.is_empty(): bits.append("weak " + ", ".join(lows.slice(0, 2)))
		if bits.is_empty(): bits.append("average key stats")
		if temper != "": bits.append(temper)
		return " · ".join(bits)
	var t = "A %s relies on: " % role
	var parts = []
	for k in keys: parts.append("%s %d (%s, %d%%)" % [HeroData.ROLL_NAMES[k], int(r[k]), HeroData.roll_grade(int(r[k])), roundi(w[k] * 100)])
	t += ", ".join(parts)
	if not highs.is_empty(): t += "\nStrong where it counts: " + ", ".join(highs)
	if not lows.is_empty(): t += "\nWeak where it counts: " + ", ".join(lows)
	t += "\nOther stats barely affect power for this role."
	t += "\nTemperament: %s%s" % [Traits.describe(hero), (" · " + temper) if temper != "" else " · neutral for this role"]
	t += "\nFit combines stat rolls (70%) and temperament (30%)."
	return t
