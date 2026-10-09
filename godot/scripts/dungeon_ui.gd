class_name DungeonUI
extends RefCounted
## The dungeon's screens, in one visual language: dark bronze-trimmed plates, title-font headings,
## medallion rooms on a painted map, a relic belt, an auto-chess synergy column and a squad strip.
## Decisions that block the map (which instance to enter, bank or go endless, the end of the run)
## appear as overlays; rewards, events and reference pages open as framed dialogs.

const W := 1548.0
const H := 768.0
const TOP_H := 78.0
const MAP_Y := 86.0
const MAP_H := 550.0
const SQUAD_Y := 644.0
const BRONZE := Color("8a6a3a")
const GOLDEN := Color("e3c589")
const PARCH := Color("f1e6cc")
const MUTE := Color("a99f8e")
const FILL := Color(0.055, 0.045, 0.07, 0.96)

# ================================================================== Visual language
static func skin(border := BRONZE, fill := FILL, radius := 8, shadow := true, width := 2) -> StyleBoxFlat:
 var sb = StyleBoxFlat.new(); sb.bg_color = fill; sb.border_color = border; sb.set_border_width_all(width); sb.set_corner_radius_all(radius)
 sb.anti_aliasing = true
 if shadow: sb.shadow_color = Color(0, 0, 0, 0.55); sb.shadow_size = 12; sb.shadow_offset = Vector2(0, 4)
 return sb

## A framed plate: bronze rim, a faint inner gold bevel and a dark body.
static func plate(parent: Node, rect: Rect2, border := BRONZE, fill := FILL) -> Panel:
 var p = Panel.new(); parent.add_child(p); p.position = rect.position; p.size = rect.size
 p.add_theme_stylebox_override("panel", skin(border, fill)); p.mouse_filter = Control.MOUSE_FILTER_PASS
 var bevel = Panel.new(); p.add_child(bevel); bevel.position = Vector2(4, 4); bevel.size = rect.size - Vector2(8, 8); bevel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var sb = StyleBoxFlat.new(); sb.draw_center = false; sb.border_color = Color(GOLDEN, 0.16); sb.set_border_width_all(1); sb.set_corner_radius_all(6)
 bevel.add_theme_stylebox_override("panel", sb)
 return p

static func text(game: Node, parent: Node, value: String, pos: Vector2, px: int, color := PARCH, width := 0.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
 var l = game.label(parent, value, px, color, width > 0.0); l.position = pos; l.horizontal_alignment = align
 if width > 0.0: l.size.x = width; l.custom_minimum_size.x = width
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return l

static func heading(game: Node, parent: Node, value: String, pos: Vector2, px: int, color := PARCH, width := 0.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
 var l = text(game, parent, value, pos, px, color, width, align)
 l.add_theme_font_override("font", load(game.TITLE_FONT))
 l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9)); l.add_theme_constant_override("outline_size", maxi(4, px / 6))
 l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6)); l.add_theme_constant_override("shadow_offset_y", 2)
 return l

static func caption(game: Node, parent: Node, value: String, pos: Vector2, color := GOLDEN, width := 0.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
 return text(game, parent, value.to_upper(), pos, 12, color, width, align)

## Gold-trimmed game button. "primary" is the warm call to action.
static func button(game: Node, parent: Node, label_text: String, callback: Callable, primary := false, size := Vector2(200, 46), disabled := false) -> Button:
 var b = Button.new(); parent.add_child(b); b.text = label_text; b.custom_minimum_size = size; b.size = size; b.disabled = disabled
 b.focus_mode = Control.FOCUS_NONE; b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 var base = Color("6b3f16") if primary else Color("1d1a24")
 b.add_theme_stylebox_override("normal", skin(GOLDEN if primary else BRONZE, base, 6, true))
 b.add_theme_stylebox_override("hover", skin(PARCH if primary else GOLDEN, base.lightened(0.18), 6, true))
 b.add_theme_stylebox_override("pressed", skin(GOLDEN, base.darkened(0.25), 6, false))
 b.add_theme_stylebox_override("disabled", skin(Color(BRONZE, 0.4), Color(0.08, 0.07, 0.1, 0.8), 6, false))
 b.add_theme_font_override("font", load(game.TITLE_FONT) if primary else game.button_font()); b.add_theme_font_size_override("font_size", 22 if primary else 17)
 b.add_theme_color_override("font_color", PARCH); b.add_theme_color_override("font_hover_color", Color.WHITE); b.add_theme_color_override("font_disabled_color", Color(MUTE, 0.6))
 b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8)); b.add_theme_constant_override("outline_size", 4)
 b.pressed.connect(callback)
 if primary and not disabled:
  var t = b.create_tween().set_loops(); t.set_trans(Tween.TRANS_SINE)
  t.tween_property(b, "modulate", Color(1.12, 1.08, 1.0), 0.9); t.tween_property(b, "modulate", Color.WHITE, 0.9)
 return b

## A circular portrait in a bronze ring.
static func portrait(parent: Node, sp: String, rect: Rect2, ring := GOLDEN, tint := Color.WHITE) -> Panel:
 var frame = Panel.new(); parent.add_child(frame); frame.position = rect.position; frame.size = rect.size
 var sb = skin(ring, Color(0.03, 0.03, 0.05, 1.0), int(rect.size.x / 2), true, 3); frame.add_theme_stylebox_override("panel", sb)
 frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW; frame.mouse_filter = Control.MOUSE_FILTER_PASS
 var art = SplashArt.make(frame, sp, rect.size, false, false); art.position = Vector2.ZERO; art.size = rect.size; art.modulate = tint
 return frame

static func painted(parent: Control, id: String, rect: Rect2, dim := 0.42) -> TextureRect:
 var art = TextureRect.new(); parent.add_child(art); art.position = rect.position; art.size = rect.size
 art.texture = DungeonInstances.art(id); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 art.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var accent = Color(DungeonInstances.info(id).accent)
 art.modulate = Color(dim, dim, dim).lerp(accent * dim, 0.45)
 return art

## A vignette that darkens the edges of a panel toward the instance's fog colour.
static func vignette(parent: Control, rect: Rect2, color: Color, strength := 0.75) -> ColorRect:
 var v = ColorRect.new(); parent.add_child(v); v.position = rect.position; v.size = rect.size; v.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var sh = Shader.new(); sh.code = "shader_type canvas_item; uniform vec4 tint:source_color; uniform float strength=0.75; void fragment(){ vec2 d=(UV-0.5)*vec2(1.0,1.25); float e=smoothstep(0.25,0.75,length(d)); COLOR=vec4(tint.rgb, e*strength); }"
 var m = ShaderMaterial.new(); m.shader = sh; m.set_shader_parameter("tint", color); m.set_shader_parameter("strength", strength); v.material = m
 return v

## Framed dialog: dim the screen, centre a plate with a title. Returns {root, box}.
static func dialog(game: Node, title: String, size: Vector2, accent := GOLDEN, closable := true) -> Dictionary:
 var shade = ColorRect.new(); game.ui.add_child(shade); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); shade.color = Color(0.01, 0.01, 0.02, 0.8)
 shade.mouse_filter = Control.MOUSE_FILTER_STOP
 var p = plate(shade, Rect2((Vector2(1600, 900) - size) * 0.5, size), accent)
 heading(game, p, title, Vector2(28, 18), 30, PARCH)
 var rule = ColorRect.new(); p.add_child(rule); rule.position = Vector2(28, 64); rule.size = Vector2(size.x - 56, 1); rule.color = Color(accent, 0.45); rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
 if closable:
  var close = HudKit.medallion(p, game, "close", "", "Close", func(): shade.queue_free(), false, 44); close.position = Vector2(size.x - 64, 12)
 var box = VBoxContainer.new(); p.add_child(box); box.position = Vector2(28, 80); box.size = Vector2(size.x - 56, size.y - 100); box.add_theme_constant_override("separation", 12)
 UIFeel.float_in(game, shade, p)
 return {"root": shade, "box": box, "panel": p}

