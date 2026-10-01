class_name SplashArt
extends Control
# League-style champion art: the creature's element splash, cover-cropped around its head
# so it reads at any size (tall card, wide banner or square icon), with a tier-coloured frame.
var sp = ""
var framed = true
var caption = ""          # optional name printed over the bottom fade
var focus = Vector2(0.5, 0.46)
var backdrop_only = false  # just the element scene, for 3D models to stand in front of
var _tex: Texture2D
var _bg: Texture2D
var _fg: Texture2D

static func path_for(species: String) -> String:
 return "res://assets/splash/%s.jpg" % species

static func make(parent: Node, species: String, min_size: Vector2, expand := false, show_frame := true) -> SplashArt:
 var art = SplashArt.new(); art.sp = species; art.framed = show_frame; art.custom_minimum_size = min_size
 art.mouse_filter = Control.MOUSE_FILTER_IGNORE
 if expand: art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 else: art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 parent.add_child(art); return art

const HEAD_Y = {}

func _ready() -> void:
 if HEAD_Y.has(sp) and focus == Vector2(0.5, 0.46): focus.y = HEAD_Y[sp]
 var p = path_for(sp)
 if backdrop_only: p = "res://assets/splash/bg/%s.jpg" % SoundDesign.SPECIES_FAMILY.get(sp, "beast")
 _tex = load(p) if ResourceLoader.exists(p) else load("res://assets/portraits/%s.png" % sp)
 var lb = "res://assets/splash/layers/%s_bg.jpg" % sp; var lf = "res://assets/splash/layers/%s_fg.png" % sp
 if not backdrop_only and ResourceLoader.exists(lb) and ResourceLoader.exists(lf): _bg = load(lb); _fg = load(lf)
 resized.connect(queue_redraw)

func _draw() -> void:
 if _tex == null or size.x < 2 or size.y < 2: return
 var ts = _tex.get_size(); var box = size
 # Cover: scale so the art fills the box, then slide the window toward the head.
 var scale_f = max(box.x / ts.x, box.y / ts.y)
 var src_size = box / scale_f
 var src_pos = Vector2(clamp(ts.x * focus.x - src_size.x * 0.5, 0, ts.x - src_size.x), clamp(ts.y * focus.y - src_size.y * 0.5, 0, ts.y - src_size.y))
 if _fg != null and box.x / box.y > 0.8:
  # Wide or square slot: fill with the element scene, then fit the whole creature inside.
  draw_texture_rect_region(_bg, Rect2(Vector2.ZERO, box), Rect2(src_pos, src_size))
  var fit = minf(box.y * 0.98 / ts.y, box.x / ts.x * 1.25)
  var fs = ts * fit
  draw_texture_rect(_fg, Rect2(Vector2((box.x - fs.x) * 0.5, box.y - fs.y + box.y * 0.02), fs), false)
 else:
  draw_texture_rect_region(_tex, Rect2(Vector2.ZERO, box), Rect2(src_pos, src_size))
 # Bottom fade so names and badges sit on darkness.
 var fade_h = box.y * (0.42 if caption != "" else 0.22)
 var top_y = box.y - fade_h
 draw_polygon(PackedVector2Array([Vector2(0, top_y), Vector2(box.x, top_y), box, Vector2(0, box.y)]), PackedColorArray([Color(0.01,0.015,0.03,0), Color(0.01,0.015,0.03,0), Color(0.01,0.015,0.03,0.92), Color(0.01,0.015,0.03,0.92)]))
 if caption != "":
  var font = load("res://assets/fonts/uncialantiqua.ttf"); var fs = int(clamp(box.x / 10.5, 13, 24))
  var w = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
  draw_string_outline(font, Vector2((box.x - w) * 0.5, box.y - fs * 0.6), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, 0.85))
  draw_string(font, Vector2((box.x - w) * 0.5, box.y - fs * 0.6), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("ffe9b8"))
 if framed:
  var tier = League.tier(sp)
  var c = Color(League.TIER_COLOR.get(tier, "9b8053"))
  var wdt = 3.0 if tier == "Legendary" else 2.0
  draw_rect(Rect2(Vector2.ONE * wdt * 0.5, box - Vector2.ONE * wdt), c, false, wdt)
  draw_rect(Rect2(Vector2.ONE * (wdt + 1.5), box - Vector2.ONE * (wdt * 2 + 3)), Color(0, 0, 0, 0.45), false, 1.0)
