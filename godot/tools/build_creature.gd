extends SceneTree
## Step 2 import pipeline: merges a creature's Meshy exports into one game model with the 14-clip set.
##
##   godot --headless --path godot -s tools/build_creature.gd -- --in <folder> --species <name>
##         [--out res://assets/beasts/<name>.glb] [--yaw 180] [--keep-root-motion] [--dry]
##
## Input folder (see art/combat_clips/README.md):
##   <species>__model.glb|fbx      rigged model (optional; the first clip file is used otherwise)
##   <species>__<clip>.glb|fbx     one clip per file: its longest animation becomes <clip>
##   <species>__set.glb|fbx        optional: clips inside that already carry the exact game names
## Output: one GLB with an AnimationPlayer holding the clips under their game names, scaled to the
## standard 1.7 height, grounded, centred, facing +Z, root motion stripped (in-place).
## The model it replaces is copied to <folder>/<species>.previous.glb first.

const CreatureBuilder = preload("res://tools/creature_builder.gd")

func _init() -> void:
	run.call_deferred()

func arg(name: String, fallback: String = "") -> String:
	var a = OS.get_cmdline_user_args()
	var i = a.find(name)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else fallback

func flag(name: String) -> bool:
	return OS.get_cmdline_user_args().has(name)

func run() -> void:
	var folder = arg("--in")
	var sp = arg("--species")
	if folder.is_empty() or sp.is_empty():
		printerr("usage: -- --in <folder> --species <name> [--out path] [--yaw 180] [--keep-root-motion] [--dry]")
		quit(2); return
	var out = arg("--out", "res://assets/beasts/%s.glb" % sp)
	var builder = CreatureBuilder.new()
	var result = builder.build(folder, sp, out, float(arg("--yaw", "0")), flag("--keep-root-motion"), flag("--dry"))
	for line in builder.report: print(line)
	quit(0 if result.ok else 1)

