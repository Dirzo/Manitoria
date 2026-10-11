class_name StatHex
extends Control
## Six-stat hexagon for one champion. Each axis places the champion's real stat at its level against
## every species at that same level (centre = the weakest, rim = the strongest). The faint outline is
## the species with average rolls, so the gap between the two shows what this champion's rolls did.
## Stars mark the two axes where it excels; dots mark the stats its role relies on.

# Clockwise from the top-left corner, like a classic RPG stat chart. Keys are the save's roll keys:
# attack = AD, haste = AS, potency = AP, speed = Mana, hp = HP, armor = Resistance.
const AXES := ["attack", "haste", "crit", "potency", "speed", "hp", "armor", "size"]
const N := 8
const SHORT := {"attack": "AD", "haste": "AS", "potency": "AP", "speed": "MANA", "hp": "HP", "armor": "RES", "size": "SIZE", "crit": "CRIT"}
const GUIDE := {
	"attack": {"name": "AD", "does": "Attack damage: each basic attack, and every signature number marked % AD.", "scale": "+2% base per level, plus AD cards, rolls, temperament and items."},
	"haste": {"name": "AS", "does": "Attack speed: attacks per second. More attacks also means more mana, so faster casts.", "scale": "AS cards, rolls, temperament and items."},
	"potency": {"name": "AP", "does": "Ability power: every signature number marked AP. Everyone starts at 100.", "scale": "AP cards, rolls and items. Signature AP numbers also grow 4.5% per level."},
	"speed": {"name": "Mana", "does": "Mana gain: multiplies all mana earned, so the signature casts more often.", "scale": "Mana cards, rolls, temperament and items."},
	"hp": {"name": "HP", "does": "Health: damage it can take before it falls.", "scale": "+3% base per level, plus HP cards, rolls, temperament and items."},
	"size": {"name": "Size", "does": "Body size. Above its natural size, every +10% gives +5% HP, +5% AD and wider attacks and spells; big champions are easier to hit with area effects.", "scale": "Set by role (tanks big, assassins small); Size cards, Giant items and temperament."},
	"crit": {"name": "Crit", "does": "Chance for a basic attack to crit for 2× (more with Crit items). Over 100% turns into extra crit damage.", "scale": "Set by role (assassins and carries high, tanks low); Crit cards, Crit items and temperament."},
	"armor": {"name": "Resistance", "does": "Reduces all damage: Resistance ÷ (100 + Resistance). 50 blocks 33%, 100 blocks 50%. True damage ignores it.", "scale": "Resistance cards, rolls and items."},
}
const BUILD_TO_AXIS := {"ad": "attack", "as": "haste", "ap": "potency", "mana": "speed", "hp": "hp", "res": "armor", "size": "size", "crit": "crit"}

## The axes this champion's signature scales with (marked with a dot).
static func key_axes(sp: String) -> Array:
	return Signatures.build_keys(sp).map(func(k): return BUILD_TO_AXIS[k])

const FILL := Color(0.22, 0.75, 0.39, 0.78)
const EDGE := Color(0.12, 0.45, 0.24)
const GHOST := Color(1, 1, 1, 0.55)
const RIM := Color(0.92, 0.9, 0.85, 0.9)
const SPOKE := Color(0.92, 0.9, 0.85, 0.28)
const LABEL := Color("e8e2d2")
const STAR := Color("ffd36e")

var hero: Dictionary = {}
var values := {}      # axis -> 0..1 for this champion
var baseline := {}    # axis -> 0..1 for the species with average rolls
var excels: Array = []
var hover := -1
var prior_values := {}
var improvement := {}
var reveal := 1.0
var font: Font
static var _ranges := {}

## Effective value of each stat (bigger is better for every axis).
static func effective(h: Dictionary) -> Dictionary:
	var s = HeroData.stats(h)
	return {"attack": s.attack, "haste": float(s["as"]), "speed": float(s.mana), "hp": s.hp, "armor": float(s.res), "potency": float(s.ap), "size": float(s.size), "crit": float(s.crit) + (float(s.crit_damage) - 2.0) * 0.25}