## Give an existing button (management tabs, the dock) the dungeon look.
static func restyle(game: Node, b: Button, primary := false, selected := false) -> void:
 var base = Color("6b3f16") if primary else (Color("2a2230") if selected else Color("16131c"))
 b.add_theme_stylebox_override("normal", skin(GOLDEN if (primary or selected) else BRONZE, base, 6, true))
 b.add_theme_stylebox_override("hover", skin(PARCH if primary else GOLDEN, base.lightened(0.15), 6, true))
 b.add_theme_stylebox_override("pressed", skin(GOLDEN, base.darkened(0.25), 6, false))
 b.add_theme_stylebox_override("disabled", skin(Color(BRONZE, 0.35), Color(0.08, 0.07, 0.09, 0.8), 6, false, 1))
 b.add_theme_color_override("font_color", PARCH if (primary or selected) else Color(PARCH, 0.8)); b.add_theme_color_override("font_hover_color", Color.WHITE)

static func rarity_color(rarity: String) -> Color:
 return Color({"Common": "9fd4c6", "Rare": "8fb8ff", "Boss": "ffb35c"}.get(rarity, "ffffff"))

static func trait_tooltip(id: String) -> String:
 return RunTraits.tooltip(id)

# ================================================================== Map drawing
## A room on the map: a medallion with a bronze rim, coloured by state, pulsing when it is open.
class RoomNode extends Button:
 var kind := "battle"
 var state := "future"     # open · here · done · future
 var tint := Color.WHITE
 var threat := Color(0, 0, 0, 0)   # danger colour for fight rooms ahead (alpha 0 = none)
 var t := 0.0
 func _ready() -> void:
  flat = true; focus_mode = Control.FOCUS_NONE
  for st in ["normal", "hover", "pressed", "disabled", "focus"]: add_theme_stylebox_override(st, StyleBoxEmpty.new())
  if state == "open": mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  pivot_offset = size * 0.5
  mouse_entered.connect(func(): if state == "open": create_tween().tween_property(self, "scale", Vector2(1.12, 1.12), 0.12))
  mouse_exited.connect(func(): create_tween().tween_property(self, "scale", Vector2.ONE, 0.12))
 func _process(dt: float) -> void:
  if state in ["open", "here"]: t += dt; queue_redraw()
 func _draw() -> void:
  var c = size * 0.5; var r = minf(size.x, size.y) * 0.5 - 4.0
  draw_circle(c + Vector2(0, 4), r + 1, Color(0, 0, 0, 0.5))
  if state == "open":
   var pulse = 0.5 + 0.5 * sin(t * 3.2)
   draw_circle(c, r + 6 + pulse * 3, Color(tint, 0.10 + 0.12 * pulse))
   draw_arc(c, r + 4 + pulse * 2, 0, TAU, 48, Color(tint, 0.45 + 0.4 * pulse), 2.5, true)
  var rim = Color("c8a060") if state in ["open", "here"] else Color("5a4a34")
  draw_circle(c, r, rim.darkened(0.35))
  var fill = {"here": tint.darkened(0.45), "open": Color(0.11, 0.09, 0.15).lerp(tint, 0.22), "done": Color(0.09, 0.08, 0.1), "future": Color(0.07, 0.06, 0.09)}.get(state, Color.BLACK)
  draw_circle(c, r - 3.5, fill)
  draw_arc(c, r - 1.5, 0, TAU, 48, rim, 2.0, true)
  draw_arc(c, r - 5.5, PI * 1.1, PI * 1.9, 24, Color(1, 1, 1, 0.10 if state != "future" else 0.04), 2.0, true)
  if threat.a > 0.0 and state in ["open", "future"]:
   # A danger arc under the medallion: green easy, gold even, orange hard, red deadly.
   draw_arc(c, r + 2.5, PI * 0.15, PI * 0.85, 18, Color(threat, 0.95 if state == "open" else 0.55), 4.0, true)
  if state == "here":
   var spin = t * 0.8
   for i in range(4): draw_arc(c, r + 5, spin + i * PI * 0.5, spin + i * PI * 0.5 + 0.9, 10, Color("fff3cf"), 2.5, true)

class DungeonMap extends Control:
 var points := {}      # Vector2i(row, col) -> centre
 var trail := []
 var map := []
 var options := []
 var row := -1
 var accent := Color.WHITE
 var t := 0.0
 func _process(dt: float) -> void:
  t += dt; queue_redraw()
 func curve(a: Vector2, b: Vector2) -> PackedVector2Array:
  var pts = PackedVector2Array(); var dx = (b.x - a.x) * 0.5
  for i in range(25):
   var s = i / 24.0; var u = 1.0 - s
   pts.append(u * u * u * a + 3 * u * u * s * (a + Vector2(dx, 0)) + 3 * u * s * s * (b - Vector2(dx, 0)) + s * s * s * b)
  return pts
 func _draw() -> void:
  for r in range(map.size() - 1):
   for i in range(map[r].size()):
    for j in map[r][i].links:
     var pts = curve(points[Vector2i(r, i)], points[Vector2i(r + 1, j)])
     var walked = r + 1 < trail.size() and int(trail[r]) == i and int(trail[r + 1]) == j
     var ahead = r == row and r < trail.size() and int(trail[r]) == i and j in options
     if walked:
      draw_polyline(pts, Color(1.0, 0.8, 0.4, 0.22), 9.0, true); draw_polyline(pts, Color("ffd36e"), 3.0, true)
     elif ahead:
      for k in range(0, pts.size() - 1, 2):
       var a = clampf(0.55 + 0.45 * sin(t * 4.0 - k * 0.5), 0.0, 1.0)
       draw_line(pts[k], pts[k + 1], Color(accent, a), 3.0, true)
     else:
      for k in range(0, pts.size(), 2): draw_circle(pts[k], 1.6, Color(1, 1, 1, 0.16 if r > row else 0.08))
  # Entrance: where the guild stands before the first room.
  if row < 0 and points.has(Vector2i(0, 0)):
   var start = Vector2(22, size.y * 0.5)
   for i in range(map[0].size()):
    var pts = curve(start, points[Vector2i(0, i)])
    for k in range(0, pts.size() - 1, 2): draw_line(pts[k], pts[k + 1], Color(accent, 0.55 + 0.4 * sin(t * 4.0 - k * 0.5)), 3.0, true)

## A hexagon synergy badge, auto-chess style: lit in the trait's colour once a threshold is met.
class TraitBadge extends Control:
 var color := Color.WHITE
 var lit := false
 var count := 0
 var font: Font
 func _draw() -> void:
  var c = size * 0.5; var r = minf(size.x, size.y) * 0.5 - 2.0
  var pts = PackedVector2Array()
  for i in range(6): pts.append(c + Vector2(cos(PI / 6 + i * PI / 3), sin(PI / 6 + i * PI / 3)) * r)
  draw_colored_polygon(pts, color.darkened(0.25) if lit else Color(0.12, 0.11, 0.15))
  var ring = pts.duplicate(); ring.append(pts[0])
  draw_polyline(ring, Color("e3c589") if lit else Color(1, 1, 1, 0.25), 2.0, true)
  if font: draw_string(font, c + Vector2(-r, 6), str(count), HORIZONTAL_ALIGNMENT_CENTER, r * 2, 17, Color.WHITE if lit else Color(1, 1, 1, 0.55))

