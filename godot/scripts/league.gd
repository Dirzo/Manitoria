class_name League
extends RefCounted
## The Manitoria league: draft tiers and costs, per-species balance, Madden-style OVR ratings
## that evolve week to week, and the Arena Impact Score (AIS) earned in every match.

const COST_UNIT := 150
const START_GOLD := 1200   # 8 draft units: headliner + 2 Epics + 1 Common (elite four) or headliner + 1 Epic + 3 Commons (full five)
const TIERS := {
	# Eight headliners: one per club, each anchoring a different team niche.
	"Legendary": ["jackalope", "zaratan", "hydra", "cerberus", "phoenix", "thunderbird", "unicorn", "sphinx"],
	"Epic": ["golem", "minotaur", "nemean", "griffin", "kitsune", "kirin", "treant", "arachne"],
	"Common": ["troll", "wendigo", "owlbear", "yeti", "direwolf", "nekomata", "gargoyle", "chimera", "manticore",
		"wyvern", "harpy", "salamander", "basilisk", "cyclops", "naga", "pegasus"],
}
## The eight team niches. Each run, one random creature from every niche becomes a Legendary
## headliner and another becomes an Epic, so every draft is fresh but every niche is covered.
const NICHE_GROUPS := {
	"Anchor": ["golem", "yeti", "zaratan"],
	"Warden": ["cerberus", "nemean"],
	"Bruiser": ["minotaur", "troll", "wendigo", "owlbear", "hydra"],
	"Healer": ["treant", "naga", "unicorn", "pegasus"],
	"Controller": ["basilisk", "sphinx", "kitsune"],
	"Caster": ["phoenix", "kirin", "salamander", "arachne"],
	"Artillery": ["cyclops", "thunderbird", "wyvern", "harpy"],
	"Skirmisher": ["direwolf", "jackalope", "manticore", "nekomata", "griffin", "gargoyle", "chimera"],
}
static var run_tiers: Dictionary = {}

## This run's tiers (falls back to the classic line-up for old saves and tools).
static func tiers() -> Dictionary:
	return run_tiers if not run_tiers.is_empty() else TIERS

static func roll_tiers(seed_text: String) -> Dictionary:
	var rng = RandomNumberGenerator.new(); rng.seed = hash("tiers|" + seed_text)
	var out = {"Legendary": [], "Epic": [], "Common": []}
	for niche in NICHE_GROUPS:
		var pool: Array = NICHE_GROUPS[niche].duplicate()
		for i in range(pool.size() - 1, 0, -1):
			var j = rng.randi_range(0, i); var t = pool[i]; pool[i] = pool[j]; pool[j] = t
		out.Legendary.append(pool[0]); out.Epic.append(pool[1])
		for k in range(2, pool.size()): out.Common.append(pool[k])
	return out

static func niche_of(sp: String) -> String:
	for n in NICHE_GROUPS:
		if sp in NICHE_GROUPS[n]: return n
	return ""

const TIER_COST := {"Legendary": 3, "Epic": 2, "Common": 1}
# Raw strength step between tiers (health and attack).
const TIER_POWER := {"Legendary": 1.12, "Epic": 1.05, "Common": 1.0}
const TIER_COLOR := {"Legendary": "ffd27a", "Epic": "c9a2ff", "Common": "9fd4c6"}
const NICHE := {
	"jackalope": "Hit-and-run skirmisher", "zaratan": "Immovable anchor", "hydra": "Self-healing bruiser",
	"cerberus": "Taunting warden", "phoenix": "Fire-zone caster that rises again", "thunderbird": "Long-range storm artillery",
	"unicorn": "Team healer & cleanse", "sphinx": "Crowd-control controller",
	"golem": "Shield-wall tank", "minotaur": "Charging bruiser", "nemean": "Rallying warden", "griffin": "Back-line diver",
	"kitsune": "Spirit trickster", "kirin": "Chain-lightning caster", "treant": "Rooting healer", "arachne": "Swarm summoner",
	"troll": "Regenerating bruiser", "wendigo": "Lifesteal bruiser", "owlbear": "Mauling bruiser", "yeti": "Frost tank",
	"direwolf": "Pack skirmisher", "nekomata": "Stealth assassin", "gargoyle": "Stone diver", "chimera": "Triple-strike duelist",
	"manticore": "Venom assassin", "wyvern": "Acid ranged", "harpy": "Silencing ranged", "salamander": "Magma caster",
	"basilisk": "Petrifying controller", "cyclops": "Boulder artillery", "naga": "Tidal shield support", "pegasus": "Haste support",
}
# Per-species fine tuning so choices within a tier are equally strong (set by tools/league_balance.gd).
const BALANCE := {
	"arachne": 1.028,
	"basilisk": 1.058,
	"cerberus": 1.054,
	"chimera": 1.15,
	"cyclops": 0.902,
	"gargoyle": 1.121,
	"golem": 1.029,
	"griffin": 1.092,
	"harpy": 1.045,
	"hydra": 0.952,
	"jackalope": 0.984,
	"kirin": 1.03,
	"kitsune": 1.049,
	"manticore": 0.86,
	"nemean": 0.896,
	"owlbear": 1.02,
	"phoenix": 1.011,
	"salamander": 0.958,
	"sphinx": 1.131,
	"thunderbird": 1.072,
	"troll": 1.064,
	"unicorn": 1.031,
	"wendigo": 1.015,
	"yeti": 0.952,
	"zaratan": 0.883,
}

