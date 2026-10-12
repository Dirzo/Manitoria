extends RefCounted
## Retargets clips from a source rig (Mesh2Motion's CC0 libraries: human, fox, horse, snake, spider, kaiju...)
## onto a Manitoria creature's own rig, so the creature keeps its Meshy model, skin weights and bone names.
##
## Both skeletons are split into chains by their shape alone (no bone names needed, so the generic
## Bone_### rigs work): spine (hips -> chest), neck (chest -> head), the two arm/front-leg chains at the
## chest, the two leg chains at the hips, and a tail. Chains are matched by role and side, and bones are
## paired along each chain by their share of its length.
##
## Per frame, in world space with both models facing +Z:
##  - hips take the source's change of orientation from its rest (delta), and a scaled, in-place version
##    of its translation;
##  - "absolute" chains (limbs) point each bone where the source's matching segment points;
##  - "relative" chains (spine, neck, tail) turn each bone by the same rotation (twist included) the source
##    bone made from its reference pose, so a hunched minotaur stays hunched while copying an upright
##    human's motion, and a boxer's hip turn keeps its counter-twisted chest;
##  - chain ends (head, hands, feet) copy the source bone's change of orientation;
##  - every other bone (ears, jaw, fingers, extra branches) keeps its rest pose relative to its parent.
## Every bone gets a track, so the whole rig moves.

const FPS := 30.0
const MODES := {"spine": "relative", "neck": "relative", "tail": "relative",
	"arm_l": "absolute", "arm_r": "absolute", "leg_l": "absolute", "leg_r": "absolute"}

var report := []

# ---------------------------------------------------------------- chains

static func subtree(sk: Skeleton3D, b: int) -> int:
	var n = 1
	for c in sk.get_bone_children(b): n += subtree(sk, c)
	return n

static func significant(sk: Skeleton3D, b: int) -> Array:
	return Array(sk.get_bone_children(b)).filter(func(c): return subtree(sk, c) >= 3)

## Follow the biggest branch from `b` until a bone with two or more significant branches (a hand with
## fingers, a head with ears and jaw) or a leaf.
static func primary_path(sk: Skeleton3D, b: int) -> Array:
	var out = [b]
	while true:
		var kids = Array(sk.get_bone_children(out[-1]))
		# Stop at a hand with fingers, a head with ears and jaw: several branches, none clearly the main one.
		if kids.is_empty() or significant(sk, out[-1]).size() >= 2 or kids.size() >= 3: break
		var best = kids[0]
		for c in kids:
			if subtree(sk, c) > subtree(sk, best): best = c
		out.append(best)
	return out

static func world_rest(sk: Skeleton3D, b: int) -> Transform3D:
	return sk.global_transform * sk.get_bone_global_rest(b)

