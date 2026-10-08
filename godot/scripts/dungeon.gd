class_name Dungeon
extends RefCounted
## Dungeon mode: a branching descent in the spirit of The Last Flame (and Slay the Spire). Your guild
## crosses three depths. Each depth is a map of rooms (skirmishes, elites, outfitters, campfires,
## unknown events and treasure) that ends at a Warden. You choose a path one room at a time.
## The guild carries a handful of flames: every lost fight snuffs one out, and when the last one
## goes out the run ends. Rewards are picked from three offers after each win, like card rewards.
##
## The run reuses the guild run's systems: state.tour still drives the outfitter, rival growth and
## recruit boards, but its level is set by how deep you are instead of by a cup bracket.

const ACTS := 3
const ROWS := 8                 # seven rooms, then the Warden
const FLAMES := {"Keeper": 4, "Standard": 3, "Champion": 2}
const XP_SCALE := 2.6           # fewer fights than the five cups, so each one teaches more
const CAMP_XP := 120
const DEPTHS := [
 {"name": "The Rootbound Halls", "region": 0, "warden": "Warden of Roots", "text": "Old roots split the stone. Beasts that heal as fast as they bleed lurk in the dark."},
 {"name": "The Cinder Vaults", "region": 1, "warden": "Warden of Embers", "text": "Sealed forges still burn here. The fire-born guard what the smiths left behind."},
 {"name": "The Starless Deep", "region": 5, "warden": "Keeper of the Last Flame", "text": "No light reaches this far down except the flame you carry. Keep it alive."},
]
const ROOMS := {
 "battle":   {"name": "Skirmish", "glyph": "swords", "color": "e8c27a", "text": "A pack of dungeon beasts. Win to pick one of three components."},
 "elite":    {"name": "Elite", "glyph": "star", "color": "ff8a7a", "text": "A rival guild lost in the dark. Hard fight; win to pick one of three finished items."},
 "shop":     {"name": "Outfitter", "glyph": "coin", "color": "c8ff9d", "text": "A hidden merchant. Buy and forge gear, then move on."},
 "rest":     {"name": "Campfire", "glyph": "flame", "color": "ffb35c", "text": "Rekindle a lost flame or train the squad."},
 "event":    {"name": "Unknown", "glyph": "roll", "color": "b9a2ff", "text": "Something waits in the dark. Choose how to face it."},
 "treasure": {"name": "Treasure", "glyph": "trophy", "color": "ffd36e", "text": "A sealed chest: gold and a component of your choice."},
 "boss":     {"name": "Warden", "glyph": "skull", "color": "ff5a6a", "text": "The guardian of this depth. Defeat it to descend. Losing costs a flame and you must try again."},
}
const PACKS := ["Gloomfang Pack", "Hollow Brood", "Mire Stalkers", "Bone Choir", "Vault Sentries", "Ashen Swarm", "Lantern Eaters", "Cinder Hounds", "Deepcrawlers", "Shade Coven"]
const EVENTS := [
 {"id": "smith", "title": "The Wandering Smith", "text": "A hooded smith works a portable anvil by candlelight. \"Coin for craft,\" she says.",
  "choices": [{"label": "Commission a piece · 90 gold", "detail": "Pick one of three finished items.", "gold": -90, "loot": "item"}, {"label": "Ask for scraps", "detail": "Gain a random component.", "component": 1}]},
 {"id": "shrine", "title": "The Ember Shrine", "text": "A shrine of black glass hungers for light. Offer it some of yours and it gives back in kind.",
  "choices": [{"label": "Feed it a flame", "detail": "Lose 1 flame. Pick one of three finished items.", "flames": -1, "loot": "item"}, {"label": "Pray quietly", "detail": "Your fielded champions gain 60 XP.", "xp": 60}]},
 {"id": "caravan", "title": "The Lost Caravan", "text": "A merchant's wagon lies overturned. Its owners are long gone.",
  "choices": [{"label": "Take the strongbox", "detail": "+110 gold.", "gold": 110}, {"label": "Take the crates", "detail": "Gain two random components.", "component": 2}]},
 {"id": "mentor", "title": "A Mentor's Ghost", "text": "The ghost of an old beast-keeper offers one lesson before it fades.",
  "choices": [{"label": "Teach the headliner", "detail": "Your headliner gains 240 XP.", "headliner_xp": 240}, {"label": "Teach everyone", "detail": "Your fielded champions gain 80 XP.", "xp": 80}]},
 {"id": "hoard", "title": "The Cursed Hoard", "text": "Gold piled to the ceiling, and a cold wind that guards it.",
  "choices": [{"label": "Fill your packs", "detail": "+220 gold, but lose 1 flame.", "gold": 220, "flames": -1}, {"label": "Leave it be", "detail": "Nothing happens."}]},
 {"id": "hearth", "title": "The Hearth Spirit", "text": "A small, warm spirit circles your torch and purrs.",
  "choices": [{"label": "Let it join your flame", "detail": "Rekindle 1 flame.", "flames": 1}, {"label": "Trade it to a collector", "detail": "+70 gold.", "gold": 70}]},
 {"id": "gamble", "title": "The Masked Gambler", "text": "\"Double or nothing on a single toss?\" The coin is already spinning.",
  "choices": [{"label": "Bet 80 gold", "detail": "Even odds: win 160 gold or lose your stake.", "gamble": 80}, {"label": "Walk away", "detail": "Nothing happens."}]},
]