# ================================================================== The map screen
static func overview(desk: ManagementDesk) -> void:
 var game = desk.game; var c: Campaign = desk.campaign; var d = c.state.dungeon
 var stage = Control.new(); stage.custom_minimum_size = Vector2(W, H); stage.mouse_filter = Control.MOUSE_FILTER_IGNORE; desk.body.add_child(stage)
 top_band(game, stage, c)
 map_panel(game, stage, c)
 squad_band(game, stage, c)
 if not d.get("instance_choices", []).is_empty(): path_overlay(game, stage, c)
 elif c.state.tour.get("complete", false) or c.state.get("run_over", false): end_overlay(game, stage, c)
 elif d.awaiting_endless: endless_overlay(game, stage, c)
 # Anything waiting in the current room opens straight away.
 elif not d.loot.is_empty(): game.get_tree().process_frame.connect(func(): loot_modal(game), CONNECT_ONE_SHOT)
 if not d.get("draft", {}).is_empty(): game.get_tree().process_frame.connect(func(): draft_dialog(game), CONNECT_ONE_SHOT)
 elif not d.event.is_empty(): game.get_tree().process_frame.connect(func(): event_modal(game), CONNECT_ONE_SHOT)

## Instance seal, name, depth pips · relic belt · tools.
static func top_band(game: Node, stage: Control, c: Campaign) -> void:
 var d = c.state.dungeon; var info = Dungeon.depth(c); var accent = Color(info.accent)
 var band = plate(stage, Rect2(0, 0, W, TOP_H), Color(accent, 0.7))
 # Seal: the instance initial in a ring of its colour.
 var seal = Panel.new(); band.add_child(seal); seal.position = Vector2(14, 9); seal.size = Vector2(60, 60)
 seal.add_theme_stylebox_override("panel", skin(accent, accent.darkened(0.7), 30, true, 3)); seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
 heading(game, seal, str(info.name).trim_prefix("The ").left(1), Vector2(0, 8), 32, accent.lightened(0.4), 60, HORIZONTAL_ALIGNMENT_CENTER)
 heading(game, band, str(info.name), Vector2(86, 6), 30, PARCH)
 caption(game, band, "%s  ·  %s%s" % [info.depth_label, Dungeon.stage_label(c), ("  ·  Ascension %d" % DungeonAscension.rank(c)) if DungeonAscension.rank(c) > 0 else ""], Vector2(88, 48), accent.lightened(0.35))
 # Depth pips: the instances already conquered, the current one, the ones still ahead.
 var visited: Array = d.get("visited", [])
 var px = 470.0
 for i in range(mini(maxi(Dungeon.ACTS, int(d.act)), 9)):
  var done = i < int(d.act) - 1; var here = i == int(d.act) - 1
  var col = Color(DungeonInstances.info(visited[i]).accent) if i < visited.size() else Color(1, 1, 1, 0.2)
  var pip = Panel.new(); band.add_child(pip); pip.position = Vector2(px + i * 30, 30 if not here else 27); pip.size = Vector2(18, 18) if not here else Vector2(24, 24)
  pip.add_theme_stylebox_override("panel", skin(GOLDEN if here else BRONZE, col.darkened(0.2) if (done or here) and i < visited.size() else Color(0.06, 0.05, 0.08), 12, false, 2))
  pip.tooltip_text = DungeonInstances.info(visited[i]).name if i < visited.size() else "Depth %d" % (i + 1)
 # Relic belt.
 var relics: Array = Relics.owned(c)
 var rx = 760.0
 caption(game, band, "Relics", Vector2(rx, 6), GOLDEN)
 if relics.is_empty(): text(game, band, "Elites, treasure and Wardens offer relics.", Vector2(rx, 34), 14, MUTE)
 for i in range(mini(relics.size(), 11)):
  var r = Relics.info(relics[i])
  var slot = Panel.new(); band.add_child(slot); slot.position = Vector2(rx + i * 44, 24); slot.size = Vector2(40, 40)
  slot.add_theme_stylebox_override("panel", skin(rarity_color(r.rarity), Color(0.04, 0.03, 0.06), 20, false, 2))
  slot.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW; slot.tooltip_text = "%s · %s relic\n%s" % [r.name, r.rarity, r.text]
  var icon = AbilityArt.icon(slot, str(r.art), 40); icon.position = Vector2.ZERO; icon.size = Vector2(40, 40); icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
 if relics.size() > 11: text(game, band, "+%d" % (relics.size() - 11), Vector2(rx + 11 * 44 + 4, 34), 16, GOLDEN)
 # Tools.
 # Tools: medallions instead of tabs. Squad and Journal open the side pages; the rest are dialogs.
 var tools = HBoxContainer.new(); band.add_child(tools); tools.add_theme_constant_override("separation", 8)
 var entries = [["squad", "Your squad: formation, items, tactics and XP", func(): game.tab = "roster"; game.render()],
  ["journal", "Journal: every room and fight so far", func(): game.tab = "matches"; game.render()],
  ["traits", "Run traits and synergies", func(): traits_modal(game)],
  ["scores", "Dungeon high scores", func(): high_scores(game)],
  ["guide", "How the dungeon works", func(): guide(game)]]
 for e in entries:
  var m = HudKit.medallion(tools, game, e[0], "", e[1], e[2], false, 50); m.name = "DungeonTool_" + e[0]
 tools.position = Vector2(W - entries.size() * 58 - 10, 14)

static func map_panel(game: Node, stage: Control, c: Campaign) -> void:
 var d = c.state.dungeon; var info = Dungeon.depth(c); var accent = Color(info.accent)
 var frame = Panel.new(); stage.add_child(frame); frame.position = Vector2(0, MAP_Y); frame.size = Vector2(W, MAP_H)
 frame.add_theme_stylebox_override("panel", skin(Color(accent, 0.55), Color(0.02, 0.02, 0.03, 1.0), 8)); frame.clip_contents = true
 painted(frame, Dungeon.instance_id(c), Rect2(0, 0, W, MAP_H), 0.5)
 vignette(frame, Rect2(0, 0, W, MAP_H), Color(info.fog).darkened(0.6), 0.9)
 text(game, frame, str(info.tagline), Vector2(0, MAP_H - 30), 14, Color(PARCH, 0.7), W, HORIZONTAL_ALIGNMENT_CENTER)
 if not d.map.is_empty(): map_view(game, frame, c, Rect2(210, 8, W - 370, MAP_H - 44))
 synergy_column(game, frame, c)
 if not d.map.is_empty(): warden_card(game, frame, c)