## Min/max of every stat across all species at a level, with average rolls (cached per level).
static func ranges(level: int) -> Dictionary:
	var cache_key=str(level)+"|"+JSON.stringify(League.run_tiers)
	if _ranges.has(cache_key): return _ranges[cache_key]
	HeroData.load_data()
	var lo = {}; var hi = {}
	for sp in HeroData.species:
		var h = HeroData.make_hero(sp, "range_" + sp, "x", level)
		h.rolls = {}
		for k in HeroData.ROLL_KEYS: h.rolls[k] = 15.5
		h.trait = "Neutral"
		var e = effective(h)
		for k in AXES:
			lo[k] = minf(lo.get(k, INF), e[k]); hi[k] = maxf(hi.get(k, -INF), e[k])
	# Leave room past the species extremes for great (or poor) rolls, items and temperament.
	for k in AXES:
		var span = maxf(0.0001, hi[k] - lo[k]); lo[k] -= span * 0.15; hi[k] += span * 0.15
	# AP and Mana start equal for everyone, so their scale comes from what cards and items can add.
	lo.potency = 70.0; hi.potency = 130.0 + 6.0 * level
	lo.speed = 0.80; hi.speed = 1.20 + 0.025 * level
	lo.size = 0.80; hi.size = 1.30 + 0.02 * level
	lo.crit = 0.0; hi.crit = 0.30 + 0.015 * level
	_ranges[cache_key] = {"lo": lo, "hi": hi}
	return _ranges[cache_key]

static func normalized(h: Dictionary) -> Dictionary:
	var r = ranges(int(h.get("level", 1))); var e = effective(h); var out = {}
	for k in AXES: out[k] = clampf((e[k] - r.lo[k]) / maxf(0.0001, r.hi[k] - r.lo[k]), 0.0, 1.0)
	return out

## The species with average rolls and a neutral temperament, at the same level and gear.
static func species_baseline(h: Dictionary) -> Dictionary:
	var b = h.duplicate(true); b.rolls = {}
	for k in HeroData.ROLL_KEYS: b.rolls[k] = 15.5
	b.trait = "Neutral"
	return normalized(b)

## Plain-language rank of a 0..1 axis value.
static func grade(v: float) -> String:
	if v >= 0.8: return "Elite"
	if v >= 0.62: return "Strong"
	if v >= 0.4: return "Average"
	if v >= 0.22: return "Low"
	return "Very low"

static func grade_color(v: float) -> Color:
	if v >= 0.8: return Color("ffd36e")
	if v >= 0.62: return Color("6fe08a")
	if v >= 0.4: return Color("d6e86a")
	if v >= 0.22: return Color("ffa451")
	return Color("ff5e5e")

static func make(parent: Node, h: Dictionary, px: Vector2) -> StatHex:
	var g = StatHex.new(); g.hero = h; g.custom_minimum_size = px
	g.mouse_filter = Control.MOUSE_FILTER_STOP; g.tooltip_text = " "
	parent.add_child(g); return g

func _ready() -> void:
	font = get_theme_default_font()
	values = normalized(hero); baseline = species_baseline(hero)
	var feedback=hero.get("copy_feedback",{})
	if not feedback.is_empty():
		var bounds=ranges(int(hero.level))
		for k in AXES:
			prior_values[k]=clampf((feedback.before[k]-bounds.lo[k])/maxf(.0001,bounds.hi[k]-bounds.lo[k]),0,1)
			improvement[k]=feedback.after[k]-feedback.before[k]
		reveal=0.0
		var tween=create_tween();tween.tween_property(self,"reveal",1.0,.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func():queue_redraw())
		set_process(true)
	var order = AXES.duplicate(); order.sort_custom(func(a, b): return values[a] > values[b])
	# Stars mark real strengths (Strong or better, up to two); a champion with none still shows its best stat.
	excels = order.slice(0, 2).filter(func(k): return values[k] >= 0.6)
	if excels.is_empty(): excels = [order[0]]
	mouse_exited.connect(func(): hover = -1; queue_redraw())
	resized.connect(queue_redraw)

