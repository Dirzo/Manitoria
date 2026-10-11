class_name SignatureCast
extends RefCounted
## v0.76: what each signature does when its mana bar fills. Numbers match Signatures.DATA text.
## u.sig_mult = Apex Signature bonus; AP numbers also grow with level (Signatures.level_factor).

const HEX := ArenaGrid.ROW_GAP

# ---------------------------------------------------------------- number helpers
static func ad(u: Dictionary, pct: float) -> float:
	return u.attack * pct / 100.0 * float(u.get("sig_mult", 1.0)) * float(u.get("sig_scale", 1.0))

static func ap(u: Dictionary, base: float) -> float:
	return base * float(u.get("ap", 100.0)) / 100.0 * Signatures.level_factor(int(u.hero.get("level", 1))) * float(u.get("sig_mult", 1.0)) * float(u.get("sig_scale", 1.0))

static func evo(u: Dictionary) -> int:
	return -1 if u.summon else Signatures.evo_index(u.hero)

static func within(sim: BattleSim, u: Dictionary, center: Vector2, hexes: int) -> Array:
	var c = ArenaGrid.nearest(center)
	return sim.foes(u).filter(func(e): return ArenaGrid.distance(e.cell, c) <= hexes)

static func allies_within(sim: BattleSim, u: Dictionary, hexes: int, include_summons := false) -> Array:
	return sim.living(u.team, include_summons).filter(func(a): return ArenaGrid.distance(a.cell, u.cell) <= hexes)

static func hit(sim: BattleSim, u: Dictionary, t: Dictionary, amount: float, true_damage := false) -> float:
	if t.is_empty() or not t.alive: return 0.0
	var before = t.hp
	sim.true_hit = true_damage
	sim.hurt(u, t, amount, true, "signature")
	sim.true_hit = false
	return maxf(0.0, before - t.hp)

static func pick(sim: BattleSim, u: Dictionary, score: Callable) -> Dictionary:
	var best = {}; var best_s = -INF
	for e in sim.foes(u):
		var s = float(score.call(e))
		if s > best_s: best_s = s; best = e
	return best

static func farthest(sim: BattleSim, u: Dictionary) -> Dictionary:
	return pick(sim, u, func(e): return u.pos.distance_to(e.pos) - (100.0 if e.summon else 0.0))

static func lowest(sim: BattleSim, u: Dictionary, reach := 99) -> Dictionary:
	return pick(sim, u, func(e): return (-e.hp / e.max_hp if ArenaGrid.distance(e.cell, u.cell) <= reach else -10.0) - (5.0 if e.summon else 0.0))

static func cluster(sim: BattleSim, u: Dictionary, backline := false) -> Dictionary:
	return pick(sim, u, func(e):
		var n = within(sim, u, e.pos, 1).size()
		return n * 10.0 - u.pos.distance_to(e.pos) * 0.1 + (6.0 if backline and e.range > 2 and not e.summon else 0.0) - (8.0 if e.summon else 0.0))

static func move_to(sim: BattleSim, u: Dictionary, pos: Vector2) -> void:
	sim.relocate_hex(u, pos)
	u.erase("next_cell")

static func leap(sim: BattleSim, u: Dictionary, t: Dictionary) -> void:
	sim.leap(u, t)
	sim.emit({"type": "dash", "uid": u.uid, "pos": u.pos})

static func push(sim: BattleSim, t: Dictionary, from: Vector2, hexes: float) -> void:
	if not t.alive or sim.active(t, "unstoppable"): return
	var dir = (t.pos - from).normalized()
	if dir == Vector2.ZERO: dir = Vector2(0, 1 if t.team == 1 else -1)
	sim.relocate_hex(t, t.pos + dir * HEX * hexes)

static func pull(sim: BattleSim, t: Dictionary, to: Vector2, hexes: float) -> void:
	if not t.alive or sim.active(t, "unstoppable"): return
	var d = to - t.pos
	sim.relocate_hex(t, t.pos + d.normalized() * minf(d.length(), HEX * hexes))

static func line_hits(sim: BattleSim, u: Dictionary, a: Vector2, b: Vector2, width := 1.4) -> Array:
	return sim.foes(u).filter(func(e): return Geometry2D.get_closest_point_to_segment(e.pos, a, b).distance_to(e.pos) < width)

static func buff(sim: BattleSim, a: Dictionary, key: String, stats: Dictionary, seconds: float) -> void:
	var b = stats.duplicate(); b.t = seconds
	a.buffs[key] = b

static func dot(sim: BattleSim, u: Dictionary, t: Dictionary, total: float, seconds: float, kind := "poison", stack := false) -> void:
	if t.is_empty() or not t.alive: return
	if stack:
		sim.status(t, kind, seconds)
		t.dots.append({"source": u.uid, "kind": kind + "_s", "credit": "signature", "remaining": seconds, "damage": total / seconds})
	else:
		sim.poison(u, t, seconds, total / seconds, kind)

