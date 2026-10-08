class_name Dungeon
extends RefCounted
## Dungeon mode: a branching descent in the spirit of The Last Flame, Slay the Spire and Guildrun.
## Your guild crosses three depths. Each depth is a map of rooms (skirmishes, elites, outfitters,
## campfires, unknown events and treasure) that ends at a Warden boss. You choose a path one room
## at a time. The guild has a few lives: every lost fight costs one, and the run ends at zero.
## Wins offer one of three rewards: components, finished items or relics (run-long passives).
## Every species carries two run traits, re-rolled each run, that unlock team synergies.
## Clearing the third depth lets you bank your score or keep going into the endless depths.
##
## The run reuses the guild run's systems: state.tour still drives the outfitter, rival growth and
## recruit boards, but its level is set by how deep you are instead of by a cup bracket.

const ACTS := 3                 # the classic descent; endless depths continue past it
const ROWS := 8                 # seven rooms, then the Warden
const MAX_CHAMPIONS := 6       # the guild grows from headliner + partner to six
const DRAFT_SIZE := 5           # champions offered at each draft
const SLOTS := [5, 11, 7, 3, 9, 13]   # formation slots for up to six monsters
const LIVES := {"Keeper": 4, "Standard": 3, "Champion": 2}
const XP_SCALE := 2.6           # fewer fights than the five cups, so each one teaches more
const CAMP_XP := 120
const SCORES_PATH := "user://dungeon_scores.json"
const ROOMS := {
 "battle":   {"name": "Skirmish", "glyph": "swords", "color": "e8c27a", "text": "A pack of dungeon monsters. Win to pick one of three components."},
 "elite":    {"name": "Elite", "glyph": "star", "color": "ff8a7a", "text": "An alpha pack or a rival guild lost in the dark. Hard fight; win to pick one of three relics."},
 "shop":     {"name": "Outfitter", "glyph": "coin", "color": "c8ff9d", "text": "A hidden merchant. Buy and forge gear, then move on."},
 "rest":     {"name": "Campfire", "glyph": "flame", "color": "ffb35c", "text": "Rest to restore a life, or train the squad."},
 "event":    {"name": "Unknown", "glyph": "roll", "color": "b9a2ff", "text": "Something waits in the dark. Choose how to face it."},
 "checkpoint": {"name": "Checkpoint", "glyph": "banner", "color": "8fe0c0", "text": "A lost champion waits at the waystone. Choose one of five to join the guild (until you have six)."},
 "treasure": {"name": "Treasure", "glyph": "trophy", "color": "ffd36e", "text": "A sealed chest: gold and one of three finished items."},
 "boss":     {"name": "Warden", "glyph": "skull", "color": "ff5a6a", "text": "The boss of this depth. Defeat it to descend. Losing costs a life and you must try again."},
}
const EVENTS := [
 {"id": "smith", "title": "The Wandering Smith", "text": "A hooded smith works a portable anvil by candlelight. \"Coin for craft,\" she says.",
  "choices": [{"label": "Commission a piece · 90 gold", "detail": "Pick one of three finished items.", "gold": -90, "loot": "item"}, {"label": "Ask for scraps", "detail": "Gain a random component.", "component": 1}]},
 {"id": "shrine", "title": "The Black Glass Shrine", "text": "A shrine of black glass hums with power. It asks for a piece of your life in return.",
  "choices": [{"label": "Offer a life", "detail": "Lose 1 life. Pick one of three relics.", "lives": -1, "loot": "relic"}, {"label": "Pray quietly", "detail": "Your fielded champions gain 60 XP.", "xp": 60}]},
 {"id": "caravan", "title": "The Lost Caravan", "text": "A merchant's wagon lies overturned. Its owners are long gone.",
  "choices": [{"label": "Take the strongbox", "detail": "+110 gold.", "gold": 110}, {"label": "Take the crates", "detail": "Gain two random components.", "component": 2}]},
 {"id": "mentor", "title": "A Mentor's Ghost", "text": "The ghost of an old beast-keeper offers one lesson before it fades.",
  "choices": [{"label": "Teach the headliner", "detail": "Your headliner gains 240 XP.", "headliner_xp": 240}, {"label": "Teach everyone", "detail": "Your fielded champions gain 80 XP.", "xp": 80}]},
 {"id": "hoard", "title": "The Cursed Hoard", "text": "Gold piled to the ceiling, and a cold wind that guards it.",
  "choices": [{"label": "Fill your packs", "detail": "+220 gold, but lose 1 life.", "gold": 220, "lives": -1}, {"label": "Leave it be", "detail": "Nothing happens."}]},
 {"id": "spring", "title": "The Healing Spring", "text": "Clear water bubbles up between the stones. It smells of summer.",
  "choices": [{"label": "Drink deeply", "detail": "Restore 1 life.", "lives": 1}, {"label": "Fill your flasks to sell", "detail": "+70 gold.", "gold": 70}]},
 {"id": "gamble", "title": "The Masked Gambler", "text": "\"Double or nothing on a single toss?\" The coin is already spinning.",
  "choices": [{"label": "Bet 80 gold", "detail": "Even odds: win 160 gold or lose your stake.", "gamble": 80}, {"label": "Walk away", "detail": "Nothing happens."}]},
 {"id": "reliquary", "title": "The Forgotten Reliquary", "text": "Dusty shelves of trinkets, each humming faintly. A sign says: TAKE ONE. PAY WHAT IS FAIR.",
  "choices": [{"label": "Pay 120 gold", "detail": "Pick one of three relics.", "gold": -120, "loot": "relic"}, {"label": "Steal one and run", "detail": "Pick one of three relics, but lose 1 life.", "lives": -1, "loot": "relic"}, {"label": "Leave", "detail": "Nothing happens."}]},
]