static func map_view(game: Node, parent: Control, c: Campaign, rect: Rect2) -> void:
 var d = c.state.dungeon
 var view = DungeonMap.new(); parent.add_child(view); view.position = rect.position; view.size = rect.size; view.mouse_filter = Control.MOUSE_FILTER_PASS
 view.map = d.map; view.trail = d.get("trail", []); view.row = int(d.row); view.options = Dungeon.reachable(c); view.accent = Color(Dungeon.depth(c).accent)
 var w = rect.size.x; var h = rect.size.y
 for r in range(d.map.size()):
  for i in range(d.map[r].size()):
   view.points[Vector2i(r, i)] = Vector2(80 + r * (w - 130) / (Dungeon.ROWS - 1), 30 + (i + 0.5) / d.map[r].size() * (h - 60))
 # Unexplored rows fade into the dark.
 var fog = ColorRect.new(); view.add_child(fog); fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var fog_x = 80 + (int(d.row) + 2.4) * (w - 130) / (Dungeon.ROWS - 1)
 fog.position = Vector2(fog_x, 0); fog.size = Vector2(maxf(0, w - fog_x - 70), h)
 var sh = Shader.new(); sh.code = "shader_type canvas_item; void fragment(){ COLOR = vec4(0.0, 0.0, 0.02, smoothstep(0.0, 0.5, UV.x) * 0.45); }"
 var fm = ShaderMaterial.new(); fm.shader = sh; fog.material = fm
 for r in range(d.map.size()):
  for i in range(d.map[r].size()):
   var n = d.map[r][i]; var info = Dungeon.ROOMS[str(n.type)]
   var here = r == int(d.row) and i == int(d.col)
   var open = r == int(d.row) + 1 and i in view.options
   var node = RoomNode.new(); node.kind = str(n.type); node.tint = Color(info.color)
   node.state = "here" if here else "open" if open else ("done" if r <= int(d.row) else "future")
   var px = 78.0 if node.kind == "boss" else 58.0
   node.size = Vector2(px, px); node.position = view.points[Vector2i(r, i)] - node.size * 0.5; view.add_child(node)
   var holder = CenterContainer.new(); holder.mouse_filter = Control.MOUSE_FILTER_IGNORE; node.add_child(holder); holder.size = node.size
   var g = FlowUI.glyph(holder, str(info.glyph), px * 0.48, true)
   g.modulate = Color.WHITE if node.state in ["open", "here"] else Color(1, 1, 1, 0.35 if node.state == "done" else 0.6)
   var tip = "%s · Room %d\n%s" % [info.name, r + 1, info.text]
   if node.kind == "boss": tip += "\n\n%s\n%s" % [Dungeon.warden(c).name, Dungeon.warden(c).text]
   if node.kind in ["battle", "elite", "boss"] and r > int(d.row):
    var ratio = Dungeon.threat(c, r, i); var tl = Dungeon.threat_label(ratio)
    if not tl.is_empty():
     node.threat = Color(tl.color)
     tip += "\n\nThreat: %s  (foes %d%% of your strength)\n%s" % [tl.text, roundi(ratio * 100), Dungeon.reward_text(node.kind)]
     if open:
      var tag = caption(game, view, tl.text, view.points[Vector2i(r, i)] + Vector2(-40, px * 0.5 + 2), Color(tl.color), 80, HORIZONTAL_ALIGNMENT_CENTER)
      tag.add_theme_constant_override("outline_size", 5)
   node.tooltip_text = tip
   if open:
    node.name = "DungeonRoom_%d_%d" % [r, i]
    var col = i
    node.pressed.connect(func(): step(game, col))
   else: node.disabled = true
 # The guild's banner: your headliner, standing where the party is.
 var face = c.headliner()
 if not face.is_empty():
  var at = view.points.get(Vector2i(int(d.row), int(d.col)), Vector2(22, h * 0.5)) if int(d.row) >= 0 else Vector2(22, h * 0.5)
  var lift = -22.0 if int(d.row) < 0 else (-76.0 if at.y > 80 else 34.0)   # above the room, or below it near the top edge
  var marker = portrait(view, str(face.sp), Rect2(at + Vector2(-22, lift), Vector2(44, 44)), GOLDEN)
  marker.tooltip_text = "%s leads the guild" % face.name
  var bob = marker.create_tween().set_loops(); bob.set_trans(Tween.TRANS_SINE)
  bob.tween_property(marker, "position:y", marker.position.y - 4, 0.9); bob.tween_property(marker, "position:y", marker.position.y, 0.9)

## The squad's synergies down the left of the map: lit traits first.
static func synergy_column(game: Node, frame: Control, c: Campaign) -> void:
 var rows = RunTraits.summary(c, c.lineup()).filter(func(r): return int(r.count) > 0)
 var col = plate(frame, Rect2(10, 10, 196, MAP_H - 50), Color(BRONZE, 0.7), Color(0.03, 0.025, 0.045, 0.82))
 caption(game, col, "Synergies", Vector2(14, 10), GOLDEN)
 if rows.is_empty(): text(game, col, "Field champions that share a trait.", Vector2(14, 32), 13, MUTE, 168)
 var font = load(game.TITLE_FONT)
 var fit = int((MAP_H - 96.0) / 44.0)
 for i in range(mini(rows.size(), fit)):
  var row = rows[i]; var t = RunTraits.info(row.id); var lit = int(row.tier) >= 0
  var y = 32 + i * 44
  var badge = TraitBadge.new(); col.add_child(badge); badge.position = Vector2(10, y); badge.size = Vector2(38, 38)
  badge.color = Color(t.color); badge.lit = lit; badge.count = int(row.count); badge.font = font; badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
  text(game, col, t.name, Vector2(54, y + 1), 15, Color(t.color).lightened(0.2) if lit else MUTE)
  var th = RunTraits.thresholds(row.id)
  text(game, col, "%s  ·  %s" % [" / ".join(th.map(func(x): return str(x))), t.flavour], Vector2(54, y + 19), 11, PARCH if lit else Color(MUTE, 0.8))
  var hit = Control.new(); col.add_child(hit); hit.position = Vector2(6, y); hit.size = Vector2(184, 40); hit.tooltip_text = RunTraits.tooltip(row.id); hit.mouse_filter = Control.MOUSE_FILTER_STOP
 if rows.size() > fit: text(game, col, "+%d more  ·  see Traits" % (rows.size() - fit), Vector2(14, MAP_H - 76), 12, MUTE)

## The Warden of this depth, waiting at the far end of the map.
static func warden_card(game: Node, frame: Control, c: Campaign) -> void:
 var w = Dungeon.warden(c)
 var card = plate(frame, Rect2(W - 152, 10, 142, 168), Color(w.glow), Color(0.05, 0.03, 0.05, 0.9)); card.mouse_filter = Control.MOUSE_FILTER_STOP
 card.tooltip_text = "%s\n%s" % [w.name, w.text]
 portrait(card, str(w.sp), Rect2(35, 12, 72, 72), Color(w.glow), Color(w.tint).lerp(Color.WHITE, 0.45))
 caption(game, card, "Warden", Vector2(0, 92), Color("ffb3a8"), 142, HORIZONTAL_ALIGNMENT_CENTER)
 var n = text(game, card, str(w.name).trim_prefix("The "), Vector2(6, 110), 13, PARCH, 130, HORIZONTAL_ALIGNMENT_CENTER); n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

## Your fielded champions with their run traits, and the next step.
static func squad_band(game: Node, stage: Control, c: Campaign) -> void:
 var band = plate(stage, Rect2(0, SQUAD_Y, W, H - SQUAD_Y), BRONZE)
 caption(game, band, "Your squad", Vector2(16, 8), GOLDEN)
 var counts = RunTraits.counts(c, c.lineup())
 var heroes = c.lineup()
 for i in range(heroes.size()):
  var h = heroes[i]; var x = 14 + i * 196
  var card = Control.new(); band.add_child(card); card.position = Vector2(x, 26); card.size = Vector2(188, 92); card.mouse_filter = Control.MOUSE_FILTER_STOP
  portrait(card, str(h.sp), Rect2(0, 6, 64, 64), GOLDEN if h.id == c.state.get("headliner", "") else BRONZE)
  text(game, card, str(h.name), Vector2(72, 2), 16, PARCH)
  text(game, card, "Lv %d  ·  %s" % [int(h.level), HeroData.species[h.sp].n], Vector2(72, 22), 12, MUTE)
  var tags = RunTraits.of(c, h.sp)
  for k in range(tags.size()):
   var t = RunTraits.info(tags[k]); var lit = RunTraits.tier_of(tags[k], int(counts.get(tags[k], 0))) >= 0
   var chip = Panel.new(); card.add_child(chip); chip.position = Vector2(72 + (k % 2) * 58, 40 + (k / 2) * 22); chip.size = Vector2(56, 19)
   chip.add_theme_stylebox_override("panel", skin(Color(t.color) if lit else Color(t.color, 0.35), Color(t.color).darkened(0.7) if lit else Color(0.07, 0.06, 0.09), 4, false, 1))
   chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
   text(game, chip, t.name, Vector2(0, 2), 10, Color(t.color).lightened(0.3) if lit else MUTE, 56, HORIZONTAL_ALIGNMENT_CENTER)
  card.tooltip_text = "%s · %s\n\n%s" % [h.name, HeroData.species[h.sp].n, "\n\n".join(tags.map(func(t): return RunTraits.tooltip(t)))]
 next_card(game, band, c)