static func active(c: Campaign) -> bool:
 return not c.state.is_empty() and c.state.get("mode", "") == "dungeon" and c.state.has("dungeon")

static func start(c: Campaign) -> void:
 var flames = int(FLAMES.get(str(c.state.get("difficulty", "Standard")), 3))
 c.state.mode = "dungeon"
 c.state.dungeon = {"act": 1, "row": -1, "col": -1, "flames": flames, "max_flames": flames, "fight": false, "loot": [], "loot_kind": "", "event": {}, "fights": 0, "wins": 0, "elites": 0, "rooms": 0, "history": [], "map": [], "trail": []}
 c.state.dungeon.map = generate(c, 1)
 sync_level(c)
 c.add_news("Into the dungeon", "Three depths, three Wardens. Your guild carries %d flame%s: every lost fight snuffs one out." % [flames, "" if flames == 1 else "s"])

static func depth(c: Campaign) -> Dictionary:
 return DEPTHS[clampi(int(c.state.dungeon.act) - 1, 0, ACTS - 1)]

static func region(c: Campaign) -> Dictionary:
 var r = WorldTour.REGIONS[int(depth(c).region)].duplicate()
 r.name = depth(c).name; r.place = depth(c).name
 return r

## Tour level follows how far down the guild is, so rival levels, gear and pricing grow
## across the whole descent the same way they grow across five cups.
static func sync_level(c: Campaign) -> void:
 var d = c.state.dungeon
 var progress = (int(d.act) - 1) * ROWS + maxi(0, int(d.row))
 c.state.tour.level = clampi(1 + progress * WorldTour.MAX_LEVEL / (ACTS * ROWS), 1, WorldTour.MAX_LEVEL)
 c.state.tour.bout = 0

# ------------------------------------------------------------------ Map
static func generate(c: Campaign, act: int) -> Array:
 var rng = RandomNumberGenerator.new(); rng.seed = hash(str(c.state.seed) + "|dungeon|" + str(act))
 var rows = []
 for r in range(ROWS):
  var count = 1 if r == ROWS - 1 else (3 if r == 0 else rng.randi_range(2, 4))
  var row = []
  for i in range(count): row.append({"type": room_type(rng, r), "links": [], "done": false})
  rows.append(row)
 # Every depth holds at least one elite before its Warden.
 if not rows.slice(2, ROWS - 2).any(func(row): return row.any(func(n): return n.type == "elite")):
  var er = rng.randi_range(4, ROWS - 3); rows[er][rng.randi_range(0, rows[er].size() - 1)].type = "elite"
 for r in range(ROWS - 1):
  var here = rows[r]; var next = rows[r + 1]
  for i in range(here.size()):
   var x = (i + 0.5) / here.size()
   var nearest = clampi(int(x * next.size()), 0, next.size() - 1)
   here[i].links.append(nearest)
   if next.size() > 1 and rng.randf() < 0.55:
    var other = clampi(nearest + (1 if rng.randf() < 0.5 else -1), 0, next.size() - 1)
    if other not in here[i].links: here[i].links.append(other)
  # Every room in the next row must be reachable.
  for j in range(next.size()):
   if not here.any(func(n): return j in n.links):
    var best = clampi(int((j + 0.5) / next.size() * here.size()), 0, here.size() - 1)
    here[best].links.append(j)
  for n in here: n.links.sort()
 return rows

