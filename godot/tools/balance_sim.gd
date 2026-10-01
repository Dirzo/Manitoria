extends SceneTree
## Sim-only batch analysis of combat pacing. env: N (battles), SEED, OUT (json path)
var casts := []        # per battle list of [time, team, uid, credit, rarity]
var dmg := {}          # credit-class -> damage
func _init() -> void:
	HeroData.load_data()
	var N = int(OS.get_environment("N")) if OS.get_environment("N") != "" else 200
	var rng := RandomNumberGenerator.new(); rng.seed = int(OS.get_environment("SEED")) if OS.get_environment("SEED") != "" else 7
	var sps = HeroData.species.keys()
	var R = {"dur": [], "first_death": [], "casts_per_unit_min": [], "overlap": [], "burst_max": [], "open5": [], "leg_casts": 0, "leg_dmg": 0.0, "rare_dmg": 0.0, "unc_dmg": 0.0, "basic_dmg": 0.0, "item_dmg": 0.0, "dot_dmg": 0.0, "sig_dmg": 0.0, "abil_dmg": 0.0, "leg_share": [], "dps": [], "team_overlap": [], "draws": 0, "left_wins": 0, "role_casts": {}, "role_time": {}}
	for b in range(N):
		var teams = []
		for side in range(2):
			var t = []
			for i in range(5):
				var sp = sps[rng.randi_range(0, sps.size() - 1)]
				if OS.get_environment("MIRROR") == "1" and side == 1: sp = teams[0][i].sp
				var lvl = rng.randi_range(4, 10)
				var h = HeroData.make_hero(sp, "%s%d%d" % [sp, side, i], sp, lvl)
				h.slot = Campaign.FORMATION[i]
				if OS.get_environment("LURK") == "1" and HeroData.species[sp].role in HeroData.FLANK: h.tactics = BattleTactics.PRESETS.Assassin
				if OS.get_environment("LURK_SIDE") == str(side) and HeroData.species[sp].role in HeroData.FLANK: h.tactics = BattleTactics.PRESETS.Assassin
				var nlearn = clampi(1 + lvl / 3, 1, 3)
				var keys = range(12); keys.shuffle()
				for k in keys.slice(0, nlearn):
					h.learned[str(k)] = 1 + (1 if rng.randf() < 0.3 else 0)
					var roll = rng.randf()
					if roll < 0.08: h.skill_rarity = h.get("skill_rarity", {}); h.skill_rarity[str(k)] = "Legendary"; h["ability_bonus_" + str(k)] = 1.25
					elif roll < 0.3: h.skill_rarity = h.get("skill_rarity", {}); h.skill_rarity[str(k)] = "Rare"; h["ability_bonus_" + str(k)] = 1.1
				t.append(h)
			teams.append(t)
		var sim = BattleSim.new()
		var cl = []
		var acc = {"leg": 0.0, "total": 0.0}
		sim.action.connect(func(e):
			if e.type == "cast":
				var u = sim.find_unit(int(e.uid))
				if not u.is_empty() and not u.summon:
					cl.append([sim.time, u.team, u.uid, e.get("credit", ""), e.get("rarity", "")])
					var role = HeroData.species[u.hero.sp].role
					R.role_casts[role] = R.role_casts.get(role, 0) + 1
			elif e.type == "hit":
				var c = str(e.get("credit", "basic"))
				var r = str(e.get("rarity", ""))
				acc.total += e.amount
				if c == "basic": R.basic_dmg += e.amount
				elif c.begins_with("item:"): R.item_dmg += e.amount
				elif c == "signature": R.sig_dmg += e.amount
				elif c.begins_with("ability:"):
					R.abil_dmg += e.amount
					if r == "Legendary": R.leg_dmg += e.amount; acc.leg += e.amount
					elif r == "Rare": R.rare_dmg += e.amount
					else: R.unc_dmg += e.amount
				else: R.dot_dmg += e.amount
		)
		sim.silent = false
		sim.setup(teams[0], teams[1], 1000 + b, 1.0)
		var first_death = -1.0
		while not sim.finished:
			sim.step(1.0 / 30.0)
			if first_death < 0 and sim.units.any(func(u): return not u.alive and not u.summon): first_death = sim.time
		for u in sim.units:
			if u.summon: continue
			var role = HeroData.species[u.hero.sp].role
			R.role_time[role] = R.role_time.get(role, 0.0) + sim.time
		R.dur.append(sim.time); R.first_death.append(first_death)
		if sim.winner == -1: R.draws += 1
		if sim.winner == 0: R.left_wins += 1
		R.casts_per_unit_min.append(cl.size() / 10.0 / (sim.time / 60.0))
		# overlap: casts that start within 0.5 s of another cast
		var ov = 0
		for i in range(cl.size()):
			for j in range(cl.size()):
				if i != j and absf(cl[i][0] - cl[j][0]) < 0.5: ov += 1; break
		R.overlap.append(float(ov) / maxf(1, cl.size()))
		var tov = 0
		for i in range(cl.size()):
			for j in range(cl.size()):
				if i != j and cl[i][1] == cl[j][1] and absf(cl[i][0] - cl[j][0]) < 0.5: tov += 1; break
		R.team_overlap.append(float(tov) / maxf(1, cl.size()))
		var mx = 0
		for c in cl:
			var n = cl.filter(func(o): return o[0] >= c[0] and o[0] < c[0] + 1.0).size()
			mx = maxi(mx, n)
		R.burst_max.append(mx)
		R.open5.append(cl.filter(func(o): return o[0] < 6.0).size())
		R.leg_casts += cl.filter(func(o): return o[4] == "Legendary").size()
		R.leg_share.append(acc.leg / maxf(1, acc.total))
		R.dps.append(acc.total / sim.time / 10.0)
	var out = {}
	for k in ["team_overlap", "dur", "first_death", "casts_per_unit_min", "overlap", "burst_max", "open5", "dps", "leg_share"]:
		var a: Array = R[k]; a.sort()
		out[k] = {"mean": a.reduce(func(s, x): return s + x, 0.0) / a.size(), "p10": a[a.size() / 10], "p50": a[a.size() / 2], "p90": a[a.size() * 9 / 10]}
	var tot = R.basic_dmg + R.item_dmg + R.sig_dmg + R.abil_dmg + R.dot_dmg
	out["share"] = {"basic": R.basic_dmg / tot, "signature": R.sig_dmg / tot, "abilities": R.abil_dmg / tot, "items": R.item_dmg / tot, "other": R.dot_dmg / tot}
	out["per_cast_dmg_index"] = {"legendary": R.leg_dmg / maxf(1, R.leg_casts)}
	out["draws"] = R.draws; out["left_wins"] = R.left_wins; out["N"] = N
	var rc = {}
	for role in R.role_casts: rc[role] = snappedf(R.role_casts[role] / maxf(1, R.role_time.get(role, 1.0)) * 60.0, 0.01)
	out["casts_per_min_by_role"] = rc
	var f = FileAccess.open(OS.get_environment("OUT"), FileAccess.WRITE); f.store_string(JSON.stringify(out, "  ")); f.close()
	quit()
