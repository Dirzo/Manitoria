class_name CombatAnimator
extends RefCounted
## v0.78 Fluid combat: one per arena fighter. Drives the creature's authored clips through a manually
## advanced AnimationTree instead of scrubbing an AnimationPlayer, so that:
##  - attacks and casts play forward, timed so the clip's measured contact frame (data/anim_contact.json)
##    lands exactly when the simulation resolves the hit; long windups hold the anticipation pose and snap;
##  - a unit that swings again before its last recovery finished cross-fades swing into swing instead of
##    popping back to idle;
##  - locomotion blends idle and walk by actual ground speed, with a quicker "combat idle" while engaged;
##  - hits bend the spine away from the blow with a damped spring (skeletal flinch), and short per-unit
##    freezes (hit-stop) hold attacker and victim on the contact pose without slowing the whole board.
## The simulation is never touched: everything here is presentation driven by sim state.

const FALLBACK := {"attack": {"ready": 0.28, "hit": 0.46, "resume": 0.46}, "cast": {"ready": 0.29, "hit": 0.29, "resume": 0.29}}
const FADE_IN := 0.06
const FADE_OUT := 0.14
const WALK_FADE := 0.12
const DEATH_RATE := 1.3
# Damped spring for the flinch: about 3.3 Hz with a little overshoot so the body rocks back once.
const FLINCH_K := 420.0
const FLINCH_C := 15.0
const FLINCH_KICK := 9.0

static var landmarks := {}
static var prepared := {}

var ok := false
var tree: AnimationTree
var blend: AnimationNodeBlendTree
var player: AnimationPlayer
var skeleton: Skeleton3D
var key := ""
var heavy := false
var tempo := 1.0
var clips := {}
var walk_w := 0.0
var slots := [{}, {}]
var current := -1
var winding := false
var dead := false
var death_t := 0.0
var death_w := 0.0
var freeze := 0.0
var spine := PackedInt32Array()
var spine_w := PackedFloat32Array()
var bend := Vector3.ZERO      # skeleton space, horizontal: direction and angle (radians) of the flinch
var bend_v := Vector3.ZERO
var bent := {}                # bone -> rotation before the flinch was layered on this frame

static func load_landmarks() -> void:
	if not landmarks.is_empty(): return
	if FileAccess.file_exists("res://data/anim_contact.json"):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/anim_contact.json"))
		if parsed is Dictionary: landmarks = parsed
	if landmarks.is_empty(): landmarks = {"_": {}}

## The timing landmarks for one clip, sanity-checked so a bad measurement can't wreck a swing.
static func marks(model_key: String, clip: String) -> Dictionary:
	load_landmarks()
	var base: Dictionary = FALLBACK.get(clip, FALLBACK.attack)
	var m: Dictionary = landmarks.get(model_key, {}).get(clip, {})
	var hit = float(m.get("hit", base.hit))
	var ready = float(m.get("ready", base.ready))
	var resume = float(m.get("resume", base.resume))
	if hit < 0.2 or hit > 0.75: hit = base.hit; ready = base.ready; resume = base.resume
	ready = clampf(ready, 0.0, hit)
	resume = clampf(resume, hit, 0.95)
	return {"ready": ready, "hit": hit, "resume": resume}

## Rig-agnostic spine: from the hip bone (the first with three or more children) up the largest branch
## to the chest. Works on the generic Bone_### rigs the creatures ship with.
static func find_spine(sk: Skeleton3D) -> PackedInt32Array:
	var out = PackedInt32Array()
	var hips = -1
	for i in sk.get_bone_count():
		if sk.get_bone_children(i).size() >= 3: hips = i; break
	if hips < 0: return out
	out.append(hips)
	var b = -1; var best = 0
	for c in sk.get_bone_children(hips):
		var n = subtree(sk, c)
		if n > best: best = n; b = c
	while b >= 0 and out.size() < 8:
		out.append(b)
		var kids = sk.get_bone_children(b)
		if kids.size() != 1: break
		b = kids[0]
	return out

