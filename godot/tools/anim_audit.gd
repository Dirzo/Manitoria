extends SceneTree
## Step 2: audit every creature's clips against the combat clip set (art/combat_clips/README.md).
## Per creature: which of the 14 clips exist; for each clip, the share of the rig it animates, the loop
## seam (largest bone-rotation jump from the last frame back to the first), horizontal root drift
## (should be ~0: clips are in place), and whether attack/cast contact was measured. Writes
## data/anim_audit.json and prints a summary.
## Run: godot --headless --path godot -s tools/anim_audit.gd [-- --strict minotaur,direwolf]
## --strict: exit 1 if a listed creature misses a clip or fails a threshold (for the pilot).
const SET := ["idle", "idle_combat", "walk", "run", "attack_1", "attack_2", "attack_heavy", "cast",
	"hit_light", "hit_heavy", "stun", "death", "spawn", "victory"]
const LOOPS := ["idle", "idle_combat", "walk", "run", "stun", "victory"]
const ACTIONS := ["attack_1", "attack_2", "attack_heavy", "cast", "hit_light", "hit_heavy"]
const MIN_COVERAGE := 0.8
const MAX_SEAM_DEG := 2.0
const MAX_DRIFT := 0.05

func _init() -> void:
	run.call_deferred()

func run() -> void:
	HeroData.load_data()
	var strict = []
	var a = OS.get_cmdline_user_args()
	if a.has("--strict") and a.find("--strict") + 1 < a.size(): strict = Array(a[a.find("--strict") + 1].split(","))
	var contact = {}
	if FileAccess.file_exists("res://data/anim_contact.json"): contact = JSON.parse_string(FileAccess.get_file_as_string("res://data/anim_contact.json"))
	var feet = {}
	if FileAccess.file_exists("res://tools/feet.json"): feet = JSON.parse_string(FileAccess.get_file_as_string("res://tools/feet.json"))
	var out = {}
	var failed = []
	print("creature      clips  missing")
	for sp in HeroData.species.keys():
		var model: Node3D = load("res://assets/beasts/%s.glb" % sp).instantiate()
		get_root().add_child(model)
		await process_frame
		var ap: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
		CombatAnimator.apply_clip_library(ap, sp)
		var sk: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
		var row = {"bones": sk.get_bone_count(), "clips": {}, "missing": [], "warnings": []}
		for clip in SET:
			var name = clip if ap.has_animation(clip) else "attack" if clip == "attack_1" and ap.has_animation("attack") else ""
			if name == "": row.missing.append(clip); continue
			var anim: Animation = ap.get_animation(name)
			var info = {"length": snappedf(anim.length, 0.01), "coverage": coverage(anim, sk), "drift": drift(anim)}
			if clip in LOOPS: info["seam_deg"] = seam(ap, sk, name)
			if clip in ["attack_1", "attack_2", "attack_heavy", "cast"]:
				info["contact"] = contact.get(sp, {}).has(name)
			row.clips[clip] = info
			if clip in ACTIONS and info.coverage < MIN_COVERAGE: row.warnings.append("%s moves %d%% of the rig" % [clip, int(info.coverage * 100)])
			if info.has("seam_deg") and info.seam_deg > MAX_SEAM_DEG: row.warnings.append("%s loop seam %.1f deg" % [clip, info.seam_deg])
			if info.drift > MAX_DRIFT and clip not in ["death", "spawn"]: row.warnings.append("%s drifts %.2f (not in place)" % [clip, info.drift])
			if info.has("contact") and not info.contact: row.warnings.append("%s has no measured contact (run anim_contact_probe)" % clip)
		var f = feet.get(sp, {}).get("feet", [])
		for bone in f:
			if sk.find_bone(bone) < 0: row.warnings.append("tools/feet.json bone %s not in this rig (re-measure gait)" % bone); break
		out[sp] = row
		print("%-13s %2d/14  %s" % [sp, SET.size() - row.missing.size(), ", ".join(row.missing) if row.missing.size() < 9 else "%d clips (original five-clip set)" % row.missing.size()])
		for w in row.warnings: print("              ! " + w)
		if sp in strict and (not row.missing.is_empty() or not row.warnings.is_empty()): failed.append(sp)
		model.queue_free()
	var file = FileAccess.open("res://data/anim_audit.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(out, "\t", true))
	var complete = out.keys().filter(func(k): return out[k].missing.is_empty())
	print("\n%d/%d creatures have the full combat set. Report: data/anim_audit.json" % [complete.size(), out.size()])
	if not strict.is_empty(): print("strict %s: %s" % [str(strict), "OK" if failed.is_empty() else "FAILED " + str(failed)])
	quit(1 if not failed.is_empty() else 0)

## Share of bones with an animated rotation that actually changes during the clip.
func coverage(anim: Animation, sk: Skeleton3D) -> float:
	var moving = {}
	for t in anim.get_track_count():
		if anim.track_get_type(t) != Animation.TYPE_ROTATION_3D: continue
		var n = anim.track_get_key_count(t)
		if n < 2: continue
		var first: Quaternion = anim.track_get_key_value(t, 0)
		for k in range(1, n):
			if first.angle_to(anim.track_get_key_value(t, k)) > 0.01:
				moving[anim.track_get_path(t).get_concatenated_subnames()] = true; break
	return snappedf(float(moving.size()) / maxf(1.0, sk.get_bone_count()), 0.01)

## Horizontal travel of the top-most translated bone from first to last key.
func drift(anim: Animation) -> float:
	var worst = 0.0
	for t in anim.get_track_count():
		if anim.track_get_type(t) != Animation.TYPE_POSITION_3D or anim.track_get_key_count(t) < 2: continue
		var a: Vector3 = anim.track_get_key_value(t, 0)
		var b: Vector3 = anim.track_get_key_value(t, anim.track_get_key_count(t) - 1)
		worst = maxf(worst, Vector2(b.x - a.x, b.z - a.z).length())
		break
	return snappedf(worst, 0.001)

## Largest bone rotation jump between the end and the start of a loop.
func seam(ap: AnimationPlayer, sk: Skeleton3D, clip: String) -> float:
	var anim = ap.get_animation(clip)
	ap.play(clip); ap.speed_scale = 0.0
	ap.seek(0.0, true); sk.force_update_all_bone_transforms()
	var start = []
	for i in sk.get_bone_count(): start.append(sk.get_bone_pose_rotation(i))
	ap.seek(maxf(0.0, anim.length - 0.0005), true); sk.force_update_all_bone_transforms()
	var worst = 0.0
	for i in sk.get_bone_count():
		var d: Quaternion = start[i].inverse() * sk.get_bone_pose_rotation(i)
		worst = maxf(worst, 2.0 * atan2(Vector3(d.x, d.y, d.z).length(), absf(d.w)))
	return snappedf(rad_to_deg(worst), 0.1)
