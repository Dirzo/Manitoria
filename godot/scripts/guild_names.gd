class_name GuildNames
extends RefCounted
## Guild name and motto generator: half grim-and-glorious, half ridiculous.

const ADJ_EPIC := ["Iron", "Crimson", "Obsidian", "Howling", "Ashen", "Thunder", "Gilded", "Midnight", "Savage", "Eternal", "Storm-Forged", "Bloodmoon", "Shattered", "Venomous", "Wrathful", "Frostbitten", "Unbroken", "Blackthorn", "Sunfire", "Grim"]
const NOUN_EPIC := ["Wardens", "Reavers", "Fangs", "Talons", "Ravagers", "Sentinels", "Dreadnoughts", "Executioners", "Wyrmguard", "Marauders", "Vanguard", "Hellhounds", "Titans", "Harbingers", "Warlords", "Phantoms", "Brood", "Legion", "Pride", "Host"]
const PLACES := ["Cinderfall", "Frostspire", "Ravenmoor", "Blackmarsh", "Stormhold", "Ashenvale", "Grimwatch", "Duskhollow", "Ironreach", "Wolfcrag", "Sunspear", "Bonehallow"]
const EPIC_PATTERNS := ["The %A %N", "%P %N", "%N of %P", "The %A %N of %P", "%P %A %N"]

const FUNNY := [
	"The Mildly Concerning Menagerie", "Goblins of Questionable Hygiene", "The Unpaid Interns of Doom", "Snack Time Berserkers",
	"The Fluffy Apocalypse", "Chaos Llamas Anonymous", "The Bitey Bois", "Wyverns With Anxiety", "The Overconfident Ducklings",
	"Tax Evasion Dragons", "The Soggy Biscuit Brigade", "Emotional Support Hydras", "The Noodle-Armed Avengers",
	"Gremlins After Midnight", "The Accidental Champions", "Pigeons of Mass Destruction", "The Nap Time Ravagers",
	"Moderately Spicy Salamanders", "The Spreadsheet Warlords", "Feral Toddlers of Ravenmoor", "The Disappointed Dads",
	"Cerberus Needs A Walk", "The Pointy Stick Society", "Unicorns Who Bite", "The Glitter Goblin Syndicate",
	"Sir Barks-A-Lot's Finest", "The Questionable Decisions", "Bards Who Can't Sing", "The Wet Socks Legion", "Crispy Phoenix Club",
]
const MOTTO_EPIC := [
	"Blood for the arena, glory for the guild", "We do not kneel", "Steel remembers", "From ash, we rise", "Strike first. Strike last.",
	"No mercy in the sand", "Fear is a lesser beast", "We are the storm", "Victory or a glorious end", "Our fangs never dull",
	"Bound by oath, forged in fire", "The crowd chants our names", "Where we walk, legends fall", "Let them come",
	"Iron will, iron claws", "Hunt. Conquer. Repeat.", "Only the bold leave the arena", "Every scar a trophy",
]
const MOTTO_FUNNY := [
	"We came, we saw, we panicked", "Probably fine", "Bite first, apologize never", "Snacks before glory",
	"Technically undefeated", "It's not a bug, it's a strategy", "We read the rules. Mostly.", "Our tank is also our healer. Help.",
	"Fortune favours the unprepared", "Victory tastes like chicken", "Win or nap trying", "Ask forgiveness, not permission",
	"Bad ideas, executed perfectly", "Loud, proud and slightly lost", "We put the 'fun' in funeral", "Ouch, but make it fashion",
	"Not all who wander are lost. We are, though.", "Pet the hydra at your own risk",
]

static func pick(arr: Array, rng: RandomNumberGenerator) -> String:
	return str(arr[rng.randi_range(0, arr.size() - 1)])

static func epic_name(rng: RandomNumberGenerator) -> String:
	for i in range(20):
		var p = pick(EPIC_PATTERNS, rng)
		var n = p.replace("%A", pick(ADJ_EPIC, rng)).replace("%N", pick(NOUN_EPIC, rng)).replace("%P", pick(PLACES, rng))
		if n.length() <= 36: return n
	return "The Iron Wardens"

## Returns {name, motto, funny}. Funny names get funny mottos (mostly).
static func roll(rng: RandomNumberGenerator, funny: int = -1) -> Dictionary:
	var silly = rng.randf() < 0.5 if funny < 0 else funny == 1
	var name = pick(FUNNY, rng) if silly else epic_name(rng)
	var motto_pool = MOTTO_FUNNY if (silly != (rng.randf() < 0.15)) else MOTTO_EPIC
	return {"name": name, "motto": pick(motto_pool, rng), "funny": silly}

static func motto(rng: RandomNumberGenerator, funny: bool) -> String:
	return pick(MOTTO_FUNNY if funny else MOTTO_EPIC, rng)
