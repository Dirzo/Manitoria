extends SceneTree
func _init() -> void:
 HeroData.load_data()
 var out=[]
 for sp in HeroData.species:
  var s=HeroData.species[sp]
  out.append({"species":sp,"index":"signature","name":s.ability_name,"effect":s.ab,"description":s.ability_description})
  for i in range(16):
   var a=HeroData.learned_ability(sp,i)
   if a.is_empty():continue
   a=a.duplicate(true);a.species=sp;a.index=str(i);out.append(a)
 var file=FileAccess.open("res://data/skill-inventory.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(out,"  "))
 print("Exported ",out.size()," signature, learned and ascended actions")
 quit()