static func subtree(sk: Skeleton3D, b: int) -> int:
	var n = 1
	for c in sk.get_bone_children(b): n += subtree(sk, c)
	return n

func setup(model: Node3D, model_key: String, heavy_body: bool, unit_tempo: float) -> void:
	key = model_key; heavy = heavy_body; tempo = unit_tempo
	var players = model.find_children("*", "AnimationPlayer", true, false)
	var skeletons = model.find_children("*", "Skeleton3D", true, false)
	if players.is_empty() or skeletons.is_empty(): return
	player = players[0]; skeleton = skeletons[0]
	for clip in ["idle", "walk", "attack", "cast", "death"]:
		if player.has_animation(clip): clips[clip] = player.get_animation(clip)
	if not clips.has("idle"): return
	for clip in clips: prepare(clips[clip], clip in ["idle", "walk"])
	player.stop(); player.active = false
	build_tree()
	var spine_bones = find_spine(skeleton)
	for i in spine_bones.size():
		spine.append(spine_bones[i])
		spine_w.append(0.15 if i == 0 else 0.85 / maxf(1, spine_bones.size() - 1))
	ok = true
	# Desynchronise idles so a squad of the same creature doesn't breathe in lockstep.
	tree.advance(randf() * float(clips.idle.length))

## Loop the cycles and switch bone tracks to cubic interpolation: the 30 fps keys read as faceted
## when a clip is slowed down, and cubic rounds the corners. Each Animation resource is shared by
## every instance of a model, so this happens once.
static func prepare(anim: Animation, looping: bool) -> void:
	var id = anim.get_instance_id()
	if prepared.has(id): return
	prepared[id] = true
	anim.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	for t in anim.get_track_count():
		if anim.track_is_compressed(t): continue
		var kind = anim.track_get_type(t)
		if kind == Animation.TYPE_ROTATION_3D or kind == Animation.TYPE_POSITION_3D:
			anim.track_set_interpolation_type(t, Animation.INTERPOLATION_CUBIC)
			if looping: anim.track_set_interpolation_loop_wrap(t, true)

func build_tree() -> void:
	blend = AnimationNodeBlendTree.new()
	var add = func(node_name: String, node: AnimationNode) -> void: blend.add_node(node_name, node)
	add.call("idle", anim_node("idle"))
	add.call("idle_ts", AnimationNodeTimeScale.new())
	add.call("walk", anim_node("walk" if clips.has("walk") else "idle"))
	add.call("walk_ts", AnimationNodeTimeScale.new())
	add.call("move", AnimationNodeBlend2.new())
	blend.connect_node("idle_ts", 0, "idle")
	blend.connect_node("walk_ts", 0, "walk")
	blend.connect_node("move", 0, "idle_ts")
	blend.connect_node("move", 1, "walk_ts")
	var below = "move"
	for s in ["a", "b", "d"]:
		add.call(s + "_clip", anim_node("death" if s == "d" and clips.has("death") else "attack" if clips.has("attack") else "idle"))
		add.call(s + "_seek", AnimationNodeTimeSeek.new())
		add.call(s + "_ts", AnimationNodeTimeScale.new())
		add.call(s + "_mix", AnimationNodeBlend2.new())
		blend.connect_node(s + "_seek", 0, s + "_clip")
		blend.connect_node(s + "_ts", 0, s + "_seek")
		blend.connect_node(s + "_mix", 0, below)
		blend.connect_node(s + "_mix", 1, s + "_ts")
		below = s + "_mix"
	blend.connect_node("output", 0, below)
	tree = AnimationTree.new()
	tree.name = "CombatAnimator"
	player.get_parent().add_child(tree)
	tree.anim_player = tree.get_path_to(player)
	tree.root_node = tree.get_path_to(player.get_node(player.root_node))
	tree.tree_root = blend
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for s in ["a", "b", "d"]: tree.set("parameters/%s_ts/scale" % s, 0.0)
	tree.set("parameters/idle_ts/scale", tempo)
	tree.set("parameters/walk_ts/scale", 1.0)
	tree.active = true