static func active(c: Campaign) -> bool:
 return not c.state.is_empty() and c.state.get("mode", "") == "dungeon" and c.state.has("dungeon")

static func start(c: Campaign) -> void:
 var lives = int(LIVES.get(str(c.state.get("difficulty", "Standard")), 3))
 c.state.mode = "dungeon"
 c.state.dungeon = {"act": 1, "row": -1, "col": -1, "lives": lives, "max_lives": lives, "fight": false, "loot": [], "loot_kind": "", "loot_queue": [], "event": {}, "fights": 0, "wins": 0, "elites": 0, "wardens": 0, "rooms": 0, "history": [], "map": [], "trail": [], "relics": [], "score": 0, "endless": false, "awaiting_endless": false}
 c.state.dungeon.traits = RunTraits.roll(str(c.state.get("salt", c.state.seed)))
 c.state.dungeon.visited = []; c.state.dungeon.instance = ""
 c.state.dungeon.instance_choices = DungeonInstances.offer([], str(c.state.seed))
 sync_level(c)
 c.add_news("Into the dungeon", "Three depths, three Wardens: choose which instance to enter at each descent. Your guild has %d li%s: every lost fight costs one." % [lives, "fe" if lives == 1 else "ves"])

## Older dungeon saves called lives "flames" and had no relics, traits or score.
static func migrate(c: Campaign) -> void:
 if not active(c): return
 var d = c.state.dungeon
 if d.has("flames"): d.lives = int(d.flames); d.max_lives = int(d.max_flames); d.erase("flames"); d.erase("max_flames")
 for key in ["relics", "loot_queue"]:
  if not d.has(key): d[key] = []
 for key in ["score", "wardens"]:
  if not d.has(key): d[key] = 0
 for key in ["endless", "awaiting_endless"]:
  if not d.has(key): d[key] = false
 # Runs from before kin / element / class traits roll the new system.
 if not d.has("traits") or int(d.traits.get("version", 1)) < 2: d.traits = RunTraits.roll(str(c.state.get("salt", c.state.seed)))
 # Before themed instances, depths were fixed; give old runs the matching instance.
 if not d.has("instance"):
  d.instance = ["blight_forest", "magma_depths", "void_rift"][int(d.act) - 1] if int(d.act) <= ACTS else DungeonInstances.ORDER[(int(d.act) - 1) % DungeonInstances.ORDER.size()]
  d.visited = [d.instance]; d.instance_choices = []

## The instance the guild is in (or about to choose, while the offer is open).
static func instance_id(c: Campaign) -> String:
 var d = c.state.dungeon
 if str(d.get("instance", "")) != "": return str(d.instance)
 return str(d.get("instance_choices", ["blight_forest"])[0]) if not d.get("instance_choices", []).is_empty() else "blight_forest"

static func depth(c: Campaign) -> Dictionary:
 var act = int(c.state.dungeon.act)
 var info = DungeonInstances.info(instance_id(c)).duplicate()
 info.text = info.tagline
 info.depth_label = ("Endless depth %d" % (act - ACTS)) if act > ACTS else "Depth %d of %d" % [act, ACTS]
 return info

static func warden(c: Campaign) -> Dictionary:
 return Bestiary.BOSSES[str(DungeonInstances.info(instance_id(c)).boss)]

## The arena and banners use this like a World Tour region; "dungeon" tells the arena to dress the stage.
static func region(c: Campaign) -> Dictionary:
 var i = DungeonInstances.info(instance_id(c))
 return {"name": i.name, "place": i.name, "theme": DungeonInstances.theme_name(instance_id(c)), "color": i.accent, "floor": i.floor, "sky": i.sky, "dungeon": instance_id(c)}