static func room_type(rng: RandomNumberGenerator, r: int) -> String:
 if r == ROWS - 1: return "boss"
 if r == 0: return "battle"
 if r == 3: return "treasure"
 if r == ROWS - 2: return "rest"
 var roll = rng.randf()
 if r >= 2 and roll < 0.16: return "elite"
 if roll < 0.30: return "event"
 if roll < 0.42: return "shop"
 if r >= 2 and roll < 0.50: return "rest"
 return "battle"

static func node(c: Campaign, row: int = -99, col: int = -99) -> Dictionary:
 var d = c.state.dungeon
 if row == -99: row = int(d.row); col = int(d.col)
 if row < 0 or row >= d.map.size() or col < 0 or col >= d.map[row].size(): return {}
 return d.map[row][col]

## Rooms the guild can step into next.
static func reachable(c: Campaign) -> Array:
 var d = c.state.dungeon
 if busy(c): return []
 if int(d.row) < 0: return range(d.map[0].size())
 if int(d.row) >= ROWS - 1: return []
 return node(c).get("links", [])

## Something must be settled before moving: a fight, loot to pick, an event or the outfitter.
static func busy(c: Campaign) -> bool:
 var d = c.state.dungeon
 return d.fight or not d.loot.is_empty() or not d.event.is_empty() or c.state.tour.get("shop", false) or c.state.tour.get("intermission", false) or c.state.get("run_over", false) or c.state.tour.get("complete", false)

static func enter(c: Campaign, col: int) -> String:
 var d = c.state.dungeon
 if col not in reachable(c): c.last_error = "That room is not on your path."; return ""
 var before = c.state.duplicate(true)
 d.row = int(d.row) + 1; d.col = col; d.rooms = int(d.rooms) + 1
 if not d.has("trail") or int(d.row) == 0: d.trail = []
 d.trail.append(col)
 sync_level(c)
 var n = node(c); var kind = str(n.type)
 match kind:
  "battle", "elite", "boss":
   d.fight = true
   if kind != "battle": WorldTour.outfit_clubs(c)
  "shop":
   n.done = true; c.state.tour.shop = true; c.state.tour.rerolls = 0; c.state.tour.serial = int(c.state.tour.serial) + 1; c.state.tour.stock = WorldTour.stock(c)
  "rest":
   d.event = {"id": "rest", "title": "Campfire", "text": "The squad huddles around a small fire. There is time for one thing.",
    "choices": [{"label": "Rekindle", "detail": "Restore 1 flame (%d / %d)." % [int(d.flames), int(d.max_flames)], "flames": 1, "disabled": int(d.flames) >= int(d.max_flames)}, {"label": "Train", "detail": "Fielded champions gain %d XP." % CAMP_XP, "xp": CAMP_XP}]}
  "event":
   var rng = RandomNumberGenerator.new(); rng.seed = hash(str(c.state.seed) + "|event|%d|%d|%d" % [int(d.act), int(d.row), col])
   var e = EVENTS[rng.randi_range(0, EVENTS.size() - 1)].duplicate(true)
   for ch in e.choices:
    if int(ch.get("flames", 0)) < 0 and int(d.flames) <= 1: ch.disabled = true; ch.detail += " (your last flame cannot be spent)"
    if int(ch.get("gold", 0)) < 0 and int(c.state.gold) < -int(ch.gold): ch.disabled = true
    if int(ch.get("gamble", 0)) > int(c.state.gold): ch.disabled = true
    if int(ch.get("flames", 0)) > 0 and int(d.flames) >= int(d.max_flames): ch.disabled = true
   d.event = e
  "treasure":
   n.done = true
   var gold = 60 + 20 * int(d.act); c.state.gold += gold; c.state.earned_gold += gold
   offer_loot(c, "component", 3)
   c.add_news("Treasure", "The chest held %d gold and a component of your choice." % gold)
 if c.save(): return kind
 c.state = before; return ""