## {"spine":[...], "neck":[...], "arm_l":[...], "arm_r":[...], "leg_l":[...], "leg_r":[...], "tail":[...]}
static func chains(sk: Skeleton3D) -> Dictionary:
	var out = {}
	var hips = -1
	for i in sk.get_bone_count():
		if significant(sk, i).size() >= 3: hips = i; break
	if hips < 0:
		for i in sk.get_bone_count():
			if significant(sk, i).size() >= 2: hips = i; break
	if hips < 0: return out
	var lo = INF; var hi = -INF
	for i in sk.get_bone_count():
		var y = world_rest(sk, i).origin.y
		lo = minf(lo, y); hi = maxf(hi, y)
	var height = maxf(0.001, hi - lo)
	var hip_pos = world_rest(sk, hips).origin
	var branches = significant(sk, hips)
	var spine_root = branches[0]
	for c in branches:
		if subtree(sk, c) > subtree(sk, spine_root): spine_root = c
	# Spine: through single significant branches up to the chest.
	var spine = [hips, spine_root]
	while significant(sk, spine[-1]).size() == 1 and spine.size() < 12:
		spine.append(significant(sk, spine[-1])[0])
	out.spine = spine
	var chest = spine[-1]
	var tip = func(b: int) -> Vector3: return world_rest(sk, primary_path(sk, b)[-1]).origin
	var at_chest = significant(sk, chest)
	var chest_kids = Array(sk.get_bone_children(chest))
	if not chest_kids.is_empty():
		# The head: high, forward and central among all the chest's branches (a short 2-bone head counts;
		# wings, being lateral, don't win).
		var score = func(c: int) -> float:
			var p = tip.call(c); return p.y + p.z - 1.5 * absf(p.x - hip_pos.x)
		var neck = chest_kids[0]
		for c in chest_kids:
			if score.call(c) > score.call(neck): neck = c
		out.neck = primary_path(sk, neck)
		var limbs = at_chest.filter(func(c): return c != neck)
		# With wings and arms both at the chest, the arms are the pair that reaches lowest.
		limbs.sort_custom(func(a, b): return tip.call(a).y < tip.call(b).y)
		var left = limbs.filter(func(c): return tip.call(c).x > hip_pos.x)
		var right = limbs.filter(func(c): return tip.call(c).x <= hip_pos.x)
		if not left.is_empty(): out.arm_l = primary_path(sk, left[0])
		if not right.is_empty(): out.arm_r = primary_path(sk, right[0])
	var others = branches.filter(func(c): return c != spine_root)
	var legs = others.filter(func(c): return tip.call(c).y - lo < height * 0.3)
	legs.sort_custom(func(a, b): return tip.call(a).y < tip.call(b).y)
	var l_legs = legs.filter(func(c): return tip.call(c).x > hip_pos.x)
	var r_legs = legs.filter(func(c): return tip.call(c).x <= hip_pos.x)
	if not l_legs.is_empty() and not r_legs.is_empty():
		out.leg_l = primary_path(sk, l_legs[0]); out.leg_r = primary_path(sk, r_legs[0])
		legs = [l_legs[0], r_legs[0]]
	else:
		legs = []
	var tails = others.filter(func(c): return c not in legs)
	if not tails.is_empty():
		var t = tails[0]
		for c in tails:
			if tip.call(c).z < tip.call(t).z: t = c
		var path = primary_path(sk, t)
		while path.size() < 40 and not sk.get_bone_children(path[-1]).is_empty():
			var kids = Array(sk.get_bone_children(path[-1])); var best = kids[0]
			for c in kids:
				if subtree(sk, c) > subtree(sk, best): best = c
			path.append(best)
		out.tail = path
	# A symmetric rig has the same joints on both sides; a longer chain ran on into a weapon or prop.
	for pair_roles in [["arm_l", "arm_r"], ["leg_l", "leg_r"]]:
		if out.has(pair_roles[0]) and out.has(pair_roles[1]):
			var n = mini(out[pair_roles[0]].size(), out[pair_roles[1]].size())
			out[pair_roles[0]] = out[pair_roles[0]].slice(0, n); out[pair_roles[1]] = out[pair_roles[1]].slice(0, n)
	out.hips = [hips]
	return out

## Direction the creature faces (horizontal, world). Long necks/heads point forward; for upright bodies,
## the toes do.
static func facing(sk: Skeleton3D, ch: Dictionary) -> Vector3:
	var hip = world_rest(sk, ch.hips[0]).origin
	if ch.has("neck"):
		var head = world_rest(sk, ch.neck[-1]).origin - hip; head.y = 0
		var height = 0.0
		for b in ch.spine + ch.neck: height = maxf(height, world_rest(sk, b).origin.y)
		if head.length() > 0.25 * maxf(0.1, height): return head.normalized()
	var sum = Vector3.ZERO
	for side in ["leg_l", "leg_r"]:
		if ch.has(side) and ch[side].size() >= 2:
			var toe = world_rest(sk, ch[side][-1]).origin - world_rest(sk, ch[side][-2]).origin; toe.y = 0
			sum += toe
	return sum.normalized() if sum.length() > 0.001 else Vector3.BACK * -1.0

# ---------------------------------------------------------------- mapping

static func chain_fractions(sk: Skeleton3D, chain: Array) -> Array:
	var d = [0.0]
	for i in range(1, chain.size()):
		d.append(d[-1] + world_rest(sk, chain[i]).origin.distance_to(world_rest(sk, chain[i - 1]).origin))
	var total = maxf(0.0001, d[-1])
	return d.map(func(x): return x / total)

## target bone -> source bone, for every chain both rigs share.
static func pair(tsk: Skeleton3D, tch: Dictionary, ssk: Skeleton3D, sch: Dictionary, only: Array = []) -> Dictionary:
	var out = {}
	for role in tch:
		if role == "hips" or not sch.has(role): continue
		if not only.is_empty() and role not in only: continue
		var tf = chain_fractions(tsk, tch[role]); var sf = chain_fractions(ssk, sch[role])
		for i in tch[role].size():
			var best = 0
			for j in sf.size():
				if absf(sf[j] - tf[i]) < absf(sf[best] - tf[i]): best = j
			if i == tch[role].size() - 1: best = sf.size() - 1
			out[tch[role][i]] = {"role": role, "source": sch[role][best], "index": i}
	return out

