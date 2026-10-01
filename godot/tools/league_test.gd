extends SceneTree
## Plays whole cups headlessly through the real campaign flow and prints the bracket path.
func _init() -> void:
	HeroData.load_data()
	var c = Campaign.new(); c.new_run("Test Club", 96, 1234, "Standard")
	print("gold ", c.state.gold, " market ", c.state.market.size())
	print("starter ok: ", c.choose_starter("jackalope"), " gold ", c.state.gold, " clubs ", c.state.clubs.size())
	for cl in c.state.clubs: print("  ", cl.name, " ", cl.roster.map(func(h): return "%s(%s)" % [h.sp, League.tier(h.sp)[0]]), " elite=", cl.elite, " ovr ", League.team_ovr(cl.roster))
	var buys = ["kirin", "golem", "naga"] if OS.get_environment("ELITE") != "1" else ["kirin", "golem", "naga"]
	for sp in (["golem", "kirin", "naga"] if OS.get_environment("ELITE") == "1" else ["golem", "troll", "harpy", "naga"]):
		for h in c.state.market:
			if h.sp == sp: print("draft ", sp, " ", c.recruit(h.id), " gold ", c.state.gold); break
	print("lineup ", c.lineup().size(), " ready ", c.lineup_ready())
	for cup in range(int(OS.get_environment("CUPS") if OS.get_environment("CUPS") != "" else "2")):
		var guard = 0
		while guard < 10:
			guard += 1
			var opp = c.opponent()
			var label = WorldTour.stage_label(c)
			var sim = BattleSim.new(); sim.silent = true
			sim.setup(c.lineup(), opp.roster, c.match_seed(), c.quality()); sim.run_to_end()
			var ok = c.resolve(sim)
			print("  cup %d %-22s vs %-16s %s  resolved=%s  record %d-%d" % [c.state.tour.level, label, opp.name, "WIN" if sim.winner == 0 else "LOSS", ok, c.state.tour.get("wins", 0), WorldTour.losses(c, 0) if c.state.tour.has("bracket") else -1])
			var finished = c.state.tour.bracket.finished
			if finished:
				print("  -> champion ", WorldTour.team_name(c, int(c.state.tour.bracket.champion)), " place ", c.state.report.get("place", "?"), " gold ", c.state.gold)
			while not c.pending_heroes().is_empty():
				var h = c.pending_heroes()[0]; c.choose(h.id, 0)
			WorldTour.leave_shop(c)
			if finished: break
	print("moves: ", c.state.get("rating_moves", []).slice(0, 4))
	var top = League.all_heroes(c); top.sort_custom(func(a, b): return League.ovr(a) > League.ovr(b))
	for h in top.slice(0, 6): print("  ", League.ovr(h), " ", h.sp, " lvl ", h.level, " ", League.ratings(h), " form ", League.form(h))
	quit()
