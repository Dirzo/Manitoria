extends SceneTree
## Step 2: CombatAnimator with the full 14-clip set, and with only the original five clips.
## The full set is synthesised from the direwolf's current clips (distinct Animation resources with the
## new names), so every new code path runs before any Meshy clip exists.
## Run: godot --headless --path godot -s tools/combat_clipset_test.gd
var failures := 0
const DT := 1.0 / 60.0

func check(ok: bool, label: String) -> void:
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func _init() -> void:
	run.call_deferred()

func trimmed(src: Animation, length: float, looping: bool) -> Animation:
	var a: Animation = src.duplicate(true)
	a.length = minf(length, src.length)
	a.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	return a

func make(full: bool) -> Dictionary:
	var holder = Node3D.new(); get_root().add_child(holder)
	var model: Node3D = load("res://assets/beasts/direwolf.glb").instantiate(); holder.add_child(model)
	if full:
		var ap: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
		var lib = AnimationLibrary.new()
		var src = func(n): return ap.get_animation(n)
		lib.add_animation("attack_1", trimmed(src.call("attack"), 99, false))
		lib.add_animation("attack_2", trimmed(src.call("attack"), 99, false))
		lib.add_animation("attack_heavy", trimmed(src.call("cast"), 1.1, false))
		lib.add_animation("idle_combat", trimmed(src.call("idle"), 1.4, true))
		lib.add_animation("run", trimmed(src.call("walk"), 0.5, true))
		lib.add_animation("hit_light", trimmed(src.call("death"), 0.3, false))
		lib.add_animation("hit_heavy", trimmed(src.call("death"), 0.6, false))
		lib.add_animation("stun", trimmed(src.call("idle"), 1.2, true))
		lib.add_animation("spawn", trimmed(src.call("cast"), 0.6, false))
		lib.add_animation("victory", trimmed(src.call("cast"), 1.2, true))
		# The imported library is shared by every instance of the model: copy it before adding clips.
		var base: AnimationLibrary = ap.get_animation_library("").duplicate()
		for n in lib.get_animation_list(): base.add_animation(n, lib.get_animation(n))
		ap.remove_animation_library(""); ap.add_animation_library("", base)
	var anim = CombatAnimator.new(); anim.setup(model, "synthetic", false, 1.0)
	return {"holder": holder, "anim": anim}

func idle_frames(a: CombatAnimator, n: int, stunned := false, travelling := false, speed := 0.0) -> void:
	for i in n: a.drive(DT, "", 0.0, true, stunned, travelling, 1.0, false, 99.0, speed, 2.0)

func windup(a: CombatAnimator, act: String, total: float) -> float:
	var r = total
	while r > 0.0:
		a.drive(DT, act, r, true, false, false, 1.0, true, 99.0); r = maxf(0.0, r - DT)
	a.drive(0.0, "", 0.0, true, false, false, 1.0, true, 99.0)
	return a.action_time()

func run() -> void:
	HeroData.load_data()
	# Full set.
	var f = make(true); var a: CombatAnimator = f.anim
	check(a.ok and a.clips.size() >= 14, "all 14 clips load (%d)" % a.clips.size())
	idle_frames(a, 10)
	var order = []
	for i in 4:
		windup(a, "attack", 0.32); order.append(a.action_clip()); idle_frames(a, 50)
	check(order == ["attack_1", "attack_2", "attack_1", "attack_2"], "basic swings alternate attack_1 / attack_2 %s" % str(order))
	var t = windup(a, "heavy", 0.5)
	var want = CombatAnimator.marks("synthetic", "attack_heavy").hit * float(a.clips.attack_heavy.length)
	check(a.action_clip() == "attack_heavy" and absf(t - want) < 0.002, "physical skills use attack_heavy and land contact (%.3f vs %.3f)" % [t, want])
	idle_frames(a, 80)
	a.hit_react(true); idle_frames(a, 3)
	check(not a.reaction.is_empty() and a.reaction.clip == "hit_heavy" and a.reaction.w > 0.3, "a big hit plays hit_heavy")
	idle_frames(a, 60)
	check(a.reaction.is_empty(), "the hit reaction ends on its own")
	a.drive(DT, "attack", 0.3, true, false, false, 1.0, true, 99.0)
	a.hit_react(false)
	check(a.reaction.is_empty(), "a hit never interrupts the fighter's own windup")
	idle_frames(a, 60)
	idle_frames(a, 20, true)
	check(a.stun_w > 0.99 and a.current < 0, "stun loop takes over and drops any action")
	idle_frames(a, 30)
	check(a.stun_w == 0.0, "and lets go when the stun ends")
	idle_frames(a, 40, false, true, 6.0)
	check(a.run_w > 0.99, "fast travel blends into run")
	idle_frames(a, 40, false, true, 1.5)
	check(a.run_w == 0.0 and a.walk_w > 0.99, "slower travel walks")
	idle_frames(a, 30)
	a.spawn()
	for i in 20:
		a.intro_dt = DT
		a.drive(0.0, "", 0.0, true, false, false, 1.0, false, 99.0)
	check(not a.event.is_empty() and a.event.t > 0.3, "spawn plays in real time while the battle clock is stopped (%.2fs)" % (a.event.get("t", 0.0)))
	idle_frames(a, 30)
	check(a.event.is_empty(), "spawn finishes and hands back to idle")
	a.celebrate(); idle_frames(a, 150)
	check(not a.event.is_empty() and a.event.clip == "victory" and a.event.w > 0.99, "victory loops after the fight")
	f.holder.queue_free()
	# Original five only: every new path falls back.
	var o = make(false); var b: CombatAnimator = o.anim
	idle_frames(b, 10)
	check(b.clip_for("attack", 1) == "attack_1" and b.clip_for("heavy", 0) == "attack_1", "without new clips: swings and skills use the one attack")
	windup(b, "attack", 0.32)
	check(b.action_clip() == "attack_1", "the original attack plays as attack_1")
	idle_frames(b, 60)
	b.hit_react(true); b.spawn(); b.celebrate()
	check(b.reaction.is_empty() and b.event.is_empty(), "hit, spawn and victory are silent no-ops (the spine flinch still works)")
	idle_frames(b, 20, true)
	check(b.stun_w > 0.99, "stun falls back to a slowed idle")
	idle_frames(b, 40, false, true, 9.0)
	check(b.run_w == 0.0, "no run clip: fast travel keeps walking")
	o.holder.queue_free()
	print("\n%s: %d failure(s)" % ["OK" if failures == 0 else "FAILED", failures])
	quit(1 if failures > 0 else 0)
