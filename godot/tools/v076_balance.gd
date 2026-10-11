extends SceneTree
## v0.76 balance sweep: random mirrored-level 5v5 fights at levels 1, 10 and 20.
## Reports fight length, casts per champion, signature share of damage, AD vs AP signature share,
## and per-species win rate (a species' team wins / fights it appeared in).
## Env: N (fights per level, default 200), LEVELS ("1,10,20").

func team(rng: RandomNumberGenerator, sps: Array, level: int, tag: String) -> Array:
	var out = []
	for i in range(5):
		var sp = sps[rng.randi_range(0, sps.size() - 1)]
		var h = HeroData.make_hero(sp, "%s%d_%d" % [tag, i, rng.randi()], tag, level)
		if level >= HeroData.EVOLVE_LEVEL: h.evolution = "%s:%d" % [sp, rng.randi_range(0, 2)]
		HeroData.auto_cards(h, h.id)
		h.slot = Campaign.FORMATION[i]
		out.append(h)
	return out

func _init() -> void:
	HeroData.load_data(); HeroData.run_salt = "v076"
	var n = int(OS.get_environment("N")) if OS.get_environment("N") != "" else 200
	var levels = (OS.get_environment("LEVELS") if OS.get_environment("LEVELS") != "" else "1,10,20").split(",")
	var sps: Array = HeroData.species.keys()
	var rng = RandomNumberGenerator.new(); rng.seed = 7676
	var wins = {}; var games = {}
	for lv_text in levels:
		var lv = int(lv_text)
		var dur = 0.0; var casts = 0.0; var units = 0.0; var sig = 0.0; var dmg = 0.0; var first = 0.0; var firsts = 0.0
		var by_path = {"ad": [0.0, 0.0], "ap": [0.0, 0.0]}
		for f in range(n):
			var a = team(rng, sps, lv, "A"); var b = team(rng, sps, lv, "B")
			var sim = BattleSim.new(); sim.silent = true
			sim.setup(a, b, rng.randi())
			var first_cast = {}
			while not sim.finished:
				sim.step(1.0 / 30.0)
				for u in sim.units:
					if not u.summon and not first_cast.has(u.uid) and float(u.ability_stats.get("signature", {}).get("casts", 0.0)) > 0: first_cast[u.uid] = sim.time
			dur += sim.time
			for t in first_cast.values(): first += t; firsts += 1
			for u in sim.units:
				if u.summon: continue
				units += 1
				var st = u.ability_stats.get("signature", {})
				casts += float(st.get("casts", 0.0))
				sig += float(st.get("damage", 0.0)); dmg += u.damage
				var path = "ad" if Signatures.primary(u.hero.sp) in ["ad", "as"] else "ap"
				by_path[path][0] += u.damage; by_path[path][1] += 1
				var key = "%s@%d" % [u.hero.sp, lv]
				games[key] = games.get(key, 0) + 1
				if sim.winner == u.team: wins[key] = wins.get(key, 0.0) + 1.0
				elif sim.winner == -1: wins[key] = wins.get(key, 0.0) + 0.5
		print("LEVEL %2d  fight %.1fs  first cast %.1fs  casts/champ %.2f  signature share %d%%  dmg per AD champ %d  per AP champ %d" % [lv, dur / n, first / maxf(1, firsts), casts / units, roundi(100 * sig / maxf(1, dmg)), roundi(by_path.ad[0] / maxf(1, by_path.ad[1])), roundi(by_path.ap[0] / maxf(1, by_path.ap[1]))])
	var rows = []
	for sp in sps:
		var line = "%-12s" % sp; var total = 0.0
		for lv_text in levels:
			var key = "%s@%d" % [sp, int(lv_text)]
			var wr = wins.get(key, 0.0) / maxf(1, games.get(key, 0))
			line += "  L%s %3d%% (%d)" % [lv_text, roundi(wr * 100), games.get(key, 0)]
			total += wr
		rows.append([total / levels.size(), line])
	rows.sort_custom(func(x, y): return x[0] > y[0])
	for r in rows: print("WR ", r[1])
	quit()