## Self-centred casts wait (with a full bar) until someone is in reach.
static func ready(sim: BattleSim, u: Dictionary) -> bool:
	match str(u.hero.sp):
		"golem", "nemean", "yeti", "zaratan", "cerberus":
			if u.hero.sp == "nemean" and evo(u) == 2: return true
			if u.hero.sp == "cerberus" and evo(u) == 2: return true
			if u.hero.sp == "yeti" and evo(u) == 2: return true
			return not within(sim, u, u.pos, 2).is_empty()
		"hydra":
			return u.hp / u.max_hp < 0.85 or evo(u) == 2
	return true

# ---------------------------------------------------------------- casting
static func cast(sim: BattleSim, u: Dictionary, target: Dictionary) -> void:
	var sp = str(u.hero.sp); var e = evo(u)
	match sp:
		"minotaur":
			var t = farthest(sim, u) if u.pos.distance_to(farthest(sim, u).pos) < HEX * 6 else target
			var start = u.pos
			if e == 0: sim.status(u, "unstoppable", 0.6)
			leap(sim, u, t)
			for v in line_hits(sim, u, start, u.pos):
				if v.uid != t.uid: hit(sim, u, v, ad(u, 100))
			hit(sim, u, t, ad(u, 400 if e == 1 else 340))
			sim.status(t, "stun", 2.5 if e == 2 else 1.5)
			if e == 0: sim.shield(u, ap(u, 150))
			if e == 1: u.interval /= 1.20
			if e == 2: pull(sim, t, sim.home(u), 2)
		"golem":
			for v in within(sim, u, u.pos, 2): v.taunt_by = u.uid; sim.status(v, "taunt", 2.0)
			var amount = ap(u, 150) + u.max_hp * (0.20 if e == 0 else 0.12)
			sim.shield(u, amount, 4.0)
			u.sig.shard_watch = u.shield if e == 1 else 0.0; u.sig.shard_time = 4.0 if e == 1 else 0.0
			if e == 2:
				var mates = sim.living(u.team, false).filter(func(a): return a.uid != u.uid)
				mates.sort_custom(func(a, b): return a.pos.distance_to(u.pos) < b.pos.distance_to(u.pos))
				for a in mates.slice(0, 2): sim.shield(a, amount * 0.5, 4.0)
		"troll":
			var t = target
			if e == 2:
				t = pick(sim, u, func(v): return v.hp if ArenaGrid.distance(v.cell, u.cell) <= 4 else -1.0)
				if not t.is_empty(): leap(sim, u, t)
			if t.is_empty(): return
			for v in within(sim, u, t.pos, 1):
				hit(sim, u, v, ad(u, 300 if e == 1 else 230))
				buff(sim, v, "troll_smash", {"as": -0.30}, 3.0)
				if e == 1: buff(sim, v, "shred", {"res": -20}, 4.0)
		"wendigo":
			var bonus = 1.00 * u.ap / 100.0 * float(u.get("sig_mult", 1.0))
			buff(sim, u, "frenzy", {"as": bonus}, 5.0)
			sim.status(u, "hunger", 5.0); sim.status(u, "channel", 5.0)
			u.sig.lifesteal = 0.80 if e == 0 else 0.60
			if e == 1:
				var t = lowest(sim, u)
				if not t.is_empty(): leap(sim, u, t); u.target = t.uid
		"cerberus":
			if e == 2:
				var c = cluster(sim, u, true)
				if not c.is_empty(): leap(sim, u, c)
			var near = sim.foes(u)
			near.sort_custom(func(a, b): return u.pos.distance_to(a.pos) < u.pos.distance_to(b.pos))
			var dealt = 0.0
			for v in near.slice(0, 3):
				dealt += hit(sim, u, v, ad(u, 130))
				if e == 1:
					dot(sim, u, v, ap(u, 130), 3.0, "burn"); sim.status(v, "scorch", 3.0); v.scorch_source = u.uid
				else:
					dot(sim, u, v, ap(u, 45), 3.0, "bleed")
				if e == 0: v.taunt_by = u.uid; sim.status(v, "taunt", 1.5)
			sim.heal(u, u, dealt * 0.25, "signature")
		"nemean":
			var reach = 3 if e == 0 else 2
			if e == 2:
				var t = pick(sim, u, func(v): return v.attack - (100.0 if v.summon else 0.0))
				if not t.is_empty():
					leap(sim, u, t); t.taunt_by = u.uid; sim.status(t, "taunt", 3.0)
			else:
				for v in within(sim, u, u.pos, reach): v.taunt_by = u.uid; sim.status(v, "taunt", 1.5)
			var b = 0.30 * u.ap / 100.0 * float(u.get("sig_mult", 1.0))
			for a in allies_within(sim, u, reach):
				buff(sim, a, "roar", {"as": b, "ad": b}, 4.0)
				if e == 0: sim.shield(a, ap(u, 90), 4.0)
			if e == 1: sim.status(u, "unstoppable", 3.0)
		"yeti":
			if e == 2:
				var dir = Vector2(0, 1 if u.team == 0 else -1)
				var start = u.pos
				move_to(sim, u, u.pos + dir * HEX * 3)
				for v in line_hits(sim, u, start, u.pos, 1.8):
					push(sim, v, u.pos, 1); sim.status(v, "stun", 1.0)
			for v in within(sim, u, u.pos, 2):
				hit(sim, u, v, ap(u, 80))
				if e == 0: sim.status(v, "stun", 1.25)
				else: buff(sim, v, "chill", {"as": -0.40}, 3.0)
			sim.shield(u, ap(u, 120) + u.res * (5.0 if e == 1 else 2.0) * float(u.get("sig_mult", 1.0)), 4.0)
		"zaratan":
			for v in within(sim, u, u.pos, 1): v.taunt_by = u.uid; sim.status(v, "taunt", 2.0)
			var secs = 4.0 if e == 2 else 3.0
			sim.status(u, "shell", secs); sim.status(u, "channel", secs)
			u.sig.absorbed = 0.0; u.sig.shell_wave = e == 1
			sim.heal(u, u, ap(u, 140), "signature")
			if e == 0:
				for a in allies_within(sim, u, 1):
					if a.uid != u.uid: buff(sim, a, "island", {"dr": 0.30}, secs)
		"owlbear":
			var t = target
			if e == 2:
				t = lowest(sim, u)
			if t.is_empty(): return
			leap(sim, u, t)
			var pin = 2.5 if e == 0 else 1.5
			sim.status(t, "root", pin); sim.status(t, "stun", pin * 0.5)
			t.pinned_by = u.uid; t.pinned_until = sim.time + pin
			if e == 0: sim.shield(u, ap(u, 120), pin)
			var bonus_as = u.base_as_now / u.base_as - 1.0 if u.has("base_as_now") else 0.0
			var claws = 4 + maxi(0, floori(bonus_as / 0.25))
			for i in range(claws):
				var victims = within(sim, u, u.pos, 1) if e == 1 else [t]
				for v in victims: hit(sim, u, v, ad(u, 80))
		"hydra":
			sim.heal(u, u, u.max_hp * 0.15 * float(u.get("sig_mult", 1.0)) + ap(u, 100), "signature")
			u.sig.heads = int(u.sig.get("heads", 0)) + 1
			u.interval /= 1.10
			if e == 0: u.attack *= 1.10; u.attack_basic *= 1.10
			if e == 2:
				var c = cluster(sim, u)
				if not c.is_empty() and u.pos.distance_to(c.pos) < HEX * 3.5: leap(sim, u, c)
		"direwolf":
			if e == 1:
				var t = lowest(sim, u)
				if not t.is_empty():
					leap(sim, u, t)
					for p in pets(sim, u): sim.relocate_hex(p, t.pos)
			if e == 2:
				u.attack *= 1.15; u.attack_basic *= 1.15; u.interval /= 1.15
				return
			var cap = 6 if e == 0 else 4
			var n = mini(3 if e == 0 else 2, cap - pets(sim, u).size())
			for i in range(n): summon(sim, u, "direwolf", "Pup", ap(u, 320), u.attack * 0.70, 1.0 / u.interval)
			if e == 0:
				var ps = pets(sim, u)
				for p in ps: p.interval = 1.0 / (1.0 / u.interval * (1.0 + 0.10 * (ps.size() - 1)))
		"manticore":
			var t = lowest(sim, u, 3)
			if t.is_empty(): t = target
			var start = u.pos
			leap(sim, u, t)
			var dmg = ad(u, 200) * (2.0 if e == 1 and t.hp / t.max_hp < 0.40 else 1.0)
			hit(sim, u, t, dmg)
			if t.alive: dot(sim, u, t, ap(u, 90), 3.0, "venom_true", e == 0 and stacks(t, u, "venom_true") < 3)
			elif e == 1: u.mana = minf(u.max_mana, u.mana + 40.0)
			if e == 2:
				move_to(sim, u, u.pos + (start - u.pos).normalized() * HEX * 3)
				sim.status(u, "stealth", 1.0)
		"griffin":
			var t = farthest(sim, u)
			if t.is_empty(): return
			leap(sim, u, t)
			hit(sim, u, t, ad(u, 220)); sim.status(t, "stun", 1.5)
			if e == 0:
				for v in within(sim, u, t.pos, 1):
					if v.uid != t.uid: hit(sim, u, v, ad(u, 120))
			if e == 1: sim.status(t, "airborne", 2.0); sim.status(t, "stun", 2.0)
			if e == 2:
				move_to(sim, u, u.start_pos); sim.shield(u, ap(u, 150))
		"kitsune":
			for i in range(2):
				var d = summon(sim, u, "kitsune", "Decoy", u.max_hp * 0.30, 0.0, 0.01)
				d.decoy = true; d.ttl = 6.0
				for v in within(sim, u, d.pos, 2): v.taunt_by = d.uid; sim.status(v, "taunt", 1.5)
			var t = pick(sim, u, func(v): return float(v.get("ap", 100.0)) + (0.0 if v.range > 2 else -20.0) - (100.0 if v.summon else 0.0))
			if t.is_empty(): return
			leap(sim, u, t)
			if e == 0:
				var list = sim.foes(u); list.sort_custom(func(a, b): return u.pos.distance_to(a.pos) < u.pos.distance_to(b.pos))
				for i in range(9):
					if list.is_empty(): break
					sim.launch(u, list[i % mini(3, list.size())], ap(u, 60) / 2.2, 0.35 + i * 0.05, true, "wisps")
			else:
				for i in range(3): sim.launch(u, t, ap(u, 60), 0.35 + i * 0.12, true, "wisps")
			if e == 2:
				move_to(sim, u, u.pos + (u.start_pos - u.pos).normalized() * HEX * 2); sim.status(u, "stealth", 1.0)
		"gargoyle":
			var c = cluster(sim, u, true)
			if c.is_empty(): return
			leap(sim, u, c)
			for v in within(sim, u, u.pos, 2 if e == 1 else 1):
				hit(sim, u, v, ad(u, 230))
				if e == 1: sim.status(v, "stun", 1.0)
			var stone = 3.0 if e == 0 else 2.0
			sim.status(u, "stone", stone); sim.status(u, "channel", stone)
			for v in within(sim, u, u.pos, 1): v.taunt_by = u.uid; sim.status(v, "taunt", stone)
			if e == 0: sim.heal(u, u, u.max_hp * 0.15, "signature")
			if e == 2: u.sig.second_drop = sim.time + stone
		"nekomata":
			sim.status(u, "stealth", 1.5)
			u.sig.ambush_at = sim.time + 1.5
			u.sig.ambush_evo = e
			sim.status(u, "channel", 1.5)
		"jackalope":
			var t = target
			var dir = (t.pos - u.pos).normalized()
			var start = u.pos
			var end = u.pos + dir * HEX * 6
			move_to(sim, u, end)
			var passes = [[start, u.pos]]
			if e == 1:
				var mid = u.pos
				move_to(sim, u, start); passes.append([mid, u.pos])
			for seg in passes:
				for v in line_hits(sim, u, seg[0], seg[1], 1.6):
					hit(sim, u, v, ad(u, 150)); sim.status(v, "stun", 0.5)
			if e == 0: u.sig.double_hits = 3
			if e == 2:
				for i in range(4):
					var p = start.lerp(end, (i + 0.5) / 4.0)
					sim.zones.append({"source": u.uid, "pos": p, "credit": "signature", "radius": HEX * 0.8, "damage": ap(u, 35), "remaining": 4.0, "effect": "roots"})
		"chimera":
			var t = target
			if t.is_empty(): return
			hit(sim, u, t, ad(u, 300 if e == 0 else 180))
			sim.status(t, "stun", 1.5 if e == 2 else 0.75)
			if e == 2: push(sim, t, u.pos, 2)
			dot(sim, u, t, ap(u, 200 if e == 1 else 100), 3.0, "burn")
			if e == 1: t.serpent_spread = u.uid
		"wyvern":
			var ts = [target]
			if e == 0:
				var list = sim.foes(u); list.sort_custom(func(a, b): return u.pos.distance_to(a.pos) < u.pos.distance_to(b.pos))
				ts = list.slice(0, 3)
			for t in ts:
				hit(sim, u, t, ad(u, 140 if e == 0 else 320))
				buff(sim, t, "shred", {"res": -25}, 5.0)
				sim.zones.append({"source": u.uid, "pos": t.pos, "credit": "signature", "radius": HEX, "damage": ad(u, 60), "remaining": 3.0, "effect": "acid"})
		"harpy":
			var t = target
			if e == 2:
				var back = pick(sim, u, func(v): return (10.0 if v.range > 2 else 0.0) - u.pos.distance_to(v.pos) * 0.1 - (50.0 if v.summon else 0.0))
				if not back.is_empty(): t = back; leap(sim, u, back); u.sig.return_at = sim.time + 1.4
			var bonus_as = u.base_as_now / u.base_as - 1.0 if u.has("base_as_now") else 0.0
			var n = 5 + maxi(0, floori(bonus_as / 0.25))
			for i in range(n):
				var last = i == n - 1
				sim.launch(u, t, ad(u, 80), 0.25 + i * 0.08, false, "barrage")
				var shot = sim.projectiles.back()
				shot.true_damage = last; shot.silence = 1.5 if last else 0.0; shot.pierce = e == 1
			if e == 0:
				for v in within(sim, u, u.pos, 2): sim.status(v, "silence", 2.0); sim.status(v, "slow", 2.0)
		"phoenix":
			cast_sunfire(sim, u, target, e)
		"kirin":
			var struck = []; var current = target; var origin = u.pos
			var jumps = 6 if e == 0 else 4
			for j in range(jumps):
				if current.is_empty(): break
				hit(sim, u, current, ap(u, 170) * pow(0.88, j)); struck.append(current.uid)
				if e == 1: sim.status(current, "stun", 0.5)
				sim.emit({"type": "bolt", "uid": u.uid, "pos": origin, "target": current.pos, "effect": "chain"})
				origin = current.pos
				var options = sim.foes(u).filter(func(v): return (e == 0 or not struck.has(v.uid)) and v.uid != current.uid and v.pos.distance_to(origin) < 4.8)
				options.sort_custom(func(a, b): return a.pos.distance_to(origin) < b.pos.distance_to(origin))
				current = options[0] if not options.is_empty() else {}
			if e == 2: dash_away(sim, u, 2)
		"basilisk":
			var t = pick(sim, u, func(v): return v.hp - (10000.0 if v.summon else 0.0))
			if t.is_empty(): return
			var victims = [t]
			if e == 0:
				var dir = (t.pos - u.pos).normalized()
				victims = sim.foes(u).filter(func(v): return (v.pos - u.pos).normalized().dot(dir) > 0.82 and u.pos.distance_to(v.pos) < HEX * 6)
			for v in victims:
				var secs = 1.5 if e == 0 else 2.5
				sim.status(v, "stun", secs); sim.status(v, "petrified", secs)
				hit(sim, u, v, ap(u, 100))
				if e == 1: dot(sim, u, v, ap(u, 180), 3.0, "poison")
				if e == 2: pull(sim, v, u.pos, 2)
		"treant":
			var allies = sim.wounded_allies(u)
			for a in allies.slice(0, 3 if e == 0 else 1): sim.heal(u, a, ap(u, 150), "signature")
			var near = sim.foes(u); near.sort_custom(func(a, b): return u.pos.distance_to(a.pos) < u.pos.distance_to(b.pos))
			if near.is_empty(): return
			var t = near[0]
			var rooted = within(sim, u, t.pos, 1) if e == 1 else [t]
			for v in rooted:
				sim.status(v, "root", 2.0 if e == 1 else 1.5); hit(sim, u, v, ap(u, 60))
			if e == 2: pull(sim, t, u.pos, 3)
		"naga":
			for a in allies_within(sim, u, 2):
				sim.shield(a, ap(u, 110), 4.0)
				if e == 1: a.moonwell = sim.time + 4.0; a.moonwell_src = u.uid
				if e == 2: buff(sim, a, "siren", {"as": 0.20, "while_shield": true}, 4.0)
			if e == 0:
				for v in within(sim, u, u.pos, 2): pull(sim, v, u.pos, 1); sim.status(v, "slow", 2.0)
		"unicorn":
			if e == 2:
				var w = sim.wounded_allies(u)
				if not w.is_empty() and w[0].uid != u.uid: move_to(sim, u, w[0].pos)
			var group = sim.living(u.team, false) if e == 1 else allies_within(sim, u, 2)
			for a in group:
				sim.heal(u, a, ap(u, 120) * (0.6 if e == 1 else 1.0), "signature")
				for k in ["stun", "root", "slow", "poison", "taunt", "confuse"]: a.status.erase(k)
				a.dots = a.dots.filter(func(dd): return dd.kind not in ["poison", "venom_true", "bleed", "burn"])
				sim.status(a, "cleansed", 1.5)
			if e == 0:
				var end = u.pos + (target.pos - u.pos).normalized() * HEX * 7
				for v in line_hits(sim, u, u.pos, end): hit(sim, u, v, ap(u, 150))
				sim.emit({"type": "bolt", "uid": u.uid, "pos": u.pos, "target": end, "effect": "beam"})
		"cyclops":
			var t = farthest(sim, u) if e == 1 else cluster(sim, u)
			if t.is_empty(): return
			sim.launch(u, t, ad(u, 600 if e == 1 else 300), clampf(u.pos.distance_to(t.pos) / 8.0, 0.7, 1.5), false, "meteor", e != 1)
			var shot = sim.projectiles.back()
			shot.heavy = true; shot.stun = 1.5; shot.radius = 2 if e == 0 else 1; shot.knock = e == 0; shot.roll = e == 2
			shot.true_damage = e == 1
		"thunderbird":
			var bonus_as = u.base_as_now / u.base_as - 1.0 if u.has("base_as_now") else 0.0
			var n = (5 if e == 0 else 3) + maxi(0, floori(bonus_as / 0.40))
			var pool = sim.foes(u)
			if pool.is_empty(): return
			for i in range(n):
				var v = cluster(sim, u) if e == 1 else pool[sim.rng.randi_range(0, pool.size() - 1)]
				if v.is_empty(): break
				var victims = within(sim, u, v.pos, 1) if e == 1 else [v]
				for w in victims:
					hit(sim, u, w, ap(u, 100) * (0.55 if e == 1 and w.uid != v.uid else 1.0))
					if e == 0: sim.status(w, "stun", 0.25)
				sim.emit({"type": "bolt", "uid": u.uid, "pos": u.pos, "target": v.pos, "effect": "stormcall"})
				pool = sim.foes(u)
				if pool.is_empty(): break
			if e == 2: dash_away(sim, u, 4)
		"sphinx":
			var list = sim.foes(u).filter(func(v): return not v.summon)
			list.sort_custom(func(a, b): return a.attack > b.attack)
			for t in list.slice(0, 2 if e == 1 else 1):
				sim.status(t, "confuse", 1.5); hit(sim, u, t, ap(u, 70))
				if e == 0: t.judgment = {"at": sim.time + 1.5, "src": u.uid, "dmg": ap(u, 180)}
		"pegasus":
			var b = 0.30 * u.ap / 100.0 * float(u.get("sig_mult", 1.0))
			for a in allies_within(sim, u, 3):
				var stats = {"as": b, "move": b}
				if e == 2: stats.ad = 0.20
				buff(sim, a, "dawnflight", stats, 5.0)
				sim.shield(a, ap(u, 60), 5.0)
				if e == 0 and a.uid != u.uid:
					var t = sim.find_unit(int(a.target))
					if not t.is_empty() and t.alive: sim.relocate_hex(a, a.pos + (t.pos - a.pos).normalized() * HEX)
			if e == 1: buff(sim, u, "skydancer", {"as": 0.60}, 5.0)
		"arachne":
			var cap = 6
			var n = mini(3, cap - pets(sim, u).size())
			for i in range(n):
				var s = summon(sim, u, "arachne", "Spiderling", ap(u, 90), ap(u, 20), 0.9)
				s.spider_slow = true; s.widow = ap(u, 60) if e == 0 else 0.0
			if e == 1:
				for v in within(sim, u, target.pos, 1): sim.status(v, "root", 1.5)
			if e == 2:
				var far = farthest(sim, u)
				var ps = pets(sim, u)
				if not far.is_empty() and not ps.is_empty():
					var center = Vector2.ZERO
					for p in ps: center += p.pos
					pull(sim, far, center / ps.size(), 6)
		"salamander":
			if e == 0:
				var end = u.pos + (target.pos - u.pos).normalized() * HEX * 6
				for v in line_hits(sim, u, u.pos, end): hit(sim, u, v, ap(u, 120))
				for i in range(3):
					sim.zones.append({"source": u.uid, "pos": u.pos.lerp(end, (i + 1) / 3.5), "credit": "signature", "radius": HEX * 0.8, "damage": ap(u, 30), "remaining": 4.0, "effect": "magma"})
				sim.emit({"type": "bolt", "uid": u.uid, "pos": u.pos, "target": end, "effect": "beam"})
			else:
				var targets = [target]
				if e == 1:
					var list = sim.foes(u); list.sort_custom(func(a, b): return u.pos.distance_to(a.pos) < u.pos.distance_to(b.pos))
					targets = list.slice(0, 3)
				for t in targets:
					var scale = 0.5 if e == 1 else 1.0
					for v in within(sim, u, t.pos, 1): hit(sim, u, v, ap(u, 120) * scale)
					sim.zones.append({"source": u.uid, "pos": t.pos, "credit": "signature", "radius": HEX, "damage": ap(u, 30) * scale, "remaining": 4.0, "effect": "magma"})
			if e == 2:
				dash_away(sim, u, 2); sim.status(u, "stealth", 1.0)

