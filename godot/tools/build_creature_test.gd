extends SceneTree
## Checks tools/creature_builder.gd on synthetic "Meshy exports" made from the current direwolf:
## one GLB per clip with Meshy-style animation names, the wrong scale, an off-centre origin, and a walk
## exported with root motion. The build must rename clips, keep poses identical, strip the walk's
## travel, normalise to 1.7 tall on the ground, flag loops, skip unknown files and round-trip through GLB.
## Run: godot --headless --path godot -s tools/build_creature_test.gd
const CreatureBuilder = preload("res://tools/creature_builder.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func _init() -> void:
	run.call_deferred()

## A copy of the direwolf holding only `clip`, renamed the way Meshy names its exports.
func fake_export(dir: String, file: String, clip: String, drift: float = 0.0) -> void:
	var scene: Node3D = load("res://assets/beasts/direwolf.glb").instantiate()
	var ap: AnimationPlayer = scene.find_children("*", "AnimationPlayer", true, false)[0]
	var anim: Animation = ap.get_animation(clip).duplicate(true)
	if drift > 0.0:
		for t in anim.get_track_count():
			if anim.track_get_type(t) != Animation.TYPE_POSITION_3D: continue
			for k in anim.track_get_key_count(t):
				var f = anim.track_get_key_time(t, k) / anim.length
				anim.track_set_key_value(t, k, anim.track_get_key_value(t, k) + Vector3(0, 0, drift * f))
	for lib in ap.get_animation_library_list(): ap.remove_animation_library(lib)
	var library = AnimationLibrary.new(); library.add_animation("Armature|mixamo.com|Layer0", anim)
	ap.add_animation_library("", library)
	var holder = Node3D.new(); holder.add_child(scene); scene.owner = holder
	for n in scene.find_children("*", "", true, false): n.owner = holder
	scene.scale = Vector3.ONE * 2.5; scene.position = Vector3(3.0, 1.0, -2.0)
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	doc.append_from_scene(holder, state); doc.write_to_filesystem(state, dir.path_join(file))
	holder.free()

func pose_at(scene: Node, clip: String, t: float) -> Array:
	var ap: AnimationPlayer = scene.find_children("*", "AnimationPlayer", true, false)[0]
	var sk: Skeleton3D = scene.find_children("*", "Skeleton3D", true, false)[0]
	ap.play(clip); ap.speed_scale = 0.0; ap.seek(t, true)
	var out = []
	for i in sk.get_bone_count(): out.append(sk.get_bone_pose_rotation(i))
	return out

func diff(a: Array, b: Array) -> float:
	var w = 0.0
	for i in mini(a.size(), b.size()):
		var d: Quaternion = a[i].inverse() * b[i]
		w = maxf(w, 2.0 * atan2(Vector3(d.x, d.y, d.z).length(), absf(d.w)))
	return w

func run() -> void:
	var dir = ProjectSettings.globalize_path("user://build_creature_test/direwolf")
	DirAccess.make_dir_recursive_absolute(dir)
	for f in DirAccess.get_files_at(dir): DirAccess.remove_absolute(dir.path_join(f))
	fake_export(dir, "direwolf__model.glb", "idle")
	fake_export(dir, "direwolf__idle.glb", "idle")
	fake_export(dir, "direwolf__walk.glb", "walk", 1.5)
	fake_export(dir, "direwolf__attack_1.glb", "attack")
	fake_export(dir, "direwolf__cast.glb", "cast")
	fake_export(dir, "direwolf__death.glb", "death")
	fake_export(dir, "direwolf__dance.glb", "idle")
	var out = ProjectSettings.globalize_path("user://build_creature_test/direwolf_built.glb")
	var builder = CreatureBuilder.new()
	var feet_copy = "user://build_creature_test/feet.json"
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://tools/feet.json"), ProjectSettings.globalize_path(feet_copy))
	builder.feet_path = feet_copy
	var result = builder.build(dir, "direwolf", out)
	for line in builder.report: print("  | ", line)
	check(result.ok, "build succeeds")
	check(result.clips.has("attack_1") and result.clips.has("walk") and result.clips.has("cast") and result.clips.size() == 5, "clips renamed to game names %s" % str(result.clips))
	check(builder.report.any(func(l): return l.contains("dance")), "unknown clip files are reported and skipped")
	var hand: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tools/feet.json")).direwolf.feet
	var found: Array = JSON.parse_string(FileAccess.get_file_as_string(feet_copy)).direwolf.feet
	hand.sort(); found.sort()
	check(hand == found, "foot bones detected on the rig match the hand-made list %s" % str(found))
	# Read the result back exactly as the game would see a freshly exported GLB.
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	check(doc.append_from_file(out, state) == OK, "output GLB loads")
	var built: Node3D = doc.generate_scene(state)
	get_root().add_child(built)
	await process_frame
	var ap: AnimationPlayer = built.find_children("*", "AnimationPlayer", true, false)[0]
	var names = Array(ap.get_animation_list())
	check(names.has("attack_1") and names.has("attack") and names.has("idle") and names.has("death"), "player holds the game clips %s" % str(names))
	var box := AABB(); var first = true
	for mi in built.find_children("*", "MeshInstance3D", true, false):
		var b = mi.global_transform * mi.get_aabb(); box = b if first else box.merge(b); first = false
	check(absf(box.size.y - 1.7) < 0.03 and absf(box.position.y) < 0.03, "normalised to 1.7 tall on the ground (%.3f tall, base %.3f)" % [box.size.y, box.position.y])
	check(Vector2(box.position.x + box.size.x / 2, box.position.z + box.size.z / 2).length() < 0.05, "centred on the origin")
	# Poses survive the round trip (bone rotations are scale-independent).
	var original: Node3D = load("res://assets/beasts/direwolf.glb").instantiate(); get_root().add_child(original)
	await process_frame
	for clip_pair in [["attack", "attack_1", 0.32], ["cast", "cast", 0.5], ["death", "death", 1.0]]:
		var d = diff(pose_at(original, clip_pair[0], clip_pair[2]), pose_at(built, clip_pair[1], clip_pair[2]))
		check(d < 0.01, "%s pose matches the source clip at %.2fs (%.4f rad)" % [clip_pair[1], clip_pair[2], d])
	# Root motion stripped from the walk.
	var walk: Animation = ap.get_animation("walk")
	var root_track = -1
	for t in walk.get_track_count():
		if walk.track_get_type(t) == Animation.TYPE_POSITION_3D: root_track = t; break
	if root_track >= 0:
		var a: Vector3 = walk.track_get_key_value(root_track, 0)
		var b: Vector3 = walk.track_get_key_value(root_track, walk.track_get_key_count(root_track) - 1)
		check(Vector2(b.x - a.x, b.z - a.z).length() < 0.01, "walk travel stripped (%.4f left)" % Vector2(b.x - a.x, b.z - a.z).length())
	# The animator accepts it, and loops the cycles (glTF itself carries no loop flag).
	var anim = CombatAnimator.new(); anim.setup(built, "direwolf", false, 1.0)
	check(anim.ok and anim.clip_for("attack", 0) == "attack_1", "CombatAnimator drives the built model")
	check(walk.loop_mode == Animation.LOOP_LINEAR and ap.get_animation("idle").loop_mode == Animation.LOOP_LINEAR and ap.get_animation("attack_1").loop_mode == Animation.LOOP_NONE, "cycles loop in game, actions don't")
	print("\n%s: %d failure(s)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)
