class_name Crest
extends Control
## A guild's heraldic crest: shield shape, field division, two tinctures, a metal trim and an
## emblem (a creature, or the guild's monogram). Drawn procedurally so it scales from a 24px
## header badge to a 300px charter preview.
var data: Dictionary = {}
var guild_name := ""

const SHAPES := ["Heater", "Kite", "Round", "Banner", "Roundel", "Tower"]
const PATTERNS := ["Plain", "Per pale", "Per fess", "Chevron", "Quarterly", "Per bend", "Saltire", "Chief", "Pall", "Bordure"]
const TINCTURES := {
	"Gules": "a3242c", "Azure": "1f4f9a", "Vert": "2f7a46", "Purpure": "5e2f8a", "Sable": "1a1a22", "Tenné": "c06a1f",
	"Celeste": "4aa3d8", "Sanguine": "6e1a24", "Murrey": "8a2f5e", "Or": "d9a838", "Argent": "dfe4ea", "Ash": "6b6f78",
}
const TINCTURE_ORDER := ["Gules", "Azure", "Vert", "Purpure", "Sable", "Tenné", "Celeste", "Sanguine", "Murrey", "Or", "Argent", "Ash"]
const METALS := {"Gold": "e8c27a", "Silver": "d8e0e8", "Bronze": "c98a52", "Obsidian": "2a2630"}
const METAL_ORDER := ["Gold", "Silver", "Bronze", "Obsidian"]

static func emblems() -> Array:
	HeroData.load_data()
	return ["Monogram"] + HeroData.species.keys()

static func default_for(name_value: String) -> Dictionary:
	var h = abs(hash(name_value + "|crest"))
	var em = emblems()
	return {"shape": SHAPES[h % SHAPES.size()], "pattern": PATTERNS[(h / 7) % PATTERNS.size()],
		"primary": TINCTURE_ORDER[(h / 31) % 9], "secondary": TINCTURE_ORDER[9 + (h / 131) % 3],
		"metal": METAL_ORDER[(h / 17) % 3], "emblem": em[1 + (h / 263) % (em.size() - 1)]}

static func of_campaign(c: Campaign) -> Dictionary:
	var d = c.state.get("crest", {})
	return d if d is Dictionary and not d.is_empty() else default_for(str(c.state.get("name", "Manitoria")))

static func make(parent: Node, crest_data: Dictionary, name_value: String, px: Vector2) -> Crest:
	var c = Crest.new(); c.data = crest_data; c.guild_name = name_value; c.custom_minimum_size = px
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE; c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(c); return c

var _settle := 4
var _emblem: Control
var _shadow: Control

func _ready() -> void:
	resized.connect(func(): queue_redraw(); _place_emblem())
	_build_emblem(); _place_emblem()

## The emblem lives in child nodes (drawn above the shield) so textures and glyphs batch cleanly.
func _build_emblem() -> void:
	var em = str(data.get("emblem", "Monogram"))
	var metal = Color(METALS.get(data.get("metal", "Gold"), "e8c27a"))
	if em != "Monogram" and ResourceLoader.exists("res://assets/portraits/%s.png" % em):
		for i in range(2):
			var t = TextureRect.new(); t.texture = load("res://assets/portraits/%s.png" % em)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if i == 0: t.modulate = Color(0, 0, 0, 0.55); _shadow = t
			else: _emblem = t
			add_child(t)
	else:
		var l = Label.new(); l.text = Crest.monogram(guild_name); l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", load("res://assets/fonts/uncialantiqua.ttf"))
		l.add_theme_color_override("font_color", metal); l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
		add_child(l); _emblem = l

func _place_emblem() -> void:
	if _emblem == null or size.x < 4: return
	var es = minf(size.x, size.y) * (0.62 if _emblem is Label else 0.74)
	var ec = Vector2(size.x * 0.5, size.y * (0.5 if data.get("shape", "") == "Roundel" else 0.47))
	_emblem.position = ec - Vector2(es, es) * 0.5; _emblem.size = Vector2(es, es)
	if _shadow: _shadow.position = _emblem.position + Vector2(0, es * 0.03); _shadow.size = _emblem.size
	if _emblem is Label:
		_emblem.text = Crest.monogram(guild_name)
		var fs = int(es * (0.62 if _emblem.text.length() <= 2 else 0.46))
		_emblem.add_theme_font_size_override("font_size", fs); _emblem.add_theme_constant_override("outline_size", maxi(2, fs / 9))

func _process(_d: float) -> void:
	# Glyph atlases and textures can arrive a frame late; redraw a few times, then rest.
	queue_redraw(); _place_emblem(); _settle -= 1
	if _settle <= 0: set_process(false)

