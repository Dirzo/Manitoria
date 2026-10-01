extends SceneTree
## Item strength probe: mirrored teams; team A's champion in slot 0 carries the test item,
## team B's carries a plain component pair's stat equivalent (two components). Reports A's win rate.
func _init():
	HeroData.load_data()
	var N = int(OS.get_environment("N")) if OS.get_environment("N") != "" else 30
	var sps = HeroData.species.keys()
	var rng = RandomNumberGenerator.new(); rng.seed = 5
	var rows = []
	var only = OS.get_environment("ONLY")
	for id in Forge.ITEMS:
		if only != "" and id != only: continue
		var wins = 0.0; var dur = 0.0
		for n in range(N):
			var team = []
			for i in range(5): team.append(sps[rng.randi_range(0, sps.size() - 1)])
			var a = []; var b = []
			for i in range(5):
				var ha = HeroData.make_hero(team[i], "a%d_%d" % [n, i], "A", 7); ha.slot = Campaign.FORMATION[i]
				var hb = HeroData.make_hero(team[i], "b%d_%d" % [n, i], "B", 7); hb.slot = Campaign.FORMATION[i]
				hb.trait = Traits.trait_of(ha); ha.trait = hb.trait
				a.append(ha); b.append(hb)
			var carrier = rng.randi_range(0, 4)
			a[carrier].equipment = {"0": id}
			var r = Forge.ITEMS[id].recipe
			b[carrier].equipment = {"0": r[0], "1": r[1]}
			var sim = BattleSim.new(); sim.silent = true
			if n % 2 == 0: sim.setup(a, b, 1000 + n)
			else: sim.setup(b, a, 1000 + n)
			var steps = 0
			while not sim.finished and steps < 60 * 160: sim.step(1.0 / 30.0); steps += 2
			var a_side = 0 if n % 2 == 0 else 1
			if sim.winner == a_side: wins += 1.0
			elif sim.winner == -1: wins += 0.5
			dur += sim.time
		rows.append([id, wins / N, dur / N])
	rows.sort_custom(func(x, y): return x[1] > y[1])
	for r in rows: print("ITEM %-14s win %.2f  dur %.0f" % [r[0], r[1], r[2]])
	quit()
