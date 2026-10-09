class_name HudKit
extends RefCounted
## In-world combat HUD pieces: no boxes. Round medallion buttons that sit on the battlefield,
## a carved scoreboard banner, and side panels that fade in from the screen edge.

const BRONZE := Color("8a6a3a")
const GOLDEN := Color("e3c589")
const PARCH := Color("f1e6cc")

## A round button: dark disc, bronze rim, gold when active, and a drawn icon or a short label.
class Medallion extends Button:
 var icon_kind := ""        # play · pause · camera · follow · stats · eye, or "" to show `caption`
 var caption := ""
 var active := false
 var muted := false        # dimmed icon (e.g. sound switched off)
 var hover_t := 0.0
 var font: Font
 func _ready() -> void:
  flat = true; focus_mode = Control.FOCUS_NONE; mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  for st in ["normal", "hover", "pressed", "disabled", "focus"]: add_theme_stylebox_override(st, StyleBoxEmpty.new())
  mouse_entered.connect(func(): hover_t = 1.0; queue_redraw())
  mouse_exited.connect(func(): hover_t = 0.0; queue_redraw())
 func _draw() -> void:
  var c = size * 0.5; var r = minf(size.x, size.y) * 0.5 - 3.0
  draw_circle(c + Vector2(0, 3), r + 1, Color(0, 0, 0, 0.45))
  if active: draw_circle(c, r + 4, Color(GOLDEN, 0.22))
  draw_circle(c, r, Color("2a1f12") if not active else Color("4a3214"))
  draw_circle(c, r - 3, Color(0.07, 0.06, 0.09, 0.96).lerp(Color(0.16, 0.12, 0.08), hover_t * 0.6))
  draw_arc(c, r - 1.5, 0, TAU, 40, GOLDEN if (active or hover_t > 0) else BRONZE, 2.5, true)
  draw_arc(c, r - 6, PI * 1.15, PI * 1.85, 16, Color(1, 1, 1, 0.12), 2.0, true)
  var ink = PARCH if not (disabled or muted) else Color(PARCH, 0.4)
  var s = r * 0.42
  match icon_kind:
   "pause":
    draw_rect(Rect2(c + Vector2(-s * 0.75, -s), Vector2(s * 0.5, s * 2)), ink); draw_rect(Rect2(c + Vector2(s * 0.25, -s), Vector2(s * 0.5, s * 2)), ink)
   "play":
    draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.6, -s), c + Vector2(s, 0), c + Vector2(-s * 0.6, s)]), ink)
   "camera":
    draw_arc(c, s, 0.5, TAU - 0.3, 24, ink, 2.5, true)
    var tip = c + Vector2(cos(0.5), sin(0.5)) * s
    draw_colored_polygon(PackedVector2Array([tip + Vector2(-s * 0.45, 0), tip + Vector2(s * 0.35, -s * 0.1), tip + Vector2(0, s * 0.45)]), ink)
   "follow":
    draw_arc(c, s, 0, TAU, 24, ink, 2.0, true); draw_circle(c, s * 0.3, ink)
    for a in [0.0, PI * 0.5, PI, PI * 1.5]: draw_line(c + Vector2(cos(a), sin(a)) * s * 1.05, c + Vector2(cos(a), sin(a)) * s * 1.5, ink, 2.0, true)
   "stats":
    for i in range(3): draw_rect(Rect2(c + Vector2(-s + i * s * 0.75, s - s * (0.8 + i * 0.6)), Vector2(s * 0.5, s * (0.8 + i * 0.6))), ink)
   "eye":
    var pts = PackedVector2Array()
    for i in range(24):
     var t = TAU * i / 24.0; pts.append(c + Vector2(cos(t) * s * 1.2, sin(t) * s * 0.6))
    var ring = pts.duplicate(); ring.append(pts[0]); draw_polyline(ring, ink, 2.0, true); draw_circle(c, s * 0.35, ink)
   "music":
    draw_line(c + Vector2(-s * 0.3, s * 0.7), c + Vector2(-s * 0.3, -s), ink, 2.5, true); draw_line(c + Vector2(s * 0.7, s * 0.4), c + Vector2(s * 0.7, -s * 1.2), ink, 2.5, true)
    draw_line(c + Vector2(-s * 0.3, -s), c + Vector2(s * 0.7, -s * 1.2), ink, 3.5, true)
    draw_circle(c + Vector2(-s * 0.62, s * 0.72), s * 0.36, ink); draw_circle(c + Vector2(s * 0.38, s * 0.42), s * 0.36, ink)
   "sound":
    draw_colored_polygon(PackedVector2Array([c + Vector2(-s, -s * 0.35), c + Vector2(-s * 0.45, -s * 0.35), c + Vector2(s * 0.15, -s * 0.9), c + Vector2(s * 0.15, s * 0.9), c + Vector2(-s * 0.45, s * 0.35), c + Vector2(-s, s * 0.35)]), ink)
    draw_arc(c + Vector2(s * 0.2, 0), s * 0.55, -0.8, 0.8, 10, ink, 2.0, true); draw_arc(c + Vector2(s * 0.2, 0), s * 0.95, -0.8, 0.8, 12, ink, 2.0, true)
   "gear":
    for i in range(8):
     var a = TAU * i / 8.0; draw_line(c + Vector2(cos(a), sin(a)) * s * 0.7, c + Vector2(cos(a), sin(a)) * s * 1.1, ink, 3.5, true)
    draw_arc(c, s * 0.7, 0, TAU, 24, ink, 3.0, true); draw_circle(c, s * 0.25, ink)
   "close":
    draw_line(c + Vector2(-s * 0.8, -s * 0.8), c + Vector2(s * 0.8, s * 0.8), ink, 3.0, true); draw_line(c + Vector2(s * 0.8, -s * 0.8), c + Vector2(-s * 0.8, s * 0.8), ink, 3.0, true)
   "menu":
    for y in [-s * 0.7, 0.0, s * 0.7]: draw_line(c + Vector2(-s, y), c + Vector2(s, y), ink, 3.0, true)
   "squad":
    draw_circle(c + Vector2(-s * 0.45, -s * 0.35), s * 0.36, ink); draw_circle(c + Vector2(s * 0.5, -s * 0.45), s * 0.32, ink)
    draw_arc(c + Vector2(-s * 0.45, s * 0.75), s * 0.7, PI, TAU, 16, ink, 3.0, true); draw_arc(c + Vector2(s * 0.55, s * 0.6), s * 0.6, PI * 1.05, TAU, 14, ink, 2.5, true)
   "journal":
    draw_rect(Rect2(c + Vector2(-s * 0.85, -s), Vector2(s * 1.7, s * 2.0)), ink, false, 2.5)
    draw_line(c + Vector2(-s * 0.55, -s), c + Vector2(-s * 0.55, s), ink, 2.0, true)
    for y in [-s * 0.4, 0.0, s * 0.4]: draw_line(c + Vector2(-s * 0.25, y), c + Vector2(s * 0.6, y), ink, 1.6, true)
   "traits":
    var hexp = PackedVector2Array()
    for i in range(7):
     var a = TAU * i / 6.0 + PI / 6.0
     hexp.append(c + Vector2(cos(a), sin(a)) * s * 1.05)
    draw_polyline(hexp, ink, 2.5, true); draw_circle(c, s * 0.3, ink)
   "scores":
    draw_colored_polygon(PackedVector2Array([c + Vector2(-s, -s * 0.6), c + Vector2(-s * 0.5, 0), c + Vector2(0, -s * 0.9), c + Vector2(s * 0.5, 0), c + Vector2(s, -s * 0.6), c + Vector2(s * 0.8, s * 0.55), c + Vector2(-s * 0.8, s * 0.55)]), ink)
    draw_rect(Rect2(c + Vector2(-s * 0.8, s * 0.7), Vector2(s * 1.6, s * 0.3)), ink)
   "guide":
    draw_arc(c + Vector2(0, -s * 0.35), s * 0.55, PI, TAU + PI * 0.35, 16, ink, 3.0, true)
    draw_line(c + Vector2(s * 0.1, s * 0.05), c + Vector2(0, s * 0.4), ink, 3.0, true); draw_circle(c + Vector2(0, s * 0.85), s * 0.17, ink)
   "atlas":
    draw_arc(c, s, 0, TAU, 28, ink, 2.5, true); draw_line(c + Vector2(-s, 0), c + Vector2(s, 0), ink, 1.6, true)
    for k in [-1.0, 1.0]:
     var pts = PackedVector2Array()
     for i in range(13):
      var t = -PI / 2 + PI * i / 12.0
      pts.append(c + Vector2(cos(t) * s * 0.45 * k, sin(t) * s))
     draw_polyline(pts, ink, 1.6, true)
   "plan":
    draw_rect(Rect2(c + Vector2(-s * 0.8, -s), Vector2(s * 1.6, s * 2.0)), ink, false, 2.5)
    for i in range(3):
     var y = -s * 0.5 + i * s * 0.5
     draw_line(c + Vector2(-s * 0.5, y), c + Vector2(-s * 0.3, y + s * 0.18), ink, 2.0, true); draw_line(c + Vector2(-s * 0.3, y + s * 0.18), c + Vector2(-s * 0.05, y - s * 0.2), ink, 2.0, true)
     draw_line(c + Vector2(s * 0.1, y), c + Vector2(s * 0.55, y), ink, 1.6, true)
   "map":
    draw_polyline(PackedVector2Array([c + Vector2(-s, -s * 0.7), c + Vector2(-s * 0.33, -s), c + Vector2(s * 0.33, -s * 0.7), c + Vector2(s, -s), c + Vector2(s, s * 0.7), c + Vector2(s * 0.33, s), c + Vector2(-s * 0.33, s * 0.7), c + Vector2(-s, s), c + Vector2(-s, -s * 0.7)]), ink, 2.2, true)
    draw_line(c + Vector2(-s * 0.33, -s), c + Vector2(-s * 0.33, s * 0.7), ink, 1.5, true); draw_line(c + Vector2(s * 0.33, -s * 0.7), c + Vector2(s * 0.33, s), ink, 1.5, true)
   _:
    if font: draw_string(font, c + Vector2(-r, s * 0.7), caption, HORIZONTAL_ALIGNMENT_CENTER, r * 2, int(r * 0.78), ink)