static func tier(sp: String) -> String:
	var all = tiers()
	for t in all:
		if sp in all[t]: return t
	return "Common"

static func cost(sp: String) -> int:
	return TIER_COST[tier(sp)] * COST_UNIT

static func stat_factor(sp: String) -> float:
	return TIER_POWER[tier(sp)] * float(BALANCE.get(sp, 1.0))

static func tier_color(sp: String) -> Color:
	return Color(TIER_COLOR[tier(sp)])

# ------------------------------------------------------------------ Arena Impact Score
## 1-100 per match. Shares of the team's damage, sustain (healing + shields), front-line soak and
## takedowns, plus survival and the result. 50 is an average contribution; 80+ is an MVP game.
static func ais(sim: BattleSim, u: Dictionary) -> int:
	var tot = {"d": 0.0, "h": 0.0, "t": 0.0, "k": 0.0}
	for v in sim.units:
		if v.team != u.team or v.summon: continue
		tot.d += v.damage; tot.h += v.healing + _shielding(v); tot.t += v.damage_taken + v.blocked; tot.k += v.kills
	var share_d = u.damage / maxf(1.0, tot.d)
	var share_h = (u.healing + _shielding(u)) / maxf(1.0, tot.h) if tot.h > 30.0 else 0.2
	var share_t = (u.damage_taken + u.blocked) / maxf(1.0, tot.t)
	var share_k = u.kills / maxf(1.0, tot.k) if tot.k > 0 else 0.2
	var raw = 0.45 * share_d + 0.22 * share_h + 0.18 * share_t + 0.15 * share_k
	var score = 50.0 + (raw - 0.2) * 160.0 + (6.0 if u.alive else -4.0) + (4.0 if sim.winner == u.team else -2.0)
	return clampi(roundi(score), 1, 100)

static func _shielding(u: Dictionary) -> float:
	var s = 0.0
	for k in u.get("ability_stats", {}):
		s += float(u.ability_stats[k].get("shielding", 0.0))
	return s

static func record_ais(h: Dictionary, score: int) -> void:
	var hist: Array = h.get("ais_history", [])
	hist.append(score)
	while hist.size() > 8: hist.pop_front()
	h.ais_history = hist; h.ais_last = score
	h.ais_total = h.get("ais_total", 0) + score; h.ais_games = h.get("ais_games", 0) + 1
	h.season_ais = h.get("season_ais", 0) + score; h.season_ais_games = h.get("season_ais_games", 0) + 1

static func form(h: Dictionary) -> float:
	var hist: Array = h.get("ais_history", [])
	if hist.is_empty(): return 50.0
	var recent = hist.slice(maxi(0, hist.size() - 5))
	return recent.reduce(func(a, b): return a + b, 0.0) / recent.size()

# ------------------------------------------------------------------ Madden-style ratings
const TIER_BASE := {"Legendary": 76, "Epic": 70, "Common": 64}

static func skill_points(h: Dictionary) -> float:
	var p = (h.signature_rank - 1) * 1.5
	for k in h.get("learned", {}):
		p += 1.5 + (int(h.learned[k]) - 1) * 1.0
		var r = RarityStyle.for_skill(h, "ability:" + str(k))
		p += 3.0 if r == "Legendary" else 1.0 if r == "Rare" else 0.0
	if RarityStyle.for_skill(h, "signature") == "Legendary": p += 3.0
	return p

