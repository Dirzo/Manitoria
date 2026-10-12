extends SceneTree
## v0.78 Fluid combat, end to end: real seeded 5v5 battles through the real ArenaView at 60 fps.
##  - every melee basic hit lands while the attacker's clip sits on its measured contact frame
##  - every swing either plays its recovery out or cross-fades into the next swing (no snapping to idle)
##  - solid hits trigger per-unit hit-stop and a flinch; dead fighters are thrown back and removed
##  - presentation does not change the simulation (same result with and without the arena)
##  - frame cost of the arena stays reasonable
## Run: godot --headless --path godot -s tools/fluid_combat_test.gd
var failures := 0
const LEFT := ["minotaur", "direwolf", "golem", "kitsune", "phoenix"]
const RIGHT := ["troll", "nemean", "wyvern", "naga", "unicorn"]

func check(ok: bool, label: String) -> void:
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func _init() -> void:
	run.call_deferred()

func team(names: Array, tag: String) -> Array:
	var out = []
	for i in names.size():
		var h = HeroData.make_hero(names[i], "%s%d" % [tag, i], "%s %d" % [tag, i], 7)
		h.slot = Campaign.FORMATION[i]
		out.append(h)
	return out

func run() -> void:
	HeroData.load_data()
	var arena = ArenaView.new(); get_root().add_child(arena)
	var sim = BattleSim.new()
	sim.setup(team(LEFT, "L"), team(RIGHT, "R"), 4242)
	var n = {"hits": 0, "aligned": 0, "flinches": 0, "stops": 0}   # lambdas capture locals by value
	var misaligned = []
	sim.action.connect(func(e):
		arena.handle_event(e)
		if e.type == "hit" and e.get("credit", "") == "basic" and arena.models.has(int(e.source)):
			var src = sim.find_unit(int(e.source))
			if src.is_empty() or src.range > 2: return
			var a: CombatAnimator = arena.models[int(e.source)].anim
			if a.action_clip() != "attack": return
			n.hits += 1
			var want = CombatAnimator.marks(src.hero.sp, "attack").hit * float(a.clips.attack.length)
			# The sim resolves on its own 30 Hz tick; the animator is at most one render frame behind it.
			if absf(a.action_time() - want) <= 0.035: n.aligned += 1
			else: misaligned.append("%s %.3f/%.3f" % [src.hero.sp, a.action_time(), want])
		if e.type == "hit" and arena.models.has(int(e.uid)):
			var v = arena.models[int(e.uid)]
			if v.anim.frozen(): n.stops += 1
			if v.anim.bend_v.length() > 0.5: n.flinches += 1)
	arena.sync(sim, 1.0 / 60.0, 0.0)
	# Watch every fighter's action slots for how swings end.
	var endings = {"played_out": 0, "cross_faded": 0, "cut_short": 0}
	var last_slot = {}
	var frame_us = []
	var accumulator = 0.0
	var frames = 0
	while not sim.finished and frames < 60 * 90:
		accumulator += 1.0 / 60.0
		while accumulator >= 1.0 / 30.0 and not sim.finished:
			sim.step(1.0 / 30.0); accumulator -= 1.0 / 30.0
		var t0 = Time.get_ticks_usec()
		arena.sync(sim, 1.0 / 60.0, 1.0)
		frame_us.append(Time.get_ticks_usec() - t0)
		frames += 1
		for uid in arena.models:
			var a: CombatAnimator = arena.models[uid].anim
			if not a.ok: continue
			for i in 2:
				var s = a.slots[i]
				var k = "%d:%d" % [uid, i]
				var prev = last_slot.get(k, {})
				if not prev.is_empty() and prev.phase != "wind" and (s.is_empty() or s.t < prev.t):
					if s.is_empty() and prev.t >= prev.length - 0.02: endings.played_out += 1
					elif not s.is_empty() or a.current != i: endings.cross_faded += 1
					else: endings.cut_short += 1
				last_slot[k] = s.duplicate()
	print("battle ended=%s winner=%d after %.1fs, %d frames" % [sim.finished, sim.winner, sim.time, frames])
	check(n.hits >= 20, "melee basic hits observed (%d)" % n.hits)
	check(n.aligned == n.hits, "every melee hit lands on the attacker's contact frame (%d/%d) %s" % [n.aligned, n.hits, str(misaligned.slice(0, 5))])
	check(endings.played_out + endings.cross_faded > 20 and endings.cut_short == 0, "swings play out or cross-fade, none snap to idle %s" % str(endings))
	check(n.stops > 0 and n.flinches > 0, "solid hits freeze the fighters (%d) and bend the victim (%d)" % [n.stops, n.flinches])
	var dead_ok = true
	for u in sim.units:
		if u.alive or not arena.models.has(u.uid): continue
		var v = arena.models[u.uid]
		if v.death_elapsed > 2.6 and v.model.visible: dead_ok = false
		if v.death_elapsed > 0.6 and v.death_dir != Vector3.ZERO and v.motion.position.length() < 0.2: dead_ok = false
	check(dead_ok, "the fallen are thrown back and gone by 2.6 s")
	frame_us.sort()
	var p95 = frame_us[int(frame_us.size() * 0.95)] / 1000.0
	print("arena.sync median %.2f ms, p95 %.2f ms" % [frame_us[frame_us.size() / 2] / 1000.0, p95])
	check(p95 < 12.0, "arena frame cost stays reasonable headless (p95 %.2f ms)" % p95)
	# Presentation never feeds back into the simulation.
	var quiet = BattleSim.new(); quiet.silent = true
	quiet.setup(team(LEFT, "L"), team(RIGHT, "R"), 4242)
	while not quiet.finished and quiet.time < sim.time + 1.0: quiet.step(1.0 / 30.0)
	check(quiet.winner == sim.winner and is_equal_approx(quiet.time, sim.time), "same result without the arena (%d @ %.2fs vs %d @ %.2fs)" % [quiet.winner, quiet.time, sim.winner, sim.time])
	print("\n%s: %d failure(s)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)