static func medallion(parent: Node, game: Node, kind: String, caption: String, tip: String, callback: Callable, active := false, px := 54.0) -> Medallion:
 var m = Medallion.new(); m.icon_kind = kind; m.caption = caption; m.active = active; m.tooltip_text = tip
 m.font = load(game.TITLE_FONT); m.custom_minimum_size = Vector2(px, px); m.size = Vector2(px, px)
 parent.add_child(m); m.pressed.connect(callback)
 return m

## The scoreboard: a tapered, carved banner (no box) behind the live score text.
class Banner extends Control:
 func _draw() -> void:
  var w = size.x; var h = size.y; var taper = h * 0.55
  var body = PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w - taper, h), Vector2(taper, h)])
  draw_colored_polygon(body, Color(0.03, 0.025, 0.04, 0.78))
  draw_polyline(PackedVector2Array([Vector2(0, 0), Vector2(taper, h), Vector2(w - taper, h), Vector2(w, 0)]), Color(GOLDEN, 0.75), 2.0, true)
  draw_line(Vector2(taper + 10, h - 6), Vector2(w - taper - 10, h - 6), Color(GOLDEN, 0.25), 1.0, true)
  for x in [taper * 0.5, w - taper * 0.5]: draw_circle(Vector2(x, h * 0.3), 3.0, GOLDEN)

