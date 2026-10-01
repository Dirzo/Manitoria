class_name TourPath
extends Control
# The World Tour as a road of six arenas: conquered stops in gold, the current arena
# glowing in its region colour, the road ahead dimmed.
var level=1
var cleared=0  # cups won so far
var t=0.0

func _ready() -> void:
 custom_minimum_size=Vector2(312,62);mouse_filter=Control.MOUSE_FILTER_PASS
 var start=int((level-1)/6)*6+1
 var tips=[]
 for i in range(6):
  var r=WorldTour.REGIONS[(start+i-1)%WorldTour.REGIONS.size()]
  tips.append("Cup %d · %s — %s"%[start+i,r.name,r.place])
 tooltip_text="\n".join(tips)

func _process(delta: float) -> void:
 t+=delta;queue_redraw()

func _draw() -> void:
 var start=int((level-1)/6)*6+1
 var gap=52.0;var y=22.0;var x0=26.0
 var font=load("res://assets/fonts/uncialantiqua.ttf")
 for i in range(5):
  var lv=start+i
  var done=lv<level
  draw_line(Vector2(x0+i*gap+11,y),Vector2(x0+(i+1)*gap-11,y),Color("e8c27a") if done else Color(1,1,1,.22),3.0 if done else 2.0)
 for i in range(6):
  var lv=start+i;var r=WorldTour.REGIONS[(lv-1)%WorldTour.REGIONS.size()]
  var c=Color(r.color);var p=Vector2(x0+i*gap,y)
  if lv<level:
   draw_circle(p,11,Color("e8c27a"));draw_circle(p,7.5,Color("3a2a14"))
   draw_polyline(PackedVector2Array([p+Vector2(-4,0),p+Vector2(-1,3.5),p+Vector2(4.5,-3.5)]),Color("ffe4a0"),2.0,true)
  elif lv==level:
   var pulse=.5+.5*sin(t*2.6)
   draw_circle(p,15+pulse*4,Color(c,.18+.12*pulse))
   draw_circle(p,12,c);draw_circle(p,8,Color("1b1420"));draw_circle(p,4.5,c.lightened(.35))
  else:
   draw_circle(p,9,Color(c,.35));draw_circle(p,6.5,Color("10141a"))
  if lv!=level:continue
  var word=str(r.name).split(" ")[0]
  var w=font.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
  draw_string(font,p+Vector2(-w/2,30),word,HORIZONTAL_ALIGNMENT_LEFT,-1,13,c.lightened(.2))