static func cast_sunfire(sim: BattleSim, u: Dictionary, target: Dictionary, e: int) -> void:
	var t = target if not target.is_empty() and target.alive else cluster(sim, u)
	if t.is_empty(): return
	if e == 1:
		var end = u.pos + (t.pos - u.pos).normalized() * HEX * 8
		for v in line_hits(sim, u, u.pos, end): hit(sim, u, v, ap(u, 240))
		sim.emit({"type": "bolt", "uid": u.uid, "pos": u.pos, "target": end, "effect": "beam"})
		return
	for v in within(sim, u, t.pos, 1):
		hit(sim, u, v, ap(u, 120)); dot(sim, u, v, ap(u, 20) * 4.0, 4.0, "burn")
	if e == 2:
		var c = ArenaGrid.nearest(t.pos)
		for a in sim.living(u.team, false):
			if ArenaGrid.distance(a.cell, c) <= 2: sim.heal(u, a, ap(u, 120), "signature")

static func pets(sim: BattleSim, u: Dictionary) -> Array:
	return sim.living(u.team).filter(func(a): return a.summon and a.owner == u.uid and not a.get("decoy", false))

static func stacks(t: Dictionary, u: Dictionary, kind: String) -> int:
	return t.dots.filter(func(d): return d.source == u.uid and str(d.kind).begins_with(kind)).size()