func anim_node(clip: String) -> AnimationNodeAnimation:
	var node = AnimationNodeAnimation.new(); node.animation = clip
	return node

## Called every frame. dt is game time (already scaled by battle speed; 0 while paused).
## act: the clip the simulation is currently winding up ("attack"/"cast"), or "" when none.
## remaining: seconds until the sim resolves that windup. next_eta: seconds until the next swing can start.
func drive(dt: float, act: String, remaining: float, alive: bool, stunned: bool, travelling: bool, walk_rate: float, engaged: bool, next_eta: float) -> void:
	if not ok: return
	# Hit-stop holds the pose, except for a fighter winding up its own strike: the windup is the sim's
	# clock, so it keeps going (the victim still shudders) and contact still lands on the hit.
	var eff = 0.0 if freeze > 0.0 and act == "" else dt
	freeze = maxf(0.0, freeze - dt)
	if not alive and not dead:
		dead = true; death_t = 0.0
		for s in slots: if not s.is_empty(): s.phase = "out"
	if alive and not dead:
		if act != "" and not winding:
			var clip = act if clips.has(act) else "attack" if clips.has("attack") else ""
			if clip != "": start(clip)
		winding = act != ""
		if current >= 0: advance_slot(slots[current], eff, remaining, stunned, next_eta)
	# Locomotion underneath everything.
	walk_w = move_toward(walk_w, 1.0 if travelling and alive else 0.0, eff / WALK_FADE)
	tree.set("parameters/move/blend_amount", walk_w)
	tree.set("parameters/walk_ts/scale", walk_rate)
	tree.set("parameters/idle_ts/scale", tempo * (1.35 if engaged else 1.0))
	for i in 2:
		var s = slots[i]
		var slot = "a" if i == 0 else "b"
		if s.is_empty(): tree.set("parameters/%s_mix/blend_amount" % slot, 0.0); continue
		var target = 1.0 if i == current and s.phase != "out" else 0.0
		s.w = move_toward(s.w, target, eff / (FADE_IN if target > s.w else FADE_OUT))
		tree.set("parameters/%s_mix/blend_amount" % slot, s.w)
		tree.set("parameters/%s_seek/seek_request" % slot, s.t)
		if s.w <= 0.0 and s.phase == "out":
			slots[i] = {}
			if current == i: current = -1
	if dead and clips.has("death"):
		death_t = minf(float(clips.death.length), death_t + eff * DEATH_RATE)
		death_w = move_toward(death_w, 1.0, eff / 0.12)
		tree.set("parameters/d_seek/seek_request", death_t)
	tree.set("parameters/d_mix/blend_amount", death_w)
	unbend()
	tree.advance(eff)
	flinch_step(eff)

func start(clip: String) -> void:
	var slot = 0 if current != 0 else 1
	var m = marks(key, clip)
	var length = float(clips[clip].length)
	var w = 0.0 if slots[slot].is_empty() else float(slots[slot].w)
	slots[slot] = {"clip": clip, "t": 0.0, "w": w, "phase": "wind", "length": length,
		"ready": m.ready * length, "hit": m.hit * length, "resume": m.resume * length}
	(blend.get_node(("a" if slot == 0 else "b") + "_clip") as AnimationNodeAnimation).animation = clip
	current = slot

