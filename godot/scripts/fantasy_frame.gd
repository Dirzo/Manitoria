class_name FantasyFrame
extends PanelContainer
static var surface: Texture2D
var accent=Color("d9b974")
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_PASS
 resized.connect(queue_redraw)
func _draw() -> void:
 if surface==null and ResourceLoader.exists("res://assets/ui/arena-vellum.png"):surface=load("res://assets/ui/arena-vellum.png")
 if surface!=null:draw_texture_rect(surface,Rect2(Vector2(4,4),size-Vector2(8,8)),true,Color(0.76,0.69,0.48,0.07))
 return
 var c=accent; c.a=.8
 for pos in [Vector2(8,8),Vector2(size.x-8,8),Vector2(8,size.y-8),Vector2(size.x-8,size.y-8)]:
  var sx=1.0 if pos.x<size.x*.5 else -1.0
  var sy=1.0 if pos.y<size.y*.5 else -1.0
  draw_polyline(PackedVector2Array([pos+Vector2(0,25*sy),pos,pos+Vector2(25*sx,0)]),c,2,true)
  var diamond=pos+Vector2(7*sx,7*sy)
  draw_colored_polygon(PackedVector2Array([diamond+Vector2(0,-3),diamond+Vector2(3,0),diamond+Vector2(0,3),diamond+Vector2(-3,0)]),c)
 draw_line(Vector2(size.x*.5-24,3),Vector2(size.x*.5+24,3),c,2,true)
