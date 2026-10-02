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

static func power_color(p: int) -> Color:
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
	var fit = HeroData.roll_fit(hero)
	var head = HBoxContainer.new(); head.add_theme_constant_override("separation", 10); parent.add_child(head)
	var pw = game.label(head, "POWER %d" % p, 15, power_color(p), false)
	pw.tooltip_text = "Power level: tier, level, abilities, how well the rolls suit a %s, temperament fit and scaling." % HeroData.species[hero.sp].role
	var tc = HeroData.roll_color(roundi(float(total) / HeroData.ROLL_KEYS.size()))
	game.label(head, "STATS %d/%d" % [total, HeroData.ROLL_MAX * HeroData.ROLL_KEYS.size()], 13, tc, false).tooltip_text = "Sum of all six stat rolls."
	var fit_text = "GREAT FIT" if fit >= 0.35 else ("GOOD FIT" if fit >= 0.1 else ("POOR FIT" if fit <= -0.25 else "OK FIT"))
	var fit_col = Color("6fe08a") if fit >= 0.1 else (Color("ff5e5e") if fit <= -0.25 else Color("d6e86a"))
	game.label(head, fit_text, 13, fit_col, false).tooltip_text = "How good the rolls are in the stats a %s actually uses (gold dots)." % HeroData.species[hero.sp].role
	if compact:
		var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 4); parent.add_child(row)
		for k in HeroData.ROLL_KEYS:
			var v = int(r[k]); var chip = PanelContainer.new(); row.add_child(chip)
			chip.add_theme_stylebox_override("panel", game.style(HeroData.roll_color(v).darkened(0.72), HeroData.roll_color(v) if w.has(k) else HeroData.roll_color(v).darkened(0.45), 5, 3, 1))
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
			var fa = HeroData.roll_fit(a); var fb = HeroData.roll_fit(b)
			if absf(fa - fb) > 0.001: return fa > fb
			return HeroData.power(a) > HeroData.power(b))
	return out

## A "Sort:" row of toggle buttons bound to game.desk_state.sort.
static func sort_bar(game: Node, parent: Node, modes: Array = ["Board", "Power", "Ideal"]) -> void:
	var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 8); parent.add_child(row)
	game.label(row, "SORT", 14, IDEAL, false)
	var names = {"Board": "Default", "Power": "Power level ▼", "Ideal": "★ Ideal trait"}
	for m in modes:
		var b = game.button(row, names.get(m, m), func(): game.desk_state.sort = m; game.render(), game.desk_state.get("sort", "Board") == m)
		b.tooltip_text = {"Board": "Original order", "Power": "Highest power level first", "Ideal": "Champions with their ideal temperament first, then the best role fit of their stat rolls"}.get(m, "")
