extends SceneTree
var checks = 0
var failures = 0

func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(message)

func _init() -> void:
 HeroData.load_data()
 check(is_equal_approx(ArenaGrid.BOUNDS.x * ArenaGrid.BOUNDS.y / (12.2 * 7.5), 1.30), "Playable area grows by exactly 30%")
 var seen = {}
 for slot in range(15):
  var left = ArenaGrid.formation_position(slot)
  var right = ArenaGrid.formation_position(slot, 1)
  check(left.abs().x <= ArenaGrid.BOUNDS.x and left.abs().y <= ArenaGrid.BOUNDS.y, "Deployment stays inside bounds")
  check(right.is_equal_approx(Vector2(-left.x, left.y)), "Both teams use mirrored deployment")
  check(ArenaGrid.nearest_formation_slot(left) == slot, "Every deployment hex round-trips through picking")
  check(not seen.has(left), "Every deployment hex is unique"); seen[left] = true
 check(ArenaGrid.formation_position(1).y != ArenaGrid.formation_position(0).y, "Middle column uses staggered hex centers")
 for sp in HeroData.species:
  var hero = HeroData.make_hero(sp, "test-" + sp, sp, 3)
  var stats = HeroData.stats(hero)
  var old_range = maxf(0.7, HeroData.species[sp].range / 44.0)
  check(stats.range > old_range if old_range > 2 else is_equal_approx(stats.range, old_range), "Ranged reach grows and melee reach stays the same: " + sp)
 var sim = BattleSim.new(); sim.silent = true
 var gunner = sim.add_unit(HeroData.make_hero("cyclops", "gunner", "Gunner"), 0, Vector2(-5, 0))
 var target = sim.add_unit(HeroData.make_hero("golem", "target", "Target"), 1, Vector2(2, 0))
 var old_hp = target.hp
 sim.attack(gunner, target)
 check(sim.projectiles.size() == 1 and target.hp == old_hp, "Ranged damage waits for projectile arrival")
 check(sim.projectiles[0].heavy and sim.projectiles[0].duration > 0.75, "Artillery has heavy, slower shells")
 check(is_equal_approx(gunner.attack_basic, gunner.attack * CombatPacing.BASIC_SCALE * 1.30), "Artillery basic shells hit 30% harder")
 gunner.alive = false
 target.cd = 999; target.attack_timer = 999
 sim.step(1.4)
 check(target.hp < old_hp and sim.projectiles.is_empty(), "An already fired shell lands after its caster falls")
 for count in [1, 4, 5, 12]:
  for selected in range(count):
   check(ChampionCarousel.offset_for(selected, selected, count) == 0, "Featured carousel champion stays centered")
   check(posmod(selected + ChampionCarousel.offset_for(0, selected, count), count) == 0, "Carousel wraps to the right champion")
 var ranged = HeroData.learned_ability("cyclops", 1)
 check(ranged.range > HeroData.EFFECTS[ranged.effect][2], "Artillery learned skills also gain reach")
 for id in Forge.COMPONENTS:
  check(AbilityArt.texture(Forge.info(id).art).resource_path == "res://assets/items/%s.png" % id, "Component uses its committed picture: " + id)
 for id in Forge.ITEMS:
  check(AbilityArt.texture(Forge.info(id).art).resource_path == "res://assets/items/i_%s.png" % id, "Finished item uses its committed picture: " + id)
 # Seeded full team fights exercise navigation, skills, projectiles and timeout.
 for seed_value in range(1, 7):
  var teams = [[], []]
  for side in range(2):
   for i in range(5):
    var sp = ["golem", "minotaur", "cyclops", "harpy", "unicorn"][i]
    var h = HeroData.make_hero(sp, "%s-%s-%s" % [sp, side, i], sp, 5)
    h.slot = Campaign.FORMATION[i]; h.learned = {"0": 1, "1": 1}
    teams[side].append(h)
  sim = BattleSim.new(); sim.silent = true; sim.setup(teams[0], teams[1], seed_value)
  var inside = true
  while not sim.finished:
   sim.step(1.0 / 30.0)
   for unit in sim.units:
    if unit.alive and (absf(unit.pos.x) > BattleSim.BOUNDS.x + 0.001 or absf(unit.pos.y) > BattleSim.BOUNDS.y + 0.001): inside = false
  check(inside and sim.finished and sim.time < CombatPacing.TIME_LIMIT + 0.1, "Full fight finishes with fighters inside enlarged bounds")
 print("Hex/artillery: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
