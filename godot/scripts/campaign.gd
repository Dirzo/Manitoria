class_name Campaign
extends RefCounted

var state: Dictionary = {}
var last_error = ""
const SAVE_VERSION = 1
const CLUBS = ["Dread Wyverns", "Ashen Crown", "Moonlit Wardens", "Iron Orchard", "Stormbound", "Thorn Company", "Ivory Pact"]
const FORMATION = [5, 11, 7, 3, 9]
const MIN_SQUAD = 4   # an elite four-creature squad is legal (and gets the elite-squad bonus)
const MAX_SQUAD = 5

func new_run(club_name: String, slot: int, seed_value: int = 0, difficulty: String = "Keeper") -> void:
 HeroData.load_data()
 var seed_used = seed_value if seed_value else int(Time.get_unix_time_from_system())
 HeroData.run_salt = str(seed_used) + ("" if seed_value else "|" + str(randi()))
 state = {"version": SAVE_VERSION, "name": club_name.strip_edges().left(36) if not club_name.strip_edges().is_empty() else "Ravenmoor Menagerie", "slot": slot, "seed": seed_used, "season": 1, "round": 0, "gold": League.START_GOLD, "earned_gold": 0, "roster": [], "market": [], "clubs": [], "schedule": [], "report": {}, "wins": 0, "losses": 0, "draws": 0, "difficulty": difficulty, "selected": "", "trophies": 0, "history": [], "next_id": 100, "music": true, "effects": true, "guide_seen": false}
 # Fresh tiers every run: a random headliner and Epic from each of the eight niches.
 state.tiers = League.roll_tiers(HeroData.run_salt); League.run_tiers = state.tiers
 var rng = RandomNumberGenerator.new(); rng.seed = seed_used
 create_market(rng)
 # Rival clubs are drafted once the player has signed a headliner (each club gets a different one).
 make_schedule()
 state.league_version = 1
 state.league_wins = 0; state.league_losses = 0; state.league_draws = 0
 ensure_management()
 state.run_id=Crypto.new().generate_random_bytes(16).hex_encode()
 state.salt=HeroData.run_salt
 WorldTour.start(self)
 add_news("Club founded", "Your %d gold founding fund is ready. Sign a Legendary headliner, then draft four more creatures." % League.START_GOLD)

## The draft board: every Epic and Common creature is always available at its tier price.
## (Legendary headliners are signed once, one per club.)
func create_market(_rng: RandomNumberGenerator = null) -> void:
 state.market = []
 for t in ["Epic", "Common"]:
  for sp in League.tiers()[t]: state.market.append(draft_prospect(sp))

func draft_prospect(sp: String) -> Dictionary:
 var wave = int(state.get("market_wave", 0))
 # Recruit boards after the first cup bring seasoned champions who arrive near your squad's level.
 var lvl = 1
 if wave > 0 and not lineup().is_empty():
  var total = 0
  for o in lineup(): total += int(o.level)
  lvl = clampi(roundi(float(total) / lineup().size()) - 1, 1, 18)
 var h = HeroData.make_hero(sp, "h%d" % state.next_id, HeroData.themed_name(sp, "h%d" % state.next_id), lvl)
 state.next_id += 1
 for k in range(mini(3, maxi(0, lvl - 1))): h.learned[str(k)] = 1
 if lvl >= 5: h.signature_rank = 2
 h.price = League.cost(sp) if wave == 0 else value_price(h)
 return h

## Value pricing for later recruit boards: rarity sets the base, then the stat rolls (overall and
## for the champion's role) and its level push the price up or down.
func value_price(h: Dictionary) -> int:
 var rolls = float(HeroData.roll_total(h)) / float(HeroData.ROLL_MAX * HeroData.ROLL_KEYS.size())   # 0..1, about 0.5 on average
 var q = 0.7 + 0.6 * rolls + 0.25 * clampf(HeroData.roll_fit(h), -1.0, 1.0)
 var lvl = 1.0 + 0.06 * (int(h.level) - 1)
 return maxi(60, roundi(League.cost(h.sp) * q * lvl / 5.0) * 5)

func recruitment_open() -> bool:
 if not state.has("tour"):return true
 var t=state.tour
 if state.get("run_over",false) or t.get("complete",false):return false
 if t.get("intermission",false):return true
 if t.get("shop",false):return false
 return not t.get("cup_started",false) and int(t.get("serial",0))==0

func recruit(id: String) -> bool:
 if not recruitment_open():last_error="Your roster is locked for this cup. Recruit between cups after keeping your team.";return false
 if state.roster.size() >= 12: return false
 for h in state.market:
  if h.id == id and state.gold >= h.price:
   state.gold -= h.price
   if lineup().size() < 5:
    h.slot = standard_slot(h, lineup().map(func(b): return b.slot))
   # The drafted champion leaves the board; nothing replaces it until the next cup's fresh board.
   state.roster.append(h); state.market.erase(h)
   if state.get("headliner", "").is_empty(): state.headliner=h.id
   add_news("New signing · " + h.name, "%s joins your %s line." % [HeroData.species[h.sp].n, HeroData.line(h.sp).to_lower()])
   state.selected = h.id
   # Squad complete (a full five, or an elite four with too little gold for another): show the roster next.
   var n = lineup().size()
   if not state.get("draft_done", false) and (n >= MAX_SQUAD or (n >= MIN_SQUAD and int(state.gold) < League.COST_UNIT)):
    state.draft_done = true; state.roster_intro = true; state.goto_roster = true
   return save()
 return false

## Compatibility for older callers: champion copies have been retired.
func copy_purchases_open() -> bool:
 return false
func copy_offer(_h: Dictionary) -> Dictionary:
 return {}
func buy_champion_copy(_id: String) -> bool:
 last_error="Champion copies are retired. Develop champions through skills, items and evolutions."
 return false

func refresh_market() -> bool:
 if not recruitment_open():last_error="Recruitment reopens between cups.";return false
 if state.roster.size() < 5 or state.gold < 25: return false
 state.gold -= 25
 var rng = RandomNumberGenerator.new(); rng.seed = state.seed + state.next_id
 create_market(rng); return save()

func lineup_ready() -> bool:
 return lineup().size() >= MIN_SQUAD and lineup().size() <= MAX_SQUAD

func lineup() -> Array:
 return state.roster.filter(func(h): return h.slot >= 0)

func hero_by_id(id: String) -> Dictionary:
 for h in state.roster + state.market:
  if h.id == id: return h
 for club in state.clubs:
  for h in club.roster:
   if h.id == id: return h
 return {}

## Standard formation: front-liners in the front column, flankers in the middle, ranged at the back.
## The grid is 5 rows x 3 columns (slot = row * 3 + column; column 0 back, 1 middle, 2 front).
const LINE_COLUMN := {"Front": 2, "Flank": 1, "Back": 0}
const ROW_ORDER := [2, 1, 3, 0, 4]
func standard_slot(h: Dictionary, taken: Array) -> int:
 var col = LINE_COLUMN.get(HeroData.line(h.sp), 1)
 for c in [col, 1, 2 if col == 0 else 0, 0 if col == 2 else 2]:
  for r in ROW_ORDER:
   if not (r * 3 + c) in taken: return r * 3 + c
 return -1

func standard_formation() -> bool:
 var starters = lineup()
 if starters.is_empty(): return false
 # Fill the front first, then flank, then back, so each column stays centred.
 starters.sort_custom(func(a, b): return LINE_COLUMN.get(HeroData.line(a.sp), 1) > LINE_COLUMN.get(HeroData.line(b.sp), 1))
 var taken = []
 for h in starters:
  h.slot = standard_slot(h, taken); taken.append(h.slot)
 return save()

func place_hero(id: String, slot: int) -> bool:
 if slot < 0 or slot >= 15: return false
 var hero = hero_by_id(id)
 if hero.is_empty() or not hero in state.roster: return false
 var other = lineup().filter(func(h): return h.slot == slot)
 if hero.slot < 0 and lineup().size() >= 5 and other.is_empty(): return false
 var old = hero.slot
 if not other.is_empty(): other[0].slot = old
 hero.slot = slot; state.selected = id
 return save()

