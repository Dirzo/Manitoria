extends SceneTree
## v0.77 item rules: every retired id converts, every recipe forges, the Anvil works and
## Size/Crit flow from items into stats.
func _init() -> void:
	HeroData.load_data(); HeroData.run_salt = "itemtest"
	var fails = []
	var check = func(ok: bool, what: String): if not ok: fails.append(what)
	var old_ids = ["fang","hide","plate","feather","ember","moon","seed","storm","silk","venom","relic","coin","bloodmaw","titan","tusk","frenzy","spellblade","executioner","thornlash","berserker","colossus","bastion","drum","phoenixember","bell","lifebloom","giant","mirror","spikes","runeward","stoneskin","ironbark","turtle","tempest","quiver","quicksilver","hunter","sugarrush","archmage","crown","scepter","chaos","hourglass","spiritbell","puppet","worldtree","swap","thundercleaver","stormmantle","lightningrod","galetalons","stormorb","overcharge","rainbringer","bottle","tempestcrown","flicker","galvanic","judgement","shadowblade","phantomcloak","smokeplate","windwalker","illusion","eclipse","wispshroud","doppel","nightshroud","assassinkit","wardshroud","viperfang","leechhide","acidshell","needles","plaguetome","witherbloom","grievous","bloodfeast","hydravenom","antidote","crusader","martyr","aegis","pilgrim","halo","rosary","chalice","divine","grail","idol"]
	for id in old_ids: check.call(Forge.valid(Forge.migrate_id(id)), "old id converts: " + id)
	var pairs = {}
	for a in Forge.COMPONENT_ORDER:
		for b in Forge.COMPONENT_ORDER:
			var made = Forge.combine(a, b)
			check.call(Forge.ITEMS.has(made), "recipe %s+%s" % [a, b])
			pairs[made] = true
	check.call(pairs.size() == Forge.ITEMS.size(), "every item has a recipe (%d of %d)" % [pairs.size(), Forge.ITEMS.size()])
	for id in Forge.ITEMS:
		var info = Forge.info(Forge.LEGEND + id)
		check.call(info.get("legendary", false) and not str(info.name).is_empty() and str(info.name) != str(Forge.ITEMS[id].name), "legendary info " + id)
	var h = HeroData.make_hero("minotaur", "t1", "T", 10)
	var base = HeroData.stats(h)
	h.equipment = {"0": "titanheart"}
	var big = HeroData.stats(h)
	check.call(big.size > base.size + 0.25 and big.hp > base.hp * 1.25, "Titan's Heart grows Size and HP")
	h.equipment = {"0": "tempestcrown"}
	var crit = HeroData.stats(h)
	check.call(crit.crit >= base.crit + 0.29 and crit.crit_damage >= 2.49, "Tempest Crown crit")
	var rng = RandomNumberGenerator.new(); rng.seed = 3
	h.equipment = {"0": "club", "1": "frenzy"}
	check.call(Forge.anvil(h, "0", rng) == "legendary" and h.equipment["0"] == Forge.LEGEND + "club", "anvil makes a Legendary")
	check.call(Forge.anvil(h, "1", rng) == "", "only one Legendary per champion")
	var destroyed = 0; var made_leg = 0
	for i in range(200):
		var w = {"equipment": {"0": "spurs"}}
		var r = Forge.anvil(w, "0", rng)
		if r == "destroyed": destroyed += 1
		elif r == "legendary": made_leg += 1
	check.call(destroyed > 70 and made_leg > 70, "wild anvil is about 50/50 (%d / %d)" % [made_leg, destroyed])
	var hh = HeroData.make_hero("golem", "t2", "T", 1); var hs = HeroData.make_hero("nekomata", "t3", "T", 1)
	check.call(HeroData.stats(hh).size > HeroData.stats(hs).size and HeroData.stats(hs).crit > HeroData.stats(hh).crit, "tanks big, assassins crit")
	for f in fails: print("FAIL ", f)
	print("item rules: %d failures" % fails.size())
	quit()