static func choose_instance(c: Campaign, id: String) -> bool:
 var d = c.state.dungeon; var t = c.state.tour
 if id not in d.get("instance_choices", []): c.last_error = "That way is not open."; return false
 var before = c.state.duplicate(true)
 d.instance = id; d.visited.append(id); d.instance_choices = []
 d.map = generate(c, int(d.act)); d.row = -1; d.col = -1; d.trail = []; sync_level(c)
 if t.get("intermission", false): t.erase("intermission"); t.erase("intermission_seen"); t.cup_started = true
 c.add_news("Entering " + DungeonInstances.info(id).name, str(DungeonInstances.info(id).tagline))
 if c.save(): return true
 c.state = before; return false

## Tour level follows how far down the guild is, so rival levels, gear and pricing grow
## across the descent the same way they grow across five cups, then keep climbing in endless.
static func sync_level(c: Campaign) -> void:
 var d = c.state.dungeon
 if int(d.act) > ACTS:
  c.state.tour.level = clampi(WorldTour.MAX_LEVEL + int(d.act) - ACTS, 1, 20)
 else:
  var progress = (int(d.act) - 1) * ROWS + maxi(0, int(d.row))
  c.state.tour.level = clampi(1 + progress * WorldTour.MAX_LEVEL / (ACTS * ROWS), 1, WorldTour.MAX_LEVEL)
 c.state.tour.bout = 0

# ------------------------------------------------------------------ Map
static func generate(c: Campaign, act: int) -> Array:
 var rng = RandomNumberGenerator.new(); rng.seed = hash(str(c.state.seed) + "|dungeon|" + str(act) + "|" + str(c.state.dungeon.get("instance", "")))
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
 if r == 3: return "checkpoint"
 if r == ROWS - 2: return "rest"
 var roll = rng.randf()
 if r >= 2 and roll < 0.16: return "elite"
 if roll < 0.30: return "event"
 if roll < 0.42: return "shop"
 if r >= 2 and roll < 0.50: return "rest"
 if r >= 2 and roll < 0.57: return "treasure"
 return "battle"

static func node(c: Campaign, row: int = -99, col: int = -99) -> Dictionary:
 var d = c.state.dungeon
 if row == -99: row = int(d.row); col = int(d.col)
 if row < 0 or row >= d.map.size() or col < 0 or col >= d.map[row].size(): return {}
 return d.map[row][col]

## Rooms the guild can step into next.
static func reachable(c: Campaign) -> Array:
 var d = c.state.dungeon
 if busy(c) or d.map.is_empty(): return []
 if int(d.row) < 0: return range(d.map[0].size())
 if int(d.row) >= ROWS - 1: return []
 return node(c).get("links", [])

## Something must be settled before moving: a fight, spoils, an event, the outfitter or a choice.
static func busy(c: Campaign) -> bool:
 var d = c.state.dungeon
 return d.fight or not d.get("draft", {}).is_empty() or not d.get("instance_choices", []).is_empty() or not d.loot.is_empty() or not d.event.is_empty() or d.awaiting_endless or c.state.tour.get("shop", false) or c.state.tour.get("intermission", false) or c.state.get("run_over", false) or c.state.tour.get("complete", false)

static func enter(c: Campaign, col: int) -> String:
 var d = c.state.dungeon
 if col not in reachable(c): c.last_error = "That room is not on your path."; return ""
 var before = c.state.duplicate(true)
 d.row = int(d.row) + 1; d.col = col; d.rooms = int(d.rooms) + 1
 if not d.has("trail") or int(d.row) == 0: d.trail = []
 d.trail.append(col)
 sync_level(c)
 add_score(c, 10)
 var n = node(c); var kind = str(n.type)
 match kind:
  "battle", "elite", "boss":
   d.fight = true
   if kind == "elite": WorldTour.outfit_clubs(c)
  "shop":
   n.done = true; c.state.tour.shop = true; c.state.tour.rerolls = 0; c.state.tour.serial = int(c.state.tour.serial) + 1; c.state.tour.stock = WorldTour.stock(c)
  "rest":
   var no_rest = Relics.owned(c).any(func(r): return Relics.info(r).get("no_rest", false))
   d.event = {"id": "rest", "title": "Campfire", "text": "The squad huddles around a small fire. There is time for one thing.",
    "choices": [{"label": "Rest", "detail": ("Warlord's Horn: no rest for you." if no_rest else "Restore 1 life (%d / %d)." % [int(d.lives), int(d.max_lives)]), "lives": 1, "disabled": no_rest or int(d.lives) >= int(d.max_lives)}, {"label": "Train", "detail": "Fielded champions gain %d XP." % CAMP_XP, "xp": CAMP_XP}]}
  "event":
   var rng = RandomNumberGenerator.new(); rng.seed = hash(str(c.state.seed) + "|event|%d|%d|%d" % [int(d.act), int(d.row), col])
   var e = EVENTS[rng.randi_range(0, EVENTS.size() - 1)].duplicate(true)
   for ch in e.choices:
    if int(ch.get("lives", 0)) < 0 and int(d.lives) <= 1: ch.disabled = true; ch.detail += " (you cannot spend your last life)"
    if int(ch.get("gold", 0)) < 0 and int(c.state.gold) < -int(ch.gold): ch.disabled = true
    if int(ch.get("gamble", 0)) > int(c.state.gold): ch.disabled = true
    if int(ch.get("lives", 0)) > 0 and int(d.lives) >= int(d.max_lives): ch.disabled = true
   d.event = e
  "checkpoint":
   n.done = true
   if c.state.roster.size() < MAX_CHAMPIONS: offer_draft(c, "checkpoint", 0)
   else:
    offer_loot(c, "item"); c.add_news("Checkpoint", "Your guild is full: the waystone offers a finished item instead.")
  "treasure":
   n.done = true
   var gold = 60 + 20 * mini(int(d.act), 6); c.state.gold += gold; c.state.earned_gold += gold
   offer_loot(c, "item")
   c.add_news("Treasure", "The chest held %d gold and a finished item of your choice." % gold)
 if c.save(): return kind
 c.state = before; return ""

