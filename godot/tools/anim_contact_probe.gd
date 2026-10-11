extends SceneTree
## Measures the timing landmarks of every creature's attack and cast clip and writes data/anim_contact.json,
## which CombatAnimator uses to line the authored motion up with the simulation's windup and hit.
##   ready  - end of the anticipation (the still moment before the strike burst)
##   hit    - contact: the strike burst has stopped (tip speed under a quarter of its peak)
##   resume - where motion starts again after the contact hold (casts skip this dead hold)
## Fractions of clip length. Speed = mean world-space speed of the rig's leaf bones, sampled at 60 Hz.
## Run: godot --headless --path godot -s tools/anim_contact_probe.gd   (PRINT=1 prints the speed curves)
const RATE := 60.0
const CLIPS := ["attack", "attack_1", "attack_2", "attack_heavy", "cast"]

func _init() -> void:
	run.call_deferred()

static func landmarks(speeds: Array) -> Dictionary:
	var n = speeds.size() - 1
	var peak = int(n * 0.12)
	for f in range(int(n * 0.12), int(n * 0.72) + 1):
		if speeds[f] > speeds[peak]: peak = f
	var top = maxf(0.0001, speeds[peak])
	var hit = peak
	for f in range(peak, n + 1):
		hit = f
		if speeds[f] < top * 0.25: break
	# Anticipation: the latest quiet frame before the strike burst, if there was a wind-up burst before it.
	var ready = hit
	var low = peak
	for f in range(peak - 1, int(n * 0.08) - 1, -1):
		if speeds[f] <= speeds[low]: low = f
		if speeds[f] > top * 0.6 and speeds[low] < top * 0.3: break
	var before = 0.0
	for f in range(0, low): before = maxf(before, speeds[f])
	if low < peak and speeds[low] < top * 0.3 and before >= top * 0.2: ready = low
	var resume = hit
	for f in range(hit, n + 1):
		if speeds[f] > top * 0.15: break
		resume = f
	return {"ready": snappedf(float(ready) / n, 0.01), "hit": snappedf(float(hit) / n, 0.01), "resume": snappedf(float(resume) / n, 0.01)}

func run() -> void:
	HeroData.load_data()
	var verbose = OS.get_environment("PRINT") == "1"
	var paths = {}
	for sp in HeroData.species.keys(): paths[sp] = "res://assets/beasts/%s.glb" % sp
	var dungeon = "res://assets/models/dungeon"
	if DirAccess.dir_exists_absolute(dungeon):
		for f in DirAccess.get_files_at(dungeon):
			if f.ends_with(".glb"): paths[f.get_basename()] = dungeon + "/" + f
	var result = {}
	for key in paths:
		var model: Node3D = load(paths[key]).instantiate()
		get_root().add_child(model)
		await process_frame
		var players = model.find_children("*", "AnimationPlayer", true, false)
		var skeletons = model.find_children("*", "Skeleton3D", true, false)
		if players.is_empty() or skeletons.is_empty(): model.queue_free(); continue
		var ap: AnimationPlayer = players[0]
		var sk: Skeleton3D = skeletons[0]
		var tips = []
		for i in sk.get_bone_count():
			if sk.get_bone_children(i).is_empty(): tips.append(i)
		result[key] = {}
		for clip in CLIPS:
			if not ap.has_animation(clip): continue
			var length = ap.get_animation(clip).length
			ap.play(clip); ap.speed_scale = 0.0
			var frames = int(length * RATE)
			var prev = {}
			var speeds = []
			for f in range(frames + 1):
				ap.seek(minf(length, f / RATE), true)
				sk.force_update_all_bone_transforms()
				var total = 0.0
				for b in tips:
					var p = sk.get_bone_global_pose(b).origin
					if prev.has(b): total += (p - prev[b]).length() * RATE
					prev[b] = p
				speeds.append(total / maxf(1, tips.size()) if f > 0 else 0.0)
			var marks = landmarks(speeds)
			marks["length"] = snappedf(length, 0.01)
			result[key][clip] = marks
			if verbose: print(key, " ", clip, " ", marks, " curve=", speeds.map(func(s): return snappedf(s, 0.1)))
		model.queue_free()
	var file = FileAccess.open("res://data/anim_contact.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t", true))
	print("Wrote clip landmarks for ", result.size(), " models")
	quit()
