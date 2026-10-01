extends SceneTree
## For every creature: foot stride length in its walk loop -> ground speed at which feet stay planted.
func _init() -> void:
	HeroData.load_data()
	var feet = JSON.parse_string(FileAccess.get_file_as_string("res://tools/feet.json"))
	var res = {}
	for sp in HeroData.species.keys():
		var model: Node3D = load("res://assets/beasts/%s.glb" % sp).instantiate(); get_root().add_child(model)
		var ap: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
		var sk: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
		var info = feet.get(sp, {})
		var L = ap.get_animation("walk").length; var N = 60
		ap.play("walk")
		var ids = []
		for f in info.get("feet", []):
			var i = sk.find_bone(f)
			if i >= 0: ids.append(i)
		var zs = {}; var ysd = {}
		var hmin = 1e9; var hmax = -1e9
		for k in range(N):
			ap.seek(L * k / N, true); ap.advance(0.0)
			var glob = []
			for b in range(sk.get_bone_count()):
				var par = sk.get_bone_parent(b); var lt = sk.get_bone_pose(b)
				glob.append(lt if par < 0 else glob[par] * lt)
			var rel = _rel(model, sk)
			for b in range(sk.get_bone_count()):
				var y = (rel * glob[b].origin).y; hmin = minf(hmin, y); hmax = maxf(hmax, y)
			for i in ids:
				var p = rel * glob[i].origin
				if not zs.has(i): zs[i] = []; ysd[i] = []
				zs[i].append(p.z); ysd[i].append(p.y)
		var strides = []; var good = 0.0; var tot = 0.0; var perfoot = {}
		for i in zs:
			var g1 = 0.0; var t1 = 0.0
			strides.append(zs[i].max() - zs[i].min())
			var ymin = ysd[i].min(); var yr = maxf(0.001, ysd[i].max() - ymin)
			for k in range(N):
				var k2 = (k + 1) % N
				if ysd[i][k] < ymin + 0.2 * yr:
					var dz = zs[i][k2] - zs[i][k]
					tot += absf(dz); good += -dz; t1 += absf(dz); g1 += -dz
			perfoot[sk.get_bone_name(i)] = snappedf(g1 / maxf(1e-6, t1), 0.01)
		strides.sort()
		var S = strides[strides.size() / 2] if strides.size() > 0 else 0.0
		var plant = S / (0.6 * L) * 0.72   # stance sweeps the full stride in DUTY (0.6) of the cycle
		var move = HeroData.species[sp].mv * 0.036 * ArenaView.FLOOR_SCALE
		res[sp] = {"stride": S * 0.72, "cycle": L, "plant": plant, "move": move, "ratio": move / plant if plant > 0.01 else 0.0, "height": (hmax - hmin) * 0.72, "flyer": info.get("flyer", false), "gait": info.get("gait", ""), "plantdir": good / maxf(1e-6, tot), "perfoot": perfoot}
		print("%-12s %-7s flyer=%-5s stride %.2f cycle %.2f plant %.2f move %.2f ratio %.2f h %.2f dir %+.2f" % [sp, res[sp].gait, res[sp].flyer, res[sp].stride, L, plant, move, res[sp].ratio, res[sp].height, res[sp].plantdir])
		model.free()
	var f = FileAccess.open("res://tools/gait_report.json", FileAccess.WRITE); f.store_string(JSON.stringify(res)); f.close()
	quit()

func _rel(model: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY; var p = n
	while p != null and p != model:
		if p is Node3D: t = p.transform * t
		p = p.get_parent()
	return t