# ------------------------------------------------------------------ Rewards, events, campfires
## Rewards wait in a queue: the first is on screen, the rest follow once it is settled.
static func offer_loot(c: Campaign, kind: String) -> void:
 var d = c.state.dungeon
 var rng = RandomNumberGenerator.new(); rng.seed = hash(str(c.state.seed) + "|loot|%d|%d|%d|%s|%d" % [int(d.act), int(d.row), int(c.state.tour.serial), kind, d.loot_queue.size()])
 var picks = []
 if kind in ["relic", "boss_relic"]:
  picks = Relics.offer(c, rng, ["Boss"] if kind == "boss_relic" else (["Common", "Rare"] if rng.randf() < 0.6 else ["Rare"]))
  if picks.is_empty(): picks = Relics.offer(c, rng, ["Common", "Rare", "Boss"])
 else:
  var pool = Forge.COMPONENT_ORDER.duplicate() if kind == "component" else Forge.ITEMS.keys()
  pool.sort()
  while picks.size() < 3 and not pool.is_empty():
   var id = pool[rng.randi_range(0, pool.size() - 1)]; pool.erase(id); picks.append(id)
 if picks.is_empty(): return
 var entry = {"kind": "relic" if kind == "boss_relic" else kind, "choices": picks}
 if d.loot.is_empty(): d.loot = entry.choices; d.loot_kind = entry.kind
 else: d.loot_queue.append(entry)

static func next_loot(c: Campaign) -> void:
 var d = c.state.dungeon
 d.loot = []; d.loot_kind = ""
 if not d.loot_queue.is_empty():
  var entry = d.loot_queue.pop_front(); d.loot = entry.choices; d.loot_kind = entry.kind

static func take_loot(c: Campaign, index: int) -> bool:
 var d = c.state.dungeon
 if index < 0 or index >= d.loot.size(): return false
 var before = c.state.duplicate(true)
 var id = str(d.loot[index])
 if d.loot_kind == "relic":
  d.relics.append(id); add_score(c, 25)
  var r = Relics.info(id)
  if r.has("max_lives"):
   d.max_lives = maxi(1, int(d.max_lives) + int(r.max_lives))
   d.lives = clampi(int(d.lives) + maxi(0, int(r.max_lives)), 1, int(d.max_lives))
  c.add_news("Relic · " + r.name, r.text)
 else:
  c.state.inventory.append(id); c.state.bag_unread = true
  c.add_news("Spoils", "%s goes into the bag." % Forge.info(id).get("name", id))
 next_loot(c)
 if c.save(): return true
 c.state = before; return false

static func skip_loot(c: Campaign) -> bool:
 var d = c.state.dungeon
 if d.loot.is_empty(): return false
 var before = c.state.duplicate(true)
 next_loot(c); c.state.gold += 25; c.state.earned_gold += 25
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
 if ch.has("lives"): d.lives = clampi(int(d.lives) + int(ch.lives), 0, int(d.max_lives))
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
 if ch.has("loot"): offer_loot(c, str(ch.loot))
 if c.save(): return outcome
 c.state = before; return ""

# ------------------------------------------------------------------ Opponents
static func quality(c: Campaign) -> float:
 var d = c.state.dungeon; var t = c.state.tour
 var base = TourBalance.quality(int(t.level), mini(3, maxi(0, int(d.row)) / 2), str(c.state.difficulty)) * (1.0 + 0.02 * clampi(int(c.state.get("challenge_rank", 0)), 0, 10))
 var kind = str(fight_node(c).get("type", "battle"))
 var mult = {"battle": 0.97, "elite": 1.02, "boss": 1.0}.get(kind, 1.0)
 if kind == "battle" and int(d.act) == 1 and int(d.row) <= 2: mult = 0.92 if int(d.row) <= 0 else 0.94
 mult *= 1.0 + 0.05 * (mini(int(d.act), ACTS) - 1)   # each classic depth is a little meaner
 # A guild still gathering its champions fights a little softer opposition.
 mult *= minf(1.0, 0.8 + 0.04 * party(c))
 if int(d.act) > ACTS: mult *= pow(1.2, int(d.act) - ACTS)   # endless compounds, so every run ends somewhere
 return base * mult

