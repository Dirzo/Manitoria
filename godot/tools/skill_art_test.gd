extends SceneTree
var checks=0
var failures=0
func expect(condition: bool,message: String) -> void:
 checks+=1
 if not condition:
  failures+=1
  push_error(message)
func _initialize() -> void:
 HeroData.load_data()
 var book=JSON.parse_string(FileAccess.get_file_as_string("res://data/skill-audit.json"))
 var actions=0
 for sp in book:
  for key in book[sp]:
   actions+=1
   var art_key=HeroData.species[sp].ab if key=="signature" else "discovery:%s:%s"%[sp,key]
   var file="signature-%s.png"%sp if key=="signature" else "%s-%s.png"%[sp,key]
   var texture=AbilityArt.texture(art_key)
   expect(texture!=null,"Missing texture: %s:%s"%[sp,key])
   if texture==null:continue
   expect(texture.resource_path=="res://assets/abilities/"+file,"Wrong icon route: %s:%s"%[sp,key])
   expect(texture.get_width()<=256 and texture.get_height()<=256,"Unoptimized runtime texture: %s:%s"%[sp,key])
 expect(actions==473,"Expected 473 action icons")
 print("Skill art integration: ",checks," checks, ",failures," failures; ",actions," icons")
 quit(1 if failures else 0)
