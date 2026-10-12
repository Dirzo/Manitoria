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
## Step 2 (combat clip set): also plays attack_1/attack_2 alternately, attack_heavy for physical skills,
## idle_combat while engaged, run when travelling fast, hit_light/hit_heavy reactions, a stun loop,
## spawn at the start of a fight and a victory loop afterwards. Every one of those clips is optional:
## a creature that only has the original five (idle, walk, attack, cast, death) falls back cleanly.
## The simulation is never touched: everything here is presentation driven by sim state.

const FALLBACK := {"attack": {"ready": 0.28, "hit": 0.46, "resume": 0.46}, "attack_1": {"ready": 0.28, "hit": 0.46, "resume": 0.46},
	"attack_2": {"ready": 0.28, "hit": 0.46, "resume": 0.46}, "attack_heavy": {"ready": 0.35, "hit": 0.5, "resume": 0.5},
	"cast": {"ready": 0.29, "hit": 0.29, "resume": 0.29}}
## Every clip name the game knows (art/combat_clips/README.md). Only idle is strictly required.
const CLIP_SET := ["idle", "idle_combat", "walk", "run", "attack", "attack_1", "attack_2", "attack_heavy", "cast",
	"hit_light", "hit_heavy", "stun", "death", "spawn", "victory"]
const LOOPS := ["idle", "idle_combat", "walk", "run", "stun", "victory"]
## Layers above the action slots, bottom to top: stun, hit reaction, event (spawn/victory), death.
const LAYERS := ["s", "h", "e", "d"]
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
var sources := {}             # clip name the game asks for -> animation name in the player (aliases)
var walk_w := 0.0
var run_w := 0.0
var combat_w := 0.0
var swings := 0
var stun_t := 0.0
var stun_w := 0.0
var reaction := {}            # current hit reaction: clip, t, peak, w
var event := {}               # spawn or victory: clip, t, loop, w
var intro_dt := 0.0           # real time for the pre-fight spawn while the battle clock is stopped
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
	var measured: Dictionary = landmarks.get(model_key, {})
	var m: Dictionary = measured.get(clip, measured.get("attack", {}) if clip == "attack_1" else {})
	var contact = float(m.get("hit", base.hit))
	var ready = float(m.get("ready", base.ready))
	var resume = float(m.get("resume", base.resume))
	var limit = 0.9 if m.get("picked", false) else 0.75
	if contact < 0.08 or contact > limit: contact = base.hit; ready = base.ready; resume = base.resume
	ready = clampf(ready, 0.0, contact)
	resume = clampf(resume, contact, 0.95)
	return {"ready": ready, "hit": contact, "resume": resume}

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

## Loose chains (tails, hair, manes, feathers: data/spring_chains.json from tools/spring_chains_probe.gd)
## trail and swing with the body. The animated pose stays the spring's target, so clips still drive them.
static var spring_data := {}
var springs: SpringBoneSimulator3D

## anchor: the node the springs measure motion against. In the arena it is the fighter's holder, so loose
## chains swing from the creature's own motion (swings, lunges, flinches, turns) but not from sliding
## across the board.
func add_springs(anchor: Node3D = null) -> void:
	if spring_data.is_empty():
		var path = "res://data/spring_chains.json"
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		spring_data = parsed if parsed is Dictionary else {"_": []}
	var list: Array = spring_data.get(key, [])
	if list.is_empty(): return
	springs = SpringBoneSimulator3D.new(); springs.name = "LooseChains"
	skeleton.add_child(springs)
	springs.setting_count = list.size()
	for i in list.size():
		var c: Dictionary = list[i]
		springs.set_root_bone_name(i, str(c.root)); springs.set_end_bone_name(i, str(c.end))
		# Long chains get stiffer so their tips don't whip; short ones (feathers, horns) stay firm.
		var n = int(c.bones)
		springs.set_stiffness(i, clampf(0.9 + 0.08 * n, 1.2, 2.4) if c.kind == "tail" or n >= 5 else 2.0)
		springs.set_drag(i, 0.6)
		springs.set_gravity(i, 0.0)   # resting tails lie on the floor; gravity would sink them
		springs.set_radius(i, 0.02)
		if anchor:
			springs.set_center_from(i, SpringBoneSimulator3D.CENTER_FROM_NODE)
			springs.set_center_node(i, springs.get_path_to(anchor))

