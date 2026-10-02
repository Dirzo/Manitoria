extends SceneTree
## Controlled experiments. env MODE=items|scaling, N=fights per cell, OUT=json path
## items:   mirror matches (same five on both sides, same level); one side's random champion carries
##          the item. Win rate of the item side = how much the item is worth.
## scaling: random 5v5 matches at fixed levels; per-species wins and damage share, grouped by
##          scaling type (early / steady / late).
const NEUTRAL = {"hp": 15, "attack": 15, "armor": 15, "haste": 15, "speed": 15, "potency": 15}

func team(rng: RandomNumberGenerator, level: int, tag: String) -> Array:
	var all = HeroData.species.keys(); var out = []
	for i in range(5):
		var sp = all[rng.randi_range(0, all.size() - 1)]
		var h = HeroData.make_hero(sp, "%s_%d" % [tag, i], "%s%d" % [tag, i], level)
		h.trait = "Steadfast"; h.rolls = NEUTRAL.duplicate(); h.slot = Campaign.FORMATION[i]
		out.append(h)
	return out

func fight(a: Array, b: Array, seed: int) -> BattleSim:
	var sim = BattleSim.new(); sim.silent = true
	sim.setup(a, b, seed, 1.0); sim.run_to_end(); return sim

func _init() -> void:
	HeroData.load_data()
	var n = int(OS.get_environment("N")); var mode = OS.get_environment("MODE"); var result = {}
	var rng = RandomNumberGenerator.new(); rng.seed = 99
	if mode == "items":
		var ids = Forge.COMPONENT_ORDER + Forge.ITEMS.keys()
		if OS.get_environment("IDS") != "": ids = Array(OS.get_environment("IDS").split(","))
		for id in ids:
			var wins = 0.0; var games = 0
			for k in range(n):
				var base = team(rng, 7, "t")
				var with_item = base.duplicate(true); var without = base.duplicate(true)
				for h in without: h.id += "_b"
				with_item[rng.randi_range(0, 4)].equipment = {"0": id}
				# Alternate sides to cancel any side advantage.
				var sim = fight(with_item, without, 1000 + k) if k % 2 == 0 else fight(without, with_item, 1000 + k)
				var item_team = 0 if k % 2 == 0 else 1
				games += 1; wins += 1.0 if sim.winner == item_team else (0.5 if sim.winner == -1 else 0.0)
			result[id] = {"winrate": wins / games, "name": Forge.info(id).name, "wild": Forge.ITEMS.get(id, {}).get("wild", false), "component": Forge.is_component(id)}
			print("%s %.2f" % [id, wins / games])
	else:
		var lvls = [1, 4, 7, 10, 14, 20]
		if OS.get_environment("LEVELS") != "": lvls = Array(OS.get_environment("LEVELS").split(",")).map(func(x): return int(x))
		for lv in lvls:
			var per = {}
			for k in range(n):
				var a = team(rng, lv, "a"); var b = team(rng, lv, "b")
				var sim = fight(a, b, 5000 + lv * 1000 + k)
				var rows = sim.report_rows()
				var tot = [0.0, 0.0]
				for r in rows: tot[r.team] += r.damage
				for r in rows:
					var s = per.get(r.sp, {"games": 0, "wins": 0.0, "share": 0.0, "damage": 0.0})
					s.games += 1; s.wins += 1.0 if sim.winner == r.team else (0.5 if sim.winner == -1 else 0.0)
					s.share += r.damage / maxf(1.0, tot[r.team]); s.damage += r.damage
					per[r.sp] = s
			result[str(lv)] = per
			print("level %d done" % lv)
	FileAccess.open(OS.get_environment("OUT"), FileAccess.WRITE).store_string(JSON.stringify(result))
	quit()
