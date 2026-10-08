extends SceneTree
## Dungeon balance probe: an auto-player drafts a normal squad (headliner, one Epic, three Commons),
## walks the map, takes and equips every reward, shops at outfitters, and fights every battle for
## real. Reports win rates per room type and depth and how far runs get.
##   PROBE_RUNS (default 12) · PROBE_DIFFICULTY (default Standard) · PROBE_ENDLESS=1 keeps going
var stats = {}
var outcomes = []

func _initialize() -> void: call_deferred("run")

func bump(key: String, won: bool) -> void:
 if not stats.has(key): stats[key] = {"fights": 0, "wins": 0}
 stats[key].fights += 1; stats[key].wins += int(won)

func equip_all(c: Campaign) -> void:
 for item in c.state.inventory.duplicate():
  for h in c.lineup():
   if c.free_slot(h) != "" and c.equip(h.id, item): break

func settle(c: Campaign, rng: RandomNumberGenerator) -> void:
 var guard = 0
 while not c.pending_heroes().is_empty() and guard < 40:
  var h = c.pending_heroes()[0]; c.choose(h.id, 0); guard += 1
 var d = c.state.dungeon
 while not d.loot.is_empty(): Dungeon.take_loot(c, rng.randi_range(0, d.loot.size() - 1))
 if not d.event.is_empty():
  var options = []
  for i in range(d.event.choices.size()):
   if not d.event.choices[i].get("disabled", false): options.append(i)
  # Prefer restoring lives when hurt, otherwise any sensible option.
  var pick = options[0]
  for i in options:
   if int(d.event.choices[i].get("lives", 0)) > 0 and int(d.lives) < int(d.max_lives): pick = i
  Dungeon.choose_event(c, pick)
  while not d.loot.is_empty(): Dungeon.take_loot(c, 0)
 if c.state.tour.shop:
  for i in range(c.state.tour.stock.size()):
   var id = str(c.state.tour.stock[i])
   if id != "" and int(c.state.gold) >= int(Forge.info(id).price) + 40: c.buy_item(i)
  WorldTour.leave_shop(c)
 if c.state.tour.get("intermission", false):
  # New recruits: replace the weakest Common if gold allows.
  WorldTour.end_intermission(c)
 equip_all(c)
 guard = 0
 while not c.pending_heroes().is_empty() and guard < 40:
  var h = c.pending_heroes()[0]; c.choose(h.id, 0); guard += 1

func play(seed: int, difficulty: String, endless: bool) -> Dictionary:
 var c = Campaign.new(); c.new_run("Probe %d" % seed, 90, 5000 + seed * 131, difficulty)
 Dungeon.start(c); c.state.speedrun_memory = true    # never touch disk
 var rng = RandomNumberGenerator.new(); rng.seed = seed
 var legends = League.tiers().Legendary
 c.choose_starter(legends[seed % legends.size()])
 var epics = c.state.market.filter(func(h): return League.tier(h.sp) == "Epic")
 c.recruit(epics[rng.randi_range(0, epics.size() - 1)].id)
 for i in range(3):
  var commons = c.state.market.filter(func(h): return League.tier(h.sp) == "Common")
  c.recruit(commons[rng.randi_range(0, commons.size() - 1)].id)
 var steps = 0
 while steps < 120:
  settle(c, rng)
  var d = c.state.dungeon
  if c.state.get("run_over", false) or c.state.tour.get("complete", false): break
  if d.awaiting_endless:
   if endless: Dungeon.go_endless(c); continue
   Dungeon.retire(c); break
  if int(d.act) >= 12: Dungeon.retire(c); break
  if d.fight:
   var kind = str(Dungeon.node(c).type)
   var sim = BattleSim.new(); sim.silent = true; sim.team_mods = c.battle_mods()
   sim.setup(c.lineup(), c.opponent().roster, c.match_seed(), c.quality()); sim.run_to_end()
   bump("%s · depth %d" % [kind, int(d.act)], sim.winner == 0)
   c.resolve(sim)
  else:
   var options = Dungeon.reachable(c)
   if options.is_empty(): break
   # A cautious player: avoid elites when down to one life.
   var pick = options[rng.randi_range(0, options.size() - 1)]
   if int(d.lives) <= 1:
    for o in options:
     if str(d.map[int(d.row) + 1][o].type) != "elite": pick = o; break
   Dungeon.enter(c, pick)
  steps += 1
 var d = c.state.dungeon
 var out = {"seed": seed, "depth": int(d.act), "row": int(d.row) + 1, "wardens": int(d.wardens), "lives": int(d.lives), "score": int(d.get("final_score", Dungeon.final_score(c))), "relics": d.relics.size(), "fallen": c.state.get("run_over", false), "level": c.lineup().map(func(h): return int(h.level))}
 print(out)
 return out

func run() -> void:
 ItemFeedback.enabled = false
 var kept_scores = FileAccess.get_file_as_string(Dungeon.SCORES_PATH) if FileAccess.file_exists(Dungeon.SCORES_PATH) else ""
 var runs = int(OS.get_environment("PROBE_RUNS")) if OS.get_environment("PROBE_RUNS") != "" else 12
 var difficulty = OS.get_environment("PROBE_DIFFICULTY") if OS.get_environment("PROBE_DIFFICULTY") != "" else "Standard"
 var endless = OS.get_environment("PROBE_ENDLESS") == "1"
 for s in range(runs):
  outcomes.append(play(s, difficulty, endless))
  await process_frame
 var keys = stats.keys(); keys.sort()
 for k in keys: print("%-22s %3d / %3d  %5.1f%%" % [k, stats[k].wins, stats[k].fights, 100.0 * stats[k].wins / maxf(1, stats[k].fights)])
 var cleared = outcomes.filter(func(o): return int(o.wardens) >= 3).size()
 var wardens = outcomes.map(func(o): return int(o.wardens))
 print("%s: %d runs · cleared %d · wardens per run %s · mean score %d" % [difficulty, runs, cleared, str(wardens), outcomes.reduce(func(a, o): return a + int(o.score), 0) / maxi(1, runs)])
 # Leave the player's own high-score table exactly as it was.
 if kept_scores != "":
  var f = FileAccess.open(Dungeon.SCORES_PATH, FileAccess.WRITE); f.store_string(kept_scores); f.close()
 elif FileAccess.file_exists(Dungeon.SCORES_PATH): DirAccess.remove_absolute(Dungeon.SCORES_PATH)
 quit()
