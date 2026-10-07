class_name GearToken
extends Button
var game: Node
var payload: Dictionary={}
var target_hero=""
var target_slot=""
var bag_target=false
var glow=Color("d9b974")
var original_style: StyleBox
var hint_pixels := 0
var _drag_hint: Control

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

## Corner badge on a component: the best item it would forge with what you already own.
func add_combo_hint() -> void:
 if game==null or payload.is_empty() or not is_inside_tree():return
 var id=str(payload.get("id",""))
 var combos=GearUI.owned_combos(game,id,payload)
 tooltip_text+=GearUI.combo_text(id,combos)
 if combos.is_empty():return
 var s=hint_pixels*0.44
 GearUI.result_badge(game,self,combos[0].made,s,Vector2(hint_pixels-s*0.78,-s*0.22))
 if combos.size()>1:
  var more=Label.new();more.text="+%d"%(combos.size()-1);more.mouse_filter=Control.MOUSE_FILTER_IGNORE
  more.add_theme_font_size_override("font_size",13);more.add_theme_color_override("font_color",Color("ffd36e"));more.add_theme_color_override("font_outline_color",Color.BLACK);more.add_theme_constant_override("outline_size",4)
  more.position=Vector2(hint_pixels-s*0.7,s*0.72);add_child(more)

## While a component is dragged, champions holding a matching loose component preview the result.
func _forge_preview(data: Variant) -> String:
 if target_hero=="" or not data is Dictionary or not Forge.is_component(str(data.get("id",""))):return ""
 var hero=game.campaign.hero_by_id(target_hero)
 if hero.is_empty():return ""
 var eq=hero.get("equipment",{})
 if target_slot!="":
  var here=str(eq.get(target_slot,""))
  if data.get("kind","")=="equipped" and here!="":return ""
  return Forge.combine(str(data.id),here) if Forge.is_component(here) else ""
 for k in eq:
  if data.get("kind","")=="equipped" and str(data.get("owner",""))==target_hero and str(data.get("slot",""))==str(k):continue
  if Forge.is_component(str(eq[k])):
   var m=Forge.combine(str(data.id),str(eq[k]))
   if m!="":return m
 return ""

func _notification(what: int) -> void:
 if what==NOTIFICATION_DRAG_BEGIN and is_inside_tree():
  original_style=get_theme_stylebox("normal")
  var data=get_viewport().gui_get_drag_data()
  if _can_drop_data(Vector2.ZERO,data):
   var silhouette=name.begins_with("CarouselHero_")
   add_theme_stylebox_override("normal",game.style(Color(0.1,0.35,0.24,0.08) if silhouette else Color("225344"),Color("c8ff9d"),4,6,3))
   var made=_forge_preview(data)
   if made!="":
    var s=minf(size.x,size.y)*0.56
    _drag_hint=GearUI.result_badge(game,self,made,s,Vector2((size.x-s)*0.5,(size.y-s)*0.5-4))
    var cap=Label.new();cap.text=Forge.ITEMS[made].name;cap.mouse_filter=Control.MOUSE_FILTER_IGNORE;cap.add_theme_font_size_override("font_size",12);cap.add_theme_color_override("font_color",Color("c8ff9d"));cap.add_theme_color_override("font_outline_color",Color.BLACK);cap.add_theme_constant_override("outline_size",4)
    cap.position=Vector2(-s*0.4,s+2);cap.size=Vector2(s*1.8,16);cap.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_drag_hint.add_child(cap)
 if what==NOTIFICATION_DRAG_END:
  if original_style!=null:add_theme_stylebox_override("normal",original_style)
  if _drag_hint!=null and is_instance_valid(_drag_hint):_drag_hint.queue_free()
  _drag_hint=null
