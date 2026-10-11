extends SceneTree
## Dungeon balance probe: an auto-player drafts a normal squad (headliner, one Epic, three Commons),
## walks the map, takes and equips every reward, shops at outfitters, and fights every battle for
## real. Reports win rates per room type and depth and how far runs get.
##   PROBE_RUNS (default 12) · PROBE_DIFFICULTY (default Standard) · PROBE_ENDLESS=1 keeps going
##   PROBE_RULES='{"death":"wounds","guild":8,"field":5}' plays a v0.78 permadeath rule set
##   PROBE_SEED0 (first seed, default 0) · PROBE_JSON=1 prints one JSON summary line per run
var stats = {}
var drafted = [];
var parties = [];
var res = []; var tiers = []; var lv = []; var items = [];
var deaths = 0; var wounds = 0; var died = []; var fights = 0; var if_lost = 0
var outcomes = []

func _initialize() -> void: call_deferred("run")

func bump(key: String, won: bool) -> void:
 if not stats.has(key): stats[key] = {"fights": 0, "wins": 0}
 stats[key].fights += 1; stats[key].wins += int(won)

## Field the healthiest guild: bench a Wounded starter for a fresh champion of similar level.
func manage_bench(c: Campaign) -> void:
 Dungeon.fill_field(c)
 for w in c.lineup():
  if not Dungeon.wounded(w): continue
  for b in c.state.roster:
   if int(b.slot) < 0 and not Dungeon.wounded(b) and int(b.level) >= int(w.level) - 2:
    b.slot = w.slot; w.slot = -1
    for k in w.get("equipment", {}).keys().duplicate(): c.unequip(str(w.id), str(k))
    break

## Level-up picks match how recruits are built (StatCards.auto_pick), so a fresh recruit is never
## better built than a veteran just because the probe chose its cards differently.
func pick_card(h: Dictionary) -> int:
 var cards = h.pending[0]
 if cards is Array and cards.all(func(x): return x is Dictionary and x.has("key") and x.has("tier")): return StatCards.auto_pick(h, cards)
 return 0

func equip_all(c: Campaign) -> void:
 for item in c.state.inventory.duplicate():
  for h in c.lineup():
   if c.free_slot(h) != "" and c.equip(h.id, item): break

func settle(c: Campaign, rng: RandomNumberGenerator) -> void:
 # Drafts: take the offer sharing the most traits with the guild (ties: first offered).
 var draft = c.state.dungeon.get("draft", {})
 if not draft.is_empty():
  var best = 0; var best_n = -1
  for i in range(draft.offers.size()):
   var n = Dungeon.shared_traits(c, draft.offers[i].sp).size()
   if n > best_n: best = i; best_n = n
  if Dungeon.take_champion(c, best): drafted.append("%s:%d.%d" % [str(draft.kind), int(c.state.dungeon.act), int(c.state.dungeon.row) + 1])
  else: Dungeon.skip_draft(c)
 if not c.state.dungeon.get("instance_choices", []).is_empty():
  var choices = c.state.dungeon.instance_choices
  Dungeon.choose_instance(c, choices[rng.randi_range(0, choices.size() - 1)])
 var guard = 0
 while not c.pending_heroes().is_empty() and guard < 40:
  var h = c.pending_heroes()[0]; c.choose(h.id, pick_card(h)); guard += 1
 var d = c.state.dungeon
 while not d.loot.is_empty(): Dungeon.take_loot(c, rng.randi_range(0, d.loot.size() - 1))
 if not d.event.is_empty():
  var options = []
  for i in range(d.event.choices.size()):
   var ch = d.event.choices[i]
   # The auto-player doesn't trade champions or relics away; a real player weighs that.
   if not ch.get("disabled", false) and not ch.get("ferry", false) and not ch.get("sacrifice", false): options.append(i)
  # Prefer restoring lives (or mending wounds) when hurt, otherwise any sensible option.
  var pick = options[0] if not options.is_empty() else 0
  var hurt = c.state.roster.filter(func(h): return Dungeon.wounded(h)).size()
  for i in options:
   if int(d.event.choices[i].get("lives", 0)) > 0 and int(d.lives) < int(d.max_lives): pick = i
   if d.event.choices[i].get("heal", false) and hurt > 0: pick = i
   if d.event.choices[i].get("revive", false): pick = i
  # Under permadeath the auto-player won't take a wound for loot unless the whole squad is fresh.
  if d.event.choices[pick].get("wound", false) and hurt > 0:
   for i in options:
    if not d.event.choices[i].get("wound", false): pick = i; break
  Dungeon.choose_event(c, pick)
  while not d.loot.is_empty(): Dungeon.take_loot(c, 0)
 if c.state.tour.shop:
  for i in range(c.state.tour.stock.size()):
   var id = str(c.state.tour.stock[i])
   if id != "" and int(c.state.gold) >= int(Forge.info(id).price) + 40: c.buy_item(i)
  if Dungeon.shop_draft_open(c) and int(c.state.gold) >= Dungeon.shop_draft_cost(c) + 40:
   Dungeon.buy_shop_draft(c); settle(c, rng)
  WorldTour.leave_shop(c)
 if c.state.tour.get("intermission", false):
  # New recruits: replace the weakest Common if gold allows.
  WorldTour.end_intermission(c)
 if Dungeon.permadeath(c): manage_bench(c)
 equip_all(c)
 guard = 0
 while not c.pending_heroes().is_empty() and guard < 40:
  var h = c.pending_heroes()[0]; c.choose(h.id, pick_card(h)); guard += 1