## Run traits and relics for the player's squad. Rivals fight with their own monster stats.
static func battle_mods(c: Campaign) -> Array:
 return [Relics.mods(c) + RunTraits.mods(c, c.lineup()), []]

static func fight_node(c: Campaign) -> Dictionary:
 var d = c.state.dungeon
 if d.fight: return node(c)
 return {}

## The room whose fight is pending, or the first fight on the path ahead (for scouting).
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
 if kind == "boss": return boss_fight(c, p.x)
 if kind == "elite":
  if abs(hash(str(c.state.seed) + "|elitekind|%d|%d|%d" % [int(c.state.dungeon.act), p.x, p.y])) % 2 == 0: return guild_at(c, p.x, p.y)
  return pack(c, p.x, p.y, true)
 return pack(c, p.x, p.y, false)

static func guild_at(c: Campaign, row: int, col: int) -> Dictionary:
 if c.state.clubs.size() < 7: c.draft_rivals()
 var index = 1 + abs(hash(str(c.state.seed) + "|elite|%d|%d|%d" % [int(c.state.dungeon.act), row, col])) % c.state.clubs.size()
 var cl = WorldTour.club(c, index)
 # A lost guild sends as many champions as you field: its strongest.
 var roster = cl.roster.duplicate(); roster.sort_custom(func(a, b): return HeroData.power(a) > HeroData.power(b))
 roster = roster.slice(0, mini(roster.size(), mini(party(c), 5)))
 return {"name": "%s (lost in the dark)" % cl.name, "roster": roster, "practice": false, "club": index}

static func pack(c: Campaign, row: int, col: int, alpha: bool) -> Dictionary:
 var d = c.state.dungeon; var t = c.state.tour
 var rng = RandomNumberGenerator.new(); rng.seed = hash(str(c.state.seed) + "|pack|%d|%d|%d" % [int(d.act), row, col])
 var pool = DungeonInstances.info(instance_id(c)).mobs.duplicate()
 # Packs match the guild up to five; a sixth champion is pure advantage.
 var size = mini(party(c), 5)
 var st = WorldTour.stage(c); var diff = str(c.state.get("difficulty", "Standard"))
 var heroes = []
 for i in range(size):
  var key = pool[rng.randi_range(0, pool.size() - 1)]
  var id = "dg_%d_%d_%d_%d" % [int(d.act), row, col, i]
  var h = Bestiary.make(key, id, TourBalance.level(int(t.level), diff, id), st, diff, SLOTS[i])
  if alpha and i == 0: h.name = "Alpha " + h.name; h.vigor = int(h.get("vigor", 0)) + 3; h.force = int(h.get("force", 0)) + 2
  heroes.append(h)
 var lead = Bestiary.info(str(heroes[0].monster)).name
 var title = "%s %s" % [lead, ["Pack", "Brood", "Horde", "Swarm", "Patrol"][abs(hash(str(c.state.seed) + str(row) + str(col) + str(d.act))) % 5]]
 return {"name": ("Alpha " + title) if alpha else title, "roster": heroes, "practice": false}

## The Warden: one boss and two escorts from its depth.
static func boss_fight(c: Campaign, row: int) -> Dictionary:
 var d = c.state.dungeon; var t = c.state.tour
 var key = str(DungeonInstances.info(instance_id(c)).boss); var b = Bestiary.BOSSES[key]
 var st = WorldTour.stage(c); var diff = str(c.state.get("difficulty", "Standard"))
 var level = TourBalance.level(int(t.level), diff)
 var heroes = [Bestiary.make(key, "boss_%d" % int(d.act), level, st, diff, Campaign.FORMATION[0])]
 heroes[0].depth = mini(int(d.act), ACTS); heroes[0].party = party(c)
 # Endless Wardens return stronger each cycle instead of starting over.
 if int(d.act) > ACTS: heroes[0].empower = 0.35 * (int(d.act) - 1)
 var pool = DungeonInstances.info(instance_id(c)).mobs
 # Escorts grow with the guild: none against two or three champions, two against five or more.
 for i in range(clampi(party(c) - 3, 0, 2)):
  var id = "boss_%d_escort_%d" % [int(d.act), i]
  heroes.append(Bestiary.make(pool[abs(hash(id + str(c.state.seed))) % pool.size()], id, maxi(1, level - 1), st, diff, SLOTS[i + 3]))
 return {"name": "%s · Warden of %s" % [b.name, str(DungeonInstances.info(instance_id(c)).name).trim_prefix("The ")], "roster": heroes, "practice": false, "boss": key}

