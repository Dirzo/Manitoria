class_name CombatGraph
extends Control
var rows: Array = []
var metric = "damage"
var duration = 1.0
var lines: Array = []
var ceiling = 1.0
const COLORS = [Color("7de0c1"),Color("ed9d80")]
func _ready() -> void:
 custom_minimum_size = Vector2(0,125); size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var count = maxi(2,ceili(duration)+2)
 for team in range(2):
  var values = []; var total = 0.0
  for second in range(count):
   for row in rows:
    if int(row.team) == team: total += row.get("timeline",{}).get(str(second),{}).get(metric,0.0)
   values.append(total)
  lines.append(values); ceiling = maxf(ceiling,total)
 resized.connect(queue_redraw)
func _draw() -> void:
 var rect = Rect2(50,12,maxf(20,size.x-66),size.y-50)
 var font = ThemeDB.fallback_font
 for i in range(5):
  var y = rect.end.y-rect.size.y*i/4.0
  draw_line(Vector2(rect.position.x,y),Vector2(rect.end.x,y),Color("29414d"),1)
  draw_string(font,Vector2(0,y+4),str(roundi(ceiling*i/4)),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("9ab1bc"))
 for team in range(lines.size()):
  var points = PackedVector2Array([Vector2(rect.position.x,rect.end.y)])
  for i in range(lines[team].size()): points.append(Vector2(rect.position.x+rect.size.x*minf(1,float(i+1)/maxf(1,duration)),rect.end.y-rect.size.y*lines[team][i]/ceiling))
  draw_polyline(points,COLORS[team],2.5,true)
 for i in range(5):
  draw_string(font,Vector2(rect.position.x+rect.size.x*i/4.0-8,size.y-18),"%ds" % roundi(duration*i/4.0),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("9ab1bc"))
 tooltip_text = "Cumulative %s over time. Teal: your club. Coral: opposition. One-second samples." % metric