func pending_heroes() -> Array:
 return state.roster.filter(func(h): return not h.pending.is_empty())

func choose(id: String, index: int) -> bool:
 var hero = hero_by_id(id)
 if hero.is_empty() or hero.pending.is_empty(): return false
 var cards = hero.pending[0]
 if index < 0 or index >= cards.size(): return false
 var before = hero.duplicate(true)
 hero.last_offers = cards.map(func(c): return c.key)
 if not hero.has("offered_discoveries"):hero.offered_discoveries=[]
 for offered in cards:
  if offered.type=="ability" and not hero.learned.has(offered.key) and offered.key not in hero.offered_discoveries:hero.offered_discoveries.append(offered.key)
 HeroData.apply_choice(hero, cards[index]); hero.pending.pop_front()
 if not hero.get("rewards", []).is_empty(): hero.rewards.pop_front()
 HeroData.materialize_reward(hero)
 if save(): return true
 hero.clear(); hero.merge(before, true); return false

func quality() -> float:
 if Dungeon.active(self): return Dungeon.quality(self)
 if state.has("tour"):
  return TourBalance.quality(int(state.tour.level),int(state.tour.bout),str(state.difficulty))*(1.0+0.02*clampi(int(state.get("challenge_rank",0)),0,10))
 if state.difficulty == "Keeper": return minf(0.96, 0.90 + state.round * 0.004)
 if state.difficulty == "Champion": return 1.08
 return 1.0

func make_schedule() -> void:
 var ring = [0, 1, 2, 3, 4, 5, 6, 7]
 var first = []
 for i in range(7):
  var pairs = []
  for j in range(4): pairs.append([ring[j], ring[7 - j]])
  first.append(pairs)
  ring.insert(1, ring.pop_back())
 state.schedule = first.duplicate(true)
 for pairs in first:
  var second = []
  for pair in pairs: second.append([pair[1], pair[0]])
  state.schedule.append(second)

func opponent() -> Dictionary:
 if state.has("tour"): return WorldTour.opponent(self)
 if state.round < 3:
  var species_sets = [["golem", "minotaur", "jackalope", "harpy", "unicorn"], ["yeti", "owlbear", "direwolf", "wyvern", "naga"], ["troll", "cerberus", "griffin", "kirin", "treant"]]
  var team = []
  for i in range(5):
   var h = HeroData.make_hero(species_sets[state.round][i], "trial_%d" % i, ["Bramble", "Flint", "Dash", "Echo", "Dawn"][i])
   h.slot = FORMATION[i]; team.append(h)
  return {"name": ["The Old Keepers", "The Practice Pack", "The Gate Wardens"][state.round], "roster": team, "practice": true}
 var index = mini(state.round - 3, 13)
 for pair in state.schedule[index]:
  if pair.has(0): return state.clubs[int(pair[1] if pair[0] == 0 else pair[0]) - 1]
 return state.clubs[0]

func match_seed() -> int:
 if state.has("tour"): return int(state.seed+700000+state.tour.serial*31)
 return int(state.seed + state.season * 1000 + state.round * 17)

## World tour points per champion: a win is worth 3, an MVP performance 2, and every champion who
## played in a cup shares its finish (champions 10, runner-up 6, third 4, fourth 2).
const TOUR_POINTS := {"win": 3, "mvp": 2}
const CUP_POINTS := {1: 10, 2: 6, 3: 4, 4: 2}

## The match MVP: highest Arena Impact Score among real champions (not summons) on either side.
static func mvp_uid(sim: BattleSim) -> int:
 var best = -1; var top = -INF
 for u in sim.units:
  if u.summon: continue
  var a = float(League.ais(sim, u))
  if a > top: top = a; best = int(u.uid)
 return best

func record_team(heroes: Array, sim: BattleSim, team: int, player: bool, rng: RandomNumberGenerator, xp_scale: float = 1.0) -> void:
 var mvp = mvp_uid(sim)
 for u in sim.units:
  if u.team != team or u.summon: continue
  var matches = heroes.filter(func(h): return h.id == u.hero.id)
  if matches.is_empty(): continue
  var h = matches[0]
  h.bouts += 1; h.wins += 1 if sim.winner == team else 0
  h.losses = int(h.get("losses", 0)) + (1 if sim.winner == 1 - team else 0)
  if int(u.uid) == mvp: h.mvps = int(h.get("mvps", 0)) + 1
  if state.has("tour"):
   h.tour_points = int(h.get("tour_points", 0)) + (TOUR_POINTS.win if sim.winner == team else 0) + (TOUR_POINTS.mvp if int(u.uid) == mvp else 0)
   if player:
    if not state.tour.has("cup_played"): state.tour.cup_played = {}
    state.tour.cup_played[h.id] = true
  h.kills += u.kills; h.impact += u.damage / 60.0 + u.healing / 45.0 + u.blocked / 120.0 + u.kills * 4.0
  League.record_ais(h, League.ais(sim, u))
  if state.has("tour") or state.round >= 3:
   h.season_bouts = h.get("season_bouts", 0) + 1
   h.season_impact = h.get("season_impact", 0.0) + u.damage / 60.0 + u.healing / 45.0 + u.blocked / 120.0 + u.kills * 4.0
   h.season_kills = h.get("season_kills", 0) + u.kills
   h.season_damage = h.get("season_damage", 0.0) + u.damage
   h.season_healing = h.get("season_healing", 0.0) + u.healing
   h.season_blocked = h.get("season_blocked", 0.0) + u.blocked
  var base = roundi((80 if sim.winner == team else 65) * xp_scale)
  gain_xp(h, roundi(base * xp_share(h, heroes, sim, team)) if player else base, sim.winner == team, player, rng)
 # Focused reserves train on the sidelines and still earn a share.
 if player:
  for h in heroes:
   if h.slot < 0 and h.get("xp_priority", "normal") == "focus":
    gain_xp(h, roundi((80 if sim.winner == team else 65) * xp_scale * BENCH_TRAINING), sim.winner == team, player, rng)

## XP priority: the fielded squad's XP pool is shared by weight, so focusing a champion speeds them
## toward Legendary skill rolls (Lv 5+) and evolution (Lv 8) at the others' expense.
const XP_WEIGHT := {"focus": 1.6, "normal": 1.0, "rest": 0.45}
const MAX_FOCUS := 2
const BENCH_TRAINING := 0.35

func xp_share(h: Dictionary, heroes: Array, sim: BattleSim, team: int) -> float:
 var total = 0.0; var n = 0
 for u in sim.units:
  if u.team != team or u.summon: continue
  for o in heroes:
   if o.id == u.hero.id: total += XP_WEIGHT.get(o.get("xp_priority", "normal"), 1.0); n += 1
 if n == 0 or total <= 0.0: return 1.0
 return XP_WEIGHT.get(h.get("xp_priority", "normal"), 1.0) * n / total

func gain_xp(h: Dictionary, amount: int, won: bool, player: bool, rng: RandomNumberGenerator) -> void:
 h.xp += amount
 h.last_xp = amount
 while h.level < 20 and h.xp >= HeroData.xp_needed(h.level):
  h.xp -= HeroData.xp_needed(h.level); h.level += 1
  if player: HeroData.queue_reward(h, h.level, won, rng.randi())
  else:
   var cards = HeroData.choices(h, won, rng)
   h.last_offers = cards.map(func(c): return c.key)
   HeroData.apply_choice(h, cards[rng.randi_range(0, cards.size() - 1)])

func set_xp_priority(id: String, priority: String) -> bool:
 var h = hero_by_id(id)
 if h.is_empty() or not h in state.roster or not XP_WEIGHT.has(priority): return false
 if priority == "focus" and h.get("xp_priority", "normal") != "focus" and state.roster.filter(func(o): return o.get("xp_priority", "normal") == "focus").size() >= MAX_FOCUS:
  last_error = "Only %d champions can be focused at once." % MAX_FOCUS; return false
 h.xp_priority = priority
 return save()