static func stage_label(c: Campaign) -> String:
 var d = c.state.dungeon
 if c.state.tour.get("complete", false): return "Run complete · %d points" % int(d.get("final_score", d.score))
 if c.state.get("run_over", false): return "Out of lives"
 if d.get("awaiting_endless", false): return "The dungeon is conquered"
 if not d.get("instance_choices", []).is_empty(): return "Choose your path"
 if int(d.row) < 0: return "Choose your first room"
 var n = node(c)
 var room = str(ROOMS.get(str(n.get("type", "battle")), {}).get("name", "Room"))
 return "Room %d of %d · %s" % [int(d.row) + 1, ROWS, room]

# ------------------------------------------------------------------ Score
## Points grow with depth: a skirmish in depth 2 is worth twice one in depth 1.
static func add_score(c: Campaign, points: int) -> void:
 var d = c.state.dungeon
 d.score = int(d.score) + points * maxi(1, int(d.act))

static func multiplier(c: Campaign) -> float:
 var diff = {"Keeper": 0.8, "Standard": 1.0, "Champion": 1.35}.get(str(c.state.get("difficulty", "Standard")), 1.0)
 return diff * (1.0 + 0.10 * clampi(int(c.state.get("challenge_rank", 0)), 0, 10))

static func final_score(c: Campaign) -> int:
 var d = c.state.dungeon
 var bonus = int(d.lives) * 150 if not c.state.get("run_over", false) else 0
 return roundi((int(d.score) + bonus) * multiplier(c))

## Lock the score into the local high-score table (once per run).
static func bank_score(c: Campaign, outcome: String) -> int:
 var d = c.state.dungeon
 if d.has("final_score"): return int(d.final_score)
 d.final_score = final_score(c); d.outcome = outcome
 var table = scores()
 table.append({"name": c.state.name, "score": int(d.final_score), "depth": int(d.act), "room": maxi(1, int(d.row) + 1), "wardens": int(d.wardens), "difficulty": str(c.state.difficulty), "challenge": int(c.state.get("challenge_rank", 0)), "outcome": outcome, "endless": d.endless, "relics": d.relics.size(), "date": Time.get_date_string_from_system(), "run_id": str(c.state.get("run_id", ""))})
 table.sort_custom(func(a, b): return int(a.score) > int(b.score))
 table = table.slice(0, 20)
 var f = FileAccess.open(SCORES_PATH, FileAccess.WRITE)
 if f: f.store_string(JSON.stringify(table)); f.close()
 return int(d.final_score)

static func scores() -> Array:
 if not FileAccess.file_exists(SCORES_PATH): return []
 var data = JSON.parse_string(FileAccess.get_file_as_string(SCORES_PATH))
 return data if data is Array else []

static func rank_of(c: Campaign) -> int:
 var id = str(c.state.get("run_id", ""))
 var table = scores()
 for i in range(table.size()):
  if str(table[i].get("run_id", "")) == id and int(table[i].score) == int(c.state.dungeon.get("final_score", -1)): return i + 1
 return 0

# ------------------------------------------------------------------ Endless
## After the third Warden: bank the score now, or keep descending for more.
static func retire(c: Campaign) -> bool:
 var before = c.state.duplicate(true)
 var d = c.state.dungeon
 d.awaiting_endless = false; c.state.tour.complete = true
 c.state.tour.erase("intermission"); c.state.tour.shop = false
 var points = bank_score(c, "Retired" if d.endless else "Conquered")
 c.add_news("Score banked", "%s left the dungeon with %d points." % [c.state.name, points])
 if c.save(): return true
 c.state = before; return false

static func go_endless(c: Campaign) -> bool:
 var d = c.state.dungeon
 if not d.awaiting_endless: return false
 var before = c.state.duplicate(true)
 d.awaiting_endless = false; d.endless = true
 descend(c)
 c.add_news("Into the endless depths", "The dungeon keeps going. Every depth is harder, and worth more points.")
 if c.save(): return true
 c.state = before; return false

static func descend(c: Campaign) -> void:
 var d = c.state.dungeon; var t = c.state.tour
 var rng = RandomNumberGenerator.new(); rng.seed = hash(str(c.state.seed) + "|descend|%d" % int(d.act))
 d.lives = mini(int(d.max_lives), int(d.lives) + 1)
 for h in c.lineup(): c.gain_xp(h, TourBalance.TRAINING_XP, true, true, rng)
 d.act = int(d.act) + 1; d.row = -1; d.col = -1; d.trail = []; d.map = []; sync_level(c)
 d.instance = ""; d.instance_choices = DungeonInstances.offer(d.visited, str(c.state.seed))
 # A champion waits on the stairs (until the guild has six).
 if c.state.roster.size() < MAX_CHAMPIONS: offer_draft(c, "warden", 0)

# ------------------------------------------------------------------ Champion drafts
## How many champions the guild fields; fights are sized to match (at least two foes).
static func party(c: Campaign) -> int:
 return clampi(c.lineup().size(), 2, MAX_CHAMPIONS)