static func next_card(game: Node, band: Control, c: Campaign) -> void:
 var d = c.state.dungeon
 var x = 1000.0; var w = W - x - 12
 var card = plate(band, Rect2(x, 10, w, 104), Color(Dungeon.depth(c).accent, 0.8), Color(0.07, 0.05, 0.08, 0.98))
 if d.fight:
  var kind = str(Dungeon.node(c).type); var rival = c.opponent(); var info = Dungeon.ROOMS[kind]
  caption(game, card, info.name, Vector2(16, 10), Color(info.color))
  var nm = heading(game, card, str(rival.name), Vector2(16, 26), 19, PARCH, 280); nm.clip_text = true
  var tl = Dungeon.threat_label(Dungeon.threat(c, int(d.row), int(d.col)))
  if not tl.is_empty(): text(game, card, "Threat: %s  ·  %s" % [tl.text, Dungeon.reward_text(kind)], Vector2(16, 50), 12, Color(tl.color), 300)
  button(game, card, "Scout", func(): ScoutUI.open(game, rival), false, Vector2(84, 34)).position = Vector2(16, 74 - 8)
  button(game, card, "Formation", func(): game.phase = "prep"; game.render(), false, Vector2(110, 34)).position = Vector2(106, 66)
  button(game, card, "Fight  ▶", game.introduce_match, true, Vector2(150, 82), not c.lineup_ready() or not c.pending_heroes().is_empty()).position = Vector2(w - 162, 11)
  return
 caption(game, card, "Next", Vector2(16, 10), GOLDEN)
 if not c.pending_heroes().is_empty():
  heading(game, card, "Your champions grew stronger", Vector2(16, 28), 20, PARCH)
  text(game, card, "Choose their new skills before the next room.", Vector2(16, 62), 13, MUTE, w - 220)
  button(game, card, "Level ups  ▶", game.prepare_match, true, Vector2(190, 70)).position = Vector2(w - 202, 17)
  return
 if c.state.tour.get("shop", false):
  heading(game, card, "The outfitter is open", Vector2(16, 28), 20, PARCH)
  text(game, card, "Buy components, forge items and hire a champion.", Vector2(16, 62), 13, MUTE, w - 220)
  button(game, card, "Outfitter  ▶", game.prepare_match, true, Vector2(190, 70)).position = Vector2(w - 202, 17)
  return
 if not Dungeon.reachable(c).is_empty():
  heading(game, card, "Choose a glowing room", Vector2(16, 28), 20, PARCH)
  var preview = Dungeon.opponent(c)
  var pp = Dungeon.preview_position(c); var ptl = Dungeon.threat_label(Dungeon.threat(c, pp.x, pp.y))
  text(game, card, "Nearest fight ahead: %s%s" % [preview.name, ("  ·  " + ptl.text) if not ptl.is_empty() else ""], Vector2(16, 62), 13, Color(ptl.color) if not ptl.is_empty() else MUTE, w - 32)
 elif not d.loot.is_empty() or not d.event.is_empty():
  heading(game, card, "Something waits here", Vector2(16, 28), 20, PARCH)
  button(game, card, "Open", func(): game.render(), true, Vector2(120, 44)).position = Vector2(w - 136, 30)
 else:
  heading(game, card, Dungeon.stage_label(c), Vector2(16, 28), 20, PARCH)
 if d.endless and not c.state.tour.get("complete", false) and not c.state.get("run_over", false):
  button(game, card, "Retire · %d pts" % Dungeon.final_score(c), func(): confirm_retire(game), false, Vector2(170, 34)).position = Vector2(w - 186, 62)

static func confirm_retire(game: Node) -> void:
 var c: Campaign = game.campaign
 var dlg = dialog(game, "Retire from the dungeon?", Vector2(640, 260))
 text(game, dlg.box, "End the run now and bank %d points on your high-score table." % Dungeon.final_score(c), Vector2.ZERO, 17, PARCH, 580)
 var row = HBoxContainer.new(); dlg.box.add_child(row); row.add_theme_constant_override("separation", 12)
 button(game, row, "Keep going", func(): dlg.root.queue_free(), false, Vector2(200, 50))
 button(game, row, "Retire", func():
  dlg.root.queue_free()
  if Dungeon.retire(c): game.render()
  else: game.toast(c.last_error), true, Vector2(200, 50))

# ================================================================== Overlays
static func overlay(stage: Control) -> Control:
 var dim = ColorRect.new(); stage.add_child(dim); dim.size = Vector2(W, H); dim.color = Color(0.01, 0.01, 0.02, 0.84); dim.mouse_filter = Control.MOUSE_FILTER_STOP
 dim.modulate.a = 0.0; dim.create_tween().tween_property(dim, "modulate:a", 1.0, 0.2)
 return dim

## The top of the stairs: two instances to choose from for the next depth.
static func path_overlay(game: Node, stage: Control, c: Campaign) -> void:
 var d = c.state.dungeon; var dim = overlay(stage)
 var act = int(d.act)
 var kicker = ("Endless depth %d" % (act - Dungeon.ACTS)) if act > Dungeon.ACTS else "Depth %d of %d" % [act, Dungeon.ACTS]
 heading(game, dim, "Choose your path", Vector2(0, 86), 40, PARCH, W, HORIZONTAL_ALIGNMENT_CENTER)
 caption(game, dim, kicker + ("  ·  new recruits wait in the Market before you go" if c.state.tour.get("intermission", false) else "  ·  each instance has its own monsters, Warden and arena"), Vector2(0, 138), GOLDEN, W, HORIZONTAL_ALIGNMENT_CENTER)
 var choices: Array = d.instance_choices
 for i in range(choices.size()):
  var id = str(choices[i]); var info = DungeonInstances.info(id); var accent = Color(info.accent)
  var x = 54 + i * 734
  var card = plate(dim, Rect2(x, 164, 706, 516), accent, Color(0.04, 0.035, 0.055, 0.99)); card.clip_contents = true
  painted(card, id, Rect2(3, 3, 700, 214), 0.8)
  vignette(card, Rect2(3, 3, 700, 214), Color(0, 0, 0), 0.8)
  heading(game, card, str(info.name), Vector2(24, 160), 34, PARCH)
  text(game, card, str(info.tagline), Vector2(24, 226), 16, Color(PARCH, 0.85), 520)
  var boss = Bestiary.info(str(info.boss))
  portrait(card, str(boss.sp), Rect2(586, 150, 96, 96), Color(boss.glow), Color(boss.tint).lerp(Color.WHITE, 0.45))
  caption(game, card, "Warden  ·  " + str(boss.name), Vector2(24, 276), Color("ffb3a8"))
  var threat = text(game, card, str(Bestiary.BOSSES[str(info.boss)].text), Vector2(24, 296), 14, MUTE, 640)
  threat.tooltip_text = str(boss.text)
  var technique = caption(game, card, WardenMechanics.KITS[str(info.boss)].name + "  ·  hover for counterplay", Vector2(24, 338), Color("ffb3a8"), 640)
  technique.tooltip_text = str(WardenMechanics.KITS[str(info.boss)].counter)
  caption(game, card, "Monsters", Vector2(24, 356), GOLDEN)
  for k in range(info.mobs.size()):
   var m = Bestiary.MOBS[info.mobs[k]]
   var face = portrait(card, str(m.sp), Rect2(24 + k * 92, 378, 56, 56), Color(m.tint).lightened(0.2), Color(m.tint).lerp(Color.WHITE, 0.5))
   face.tooltip_text = "%s\n%s" % [m.name, m.text]
   text(game, card, str(m.name), Vector2(10 + k * 92, 438), 11, PARCH, 84, HORIZONTAL_ALIGNMENT_CENTER)
  var go = button(game, card, "Enter  ▶", func():
   if Dungeon.choose_instance(c, id):
    game.render(); FlowUI.banner(game, str(info.name).to_upper(), accent, kicker)
   else: game.toast(c.last_error), true, Vector2(220, 60))
  go.position = Vector2(462, 438); go.name = "DungeonEnter_%d" % i

