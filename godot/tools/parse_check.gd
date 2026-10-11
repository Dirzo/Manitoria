extends SceneTree
## Loads every script so parse and type errors surface without running the game.
func _init() -> void:
	var bad = 0
	for dir_path in ["res://scripts", "res://scripts/vfx"]:
		var d = DirAccess.open(dir_path)
		for f in d.get_files():
			if f.ends_with(".gd"):
				var s = load(dir_path + "/" + f)
				if s == null: bad += 1; print("FAILED ", f)
	print("parse check: %d failures" % bad)
	quit()
