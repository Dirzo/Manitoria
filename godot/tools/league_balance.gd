extends SceneTree
## MODE=elite : elite four (L+2E+1C) vs full five (L+1E+3C), sides alternated.
## MODE=species: random legal clubs vs each other; per-species win rate.  env N, LEVEL, OUT
func _init() -> void:
	HeroData.load_data()
	var N = int(OS.get_environment("N")) if OS.get_environment("N") != "" else 100
	var lvl = int(OS.get_environment("LEVEL")) if OS.get_environment("LEVEL") != "" else 6
	var mode = OS.get_environment("MODE")
	var rng := RandomNumberGenerator.new(); rng.seed = int(OS.get_environment("SEED")) if OS.get_environment("SEED") != "" else 3
	var res = {"elite_wins": 0, "full_wins": 0, "draws": 0, "dur": 0.0}
	var sp_w = {}; var sp_n = {}
	for b in range(N):
		var legs = League.TIERS.Legendary.duplicate(); legs.shuffle()
		var teams = []
		for side in range(2):
			var cl: Dictionary
			var want_elite = (b % 2 == side) if mode == "elite" else rng.randf() < 0.4
			for attempt in range(30):
				cl = League.draft_club("T%d" % side, legs[side], rng, "b%d_%d" % [b, side])
				if cl.elite == want_elite: break
			for h in cl.roster:
				h.level = lvl
				var keys = range(12); keys.shuffle()
				for k in keys.slice(0, clampi(lvl / 3, 1, 3)): h.learned[str(k)] = 1
				h.signature_rank = 2 if lvl >= 5 else 1
			teams.append(cl)
		var sim = BattleSim.new(); sim.silent = true
		sim.setup(teams[0].roster, teams[1].roster, 5000 + b, 1.0); sim.run_to_end()
		res.dur += sim.time
		if sim.winner < 0: res.draws += 1
		for side in range(2):
			var won = sim.winner == side
			if mode == "elite" and won: res["elite_wins" if teams[side].elite else "full_wins"] += 1
			for h in teams[side].roster:
				sp_n[h.sp] = sp_n.get(h.sp, 0) + 1; sp_w[h.sp] = sp_w.get(h.sp, 0) + (1 if won else 0)
	res.dur /= N
	var rates = {}
	for sp in sp_n: rates[sp] = [snappedf(float(sp_w[sp]) / sp_n[sp], 0.01), sp_n[sp]]
	res.species = rates
	var f = FileAccess.open(OS.get_environment("OUT"), FileAccess.WRITE); f.store_string(JSON.stringify(res, "  ")); f.close()
	quit()