static func summon(sim: BattleSim, u: Dictionary, sp: String, name: String, hp: float, attack: float, aspd: float) -> Dictionary:
	var pet = HeroData.make_hero(sp, "pet", name, int(u.hero.level))
	var spot = u.pos + Vector2(sim.rng.randf_range(-1, 1), sim.rng.randf_range(-1, 1))
	var s = sim.add_unit(pet, u.team, spot, 1.0, u.uid)
	s.max_hp = maxf(1.0, hp); s.hp = s.max_hp; s.attack = attack; s.attack_basic = attack
	s.interval = 1.0 / maxf(0.05, aspd); s.ttl = 999.0
	s.res = u.res * 0.5; s.armor = s.res / (100.0 + s.res)
	return s

static func dash_away(sim: BattleSim, u: Dictionary, hexes: int) -> void:
	var foes = sim.foes(u)
	if foes.is_empty(): return
	foes.sort_custom(func(a, b): return u.pos.distance_to(a.pos) < u.pos.distance_to(b.pos))
	var dir = (u.pos - foes[0].pos).normalized()
	move_to(sim, u, u.pos + dir * HEX * hexes)
	sim.emit({"type": "dash", "uid": u.uid, "pos": u.pos})

# ---------------------------------------------------------------- hooks the sim calls
## Extra damage a signature's owner deals (petrified, poisoned, pinned, execute bonuses).
static func damage_mult(sim: BattleSim, source: Dictionary, target: Dictionary) -> float:
	var m = 1.0
	if sim.active(target, "petrified"): m *= 1.30
	if source.summon: return m
	var sp = str(source.hero.sp); var e = evo(source)
	if sp == "manticore" and target.dots.any(func(d): return d.source == source.uid): m *= 1.15
	if sp == "wendigo" and e == 1 and target.hp / target.max_hp < 0.40: m *= 1.30
	if sp == "owlbear" and e == 2 and int(target.get("pinned_by", -1)) == source.uid and sim.time < float(target.get("pinned_until", 0.0)): m *= 1.30
	return m