## After the headliner is signed: the partner draft opens and the founding fund becomes travel money.
static func after_headliner(c: Campaign) -> void:
 c.state.gold = mini(int(c.state.gold), 150)
 c.state.draft_done = true
 offer_draft(c, "partner", 0)

## Five champions to choose from. Stats are rolled fresh for each one; species that share an
## awakened trait with the guild are likelier to appear, but nothing is guaranteed.
static func offer_draft(c: Campaign, kind: String, cost: int) -> void:
 var d = c.state.dungeon
 var rng = RandomNumberGenerator.new(); rng.seed = hash(str(c.state.seed) + "|draft|%s|%d|%d|%d" % [kind, int(d.act), int(d.row), c.state.roster.size()])
 var owned = c.state.roster.map(func(h): return h.sp)
 var mine = {}
 for h in c.state.roster:
  for t in RunTraits.of(c, h.sp): mine[t] = true
 var pool = []
 for sp in League.tiers().get("Epic", []) + League.tiers().get("Common", []):
  if sp in owned or sp in pool: continue
  pool.append(sp)
 pool.sort()
 var picks = []
 while picks.size() < DRAFT_SIZE and not pool.is_empty():
  var weights = pool.map(func(sp): return 1.0 + 1.6 * RunTraits.of(c, sp).filter(func(t): return mine.has(t)).size())
  var total = 0.0
  for w in weights: total += w
  var roll = rng.randf() * total; var pick = 0
  for i in range(weights.size()):
   roll -= weights[i]
   if roll <= 0.0: pick = i; break
  picks.append(pool[pick]); pool.remove_at(pick)
 var level = 1
 if not c.lineup().is_empty():
  var sum = 0
  for h in c.lineup(): sum += int(h.level)
  level = clampi(roundi(float(sum) / c.lineup().size()), 1, 18)
 var offers = []
 for sp in picks:
  var id = "h%d" % int(c.state.next_id); c.state.next_id = int(c.state.next_id) + 1
  var h = HeroData.make_hero(sp, id, HeroData.themed_name(sp, id), level)
  for k in range(mini(3, maxi(0, level - 1))): h.learned[str(k)] = 1
  if level >= 5: h.signature_rank = 2
  h.price = 0
  offers.append(h)
 d.draft = {"kind": kind, "offers": offers, "cost": cost}

## Traits a draft offer shares with the guild (for the "synergy" mark on its card).
static func shared_traits(c: Campaign, sp: String) -> Array:
 var mine = {}
 for h in c.state.roster:
  for t in RunTraits.of(c, h.sp): mine[t] = true
 return RunTraits.of(c, sp).filter(func(t): return mine.has(t))

static func take_champion(c: Campaign, index: int) -> bool:
 var d = c.state.dungeon; var draft = d.get("draft", {})
 if draft.is_empty() or index < 0 or index >= draft.offers.size(): return false
 if c.state.roster.size() >= MAX_CHAMPIONS: c.last_error = "Your guild already has six champions."; return false
 if int(c.state.gold) < int(draft.cost): c.last_error = "Not enough gold."; return false
 var before = c.state.duplicate(true)
 var h = draft.offers[index].duplicate(true)
 c.state.gold = int(c.state.gold) - int(draft.cost)
 h.slot = c.standard_slot(h, c.lineup().map(func(o): return o.slot)) if c.lineup().size() < MAX_CHAMPIONS else -1
 c.state.roster.append(h); c.state.selected = h.id
 d.draft = {}
 add_score(c, 25)
 c.add_news("%s joins the guild" % h.name, "%s · %s" % [HeroData.species[h.sp].n, RunTraits.tag_text(c, h.sp)])
 if c.save(): return true
 c.state = before; return false

static func skip_draft(c: Campaign) -> bool:
 var d = c.state.dungeon
 if d.get("draft", {}).is_empty() or str(d.draft.kind) == "partner": return false
 var before = c.state.duplicate(true)
 if int(d.draft.cost) == 0: c.state.gold = int(c.state.gold) + 25
 d.draft = {}
 if c.save(): return true
 c.state = before; return false

## Outfitters sell one champion draft per visit.
static func shop_draft_cost(c: Campaign) -> int:
 return 110 + 30 * mini(int(c.state.dungeon.act), 6)

static func shop_draft_open(c: Campaign) -> bool:
 return c.state.tour.get("shop", false) and c.state.roster.size() < MAX_CHAMPIONS and int(c.state.dungeon.get("shop_draft_serial", -1)) != int(c.state.tour.serial)

static func buy_shop_draft(c: Campaign) -> bool:
 if not shop_draft_open(c): c.last_error = "No champion for hire here."; return false
 if int(c.state.gold) < shop_draft_cost(c): c.last_error = "Not enough gold."; return false
 c.state.dungeon.shop_draft_serial = int(c.state.tour.serial)
 offer_draft(c, "shop", shop_draft_cost(c))
 return c.save()

