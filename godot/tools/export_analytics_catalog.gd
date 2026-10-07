extends SceneTree
func _init() -> void:
 var file=FileAccess.open("user://analytics-evolutions.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(Evolutions.DATA));file.close();quit()