## After a basic attack lands.
static func on_basic(sim: BattleSim, u: Dictionary, target: Dictionary, amount: float) -> void:
	if u.summon:
		if u.get("spider_slow", false): buff(sim, target, "spider", {"as": -0.20}, 2.0)
		var owner = sim.find_unit(int(u.owner))
		if not owner.is_empty() and owner.hero.sp == "direwolf" and evo(owner) == 1: dot(sim, owner, target, ap(owner, 30), 3.0, "bleed")
		return
	var sp = str(u.hero.sp); var e = evo(u)
	match sp:
		"hydra":
			for v in within(sim, u, target.pos, 1):
				if v.uid != target.uid: sim.hurt(u, v, amount * 0.40, false, "passive")
			if e == 1: dot(sim, u, target, ap(u, 12) * 3.0, 3.0, "venom", true)
		"wyvern":
			if e == 1 and target.buffs.has("shred"):
				for v in within(sim, u, target.pos, 1):
					if v.uid != target.uid: sim.hurt(u, v, u.attack * 0.5, false, "passive")
		"kirin":
			if e == 2:
				u.sig.count = int(u.sig.get("count", 0)) + 1
				if u.sig.count % 3 == 0:
					var list = sim.foes(u).filter(func(v): return v.uid != target.uid)
					list.sort_custom(func(a, b): return target.pos.distance_to(a.pos) < target.pos.distance_to(b.pos))
					for v in list.slice(0, 2):
						sim.hurt(u, v, u.attack * 0.6, false, "passive")
						sim.emit({"type": "bolt", "uid": u.uid, "pos": target.pos, "target": v.pos, "effect": "chain"})
		"salamander":
			if e == 1: dot(sim, u, target, u.attack * 0.30, 3.0, "burn")

