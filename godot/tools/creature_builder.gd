extends RefCounted
## Merges a creature's Meshy exports into one game model. Driven by tools/build_creature.gd (CLI)
## and tools/build_creature_test.gd. See that CLI for the input contract.

const CLIPS := ["idle", "idle_combat", "walk", "run", "attack", "attack_1", "attack_2", "attack_heavy", "cast",
	"hit_light", "hit_heavy", "stun", "death", "spawn", "victory"]
const LOOPS := ["idle", "idle_combat", "walk", "run", "stun", "victory"]
const HEIGHT := 1.7
const EXTS := ["glb", "gltf", "fbx"]

var report := []
var feet_path := "res://tools/feet.json"   # tests point this at a scratch copy

## Returns {"ok", "clips", "scale", "out"}. Usable from tests.
func build(folder: String, sp: String, out: String, yaw: float = 0.0, keep_root_motion: bool = false, dry: bool = false) -> Dictionary:
	report.clear()
	var files = {}   # clip -> path ; plus "model" / "set"
	if not DirAccess.dir_exists_absolute(folder):
		report.append("ERROR: no folder " + folder); return {"ok": false}
	for f in DirAccess.get_files_at(folder):
		var ext = f.get_extension().to_lower()
		if ext not in EXTS or not f.to_lower().begins_with(sp.to_lower() + "__"): continue
		var key = f.get_basename().substr(sp.length() + 2).to_lower()
		if key in CLIPS or key in ["model", "set"]: files[key] = folder.path_join(f)
		else: report.append("skipped %s (unknown clip name '%s')" % [f, key])
	var clip_keys = files.keys().filter(func(k): return k in CLIPS)
	if clip_keys.is_empty() and not files.has("set"):
		report.append("ERROR: no <%s>__<clip> files in %s" % [sp, folder]); return {"ok": false}
	var base_path = files.get("model", files.get("set", files.get(clip_keys[0] if not clip_keys.is_empty() else "", "")))
	var base: Node3D = load_scene(base_path)
	if base == null: return {"ok": false}
	var player: AnimationPlayer = first(base, "AnimationPlayer")
	var skeleton: Skeleton3D = first(base, "Skeleton3D")
	if skeleton == null:
		report.append("ERROR: %s has no skeleton (rig it first)" % base_path); base.free(); return {"ok": false}
	if player == null:
		player = AnimationPlayer.new(); player.name = "AnimationPlayer"; base.add_child(player); player.owner = base
	var player_root: Node = player.get_node(player.root_node)
	var clips = {}
	# Named clips from a set file.
	if files.has("set"):
		var set_scene = load_scene(files.set)
		if set_scene:
			var sp_player: AnimationPlayer = first(set_scene, "AnimationPlayer")
			if sp_player:
				for n in sp_player.get_animation_list():
					var clean = str(n).get_slice("|", str(n).get_slice_count("|") - 1).to_lower()
					if clean in CLIPS: clips[clean] = sp_player.get_animation(n).duplicate(true)
			set_scene.free()
	# One clip per file.
	for key in clip_keys:
		var scene = load_scene(files[key])
		if scene == null: continue
		var p: AnimationPlayer = first(scene, "AnimationPlayer")
		if p == null or p.get_animation_list().is_empty():
			report.append("WARNING: %s has no animation" % files[key].get_file()); scene.free(); continue
		var best: Animation = null
		for n in p.get_animation_list():
			var a = p.get_animation(n)
			if best == null or a.length > best.length: best = a
		clips[key] = best.duplicate(true)
		scene.free()
	if clips.has("attack") and not clips.has("attack_1"): clips["attack_1"] = clips["attack"]
	if clips.has("attack_1") and not clips.has("attack"): clips["attack"] = clips["attack_1"]   # older code paths
	# Point every track at this model's skeleton and strip root motion.
	var skel_path = player_root.get_path_to(skeleton)
	var remapped = 0; var dropped = 0; var drift_removed = 0.0
	for key in clips:
		var anim: Animation = clips[key]
		for t in range(anim.get_track_count() - 1, -1, -1):
			var path = anim.track_get_path(t)
			var bone = path.get_concatenated_subnames()
			if bone.is_empty():
				if not player_root.has_node(NodePath(str(path))): anim.remove_track(t); dropped += 1
				continue
			if skeleton.find_bone(bone) < 0:
				anim.remove_track(t); dropped += 1; continue
			var fixed = NodePath(str(skel_path) + ":" + bone)
			if fixed != path: anim.track_set_path(t, fixed); remapped += 1
		if not keep_root_motion: drift_removed = maxf(drift_removed, strip_root_motion(anim, skeleton))
		anim.loop_mode = Animation.LOOP_LINEAR if key in LOOPS else Animation.LOOP_NONE
	# Replace the player's animations with the game set.
	for lib in player.get_animation_library_list(): player.remove_animation_library(lib)
	var library = AnimationLibrary.new()
	for key in clips: library.add_animation(key, clips[key])
	player.add_animation_library("", library)
	# Normalise: 1.7 tall, feet on the ground, centred, facing +Z.
	var box = bounds(base)
	var scale = HEIGHT / maxf(0.001, box.size.y)
	var wrapper = Node3D.new(); wrapper.name = sp
	wrapper.add_child(base)
	base.owner = null
	set_owner_recursive(base, wrapper)
	base.rotation.y = deg_to_rad(yaw)
	base.scale = Vector3.ONE * scale
	var centre = Vector3(box.position.x + box.size.x * 0.5, box.position.y, box.position.z + box.size.z * 0.5)
	base.position = -(Basis(Vector3.UP, deg_to_rad(yaw)) * centre) * scale
	var have = CLIPS.filter(func(c): return clips.has(c) and c != "attack")
	var missing = CLIPS.filter(func(c): return not clips.has(c) and c != "attack")
	report.append("%s: %d clips %s" % [sp, have.size(), str(have)])
	if not missing.is_empty(): report.append("  missing (fallbacks will be used): %s" % str(missing))
	report.append("  scale x%.3f (was %.2f tall), %d track paths remapped, %d tracks dropped, root drift removed up to %.2f" % [scale, box.size.y, remapped, dropped, drift_removed])
	for need in ["idle", "walk", "death"]:
		if not clips.has(need): report.append("  WARNING: required clip '%s' is missing" % need)
	if not clips.has("attack_1"): report.append("  WARNING: no attack clip")
	if not clips.has("cast"): report.append("  WARNING: required clip 'cast' is missing")
	var ok = clips.has("idle") and clips.has("attack_1")
	var foot_bones = find_feet(skeleton)
	if ok and not dry: update_feet(sp, skeleton, foot_bones)
	if ok and not dry:
		var abs_out = ProjectSettings.globalize_path(out)
		if FileAccess.file_exists(abs_out):
			var backup = folder.path_join(sp + ".previous.glb")
			if not FileAccess.file_exists(backup): DirAccess.copy_absolute(abs_out, backup)
			report.append("  previous model backed up to " + backup)
		var doc = GLTFDocument.new(); var state = GLTFState.new()
		var err = doc.append_from_scene(wrapper, state)
		if err == OK: err = doc.write_to_filesystem(state, abs_out)
		if err != OK: report.append("ERROR: export failed (%d)" % err); ok = false
		else: report.append("  wrote " + out)
	wrapper.free()
	return {"ok": ok, "clips": have, "scale": scale, "out": out}