func _process(_delta: float) -> void:
	if reveal<1.0:queue_redraw()
	else:set_process(false)

func center() -> Vector2: return size * 0.5 + Vector2(0, 4)
func radius() -> float: return minf(size.x * 0.5 - 84.0, size.y * 0.5 - 26.0)

func corner(i: int, r: float) -> Vector2:
	# Octagon: eight axes, starting just left of the top and running clockwise.
	var a = deg_to_rad(-112.5 + 45.0 * i)
	return center() + Vector2(cos(a), sin(a)) * r

func _draw() -> void:
	if values.is_empty(): return
	var R = radius()
	var rim = PackedVector2Array(); for i in range(N + 1): rim.append(corner(i % N, R))
	draw_colored_polygon(rim.slice(0, 6), Color(0, 0, 0, 0.22))
	for f in [0.5]:
		var ring = PackedVector2Array(); for i in range(N + 1): ring.append(corner(i % N, R * f))
		draw_polyline(ring, SPOKE, 1.0, true)
	for i in range(N / 2): draw_line(corner(i, R), corner(i + N / 2, R), SPOKE, 1.0, true)
	draw_polyline(rim, RIM, 2.5, true)
	# Species baseline (average rolls) as a faint outline.
	var ghost = PackedVector2Array()
	for i in range(N + 1): ghost.append(corner(i % N, R * (0.08 + 0.92 * baseline[AXES[i % N]])))
	draw_polyline(ghost, GHOST, 1.5, true)
	# Gold outline holds the pre-purchase stats while the current polygon expands.
	if not prior_values.is_empty():
		var prior=PackedVector2Array()
		for i in range(N + 1):prior.append(corner(i%N,R*(.08+.92*prior_values[AXES[i%N]])))
		draw_polyline(prior,STAR,2.0,true)
	# This champion.
	var poly = PackedVector2Array()
	for i in range(N): poly.append(corner(i, R * (0.08 + 0.92 * lerpf(prior_values.get(AXES[i],values[AXES[i]]),values[AXES[i]],reveal))))
	draw_colored_polygon(poly, FILL)
	var edge = poly.duplicate(); edge.append(poly[0]); draw_polyline(edge, EDGE, 2.0, true)
	var w = key_axes(hero.sp)
	for i in range(N):
		var k = AXES[i]; var p = corner(i, R + 14.0)
		var name = ("★ " if k in excels else "") + (SHORT[k] if size.x<500 else GUIDE[k].name) + (" •" if k in w else "")
		if improvement.get(k,0.0)>.00001:
			var delta=float(improvement[k])
			name+=" +%.1fpp"%(delta*100) if k=="armor" else " +%.1f%%"%(delta/maxf(.0001,hero.copy_feedback.before[k])*100) if k=="speed" else " +%.1f"%delta
		var col = Color("8effac") if improvement.get(k,0.0)>.00001 else STAR if k in excels else LABEL
		if hover == i: col = Color.WHITE
		var fs = 14 if size.x >= 400 else 12
		var tw = font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var x = p.x - tw * 0.5
		if i in [2, 3]: x = p.x + 2.0                 # right side: text runs outward
		elif i in [6, 7]: x = p.x - tw - 2.0          # left side
		var y = p.y + 5.0
		if i in [0, 1]: y = p.y - 2.0                 # top corners sit above the rim
		elif i in [4, 5]: y = p.y + 14.0              # bottom corners sit below
		draw_string(font, Vector2(x, y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var best = -1; var d = INF
		for i in range(N):
			var dd = e.position.distance_to(corner(i, radius() * 0.75))
			if dd < d: d = dd; best = i
		if best != hover: hover = best; queue_redraw()

func _get_tooltip(_at: Vector2) -> String:
	if hover < 0: return ""
	var k = AXES[hover]; var g = GUIDE[k]
	return "%s · %s for its level\n%s\n%s" % [g.name, grade(values[k]), g.does, g.scale]

## Stat guide: one line per stat with this champion's grade, what the stat does and how it scales.
static func guide(game: Node, parent: Node, h: Dictionary, compact := false) -> void:
	var v = normalized(h); var w = key_axes(h.sp)
	var grid = GridContainer.new(); grid.columns = 2 if compact else 3
	grid.add_theme_constant_override("h_separation", 12); grid.add_theme_constant_override("v_separation", 4); parent.add_child(grid)
	for k in AXES:
		var g = GUIDE[k]
		var n = game.label(grid, ("• " if k in w else "  ") + g.name, 13 if compact else 14, Color("ffd36e") if k in w else Color.WHITE, false)
		n.custom_minimum_size.x = 112 if compact else 120; n.mouse_filter = Control.MOUSE_FILTER_STOP
		n.tooltip_text = g.does + "\n" + g.scale + ("\nIts signature scales with this." if k in w else "")
		var gl = game.label(grid, grade(v[k]), 13 if compact else 14, grade_color(v[k]), false); gl.custom_minimum_size.x = 58 if compact else 70
		gl.tooltip_text = n.tooltip_text; gl.mouse_filter = Control.MOUSE_FILTER_STOP
		if not compact:
			var d = game.label(grid, g.does, 12, Color("b9c6cc"), false); d.custom_minimum_size.x = 250
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; d.tooltip_text = n.tooltip_text; d.mouse_filter = Control.MOUSE_FILTER_STOP

## How this champion grows: Health and Damage now, at level 10 and at level 20, plus its curve.
static func scaling(game: Node, parent: Node, h: Dictionary) -> void:
	var row = VBoxContainer.new(); row.add_theme_constant_override("separation", 2); parent.add_child(row)
	var levels = [int(h.level)]
	for l in [10, 20]:
		if l > int(h.level): levels.append(l)
	var hp = []; var dmg = []
	for l in levels:
		var c = h.duplicate(true); c.level = l
		if l != int(h.level): c.cards = {}
		var s = HeroData.stats(c); hp.append(str(roundi(s.hp))); dmg.append(str(roundi(s.attack)))
	game.label(row, "SCALING  ·  " + Traits.scaling_text(h.sp) + "  ·  " + Traits.info(h.sp).calling, 13, Color("ffd36e"), false)
	game.label(row, "Level %s" % "  →  ".join(levels.map(func(x): return str(x))), 13, Color("9fb0b8"), false)
	game.label(row, "HP %s     AD %s   (before level-up cards)" % ["  →  ".join(hp), "  →  ".join(dmg)], 14, Color.WHITE, false)
	var curve = Traits.score(h)
	var note = "Strong from the first cup; its lead shrinks later." if curve <= 4.0 else ("Starts slower and keeps getting stronger into the late cups." if curve >= 7.0 else "Even growth across the tour.")
	game.label(row, note, 12, Color("b9c6cc"), false)

## "How stats work": the full explainer, reachable from the headliner pick, the draft board and the
## champion view. Optional champion shows its own numbers next to each rule.
static func explain(game: Node, h: Dictionary = {}) -> void:
	var dialog = GearUI.modal(game, "How stats work", Vector2(1180, 780))
	var scroll = ScrollContainer.new(); scroll.custom_minimum_size = Vector2(1120, 660); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; dialog.box.add_child(scroll)
	var box = VBoxContainer.new(); box.size_flags_horizontal = Control.SIZE_EXPAND_FILL; box.add_theme_constant_override("separation", 8); scroll.add_child(box)
	var head = func(t: String): game.label(box, t, 17, Color("ffd36e"), false)
	var para = func(t: String):
		var l = game.label(box, t, 14, Color("dfe8ec"), true); l.custom_minimum_size.x = 1080
	head.call("THE EIGHT STATS")
	var grid = GridContainer.new(); grid.columns = 3; grid.add_theme_constant_override("h_separation", 16); grid.add_theme_constant_override("v_separation", 6); box.add_child(grid)
	for k in AXES:
		var g = GUIDE[k]
		game.label(grid, g.name, 15, Color.WHITE, false).custom_minimum_size.x = 130
		var d = game.label(grid, g.does, 13, Color("c9d6dc"), true); d.custom_minimum_size.x = 400
		var sc = game.label(grid, g.scale, 13, Color("9fd8ff"), true); sc.custom_minimum_size.x = 500
	head.call("MANA AND THE SIGNATURE")
	para.call("Every champion has one signature ability, cast the moment its mana bar fills, then the bar empties. Mana comes from basic attacks (+10 each) and from taking damage (1% of the hit before Resistance plus 3% after, up to 40). The Mana stat multiplies everything earned. A silenced champion earns no mana, and nobody earns mana while a signature is channeling.")
	para.call("Signature numbers say what they scale with: \"300% AD\" grows with AD; \"150 AP\" is 150 at 100 AP and grows with AP and level. The champion card always shows the current number.")
	head.call("LEVEL-UP CARDS")
	para.call("Every level-up deals three cards, each a different stat at a random rarity (Common 55%, Rare 28%, Epic 13%, Legendary 4%; better from level 15). Keep one. Each level also adds +3% base HP and +2% base AD. Evolutions come at level %d and the Apex at level %d. Card rerolls redraw the three cards: every run starts with %d, and dungeon elites and Wardens give more." % [HeroData.EVOLVE_LEVEL, HeroData.APEX_LEVEL, StatCards.REROLLS_START])
	var grades = HBoxContainer.new(); grades.add_theme_constant_override("separation", 10); box.add_child(grades)
	for r in StatCards.RARITIES:
		var c = Color(StatCards.COLORS[r]); var p = PanelContainer.new(); grades.add_child(p)
		p.add_theme_stylebox_override("panel", game.style(c.darkened(0.74), c, 6, 6, 1))
		game.label(p, "%s  AD +%d · HP +%d" % [r, StatCards.VALUES.ad[StatCards.RARITIES.find(r)], StatCards.VALUES.hp[StatCards.RARITIES.find(r)]], 13, c, false)
	head.call("ROLLS · 0 to 31")
	para.call("Every champion is born with a roll from 0 to 31 in each stat; 15-16 is average. A roll changes HP and AD by up to ±18%, AS by ±12%, AP by ±12, Mana by ±10% and Resistance by ±5. Rarer champions never roll very low: Legendary rolls start at %d, Epic at %d and Common at %d." % [HeroData.ROLL_FLOOR.Legendary, HeroData.ROLL_FLOOR.Epic, HeroData.ROLL_FLOOR.Common])
	head.call("ROLE, TEMPERAMENT AND FIT")
	para.call("• marks the stats its signature scales with. Temperament nudges stats too (for example faster attacks but less health). A champion is a GOOD or GREAT fit when its best rolls land on the stats its signature wants and its temperament suits its role; both count.")
	head.call("POWER")
	para.call("Power (1 to 100) sums it all up: level, rolls, cards and evolutions. New champions top out around the low 30s and the best late-tour champions reach 100. Its colour shows how good the rolls are for that champion, whatever its level.")
	head.call("THE HEXAGON")
	para.call("The hexagon compares this champion's real stats with every species at the same level: centre is the weakest, the rim the strongest. The faint outline is the same species with average rolls, so the gap shows what its rolls did. Stars mark where it excels.")
	if not h.is_empty():
		head.call("%s RIGHT NOW" % str(h.name).to_upper())
		var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 16); box.add_child(row)
		make(row, h, Vector2(420, 300))
		var side = VBoxContainer.new(); row.add_child(side)
		TraitUI.rolls(game, side, h, false)
		scaling(game, side, h)

## Small "?  How stats work" button.
static func help_button(game: Node, parent: Node, h: Dictionary = {}, text := "?  How stats work") -> Button:
	var b = game.button(parent, text, func(): explain(game, h))
	b.tooltip_text = "The eight stats, mana and the signature, level-up cards, rolls, fit and Power."
	return b
