extends SceneTree
## Many short campaigns: player's match win rate and placements over the first cups. env RUNS CUPS DIFF
func _init() -> void:
	HeroData.load_data()
	var runs = int(OS.get_environment("RUNS")); var cups = int(OS.get_environment("CUPS"))
	var wins = 0; var games = 0; var places = {}; var champs = 0; var dead = 0; var reached = 0
	for r in range(runs):
		var c = Campaign.new(); c.new_run("Sweep", 95, 5000 + r * 77, OS.get_environment("DIFF"))
		# Classic tiers keep sweeps comparable across versions.
		League.run_tiers = {}; c.state.tiers = {}; c.create_market()
		var legs = League.TIERS.Legendary; c.choose_starter(legs[r % legs.size()])
		var plan = [["golem", "kirin", "naga"], ["troll", "griffin", "harpy", "pegasus"], ["nemean", "yeti", "wyvern", "naga"], ["minotaur", "treant", "cyclops"]][r % 4]
		for sp in plan:
			for h in c.state.market:
				if h.sp == sp: c.recruit(h.id); break
		var survived = 0
		for cup in range(cups):
			if c.state.get("run_over", false): break
			for guard in range(10):
				var opp = c.opponent()
				var sim = BattleSim.new(); sim.silent = true
				sim.setup(c.lineup(), opp.roster, c.match_seed(), c.quality()); sim.run_to_end()
				games += 1; wins += int(sim.winner == 0)
				c.resolve(sim)
				var fin = c.state.tour.bracket.finished
				if fin:
					var p = int(c.state.report.get("place", 0)); places[p] = places.get(p, 0) + 1
					if p == 1: champs += 1
				while not c.pending_heroes().is_empty(): c.choose(c.pending_heroes()[0].id, 0)
				if OS.get_environment("SHOP") == "1" and c.state.tour.shop:
					for i in range(c.state.tour.stock.size()):
						var id = str(c.state.tour.stock[i])
						if id == "" or c.state.gold < Forge.info(id).price + 60: continue
						for h in c.lineup():
							if GearUI.fits(h, id) and c.buy_and_equip(i, h.id): break
				WorldTour.leave_shop(c)
				if fin: break
		dead += int(c.state.get("run_over", false)); reached += int(c.state.tour.level)
	print("RUNS ended=%d/%d avg cup reached=%.1f" % [dead, runs, float(reached) / runs])
	print("SWEEP diff=%s runs=%d cups=%d match winrate=%.2f (%d games) places=%s champs=%d" % [OS.get_environment("DIFF"), runs, cups, float(wins) / games, games, places, champs])
	quit()