func play(seed: int, difficulty: String, endless: bool) -> Dictionary:
 drafted = []; parties = []; res = []; tiers = []; lv = []; items = []; deaths = 0; wounds = 0; died = []; fights = 0; if_lost = 0
 var c = Campaign.new(); c.new_run("Probe %d" % seed, 90, 5000 + seed * 131, difficulty)
 Dungeon.start(c, int(OS.get_environment("PROBE_ASCENSION")) if OS.get_environment("PROBE_ASCENSION") != "" else 0); c.state.speedrun_memory = true    # never touch disk
 var rng = RandomNumberGenerator.new(); rng.seed = seed
 var legends = League.tiers().Legendary
 c.choose_starter(legends[seed % legends.size()])   # opens the partner draft
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
   var ratio = Dungeon.threat(c, int(d.row), int(d.col)); var parts = Dungeon.last_threat.duplicate()
   var sim = BattleSim.new(); sim.silent = true; sim.team_mods = c.battle_mods()
   sim.setup(c.lineup(), c.opponent().roster, c.match_seed(), c.quality()); sim.run_to_end()
   bump("%s · depth %d" % [kind, int(d.act)], sim.winner == 0)
   if OS.get_environment("PROBE_THREAT") == "1": print("THREAT ", JSON.stringify({"kind": kind, "act": int(d.act), "ratio": ratio, "won": sim.winner == 0, "parts": parts}))
   if kind == "boss": bump("warden · %s" % str(DungeonInstances.info(Dungeon.instance_id(c)).boss), sim.winner == 0)
   c.resolve(sim)
   var rep = c.state.get("report", {})
   for f in rep.get("fates", []):
    if f.fate == "dead": deaths += 1; died.append("%s@%d.%d" % [f.sp, int(d.act), int(d.row) + 1])
    elif f.fate == "wounded": wounds += 1
   fights += 1; if_lost += int(sim.winner != 0)
   parties.append(sim.units.filter(func(u): return u.team == 0 and not u.summon).size())
   tiers.append(RunTraits.mods(c, c.lineup()).size()); lv.append(c.lineup().reduce(func(acc, h): return acc + int(h.level), 0) / maxf(1, c.lineup().size()) - float(Dungeon.quality_at(c, int(d.row), kind)) * 0.0)
   res.append([int(sim.winner == 0), kind, int(d.act), parties[-1]])
   items.append(c.lineup().reduce(func(acc, h): return acc + h.get("equipment", {}).size(), 0))
  else:
   var options = Dungeon.reachable(c)
   if options.is_empty(): break
   # A cautious player: avoid elites when down to one life.
   var pick = options[rng.randi_range(0, options.size() - 1)]
   var fragile = int(d.lives) <= 1
   if Dungeon.permadeath(c) and not Dungeon.uses_lives(c): fragile = c.state.roster.size() <= 3 or c.lineup().filter(func(h): return Dungeon.wounded(h)).size() >= 2
   if fragile:
    for o in options:
     if str(d.map[int(d.row) + 1][o].type) != "elite": pick = o; break
   Dungeon.enter(c, pick)
  steps += 1
 var d = c.state.dungeon
 var out = {"relic_ids": c.state.dungeon.relics.duplicate(), "field_cap": Dungeon.field_cap(c), "revived": c.state.dungeon.get("graveyard", []).size(), "res": res, "tiers": tiers, "lv": lv, "items": items, "party": parties, "drafted": drafted, "deaths": deaths, "wounds": wounds, "died": died, "fights": fights, "losses": if_lost, "guild": c.state.roster.size(), "gold": int(c.state.gold), "seed": seed, "depth": int(d.act), "row": int(d.row) + 1, "wardens": int(d.wardens), "lives": int(d.lives), "score": int(d.get("final_score", Dungeon.final_score(c))), "relics": d.relics.size(), "fallen": c.state.get("run_over", false), "level": c.lineup().map(func(h): return int(h.level))}
 print("RUN " + JSON.stringify(out))
 return out