## Sub-ratings 40-99: POW (damage), DUR (toughness), SPD (mobility & attack speed), SKL (kit), IMP (form).
static func ratings(h: Dictionary) -> Dictionary:
	HeroData.load_data()
	var d = HeroData.species[h.sp]
	var lvl = (int(h.level) - 1) * 1.1
	var f = stat_factor(h.sp)
	var pow_ = 52.0 + (d.atk * f - 0.6) * 38.0 + (d["as"] - 0.55) * 18.0 + lvl
	var dur = 50.0 + (d.hp * f - 0.6) * 28.0 + d.def * 3.0 + lvl
	var spd = 45.0 + (d.mv - 42.0) * 0.55 + (d["as"] - 0.55) * 22.0 + lvl * 0.5
	var skl = 55.0 + skill_points(h) * 2.2 + (4.0 if not h.get("evolution", "").is_empty() else 0.0) + lvl * 0.6
	var imp = 40.0 + (form(h) - 30.0) * 0.9 if h.has("ais_history") else 60.0 + lvl * 0.4
	# Stat genes: each rating moves with the rolls behind it.
	pow_ += HeroData.roll_norm(h, "attack") * 7.0 + HeroData.roll_norm(h, "haste") * 4.0
	dur += HeroData.roll_norm(h, "hp") * 7.0 + HeroData.roll_norm(h, "armor") * 5.0
	spd += HeroData.roll_norm(h, "speed") * 7.0 + HeroData.roll_norm(h, "haste") * 3.0
	skl += HeroData.roll_norm(h, "potency") * 7.0
	var r = {"POW": pow_, "DUR": dur, "SPD": spd, "SKL": skl, "IMP": imp}
	for k in r: r[k] = clampi(roundi(r[k]), 40, 99)
	return r

static func ovr(h: Dictionary) -> int:
	var base = TIER_BASE[tier(h.sp)] + (int(h.level) - 1) * 1.05 + skill_points(h) * 0.55
	base += 2.0 if not h.get("evolution", "").is_empty() else 0.0
	base += (form(h) - 50.0) * 0.12 if h.has("ais_history") else 0.0
	# Blend in the role-weighted attributes so creatures of the same tier still rate differently.
	var r = ratings(h)
	var w = {"Front": {"DUR": 0.45, "POW": 0.3, "SPD": 0.1, "SKL": 0.15}, "Flank": {"POW": 0.4, "SPD": 0.35, "DUR": 0.1, "SKL": 0.15},
		"Back": {"POW": 0.4, "SKL": 0.35, "DUR": 0.1, "SPD": 0.15}}[HeroData.line(h.sp)]
	if HeroData.species[h.sp].role == "Support": w = {"SKL": 0.45, "DUR": 0.25, "POW": 0.15, "SPD": 0.15}
	var attr = 0.0
	for k in w: attr += r[k] * w[k]
	base = base * 0.8 + (attr + (TIER_BASE[tier(h.sp)] - 70) * 0.6) * 0.2
	# Power level: only the rolls the role uses count (a tank with great damage rolls is still a weak
	# tank), plus temperament fit and where the champion sits on its scaling curve right now.
	base += HeroData.roll_fit(h) * 7.0
	base += 2.0 if Traits.is_ideal(h) else 0.0
	base += (Traits.curve(h) - 1.0) * 22.0
	return clampi(roundi(base), 40, 99)

static func team_ovr(heroes: Array) -> int:
	if heroes.is_empty(): return 0
	var s = 0.0
	for h in heroes: s += ovr(h)
	return roundi(s / heroes.size())

static func rating_badge_text(h: Dictionary) -> String:
	var delta = ovr(h) - int(h.get("ovr_week", ovr(h)))
	return "%d OVR%s" % [ovr(h), (" +%d" % delta) if delta > 0 else (" -%d" % -delta) if delta < 0 else ""]

## Snapshot every league creature's rating at the start of a week so movement can be shown.
static func week_snapshot(c: Campaign) -> void:
	for h in all_heroes(c): h.ovr_week = ovr(h)

static func all_heroes(c: Campaign) -> Array:
	var out = c.state.roster.duplicate()
	for club in c.state.clubs: out.append_array(club.roster)
	return out

