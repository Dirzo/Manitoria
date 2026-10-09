class_name DungeonAscension
extends RefCounted
## The dungeon's difficulty ladder, like Guildrun's challenge climb and Slay the Spire's Ascension.
## Clearing all three Wardens at a rank unlocks the next one. Ranks stack: Ascension 5 has the
## modifiers of ranks 1 to 5. Each rank adds 15% to the final score.

const MAX := 8
const PROGRESS_PATH := "user://dungeon_progress.json"
const RANKS := [
 {"name": "The Open Door", "text": "No modifiers."},
 {"name": "Hungry Dark", "text": "Every fight is 6% harder."},
 {"name": "Lean Purses", "text": "Fights pay 20% less gold."},
 {"name": "Alpha Elites", "text": "Elites are 10% stronger."},
 {"name": "Thin Blood", "text": "Start with one fewer life (never fewer than one)."},
 {"name": "Narrow Paths", "text": "Champion drafts offer four champions instead of five."},
 {"name": "Wrathful Wardens", "text": "Wardens are 12% stronger."},
 {"name": "No Mercy", "text": "Losing to an elite or a Warden costs two lives."},
 {"name": "The Last Light", "text": "Campfires and descents no longer restore lives."},
]

static func rank(c: Campaign) -> int:
 return clampi(int(c.state.get("dungeon", {}).get("ascension", 0)), 0, MAX)

## True when the run's rank includes modifier n.
static func has(c: Campaign, n: int) -> bool:
 return rank(c) >= n

static func score_multiplier(c: Campaign) -> float:
 return 1.0 + 0.15 * rank(c)

static func info(n: int) -> Dictionary:
 return RANKS[clampi(n, 0, MAX)]

## The modifiers in play at rank n, one line each.
static func lines(n: int) -> Array:
 var out = []
 for i in range(1, clampi(n, 0, MAX) + 1): out.append("%d · %s: %s" % [i, RANKS[i].name, RANKS[i].text])
 return out

static func _read() -> Dictionary:
 if not FileAccess.file_exists(PROGRESS_PATH): return {}
 var data = JSON.parse_string(FileAccess.get_file_as_string(PROGRESS_PATH))
 return data if data is Dictionary else {}

## The highest rank a new run may choose: one above the highest rank ever cleared.
static func unlocked() -> int:
 var best = int(_read().get("cleared", -1))
 return clampi(best + 1, 0, MAX)

## Called when the third Warden falls. Returns the newly unlocked rank, or -1.
static func record_clear(c: Campaign) -> int:
 var data = _read(); var best = int(data.get("cleared", -1))
 if rank(c) <= best: return -1
 data.cleared = rank(c)
 var f = FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
 if f: f.store_string(JSON.stringify(data)); f.close()
 return rank(c) + 1 if rank(c) < MAX else -1
