extends SceneTree
## v0.79 permadeath rules: who dies, grace wounds, items to the bag, legacy XP, the crown passing,
## the Ferryman's revival, wound penalties and healing, and old saves keeping guild lives.
func _init() -> void:
	HeroData.load_data()
	var fails = []
	var check = func(ok: bool, what: String): if not ok: fails.append(what)
	var c = Campaign.new(); c.new_run("Perma", 91, 4242, "Standard"); Dungeon.start(c)
	c.state.roster = []
	for i in range(6):
		var h = HeroData.make_hero(["golem", "minotaur", "harpy", "unicorn", "phoenix", "troll"][i], "pd%d" % i, "Pd %d" % i, 8)
		h.slot = Dungeon.SLOTS[i] if i < 5 else -1
		c.state.roster.append(h)
	c.state.headliner = "pd0"
	var d = c.state.dungeon
	check.call(Dungeon.permadeath(c) and Dungeon.uses_lives(c), "new runs use permadeath with lives")
	check.call(Dungeon.field_cap(c) == 5 and Dungeon.guild_cap(c) == 7, "field five, guild seven")
	# Grace: act 1, room 1 only wounds.
	var sim = BattleSim.new(); sim.fall_order = ["pd2", "pd1"]
	d.act = 1; d.row = 0
	var fates = Dungeon.casualties(c, sim, false)
	check.call(fates.size() == 1 and fates[0].fate == "spared" and Dungeon.wounded(c.hero_by_id("pd2")), "grace rooms wound instead of kill")
	check.call(c.state.roster.size() == 6, "nobody died in grace")
	var wm = Dungeon.wound_mods(c)
	check.call(wm.size() == 1 and float(wm[0].hp) < 0, "wounded champions fight weaker")
	check.call(Dungeon.heal_wounds(c) == 1 and not Dungeon.wounded(c.hero_by_id("pd2")), "rest mends wounds")
	# A win kills nobody under "fallen".
	d.row = 5
	check.call(Dungeon.casualties(c, sim, true).is_empty() and c.state.roster.size() == 6, "a won fight kills nobody")
	# A loss kills the first to fall; items return; legacy XP; the bench steps up.
	var harpy = c.hero_by_id("pd2"); harpy.equipment = {"0": "club"}
	var bag = c.state.inventory.size()
	var xp_before = int(c.hero_by_id("pd1").get("xp", 0)) + 1000 * int(c.hero_by_id("pd1").level)
	fates = Dungeon.casualties(c, sim, false)
	check.call(fates.size() == 1 and fates[0].fate == "dead" and c.hero_by_id("pd2").is_empty(), "a lost fight kills the first champion to fall")
	check.call(c.state.inventory.size() == bag + 1 and "club" in c.state.inventory, "the fallen's items return to the bag")
	check.call(int(c.hero_by_id("pd1").get("xp", 0)) + 1000 * int(c.hero_by_id("pd1").level) > xp_before, "survivors gain legacy XP")
	check.call(c.lineup().size() == 5 and int(c.hero_by_id("pd5").slot) >= 0, "the bench steps into the empty place")
	check.call(d.graveyard.size() == 1 and str(d.graveyard[0].name) == "Pd 2", "the graveyard remembers the fallen")
	# The headliner passes the crown.
	sim.fall_order = ["pd0"]
	Dungeon.casualties(c, sim, false)
	check.call(str(c.state.headliner) != "pd0" and not c.hero_by_id(str(c.state.headliner)).is_empty(), "the crown passes to a survivor")
	# The Ferryman brings back the most recent fallen, without items.
	var ferry = Dungeon.EVENTS.filter(func(e): return e.id == "ferryman")[0].duplicate(true)
	d.event = ferry; c.state.gold = 500
	var size_before = c.state.roster.size()
	check.call(Dungeon.choose_event(c, 0) != "" and c.state.roster.size() == size_before + 1 and not c.hero_by_id("pd0").is_empty(), "the Ferryman revives the fallen")
	check.call(c.hero_by_id("pd0").get("equipment", {}).is_empty() and int(c.state.gold) == 380, "revival costs 120 gold and returns no items")
	# Sixth-slot relics.
	for id in ["war_council", "crowded_banner", "mercenary_contract", "reapers_bargain", "sixth_standard"]:
		var t = Campaign.new(); t.new_run("Six " + id, 91, 7, "Standard"); Dungeon.start(t)
		t.state.dungeon.relics.append(id)
		check.call(Dungeon.field_cap(t) == 6, id + " fields six")
	# Old saves keep plain guild lives.
	var old = Campaign.new(); old.new_run("Old", 91, 8, "Standard"); Dungeon.start(old); old.state.dungeon.erase("rules")
	check.call(not Dungeon.permadeath(old) and Dungeon.field_cap(old) == 6, "saves without rules keep the old lives and six fielded")
	for f in fails: print("FAIL ", f)
	print("permadeath rules: %d failures" % fails.size())
	quit()