# ------------------------------------------------------------------ Rewards, events, campfires
static func offer_loot(c: Campaign, kind: String, count: int) -> void:
 var d = c.state.dungeon
 var rng = RandomNumberGenerator.new(); rng.seed = hash(str(c.state.seed) + "|loot|%d|%d|%d|%s" % [int(d.act), int(d.row), int(c.state.tour.serial), kind])
 var pool = Forge.COMPONENT_ORDER.duplicate() if kind == "component" else Forge.ITEMS.keys()
 var picks = []
 while picks.size() < count and not pool.is_empty():
  var id = pool[rng.randi_range(0, pool.size() - 1)]; pool.erase(id); picks.append(id)
 d.loot = picks; d.loot_kind = kind

static func take_loot(c: Campaign, index: int) -> bool:
 var d = c.state.dungeon
 if index < 0 or index >= d.loot.size(): return false
 var before = c.state.duplicate(true)
 var id = str(d.loot[index]); c.state.inventory.append(id); c.state.bag_unread = true
 d.loot = []; d.loot_kind = ""
 c.add_news("Spoils", "%s goes into the bag." % Forge.info(id).get("name", id))
 if c.save(): return true
 c.state = before; return false

static func skip_loot(c: Campaign) -> bool:
 var d = c.state.dungeon
 if d.loot.is_empty(): return false
 var before = c.state.duplicate(true)
 d.loot = []; d.loot_kind = ""; c.state.gold += 25; c.state.earned_gold += 25
 if c.save(): return true
 c.state = before; return false

static func choose_event(c: Campaign, index: int) -> String:
 var d = c.state.dungeon
 if d.event.is_empty() or index < 0 or index >= d.event.choices.size(): return ""
 var ch = d.event.choices[index]
 if ch.get("disabled", false): c.last_error = "You cannot choose that right now."; return ""
 var before = c.state.duplicate(true)
 var rng = RandomNumberGenerator.new(); rng.seed = hash(str(c.state.seed) + "|choice|%d|%d|%d" % [int(d.act), int(d.row), index])
 var outcome = str(ch.detail)
 if ch.has("gold"):
  c.state.gold = maxi(0, int(c.state.gold) + int(ch.gold))
  if int(ch.gold) > 0: c.state.earned_gold += int(ch.gold)
 if ch.has("flames"): d.flames = clampi(int(d.flames) + int(ch.flames), 0, int(d.max_flames))
 if ch.has("gamble"):
  var won = rng.randf() < 0.5
  c.state.gold += int(ch.gamble) if won else -int(ch.gamble)
  outcome = "The coin lands your way: +%d gold." % int(ch.gamble) if won else "The coin betrays you: -%d gold." % int(ch.gamble)
 for i in range(int(ch.get("component", 0))):
  var id = Forge.COMPONENT_ORDER[rng.randi_range(0, Forge.COMPONENT_ORDER.size() - 2)]
  c.state.inventory.append(id); c.state.bag_unread = true
 if ch.has("xp"):
  for h in c.lineup(): c.gain_xp(h, int(ch.xp), true, true, rng)
 if ch.has("headliner_xp") and not c.headliner().is_empty(): c.gain_xp(c.headliner(), int(ch.headliner_xp), true, true, rng)
 var n = node(c)
 if not n.is_empty(): n.done = true
 c.add_news(str(d.event.title), outcome)
 d.event = {}
 if ch.has("loot"): offer_loot(c, str(ch.loot), 3)
 if c.save(): return outcome
 c.state = before; return ""

# ------------------------------------------------------------------ Opponents
static func quality(c: Campaign) -> float:
 var d = c.state.dungeon; var t = c.state.tour
 var base = TourBalance.quality(int(t.level), mini(3, maxi(0, int(d.row)) / 2), str(c.state.difficulty)) * (1.0 + 0.02 * clampi(int(c.state.get("challenge_rank", 0)), 0, 10))
 var kind = str(fight_node(c).get("type", "battle"))
 var mult = {"battle": 0.97, "elite": 1.06, "boss": 1.10}.get(kind, 1.0)
 if kind == "battle" and int(d.act) == 1 and int(d.row) <= 0: mult = 0.92
 return base * mult

## The room whose fight is pending, or the first fight on the path ahead (for scouting).
static func fight_node(c: Campaign) -> Dictionary:
 var d = c.state.dungeon
 if d.fight: return node(c)
 return {}

static func preview_position(c: Campaign) -> Vector2i:
 var d = c.state.dungeon
 if d.fight: return Vector2i(int(d.row), int(d.col))
 var options = reachable(c) if not busy(c) else []
 for col in options:
  if str(d.map[int(d.row) + 1][col].type) in ["battle", "elite", "boss"]: return Vector2i(int(d.row) + 1, col)
 if not options.is_empty(): return Vector2i(int(d.row) + 1, options[0])
 return Vector2i(maxi(0, int(d.row)), maxi(0, int(d.col)))

