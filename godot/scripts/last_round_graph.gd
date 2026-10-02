class_name LastRoundGraph
extends Control
## Last round at a glance: four small panels (Damage, Crowd control, Healing, Damage taken), one bar
## per champion. Each panel has its own scale because the units differ (damage vs seconds of CC).

const METRICS := [
	{"key": "damage", "title": "DAMAGE", "color": Color("d9602f"), "fmt": "num"},
	{"key": "cc", "title": "CROWD CONTROL", "color": Color("8f62e6"), "fmt": "sec"},
	{"key": "healing", "title": "HEALING", "color": Color("2fa955"), "fmt": "num"},
	{"key": "taken", "title": "DAMAGE TAKEN", "color": Color("3f8fc8"), "fmt": "num"},
]
const INK := Color("e8e2d2")
const MUTED := Color("9fb0b8")
const GRID := Color(1, 1, 1, 0.08)

var rows: Array = []
var hover := Vector2i(-1, -1)   # (metric, champion)
var font: Font

static func make(game: Node, parent: Node, height := 132.0) -> LastRoundGraph:
	var rep = game.campaign.state.get("report", {})
	if rep.is_empty() or not rep.has("rows"): return null
	var mine = rep.rows.filter(func(r): return int(r.team) == 0)
	if mine.is_empty(): return null
	var g = LastRoundGraph.new(); g.rows = mine
	g.custom_minimum_size = Vector2(0, height); g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.mouse_filter = Control.MOUSE_FILTER_STOP; g.tooltip_text = " "
	parent.add_child(g); return g

func _ready() -> void:
	font = get_theme_default_font()
	mouse_exited.connect(func(): hover = Vector2i(-1, -1); queue_redraw())
	resized.connect(queue_redraw)

static func fmt(v: float, kind: String) -> String:
	if kind == "sec": return "%.1fs" % v
	if v >= 1000.0: return "%.1fk" % (v / 1000.0)
	return str(roundi(v))

func panel_rect(i: int) -> Rect2:
	var gap = 14.0; var w = (size.x - gap * 3) / 4.0
	return Rect2(i * (w + gap), 0, w, size.y)

func bar_rect(i: int, j: int, value: float, top: float) -> Rect2:
	var p = panel_rect(i); var n = rows.size()
	var plot = Rect2(p.position.x + 4, 30, p.size.x - 8, p.size.y - 30 - 16)
	var slot = plot.size.x / n; var bw = minf(22.0, slot - 8.0)
	var h = 0.0 if top <= 0.0 else plot.size.y * value / top
	h = maxf(h, 2.0) if value > 0.0 else 0.0
	return Rect2(plot.position.x + slot * j + (slot - bw) * 0.5, plot.end.y - h, bw, h)

func _draw() -> void:
	if rows.is_empty(): return
	for i in range(METRICS.size()):
		var m = METRICS[i]; var p = panel_rect(i)
		var top = 0.0; var total = 0.0
		for r in rows: top = maxf(top, float(r.get(m.key, 0.0))); total += float(r.get(m.key, 0.0))
		draw_string(font, Vector2(p.position.x + 4, 12), ("LAST ROUND · " if i == 0 else "") + m.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ffd36e") if i == 0 else MUTED)
		draw_string(font, Vector2(p.position.x + 4, 12), fmt(total, m.fmt), HORIZONTAL_ALIGNMENT_RIGHT, p.size.x - 8, 11, INK)
		var base_y = p.size.y - 16
		draw_line(Vector2(p.position.x + 4, base_y), Vector2(p.end.x - 4, base_y), GRID, 1.0)
		var best = -1
		for j in range(rows.size()):
			if float(rows[j].get(m.key, 0.0)) == top and top > 0.0: best = j
		for j in range(rows.size()):
			var v = float(rows[j].get(m.key, 0.0))
			var r = bar_rect(i, j, v, top)
			var col: Color = m.color if (hover == Vector2i(-1, -1) or hover == Vector2i(i, j)) else Color(m.color, 0.45)
			if r.size.y > 0.0:
				var sb = StyleBoxFlat.new(); sb.bg_color = col
				var rad = mini(4, int(r.size.x * 0.5)); sb.corner_radius_top_left = rad; sb.corner_radius_top_right = rad
				draw_style_box(sb, r)
			# Direct-label only the leader in each panel; hover reveals the rest.
			if j == best or hover == Vector2i(i, j):
				draw_string(font, Vector2(r.position.x - 12, r.position.y - 3), fmt(v, m.fmt), HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 24, 10, INK)
			var nm = str(rows[j].name).left(6)
			var slot_w = (p.size.x - 8) / rows.size()
			draw_string(font, Vector2(p.position.x + 4 + slot_w * j, p.size.y - 4), nm, HORIZONTAL_ALIGNMENT_CENTER, slot_w, 10, INK if hover == Vector2i(i, j) else MUTED)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var h = Vector2i(-1, -1)
		for i in range(METRICS.size()):
			var p = panel_rect(i)
			if not p.has_point(e.position): continue
			var slot = (p.size.x - 8) / rows.size()
			var j = clampi(int((e.position.x - p.position.x - 4) / slot), 0, rows.size() - 1)
			h = Vector2i(i, j)
		if h != hover: hover = h; queue_redraw()

func _get_tooltip(_at: Vector2) -> String:
	if hover.x < 0: return ""
	var r = rows[hover.y]
	return "%s · %s\nDamage %s · CC %s · Healing %s · Taken %s" % [r.name, HeroData.species[r.sp].n, fmt(r.get("damage", 0.0), "num"), fmt(r.get("cc", 0.0), "sec"), fmt(r.get("healing", 0.0), "num"), fmt(r.get("taken", 0.0), "num")]
