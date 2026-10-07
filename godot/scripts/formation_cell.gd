class_name FormationCell
extends Button
signal placed(hero_id: String, destination: int)
var hero_id = ""
var destination = 0
var caption = "+"
var selected = false

func polygon() -> PackedVector2Array:
 return PackedVector2Array([Vector2(size.x * 0.25, 2), Vector2(size.x * 0.75, 2), Vector2(size.x - 2, size.y * 0.5), Vector2(size.x * 0.75, size.y - 2), Vector2(size.x * 0.25, size.y - 2), Vector2(2, size.y * 0.5)])

func _ready() -> void:
 for state in ["normal", "hover", "pressed", "focus"]: add_theme_stylebox_override(state, StyleBoxEmpty.new())
 mouse_entered.connect(queue_redraw); mouse_exited.connect(queue_redraw)
 focus_entered.connect(queue_redraw); focus_exited.connect(queue_redraw)
 resized.connect(queue_redraw)

func _has_point(point: Vector2) -> bool:
 return Geometry2D.is_point_in_polygon(point, polygon())

func _draw() -> void:
 var points = polygon()
 var fill = Color("45636b") if selected else (Color("294b58") if is_hovered() else Color("17303b"))
 var rim = Color("f1d79f") if selected or has_focus() else Color("557879")
 draw_colored_polygon(points, fill)
 points.append(points[0]); draw_polyline(points, rim, 2.0, true)
 var font = get_theme_font("font")
 var display = caption
 while display.length() > 2 and font.get_string_size(display, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > size.x * 0.78: display = display.left(display.length() - 2) + "…"
 var width = font.get_string_size(display, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
 draw_string(font, Vector2((size.x - width) * 0.5, size.y * 0.5 + 4), display, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, rim)

func _get_drag_data(_position: Vector2) -> Variant:
 if hero_id.is_empty(): return null
 var label = Label.new(); label.text = caption; label.add_theme_color_override("font_color", Color("ead3a0"))
 set_drag_preview(label)
 return {"hero_id": hero_id}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
 return data is Dictionary and data.has("hero_id")

func _drop_data(_position: Vector2, data: Variant) -> void:
 placed.emit(data.hero_id, destination)