func outline_points(box: Vector2) -> PackedVector2Array:
	var w = box.x; var h = box.y; var pts = PackedVector2Array()
	match str(data.get("shape", "Heater")):
		"Kite":
			pts = [Vector2(0.06, 0.06), Vector2(0.94, 0.06), Vector2(0.9, 0.42), Vector2(0.5, 0.98), Vector2(0.1, 0.42)]
		"Round":
			pts = [Vector2(0.06, 0.04), Vector2(0.94, 0.04)]
			for i in range(17):
				var a = PI * float(i) / 16.0
				pts.append(Vector2(0.5 + 0.44 * cos(a), 0.52 + 0.44 * sin(a)))
		"Banner":
			pts = [Vector2(0.1, 0.02), Vector2(0.9, 0.02), Vector2(0.9, 0.98), Vector2(0.5, 0.78), Vector2(0.1, 0.98)]
		"Roundel":
			for i in range(40):
				var a = TAU * float(i) / 40.0
				pts.append(Vector2(0.5 + 0.46 * cos(a), 0.5 + 0.46 * sin(a)))
		"Tower":
			pts = [Vector2(0.06, 0.16), Vector2(0.2, 0.16), Vector2(0.2, 0.03), Vector2(0.38, 0.03), Vector2(0.38, 0.16), Vector2(0.62, 0.16), Vector2(0.62, 0.03), Vector2(0.8, 0.03), Vector2(0.8, 0.16), Vector2(0.94, 0.16), Vector2(0.94, 0.62), Vector2(0.5, 0.98), Vector2(0.06, 0.62)]
		_:
			pts = [Vector2(0.06, 0.04), Vector2(0.94, 0.04), Vector2(0.94, 0.5)]
			for i in range(1, 12):
				var t = float(i) / 12.0
				pts.append(Vector2(0.94 - 0.44 * t, 0.5 + 0.46 * sin(t * PI * 0.5)))
			for i in range(1, 12):
				var t = float(i) / 12.0
				pts.append(Vector2(0.5 - 0.44 * t, 0.96 - 0.46 * (1.0 - cos(t * PI * 0.5))))
			pts.append(Vector2(0.06, 0.5))
	var out = PackedVector2Array()
	for p in pts: out.append(Vector2(p.x * w, p.y * h))
	return out

func division(box: Vector2) -> Array:
	var w = box.x; var h = box.y
	var r = func(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> PackedVector2Array: return PackedVector2Array([Vector2(a.x * w, a.y * h), Vector2(b.x * w, b.y * h), Vector2(c.x * w, c.y * h), Vector2(d.x * w, d.y * h)])
	match str(data.get("pattern", "Plain")):
		"Per pale": return [r.call(Vector2(0.5, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0.5, 1))]
		"Per fess": return [r.call(Vector2(0, 0.5), Vector2(1, 0.5), Vector2(1, 1), Vector2(0, 1))]
		"Chevron": return [PackedVector2Array([Vector2(0, 0.78 * h), Vector2(0.5 * w, 0.36 * h), Vector2(w, 0.78 * h), Vector2(w, h), Vector2(0.5 * w, 0.58 * h), Vector2(0, h)])]
		"Quarterly": return [r.call(Vector2(0.5, 0), Vector2(1, 0), Vector2(1, 0.5), Vector2(0.5, 0.5)), r.call(Vector2(0, 0.5), Vector2(0.5, 0.5), Vector2(0.5, 1), Vector2(0, 1))]
		"Per bend": return [PackedVector2Array([Vector2(0, 0), Vector2(w, h), Vector2(0, h)])]
		"Saltire": return [PackedVector2Array([Vector2(0, 0), Vector2(0.12 * w, 0), Vector2(w, 0.88 * h), Vector2(w, h), Vector2(0.88 * w, h), Vector2(0, 0.12 * h)]), PackedVector2Array([Vector2(w, 0), Vector2(w, 0.12 * h), Vector2(0.12 * w, h), Vector2(0, h), Vector2(0, 0.88 * h), Vector2(0.88 * w, 0)])]
		"Chief": return [r.call(Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.3), Vector2(0, 0.3))]
		"Pall": return [PackedVector2Array([Vector2(0, 0), Vector2(0.14 * w, 0), Vector2(0.5 * w, 0.4 * h), Vector2(0.86 * w, 0), Vector2(w, 0), Vector2(0.58 * w, 0.5 * h), Vector2(0.58 * w, h), Vector2(0.42 * w, h), Vector2(0.42 * w, 0.5 * h)])]
		"Bordure": return ["bordure"]
	return []

func _draw() -> void:
	var box = size
	if box.x < 4: return
	var shield = outline_points(box)
	var primary = Color(TINCTURES.get(data.get("primary", "Azure"), "1f4f9a"))
	var secondary = Color(TINCTURES.get(data.get("secondary", "Or"), "d9a838"))
	var metal = Color(METALS.get(data.get("metal", "Gold"), "e8c27a"))
	# Drop shadow, field, division.
	var shadow = PackedVector2Array(); for p in shield: shadow.append(p + Vector2(0, box.y * 0.025))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.45))
	draw_colored_polygon(shield, primary)
	for part in division(box):
		if part is String:
			var inner = PackedVector2Array(); var c = box * 0.5
			for p in shield: inner.append(c + (p - c) * 0.8)
			for piece in Geometry2D.clip_polygons(shield, inner): draw_colored_polygon(piece, secondary)
		else:
			for piece in Geometry2D.intersect_polygons(shield, part): draw_colored_polygon(piece, secondary)
	# Soft top-left sheen.
	var sheen = PackedVector2Array([Vector2(0, 0), Vector2(box.x * 0.65, 0), Vector2(0, box.y * 0.6)])
	for piece in Geometry2D.intersect_polygons(shield, sheen): draw_colored_polygon(piece, Color(1, 1, 1, 0.07))
	# Metal trim.
	var line = shield.duplicate(); line.append(shield[0])
	var bw = maxf(1.5, minf(box.x, box.y) * 0.035)
	draw_polyline(line, metal.darkened(0.45), bw * 1.7, true)
	draw_polyline(line, metal, bw, true)

static func monogram(name_value: String) -> String:
	var words = name_value.strip_edges().split(" ", false)
	var t = ""
	for w in words.slice(0, 3): t += w[0].to_upper()
	return t if t != "" else "M"
