extends SceneTree
## Finds each creature's loose chains (tails, hair, cloth, manes: single-bone runs of 3+ that end in a leaf
## and branch off the body, not off an arm or leg) and writes data/spring_chains.json. CombatAnimator
## puts a SpringBoneSimulator3D on them so they trail and swing with the body's motion.
## Chains named in data/retarget_jobs.json overrides are honoured (the naga's arms, for example).
##   godot --headless --path godot -s tools/spring_chains_probe.gd      (PRINT=1 lists every chain)
const Retargeter = preload("res://tools/retargeter.gd")

func _init() -> void:
	run.call_deferred()

func run() -> void:
	HeroData.load_data()
	var jobs = JSON.parse_string(FileAccess.get_file_as_string("res://data/retarget_jobs.json"))
	var verbose = OS.get_environment("PRINT") == "1"
	var out = {}
	var total = 0
	for sp in HeroData.species.keys():
		var model: Node3D = load("res://assets/beasts/%s.glb" % sp).instantiate()
		get_root().add_child(model)
		await process_frame
		var sk: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
		var job = jobs.get(sp, {}) if jobs is Dictionary else {}
		var ch = Retargeter.chains_from_names(sk, job.chains) if job.has("chains") else Retargeter.chains(sk)
		var body = {}   # bones of the main body chains (spine, neck)
		var limbs = {}  # bones of limbs and everything below them
		for role in ch:
			for b in ch[role]:
				if role in ["spine", "neck", "hips"]: body[b] = true
		for role in ["arm_l", "arm_r", "leg_l", "leg_r"]:
			if ch.has(role) and not ch[role].is_empty(): mark_below(sk, ch[role][0], limbs)
		var tail_bones = ch.get("tail", [])
		# A tail already animated by retargeted clips (from a source rig with a tail) keeps its authored swish.
		var driven_tail = not job.is_empty() and str(job.get("set", "")) in ["fox", "horse", "kaiju", "dragon", "spider", "snake"] \
			and (job.get("roles", []).is_empty() or "tail" in job.get("roles", []))
		if "tail" in job.get("no_springs", []) or driven_tail:
			for b in tail_bones: body[b] = true   # treated as body: no spring
			tail_bones = []
		var lo = INF; var hi = -INF
		for i in sk.get_bone_count():
			var y = Retargeter.world_rest(sk, i).origin.y
			lo = minf(lo, y); hi = maxf(hi, y)
		var found = []
		for b in sk.get_bone_count():
			if limbs.has(b) or body.has(b): continue
			var parent = sk.get_bone_parent(b)
			if parent < 0 or sk.get_bone_children(parent).size() < 2: continue   # chains start at a branch
			var path = [b]
			while sk.get_bone_children(path[-1]).size() == 1: path.append(sk.get_bone_children(path[-1])[0])
			if not sk.get_bone_children(path[-1]).is_empty() or path.size() < 3: continue
			if path.any(func(x): return limbs.has(x) or body.has(x)): continue
			var kind = "tail" if b in tail_bones else "loose"
			# Extra legs the limb finder didn't claim (spider legs, flippers) stand on the floor: no springs.
			if kind != "tail" and Retargeter.world_rest(sk, path[-1]).origin.y - lo < (hi - lo) * 0.18: continue
			var tip = (Retargeter.world_rest(sk, path[-1]).origin.y - lo) / maxf(0.001, hi - lo)
			found.append({"root": sk.get_bone_name(path[0]), "end": sk.get_bone_name(path[-1]), "bones": path.size(), "kind": kind, "tip": snappedf(tip, 0.01)})
		# A tail that is a long branching chain (the naga's coils) is not a clean single run: add it whole.
		if not tail_bones.is_empty() and not found.any(func(f): return f.kind == "tail") and tail_bones.size() >= 3:
			found.append({"root": sk.get_bone_name(tail_bones[0]), "end": sk.get_bone_name(tail_bones[-1]), "bones": tail_bones.size(), "kind": "tail"})
		if not found.is_empty(): out[sp] = found
		total += found.size()
		if verbose: print(sp, " ", found.map(func(f): return "%s %s->%s (%d)" % [f.kind, f.root, f.end, f.bones]))
		model.queue_free()
	var file = FileAccess.open("res://data/spring_chains.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(out, "\t", true))
	print("Wrote %d loose chains for %d creatures" % [total, out.size()])
	quit()

func mark_below(sk: Skeleton3D, b: int, into: Dictionary) -> void:
	into[b] = true
	for c in sk.get_bone_children(b): mark_below(sk, c, into)
