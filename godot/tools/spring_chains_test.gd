extends SceneTree
## Loose-chain springs: a creature jerked sideways leaves its tail/hair trailing, and they settle back.
## Run at real frame timing (springs integrate with the process delta):
##   godot --headless --path godot --fixed-fps 60 -s tools/spring_chains_test.gd
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func _initialize() -> void:
	run.call_deferred()

func tip_local(model: Node3D, sk: Skeleton3D, bone: int) -> Vector3:
	return model.global_transform.affine_inverse() * (sk.global_transform * sk.get_bone_global_pose(bone)).origin

func run() -> void:
	HeroData.load_data()
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/spring_chains.json"))
	check(not data.has("direwolf"), "the direwolf's tail is animated by its retargeted clips, so it gets no spring")
	check(data is Dictionary and data.size() >= 20, "loose chains listed for most creatures (%d)" % (data.size() if data is Dictionary else 0))
	for sp in ["naga", "kitsune", "minotaur"]:
		# Same nesting as the arena: holder (moved by the sim) > CombatMotion (lunges) > model (turns).
		var holder = Node3D.new(); get_root().add_child(holder)
		var motion = Node3D.new(); holder.add_child(motion)
		var model: Node3D = load("res://assets/beasts/%s.glb" % sp).instantiate(); motion.add_child(model)
		var anim = CombatAnimator.new(); anim.setup(model, sp, false, 1.0)
		check(anim.springs != null and anim.springs.setting_count == data[sp].size(), "%s gets %d spring chains" % [sp, data[sp].size()])
		var sk = anim.skeleton
		var tips = data[sp].map(func(c): return sk.find_bone(c.end))
		# Drawn pose (springs applied) exists only during the skeleton update; the animated pose is what
		# the bones hold outside it. The gap between the two, measured in the same frame, is the spring.
		var drawn = {}
		sk.skeleton_updated.connect(func():
			for b in tips: drawn[b] = tip_local(model, sk, b))
		var gap = func() -> float:
			var w = 0.0
			for b in tips:
				if drawn.has(b): w = maxf(w, drawn[b].distance_to(tip_local(model, sk, b)))
			return w
		var step = func(lunge: float) -> void:
			motion.position.z = lunge   # an attack lunge on CombatMotion, as animate_weight does
			anim.drive(1.0 / 60.0, "", 0.0, true, false, false, 1.0, false, 99.0)
		for i in 30: step.call(0.0); await process_frame
		var still = 0.0   # the idle's own motion: peak over a second of standing
		for i in 60:
			step.call(0.0); await process_frame
			still = maxf(still, gap.call())
		var worst = 0.0
		for i in 70:
			step.call(0.28 * sin(PI * i / 12.0) if i < 12 else 0.0); await process_frame   # a 0.2 s, 0.28-unit lunge
			worst = maxf(worst, gap.call())
		for i in 240: step.call(0.0); await process_frame
		var settle = gap.call()
		var dash = 0.0
		for i in 70:   # sliding across the board (the holder) must not whip the tail
			holder.position.x += 4.0 / 60.0 if i < 30 else 0.0
			step.call(0.0); await process_frame
			dash = maxf(dash, gap.call())
		print("   %s: standing %.3f, lunge peak %.3f, after %.3f, sliding %.3f" % [sp, still, worst, settle, dash])
		check(worst > 0.03 and worst > still * 2.0, "%s loose chains trail the motion" % sp)
		check(settle < maxf(still * 3.0, worst * 0.35) and not is_nan(settle), "%s settles back" % sp)
		check(dash < maxf(still * 3.0, 0.05), "%s doesn't whip when sliding across the board" % sp)
		holder.queue_free()
	print("\n%s: %d failure(s)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)