static func banner(parent: Node, rect: Rect2) -> Banner:
 var b = Banner.new(); parent.add_child(b); b.position = rect.position; b.size = rect.size; b.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return b

## A soft dark fade from one screen edge, so side panels read without a box.
static func edge_fade(parent: Node, rect: Rect2, from_left: bool, strength := 0.72) -> ColorRect:
 var v = ColorRect.new(); parent.add_child(v); v.position = rect.position; v.size = rect.size; v.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var sh = Shader.new()
 sh.code = "shader_type canvas_item; uniform float strength=0.7; uniform bool left=true; void fragment(){ float x = left ? UV.x : 1.0-UV.x; float y = smoothstep(0.0,0.12,UV.y)*smoothstep(1.0,0.82,UV.y); COLOR=vec4(0.01,0.01,0.02,(1.0-smoothstep(0.0,1.0,x))*strength*y); }"
 var m = ShaderMaterial.new(); m.shader = sh; m.set_shader_parameter("strength", strength); m.set_shader_parameter("left", from_left); v.material = m
 return v

## A clean text tab (no box): small-caps book serif with tracking, muted until hovered, gold when
## active, with a gilded rule that grows from the centre — the Baldur's Gate 3 menu treatment.
class NavTab extends Button:
 var label := ""
 var active := false
 var glow := 0.0
 var font: Font
 func _ready() -> void:
  flat = true; focus_mode = Control.FOCUS_NONE; mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  for st in ["normal", "hover", "pressed", "disabled", "focus"]: add_theme_stylebox_override(st, StyleBoxEmpty.new())
  set_meta("feel_amp", 0.0)
  mouse_entered.connect(func(): _glow(1.0))
  mouse_exited.connect(func(): _glow(0.0))
 func _glow(v: float) -> void:
  var tw = create_tween(); tw.tween_method(func(x): glow = x; queue_redraw(), glow, v, 0.16)
 func _draw() -> void:
  var w = size.x; var h = size.y
  var ink = GOLDEN if active else PARCH.lerp(Color.WHITE, glow) * Color(1, 1, 1, 0.82 + 0.18 * glow)
  var fs = 17
  var txt = label.to_upper()
  if font:
   var tw = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
   var pos = Vector2((w - tw) * 0.5, h * 0.5 + fs * 0.32)
   draw_string(font, pos + Vector2(0, 2), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.7))
   draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
  var reach = (0.36 if active else 0.0) + glow * 0.12
  if reach > 0.0:
   var y = h - 5.0; var mid = w * 0.5
   draw_line(Vector2(mid - w * reach, y), Vector2(mid + w * reach, y), Color(GOLDEN, 0.85 if active else 0.5), 1.5, true)
   if active:
    draw_colored_polygon(PackedVector2Array([Vector2(mid, y - 4), Vector2(mid + 4, y), Vector2(mid, y + 4), Vector2(mid - 4, y)]), GOLDEN)

static func nav_tab(parent: Node, game: Node, text: String, callback: Callable, active := false) -> NavTab:
 var t = NavTab.new(); t.label = text; t.active = active; t.font = game.button_font()
 # Keep the real button text (for search and tests) but draw it ourselves.
 t.text = text
 for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color", "font_outline_color"]: t.add_theme_color_override(k, Color(0, 0, 0, 0))
 t.custom_minimum_size = Vector2(0, 44); t.tooltip_text = ""
 parent.add_child(t); t.pressed.connect(callback)
 return t