## Retargeted combat clips (tools/retarget_creature.gd) live beside the model in
## assets/beasts/clips/<model>.res and replace the model's own clips of the same name. The model's
## animation library is shared by every instance of that model, so this happens once per model.
const CLIP_LIBRARY := "res://assets/beasts/clips/%s.res"
static func apply_clip_library(ap: AnimationPlayer, model_key: String) -> int:
	var path = CLIP_LIBRARY % model_key
	if not ResourceLoader.exists(path): return 0
	var extra: AnimationLibrary = load(path)
	if extra == null: return 0
	if not ap.has_animation_library(""): ap.add_animation_library("", AnimationLibrary.new())
	var lib = ap.get_animation_library("")
	var n = 0
	for name in extra.get_animation_list():
		var anim = extra.get_animation(name)
		if lib.has_animation(name):
			if lib.get_animation(name) == anim: continue
			lib.remove_animation(name)
		lib.add_animation(name, anim); n += 1
	# Older code paths and previews that ask for the single "attack" get the new first swing.
	if extra.has_animation("attack_1") and lib.get_animation("attack") != extra.get_animation("attack_1"):
		if lib.has_animation("attack"): lib.remove_animation("attack")
		lib.add_animation("attack", extra.get_animation("attack_1"))
	return n

func setup(model: Node3D, model_key: String, heavy_body: bool, unit_tempo: float) -> void:
	key = model_key; heavy = heavy_body; tempo = unit_tempo
	var players = model.find_children("*", "AnimationPlayer", true, false)
	var skeletons = model.find_children("*", "Skeleton3D", true, false)
	if players.is_empty() or skeletons.is_empty(): return
	player = players[0]; skeleton = skeletons[0]
	apply_clip_library(player, model_key)
	for clip in CLIP_SET:
		if player.has_animation(clip): clips[clip] = player.get_animation(clip); sources[clip] = clip
	if not clips.has("idle"): return
	# The original single attack is attack_1 (and new sets keep `attack` working for older code).
	if clips.has("attack") and not clips.has("attack_1"): clips["attack_1"] = clips["attack"]; sources["attack_1"] = "attack"
	if clips.has("attack_1") and not clips.has("attack"): clips["attack"] = clips["attack_1"]; sources["attack"] = "attack_1"
	for clip in clips: prepare(clips[clip], clip in LOOPS)
	player.stop(); player.active = false
	build_tree()
	var spine_bones = find_spine(skeleton)
	for i in spine_bones.size():
		spine.append(spine_bones[i])
		spine_w.append(0.15 if i == 0 else 0.85 / maxf(1, spine_bones.size() - 1))
	# The arena nests the model as holder > CombatMotion > model.
	var holder = model.get_parent().get_parent() if model.get_parent() and model.get_parent().get_parent() is Node3D else model
	add_springs(holder)
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
	# Locomotion: (idle | combat idle) blended with (walk | run) by ground speed.
	for pair in [["idle", "idle"], ["combat", "idle_combat" if clips.has("idle_combat") else "idle"],
			["walk", "walk" if clips.has("walk") else "idle"], ["run", "run" if clips.has("run") else "walk" if clips.has("walk") else "idle"]]:
		add.call(pair[0], anim_node(pair[1]))
		add.call(pair[0] + "_ts", AnimationNodeTimeScale.new())
		blend.connect_node(pair[0] + "_ts", 0, pair[0])
	add.call("rest", AnimationNodeBlend2.new())
	add.call("gait", AnimationNodeBlend2.new())
	add.call("move", AnimationNodeBlend2.new())
	blend.connect_node("rest", 0, "idle_ts"); blend.connect_node("rest", 1, "combat_ts")
	blend.connect_node("gait", 0, "walk_ts"); blend.connect_node("gait", 1, "run_ts")
	blend.connect_node("move", 0, "rest"); blend.connect_node("move", 1, "gait")
	var below = "move"
	# Seek-driven layers: two action slots, then stun, hit reaction, spawn/victory and death on top.
	for s in ["a", "b"] + LAYERS:
		var first = "death" if s == "d" and clips.has("death") else "stun" if s == "s" and clips.has("stun") else "idle"
		add.call(s + "_clip", anim_node(first))
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
	for s in ["a", "b"] + LAYERS: tree.set("parameters/%s_ts/scale" % s, 0.0)
	for s in ["idle", "combat", "walk", "run"]: tree.set("parameters/%s_ts/scale" % s, tempo)
	tree.active = true

