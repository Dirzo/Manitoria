class_name FormationCell
extends Button
signal placed(hero_id: String, destination: int)
var hero_id = ""
var destination = 0

func _get_drag_data(_position: Vector2) -> Variant:
 if hero_id.is_empty(): return null
 var label = Label.new(); label.text = text; label.add_theme_color_override("font_color", Color("ead3a0"))
 set_drag_preview(label)
 return {"hero_id": hero_id}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
 return data is Dictionary and data.has("hero_id")

func _drop_data(_position: Vector2, data: Variant) -> void:
 placed.emit(data.hero_id, destination)
