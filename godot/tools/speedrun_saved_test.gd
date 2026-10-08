extends SceneTree
static func equivalent(a: Variant,b: Variant) -> bool:
 if (a is float or a is int) and (b is float or b is int):return absf(float(a)-float(b))<=1e-9*maxf(1.0,maxf(absf(float(a)),absf(float(b))))
 if a is Dictionary and b is Dictionary:
  if a.size()!=b.size():return false
  for key in a:
   if not b.has(key) or not equivalent(a[key],b[key]):return false
  return true
 if a is Array and b is Array:
  if a.size()!=b.size():return false
  for i in range(a.size()):
   if not equivalent(a[i],b[i]):return false
  return true
 return a==b
func _initialize() -> void:
 var reference=JSON.parse_string(FileAccess.get_file_as_string("user://speedrun_reference_5.json"))
 var records=JSON.parse_string(FileAccess.get_file_as_string(SpeedrunLab.RESULTS_PATH))
 if not reference is Dictionary or not records is Array or records.is_empty():
  push_error("Needs user://speedrun_reference_5.json and a saved benchmark: run a five-cup benchmark in the same user-data folder first")
  print("SPEEDRUN SAVED EQUIVALENCE: skipped, no reference data");quit(1);return
 var actual=records[0];var failures=0
 for key in ["matches","purchases","decisions","gold_left","final_roster"]:
  if not equivalent(actual[key],reference[key]):failures+=1;push_error("Full-run equivalence: "+key)
 print("SPEEDRUN SAVED EQUIVALENCE: 5 checks; %d failures"%failures);quit(1 if failures else 0)
