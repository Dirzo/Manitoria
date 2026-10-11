extends SceneTree
## v0.76: an old v0.75 champion (skills, ranks, Apex Mastery, pending skill cards) migrates cleanly.
func _init() -> void:
	HeroData.load_data(); HeroData.run_salt = "mig"
	var fails = 0
	var h = HeroData.make_hero("phoenix", "old1", "Ashborn", 17)
	h.progression_version = 2; h.learned = {"0": 3, "4": 2}; h.signature_rank = 3; h.apex = "apex_skill"; h.evolution = "phoenix:1"
	h.skill_rarity = {"0": "Legendary"}; h.ability_bonus_0 = 1.25; h.erase("cards")
	h.pending = [[{"type": "ability", "key": "5"}], [{"type": "signature", "key": "signature"}]]; h.rewards = [{"level": 16, "won": true, "seed": 1}, {"level": 17, "won": true, "seed": 2}]
	HeroData.migrate_progression(h)
	var checks = [
		[h.learned.is_empty(), "skills removed"], [int(h.signature_rank) == 1, "rank reset"],
		[str(h.apex) == "apex_sig", "Apex Mastery -> Apex Signature"], [str(h.evolution) == "phoenix:1", "evolution kept"],
		[not h.has("skill_rarity"), "skill rarity removed"], [h.pending.size() == 2, "two pending level-ups kept"],
		[str(h.pending[0][0].type) == "stat", "pending become stat cards"], [not StatCards.picks_line(h).is_empty(), "past levels auto-picked"],
		[bool(h.get("card_reset", false)), "free reset offered"],
	]
	var before = StatCards.picks_line(h)
	HeroData.reset_cards(h)
	checks.append([h.cards.is_empty(), "reset clears cards"])
	checks.append([h.pending.size() >= 14, "reset re-queues picks (%d)" % h.pending.size()])
	checks.append([not bool(h.get("card_reset", false)), "reset only once"])
	var s = HeroData.stats(h)
	checks.append([s.ap >= 90 and s.res > 0 and s.max_mana > 0, "stats valid"])
	for c in checks:
		if not c[0]: fails += 1; print("FAIL ", c[1])
	print("migration: %d checks, %d failures" % [checks.size(), fails])
	quit()