## Bonus to a basic attack before it lands (Lucky Foot's doubled hits).
static func basic_mult(u: Dictionary) -> float:
	if u.summon: return 1.0
	if int(u.sig.get("double_hits", 0)) > 0:
		u.sig.double_hits -= 1
		return 2.0
	return 1.0

## Every tick for each living champion.
static func tick(sim: BattleSim, u: Dictionary, dt: float) -> void:
	if u.summon: return
	var sp = str(u.hero.sp); var e = evo(u)
	match sp:
		"troll":
			sim.heal(u, u, u.max_hp * (0.03 if e == 0 else 0.015) * dt, "regeneration")
		"wendigo":
			if e == 2 and u.buffs.has("frenzy"):
				for v in within(sim, u, u.pos, 2):
					buff(sim, v, "horror", {"as": -0.30}, 0.5)
					sim.hurt(u, v, ap(u, 25) * dt, true, "signature")
		"golem":
			if e == 1 and float(u.sig.get("shard_time", 0.0)) > 0.0:
				u.sig.shard_time -= dt
				if u.sig.shard_time <= 0.0 or u.shield <= 0.0:
					var absorbed = maxf(0.0, float(u.sig.shard_watch) - u.shield)
					u.sig.shard_time = 0.0
					for v in within(sim, u, u.pos, 2): hit(sim, u, v, absorbed * 0.60)
					sim.emit({"type": "cast", "uid": u.uid, "effect": "quake", "name": "Shatter", "pos": u.pos, "target": u.pos})
		"zaratan":
			if u.sig.get("shell_wave", false) and not sim.active(u, "shell") and u.sig.has("absorbed"):
				var dmg = float(u.sig.absorbed) * 0.25
				u.sig.erase("absorbed"); u.sig.shell_wave = false
				for v in within(sim, u, u.pos, 2): hit(sim, u, v, dmg); push(sim, v, u.pos, 1)
				sim.emit({"type": "cast", "uid": u.uid, "effect": "tidal", "name": "Tidal Shell", "pos": u.pos, "target": u.pos})
		"nekomata":
			if u.sig.has("ambush_at") and sim.time >= float(u.sig.ambush_at):
				u.sig.erase("ambush_at")
				ambush(sim, u, int(u.sig.get("ambush_evo", -1)))
		"gargoyle":
			if u.sig.has("second_drop") and sim.time >= float(u.sig.second_drop):
				u.sig.erase("second_drop")
				var c = cluster(sim, u, true)
				if not c.is_empty():
					leap(sim, u, c)
					for v in within(sim, u, u.pos, 1): hit(sim, u, v, ad(u, 90))
					sim.emit({"type": "cast", "uid": u.uid, "effect": "stonedive", "name": "Belfry Hunter", "pos": u.pos, "target": u.pos})
		"harpy":
			if u.sig.has("return_at") and sim.time >= float(u.sig.return_at):
				u.sig.erase("return_at"); move_to(sim, u, u.start_pos)
		"wyvern":
			if e == 2 and sim.time >= float(u.sig.get("buffet_ready", 0.0)):
				var near = within(sim, u, u.pos, 1)
				if not near.is_empty():
					u.sig.buffet_ready = sim.time + 6.0
					for v in near: push(sim, v, u.pos, 1)
					dash_away(sim, u, 2)
	if u.has("judgment") and sim.time >= float(u.judgment.at):
		pass