## Saved formations: up to three named presets of who starts and where.
const FORMATION_SLOTS := 3
func save_formation(index: int) -> bool:
 if index < 0 or index >= FORMATION_SLOTS: return false
 if not state.has("formations") or not state.formations is Array: state.formations = []
 while state.formations.size() < FORMATION_SLOTS: state.formations.append({})
 var slots = {}
 for h in lineup(): slots[h.id] = int(h.slot)
 state.formations[index] = {"name": "Formation %d" % (index + 1), "slots": slots}
 return save()

func load_formation(index: int) -> bool:
 var list = state.get("formations", [])
 if index < 0 or index >= list.size() or list[index].is_empty(): last_error = "Nothing saved in that slot yet."; return false
 var slots: Dictionary = list[index].slots
 var keep = state.roster.filter(func(h): return slots.has(h.id))
 if keep.size() < MIN_SQUAD: last_error = "Some champions from that formation have left the guild."; return false
 for h in state.roster: h.slot = int(slots[h.id]) if slots.has(h.id) else -1
 return save()

func record_club(club: Dictionary, outcome: int) -> void:
 if outcome == 0: club.wins += 1
 elif outcome == 1: club.losses += 1
 else: club.draws += 1

func resolve(sim: BattleSim) -> bool:
 if state.has("tour"): return WorldTour.resolve(self,sim)
 if not sim.finished or sim.battle_seed != match_seed() or int(state.get("resolved_seed", -1)) == match_seed(): return false
 RunDatabase.capture(self,sim,"player","season_%d_round_%d"%[int(state.season),int(state.round)])
 state.resolved_seed = match_seed()
 var rng = RandomNumberGenerator.new(); rng.seed = match_seed() + 801
 var reward = 110 if sim.winner == 0 else 80 if sim.winner == -1 else 70
 state.gold += reward; state.earned_gold += reward
 var rows = sim.report_rows()
 record_team(state.roster, sim, 0, true, rng)
 record_club(state, sim.winner)
 state.report = {"winner": sim.winner, "gold": reward, "duration": sim.time, "rows": rows, "opponent": opponent().name, "round": state.round}
 state.report.season = state.season
 state.archive.append(state.report.duplicate(true))
 add_news("%s · %s" % ["Victory" if sim.winner == 0 else "Draw" if sim.winner == -1 else "Defeat", opponent().name], "%d gold earned. %d heroes have level-up choices waiting." % [reward, pending_heroes().size()])
 if state.round >= 3:
  if sim.winner == 0: state.league_wins += 1
  elif sim.winner == 1: state.league_losses += 1
  else: state.league_draws += 1
  var rival = opponent()
  record_team(rival.roster, sim, 1, false, rng)
  record_club(rival, 1 - sim.winner if sim.winner >= 0 else -1)
  for pair in state.schedule[state.round - 3]:
   if pair.has(0): continue
   var ca = state.clubs[int(pair[0]) - 1]; var cb = state.clubs[int(pair[1]) - 1]
   var background = BattleSim.new()
   background.silent = true
   background.setup(ca.roster, cb.roster, match_seed() + int(pair[0]))
   while not background.finished: background.step(0.1)
   RunDatabase.capture(self,background,"cpu","season_%d_round_%d_pair_%d"%[int(state.season),int(state.round),int(pair[0])])
   record_team(ca.roster, background, 0, false, rng); record_team(cb.roster, background, 1, false, rng)
   record_club(ca, background.winner); record_club(cb, 1 - background.winner if background.winner >= 0 else -1)
 state.round += 1
 return save()

func new_season() -> bool:
 if state.round < 17 or not pending_heroes().is_empty(): return false
 var leaders = standings()
 if leaders[0].name == state.name: state.trophies += 1; state.gold += 400
 state.history.append({"season": state.season, "wins": state.wins, "losses": state.losses, "champion": leaders[0].name})
 state.season += 1; state.round = 3; state.report = {}
 state.wins = 0; state.losses = 0; state.draws = 0
 state.league_wins = 0; state.league_losses = 0; state.league_draws = 0
 for c in state.clubs: c.wins = 0; c.losses = 0; c.draws = 0
 var heroes = state.roster.duplicate()
 for c in state.clubs: heroes.append_array(c.roster)
 for h in heroes:
  for key in ["season_bouts", "season_impact", "season_kills", "season_damage", "season_healing", "season_blocked"]: h[key] = 0
 add_news("Season %d begins" % state.season, "Your roster and learned abilities carry forward. The league table starts fresh.")
 return save()

func standings() -> Array:
 var rows = [{"name": state.name, "wins": state.get("league_wins", 0), "losses": state.get("league_losses", 0), "draws": state.get("league_draws", 0)}]
 rows.append_array(state.clubs.duplicate(true))
 rows.sort_custom(func(a, b): return a.wins * 3 + a.draws > b.wins * 3 + b.draws)
 return rows

func leaders() -> Array:
 var all = []
 for h in state.roster:
  if h.bouts > 0: all.append({"name": h.name, "species": h.sp, "club": state.name, "impact": h.impact / h.bouts, "bouts": h.bouts, "kills": h.kills})
 for c in state.clubs:
  for h in c.roster:
   if h.bouts > 0: all.append({"name": h.name, "species": h.sp, "club": c.name, "impact": h.impact / h.bouts, "bouts": h.bouts, "kills": h.kills})
 all.sort_custom(func(a, b): return a.impact > b.impact)
 return all

static func save_path(slot: int) -> String:
 return "user://campaign_%d.json" % slot

