extends SceneTree
func _init() -> void:
	HeroData.load_data()
	var n = 0; var counts = {}
	for sp in HeroData.species:
		var h = HeroData.make_hero(sp, "e_" + sp, "x", 10)
		var rng = RandomNumberGenerator.new(); rng.seed = 5
		var cards = HeroData.choices(h, true, rng, 10)
		counts[sp] = cards.size()
		assert(cards.size() == 3 and cards[0].type == "evolution")
	print("evolution choices per species: ", counts.values().min(), "-", counts.values().max())
	# Fight every evolution once: an evolved champion plus four allies vs an unevolved copy.
	var wins = 0.0; var games = 0; var by = {}
	var sps = HeroData.species.keys()
	for sp in sps:
		for i in range(3):
			var key = "%s:%d" % [sp, i]
			var a = []; var b = []
			for j in range(5):
				var s2 = sp if j == 0 else sps[(sps.find(sp) + j * 7) % sps.size()]
				var ha = HeroData.make_hero(s2, "a%d%s%d" % [j, sp, i], "a", 10); ha.slot = Campaign.FORMATION[j]
				var hb = ha.duplicate(true); hb.id = ha.id + "b"
				if j == 0: ha.evolution = key
				a.append(ha); b.append(hb)
			for side in [0, 1]:
				var sim = BattleSim.new(); sim.silent = true
				if side == 0: sim.setup(a, b, 77 + i)
				else: sim.setup(b, a, 77 + i)
				sim.run_to_end()
				var w = (1.0 if sim.winner == side else 0.5 if sim.winner == -1 else 0.0)
				wins += w; games += 1; by[key] = by.get(key, 0.0) + w * 0.5
	print("evolved side win rate over %d fights: %.2f" % [games, wins / games])
	var keys = by.keys(); keys.sort_custom(func(x, y): return by[x] < by[y])
	print("weakest: ", keys.slice(0, 6).map(func(k): return "%s %.1f" % [Evolutions.entry(k).name, by[k]]))
	quit()