func load_scene(path: String) -> Node3D:
	if path.is_empty(): return null
	var doc = FBXDocument.new() if path.get_extension().to_lower() == "fbx" else GLTFDocument.new()
	var state = FBXState.new() if path.get_extension().to_lower() == "fbx" else GLTFState.new()
	var err = doc.append_from_file(path, state)
	if err != OK:
		report.append("ERROR: could not read %s (%d)" % [path.get_file(), err]); return null
	return doc.generate_scene(state) as Node3D

func first(node: Node, type: String) -> Node:
	var found = node.find_children("*", type, true, false)
	return found[0] if not found.is_empty() else null

func set_owner_recursive(node: Node, owner_node: Node) -> void:
	for c in node.get_children():
		c.owner = owner_node
		set_owner_recursive(c, owner_node)
	node.owner = owner_node if node != owner_node else null

## Union of the meshes' bounds in the scene root's space (rest pose).
func bounds(root: Node3D) -> AABB:
	var box := AABB(); var first_box = true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var xf = Transform3D.IDENTITY; var n: Node = mi
		while n != null and n != root:
			if n is Node3D: xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var b = xf * (mi as MeshInstance3D).get_aabb()
		box = b if first_box else box.merge(b); first_box = false
	return box

## In-place clips: remove the horizontal travel of the top-most translated bone, keeping its bob and sway.
## Returns how far it had drifted.
func strip_root_motion(anim: Animation, skeleton: Skeleton3D) -> float:
	var best = -1; var depth = 999
	for t in anim.get_track_count():
		if anim.track_get_type(t) != Animation.TYPE_POSITION_3D: continue
		var b = skeleton.find_bone(anim.track_get_path(t).get_concatenated_subnames())
		if b < 0: continue
		var d = 0; var p = b
		while skeleton.get_bone_parent(p) >= 0: p = skeleton.get_bone_parent(p); d += 1
		if d < depth: depth = d; best = t
	if best < 0 or anim.track_get_key_count(best) < 2: return 0.0
	var n = anim.track_get_key_count(best)
	var p0: Vector3 = anim.track_get_key_value(best, 0)
	var p1: Vector3 = anim.track_get_key_value(best, n - 1)
	var drift = Vector3(p1.x - p0.x, 0.0, p1.z - p0.z)
	var t0 = anim.track_get_key_time(best, 0); var t1 = anim.track_get_key_time(best, n - 1)
	for k in n:
		var f = (anim.track_get_key_time(best, k) - t0) / maxf(0.0001, t1 - t0)
		var v: Vector3 = anim.track_get_key_value(best, k)
		anim.track_set_key_value(best, k, v - drift * f)
	return drift.length()