## The ladder line under a finished run: the rank played and anything it unlocked.
static func ascension_note(game: Node, card: Control, c: Campaign, pos: Vector2) -> void:
 var d = c.state.dungeon; var unlocked = int(d.get("ascension_unlocked", 0))
 if unlocked <= 0 and DungeonAscension.rank(c) == 0: return
 var line = ("Ascension %d · %s" % [DungeonAscension.rank(c), DungeonAscension.info(DungeonAscension.rank(c)).name]) if DungeonAscension.rank(c) > 0 else "No Ascension"
 if unlocked > 0: line += "   ✦ Ascension %d unlocked: %s" % [unlocked, DungeonAscension.info(unlocked).name]
 text(game, card, line, pos, 15, Color("ffd36e") if unlocked > 0 else MUTE, 880, HORIZONTAL_ALIGNMENT_CENTER)

static func endless_overlay(game: Node, stage: Control, c: Campaign) -> void:
 var dim = overlay(stage)
 var card = plate(dim, Rect2(274, 194, 1000, 380), GOLDEN, Color(0.04, 0.035, 0.055, 0.99))
 heading(game, card, "The dungeon is conquered", Vector2(0, 40), 44, PARCH, 1000, HORIZONTAL_ALIGNMENT_CENTER)
 text(game, card, "All three Wardens have fallen. Bank your score now, or go into the endless depths, where every depth is harder and worth more points. If you run out of lives there, the run ends where you fall.", Vector2(90, 124), 17, MUTE, 820, HORIZONTAL_ALIGNMENT_CENTER)
 var bank = button(game, card, "Bank · %d points" % Dungeon.final_score(c), func():
  if Dungeon.retire(c): game.render(); FlowUI.banner(game, "%d POINTS" % int(c.state.dungeon.final_score), Color("ffd36e"), "Score banked")
  else: game.toast(c.last_error), false, Vector2(300, 60))
 bank.position = Vector2(170, 260); bank.name = "DungeonBankScore"
 var go = button(game, card, "Into the endless depths  ▶", func():
  if Dungeon.go_endless(c): game.render()
  else: game.toast(c.last_error), true, Vector2(380, 60))
 go.position = Vector2(490, 260); go.name = "DungeonGoEndless"
 ascension_note(game, card, c, Vector2(60, 200))

static func end_overlay(game: Node, stage: Control, c: Campaign) -> void:
 var d = c.state.dungeon; var dim = overlay(stage)
 var fallen = c.state.get("run_over", false)
 var card = plate(dim, Rect2(274, 164, 1000, 440), Color("ff8a7a") if fallen else GOLDEN, Color(0.04, 0.035, 0.055, 0.99))
 heading(game, card, "Out of lives" if fallen else "Run complete", Vector2(0, 30), 46, Color("ffcfb8") if fallen else PARCH, 1000, HORIZONTAL_ALIGNMENT_CENTER)
 heading(game, card, "%d points" % int(d.get("final_score", Dungeon.final_score(c))), Vector2(0, 100), 40, Color("9fd8ff"), 1000, HORIZONTAL_ALIGNMENT_CENTER)
 var place = Dungeon.rank_of(c)
 text(game, card, "%s  ·  reached %s  ·  %d Warden%s  ·  %d fights won (%d flawless)  ·  %d relics%s" % [str(d.get("outcome", "Fallen" if fallen else "Conquered")), Dungeon.depth(c).name, int(d.wardens), "" if int(d.wardens) == 1 else "s", int(d.wins), int(d.get("flawless", 0)), d.relics.size(), ("  ·  #%d on your high scores" % place) if place > 0 else ""], Vector2(60, 172), 17, PARCH, 880, HORIZONTAL_ALIGNMENT_CENTER)
 ascension_note(game, card, c, Vector2(60, 300))
 var visited: Array = d.get("visited", [])
 var shown = mini(visited.size(), 6)
 for i in range(shown):
  var info = DungeonInstances.info(visited[i])
  var chip = plate(card, Rect2(500 - shown * 80 + i * 160, 226, 150, 64), Color(info.accent), Color(info.accent).darkened(0.75))
  text(game, chip, str(info.name).trim_prefix("The "), Vector2(0, 20), 14, Color(info.accent).lightened(0.4), 150, HORIZONTAL_ALIGNMENT_CENTER)
 button(game, card, "High scores", func(): high_scores(game), false, Vector2(220, 56)).position = Vector2(250, 340)
 button(game, card, "New dungeon run  ▶", func(): game.new_crest = {}; game.new_mode = "dungeon"; game.phase = "new"; game.render(), true, Vector2(300, 56)).position = Vector2(490, 340)

# ================================================================== Rooms, rewards and events
static func step(game: Node, col: int) -> void:
 var c: Campaign = game.campaign
 var kind = Dungeon.enter(c, col)
 if kind == "": game.toast(c.last_error if not c.last_error.is_empty() else "Could not enter that room."); return
 game.sound.cue("contest_reveal")
 var info = Dungeon.ROOMS[kind]
 if kind == "shop":
  game.phase = "shop"; game.render(); FlowUI.banner(game, "OUTFITTER", Color(info.color)); return
 game.render()
 if kind in ["battle", "elite", "boss"]: FlowUI.banner(game, str(info.name).to_upper(), Color(info.color), c.opponent().name)