# ---------------------------------------------------------------- retarget

## Chains given by bone name (for rigs the shape rules misread), e.g. {"spine": ["Bone_004", ...]}.
## The first spine bone is the hips.
static func chains_from_names(sk: Skeleton3D, names: Dictionary) -> Dictionary:
	var out = {}
	for role in names:
		out[role] = Array(names[role]).map(func(n): return sk.find_bone(n)).filter(func(b): return b >= 0)
	if out.has("spine") and not out.spine.is_empty(): out.hips = [out.spine[0]]
	return out

## Builds the clip on the target from the source clip. `roles` limits which chains are driven (for a
## naga's upper body, say); unlisted chains keep their rest pose. `override` names the target's chains
## by bone name. Manitoria creatures all face +Z. Returns the Animation.
## `ground` (0..1) pulls the lowest foot back onto the floor each frame: 1 for planted clips, less for
## ones with a flight phase (runs), 0 for deaths and leaps that own their height.
func retarget(target: Node3D, source: Node3D, clip: String, roles: Array = [], loop: bool = false,
		speed: float = 1.0, trim: Vector2 = Vector2(0, 1), travel: float = 0.25, override: Dictionary = {},
		ground: float = 1.0, twist: float = 1.0, amplify: float = 1.0, body: float = 1.0) -> Animation:
	var tsk: Skeleton3D = target.find_children("*", "Skeleton3D", true, false)[0]
	var ssk: Skeleton3D = source.find_children("*", "Skeleton3D", true, false)[0]
	var sap: AnimationPlayer = source.find_children("*", "AnimationPlayer", true, false)[0]
	var tap: AnimationPlayer = target.find_children("*", "AnimationPlayer", true, false)[0]
	if not sap.has_animation(clip):
		report.append("missing source clip " + clip); return null
	var tch = chains_from_names(tsk, override) if not override.is_empty() else chains(tsk)
	var sch = chains(ssk)
	var pairs = pair(tsk, tch, ssk, sch, roles)
	var align = Quaternion(facing(ssk, sch), Vector3(0, 0, 1))   # source world -> target world
	var tskr = tsk.global_transform.basis.get_rotation_quaternion()
	var t_hips = tch.hips[0]; var s_hips = sch.hips[0]
	var drive_hips = roles.is_empty() or "spine" in roles or "hips" in roles
	var t_hip_rest = world_rest(tsk, t_hips); var s_hip_rest = world_rest(ssk, s_hips)
	var t_ground = INF; var s_ground = INF
	for i in tsk.get_bone_count(): t_ground = minf(t_ground, world_rest(tsk, i).origin.y)
	for i in ssk.get_bone_count(): s_ground = minf(s_ground, world_rest(ssk, i).origin.y)
	var scale = (t_hip_rest.origin.y - t_ground) / maxf(0.001, s_hip_rest.origin.y - s_ground)
	# Feet: the ends of chains that rest near the floor.
	var feet = []
	var t_top = -INF
	for i in tsk.get_bone_count(): t_top = maxf(t_top, world_rest(tsk, i).origin.y)
	for role in ["leg_l", "leg_r", "arm_l", "arm_r", "tail"]:
		if tch.has(role) and not tch[role].is_empty():
			var end = tch[role][-1]
			if world_rest(tsk, end).origin.y - t_ground < (t_top - t_ground) * 0.12: feet.append(end)
	var rest_floor = INF
	for b in feet: rest_floor = minf(rest_floor, world_rest(tsk, b).origin.y)
	var lifts = []
	# Chain neighbours: the next bone along each target chain.
	var next_of = {}
	for role in tch:
		for i in range(tch[role].size() - 1): next_of[tch[role][i]] = tch[role][i + 1]
	var source_next = {}
	for role in sch:
		for i in range(sch[role].size() - 1): source_next[sch[role][i]] = sch[role][i + 1]
	# Bones in parent-first order.
	var order = []
	var queue = []
	for i in tsk.get_bone_count():
		if tsk.get_bone_parent(i) < 0: queue.append(i)
	while not queue.is_empty():
		var b = queue.pop_front(); order.append(b)
		for c in tsk.get_bone_children(b): queue.append(c)
	# Source reference pose, in target-aligned world space. Mesh2Motion libraries ship a "Rest Pose" clip,
	# the pose their animations are authored against; the skin's bind pose can differ from it.
	var s_rest_rot = {}; var s_rest_pos = {}
	var rest_clip = ""
	for n in sap.get_animation_list():
		if str(n).to_lower().replace("_", " ") == "rest pose": rest_clip = n
	if rest_clip != "":
		sap.play(rest_clip); sap.speed_scale = 0.0; sap.seek(0.0, true); ssk.force_update_all_bone_transforms()
	for i in ssk.get_bone_count():
		var w = (ssk.global_transform * ssk.get_bone_global_pose(i)) if rest_clip != "" else world_rest(ssk, i)
		s_rest_rot[i] = align * w.basis.get_rotation_quaternion(); s_rest_pos[i] = align * w.origin
	var t_rest_rot = {}; var t_rest_pos = {}
	for i in tsk.get_bone_count():
		var w = world_rest(tsk, i)
		t_rest_rot[i] = w.basis.get_rotation_quaternion(); t_rest_pos[i] = w.origin
	var anim_src = sap.get_animation(clip)
	var start = anim_src.length * trim.x; var stop = anim_src.length * trim.y
	var length = (stop - start) / speed
	var frames = maxi(2, int(round(length * FPS)) + 1)
	var out = Animation.new(); out.length = length
	var root_node: Node = tap.get_node(tap.root_node)
	var base_path = str(root_node.get_path_to(tsk))
	var tracks = {}
	for b in order:
		var t = out.add_track(Animation.TYPE_ROTATION_3D)
		out.track_set_path(t, NodePath(base_path + ":" + tsk.get_bone_name(b)))
		out.track_set_interpolation_type(t, Animation.INTERPOLATION_LINEAR)
		tracks[b] = t
	var hip_track = out.add_track(Animation.TYPE_POSITION_3D)
	out.track_set_path(hip_track, NodePath(base_path + ":" + tsk.get_bone_name(t_hips)))
	sap.play(clip); sap.speed_scale = 0.0
	var first_local = []
	if amplify != 1.0:
		sap.seek(start, true)
		for i in ssk.get_bone_count(): first_local.append(ssk.get_bone_pose_rotation(i))
	var hip_offsets = []
	for f in frames:
		var time_out = minf(length, f / FPS)
		sap.seek(minf(anim_src.length, start + time_out * speed), true)
		if amplify != 1.0:
			# Exaggerate the motion: scale every joint's turn away from the clip's first frame.
			for i in ssk.get_bone_count():
				var q0: Quaternion = first_local[i]
				var d: Quaternion = q0.inverse() * ssk.get_bone_pose_rotation(i)
				var axis = Vector3(d.x, d.y, d.z)
				if axis.length() > 0.00001:
					var ang = 2.0 * atan2(axis.length(), d.w) * amplify
					ssk.set_bone_pose_rotation(i, q0 * Quaternion(axis.normalized(), ang))
		ssk.force_update_all_bone_transforms()
		var s_rot = {}; var s_pos = {}
		for i in ssk.get_bone_count():
			var w = ssk.global_transform * ssk.get_bone_global_pose(i)
			s_rot[i] = align * w.basis.get_rotation_quaternion(); s_pos[i] = align * w.origin
		if twist < 1.0:
			# Keep only part of the body's turn: spin the whole source figure back about its pelvis by the
			# rest of the upper body's yaw, so the creature keeps facing its target through the swing.
			var chest = sch.spine[-1]
			var f0 = s_rest_rot[chest] * Vector3.FORWARD; var f1 = s_rot[chest] * Vector3.FORWARD
			var yaw = atan2(f1.x, f1.z) - atan2(f0.x, f0.z)
			yaw = wrapf(yaw, -PI, PI)
			var back = Quaternion(Vector3.UP, -yaw * (1.0 - twist))
			var pivot = s_pos[s_hips]
			for i in ssk.get_bone_count():
				s_rot[i] = back * s_rot[i]; s_pos[i] = pivot + back * (s_pos[i] - pivot)
		var W = {}
		for b in order:
			var parent = tsk.get_bone_parent(b)
			var parent_w: Quaternion = W[parent] if parent >= 0 else tskr
			var rest_local = tsk.get_bone_rest(b).basis.get_rotation_quaternion()
			var tmp: Quaternion = parent_w * rest_local
			var w: Quaternion = tmp
			if b == t_hips and drive_hips:
				w = Quaternion.IDENTITY.slerp(s_rot[s_hips] * s_rest_rot[s_hips].inverse(), body) * t_rest_rot[b]
			elif pairs.has(b):
				var p = pairs[b]; var s = p.source
				var mode = MODES.get(p.role, "relative")
				if mode == "absolute" and next_of.has(b) and pairs.has(next_of[b]) and pairs[next_of[b]].source != s:
					var s2 = pairs[next_of[b]].source
					var want = (s_pos[s2] - s_pos[s]).normalized()
					var cur = (tmp * tsk.get_bone_rest(next_of[b]).origin).normalized()
					if cur.length() > 0.0001 and want.length() > 0.0001:
						w = Quaternion(cur, want) * tmp
				else:
					var d: Quaternion = s_rot[s] * s_rest_rot[s].inverse()
					# body < 1 tones down the trunk for creatures whose legs aren't driven (they'd tip over).
					if p.role == "spine": d = Quaternion.IDENTITY.slerp(d, body)
					w = d * t_rest_rot[b]
			W[b] = w.normalized()
			var local = (parent_w.inverse() * W[b]).normalized()
			out.rotation_track_insert_key(tracks[b], time_out, local)
		var off = (s_pos[s_hips] - s_rest_pos[s_hips]) * scale if drive_hips else Vector3.ZERO
		hip_offsets.append(off)
		var lift = 0.0
		if ground > 0.0 and not feet.is_empty():
			for b in order:
				var parent = tsk.get_bone_parent(b)
				var pw: Quaternion = W[parent] if parent >= 0 else tskr
				tsk.set_bone_pose_rotation(b, (pw.inverse() * W[b]).normalized())
			var hp = tsk.get_bone_parent(t_hips)
			var hp_rest = tsk.global_transform * (tsk.get_bone_global_rest(hp) if hp >= 0 else Transform3D.IDENTITY)
			tsk.set_bone_pose_position(t_hips, hp_rest.affine_inverse() * (t_hip_rest.origin + Vector3(0, off.y, 0)))
			tsk.force_update_all_bone_transforms()
			var low = INF
			for b in feet: low = minf(low, (tsk.global_transform * tsk.get_bone_global_pose(b)).origin.y)
			lift = (rest_floor - low) * ground
		lifts.append(lift)
	# In place: remove net horizontal travel, keep bob and a little lunge.
	var drift = hip_offsets[-1] - hip_offsets[0]
	for f in frames:
		var off: Vector3 = hip_offsets[f]
		var k = float(f) / maxf(1, frames - 1)
		off.x -= drift.x * k; off.z -= drift.z * k
		if loop: off -= Vector3(hip_offsets[0].x, 0, hip_offsets[0].z)
		off.x = clampf(off.x, -travel, travel); off.z = clampf(off.z, -travel, travel)
		var parent = tsk.get_bone_parent(t_hips)
		var parent_rest = tsk.global_transform * (tsk.get_bone_global_rest(parent) if parent >= 0 else Transform3D.IDENTITY)
		off.y += lifts[f]
		var world = t_hip_rest.origin + off
		out.position_track_insert_key(hip_track, minf(length, f / FPS), parent_rest.affine_inverse() * world)
	tsk.reset_bone_poses()
	if loop: close_loop(out)
	out.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	report.append("%s <- %s: %d bones driven by %d chains, %.2fs, facing fix %.0f deg" % [out.resource_name, clip, pairs.size(), tch.size(), length, rad_to_deg(align.get_angle())])
	return out

## Blend the last 15% toward the first frame so loops have no seam.
static func close_loop(anim: Animation) -> void:
	for t in anim.get_track_count():
		var n = anim.track_get_key_count(t)
		if n < 4: continue
		var first = anim.track_get_key_value(t, 0)
		var blend_from = int(n * 0.85)
		for k in range(blend_from, n):
			var w = float(k - blend_from + 1) / float(n - blend_from)
			var v = anim.track_get_key_value(t, k)
			if v is Quaternion: anim.track_set_key_value(t, k, v.slerp(first, w))
			elif v is Vector3: anim.track_set_key_value(t, k, v.lerp(first, w))
