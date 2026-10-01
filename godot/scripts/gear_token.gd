class_name GearToken
extends Button
var game: Node
var payload: Dictionary={}
var target_hero=""
var target_slot=""
var bag_target=false
var glow=Color("d9b974")
var original_style: StyleBox

func _ready() -> void:
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 focus_mode=Control.FOCUS_ALL
 original_style=get_theme_stylebox("normal")

func _get_drag_data(_position: Vector2) -> Variant:
 if payload.is_empty():return null
 var item=ItemEffects.definition(str(payload.get("id","")))
 if item.is_empty():return null
 if payload.get("kind","")=="offer" and (not GearUI.stock_ok(game.campaign,int(payload.index)) or game.campaign.state.gold<item.price):return null
 var preview=PanelContainer.new();preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
 preview.add_theme_stylebox_override("panel",game.style(Color("231b40"),Color("ffd36e"),4,8,2))
 var box=VBoxContainer.new();preview.add_child(box);AbilityArt.icon(box,item.art,80)
 game.label(box,item.name,14,game.WHITE,false)
 set_drag_preview(preview)
 return payload.duplicate()

func _can_drop_data(_position: Vector2,data: Variant) -> bool:
 return GearUI.can_drop(game,data,target_hero,target_slot,bag_target)

func _drop_data(_position: Vector2,data: Variant) -> void:
 GearUI.apply_drop(game,data,target_hero,target_slot,bag_target)

func _notification(what: int) -> void:
 if what==NOTIFICATION_DRAG_BEGIN and is_inside_tree():
  original_style=get_theme_stylebox("normal")
  if _can_drop_data(Vector2.ZERO,get_viewport().gui_get_drag_data()):add_theme_stylebox_override("normal",game.style(Color("225344"),Color("c8ff9d"),4,6,3))
 if what==NOTIFICATION_DRAG_END and original_style!=null:add_theme_stylebox_override("normal",original_style)