static func ambush(sim: BattleSim, u: Dictionary, e: int) -> void:
	var t = lowest(sim, u)
	if t.is_empty(): return
	leap(sim, u, t)
	sim.emit({"type": "cast", "uid": u.uid, "effect": "vanish", "name": "Twin-Tail Ambush", "pos": u.pos, "target": t.pos})
	var dealt = 0.0
	var first = ap(u, 110) if e == 1 else ad(u, 145)
	dealt += hit(sim, u, t, first, e == 1)
	var second_t = t
	if e == 2:
		var other = sim.foes(u).filter(func(v): return v.uid != t.uid)
		other.sort_custom(func(a, b): return a.hp / a.max_hp < b.hp / b.max_hp)
		if not other.is_empty(): second_t = other[0]; leap(sim, u, second_t)
	dealt += hit(sim, u, second_t, first, true)
	if e == 0:
		sim.heal(u, u, dealt, "signature")
		if not t.alive or not second_t.alive:
			sim.status(u, "stealth", 1.5); u.sig.ambush_at = sim.time + 1.5; sim.status(u, "channel", 1.5)

## Called by the sim when a unit dies (spiderlings, decoys, serpent burn, judgment).
static func on_death(sim: BattleSim, dead: Dictionary) -> void:
	if dead.summon and float(dead.get("widow", 0.0)) > 0.0:
		var owner = sim.find_unit(int(dead.owner))
		if not owner.is_empty():
			for v in within(sim, owner, dead.pos, 1): hit(sim, owner, v, dead.widow)
	if dead.get("decoy", false):
		var owner = sim.find_unit(int(dead.owner))
		if not owner.is_empty() and evo(owner) == 1:
			for v in within(sim, owner, dead.pos, 1): hit(sim, owner, v, ap(owner, 100))
	if dead.has("serpent_spread"):
		var owner = sim.find_unit(int(dead.serpent_spread))
		if not owner.is_empty() and owner.alive:
			for v in within(sim, owner, dead.pos, 1): dot(sim, owner, v, ap(owner, 200), 3.0, "burn")

## Per-tick checks on any unit (confusion explosions, moonwell shields).
static func tick_any(sim: BattleSim, u: Dictionary) -> void:
	if u.has("judgment") and sim.time >= float(u.judgment.at):
		var j = u.judgment; u.erase("judgment")
		var src = sim.find_unit(int(j.src))
		if not src.is_empty():
			for v in sim.living(u.team).filter(func(a): return ArenaGrid.distance(a.cell, u.cell) <= 1):
				hit(sim, src, v, float(j.dmg))
			sim.emit({"type": "impact", "pos": u.pos, "effect": "meteor", "credit": "signature", "uid": src.uid, "heavy": true})
	if u.has("moonwell") and sim.time >= float(u.moonwell):
		var src = sim.find_unit(int(u.moonwell_src))
		var left = u.shield
		u.erase("moonwell")
		if left > 0.0 and not src.is_empty(): u.shield = 0.0; sim.heal(src, u, left, "signature")
