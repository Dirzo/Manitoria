extends SceneTree
## v0.77 item sweep. Mirrored 5v5s at a level: team A's carrier holds the test item, team B's the
## same item's two components (its stats without the effect). Reports A's win rate, how often the
## item triggered, the biggest Size and crit seen, and flags any item that never triggers.
## Env: N (fights per item, default 24), LEVEL (default 10), LEG=1 tests Legendaries, ONLY=<id>.

func _init() -> void:
	HeroData.load_data(); HeroData.run_salt = "items"
	var n = int(OS.get_environment("N")) if OS.get_environment("N") != "" else 24
	var level = int(OS.get_environment("LEVEL")) if OS.get_environment("LEVEL") != "" else 10
	var legend = OS.get_environment("LEG") == "1"
	var only = OS.get_environment("ONLY")
	var sps: Array = HeroData.species.keys()
	var rows = []; var silent = []
	var shard = int(OS.get_environment("SHARD")) if OS.get_environment("SHARD") != "" else -1
	var shards = int(OS.get_environment("SHARDS")) if OS.get_environment("SHARDS") != "" else 1
	var index = -1
	for id in Forge.ITEMS:
		index += 1
		if only != "" and id != only: continue
		if shard >= 0 and index % shards != shard: continue
		var test_id = (Forge.LEGEND + id) if legend else id
		var wins = 0.0; var procs = 0.0; var max_size = 0.0; var max_crit = 0.0; var rng = RandomNumberGenerator.new(); rng.seed = hash(id) + level
		for f in range(n):
			var a = []; var b = []
			for i in range(5):
				var sp = sps[rng.randi_range(0, sps.size() - 1)]
				var ha = HeroData.make_hero(sp, "a%d_%d" % [f, i], "A", level); ha.slot = Campaign.FORMATION[i]
				var hb = HeroData.make_hero(sp, "b%d_%d" % [f, i], "B", level); hb.slot = Campaign.FORMATION[i]
				hb.trait = Traits.trait_of(ha); hb.rolls = HeroData.rolls(ha)
				if level >= HeroData.EVOLVE_LEVEL: ha.evolution = "%s:%d" % [sp, f % 3]; hb.evolution = ha.evolution
				HeroData.auto_cards(ha, ha.id); hb.cards = ha.cards.duplicate()
				a.append(ha); b.append(hb)
			var carrier = rng.randi_range(0, 4)
			a[carrier].equipment = {"0": test_id}
			var r = Forge.ITEMS[id].recipe
			b[carrier].equipment = {"0": r[0], "1": r[1]}
			var sim = BattleSim.new(); sim.silent = true
			var a_side = f % 2
			if a_side == 0: sim.setup(a, b, 1000 + f)
			else: sim.setup(b, a, 1000 + f)
			sim.run_to_end()
			if sim.winner == a_side: wins += 1.0
			elif sim.winner == -1: wins += 0.5
			for u in sim.units:
				if u.summon or u.team != a_side or not (test_id in Forge.carried(u.hero)): continue
				procs += float(u.ability_stats.get("item:" + id, {}).get("casts", 0.0))
				max_size = maxf(max_size, float(u.size)); max_crit = maxf(max_crit, float(u.get("biggest_crit", 0.0)))
		rows.append([test_id, wins / n, procs / n, max_size, max_crit])
		if procs == 0 and not (id in ["titanheart", "draught", "tempestcrown", "archmage", "colossus", "spurs", "giant", "glasstitan", "gambler", "dragonedge", "granite", "wildfire"]): silent.append(test_id)
	rows.sort_custom(func(x, y): return x[1] > y[1])
	for r in rows: print("ITEM %-18s win %3d%%  procs/fight %5.1f  max size %.2f  biggest crit %d" % [r[0], roundi(r[1] * 100), r[2], r[3], roundi(r[4])])
	print("NEVER TRIGGERED: ", silent)
	quit()