## Feet for the gait tools: leaf bones resting within the bottom 8% of the rig's height. A new rig has new
## bone names, so tools/feet.json must follow it.
func find_feet(sk: Skeleton3D) -> Array:
	var lo = INF; var hi = -INF
	for i in sk.get_bone_count():
		var y = sk.get_bone_global_rest(i).origin.y; lo = minf(lo, y); hi = maxf(hi, y)
	var out = []
	for i in sk.get_bone_count():
		if sk.get_bone_children(i).is_empty() and sk.get_bone_global_rest(i).origin.y < lo + (hi - lo) * 0.08: out.append(i)
	return out

func update_feet(sp: String, sk: Skeleton3D, foot_bones: Array) -> void:
	var path = feet_path
	if not FileAccess.file_exists(path): return
	var feet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var entry: Dictionary = feet.get(sp, {"gait": "quad", "flyer": false, "step": 1.0})
	if entry.get("gait", "") == "slither" or entry.get("flyer", false): return
	if foot_bones.size() not in [2, 4, 6, 8]:
		report.append("  WARNING: found %d foot bones; set %s's feet in tools/feet.json by hand" % [foot_bones.size(), sp]); return
	var names = []; var hips = []
	for b in foot_bones:
		names.append(sk.get_bone_name(b))
		var h = b
		for k in 3: h = sk.get_bone_parent(h) if sk.get_bone_parent(h) >= 0 else h
		hips.append(sk.get_bone_name(h))
	entry["feet"] = names; entry["hips"] = hips; entry["gait"] = "biped" if names.size() == 2 else entry.get("gait", "quad")
	feet[sp] = entry
	var f = FileAccess.open(path, FileAccess.WRITE); f.store_string(JSON.stringify(feet))
	report.append("  feet %s written to tools/feet.json (re-run tools/gait_probe.gd and update scripts/gait_rates.gd)" % str(names))