func anim_node(clip: String) -> AnimationNodeAnimation:
	var node = AnimationNodeAnimation.new(); node.animation = clip
	return node

## Called every frame. dt is game time (already scaled by battle speed; 0 while paused).
## act: what the simulation is winding up: "attack" (a basic swing), "heavy" (a physical skill) or
## "cast" (a magical one); "" when none. remaining: seconds until the sim resolves that windup.
## next_eta: seconds until the next swing can start. ground_speed and plant (the walk cycle's
## foot-planted speed, GaitRates.PLANT) pick walk or run.
func drive(dt: float, act: String, remaining: float, alive: bool, stunned: bool, travelling: bool, walk_rate: float, engaged: bool, next_eta: float, ground_speed: float = 0.0, plant: float = 2.0) -> void:
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
			var clip = clip_for(act, swings)
			if act == "attack": swings += 1
			if clip != "": start(clip)
		winding = act != ""
		if current >= 0: advance_slot(slots[current], eff, remaining, stunned, next_eta)
	# Locomotion underneath everything.
	var moving = travelling and alive
	walk_w = move_toward(walk_w, 1.0 if moving else 0.0, eff / WALK_FADE)
	var fast = ground_speed > plant * (1.25 if run_w > 0.5 else 1.45)
	run_w = move_toward(run_w, 1.0 if moving and fast and clips.has("run") else 0.0, eff / 0.15)
	combat_w = move_toward(combat_w, 1.0 if engaged and alive else 0.0, eff / 0.25)
	tree.set("parameters/move/blend_amount", walk_w)
	tree.set("parameters/gait/blend_amount", run_w)
	if clips.has("idle_combat"):
		tree.set("parameters/rest/blend_amount", combat_w)
	else:
		# No authored combat idle: the same idle, breathing faster while engaged (blending the clip
		# against a sped-up copy of itself would only smear it).
		tree.set("parameters/rest/blend_amount", 0.0)
		tree.set("parameters/idle_ts/scale", tempo * (1.35 if engaged and alive else 1.0))
	tree.set("parameters/walk_ts/scale", walk_rate)
	if clips.has("run"):
		# A run stride covers about 1.8x a walk stride in its own cycle time.
		var run_plant = plant * 1.8 * float(clips.walk.length if clips.has("walk") else 1.0) / maxf(0.1, float(clips.run.length))
		tree.set("parameters/run_ts/scale", clampf(ground_speed / maxf(0.1, run_plant), 0.5, 2.2))
	else:
		tree.set("parameters/run_ts/scale", walk_rate)
	tree.set("parameters/combat_ts/scale", tempo * (1.0 if clips.has("idle_combat") else 1.35))
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
	layers(eff, stunned and alive and not dead)
	if dead and clips.has("death"):
		death_t = minf(float(clips.death.length), death_t + eff * DEATH_RATE)
		death_w = move_toward(death_w, 1.0, eff / 0.12)
		tree.set("parameters/d_seek/seek_request", death_t)
	tree.set("parameters/d_mix/blend_amount", death_w)
	unbend()
	tree.advance(eff)
	flinch_step(eff)
	intro_dt = 0.0

## Which clip plays for an action. Basic swings alternate attack_1 / attack_2 when both exist;
## physical skills use attack_heavy; anything missing falls back toward attack_1.
func clip_for(kind: String, swing: int) -> String:
	match kind:
		"attack":
			if clips.has("attack_1") and clips.has("attack_2"): return "attack_1" if swing % 2 == 0 else "attack_2"
			return "attack_1" if clips.has("attack_1") else ""
		"heavy": return "attack_heavy" if clips.has("attack_heavy") else clip_for("attack", swing)
		"cast": return "cast" if clips.has("cast") else clip_for("attack", swing)
	return kind if clips.has(kind) else clip_for("attack", swing)

