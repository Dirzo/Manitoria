extends SceneTree
## v0.76 smoke test: every species and every evolution casts its signature in real fights.
## Prints casts per fight and signature damage/healing share, and flags any species that never cast.

func _init() -> void:
	HeroData.load_data()
	HeroData.run_salt = "smoke"
	var sps: Array = HeroData.species.keys()
	var rng = RandomNumberGenerator.new(); rng.seed = 76
	var bad = []
	for sp in sps:
		for e in range(-1, 3):
			var casts = 0.0; var sig = 0.0; var total = 0.0; var fights = 3
			for f in range(fights):
				var left = []; var right = []
				for i in range(5):
					var h = HeroData.make_hero(sp if i == 0 else sps[rng.randi_range(0, sps.size() - 1)], "L%d_%d_%s" % [i, f, sp], "L", 10)
					if i == 0 and e >= 0: h.evolution = "%s:%d" % [sp, e]
					h.slot = i; left.append(h)
					var r = HeroData.make_hero(sps[rng.randi_range(0, sps.size() - 1)], "R%d_%d_%s" % [i, f, sp], "R", 10)
					r.slot = i; right.append(r)
				var sim = BattleSim.new()
				sim.setup(left, right, rng.randi())
				sim.run_to_end()
				for u in sim.units:
					if u.team == 0 and not u.summon and u.hero.sp == sp and u.hero.id.begins_with("L0"):
						casts += float(u.ability_stats.get("signature", {}).get("casts", 0.0))
						sig += float(u.ability_stats.get("signature", {}).get("damage", 0.0)) + float(u.ability_stats.get("signature", {}).get("healing", 0.0))
						total += u.damage + u.healing
			print("%-12s evo %2d  casts/fight %.1f  signature share %3d%%" % [sp, e, casts / fights, roundi(100.0 * sig / maxf(1.0, total))])
			if casts == 0: bad.append("%s:%d" % [sp, e])
	print("NO CASTS: ", bad)
	quit()