static func opponent(c: Campaign) -> Dictionary:
 var p = preview_position(c)
 var n = node(c, p.x, p.y)
 var kind = str(n.get("type", "battle"))
 if kind == "elite": return guild_at(c, p.x, p.y, false)
 if kind == "boss": return guild_at(c, p.x, p.y, true)
 return pack(c, p.x, p.y)

static func guild_at(c: Campaign, row: int, col: int, boss: bool) -> Dictionary:
 if c.state.clubs.size() < 7: c.draft_rivals()
 var index = 0
 if boss:
  var order = range(1, c.state.clubs.size() + 1)
  order.sort_custom(func(x, y): return League.team_ovr(WorldTour.club(c, x).roster) > League.team_ovr(WorldTour.club(c, y).roster))
  index = order[clampi(ACTS - int(c.state.dungeon.act), 0, order.size() - 1)]
 else:
  index = 1 + abs(hash(str(c.state.seed) + "|elite|%d|%d|%d" % [int(c.state.dungeon.act), row, col])) % c.state.clubs.size()
 var cl = WorldTour.club(c, index)
 var title = "%s · %s" % [cl.name, depth(c).warden] if boss else "%s (lost in the dark)" % cl.name
 return {"name": title, "roster": cl.roster, "practice": false, "club": index}

static func pack(c: Campaign, row: int, col: int) -> Dictionary:
 var d = c.state.dungeon; var t = c.state.tour
 var rng = RandomNumberGenerator.new(); rng.seed = hash(str(c.state.seed) + "|pack|%d|%d|%d" % [int(d.act), row, col])
 var home = WorldTour.REGIONS[int(depth(c).region)]
 var pool = home.roster + WorldTour.REGIONS[(int(depth(c).region) + 1 + int(d.act)) % WorldTour.REGIONS.size()].roster
 var size = 4 if int(d.act) == 1 and row <= 1 else 5
 var st = WorldTour.stage(c); var diff = str(c.state.get("difficulty", "Standard"))
 var heroes = []
 for i in range(size):
  var sp = pool[rng.randi_range(0, pool.size() - 1)]
  var id = "dg_%d_%d_%d_%d" % [int(d.act), row, col, i]
  var level = TourBalance.level(int(t.level), diff, id)
  var h = HeroData.make_hero(sp, id, HeroData.themed_name(sp, id), level)
  h.slot = Campaign.FORMATION[i]
  for k in range(mini(3, maxi(0, level - 1))): h.learned[str(k)] = 2 if level >= 8 else 1
  if level >= 5: h.signature_rank = 2
  var tier = TourBalance.rarity(st, diff, id)
  h.skill_rarity = {"0": tier}; h.ability_bonus_0 = 1.25 if tier == "Legendary" else 1.1 if tier == "Rare" else 1.0
  h.equipment = Forge.rival_loadout(h, st, diff)
  if level >= HeroData.EVOLVE_LEVEL: h.evolution = "%s:%d" % [sp, i % 3]
  heroes.append(h)
 return {"name": PACKS[abs(hash(str(c.state.seed) + str(row) + str(col) + str(d.act))) % PACKS.size()], "roster": heroes, "practice": false}

static func stage_label(c: Campaign) -> String:
 var d = c.state.dungeon
 if c.state.tour.get("complete", false): return "The Last Flame endures"
 if c.state.get("run_over", false): return "The flame has gone out"
 if c.state.tour.get("intermission", false): return "Descending to depth %d" % int(d.act)
 if int(d.row) < 0: return "Choose your first room"
 var n = node(c)
 var room = str(ROOMS.get(str(n.get("type", "battle")), {}).get("name", "Room"))
 return "Room %d of %d · %s" % [int(d.row) + 1, ROWS, room]