func start(clip: String) -> void:
	var slot = 0 if current != 0 else 1
	var m = marks(key, clip)
	var length = float(clips[clip].length)
	var w = 0.0 if slots[slot].is_empty() else float(slots[slot].w)
	slots[slot] = {"clip": clip, "t": 0.0, "w": w, "phase": "wind", "length": length,
		"ready": m.ready * length, "hit": m.hit * length, "resume": m.resume * length}
	(blend.get_node(("a" if slot == 0 else "b") + "_clip") as AnimationNodeAnimation).animation = sources.get(clip, clip)
	current = slot
	if not event.is_empty() and event.clip == "spawn": event.t = maxf(event.t, float(clips.spawn.length) - 0.1)

## Stun loop, hit reaction and spawn/victory layers.
func layers(eff: float, stunned: bool) -> void:
	# Stun: the stun loop, or a slowed idle when the creature has none.
	stun_w = move_toward(stun_w, 1.0 if stunned else 0.0, eff / (0.1 if stunned else 0.18))
	if stun_w > 0.0:
		var clip = "stun" if clips.has("stun") else "idle"
		stun_t = fmod(stun_t + eff * (tempo if clip == "stun" else 0.35), float(clips[clip].length))
		tree.set("parameters/s_seek/seek_request", stun_t)
	tree.set("parameters/s_mix/blend_amount", stun_w)
	# Hit reaction: quick in, fades over the back half.
	if not reaction.is_empty():
		var length = float(clips[reaction.clip].length)
		reaction.t = minf(length, reaction.t + eff * tempo)
		var fall = clampf((length - reaction.t) / (length * 0.45), 0.0, 1.0)
		reaction.w = minf(move_toward(reaction.w, reaction.peak, eff / 0.04), reaction.peak * fall)
		tree.set("parameters/h_seek/seek_request", reaction.t)
		if reaction.t >= length or dead: reaction = {}
	tree.set("parameters/h_mix/blend_amount", 0.0 if reaction.is_empty() else reaction.w)
	# Spawn (one shot, pre-fight clock allowed) and victory (loop).
	if not event.is_empty():
		var length = float(clips[event.clip].length)
		var step = maxf(eff, intro_dt) if event.clip == "spawn" else eff
		event.t = fmod(event.t + step * tempo, length) if event.loop else minf(length, event.t + step * tempo)
		if event.loop: event.w = move_toward(event.w, 1.0, step / 0.25)
		else: event.w = clampf((length - event.t) / 0.15, 0.0, 1.0)
		tree.set("parameters/e_seek/seek_request", event.t)
		if (not event.loop and event.t >= length) or dead: event = {}
	tree.set("parameters/e_mix/blend_amount", 0.0 if event.is_empty() else event.w)

## A visible reaction to a hit (the spine flinch always applies on top). Skipped mid-windup so it
## can't interrupt the fighter's own strike.
func hit_react(heavy_hit: bool) -> void:
	if not ok or dead or winding: return
	var clip = "hit_heavy" if heavy_hit and clips.has("hit_heavy") else "hit_light" if clips.has("hit_light") else "hit_heavy" if clips.has("hit_heavy") else ""
	if clip == "": return
	if not reaction.is_empty() and reaction.clip == "hit_heavy" and clip == "hit_light" and reaction.t < 0.2: return
	(blend.get_node("h_clip") as AnimationNodeAnimation).animation = clip
	reaction = {"clip": clip, "t": 0.0, "peak": 1.0 if clip == "hit_heavy" else 0.75, "w": 0.0 if reaction.is_empty() else float(reaction.w)}

## Leap onto the board as the fight starts (no-op without a spawn clip).
func spawn() -> void:
	if not ok or dead or not clips.has("spawn"): return
	(blend.get_node("e_clip") as AnimationNodeAnimation).animation = "spawn"
	event = {"clip": "spawn", "t": 0.0, "loop": false, "w": 1.0}

## Winners celebrate while the results are tallied (no-op without a victory clip).
func celebrate() -> void:
	if not ok or dead or not clips.has("victory") or (not event.is_empty() and event.clip == "victory"): return
	(blend.get_node("e_clip") as AnimationNodeAnimation).animation = "victory"
	event = {"clip": "victory", "t": 0.0, "loop": true, "w": 0.0}

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
		# Finished, but the next swing is about to start: hold the last frame so the two swings
		# cross-fade straight into each other instead of dipping toward idle in between.
		if s.t >= s.length - 0.001 and next_eta > FADE_OUT: s.phase = "out"

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