# ------------------------------------------------------------------ Fights
static func resolve(c: Campaign, sim: BattleSim) -> bool:
 var d = c.state.dungeon; var t = c.state.tour
 if not d.fight or t.get("complete", false) or not sim.finished or sim.battle_seed != c.match_seed(): return false
 var before = c.state.duplicate(true)
 var n = node(c); var kind = str(n.type); var rival = opponent(c); var r = region(c)
 RunDatabase.capture(c, sim, "player", "dungeon_%d" % int(t.serial))
 var rng = RandomNumberGenerator.new(); rng.seed = c.match_seed() + 801
 var won = sim.winner == 0
 var base_gold = TourBalance.match_gold(mini(int(t.level), 10), str(c.state.difficulty), won)
 var reward = roundi(base_gold * ({"battle": 0.55, "elite": 0.85, "boss": 1.3}.get(kind, 0.6) if won else 0.35))
 if won: reward += int(Relics.total(c, "gold_win"))
 c.record_team(c.state.roster, sim, 0, true, rng, XP_SCALE * (1.0 + Relics.total(c, "xp"))); c.record_club(c.state, sim.winner)
 if rival.has("club"):
  var cl = WorldTour.club(c, int(rival.club))
  c.record_team(cl.roster, sim, 1, false, rng); c.record_club(cl, 1 if won else 0 if sim.winner == 1 else -1)
 var report = {"winner": sim.winner, "gold": reward, "duration": sim.time, "rows": sim.report_rows(), "opponent": rival.name, "round": t.serial, "season": c.state.season, "tour_level": t.level, "location": r.place, "bout": int(d.fights) + 1, "stage": "%s · Room %d" % [ROOMS[kind].name, int(d.row) + 1], "dungeon": true, "room": kind}
 report.ais = sim.units.filter(func(u): return not u.summon).map(func(u): return {"uid": u.uid, "team": u.team, "name": u.hero.name, "sp": u.hero.sp, "ais": League.ais(sim, u), "ovr": League.ovr(u.hero), "power": HeroData.power(u.hero)})
 t.serial = int(t.serial) + 1; t.cup_started = true; d.fights = int(d.fights) + 1
 var score_before = int(d.score)
 if won:
  d.wins = int(d.wins) + 1; n.done = true; d.fight = false
  add_score(c, {"battle": 100, "elite": 250, "boss": 800}[kind])
  if kind == "battle": offer_loot(c, "component")
  elif kind == "elite": d.elites = int(d.elites) + 1; offer_loot(c, "relic")
  else:
   d.wardens = int(d.wardens) + 1
   offer_loot(c, "item"); offer_loot(c, "boss_relic")
   report.warden_down = true
   d.history.append({"act": int(d.act), "name": depth(c).name, "fights": int(d.fights), "lives": int(d.lives)})
   t.history.append({"level": int(d.act), "location": depth(c).name, "wins": int(d.wins), "attempt": 1, "promoted": true, "place": 1})
   # Every Warden drops a chest: bronze, silver, then gold for the deepest.
   var medal = ["Bronze", "Silver", "Gold"][clampi(int(d.act) - 1, 0, 2)]
   TrophyVault.award(c, medal); report.chest = true; report.medal = medal
   if int(d.act) == ACTS:
    c.state.trophies = int(c.state.trophies) + 1; report.dungeon_cleared = true; d.awaiting_endless = true
    c.add_news("The dungeon is conquered", "%s defeated all three Wardens with %d li%s left. Bank the score or descend into the endless depths." % [c.state.name, int(d.lives), "fe" if int(d.lives) == 1 else "ves"])
   else:
    descend(c)
    c.add_news("Warden defeated", "The way down to %s is open. One life restored, the squad trains, and new recruits wait on the stairs." % depth(c).name)
 else:
  d.lives = maxi(0, int(d.lives) - 1); report.life_lost = true
  if kind != "boss": n.done = true; d.fight = false   # beaten back, the guild pushes past; a Warden must be beaten
  if int(d.lives) <= 0:
   c.state.run_over = true; report.run_over = true; d.fight = false
   d.loot = []; d.loot_queue = []
   report.final_score = bank_score(c, "Fallen")
   c.add_news("Out of lives", "%s fell in %s, room %d, with %d points." % [c.state.name, depth(c).name, int(d.row) + 1, int(report.final_score)])
  else:
   c.add_news("A life lost", "%s lost to %s. %d li%s left." % [c.state.name, rival.name, int(d.lives), "fe" if int(d.lives) == 1 else "ves"])
 report.lives = int(d.lives); report.points = int(d.score) - score_before
 c.state.gold += reward; c.state.earned_gold += reward
 c.state.report = report; c.state.archive.append(report.duplicate(true))
 if c.save(): return true
 c.state = before; return false
