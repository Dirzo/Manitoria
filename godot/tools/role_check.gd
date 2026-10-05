extends SceneTree
## Random 5v5 battles at one level: win rate by line (Front/Flank/Back) and by role. env N, LVL
func _init() -> void:
	HeroData.load_data()
	var N = int(OS.get_environment("N")) if OS.get_environment("N") != "" else 300
	var lvl = int(OS.get_environment("LVL")) if OS.get_environment("LVL") != "" else 8
	var rng := RandomNumberGenerator.new(); rng.seed = 11
	var sps = HeroData.species.keys()
	var by_line = {}; var by_role = {}; var dmg_line = {}; var dur = 0.0
	for b in range(N):
		var teams = []
		for side in range(2):
			var t = []
			for i in range(5):
				var sp = sps[rng.randi_range(0, sps.size() - 1)]
				var h = HeroData.make_hero(sp, "%s%d%d%d" % [sp, side, i, b], sp, lvl)
				for k in range(3): h.learned[str(k)] = 1
				t.append(h)
			var used = {}
			for h in t:
				var col = {"Front": 2, "Flank": 1, "Back": 0}[HeroData.line(h.sp)]
				var row = 0
				while used.has(row * 3 + col): row += 1
				if row > 4:
					row = 0; col = 1
					while used.has(row * 3 + col): row += 1
				h.slot = row * 3 + col; used[h.slot] = true
			teams.append(t)
		var sim = BattleSim.new(); sim.silent = true
		sim.setup(teams[0], teams[1], 1000 + b, 1.0); sim.run_to_end(); dur += sim.time
		for u in sim.units:
			if u.summon: continue
			var line = HeroData.line(u.hero.sp); var role = HeroData.species[u.hero.sp].role
			var w = 1.0 if sim.winner == u.team else (0.5 if sim.winner < 0 else 0.0)
			for pair in [[by_line, line], [by_role, role]]:
				var d = pair[0]; var k = pair[1]
				if not d.has(k): d[k] = [0.0, 0]
				d[k][0] += w; d[k][1] += 1
			dmg_line[line] = dmg_line.get(line, 0.0) + u.damage
	print("ROLECHECK lvl=%d n=%d avg duration %.1fs" % [lvl, N, dur / N])
	for k in by_line: print("  line %-6s win %.3f  (%d)  dmg/unit %.0f" % [k, by_line[k][0] / by_line[k][1], by_line[k][1], dmg_line[k] / by_line[k][1]])
	var roles = by_role.keys(); roles.sort_custom(func(a, b): return by_role[a][0] / by_role[a][1] > by_role[b][0] / by_role[b][1])
	for k in roles: print("  role %-11s win %.3f (%d)" % [k, by_role[k][0] / by_role[k][1], by_role[k][1]])
	quit()