func run() -> void:
 ItemFeedback.enabled = false
 var kept_scores = FileAccess.get_file_as_string(Dungeon.SCORES_PATH) if FileAccess.file_exists(Dungeon.SCORES_PATH) else ""
 var kept_progress = FileAccess.get_file_as_string(DungeonAscension.PROGRESS_PATH) if FileAccess.file_exists(DungeonAscension.PROGRESS_PATH) else ""
 var runs = int(OS.get_environment("PROBE_RUNS")) if OS.get_environment("PROBE_RUNS") != "" else 12
 var difficulty = OS.get_environment("PROBE_DIFFICULTY") if OS.get_environment("PROBE_DIFFICULTY") != "" else "Standard"
 var endless = OS.get_environment("PROBE_ENDLESS") == "1"
 if OS.get_environment("PROBE_RULES") != "": Dungeon.probe_rules = JSON.parse_string(OS.get_environment("PROBE_RULES"))
 var seed0 = int(OS.get_environment("PROBE_SEED0")) if OS.get_environment("PROBE_SEED0") != "" else 0
 for s in range(seed0, seed0 + runs):
  outcomes.append(play(s, difficulty, endless))
  await process_frame
 var keys = stats.keys(); keys.sort()
 for k in keys: print("%-22s %3d / %3d  %5.1f%%" % [k, stats[k].wins, stats[k].fights, 100.0 * stats[k].wins / maxf(1, stats[k].fights)])
 var cleared = outcomes.filter(func(o): return int(o.wardens) >= 3).size()
 var wardens = outcomes.map(func(o): return int(o.wardens))
 print("%s: %d runs · cleared %d · wardens per run %s · mean score %d" % [difficulty, runs, cleared, str(wardens), outcomes.reduce(func(a, o): return a + int(o.score), 0) / maxi(1, runs)])
 # Leave the player's own high-score table and Ascension progress exactly as they were.
 if kept_progress != "":
  var pf = FileAccess.open(DungeonAscension.PROGRESS_PATH, FileAccess.WRITE); pf.store_string(kept_progress); pf.close()
 elif FileAccess.file_exists(DungeonAscension.PROGRESS_PATH): DirAccess.remove_absolute(DungeonAscension.PROGRESS_PATH)
 if kept_scores != "":
  var f = FileAccess.open(Dungeon.SCORES_PATH, FileAccess.WRITE); f.store_string(kept_scores); f.close()
 elif FileAccess.file_exists(Dungeon.SCORES_PATH): DirAccess.remove_absolute(Dungeon.SCORES_PATH)
 quit()