static func club_of(c: Campaign, h: Dictionary) -> String:
	if c.state.roster.has(h): return c.state.name
	for club in c.state.clubs:
		if club.roster.has(h): return club.name
	return ""

## End-of-week ratings update: report the biggest movers as league news.
static func weekly_update(c: Campaign) -> Array:
	var moves = []
	for h in all_heroes(c):
		var before = int(h.get("ovr_week", ovr(h)))
		var now = ovr(h)
		if now != before: moves.append({"hero": h, "club": club_of(c, h), "from": before, "to": now})
	moves.sort_custom(func(a, b): return absi(a.to - a.from) > absi(b.to - b.from))
	var lines = []
	for m in moves.slice(0, 4):
		lines.append("%s %s %d → %d (%s)" % [HeroData.species[m.hero.sp].n, "up" if m.to > m.from else "down", m.from, m.to, m.club])
	if not lines.is_empty(): c.add_news("Ratings update", " · ".join(lines))
	c.state.rating_moves = moves.slice(0, 12).map(func(m): return {"id": m.hero.id, "sp": m.hero.sp, "name": m.hero.name, "club": m.club, "from": m.from, "to": m.to})
	week_snapshot(c)
	return moves

# ------------------------------------------------------------------ AI club drafting
const CLUB_LANES := [["Tank", "Warden"], ["Bruiser", "Tank", "Warden"], ["Skirmisher", "Assassin", "Diver", "Trickster", "Duelist"], ["Caster", "Ranged", "Artillery", "Controller", "Summoner"], ["Support"]]

## Each rival club: its legendary headliner plus a budget-built supporting cast covering all lanes.
static func draft_club(name: String, headliner: String, rng: RandomNumberGenerator, id_prefix: String) -> Dictionary:
	HeroData.load_data()
	var picks = [headliner]
	var head_role = HeroData.species[headliner].role
	var lanes = []
	var filled = false
	for lane in CLUB_LANES:
		if not filled and head_role in lane: filled = true; continue
		lanes.append(lane)
	lanes = lanes.slice(0, 4)
	# Same 8-unit budget as the player: an elite four (2 Epics + 1 Common) or a full five (1 Epic + 3 Commons).
	var elite = rng.randf() < 0.35
	if elite:
		var drop = rng.randi_range(0, lanes.size() - 1)
		if lanes[drop] == ["Support"] and head_role != "Support": drop = (drop + 1) % lanes.size()
		lanes.remove_at(drop)
	var epics = 2 if elite else 1
	for i in range(lanes.size() - 1, 0, -1):
		var j = rng.randi_range(0, i); var tmp = lanes[i]; lanes[i] = lanes[j]; lanes[j] = tmp
	for i in range(lanes.size()):
		var want_epic = i < epics
		var pool = []
		for sp in HeroData.species:
			if sp in picks or tier(sp) == "Legendary": continue
			if HeroData.species[sp].role in lanes[i] and (tier(sp) == "Epic") == want_epic: pool.append(sp)
		if pool.is_empty():
			for sp in HeroData.species:
				if sp not in picks and tier(sp) != "Legendary" and HeroData.species[sp].role in lanes[i] and (tier(sp) == "Epic") == want_epic: pool.append(sp)
		if pool.is_empty():
			for sp in tiers()["Epic" if want_epic else "Common"]:
				if sp not in picks: pool.append(sp)
		picks.append(pool[rng.randi_range(0, pool.size() - 1)])
	var order = _lane_order(picks)
	var roster = []
	for i in range(order.size()):
		var h = HeroData.make_hero(order[i], "%s_%d" % [id_prefix, i], HeroData.themed_name(order[i], "%s_%d_%d" % [id_prefix, i, rng.randi()]))
		h.slot = Campaign.FORMATION[i]; h.price = cost(order[i])
		roster.append(h)
	return {"name": name, "roster": roster, "wins": 0, "losses": 0, "draws": 0, "headliner": roster[order.find(headliner)].id, "elite": elite}

static func _lane_order(picks: Array) -> Array:
	# FORMATION slots are [front, front-2, mid, back, back-2]; place by line.
	var front = picks.filter(func(sp): return HeroData.line(sp) == "Front")
	var flank = picks.filter(func(sp): return HeroData.line(sp) == "Flank")
	var back = picks.filter(func(sp): return HeroData.line(sp) == "Back")
	return front + flank + back