## One of three rewards, as cards.
static func loot_modal(game: Node) -> void:
 var c: Campaign = game.campaign; var d = c.state.dungeon
 if d.loot.is_empty(): return
 var relic = d.loot_kind == "relic"
 var title = "Choose a relic" if relic else ("Choose a component" if d.loot_kind == "component" else "Choose a finished item")
 var dlg = dialog(game, title, Vector2(1040, 560))
 text(game, dlg.box, ("Relics last for the whole run." if relic else "Two components on one champion forge a finished item.") + "  Take one, or skip for 25 gold." + ("  ·  %d more reward%s waiting" % [d.loot_queue.size(), "" if d.loot_queue.size() == 1 else "s"] if not d.loot_queue.is_empty() else ""), Vector2.ZERO, 15, MUTE)
 var row = HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 18); dlg.box.add_child(row)
 for i in range(d.loot.size()):
  var id = str(d.loot[i])
  var name_text = ""; var kind_text = ""; var body = ""; var tint = GOLDEN
  if relic:
   var r = Relics.info(id); name_text = r.name; kind_text = "%s relic" % r.rarity; body = r.text; tint = rarity_color(r.rarity)
  else:
   var item = Forge.info(id); name_text = item.name
   kind_text = ("Wild item" if item.get("wild", false) else "Finished item") if item.kind == "item" else "Component"
   body = (Forge.stat_line(id) + "\n" + str(item.get("text", ""))) if item.kind == "item" else str(item.get("short", ""))
   tint = Color("ff9be0") if item.get("wild", false) else (Color("9fd4c6") if item.kind == "component" else GOLDEN)
  var holder = Control.new(); holder.custom_minimum_size = Vector2(310, 380); row.add_child(holder)
  var card = plate(holder, Rect2(0, 0, 310, 380), tint, Color(0.06, 0.045, 0.09, 0.98))
  var art_frame = Panel.new(); card.add_child(art_frame); art_frame.position = Vector2(105, 18); art_frame.size = Vector2(100, 100)
  art_frame.add_theme_stylebox_override("panel", skin(tint, Color(0.03, 0.02, 0.05), 50, true, 3)); art_frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
  if relic:
   var icon = AbilityArt.icon(art_frame, str(Relics.info(id).art), 100); icon.position = Vector2.ZERO; icon.size = Vector2(100, 100)
  else:
   var token = GearUI.token(game, art_frame, Forge.info(id), 84); token.position = Vector2(8, 8)
  heading(game, card, name_text, Vector2(0, 128), 22, PARCH, 310, HORIZONTAL_ALIGNMENT_CENTER)
  caption(game, card, kind_text, Vector2(0, 160), tint, 310, HORIZONTAL_ALIGNMENT_CENTER)
  var b = text(game, card, body, Vector2(22, 184), 14, Color("d8d2c0"), 266, HORIZONTAL_ALIGNMENT_CENTER); b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  var index = i
  var take = button(game, card, "Take", func():
   if Dungeon.take_loot(c, index): dlg.root.queue_free(); game.sound.cue("upgrade"); game.render()
   else: game.toast(c.last_error), true, Vector2(200, 52))
  take.position = Vector2(55, 312); take.name = "DungeonLoot_%d" % i
  card.modulate.a = 0.0; card.position.y = 30
  var tw = card.create_tween().set_parallel(true)
  tw.tween_property(card, "modulate:a", 1.0, 0.25).set_delay(0.08 * i); tw.tween_property(card, "position:y", 0.0, 0.3).set_delay(0.08 * i).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
 var skip_row = HBoxContainer.new(); skip_row.alignment = BoxContainer.ALIGNMENT_CENTER; dlg.box.add_child(skip_row)
 reroll_button(game, skip_row, func(): return Dungeon.reroll_loot(c), dlg)
 button(game, skip_row, "Skip  ·  +25 gold", func():
  if Dungeon.skip_loot(c): dlg.root.queue_free(); game.render(), false, Vector2(220, 44))

## Five champions to choose from: the same cards as the guild-run draft board (art, random stat
## rolls, run traits), with the traits each one shares with your guild called out above it.
static func draft_dialog(game: Node) -> void:
 var c: Campaign = game.campaign; var d = c.state.dungeon; var draft = d.get("draft", {})
 if draft.is_empty(): return
 var titles = {"partner": "Choose your partner", "checkpoint": "A champion waits at the waystone", "warden": "A champion waits on the stairs", "shop": "Champions for hire"}
 var dlg = dialog(game, str(titles.get(str(draft.kind), "Choose a champion")), Vector2(1540, 610), GOLDEN, str(draft.kind) != "partner")
 var cost = int(draft.cost)
 text(game, dlg.box, ("Your headliner needs a partner. " if str(draft.kind) == "partner" else "") + "Pick one of five. Their stats are rolled fresh; ✦ marks traits they share with your guild." + ("  ·  Costs %d gold." % cost if cost > 0 else "") + "  ·  Guild %d / %d" % [c.state.roster.size(), Dungeon.MAX_CHAMPIONS], Vector2.ZERO, 15, MUTE)
 var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 10); dlg.box.add_child(row)
 for i in range(draft.offers.size()):
  var h = draft.offers[i]; var index = i
  var col = VBoxContainer.new(); col.add_theme_constant_override("separation", 6); row.add_child(col)
  var shared = Dungeon.shared_traits(c, h.sp)
  var tag = Panel.new(); tag.custom_minimum_size = Vector2(286, 30); col.add_child(tag)
  tag.add_theme_stylebox_override("panel", skin(GOLDEN if not shared.is_empty() else Color(BRONZE, 0.4), Color("3a2a10") if not shared.is_empty() else Color(0.06, 0.05, 0.08), 6, false, 1))
  text(game, tag, ("✦ Synergy · " + ", ".join(shared.map(func(t): return RunTraits.info(t).name))) if not shared.is_empty() else "No shared traits yet", Vector2(0, 5), 13, GOLDEN if not shared.is_empty() else MUTE, 286, HORIZONTAL_ALIGNMENT_CENTER)
  DraftBoard.card(game, col, h, {"on_draft": func():
   if Dungeon.take_champion(c, index): dlg.root.queue_free(); game.sound.cue("contest_lock"); game.render(); FlowUI.banner(game, "%s JOINS" % str(h.name).to_upper(), Color("ffd36e"))
   else: game.toast(c.last_error),
   "draft_text": ("Hire · %d gold" % cost) if cost > 0 else "Choose", "draft_disabled": int(c.state.gold) < cost}, 286, 168)
  col.modulate.a = 0.0
  col.create_tween().tween_property(col, "modulate:a", 1.0, 0.25).set_delay(0.07 * i)
 if str(draft.kind) != "partner":
  var skip_row = HBoxContainer.new(); skip_row.alignment = BoxContainer.ALIGNMENT_CENTER; dlg.box.add_child(skip_row)
  reroll_button(game, skip_row, func(): return Dungeon.reroll_draft(c), dlg)
  button(game, skip_row, "Pass" + ("  ·  +25 gold" if cost == 0 else ""), func():
   if Dungeon.skip_draft(c): dlg.root.queue_free(); game.render(), false, Vector2(220, 44))

## Spend gold for a fresh set of offers; the price climbs within a room.
static func reroll_button(game: Node, row: Control, action: Callable, dlg: Dictionary) -> Button:
 var c: Campaign = game.campaign; var cost = Dungeon.reroll_cost(c)
 var b = button(game, row, "Reroll  ·  %d gold" % cost, func():
  if action.call():
   dlg.root.queue_free(); game.sound.cue("contest_reveal"); game.render()
   # Outside the Dungeon tab (at the outfitter) nothing reopens the draft on render.
   if game.phase == "shop" and not c.state.dungeon.get("draft", {}).is_empty(): draft_dialog(game)
  else: game.toast(c.last_error), false, Vector2(220, 44), int(c.state.gold) < cost)
 b.tooltip_text = "New offers for %d gold. Each reroll in this room costs 20 more." % cost; b.name = "DungeonReroll"
 return b

static func relic_modal(game: Node) -> void:
 loot_modal(game)