## Every champion in the league answers to a name of its own.
func ensure_unique_names() -> void:
 var taken = {}
 var groups = [state.get("roster", []), state.get("market", [])]
 for cl in state.get("clubs", []): groups.append(cl.get("roster", []))
 for group in groups:
  for h in group:
   var n = str(h.get("name", ""))
   if n == "" or taken.has(n):
    var k = abs(hash(str(h.get("id", "")) + "|name"))
    var pool: Array = HeroData.SPECIES_NAMES.get(str(h.get("sp", "")), HeroData.NAMES)
    var found = false
    for step in range(pool.size()):
     var cand = str(pool[(k + step * 7) % pool.size()])
     if not taken.has(cand): n = cand; found = true; break
    if not found:
     # Pool exhausted: add a numeral (Frezi II, Frezi III, ...).
     var root = str(pool[k % pool.size()])
     for r in ["II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]:
      if not taken.has(root + " " + r): n = root + " " + r; break
    h.name = n
   taken[n] = true

func save() -> bool:
 if state.is_empty(): return false
 if state.get("speedrun_memory",false):return true
 ensure_unique_names()
 if not state.get("speedrun_lab",false):TrophyVault.sync(self)
 var path = "user://speedrun_draft.json" if state.get("speedrun_lab",false) else save_path(int(state.slot))
 var f = FileAccess.open(path + ".tmp", FileAccess.WRITE)
 if f == null: last_error = "Could not save. Your current campaign is still open."; return false
 f.store_string(JSON.stringify(state)); f.close()
 if FileAccess.file_exists(path):
  var err = DirAccess.copy_absolute(path, path + ".backup")
  if err != OK: last_error = "Could not create the save backup."; return false
 var error = DirAccess.rename_absolute(path + ".tmp", path)
 last_error = "" if error == OK else "Could not finish saving the campaign."
 if error == OK and not state.get("speedrun_lab",false) and not RunDatabase.flush(self):last_error="Campaign saved; Atlas write is pending and will retry on the next save."
 return error == OK

static func valid(data: Variant) -> bool:
 if data is Dictionary and data.has("tour"):
  var t=data.tour
  if not t is Dictionary:return false
  if int(t.get("level",0))<1 or int(t.get("level",99))>20 or int(t.get("bout",-1))<0 or int(t.get("bout",99))>16:return false
  if not t.get("stock") is Array or not t.get("history") is Array or not t.get("shop") is bool:return false
 return data is Dictionary and data.get("version", 0) == SAVE_VERSION and data.get("roster") is Array and data.get("clubs") is Array and data.get("schedule") is Array and data.get("name") is String and data.get("round", -1) >= 0 and data.get("round", 99) <= 17

func load_slot(slot: int) -> bool:
 var path = save_path(slot)
 if not FileAccess.file_exists(path): return false
 var data = JSON.parse_string(FileAccess.get_file_as_string(path))
 if not valid(data):
  if FileAccess.file_exists(path + ".backup"): data = JSON.parse_string(FileAccess.get_file_as_string(path + ".backup"))
  if not valid(data): last_error = "This save cannot be read. Its files have been kept."; return false
 state = data; state.slot = slot
 HeroData.run_salt = str(state.get("salt", state.get("seed", "")))
 League.run_tiers = state.get("tiers", {}) if state.get("tiers") is Dictionary else {}
 ensure_management()
 return true

# New management fields are additive, so existing 0.3 campaign slots still load.
func ensure_management() -> void:
 if not state.get("speedrun_lab",false):TrophyVault.sync(self)
 for h in state.get("roster",[])+state.get("market",[]):
  h.erase("copies");h.erase("copy_feedback")
 for cl in state.get("clubs",[]):
  for h in cl.roster:h.erase("copies");h.erase("copy_feedback")
 if not state.has("headliner") or not state.roster.any(func(h):return h.id==state.headliner):
  state.headliner=state.roster[0].id if not state.roster.is_empty() else ""
 if state.has("tour"):
  if state.tour.stock.any(func(v): return not v is String): state.tour.stock = WorldTour.stock(self) if state.tour.shop else []
  state.tour.rerolls=int(state.tour.get("rerolls",0))
 for h in state.roster + state.market: HeroData.migrate_progression(h)
 for club in state.clubs:
  for h in club.roster:
   HeroData.migrate_progression(h)
   while not h.pending.is_empty():
    HeroData.apply_choice(h, h.pending[0][0]); h.pending.pop_front(); h.rewards.pop_front(); HeroData.materialize_reward(h)
 for key in ["archive", "news", "inventory"]:
  if not state.has(key): state[key] = []
 if int(state.get("league_version", 0)) < 1:
  # Older clubs: rebuild the draft board and redraft the league around the new headliner tiers.
  create_market()
  if not state.roster.is_empty(): draft_rivals()
  if state.has("tour"): state.tour.erase("bracket"); state.tour.bout = 0
  state.league_version = 1
 if int(state.get("forge_version", 0)) < 1:
  # The old gear catalogue is retired: every legacy item becomes a Forge component.
  var conv = func(old: String) -> String: return old if Forge.valid(old) else Forge.COMPONENT_ORDER[abs(hash(old)) % Forge.COMPONENT_ORDER.size()]
  state.inventory = state.inventory.map(func(i): return conv.call(str(i)))
  for h in state.roster + state.get("reserves", []):
   var old_items = h.get("equipment", {}).values()
   h.equipment = {}
   for i in range(mini(old_items.size(), Forge.SLOTS)): h.equipment[str(i)] = conv.call(str(old_items[i]))
  state.forge_version = 1
 if not state.has("management_version"):
  if not state.report.is_empty() and state.archive.is_empty():
   var old = state.report.duplicate(true); old.season = state.season; state.archive.append(old)
  state.management_version = 1

func add_news(title: String, detail: String) -> void:
 if not state.has("news"): state.news = []
 state.news.push_front({"title": title, "detail": detail, "season": state.season, "round": state.round})
 if state.news.size() > 40: state.news.resize(40)

## Sell a champion back for half of what it cost. Its items go to the bag. The headliner can't be sold.
func sell_price(h: Dictionary) -> int:
 return roundi(float(int(h.get("price", League.cost(h.sp)))+int(h.get("copy_gold",0))) * 0.5)

func sell(id: String) -> bool:
 if not recruitment_open():last_error="Keep your current roster until the cup finishes.";return false
 var h = hero_by_id(id)
 if h.is_empty() or h not in state.roster: last_error = "That champion isn't in your guild."; return false
 if id == str(state.get("headliner", "")): last_error = "Your headliner can't be sold. Make another champion headliner first."; return false
 var refund = sell_price(h)
 for v in h.get("equipment", {}).values(): state.inventory.append(str(v))
 if not h.get("equipment",{}).is_empty():state.bag_unread=true
 state.roster.erase(h); state.gold += refund
 for f in state.get("formations", []):
  if f is Dictionary and f.has("slots"): f.slots.erase(id)
 add_news("Released · " + h.name, "%s left the guild for %d gold." % [h.name, refund])
 return save()

func bench(id: String) -> bool:
 var h = hero_by_id(id)
 if h.is_empty() or h not in state.roster: return false
 h.slot = -1
 return save()

func suggest_lineup() -> bool:
 var pool = state.roster.duplicate()
 pool.sort_custom(func(a, b): return HeroData.power(a) > HeroData.power(b))
 var picks = []
 for lane in ["Front", "Front", "Flank", "Back", "Back"]:
  var options = pool.filter(func(h): return HeroData.line(h.sp) == lane)
  if not options.is_empty(): picks.append(options[0]); pool.erase(options[0])
 while picks.size() < mini(5, state.roster.size()): picks.append(pool.pop_front())
 for h in state.roster: h.slot = -1
 for p in picks: p.slot = 0
 return standard_formation()

func season_leaders(metric: String = "impact", per_bout: bool = true) -> Array:
 var rows = []
 var clubs = [{"name": state.name, "roster": state.roster}] + state.clubs
 for club in clubs:
  for h in club.roster:
   var bouts = int(h.get("season_bouts", 0))
   if bouts == 0: continue
   var total = float(h.get("season_" + metric, 0))
   rows.append({"hero": h, "club": club.name, "bouts": bouts, "score": total / bouts if per_bout else total})
 rows.sort_custom(func(a, b): return a.score > b.score)
 return rows

const EQUIPMENT = [
 {
  "id": "claw",
  "name": "Iron Claw Caps",
  "slot": "claw",
  "price": 60,
  "level": 1,
  "rarity": "Common",
  "role": "Shield breaker",
  "art": "basic",
  "description": "Basic attacks against shields deal an extra 35% attack to the shield.",
  "tip": "Counters shields; no bonus against exposed health.",
  "attack": 0.03,
  "category": "Carry"
 },
 {
  "id": "barding",
  "name": "Leather Barding",
  "slot": "armor",
  "price": 60,
  "level": 1,
  "rarity": "Common",
  "role": "Opening guard",
  "art": "ward",
  "description": "Start combat with a 12% maximum-health shield for 5 seconds.",
  "tip": "Frontline opener; wasted if contact comes too late.",
  "hp": 0.04,
  "category": "Tank"
 },
 {
  "id": "scale",
  "name": "Scale Barding",
  "slot": "armor",
  "price": 150,
  "level": 1,
  "rarity": "Common",
  "role": "Duelist defense",
  "art": "bulwark",
  "description": "Take 12% less damage from basic attacks.",
  "tip": "Counters attack carries; does not reduce spells.",
  "hp": 0.04,
  "category": "Tank"
 },
 {
  "id": "totem",
  "name": "Hunter’s Totem",
  "slot": "charm",
  "price": 120,
  "level": 1,
  "rarity": "Common",
  "role": "Pack support",
  "art": "rally",
  "description": "On casting, shield the nearest other ally within 4m for 5% of your maximum health. 6s cooldown.",
  "tip": "Stay beside a carry; cannot shield its wearer.",
  "speed": 0.05,
  "category": "Support"
 },
 {
  "id": "thornmail",
  "name": "Briar Carapace",
  "slot": "armor",
  "price": 180,
  "level": 2,
  "rarity": "Rare",
  "role": "Retaliation",
  "art": "roots",
  "description": "After taking a basic hit, retaliate for 30% attack as magic damage. 2s cooldown.",
  "tip": "Punishes attackers; spell damage never triggers it.",
  "hp": 0.06,
  "category": "Tank"
 },
 {
  "id": "emberfang",
  "name": "Ember Fangs",
  "slot": "claw",
  "price": 200,
  "level": 2,
  "rarity": "Rare",
  "role": "Healing denial",
  "art": "fire",
  "description": "Damaging basic hits inflict Scorch: 35% less healing for 3s.",
  "tip": "Hunt healers’ targets; does not stack with more Fangs.",
  "attack": 0.06,
  "category": "Carry"
 },
 {
  "id": "tideheart",
  "name": "Tideheart Pearl",
  "slot": "charm",
  "price": 220,
  "level": 3,
  "rarity": "Rare",
  "role": "Healer’s ward",
  "art": "renew",
  "description": "Effective healing on another ally grants a shield equal to 25% of that heal, capped at 6% of their maximum health. 2s cooldown.",
  "tip": "Needs real healing; overhealing and self-heals do not trigger.",
  "hp": 0.05,
  "category": "Support"
 },
 {
  "id": "frostplate",
  "name": "Froststeel Barding",
  "slot": "armor",
  "price": 260,
  "level": 4,
  "rarity": "Rare",
  "role": "Melee disruption",
  "art": "frost",
  "description": "Once below 40% health, slow enemies within 3m for 3s and gain a 12% maximum-health shield.",
  "tip": "Once per battle; enemies can finish you with a lethal hit.",
  "hp": 0.08,
  "category": "Tank"
 },
 {
  "id": "sunclaw",
  "name": "Sovereign Talons",
  "slot": "claw",
  "price": 400,
  "level": 5,
  "rarity": "Legendary",
  "role": "Finisher",
  "art": "execute",
  "description": "Basic hits against enemies below 35% health deal an extra 45% attack as magic damage. 2s cooldown.",
  "tip": "Pick weakened targets; no bonus against healthy enemies.",
  "attack": 0.08,
  "category": "Flank"
 },
 {
  "id": "starheart",
  "name": "Astral Heart",
  "slot": "charm",
  "price": 420,
  "level": 6,
  "rarity": "Legendary",
  "role": "Spell cycling",
  "art": "storm",
  "description": "Resolving a learned ability removes 1.5s from signature cooldown. 4s cooldown.",
  "tip": "Needs learned spells; never bypasses a windup.",
  "hp": 0.05,
  "category": "Carry"
 },
 {
  "id": "crownguard",
  "name": "Crownwarden Plate",
  "slot": "armor",
  "price": 440,
  "level": 7,
  "rarity": "Legendary",
  "role": "Emergency recovery",
  "art": "guardian",
  "description": "Once below 30% health, cleanse stun, root and silence and gain a 22% maximum-health shield.",
  "tip": "Once per battle; cannot prevent a lethal hit.",
  "hp": 0.1,
  "category": "Tank"
 },
 {
  "id": "windstep",
  "name": "Windstep Charm",
  "slot": "charm",
  "price": 110,
  "level": 1,
  "rarity": "Common",
  "role": "Freedom of movement",
  "art": "gust",
  "description": "Stuns, roots and slows applied to the wearer last 30% less time.",
  "tip": "Helps mobile hunters; silence duration is unchanged.",
  "hp": 0.04,
  "category": "Flank"
 },
 {
  "id": "spellguard",
  "name": "Spellguard Mantle",
  "slot": "armor",
  "price": 150,
  "level": 1,
  "rarity": "Common",
  "category": "Tank",
  "art": "ward",
  "role": "Spell defense",
  "description": "Take 12% less magical damage.",
  "tip": "Basic attacks bypass this protection.",
  "trigger": "mitigation",
  "effect": "magic_guard",
  "condition": "always",
  "proc_cd": 6,
  "value": 0.0,
  "hp": 0.04
 },
 {
  "id": "rampart",
  "name": "Rampart Sigil",
  "slot": "charm",
  "price": 220,
  "level": 2,
  "rarity": "Rare",
  "category": "Tank",
  "art": "bulwark",
  "role": "Cast and brace",
  "description": "Resolving a skill grants a 6% maximum-health shield. 6s cooldown.",
  "tip": "Needs time to finish a cast.",
  "trigger": "cast",
  "effect": "self_ward",
  "condition": "always",
  "proc_cd": 6,
  "value": 0.06,
  "hp": 0.03
 },
 {
  "id": "anchor",
  "name": "Anchor Chains",
  "slot": "claw",
  "price": 200,
  "level": 2,
  "rarity": "Rare",
  "category": "Tank",
  "art": "roots",
  "role": "Pin an attacker",
  "description": "After a damaging basic hit from an enemy within 3m, root them for 0.6s. 10s cooldown.",
  "tip": "Ranged attackers outside 3m stay free.",
  "trigger": "hurt_basic",
  "effect": "root",
  "condition": "close",
  "proc_cd": 10,
  "value": 0.6,
  "attack": 0.03
 },
 {
  "id": "laststand",
  "name": "Laststand Talisman",
  "slot": "charm",
  "price": 240,
  "level": 3,
  "rarity": "Rare",
  "category": "Tank",
  "art": "renew",
  "role": "Survival recovery",
  "description": "After taking damage below 40% health, heal 5% maximum health. 8s cooldown.",
  "tip": "Cannot rescue a lethal hit; healing reduction applies.",
  "trigger": "hurt",
  "effect": "self_heal",
  "condition": "low40",
  "proc_cd": 8,
  "value": 0.05,
  "hp": 0.03
 },
 {
  "id": "breakwater",
  "name": "Breakwater Plate",
  "slot": "armor",
  "price": 260,
  "level": 4,
  "rarity": "Rare",
  "category": "Tank",
  "art": "shellup",
  "role": "Burst response",
  "description": "Survive a hit worth at least 12% maximum health to gain an 8% health shield. 8s cooldown.",
  "tip": "Small hits do not trigger it.",
  "trigger": "hurt",
  "effect": "self_ward",
  "condition": "burst",
  "proc_cd": 8,
  "value": 0.08,
  "hp": 0.04
 },
 {
  "id": "defiance",
  "name": "Defiance Horn",
  "slot": "claw",
  "price": 360,
  "level": 5,
  "rarity": "Legendary",
  "category": "Tank",
  "art": "prideroar",
  "role": "Outnumbered guard",
  "description": "When damaged with 2+ enemies within 3m, weaken the attacker for 2s. 8s cooldown.",
  "tip": "Needs a crowded frontline; weaken does not stack.",
  "trigger": "hurt",
  "effect": "weaken",
  "condition": "outnumbered",
  "proc_cd": 8,
  "value": 2,
  "attack": 0.03
 },
 {
  "id": "wardstone",
  "name": "Wardstone Standard",
  "slot": "charm",
  "price": 400,
  "level": 6,
  "rarity": "Legendary",
  "category": "Tank",
  "art": "guardian",
  "role": "Opening escort",
  "description": "At combat start, shield the two nearest allies within 4m for 6% of your maximum health.",
  "tip": "Cannot shield its wearer; shields expire after 5s.",
  "trigger": "opening",
  "effect": "escort",
  "condition": "always",
  "proc_cd": 10000,
  "value": 0.06,
  "hp": 0.03
 },
 {
  "id": "ambushknife",
  "name": "Ambush Knife",
  "slot": "claw",
  "price": 220,
  "level": 2,
  "rarity": "Rare",
  "category": "Flank",
  "art": "ambush",
  "role": "Isolated prey",
  "description": "Basic hits on an enemy with no ally within 3m deal 45% attack bonus magic damage. 4s cooldown.",
  "tip": "Enemy formations can deny the bonus.",
  "trigger": "basic",
  "effect": "damage",
  "condition": "isolated",
  "proc_cd": 4,
  "value": 0.45,
  "attack": 0.03
 },
 {
  "id": "duskveil",
  "name": "Duskveil Cloak",
  "slot": "armor",
  "price": 110,
  "level": 1,
  "rarity": "Common",
  "category": "Flank",
  "art": "vanish",
  "role": "Entry protection",
  "description": "Your first damaging basic hit grants an 8% maximum-health shield.",
  "tip": "Once per fight; survives contact instead of the march.",
  "trigger": "basic",
  "effect": "self_ward",
  "condition": "always",
  "proc_cd": 10000,
  "value": 0.08,
  "hp": 0.04
 },
 {
  "id": "hookblade",
  "name": "Hookblade",
  "slot": "claw",
  "price": 120,
  "level": 1,
  "rarity": "Common",
  "category": "Flank",
  "art": "gore",
  "role": "Backline pursuit",
  "description": "Basic hits on a ranged enemy slow them for 1.5s. 5s cooldown.",
  "tip": "No effect against melee opponents.",
  "trigger": "basic",
  "effect": "slow",
  "condition": "ranged_target",
  "proc_cd": 5,
  "value": 1.5,
  "attack": 0.03
 },
 {
  "id": "silencepin",
  "name": "Silence Pin",
  "slot": "charm",
  "price": 380,
  "level": 5,
  "rarity": "Legendary",
  "category": "Flank",
  "art": "silence",
  "role": "Disrupt a caster",
  "description": "Resolving a skill silences your current enemy target within 4m for 1.2s. 10s cooldown.",
  "tip": "Requires a nearby living target; cannot skip windups.",
  "trigger": "cast",
  "effect": "silence",
  "condition": "within4",
  "proc_cd": 10,
  "value": 1.2,
  "hp": 0.03
 },
 {
  "id": "nightleech",
  "name": "Nightleech Fang",
  "slot": "claw",
  "price": 240,
  "level": 3,
  "rarity": "Rare",
  "category": "Flank",
  "art": "drain",
  "role": "Duel sustain",
  "description": "Basic hits on isolated enemies heal 30% of actual damage dealt. 4s cooldown.",
  "tip": "Only effective health damage counts.",
  "trigger": "basic",
  "effect": "damage_heal",
  "condition": "isolated",
  "proc_cd": 4,
  "value": 0.3,
  "attack": 0.03
 },
 {
  "id": "pursuit",
  "name": "Pursuit Talon",
  "slot": "claw",
  "price": 210,
  "level": 2,
  "rarity": "Rare",
  "category": "Flank",
  "art": "skystrike",
  "role": "Opening pressure",
  "description": "Basic hits against enemies still above 75% health deal 40% attack bonus magic damage. 3s cooldown.",
  "tip": "Stops working as the target weakens.",
  "trigger": "basic",
  "effect": "damage",
  "condition": "healthy_target",
  "proc_cd": 3,
  "value": 0.4,
  "attack": 0.03
 },
 {
  "id": "crescent",
  "name": "Crescent Spurs",
  "slot": "charm",
  "price": 250,
  "level": 4,
  "rarity": "Rare",
  "category": "Flank",
  "art": "gust",
  "role": "Break free",
  "description": "Resolving a skill clears your roots and slows. 8s cooldown.",
  "tip": "Cannot remove stun or silence to start a cast.",
  "trigger": "cast",
  "effect": "self_cleanse",
  "condition": "snared",
  "proc_cd": 8,
  "value": 0.0,
  "hp": 0.03
 },
 {
  "id": "smoke",
  "name": "Smokeweave",
  "slot": "armor",
  "price": 400,
  "level": 6,
  "rarity": "Legendary",
  "category": "Flank",
  "art": "vanish",
  "role": "Emergency escape",
  "description": "Survive damage below 30% health to gain 1.2s stealth and a 5% health shield.",
  "tip": "Once per fight; existing projectiles can still hit.",
  "trigger": "hurt",
  "effect": "escape",
  "condition": "low30",
  "proc_cd": 10000,
  "value": 0.05,
  "hp": 0.04
 },
 {
  "id": "duelist",
  "name": "Duelist Seal",
  "slot": "charm",
  "price": 260,
  "level": 3,
  "rarity": "Rare",
  "category": "Flank",
  "art": "threefold",
  "role": "Stay on target",
  "description": "Every third damaging basic hit on the same target deals 35% attack bonus magic damage. 3s cooldown.",
  "tip": "Changing target resets the hit count.",
  "trigger": "basic",
  "effect": "damage",
  "condition": "third_same",
  "proc_cd": 3,
  "value": 0.35,
  "hp": 0.03
 },
 {
  "id": "shade",
  "name": "Shadeguard",
  "slot": "armor",
  "price": 230,
  "level": 2,
  "rarity": "Rare",
  "category": "Flank",
  "art": "ward",
  "role": "Ranged entry",
  "description": "Survive a hit from beyond 3m to gain a 10% maximum-health shield. 8s cooldown.",
  "tip": "Protection begins after the triggering hit.",
  "trigger": "hurt",
  "effect": "self_ward",
  "condition": "distant",
  "proc_cd": 8,
  "value": 0.1,
  "hp": 0.04
 },
 {
  "id": "steadybow",
  "name": "Steadyshot Bow",
  "slot": "claw",
  "price": 130,
  "level": 1,
  "rarity": "Common",
  "category": "Carry",
  "art": "barrage",
  "role": "Attack rhythm",
  "description": "Every third damaging basic hit deals 35% attack bonus magic damage. 3s cooldown.",
  "tip": "Spell hits do not build the counter.",
  "trigger": "basic",
  "effect": "damage",
  "condition": "third",
  "proc_cd": 3,
  "value": 0.35,
  "attack": 0.03
 },
 {
  "id": "longshot",
  "name": "Longshot Lens",
  "slot": "charm",
  "price": 220,
  "level": 2,
  "rarity": "Rare",
  "category": "Carry",
  "art": "beam",
  "role": "Keep your distance",
  "description": "Basic hits from at least 4m deal 25% attack bonus magic damage. 3s cooldown.",
  "tip": "Melee pressure denies the bonus.",
  "trigger": "basic",
  "effect": "damage",
  "condition": "long_range",
  "proc_cd": 3,
  "value": 0.25,
  "hp": 0.03
 },
 {
  "id": "giantbane",
  "name": "Giantbane Arrow",
  "slot": "claw",
  "price": 270,
  "level": 4,
  "rarity": "Rare",
  "category": "Carry",
  "art": "execute",
  "role": "Anti-tank",
  "description": "Basic hits on enemies with 25% more maximum health deal 2% of their maximum health as magic damage, capped at 70% attack. 4s cooldown.",
  "tip": "No proc on smaller enemies.",
  "trigger": "basic",
  "effect": "giant_damage",
  "condition": "giant",
  "proc_cd": 4,
  "value": 0.02,
  "attack": 0.03
 },
 {
  "id": "echoedge",
  "name": "Echo Edge",
  "slot": "claw",
  "price": 400,
  "level": 5,
  "rarity": "Legendary",
  "category": "Carry",
  "art": "foxfire",
  "role": "Weave attacks",
  "description": "A resolved learned skill primes your next basic hit within 5s for 60% attack bonus magic damage. 6s cooldown.",
  "tip": "Must weave an attack between skills.",
  "trigger": "basic",
  "effect": "damage",
  "condition": "spell_primed",
  "proc_cd": 6,
  "value": 0.6,
  "attack": 0.03
 },
 {
  "id": "focuslens",
  "name": "Focus Lens",
  "slot": "charm",
  "price": 230,
  "level": 3,
  "rarity": "Rare",
  "category": "Carry",
  "art": "focus",
  "role": "Focused fire",
  "description": "Every third basic hit on the same target recovers 1s of signature cooldown. 4s cooldown.",
  "tip": "Target changes reset the sequence.",
  "trigger": "basic",
  "effect": "self_cooldown",
  "condition": "third_same",
  "proc_cd": 4,
  "value": 1,
  "hp": 0.03
 },
 {
  "id": "stormwire",
  "name": "Stormwire",
  "slot": "claw",
  "price": 420,
  "level": 6,
  "rarity": "Legendary",
  "category": "Carry",
  "art": "chain",
  "role": "Cleave a cluster",
  "description": "Basic hits arc to one other enemy within 3m of the target for 35% attack magic damage. 4s cooldown.",
  "tip": "Deals no bonus to the original target.",
  "trigger": "basic",
  "effect": "chain",
  "condition": "secondary",
  "proc_cd": 4,
  "value": 0.35,
  "attack": 0.03
 },
 {
  "id": "runic",
  "name": "Runic Capacitor",
  "slot": "charm",
  "price": 240,
  "level": 2,
  "rarity": "Rare",
  "category": "Carry",
  "art": "storm",
  "role": "Spell follow-through",
  "description": "Resolving a skill zaps your current target within 5m for 25% attack magic damage. 6s cooldown.",
  "tip": "Needs a living target in range.",
  "trigger": "cast",
  "effect": "damage",
  "condition": "within5",
  "proc_cd": 6,
  "value": 0.25,
  "hp": 0.03
 },
 {
  "id": "siege",
  "name": "Siege Pennant",
  "slot": "charm",
  "price": 200,
  "level": 2,
  "rarity": "Rare",
  "category": "Carry",
  "art": "rally",
  "role": "Crack defenses",
  "description": "Basic hits against a shield grant Rally for 1.5s. 6s cooldown.",
  "tip": "Rally does not stack with other Rally sources.",
  "trigger": "shield_hit",
  "effect": "self_rally",
  "condition": "always",
  "proc_cd": 6,
  "value": 1.5,
  "hp": 0.03
 },
 {
  "id": "lifeline",
  "name": "Lifeline Harness",
  "slot": "armor",
  "price": 380,
  "level": 5,
  "rarity": "Legendary",
  "category": "Carry",
  "art": "ward",
  "role": "Carry insurance",
  "description": "Survive damage below 35% health to gain a 14% maximum-health shield.",
  "tip": "Once per battle; not protection against a lethal hit.",
  "trigger": "hurt",
  "effect": "self_ward",
  "condition": "low35",
  "proc_cd": 10000,
  "value": 0.14,
  "hp": 0.04
 },
 {
  "id": "mercybell",
  "name": "Mercy Bell",
  "slot": "charm",
  "price": 130,
  "level": 1,
  "rarity": "Common",
  "category": "Support",
  "art": "renew",
  "role": "Combat medic",
  "description": "On casting, heal the most wounded other ally within 5m for 4% of your maximum health. 6s cooldown.",
  "tip": "Must finish a cast near an injured ally.",
  "trigger": "cast",
  "effect": "ally_heal",
  "condition": "wounded_ally",
  "proc_cd": 6,
  "value": 0.04,
  "hp": 0.04
 },
 {
  "id": "cleanser",
  "name": "Cleansing Incense",
  "slot": "charm",
  "price": 240,
  "level": 2,
  "rarity": "Rare",
  "category": "Support",
  "art": "radiance",
  "role": "Cleanse a teammate",
  "description": "Effective healing on another ally clears their stun, root and silence. 6s cooldown.",
  "tip": "Needs effective healing and removable control.",
  "trigger": "heal",
  "effect": "ally_cleanse",
  "condition": "controlled",
  "proc_cd": 6,
  "value": 0.0,
  "hp": 0.04
 },
 {
  "id": "rallybanner",
  "name": "Rally Banner",
  "slot": "claw",
  "price": 240,
  "level": 3,
  "rarity": "Rare",
  "category": "Support",
  "art": "rally",
  "role": "Empower recovery",
  "description": "Effective healing on another ally grants them Rally for 2s. 6s cooldown.",
  "tip": "No self-buff; Rally does not stack.",
  "trigger": "heal",
  "effect": "ally_rally",
  "condition": "always",
  "proc_cd": 6,
  "value": 2,
  "hp": 0.04
 },
 {
  "id": "echochalice",
  "name": "Echo Chalice",
  "slot": "charm",
  "price": 260,
  "level": 4,
  "rarity": "Rare",
  "category": "Support",
  "art": "rootbloom",
  "role": "Spread recovery",
  "description": "Healing another ally also heals one injured ally within 3m of them for 30% of actual healing, capped at 4% recipient maximum health. 4s cooldown.",
  "tip": "Cannot echo back to the original target or caster.",
  "trigger": "heal",
  "effect": "echo_heal",
  "condition": "echo_target",
  "proc_cd": 4,
  "value": 0.3,
  "hp": 0.04
 },
 {
  "id": "lantern",
  "name": "Guardian Lantern",
  "slot": "armor",
  "price": 220,
  "level": 2,
  "rarity": "Rare",
  "category": "Support",
  "art": "ward",
  "role": "Protect the wounded",
  "description": "On casting, shield the most wounded other ally within 5m below 50% health for 8% of your maximum health. 8s cooldown.",
  "tip": "Healthy allies do not consume the trigger.",
  "trigger": "cast",
  "effect": "ally_ward",
  "condition": "critical_ally",
  "proc_cd": 8,
  "value": 0.08,
  "hp": 0.04
 },
 {
  "id": "pilgrim",
  "name": "Pilgrim Medal",
  "slot": "armor",
  "price": 110,
  "level": 1,
  "rarity": "Common",
  "category": "Support",
  "art": "tailwind",
  "role": "Opening blessing",
  "description": "At combat start, grant the nearest other ally within 4m Rally for 2.5s.",
  "tip": "Once per fight; arrange allies for early contact.",
  "trigger": "opening",
  "effect": "opening_rally",
  "condition": "near_ally",
  "proc_cd": 10000,
  "value": 2.5,
  "hp": 0.04
 },
 {
  "id": "rescuecord",
  "name": "Rescue Cord",
  "slot": "armor",
  "price": 360,
  "level": 5,
  "rarity": "Legendary",
  "category": "Support",
  "art": "renew",
  "role": "Parting recovery",
  "description": "Survive damage below 35% health to heal the most wounded other ally within 5m for 8% of your maximum health.",
  "tip": "Once per battle; helps an ally, not its wearer.",
  "trigger": "hurt",
  "effect": "ally_heal",
  "condition": "low35_ally",
  "proc_cd": 10000,
  "value": 0.08,
  "hp": 0.04
 },
 {
  "id": "frostcensor",
  "name": "Frost Censer",
  "slot": "claw",
  "price": 180,
  "level": 2,
  "rarity": "Rare",
  "category": "Support",
  "art": "frost",
  "role": "Protect through pressure",
  "description": "Damaging basic hits weaken the enemy for 2s. 6s cooldown.",
  "tip": "Requires attacking; weaken does not stack.",
  "trigger": "basic",
  "effect": "weaken",
  "condition": "always",
  "proc_cd": 6,
  "value": 2,
  "hp": 0.04
 },
 {
  "id": "hourglass",
  "name": "Kindred Hourglass",
  "slot": "charm",
  "price": 420,
  "level": 6,
  "rarity": "Legendary",
  "category": "Support",
  "art": "focus",
  "role": "Enable an ally",
  "description": "Effective healing on another ally recovers 1s of their signature cooldown. 6s cooldown.",
  "tip": "No benefit when their signature is already ready.",
  "trigger": "heal",
  "effect": "ally_cooldown",
  "condition": "cooling",
  "proc_cd": 6,
  "value": 1,
  "hp": 0.04
 },
 {
  "id": "concord",
  "name": "Concord Staff",
  "slot": "claw",
  "price": 400,
  "level": 5,
  "rarity": "Legendary",
  "category": "Support",
  "art": "guardian",
  "role": "Paired protection",
  "description": "On casting, shield yourself and the nearest other ally within 4m for 4% of your maximum health. 8s cooldown.",
  "tip": "Requires another ally nearby.",
  "trigger": "cast",
  "effect": "paired_ward",
  "condition": "near_ally",
  "proc_cd": 8,
  "value": 0.04,
  "hp": 0.04
 }
]

func buy_item(index: int) -> bool:
 # Outfitter offers are positions in state.tour.stock (component or finished item ids).
 if not state.has("tour") or not state.tour.shop or index < 0 or index >= state.tour.stock.size(): return false
 var id = str(state.tour.stock[index]); var item = Forge.info(id)
 if item.is_empty() or id == "": last_error = "That offer is sold out."; return false
 if state.gold < item.price: last_error = "Not enough gold."; return false
 var before=state.duplicate(true)
 state.gold -= item.price; state.inventory.append(id); state.tour.stock[index] = ""
 state.bag_unread=true
 if save(): return true
 state=before;return false

func free_slot(h: Dictionary) -> String:
 for i in range(HeroData.item_slots(h)):
  if not h.get("equipment", {}).has(str(i)): return str(i)
 return ""

## TFT rules: a component dropped on a champion holding a loose component forges them together.
func place_item(h: Dictionary, item_id: String) -> String:
 if not h.has("equipment"): h.equipment = {}
 if Forge.is_component(item_id):
  for k in h.equipment:
   if Forge.is_component(str(h.equipment[k])):
    var made = Forge.combine(str(h.equipment[k]), item_id)
    if made != "": h.equipment[k] = made; return k
 var slot = free_slot(h)
 if slot == "": last_error = "%s already carries three items. Unequip one first." % h.name; return ""
 h.equipment[slot] = item_id
 return slot

func equip(id: String, item_id: String) -> bool:
 var h = hero_by_id(id)
 if h.is_empty() or h not in state.roster or not state.inventory.has(item_id) or not Forge.valid(item_id): return false
 var before=state.duplicate(true)
 state.inventory.erase(item_id)
 if place_item(h, item_id) == "": state=before; return false
 if save():return true
 state=before;return false

func unequip(id: String, slot: String) -> bool:
 var h = hero_by_id(id)
 if h.is_empty() or h not in state.roster or not h.get("equipment", {}).has(slot): return false
 var before=state.duplicate(true)
 state.inventory.append(h.equipment[slot]); h.equipment.erase(slot)
 state.bag_unread=true
 if save():return true
 state=before;return false

## Forge two components from the bag into a finished item.
func forge_bag(a: String, b: String) -> String:
 var made = Forge.combine(a, b)
 if made == "" or not state.inventory.has(a) or not state.inventory.has(b) or (a == b and state.inventory.count(a) < 2): return ""
 var before = state.duplicate(true)
 state.inventory.erase(a); state.inventory.erase(b); state.inventory.append(made)
 state.bag_unread=true
 if save(): return made
 state = before; return ""

func set_tactics(id: String, values: Dictionary) -> bool:
 var hero = hero_by_id(id)
 if hero.is_empty(): return false
 var previous = hero.get("tactics", {}).duplicate(true)
 hero.tactics = BattleTactics.normalized(values)
 if save(): return true
 hero.tactics = previous
 return false

func reroll_shop() -> bool:
 if not state.has("tour") or not state.tour.shop: return false
 var cost=25+15*int(state.tour.get("rerolls",0))
 if state.gold<cost: return false
 var before=state.duplicate(true)
 state.gold-=cost;state.tour.rerolls=int(state.tour.get("rerolls",0))+1
 state.tour.stock=WorldTour.stock(self)
 if save(): return true
 state=before;return false

func sell_item(item_id: String) -> bool:
 if not state.has("tour") or not state.tour.shop or item_id not in state.inventory: return false
 var item=Forge.info(item_id)
 if item.is_empty(): return false
 var before=state.duplicate(true)
 state.inventory.erase(item_id);state.gold+=int(item.price/2)
 if save(): return true
 state=before;return false

func buy_and_equip(index: int, id: String) -> bool:
 if not state.has("tour") or not state.tour.shop or index < 0 or index >= state.tour.stock.size(): return false
 var h=hero_by_id(id); var item_id = str(state.tour.stock[index]); var item = Forge.info(item_id)
 if h.is_empty() or h not in state.roster or item.is_empty(): return false
 if state.gold<item.price: last_error = "Not enough gold."; return false
 var before=state.duplicate(true)
 if place_item(h, item_id) == "":
  # No room on this champion: the purchase goes to the bag instead of failing.
  state = before; last_error = ""
  if buy_item(index): last_error = "bag"; return true
  return false
 state.gold-=item.price;state.tour.stock[index]=""
 if save():return true
 state=before;return false

func transfer_item(from_id: String,to_id: String,slot: String,target_slot: String="") -> bool:
 if from_id==to_id:return false
 var source=hero_by_id(from_id);var target=hero_by_id(to_id)
 if source not in state.roster or target not in state.roster:return false
 var item_id=str(source.get("equipment",{}).get(slot,""))
 if item_id.is_empty():return false
 var before=state.duplicate(true)
 if target_slot in GearUI.slot_keys(target):
  var displaced=str(target.get("equipment",{}).get(target_slot,""))
  if displaced!="":source.equipment[slot]=displaced
  else:source.equipment.erase(slot)
  target.equipment[target_slot]=item_id
  if save():return true
  state=before;return false
 source.equipment.erase(slot)
 if place_item(target, item_id) == "": state = before; return false
 if save():return true
 state=before;return false

func headliner() -> Dictionary:
 for h in state.get("roster",[]):
  if h.id==state.get("headliner",""):return h
 return state.roster[0] if not state.get("roster",[]).is_empty() else {}

## The eight Legendary headliners for this run, rolled once (trait + stat genes) so the
## signing screen shows the exact champion you'd get.
func legend_pool() -> Dictionary:
 if not state.has("legends") or not state.legends is Dictionary or state.legends.is_empty():
  state.legends={}
  for sp in League.tiers().Legendary:
   var h=HeroData.make_hero(sp,"h%d"%state.next_id,HeroData.themed_name(sp,"h%d"%state.next_id));state.next_id+=1
   h.price=League.cost(sp);state.legends[sp]=h
 return state.legends

func choose_starter(sp: String) -> bool:
 if not state.roster.is_empty() or not HeroData.species.has(sp) or League.tier(sp)!="Legendary":last_error="Choose one of the eight Legendary headliners.";return false
 if state.gold<League.cost(sp):last_error="Not enough gold.";return false
 var before=state.duplicate(true)
 var hero={}
 for h in state.market:
  if h.sp==sp:hero=h;break
 if hero.is_empty() and legend_pool().has(sp):hero=legend_pool()[sp];state.legends.erase(sp)
 elif not hero.is_empty():state.market.erase(hero)
 if hero.is_empty():
  hero=HeroData.make_hero(sp,"h%d"%state.next_id,HeroData.themed_name(sp,"h%d"%state.next_id));state.next_id+=1
 hero.slot=standard_slot(hero,[]);hero.price=League.cost(sp);state.roster.append(hero)
 state.headliner=hero.id;state.selected=hero.id;state.gold-=hero.price
 draft_rivals()
 add_news("Your headliner",hero.name+" leads "+state.name+" into the arena.")
 if save():return true
 state=before;return false

## Draft the seven rival clubs around the headliners the player did not take.
func draft_rivals() -> void:
 var mine = state.roster.map(func(h): return h.sp)
 var free = League.tiers().Legendary.filter(func(sp): return sp not in mine)
 var rng = RandomNumberGenerator.new(); rng.seed = int(state.seed) + 4242
 for i in range(free.size() - 1, 0, -1):
  var j = rng.randi_range(0, i); var tmp = free[i]; free[i] = free[j]; free[j] = tmp
 state.clubs = []
 for i in range(7):
  state.clubs.append(League.draft_club(CLUBS[i], free[i % free.size()], rng, "r%d" % i))
 League.week_snapshot(self)
 add_news("Draft day", "Seven rival clubs built their teams around: " + ", ".join(state.clubs.map(func(cl): return HeroData.species[cl.roster.filter(func(h): return h.id == cl.headliner)[0].sp].n)) + ".")

func set_headliner(id: String) -> bool:
 if not state.roster.any(func(h):return h.id==id):return false
 var previous=state.get("headliner","");state.headliner=id
 if save():return true
 state.headliner=previous;return false