func advance_slot(s: Dictionary, eff: float, remaining: float, stunned: bool, next_eta: float) -> void:
	if stunned and s.phase != "out": s.phase = "out"; return
	if s.phase == "wind":
		if not winding:
			# Released: the hit frame is now. Casts skip the authored dead hold after release.
			s.t = maxf(s.t, s.hit)
			if s.clip == "cast": s.t = maxf(s.t, s.resume)
			s.phase = "post"
		else:
			s.t = wind_time(s.t, eff, remaining, s.ready, s.hit, tempo)
	if s.phase == "post":
		var left = s.length - s.t
		var rate = tempo
		if next_eta < left: rate = clampf(left / maxf(0.05, next_eta), tempo, 3.0)
		s.t = minf(s.length, s.t + eff * rate)
		if s.t >= s.length - 0.001: s.phase = "out"

## Where the clip should be after eff seconds of a windup that resolves in `remaining` seconds:
## play the anticipation at natural speed and hold it, then strike so contact lands on the release.
## Too little time and the whole move is sped up instead.
static func wind_time(t: float, eff: float, remaining: float, ready: float, hit: float, rate: float) -> float:
	if eff <= 0.0: return t
	if remaining <= 0.0001: return hit
	var strike = hit - ready
	if t < ready:
		var need = (hit - t) / remaining
		if need > rate: return minf(hit, t + eff * need)
		return minf(ready, t + eff * rate)
	if remaining > strike / maxf(0.01, rate): return t
	return minf(hit, t + eff * (hit - t) / remaining)

## A blow from `push` (world-space direction the victim is shoved). strength 0..1.
func flinch(push: Vector3, strength: float) -> void:
	if not ok or spine.is_empty() or not skeleton.is_inside_tree(): return
	var flat = Vector3(push.x, 0.0, push.z)
	if flat.length_squared() < 0.0001: return
	var local = (skeleton.global_transform.basis.orthonormalized().inverse() * flat.normalized())
	local.y = 0.0
	bend_v += local.normalized() * FLINCH_KICK * clampf(strength, 0.0, 1.0) * (0.65 if heavy else 1.0)

func hitstop(seconds: float) -> void:
	freeze = maxf(freeze, seconds)

func frozen() -> bool:
	return freeze > 0.0

func unbend() -> void:
	for b in bent: skeleton.set_bone_pose_rotation(b, bent[b])
	bent.clear()

func flinch_step(eff: float) -> void:
	if spine.is_empty(): return
	if eff > 0.0:
		var steps = int(ceil(eff / 0.016))
		var h = eff / steps
		for i in steps:
			bend_v += (-FLINCH_K * bend - FLINCH_C * bend_v) * h
			bend += bend_v * h
	var angle = bend.length()
	if angle < 0.0005: return
	var axis_skel = Vector3.UP.cross(bend / angle).normalized()
	# Global rotations of the spine before anything is bent, composed down the chain.
	var globals = []
	var parent = skeleton.get_bone_parent(spine[0])
	var acc = Quaternion.IDENTITY
	var chain = []
	while parent >= 0: chain.push_front(parent); parent = skeleton.get_bone_parent(parent)
	for b in chain: acc = acc * skeleton.get_bone_pose_rotation(b)
	for b in spine:
		acc = acc * skeleton.get_bone_pose_rotation(b)
		globals.append(acc)
	for i in spine.size():
		var b = spine[i]
		var base = skeleton.get_bone_pose_rotation(b)
		bent[b] = base
		var axis_local = (globals[i].inverse() * axis_skel).normalized()
		skeleton.set_bone_pose_rotation(b, base * Quaternion(axis_local, angle * spine_w[i]))

## Copy the current pose (for afterimages).
func copy_pose_to(target: Skeleton3D) -> void:
	if not ok or target == null or target.get_bone_count() != skeleton.get_bone_count(): return
	for i in skeleton.get_bone_count(): target.set_bone_pose(i, skeleton.get_bone_pose(i))

## Current clip time of the active action (for tests).
func action_time() -> float:
	return -1.0 if current < 0 else float(slots[current].t)

func action_clip() -> String:
	return "" if current < 0 else str(slots[current].clip)

func action_weight() -> float:
	return 0.0 if current < 0 else float(slots[current].w)
