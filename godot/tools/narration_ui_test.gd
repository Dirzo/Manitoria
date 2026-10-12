extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game = load("res://scripts/main.gd").new(); root.add_child(game)
 game.set_process(false)
 var recorder = game.playtest
 assert(recorder!=null and recorder.narration_label!=null)
 DirAccess.make_dir_recursive_absolute(recorder.narration_folder)
 var status_path = recorder.narration_folder.path_join("status.json")
 var status = FileAccess.open(status_path,FileAccess.WRITE)
 status.store_string(JSON.stringify({"state":"paused","updated_ms":int(Time.get_unix_time_from_system()*1000)}));status.close()
 recorder._process(.6)
 assert(recorder.narration_label.text.begins_with("MIC PAUSED"))
 var key = InputEventKey.new(); key.keycode=KEY_F8;key.pressed=true
 recorder.input(key)
 assert(FileAccess.file_exists(recorder.narration_folder.path_join("control.json")))
 status = FileAccess.open(status_path,FileAccess.WRITE)
 status.store_string(JSON.stringify({"state":"recording","updated_ms":0}));status.close()
 recorder._process(.6)
 assert(recorder.narration_label.text.begins_with("MIC OFF"),"Dead helper must never appear to be recording")
 recorder.finish()
 print("PASS: microphone pause request, paused indicator, stale helper detection and shared session")
 quit()
