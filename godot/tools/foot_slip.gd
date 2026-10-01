extends SceneTree
## Walks every creature at full sim speed with the arena's walk-rate rule and measures foot slip:
## horizontal speed of feet while planted / body speed. 0 = perfectly planted, 1 = skating.
var feet: Dictionary
func _init() -> void:
	HeroData.load_data()
	feet = JSON.parse_string(FileAccess.get_file_as_string("res://tools/feet.json"))
	var only = OS.get_environment("ONLY")
	for sp in HeroData.species.keys():
		if only != "" and sp != only: continue
		var info = feet.get(sp, {})
		if info.get("flyer", false) or info.get("feet", []).is_empty(): continue
		var holder := Node3D.new(); get_root().add_child(holder)
		var model: Node3D = load("res://assets/beasts/%s.glb" % sp).instantiate(); holder.add_child(model)
		model.scale = Vector3.ONE * 0.72
		var ap: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
		var sk: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
		ap.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
		ap.play("walk")
		var v = HeroData.species[sp].mv * 0.036 * ArenaView.FLOOR_SCALE * float(OS.get_environment("PACE") if OS.get_environment("PACE") != "" else "1.0")
		ap.speed_scale = GaitRates.walk_rate(sp, v)
		var ids = []
		for f in info.feet:
			var i = sk.find_bone(f)
			if i >= 0: ids.append(i)
		var dt = 1.0 / 120.0
		var prevp = {}; var ymin = {}; var ymax = {}
		var samples = []
		for k in range(480):
			holder.position.z += v * dt
			ap.advance(dt)
			var glob = []
			for b in range(sk.get_bone_count()):
				var par = sk.get_bone_parent(b); var lt = sk.get_bone_pose(b)
				glob.append(lt if par < 0 else glob[par] * lt)
			var rel = _rel(holder, sk)
			for i in ids:
				var wp = holder.transform * rel * glob[i].origin
				if prevp.has(i) and k > 120:
					samples.append([i, wp.y, Vector2(wp.x - prevp[i].x, wp.z - prevp[i].z).length() / dt, (wp.z - prevp[i].z) / dt])
				ymin[i] = minf(ymin.get(i, 1e9), wp.y); ymax[i] = maxf(ymax.get(i, -1e9), wp.y)
				prevp[i] = wp
		# planted = foot nearly still in the world; good gait: ~40-60% planted, and planted while LOW.
		var planted = 0; var n = 0; var hp = 0.0; var hall = 0.0
		for s in samples:
			var i = s[0]; var hr = (s[1] - ymin[i]) / maxf(0.02, ymax[i] - ymin[i])
			n += 1; hall += hr
			if s[2] < 0.25 * v: planted += 1; hp += hr
		var pf = float(planted) / maxf(1, n)
		print("%-12s rate %.2f body %.2f planted %.0f%%  height-when-planted %.2f (avg %.2f)" % [sp, ap.speed_scale, v, pf * 100.0, hp / maxf(1, planted), hall / maxf(1, n)])
		holder.free()
	quit()

func _rel(top: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY; var p = n
	while p != null and p != top:
		if p is Node3D: t = p.transform * t
		p = p.get_parent()
	return t