# ------------------------------------------------------------------ Fights
static func resolve(c: Campaign, sim: BattleSim) -> bool:
 var d = c.state.dungeon; var t = c.state.tour
 if not d.fight or t.get("complete", false) or not sim.finished or sim.battle_seed != c.match_seed(): return false
 var before = c.state.duplicate(true)
 var n = node(c); var kind = str(n.type); var rival = opponent(c); var r = region(c)
 RunDatabase.capture(c, sim, "player", "dungeon_%d" % int(t.serial))
 var rng = RandomNumberGenerator.new(); rng.seed = c.match_seed() + 801
 var won = sim.winner == 0
 var base_gold = TourBalance.match_gold(int(t.level), str(c.state.difficulty), won)
 var reward = roundi(base_gold * ({"battle": 0.55, "elite": 0.85, "boss": 1.3}.get(kind, 0.6) if won else 0.35))
 c.record_team(c.state.roster, sim, 0, true, rng, XP_SCALE); c.record_club(c.state, sim.winner)
 if rival.has("club"):
  var cl = WorldTour.club(c, int(rival.club))
  c.record_team(cl.roster, sim, 1, false, rng); c.record_club(cl, 1 if won else 0 if sim.winner == 1 else -1)
 var report = {"winner": sim.winner, "gold": reward, "duration": sim.time, "rows": sim.report_rows(), "opponent": rival.name, "round": t.serial, "season": c.state.season, "tour_level": t.level, "location": r.place, "bout": int(d.fights) + 1, "stage": "%s · Room %d" % [ROOMS[kind].name, int(d.row) + 1], "dungeon": true, "room": kind}
 report.ais = sim.units.filter(func(u): return not u.summon).map(func(u): return {"uid": u.uid, "team": u.team, "name": u.hero.name, "sp": u.hero.sp, "ais": League.ais(sim, u), "ovr": League.ovr(u.hero), "power": HeroData.power(u.hero)})
 t.serial = int(t.serial) + 1; t.cup_started = true; d.fights = int(d.fights) + 1
 if won:
  d.wins = int(d.wins) + 1; n.done = true; d.fight = false
  if kind == "elite": d.elites = int(d.elites) + 1
  if kind == "battle": offer_loot(c, "component", 3)
  else: offer_loot(c, "item", 3)
  if kind == "boss":
   report.warden_down = true
   d.history.append({"act": int(d.act), "name": depth(c).name, "fights": int(d.fights), "flames": int(d.flames)})
   t.history.append({"level": int(d.act), "location": depth(c).name, "wins": int(d.wins), "attempt": 1, "promoted": true, "place": 1})
   # Every Warden drops a chest: bronze, silver, then gold for the deepest.
   var medal = ["Bronze", "Silver", "Gold"][clampi(int(d.act) - 1, 0, 2)]
   TrophyVault.award(c, medal); report.chest = true; report.medal = medal
   if int(d.act) >= ACTS:
    t.complete = true; c.state.trophies = int(c.state.trophies) + 1; report.dungeon_cleared = true
    c.add_news("The Last Flame endures", "%s conquered all three depths with %d flame%s left." % [c.state.name, int(d.flames), "" if int(d.flames) == 1 else "s"])
   else:
    d.flames = mini(int(d.max_flames), int(d.flames) + 1)
    for h in c.lineup(): c.gain_xp(h, TourBalance.TRAINING_XP, true, true, rng)
    d.act = int(d.act) + 1; d.row = -1; d.col = -1; d.trail = []; d.map = generate(c, int(d.act)); sync_level(c)
    t.intermission = true; t.erase("intermission_seen"); c.state.market_wave = int(c.state.get("market_wave", 0)) + 1; c.create_market()
    c.add_news("Warden defeated", "The way down to %s is open. One flame rekindles, the squad trains, and new recruits wait at the stairs." % depth(c).name)
 else:
  d.flames = maxi(0, int(d.flames) - 1); report.flame_lost = true
  if kind != "boss": n.done = true; d.fight = false   # scorched, the guild pushes past; a Warden must be beaten
  if int(d.flames) <= 0:
   c.state.run_over = true; report.run_over = true; d.fight = false
   c.add_news("The flame goes out", "%s fell in %s, room %d." % [c.state.name, depth(c).name, int(d.row) + 1])
  else:
   c.add_news("A flame gutters", "%s lost to %s. %d flame%s remain." % [c.state.name, rival.name, int(d.flames), "" if int(d.flames) == 1 else "s"])
 report.flames = int(d.flames)
 c.state.gold += reward; c.state.earned_gold += reward
 c.state.report = report; c.state.archive.append(report.duplicate(true))
 if c.save(): return true
 c.state = before; return false