static func event_modal(game: Node) -> void:
 var c: Campaign = game.campaign; var d = c.state.dungeon
 if d.event.is_empty(): return
 var e = d.event; var accent = Color(Dungeon.depth(c).accent)
 var dlg = dialog(game, str(e.title), Vector2(940, 236 + e.choices.size() * 72), accent)
 var art = Control.new(); art.custom_minimum_size = Vector2(880, 120); dlg.box.add_child(art); art.clip_contents = true
 painted(art, Dungeon.instance_id(c), Rect2(0, 0, 880, 120), 0.55); vignette(art, Rect2(0, 0, 880, 120), Color(0, 0, 0), 0.7)
 var story = text(game, art, str(e.text), Vector2(30, 40), 18, PARCH, 820); story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 for i in range(e.choices.size()):
  var ch = e.choices[i]; var index = i; var off = ch.get("disabled", false)
  var b = Button.new(); dlg.box.add_child(b); b.custom_minimum_size = Vector2(880, 60); b.disabled = off; b.name = "DungeonChoice_%d" % i; b.focus_mode = Control.FOCUS_NONE
  b.add_theme_stylebox_override("normal", skin(BRONZE, Color(0.09, 0.08, 0.12), 6, false))
  b.add_theme_stylebox_override("hover", skin(GOLDEN, Color(0.14, 0.12, 0.18), 6, false))
  b.add_theme_stylebox_override("pressed", skin(GOLDEN, Color(0.06, 0.05, 0.08), 6, false))
  b.add_theme_stylebox_override("disabled", skin(Color(BRONZE, 0.3), Color(0.05, 0.05, 0.07), 6, false))
  heading(game, b, str(ch.label), Vector2(20, 8), 19, PARCH if not off else MUTE)
  text(game, b, str(ch.detail), Vector2(20, 34), 13, Color("c8dcb1") if not off else Color(MUTE, 0.7), 840)
  b.pressed.connect(func():
   var outcome = Dungeon.choose_event(c, index)
   if outcome == "": game.toast(c.last_error); return
   dlg.root.queue_free(); game.toast(outcome)
   if not c.pending_heroes().is_empty(): game.phase = "upgrade"
   game.render())

# ================================================================== Reference pages
static func traits_modal(game: Node) -> void:
 var c: Campaign = game.campaign
 var dlg = dialog(game, "Run traits", Vector2(1360, 780))
 text(game, dlg.box, "Awakened this run. Each creature carries up to three of its own traits (kin, element, class). Field different champions that share a trait to unlock it.", Vector2.ZERO, 14, MUTE)
 var scroll = ScrollContainer.new(); scroll.custom_minimum_size = Vector2(1300, 620); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; dlg.box.add_child(scroll)
 var grid = GridContainer.new(); grid.columns = 2; grid.add_theme_constant_override("h_separation", 16); grid.add_theme_constant_override("v_separation", 12); scroll.add_child(grid)
 var counts = RunTraits.counts(c, c.lineup())
 for id in RunTraits.data(c).get("active", []):
  var t = RunTraits.info(id); var n = int(counts.get(id, 0)); var lit = RunTraits.tier_of(id, n) >= 0
  var holder = Control.new(); holder.custom_minimum_size = Vector2(636, 128); grid.add_child(holder)
  var card = plate(holder, Rect2(0, 0, 636, 128), Color(t.color) if lit else Color(t.color, 0.4), Color(0.05, 0.045, 0.07, 0.96))
  var badge = TraitBadge.new(); card.add_child(badge); badge.position = Vector2(14, 14); badge.size = Vector2(48, 48)
  badge.color = Color(t.color); badge.lit = lit; badge.count = n; badge.font = load(game.TITLE_FONT)
  heading(game, card, "%s  ·  %s" % [t.name, t.flavour], Vector2(74, 10), 20, Color(t.color).lightened(0.25))
  caption(game, card, "%s trait" % t.kind, Vector2(74, 40), Color(RunTraits.KIND_COLOR[t.kind]))
  var th = RunTraits.thresholds(id)
  for k in range(t.tiers.size()):
   text(game, card, "(%d)  %s" % [th[k], t.tiers[k][2]], Vector2(74, 58 + k * 20), 13, PARCH if RunTraits.tier_of(id, n) >= k else MUTE, 550)
  var holders = HeroData.species.keys().filter(func(sp): return id in RunTraits.of(c, sp)); holders.sort()
  var hl = text(game, card, " · ".join(holders.map(func(sp): return HeroData.species[sp].n)), Vector2(74, 100), 11, Color(MUTE, 0.9), 550); hl.clip_text = true

static func high_scores(game: Node) -> void:
 var dlg = dialog(game, "Dungeon high scores", Vector2(1100, 660))
 var table = Dungeon.scores()
 if table.is_empty():
  text(game, dlg.box, "No banked runs yet. A run's score is banked when you run out of lives, conquer the dungeon or retire from the endless depths.", Vector2.ZERO, 17, MUTE, 1000); return
 var grid = GridContainer.new(); grid.columns = 7; grid.add_theme_constant_override("h_separation", 26); grid.add_theme_constant_override("v_separation", 8); dlg.box.add_child(grid)
 for head in ["#", "Guild", "Score", "Reached", "Wardens", "Difficulty", "Result"]: game.label(grid, head.to_upper(), 12, GOLDEN, false)
 for i in range(mini(15, table.size())):
  var e = table[i]
  var top = i < 3
  game.label(grid, str(i + 1), 18 if top else 16, GOLDEN if top else PARCH, false)
  game.label(grid, str(e.get("name", "?")), 16, PARCH, false)
  game.label(grid, str(int(e.get("score", 0))), 20 if top else 17, Color("ffd36e"), false)
  var depth_n = int(e.get("depth", 1))
  game.label(grid, ("Endless %d" % (depth_n - Dungeon.ACTS)) if depth_n > Dungeon.ACTS else "Depth %d · room %d" % [depth_n, int(e.get("room", 1))], 15, PARCH, false)
  game.label(grid, str(int(e.get("wardens", 0))), 15, PARCH, false)
  game.label(grid, str(e.get("difficulty", "")) + (" · A%d" % int(e.get("ascension", e.get("challenge", 0))) if int(e.get("ascension", e.get("challenge", 0))) > 0 else ""), 15, MUTE, false)
  game.label(grid, "%s · %s" % [str(e.get("outcome", "")), str(e.get("date", ""))], 14, MUTE, false)

static func guide(game: Node) -> void:
 var dlg = dialog(game, "The Dungeon", Vector2(1000, 760))
 for line in [
  "Three depths, each one an instance you choose at the top of the stairs: ten in all, from the Blight Forest to the Void Rift. Each has its own monsters, Warden boss and arena.",
  "Pick one room at a time along the glowing paths. Losing a fight costs a life; lose them all and the run ends. Campfires, healing springs and defeated Wardens restore them.",
  "Skirmishes reward one of three components, treasure one of three finished items, elites one of three relics. Wardens give a finished item, a Warden relic and a medal chest.",
  "Run traits: every creature carries up to three of its own traits (kin, element, class). Each run awakens a different set, each with its own flavour. Field different champions that share a trait to unlock it.",
  "Read the map: the arc under each fight room shows its threat (green easy, gold even, orange hard, red deadly). Elites are the greedy path: harder fights, but they pay relics.",
  "Win without losing a champion for a Flawless victory: +50% points and +25% gold. Positioning pays.",
  "Gold buys rerolls of any draft or reward (20, then 40, 60… in the same room). The Ember Altar trades a relic up a rarity; the Pale Ferryman takes a champion for a Boss relic.",
  "Score: rooms, wins, elites, Wardens and relics earn points, multiplied by the depth. Lives left add a bonus; difficulty and Ascension multiply the total. Clear the dungeon to unlock the next Ascension rank.",
  "After the third Warden, bank your score or go into the endless depths, where each depth is harder and worth more.",
 ]:
  var l = game.label(dlg.box, "◆  " + line, 16, PARCH); l.custom_minimum_size.x = 940
