class_name StatHex
extends Control
## Six-stat hexagon for one champion. Each axis places the champion's real stat at its level against
## every species at that same level (centre = the weakest, rim = the strongest). The faint outline is
## the species with average rolls, so the gap between the two shows what this champion's rolls did.
## Stars mark the two axes where it excels; dots mark the stats its role relies on.

# Clockwise from the top-left corner, like a classic RPG stat chart.
const AXES := ["attack", "haste", "speed", "hp", "armor", "potency"]
const GUIDE := {
	"attack": {"name": "Damage", "does": "Basic-attack hit, and the base most skills multiply.", "scale": "Grows every level (+2.6 x the species' damage), shaped by its scaling curve."},
	"haste": {"name": "Attack speed", "does": "How often it attacks. More swings means more damage and more on-hit effects.", "scale": "Does not grow with level. Raise it with items and temperament."},
	"speed": {"name": "Move speed", "does": "How fast it reaches the back line, chases, or escapes.", "scale": "Does not grow with level. Raise it with items."},
	"hp": {"name": "Health", "does": "How much damage it can take before it falls.", "scale": "Grows every level (+24 x the species' health), shaped by its scaling curve."},
	"armor": {"name": "Armor", "does": "Cuts the damage of every hit it takes.", "scale": "Does not grow with level. Raise it with items or the Guardian evolution."},
	"potency": {"name": "Ability power", "does": "Strength of its skills: damage, healing, shields and control.", "scale": "From rolls and items. Each skill rank adds +20% power and an 8% shorter cooldown."},
}
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
var font: Font
static var _ranges := {}

## Effective value of each stat (bigger is better for every axis).
static func effective(h: Dictionary) -> Dictionary:
	var s = HeroData.stats(h)
	return {"attack": s.attack, "haste": 1.0 / maxf(0.05, s.interval), "speed": s.speed, "hp": s.hp, "armor": s.armor, "potency": HeroData.spell_factor(h)}

## Min/max of every stat across all species at a level, with average rolls (cached per level).
static func ranges(level: int) -> Dictionary:
	if _ranges.has(level): return _ranges[level]
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
	_ranges[level] = {"lo": lo, "hi": hi}
	return _ranges[level]

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
	var order = AXES.duplicate(); order.sort_custom(func(a, b): return values[a] > values[b])
	# Stars mark real strengths (Strong or better, up to two); a champion with none still shows its best stat.
	excels = order.slice(0, 2).filter(func(k): return values[k] >= 0.6)
	if excels.is_empty(): excels = [order[0]]
	mouse_exited.connect(func(): hover = -1; queue_redraw())
	resized.connect(queue_redraw)

func center() -> Vector2: return size * 0.5 + Vector2(0, 4)
func radius() -> float: return minf(size.x * 0.5 - 84.0, size.y * 0.5 - 26.0)

func corner(i: int, r: float) -> Vector2:
	# Flat-top hexagon: corners at 240, 300, 0, 60, 120, 180 degrees, starting top-left.
	var a = deg_to_rad(240.0 + 60.0 * i)
	return center() + Vector2(cos(a), sin(a)) * r

func _draw() -> void:
	if values.is_empty(): return
	var R = radius()
	var rim = PackedVector2Array(); for i in range(7): rim.append(corner(i % 6, R))
	draw_colored_polygon(rim.slice(0, 6), Color(0, 0, 0, 0.22))
	for f in [0.5]:
		var ring = PackedVector2Array(); for i in range(7): ring.append(corner(i % 6, R * f))
		draw_polyline(ring, SPOKE, 1.0, true)
	for i in range(3): draw_line(corner(i, R), corner(i + 3, R), SPOKE, 1.0, true)
	draw_polyline(rim, RIM, 2.5, true)
	# Species baseline (average rolls) as a faint outline.
	var ghost = PackedVector2Array()
	for i in range(7): ghost.append(corner(i % 6, R * (0.08 + 0.92 * baseline[AXES[i % 6]])))
	draw_polyline(ghost, GHOST, 1.5, true)
	# This champion.
	var poly = PackedVector2Array()
	for i in range(6): poly.append(corner(i, R * (0.08 + 0.92 * values[AXES[i]])))
	draw_colored_polygon(poly, FILL)
	var edge = poly.duplicate(); edge.append(poly[0]); draw_polyline(edge, EDGE, 2.0, true)
	var w = HeroData.role_weights(hero.sp)
	for i in range(6):
		var k = AXES[i]; var p = corner(i, R + 14.0)
		var name = ("★ " if k in excels else "") + GUIDE[k].name + (" •" if w.has(k) else "")
		var col = STAR if k in excels else LABEL
		if hover == i: col = Color.WHITE
		var fs = 14 if size.x >= 400 else 12
		var tw = font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var x = p.x - tw * 0.5
		if i == 2: x = p.x + 2.0                      # right corner: text runs outward
		elif i == 5: x = p.x - tw - 2.0               # left corner
		var y = p.y + 5.0
		if i in [0, 1]: y = p.y - 2.0                 # top corners sit above the rim
		elif i in [3, 4]: y = p.y + 14.0              # bottom corners sit below
		draw_string(font, Vector2(x, y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var best = -1; var d = INF
		for i in range(6):
			var dd = e.position.distance_to(corner(i, radius() * 0.75))
			if dd < d: d = dd; best = i
		if best != hover: hover = best; queue_redraw()

func _get_tooltip(_at: Vector2) -> String:
	if hover < 0: return ""
	var k = AXES[hover]; var g = GUIDE[k]
	return "%s · %s for its level\n%s\n%s" % [g.name, grade(values[k]), g.does, g.scale]

## Stat guide: one line per stat with this champion's grade, what the stat does and how it scales.
static func guide(game: Node, parent: Node, h: Dictionary, compact := false) -> void:
	var v = normalized(h); var w = HeroData.role_weights(h.sp)
	var grid = GridContainer.new(); grid.columns = 2 if compact else 3
	grid.add_theme_constant_override("h_separation", 12); grid.add_theme_constant_override("v_separation", 4); parent.add_child(grid)
	for k in AXES:
		var g = GUIDE[k]
		var n = game.label(grid, ("• " if w.has(k) else "  ") + g.name, 13 if compact else 14, Color("ffd36e") if w.has(k) else Color.WHITE, false)
		n.custom_minimum_size.x = 112 if compact else 120; n.mouse_filter = Control.MOUSE_FILTER_STOP
		n.tooltip_text = g.does + "\n" + g.scale + ("\nKey stat for a " + HeroData.species[h.sp].role + "." if w.has(k) else "")
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
		var s = HeroData.stats(c); hp.append(str(roundi(s.hp))); dmg.append(str(roundi(s.attack)))
	game.label(row, "SCALING  ·  " + Traits.scaling_text(h.sp) + "  ·  " + Traits.info(h.sp).calling, 13, Color("ffd36e"), false)
	game.label(row, "Level %s" % "  →  ".join(levels.map(func(x): return str(x))), 13, Color("9fb0b8"), false)
	game.label(row, "Health %s     Damage %s" % ["  →  ".join(hp), "  →  ".join(dmg)], 14, Color.WHITE, false)
	var curve = Traits.score(h)
	var note = "Strong from the first cup; its lead shrinks later." if curve <= 4.0 else ("Starts slower and keeps getting stronger into the late cups." if curve >= 7.0 else "Even growth across the tour.")
	game.label(row, note, 12, Color("b9c6cc"), false)
