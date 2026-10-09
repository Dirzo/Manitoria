extends SceneTree
## Warden calibration: every Warden fights the same reference squads (random drafts at the level,
## item count and relic count a typical run has when it reaches that depth) across a range of
## mechanic weights, and reports the weight that lands closest to the target win rate.
##   PROBE_SQUADS (default 16) · PROBE_DEPTH (default 2) · PROBE_TARGET (default 0.6)
const LEVEL := {1: 6, 2: 10, 3: 13}
const ITEMS := {1: 1, 2: 2, 3: 3}   # random components, as the auto-player equips them
const RELICS := {1: 0, 2: 2, 3: 4}
const WEIGHTS := [0.5, 0.75, 1.0, 1.3, 1.6, 2.0, 2.5]

func _initialize() -> void: call_deferred("run")

func squads(depth: int, n: int) -> Array:
 var out = []
 var species = HeroData.species.keys(); species.sort()
 for s in range(n):
  var c = Campaign.new(); c.new_run("Ref %d" % s, 90, 7000 + s * 53, "Standard"); c.state.speedrun_memory = true
  Dungeon.start(c); Dungeon.choose_instance(c, c.state.dungeon.instance_choices[0])
  var rng = RandomNumberGenerator.new(); rng.seed = 900 + s
  c.state.roster = []
  for i in range(5):
   var sp = species[rng.randi_range(0, species.size() - 1)]
   var h = HeroData.make_hero(sp, "ref%d_%d" % [s, i], sp, 1); h.slot = Campaign.FORMATION[i]
   while int(h.level) < LEVEL[depth]:
    h.level += 1; var cards = HeroData.choices(h, true, rng)
    if not cards.is_empty(): HeroData.apply_choice(h, cards[0])
   h.equipment = {}
   for k in range(ITEMS[depth]): h.equipment[str(k)] = Forge.COMPONENT_ORDER[rng.randi_range(0, Forge.COMPONENT_ORDER.size() - 2)]
   c.state.roster.append(h)
  c.state.headliner = c.state.roster[0].id
  var pool = Relics.RELICS.keys().filter(func(id): return Relics.RELICS[id].rarity != "Boss" and id != "trait_emblem"); pool.sort()
  for k in range(RELICS[depth]): c.state.dungeon.relics.append(pool[rng.randi_range(0, pool.size() - 1)])
  out.append(c)
 return out

func fight(c: Campaign, key: String, depth: int, weight: float, seed: int) -> bool:
 var level = TourBalance.level({1: 2, 2: 4, 3: 5}[depth], "Standard")
 var b = Bestiary.make(key, "probe_boss", level, WorldTour.stage(c), "Standard", Campaign.FORMATION[0]); b.depth = depth
 var w = Bestiary.weight(key, depth)
 # Express the trial weight as an empowerment on top of the Warden's current weight.
 var base = Bestiary.strength(key, depth)
 b.empower = (1.0 + base.hp * weight / w) / (1.0 + base.hp) - 1.0
 var mobs = []
 for id in DungeonInstances.ORDER:
  if DungeonInstances.info(id).boss == key: mobs = DungeonInstances.info(id).mobs
 var roster = [b]
 for i in range(2): roster.append(Bestiary.make(mobs[(seed + i) % mobs.size()], "probe_esc_%d" % i, maxi(1, level - 1), WorldTour.stage(c), "Standard", Campaign.FORMATION[i + 3]))
 var sim = BattleSim.new(); sim.silent = true; sim.team_mods = c.battle_mods()
 sim.setup(c.lineup(), roster, 4000 + seed, TourBalance.quality({1: 2, 2: 4, 3: 5}[depth], 3, "Standard")); sim.run_to_end()
 return sim.winner == 0

func run() -> void:
 ItemFeedback.enabled = false; HeroData.load_data()
 var n = int(OS.get_environment("PROBE_SQUADS")) if OS.get_environment("PROBE_SQUADS") != "" else 16
 var depth = int(OS.get_environment("PROBE_DEPTH")) if OS.get_environment("PROBE_DEPTH") != "" else 2
 var target = float(OS.get_environment("PROBE_TARGET")) if OS.get_environment("PROBE_TARGET") != "" else 0.6
 var teams = squads(depth, n)
 var keys = Bestiary.BOSSES.keys(); keys.sort()
 if OS.get_environment("PROBE_BOSS") != "": keys = [OS.get_environment("PROBE_BOSS")]
 if OS.get_environment("PROBE_SEARCH") == "1":
  # Bisection in log space: the weight that lands the reference squads on the target win rate.
  for key in keys:
   var lo = log(0.25); var hi = log(3.5); var rate = 0.0
   for step in range(6):
    var mid = (lo + hi) * 0.5; var wins = 0
    for s in range(teams.size()): wins += int(fight(teams[s], key, depth, exp(mid), s))
    rate = float(wins) / teams.size()
    if rate > target: lo = mid
    else: hi = mid
    await process_frame
   print("SEARCH %s depth %d weight %.2f (last %.0f%%)" % [key, depth, exp((lo + hi) * 0.5), rate * 100])
  quit(); return
 for key in keys:
  var rates = []
  for w in WEIGHTS:
   var wins = 0
   for s in range(teams.size()): wins += int(fight(teams[s], key, depth, w, s))
   rates.append(float(wins) / teams.size())
   await process_frame
  var best = 0
  for i in range(rates.size()):
   if absf(rates[i] - target) < absf(rates[best] - target): best = i
  print("%-17s current %.2f · %s · best weight %.2f" % [key, float(Bestiary.BOSSES[key].weight), " ".join(range(WEIGHTS.size()).map(func(i): return "%.2f:%d%%" % [WEIGHTS[i], roundi(rates[i] * 100)])), WEIGHTS[best]])
 quit()
