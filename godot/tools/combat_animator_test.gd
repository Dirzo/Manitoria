extends SceneTree
## v0.78 Fluid combat: CombatAnimator checks (headless).
##  1. The tree reproduces the authored clip: at the moment a windup resolves, the pose equals the attack
##     clip sampled at its measured contact frame.
##  2. Long windups hold the anticipation and still land contact on release.
##  3. Swing-to-swing: a unit that attacks again during recovery never drops back to idle in between.
##  4. Hit-stop freezes the pose; pausing (dt 0) never accumulates the flinch; the flinch settles back.
##  5. Every creature model builds a tree and finds a spine.
## Run: godot --headless --path godot -s tools/combat_animator_test.gd
var failures := 0
const DT := 1.0 / 60.0

func check(ok: bool, label: String) -> void:
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func _init() -> void:
	run.call_deferred()

func make(sp: String) -> Dictionary:
	var holder = Node3D.new(); get_root().add_child(holder)
	var model: Node3D = load("res://assets/beasts/%s.glb" % sp).instantiate(); holder.add_child(model)
	var anim = CombatAnimator.new(); anim.setup(model, sp, false, 1.0)
	return {"holder": holder, "model": model, "anim": anim}

func pose(sk: Skeleton3D) -> Array:
	var out = []
	for i in sk.get_bone_count(): out.append(sk.get_bone_pose_rotation(i))
	return out

func pose_diff(a: Array, b: Array) -> float:
	var worst = 0.0
	for i in a.size():
		# Precise for tiny angles (Quaternion.angle_to bottoms out around 7e-4 rad through acos).
		var d: Quaternion = a[i].inverse() * b[i]
		worst = maxf(worst, 2.0 * atan2(Vector3(d.x, d.y, d.z).length(), absf(d.w)))
	return worst

## Reference: the raw clip sampled with a plain AnimationPlayer on a second instance.
func reference(sp: String, clip: String, t: float) -> Array:
	var holder = Node3D.new(); get_root().add_child(holder)
	var model: Node3D = load("res://assets/beasts/%s.glb" % sp).instantiate(); holder.add_child(model)
	var ap: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
	var sk: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	ap.play(clip); ap.speed_scale = 0.0; ap.seek(t, true)
	var out = pose(sk)
	holder.queue_free()
	return out

## Runs a windup of `total` seconds; returns the clip time and pose at release and the frame-by-frame times.
func windup(a: CombatAnimator, total: float, eta_after: float = 99.0) -> Dictionary:
	var remaining = total
	var times = []
	while remaining > 0.0:
		a.drive(DT, "attack", remaining, true, false, false, 1.0, true, 99.0)
		times.append(a.action_time())
		remaining = maxf(0.0, remaining - DT)
	a.drive(DT * 0.0, "", 0.0, true, false, false, 1.0, true, eta_after)   # release frame (no time passes)
	return {"t": a.action_time(), "times": times, "pose": pose(a.skeleton)}

func run() -> void:
	HeroData.load_data()
	# 1 + 2: contact alignment, normal and artillery windups.
	for sp in ["golem", "direwolf", "wyvern", "naga"]:
		var m = CombatAnimator.marks(sp, "attack")
		for total in [0.32, 0.44, 0.62]:
			var u = make(sp); var a: CombatAnimator = u.anim
			for i in 10: a.drive(DT, "", 0.0, true, false, false, 1.0, true, 99.0)
			var r = windup(a, total)
			var hit_t = m.hit * float(a.clips.attack.length)
			check(absf(r.t - hit_t) < 0.002, "%s %.2fs windup lands contact at %.3fs (clip %.3fs)" % [sp, total, hit_t, r.t])
			var diff = pose_diff(r.pose, reference(sp, "attack", hit_t))
			check(diff < 0.02, "%s %.2fs release pose matches the authored contact frame (max %.4f rad)" % [sp, total, diff])
			if total >= 0.6:
				var held = 0
				for i in range(1, r.times.size()):
					if absf(r.times[i] - r.times[i - 1]) < 0.00001 and absf(r.times[i] - m.ready * float(a.clips.attack.length)) < 0.002: held += 1
				check(held >= 6, "%s long windup holds the anticipation pose (%d frames)" % [sp, held])
			u.holder.queue_free()
	# 3: swing into swing. Fast attacker: recovery 0.22 s, next windup right after.
	var u3 = make("direwolf"); var a3: CombatAnimator = u3.anim
	var min_w = 1.0
	for swing in 4:
		var r = windup(a3, 0.32, 0.22)
		var gap = 0.22
		while gap > 0.0:
			a3.drive(DT, "", 0.0, true, false, false, 1.0, true, gap)
			if swing > 0 or gap < 0.2: min_w = minf(min_w, a3.action_weight())
			gap -= DT
	check(min_w > 0.9, "back-to-back swings never fall back to idle (min action weight %.2f)" % min_w)
	u3.holder.queue_free()
	# 4: hit-stop, pause and flinch.
	var u4 = make("minotaur"); var a4: CombatAnimator = u4.anim
	for i in 20: a4.drive(DT, "", 0.0, true, false, false, 1.0, false, 99.0)
	a4.hitstop(0.08)
	a4.drive(DT, "", 0.0, true, false, false, 1.0, false, 99.0)
	var before = pose(a4.skeleton)
	for i in 3: a4.drive(DT, "", 0.0, true, false, false, 1.0, false, 99.0)
	check(pose_diff(before, pose(a4.skeleton)) < 0.0001, "hit-stop holds the pose (%.5f)" % pose_diff(before, pose(a4.skeleton)))
	for i in 3: a4.drive(DT, "", 0.0, true, false, false, 1.0, false, 99.0)
	check(not a4.frozen() and pose_diff(before, pose(a4.skeleton)) > 0.0001, "and releases it afterwards")
	for i in 4: a4.drive(DT, "", 0.0, true, false, false, 1.0, false, 99.0)
	a4.flinch(Vector3(1, 0, 0), 1.0)
	for i in 5: a4.drive(DT, "", 0.0, true, false, false, 1.0, false, 99.0)
	check(a4.bend.length() > 0.08, "a heavy blow bends the spine (%.2f rad)" % a4.bend.length())
	a4.drive(0.0, "", 0.0, true, false, false, 1.0, false, 99.0)
	var bent = pose(a4.skeleton)
	for i in 30: a4.drive(0.0, "", 0.0, true, false, false, 1.0, false, 99.0)
	check(pose_diff(bent, pose(a4.skeleton)) < 0.0001, "30 paused frames re-apply the same flinch instead of accumulating (%.5f)" % pose_diff(bent, pose(a4.skeleton)))
	for i in 90: a4.drive(DT, "", 0.0, true, false, false, 1.0, false, 99.0)
	check(a4.bend.length() < 0.01, "the flinch settles (%.4f rad left)" % a4.bend.length())
	u4.holder.queue_free()
	# 5: every model.
	var missing = []
	for sp in HeroData.species.keys():
		var u = make(sp)
		if not u.anim.ok: missing.append(sp + ":tree")
		elif u.anim.spine.size() < 2 and sp != "arachne": missing.append(sp + ":spine")
		u.holder.queue_free()
	check(missing.is_empty(), "all creatures build a combat animator %s" % str(missing))
	print("\n%s: %d failure(s)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)
