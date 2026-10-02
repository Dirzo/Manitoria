class_name AbilityFX
extends RefCounted
## Ability effect compositions. One composition per effect family; the caster's element and card
## palette give every creature its own version (Kirin's storm is gold, Thunderbird's is blue, etc).

const ELEMENT := {
	"phoenix": "fire", "salamander": "fire", "cerberus": "fire", "chimera": "fire",
	"kirin": "lightning", "thunderbird": "lightning",
	"naga": "water", "zaratan": "water",
	"yeti": "ice", "wendigo": "ice",
	"golem": "earth", "gargoyle": "earth", "troll": "earth", "cyclops": "earth", "minotaur": "earth",
	"treant": "nature", "jackalope": "nature", "owlbear": "nature",
	"basilisk": "poison", "manticore": "poison", "wyvern": "poison", "hydra": "poison", "arachne": "poison",
	"griffin": "wind", "harpy": "wind", "pegasus": "wind",
	"unicorn": "holy", "sphinx": "holy", "nemean": "holy",
	"nekomata": "shadow", "kitsune": "spirit", "direwolf": "spirit",
}
# Per element: main colour, hot/bright colour, particle motif, smoke colour.
const STYLE := {
	"fire": ["ff6a1c", "ffe2a0", "ember", Color(0.22, 0.16, 0.13, 0.55)],
	"lightning": ["7fb2ff", "eef6ff", "spark", Color(0.25, 0.28, 0.38, 0.5)],
	"water": ["3fc9e6", "d8fbff", "droplet", Color(0.6, 0.85, 0.95, 0.35)],
	"ice": ["8fd8ff", "f2fbff", "snow", Color(0.82, 0.92, 1.0, 0.4)],
	"earth": ["d39a55", "ffe3b0", "shard", Color(0.5, 0.43, 0.36, 0.6)],
	"nature": ["86d955", "eaffc9", "leaf", Color(0.45, 0.55, 0.35, 0.35)],
	"poison": ["8fe04a", "e9ffb8", "droplet", Color(0.35, 0.62, 0.22, 0.5)],
	"wind": ["cfe9f2", "ffffff", "feather", Color(0.75, 0.8, 0.82, 0.3)],
	"holy": ["ffd36a", "fffbe6", "star", Color(0.95, 0.9, 0.75, 0.3)],
	"shadow": ["a060ff", "f0d8ff", "glow", Color(0.12, 0.08, 0.18, 0.6)],
	"spirit": ["8fb8ff", "e8f0ff", "glow", Color(0.3, 0.35, 0.55, 0.4)],
}

static func element(sp: String) -> String:
	return ELEMENT.get(sp, "holy")

static func ctx(sp: String, palette_color: Color = Color(0, 0, 0, 0), rarity: String = "Uncommon") -> Dictionary:
	var el = element(sp); var st = STYLE[el]
	var main = Color(st[0])
	# Blend the card palette in so each ability painting still reads in its effect.
	if palette_color.a > 0.0: main = main.lerp(palette_color, 0.3)
	main = vivid(main, 1.3)
	var hot = vivid(Color(st[1]), 1.5)
	# A neighbouring hue gives every burst two tones instead of one flat colour.
	var alt = Color.from_hsv(fposmod(main.h + ALT_SHIFT.get(el, 0.08), 1.0), clampf(main.s * 1.1, 0.0, 1.0), clampf(main.v * 1.05, 0.0, 1.0))
	var boost = 1.25 if rarity == "Uncommon" else (1.6 if rarity == "Rare" else 2.0)
	return {"sp": sp, "el": el, "color": main, "hot": hot, "alt": alt, "motif": st[2], "smoke": st[3], "boost": boost, "rarity": rarity}

# Hue nudge for each element's second tone (fire leans magenta-red, storms lean violet, ...).
const ALT_SHIFT := {"fire": -0.06, "lightning": 0.1, "water": -0.08, "ice": 0.12, "earth": -0.05, "nature": -0.12, "poison": 0.2, "wind": 0.45, "holy": -0.08, "shadow": 0.12, "spirit": 0.1}

## Push saturation up (keeps near-white colours bright but tints them a little).
static func vivid(col: Color, amount: float) -> Color:
	return Color.from_hsv(col.h, clampf(maxf(col.s, 0.12) * amount, 0.0, 1.0), clampf(col.v * 1.04, 0.0, 1.0), col.a)

# ---------------------------------------------------------------- windup (gathering energy)
static func windup(vfx: VFX, c: Dictionary, at: Vector3, duration: float) -> void:
	vfx.rune(at, 1.8, c.color, 0, duration, 0.0, 1.6)
	vfx.spray(at + Vector3.UP * 1.2, int(18 * c.boost), "glow", c.hot, Vector2(-1.6, -0.8), Vector2(duration * 0.8, duration), 0.08, Vector3.UP, 1.6, 0.0, 1.5, 0.0, 0.0, 1, 0.0)
	vfx.glow(at + Vector3.UP * 1.5, 1.6, c.color, duration, 1, 0.0, 1.6)

# ---------------------------------------------------------------- per-family compositions
static func play(vfx: VFX, family: String, c: Dictionary, from: Vector3, to: Vector3, targets: Array = []) -> void:
	var fn = "fx_" + family
	var me = AbilityFX.new()
	if me.has_method(fn): me.call(fn, vfx, c, from, to, targets)
	else: me.fx_generic(vfx, c, from, to, targets)

func _dir(from: Vector3, to: Vector3) -> Vector3:
	var d = to - from; d.y = 0
	return d.normalized() if d.length() > 0.01 else Vector3.FORWARD

func _impact(vfx: VFX, c: Dictionary, at: Vector3, scale: float = 1.0) -> void:
	vfx.glow(at + Vector3.UP * 1.0, 2.8 * scale, c.hot, 0.35, 0, 0.0, 2.6)
	vfx.glow(at + Vector3.UP * 1.0, 4.2 * scale, c.alt, 0.45, 0, 0.0, 1.3)
	vfx.rune(at, 2.6 * scale, c.color, 1, 0.5, 0.0, 2.4)
	vfx.spray(at + Vector3.UP * 0.8, int(24 * c.boost * scale), c.motif, c.color, Vector2(2.5, 6.0), Vector2(0.35, 0.75), 0.13, Vector3.UP, 1.3, 5.0, 1.2, 0.5 if c.motif == "spark" else 0.0, 0.0, 0.0, 0.0, c.alt)

func _element_burst(vfx: VFX, c: Dictionary, at: Vector3, r: float) -> void:
	match c.el:
		"fire":
			for i in range(5):
				var a = i * TAU / 5.0
				vfx.flame(at + Vector3(cos(a), 0, sin(a)) * r * 0.45, Vector2(0.7, 1.4) * r * 0.6, c.color, 0.9, i * 0.03)
			vfx.smoke(at + Vector3.UP * 1.4, 2.0 * r, c.smoke, 1.6, 0.15)
		"ice":
			for i in range(6):
				var a = i * 1.9
				vfx.crystal(at + Vector3(cos(a), 0, sin(a)) * r * 0.5, 0.8 + (i % 3) * 0.3, 0.15, c.color, 1.4, i * 0.02, Vector3(sin(a) * 0.4, 0, cos(a) * 0.4))
			vfx.smoke(at + Vector3.UP * 0.4, 2.2 * r, c.smoke, 1.4, 0.0, Vector3(0, 0.2, 0))
		"earth":
			for i in range(5):
				var a = i * TAU / 5.0
				var p0 = at + Vector3(cos(a) * r * 0.6, 0.1, sin(a) * r * 0.6)
				vfx.rock(p0, 0.18 + (i % 3) * 0.08, Color("7b6c5d"), 0.0, 1.2, 0.0, _hop(p0, Vector3(cos(a), 0, sin(a)) * 1.6, 3.4))
			vfx.smoke(at + Vector3.UP * 0.4, 2.2 * r, c.smoke, 1.5)
		"water":
			vfx.swirl(at, 0.3 * r, 1.1 * r, 1.4 * r, c.color, c.hot, 0.9, 14.0, 0.9)
			vfx.spray(at + Vector3.UP * 0.3, 30, "droplet", c.hot, Vector2(2, 4), Vector2(0.5, 0.9), 0.1, Vector3.UP, 0.9, 8.0, 0.4)
		"poison":
			for i in range(4): vfx.smoke(at + Vector3(randf_range(-0.6, 0.6), 0.5, randf_range(-0.6, 0.6)) * r, 1.4 * r, c.smoke, 1.8, i * 0.08, Vector3(0, 0.35, 0), 0.4)
			vfx.spray(at + Vector3.UP * 0.4, 20, "droplet", c.color, Vector2(1.5, 3), Vector2(0.4, 0.9), 0.1, Vector3.UP, 1.0, 7.0)
		"lightning":
			vfx.bolt(at + Vector3(randf_range(-0.4, 0.4), 7.0, randf_range(-0.4, 0.4)), at, c.color, 0.2, 0.4, 1)
		"shadow", "spirit":
			for i in range(3): vfx.smoke(at + Vector3.UP * 0.6, 1.6 * r, c.smoke, 1.3, i * 0.06, Vector3(0, 0.5, 0), 0.8)
		"nature":
			vfx.spray(at + Vector3.UP * 0.4, 26, "leaf", c.color, Vector2(1.5, 3.2), Vector2(0.8, 1.4), 0.15, Vector3.UP, 1.1, 1.5, 1.0)
		"wind":
			vfx.swirl(at, 0.4 * r, 1.4 * r, 1.8 * r, c.color, c.hot, 0.8, 16.0, 0.7)
			vfx.spray(at + Vector3.UP * 0.6, 16, "feather", c.hot, Vector2(1.5, 3.0), Vector2(0.9, 1.5), 0.18, Vector3.UP, 1.2, 0.6, 0.8)
		_:
			vfx.spray(at + Vector3.UP * 0.6, 24, "star", c.hot, Vector2(1.2, 3.0), Vector2(0.6, 1.1), 0.12, Vector3.UP, 1.1, 0.5, 1.0)

func _hop(start: Vector3, vel: Vector3, up: float) -> Callable:
	# Debris thrown by an eruption: analytic ballistic arc (pause-safe), spinning, then sinks away.
	return func(node: Node3D, a: float):
		var p = start + vel * a + Vector3.UP * (up * a - 4.9 * a * a)
		p.y = maxf(p.y, start.y - 0.25 - maxf(0.0, a - 1.0) * 0.6)
		node.position = p
		node.rotation = Vector3(3, 2, 1) * a

# QUAKE / SMASH: ground shock, cracks, flung rock, dust
func fx_quake(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, _t: Array) -> void:
	var at = from
	vfx.rune(at, 3.2, c.color, 1, 0.8, 0.0, 2.2)
	vfx.rune(at, 3.0, c.color, 2, 1.6, 0.05, 1.6)
	for i in range(10):
		var a = i * TAU / 10.0 + randf() * 0.3; var r = randf_range(0.8, 2.6)
		var p0 = at + Vector3(cos(a) * r, -0.2, sin(a) * r)
		vfx.rock(p0, randf_range(0.14, 0.32), Color("7f6f60"), 0.35 if c.el == "fire" else 0.0, 1.4, randf() * 0.12, _hop(p0, Vector3(cos(a), 0, sin(a)) * randf_range(0.8, 2.0), randf_range(3.0, 5.5)))
	for i in range(6):
		var a = i * TAU / 6.0
		vfx.smoke(at + Vector3(cos(a) * 1.6, 0.3, sin(a) * 1.6), 2.0, Color(0.5, 0.44, 0.37, 0.55), 1.6, 0.05, Vector3(cos(a) * 0.8, 0.3, sin(a) * 0.8))
	_element_burst(vfx, c, at, 1.4)

func fx_smash(vfx, c, f, t, x): fx_quake(vfx, c, t, t, x)

# FISSURE: a travelling rupture with rising spikes along the lane
func fx_fissure(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, _t: Array) -> void:
	var d = _dir(from, to); var length = maxf(4.0, from.distance_to(to))
	for i in range(12):
		var p = from + d * (0.8 + i * length / 12.0) + d.cross(Vector3.UP) * randf_range(-0.35, 0.35)
		var delay = i * 0.045
		vfx.rune(p, 1.0, c.color, 2, 1.3, delay, 1.6)
		vfx.crystal(p, randf_range(0.7, 1.4), randf_range(0.14, 0.24), Color("a38a6a") if c.el != "ice" else c.color, 1.3, delay, Vector3(randf_range(-0.35, 0.35), 0, randf_range(-0.35, 0.35)))
		vfx.smoke(p + Vector3.UP * 0.3, 1.2, Color(0.5, 0.44, 0.36, 0.5), 1.2, delay)
	vfx.spray(from + d, 40, "shard", c.color, Vector2(2, 5), Vector2(0.5, 1.0), 0.12, d + Vector3.UP, 0.6, 6.0, 0.6)

# METEOR / BOULDER: the flight is drawn by the projectile; this is the landing
func fx_meteor(vfx: VFX, c: Dictionary, _from: Vector3, to: Vector3, _t: Array) -> void:
	vfx.glow(to + Vector3.UP * 0.6, 4.5, c.hot, 0.45, 0, 0.0, 2.6)
	vfx.rune(to, 3.4, c.color, 1, 0.9, 0.0, 2.4)
	vfx.rune(to, 2.6, Color("ff8a3a") if c.el in ["fire", "earth"] else c.color, 2, 2.4, 0.0, 1.8)
	vfx.rock(to + Vector3.UP * 0.2, 0.6, Color("4a3b31"), 1.0 if c.el in ["fire", "earth"] else 0.3, 2.4)
	for i in range(8):
		var a = i * TAU / 8.0
		var p0 = to + Vector3(cos(a) * 0.5, 0.2, sin(a) * 0.5)
		vfx.rock(p0, randf_range(0.12, 0.25), Color("6a5a4c"), 0.6, 1.4, 0.0, _hop(p0, Vector3(cos(a), 0, sin(a)) * randf_range(1.5, 3.0), randf_range(3.5, 6.0)))
	vfx.spray(to + Vector3.UP * 0.4, int(50 * c.boost), c.motif if c.el != "earth" else "ember", c.hot, Vector2(3, 7), Vector2(0.5, 1.1), 0.1, Vector3.UP, 1.1, 7.0, 1.0, 0.4)
	for i in range(5): vfx.smoke(to + Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1)), 2.6, c.smoke if c.el != "fire" else Color(0.25, 0.2, 0.18, 0.6), 2.2, i * 0.05, Vector3(0, 0.7, 0))
	_element_burst(vfx, c, to, 1.6)

func fx_boulder(vfx, c, f, t, x): fx_meteor(vfx, c, f, t, x)

# STORM / STORMCALL: overhead cloud and branching strikes on each target
func fx_storm(vfx: VFX, c: Dictionary, _from: Vector3, to: Vector3, targets: Array) -> void:
	var pts = targets if not targets.is_empty() else [to]
	var center = Vector3.ZERO
	for p in pts: center += p
	center /= pts.size()
	for i in range(3):
		vfx.smoke(center + Vector3(randf_range(-1.2, 1.2), 5.6, randf_range(-0.8, 0.8)), 2.8, Color(0.2, 0.21, 0.3, 0.5), 1.4, i * 0.05, Vector3(0, 0, 0), 0.5)
	for k in range(pts.size()):
		var p: Vector3 = pts[k]; var delay = k * 0.09
		vfx.bolt(p + Vector3(randf_range(-0.6, 0.6), 5.8, randf_range(-0.6, 0.6)), p, c.color, 0.28 * c.boost, 0.6, 3, delay)
		vfx.glow(p + Vector3.UP * 0.4, 3.0, c.hot, 0.35, 0, delay, 2.6)
		vfx.rune(p, 1.4, c.color, 1, 0.6, delay, 2.4)
		vfx.rune(p, 1.0, Color(0.25, 0.25, 0.3), 4, 1.8, delay, 0.6)
		vfx.spray(p + Vector3.UP * 0.2, 26, "spark", c.hot, Vector2(3, 7), Vector2(0.25, 0.6), 0.05, Vector3.UP, 1.3, 9.0, 1.5, 0.08, delay)

func fx_stormcall(vfx, c, f, t, x): fx_storm(vfx, c, f, t, x)

# CHAIN LIGHTNING: arcs hop target to target
func fx_chain(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, targets: Array) -> void:
	var prev = from + Vector3.UP * 1.4
	var pts = targets if not targets.is_empty() else [to]
	for k in range(pts.size()):
		var p = pts[k] + Vector3.UP * 1.0
		vfx.bolt(prev, p, c.color, 0.26 * c.boost, 0.65, 2, k * 0.08, 0.6)
		vfx.glow(p, 2.0, c.hot, 0.3, 0, k * 0.08, 2.4)
		vfx.spray(p, 16, "spark", c.hot, Vector2(2, 5), Vector2(0.2, 0.5), 0.05, Vector3.UP, 1.4, 5.0, 1.5, 0.08, k * 0.08)
		prev = p

# BEAM / LANCE: channelled lance with muzzle and impact glows
func fx_beam(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, _t: Array) -> void:
	var d = _dir(from, to); var a = from + Vector3.UP * 1.3 + d * 0.6; var b = to + Vector3.UP * 1.1
	vfx.beam(a, b, 0.26 * c.boost, c.color, 0.85)
	vfx.beam(a, b, 0.07, c.hot, 0.85)
	vfx.glow(a, 1.8, c.hot, 0.85, 1, 0.0, 2.4)
	vfx.glow(b, 1.6, c.color, 0.85, 1, 0.0, 2.0)
	vfx.spray(a, int(50 * c.boost), c.motif if c.motif != "leaf" else "star", c.hot, Vector2(6, 11), Vector2(0.3, 0.8), 0.07, d, 0.15, 0.0, 0.3, 0.08)
	vfx.spray(b, 24, "spark", c.hot, Vector2(2, 5), Vector2(0.2, 0.5), 0.06, Vector3.UP - d, 1.0, 4.0, 1.2, 0.06)
	vfx.rune(from, 1.3, c.color, 0, 1.0, 0.0, 1.4)

func fx_gaze(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, _t: Array) -> void:
	var a = from + Vector3.UP * 1.3; var b = to + Vector3.UP * 1.0
	vfx.beam(a, b, 0.17, c.color.lerp(Color("b8ff7a"), 0.5), 0.7)
	vfx.glow(a, 1.2, Color("d9ff9a"), 0.7, 1, 0.0, 1.6)
	for i in range(6):
		var ang = i * TAU / 6.0
		vfx.crystal(to + Vector3(cos(ang) * 0.4, 0, sin(ang) * 0.4), randf_range(0.9, 1.5), 0.2, Color("a79d8a"), 2.2, 0.15 + i * 0.03, Vector3(sin(ang) * 0.25, 0, cos(ang) * 0.25))
	vfx.smoke(to + Vector3.UP * 0.6, 2.0, Color(0.6, 0.58, 0.5, 0.5), 1.6, 0.2)

# FIRE / FLAMEWAVE / breath: a rolling cone of flame tongues travelling to the target
func fx_fire(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, _t: Array) -> void:
	var d = _dir(from, to); var mouth = from + Vector3.UP * 1.2 + d * 0.8
	var dist = maxf(2.0, mouth.distance_to(to))
	var tongue_tint = c.color if c.el == "fire" else c.color.lerp(Color("ff7a2a"), 0.2)
	for i in range(22):
		var delay = i * 0.025
		var start = mouth
		var side = d.cross(Vector3.UP) * randf_range(-0.6, 0.6)
		var vel = (d * dist + side * 2.4) / 0.55
		var sz = randf_range(0.9, 1.4)
		vfx.flame(start, Vector2(0.8, 1.0) * sz, tongue_tint, 0.62, delay, Color("fff1c8"), func(n, a): var k = minf(a, 0.55); n.position = start + vel * k + Vector3(0, -0.8 * k, 0); n.scale = Vector3(0.8 + a * 2.6, 0.9 + a * 2.2, 1.0) * sz)
		if i % 3 == 0:
			vfx.glow(start, 0.9, tongue_tint, 0.55, 1, delay, 1.2, func(n, a): var k = minf(a, 0.55); n.position = start + vel * k + Vector3(0, -0.6 * k, 0); n.scale = Vector3.ONE * (0.8 + a * 3.0))
	vfx.spray(mouth, int(60 * c.boost), "ember", c.hot, Vector2(5, 9), Vector2(0.4, 0.9), 0.08, d, 0.25, -0.5, 0.6, 0.15)
	# The ground keeps burning where it lands.
	for i in range(5):
		var p = to + Vector3(randf_range(-1.1, 1.1), 0, randf_range(-1.1, 1.1))
		vfx.flame(p, Vector2(0.7, 1.3), tongue_tint, 1.6, 0.4 + i * 0.05)
	vfx.rune(to, 2.4, Color("ff7a2a"), 4, 2.2, 0.35, 1.4)
	vfx.smoke(to + Vector3.UP * 1.6, 2.8, Color(0.2, 0.16, 0.14, 0.5), 2.2, 0.5)

func fx_flamewave(vfx, c, f, t, x): fx_fire(vfx, c, f, t, x)
func fx_threefold(vfx, c, f, t, x): fx_fire(vfx, c, f, t, x)

# MAGMA / lava pool
func fx_magma(vfx: VFX, c: Dictionary, _from: Vector3, to: Vector3, _t: Array) -> void:
	vfx.rune(to, 2.6, Color("ff5a14"), 3, 3.0, 0.0, 2.4)
	vfx.rune(to, 2.4, Color("ffb050"), 2, 3.0, 0.1, 2.0)
	for i in range(6):
		var p = to + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
		vfx.flame(p, Vector2(0.6, 1.0), Color("ff5a14"), 2.4, i * 0.1)
	vfx.spray(to + Vector3.UP * 0.2, 40, "ember", Color("ffb050"), Vector2(2, 5), Vector2(0.6, 1.3), 0.1, Vector3.UP, 0.6, 5.0, 0.5, 0.2)
	vfx.smoke(to + Vector3.UP * 1.2, 3.0, Color(0.25, 0.18, 0.15, 0.55), 2.6, 0.2)

# FROST / FROSTROAR: nova of ice crystals encasing the area
func fx_frost(vfx: VFX, c: Dictionary, _from: Vector3, to: Vector3, _t: Array) -> void:
	var ice = c.color if c.el in ["ice", "water"] else c.color.lerp(Color("aee6ff"), 0.5)
	vfx.rune(to, 2.8, ice, 1, 0.7, 0.0, 2.2)
	vfx.rune(to, 2.6, ice.lightened(0.3), 3, 2.0, 0.0, 1.2)
	for i in range(16):
		var a = randf() * TAU; var r = randf_range(0.3, 2.2)
		vfx.crystal(to + Vector3(cos(a) * r, 0, sin(a) * r), randf_range(0.6, 1.6), randf_range(0.12, 0.26), ice, 2.0, r * 0.06, Vector3(sin(a) * 0.45 * r / 2.2, 0, cos(a) * 0.45 * r / 2.2))
	vfx.spray(to + Vector3.UP * 0.8, int(50 * c.boost), "snow", Color("f2fbff"), Vector2(1, 3), Vector2(1.0, 2.0), 0.1, Vector3.UP, 1.3, 0.5, 0.9)
	for i in range(4): vfx.smoke(to + Vector3(randf_range(-1, 1), 0.3, randf_range(-1, 1)), 2.4, Color(0.85, 0.93, 1.0, 0.35), 2.0, i * 0.05, Vector3(0, 0.15, 0))

func fx_frostroar(vfx, c, f, t, x): fx_frost(vfx, c, t, f, x)

# ROOTS / ROOTBLOOM / BROOD-webs: thorned vines burst up and coil around the area
func fx_roots(vfx: VFX, c: Dictionary, _from: Vector3, to: Vector3, _t: Array) -> void:
	# Meshy root-claw bursts up under the target and clenches.
	vfx.prop("root_claw", to + Vector3(0, -0.05, 0), 2.2, {"scale": 2.1, "yaw": randf() * TAU, "solid": true, "base": Color(0.36, 0.26, 0.17) if c.el != "poison" else Color(0.3, 0.24, 0.36), "tint": c.color, "rise": 0.14})
	var bark = Color("6b4a2c") if c.el != "poison" else Color("4a3a5a")
	for i in range(7):
		var a = i * TAU / 7.0 + randf() * 0.4; var r0 = randf_range(0.9, 1.6)
		var pts := PackedVector3Array()
		for k in range(12):
			var t = k / 11.0
			var ang = a + t * randf_range(2.2, 3.4)
			var rr = lerpf(r0, 0.35, t)
			pts.append(to + Vector3(cos(ang) * rr, t * randf_range(1.6, 2.4), sin(ang) * rr))
		vfx.vine(pts, randf_range(0.13, 0.2), bark, c.color, 2.2, i * 0.04)
	vfx.rune(to, 2.2, c.color, 3, 2.2, 0.0, 1.0)
	vfx.spray(to + Vector3.UP * 0.3, 30, "leaf", c.color, Vector2(1, 2.5), Vector2(0.9, 1.6), 0.14, Vector3.UP, 1.0, 1.0, 1.0)
	vfx.smoke(to + Vector3.UP * 0.2, 2.4, Color(0.4, 0.35, 0.28, 0.4), 1.4)

func fx_rootbloom(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, t: Array) -> void:
	fx_roots(vfx, c, from, to, t); fx_renew(vfx, c, from, from, [])

# TOXIC / VENOM / ACID: bubbling poison cloud and dripping pool
func fx_toxic(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, _t: Array) -> void:
	var tox = c.color if c.el == "poison" else c.color.lerp(Color("8fe04a"), 0.5)
	var d = _dir(from, to)
	vfx.spray(from + Vector3.UP * 1.2 + d * 0.6, 30, "droplet", tox, Vector2(5, 8), Vector2(0.4, 0.6), 0.12, d + Vector3.UP * 0.4, 0.2, 6.0, 0.2)
	vfx.rune(to, 2.5, tox, 3, 3.2, 0.3, 1.5)
	for i in range(9):
		var p = to + Vector3(randf_range(-1.3, 1.3), randf_range(0.3, 1.1), randf_range(-1.3, 1.3))
		vfx.smoke(p, randf_range(1.2, 2.0), Color(tox.r * 0.5, tox.g * 0.6, tox.b * 0.35, 0.55), 2.6, 0.3 + i * 0.05, Vector3(0, 0.25, 0), 0.5)
	vfx.spray(to + Vector3.UP * 0.2, 36, "glow", tox.lightened(0.3), Vector2(0.4, 1.2), Vector2(1.0, 2.2), 0.09, Vector3.UP, 0.8, -0.3, 0.6, 0.0, 0.3, 1, 1.4)

func fx_acid(vfx, c, f, t, x): fx_toxic(vfx, c, f, t, x)
func fx_venom(vfx, c, f, t, x): fx_toxic(vfx, c, f, t, x)
func fx_poison(vfx, c, f, t, x): fx_toxic(vfx, c, f, t, x)

# GUST / TAILWIND: a wind blast of swirling streaks carrying the element's debris
func fx_gust(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, _t: Array) -> void:
	var d = _dir(from, to)
	var start = from + d * 0.8
	var travel = maxf(3.0, start.distance_to(to))
	for i in range(3):
		var delay = i * 0.08
		var s0 = start + Vector3.UP * (0.2 + i * 0.1)
		vfx.swirl(s0, 0.35, 1.3, 2.4, c.color, c.hot, 0.9, 16.0, 0.8, delay, func(n, a): n.position = s0 + d * travel * minf(a / 0.6, 1.0); n.rotation.y = a * 2.0)
	var debris = {"water": "droplet", "poison": "droplet", "nature": "leaf", "fire": "ember", "ice": "snow"}.get(c.el, "feather")
	vfx.spray(start + Vector3.UP * 1.0, int(40 * c.boost), debris, c.hot, Vector2(6, 10), Vector2(0.5, 1.0), 0.16, d, 0.35, 0.5, 0.4)
	vfx.spray(start + Vector3.UP * 1.0, 40, "spark", c.color, Vector2(8, 13), Vector2(0.3, 0.6), 0.05, d, 0.15, 0.0, 0.2, 0.25)
	vfx.smoke(to + Vector3.UP * 0.5, 2.4, c.smoke, 1.2, 0.35, d * 1.5)

func fx_tailwind(vfx: VFX, c: Dictionary, from: Vector3, _to: Vector3, _t: Array) -> void:
	vfx.swirl(from, 1.4, 2.4, 2.2, c.color, c.hot, 1.4, 10.0, 0.6)
	vfx.spray(from + Vector3.UP * 0.5, 40, "feather", c.hot, Vector2(1.5, 3.5), Vector2(1.0, 1.8), 0.2, Vector3.UP, 1.2, 0.3, 0.6)
	vfx.rune(from, 2.0, c.color, 0, 1.4, 0.0, 1.2)

# WHIRL: a cyclone around the caster
func fx_whirl(vfx: VFX, c: Dictionary, from: Vector3, _to: Vector3, _t: Array) -> void:
	vfx.swirl(from, 0.9, 2.4, 3.2, c.color, c.hot, 1.2, 14.0, 1.0)
	vfx.swirl(from, 0.6, 1.9, 2.6, c.hot, Color.WHITE, 1.2, 18.0, 0.7, 0.05)
	vfx.spray(from + Vector3.UP * 0.8, 40, "spark", c.hot, Vector2(4, 8), Vector2(0.3, 0.7), 0.05, Vector3.UP, 1.5, 3.0, 1.0, 0.2)
	vfx.smoke(from + Vector3.UP * 0.3, 3.4, Color(0.5, 0.45, 0.38, 0.45), 1.3, 0.0, Vector3(0, 0.3, 0))
	vfx.rune(from, 2.6, c.color, 1, 0.8, 0.0, 1.8)

# WARD / TIDAL / BULWARK / SHELLUP: shields bloom over every protected ally
func fx_ward(vfx: VFX, c: Dictionary, from: Vector3, _to: Vector3, targets: Array) -> void:
	var tint = c.color.lerp(Color("7de6d8"), 0.3)
	vfx.rune(from, 2.8, tint, 0, 1.6, 0.0, 1.8)
	var pts = targets if not targets.is_empty() else [from]
	for k in range(pts.size()):
		var p: Vector3 = pts[k]
		vfx.shield(p + Vector3.UP * 1.0, 1.2, tint, 1.8, 0.0, 0.08 + k * 0.05)
		vfx.spray(p + Vector3.UP * 0.2, 16, "star", c.hot, Vector2(0.6, 1.4), Vector2(0.8, 1.4), 0.1, Vector3.UP, 0.5, -0.4, 0.4, 0.0, k * 0.05, 1, 0.9)
	if c.el == "water": vfx.swirl(from, 1.2, 2.0, 1.6, c.color, c.hot, 1.2, 12.0, 0.7)

func fx_tidal(vfx, c, f, t, x): fx_ward(vfx, c, f, t, x)
func fx_bulwark(vfx, c, f, t, x): fx_ward(vfx, c, f, t, x)
func fx_shellup(vfx, c, f, t, x): fx_ward(vfx, c, f, t, x)

# RENEW / RADIANCE / REGROWTH / REBIRTH: pillars of light and rising motes over healed allies
func fx_renew(vfx: VFX, c: Dictionary, from: Vector3, _to: Vector3, targets: Array) -> void:
	var tint = c.color.lerp(Color("9df2c8"), 0.35)
	vfx.rune(from, 2.4, tint, 0, 1.6, 0.0, 1.6)
	var pts = targets if not targets.is_empty() else [from]
	var motif = {"nature": "leaf", "holy": "star", "water": "droplet", "fire": "ember"}.get(c.el, "petal")
	for k in range(pts.size()):
		var p: Vector3 = pts[k]; var delay = 0.1 + k * 0.08
		vfx.beam(p, p + Vector3.UP * 4.5, 0.45, tint, 1.1, delay, 1.0)
		vfx.glow(p + Vector3.UP * 1.0, 2.2, c.hot, 0.8, 0, delay, 1.6)
		vfx.spray(p + Vector3.UP * 0.2, 26, motif, c.hot, Vector2(0.8, 2.0), Vector2(1.0, 1.7), 0.13, Vector3.UP, 0.5, -0.6, 0.5, 0.0, delay, 1, 0.6)

func fx_radiance(vfx, c, f, t, x): fx_renew(vfx, c, f, t, x)
func fx_regrowth(vfx, c, f, t, x): fx_renew(vfx, c, f, t, x)
func fx_rebirth(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, t: Array) -> void:
	for i in range(8):
		var a = i * TAU / 8.0
		vfx.flame(to + Vector3(cos(a), 0, sin(a)) * 0.7, Vector2(0.9, 2.4), Color("ff6a1c"), 1.6, i * 0.04)
	vfx.beam(to, to + Vector3.UP * 6.0, 0.7, Color("ffb050"), 1.3, 0.0, 1.0)
	vfx.spray(to + Vector3.UP * 0.5, 80, "ember", Color("ffe2a0"), Vector2(2, 6), Vector2(0.8, 1.6), 0.1, Vector3.UP, 0.6, -1.0, 0.6, 0.3)

# RALLY / PRIDEROAR / HOWL: a golden war-cry shockwave and rising embers of courage
func fx_rally(vfx: VFX, c: Dictionary, from: Vector3, _to: Vector3, targets: Array) -> void:
	vfx.prop("war_banner", from + Vector3(0.9, 0, -0.7), 2.6, {"scale": 4.2, "yaw": PI * 0.5, "solid": true, "base": Color(0.5, 0.38, 0.26), "tint": c.color, "rise": 0.12})
	var gold = c.color.lerp(Color("ffcf6a"), 0.45)
	vfx.rune(from, 3.4, gold, 1, 0.9, 0.0, 2.2)
	vfx.rune(from, 2.4, gold, 0, 1.6, 0.0, 1.6)
	vfx.beam(from, from + Vector3.UP * 5.0, 0.4, gold, 0.9, 0.0, 1.0)
	for p in targets:
		vfx.spray(p + Vector3.UP * 0.1, 18, "star", gold.lightened(0.3), Vector2(1.0, 2.2), Vector2(0.7, 1.2), 0.12, Vector3.UP, 0.4, -0.2, 0.5, 0.0, 0.15)
		vfx.glow(p + Vector3.UP * 1.0, 1.6, gold, 0.6, 0, 0.15, 1.4)

func fx_prideroar(vfx, c, f, t, x): fx_rally(vfx, c, f, t, x)
func fx_howl(vfx, c, f, t, x): fx_rally(vfx, c, f, t, x)

# DRAIN / HUNGER: a siphon stream flows from the victim back to the caster
func fx_drain(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, _t: Array) -> void:
	var tint = c.color.lerp(Color("ff3a5a"), 0.4)
	var a = to + Vector3.UP * 1.0; var b = from + Vector3.UP * 1.3
	vfx.beam(a, b, 0.14, tint, 0.9)
	var vel = (b - a) / 0.6
	for i in range(12):
		var delay = i * 0.05
		vfx.glow(a, 0.5, tint.lightened(0.3), 0.6, 1, delay, 2.2, func(n, age): n.position = a + vel * age + Vector3(0, sin(age * 12.0 + i) * 0.2, 0))
	vfx.smoke(to + Vector3.UP * 0.8, 1.8, Color(0.3, 0.05, 0.08, 0.5), 1.2, 0.0, Vector3(0, 0.4, 0), 0.4)
	vfx.glow(b, 1.8, tint, 0.9, 0, 0.4, 1.8)

func fx_hunger(vfx, c, f, t, x): fx_drain(vfx, c, f, t, x)

# FEAR: spectral dread rolls out as dark smoke and a sickly ring
func fx_fear(vfx: VFX, c: Dictionary, from: Vector3, _to: Vector3, _t: Array) -> void:
	# A spectral horned skull looms over the caster and rushes forward.
	var skull_d = Vector3(1, 0, 0) if _to.x >= from.x else Vector3(-1, 0, 0)
	vfx.prop("horned_skull", from + Vector3.UP * 2.2, 1.5, {"scale": 1.8, "yaw": atan2(skull_d.x, skull_d.z), "tint": c.color.lerp(Color("8a4dff"), 0.5), "hot": Color("e8d8ff"), "intensity": 1.6, "update": func(n, age): n.position = from + Vector3.UP * (2.2 + age * 0.3) + skull_d * age * age * 2.2})
	var tint = c.color.lerp(Color("8a4dff"), 0.35)
	vfx.rune(from, 3.4, tint, 1, 1.0, 0.0, 1.8)
	for i in range(10):
		var a = i * TAU / 10.0
		var p = from + Vector3(cos(a) * 0.6, 0.6, sin(a) * 0.6)
		vfx.smoke(p, 1.8, Color(0.08, 0.05, 0.12, 0.7), 1.6, i * 0.02, Vector3(cos(a) * 1.8, 0.4, sin(a) * 1.8), 0.0)
	vfx.spray(from + Vector3.UP * 1.0, 30, "glow", tint, Vector2(2, 4), Vector2(0.8, 1.4), 0.12, Vector3.UP, 1.4, 0.0, 0.8)
	vfx.glow(from + Vector3.UP * 2.2, 2.0, tint, 1.0, 1, 0.0, 1.2)

# SILENCE / SHRIEK / RIDDLE: rune seals clamp over the targets
func fx_silence(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, targets: Array) -> void:
	var tint = c.color.lerp(Color("c09dff"), 0.4)
	var pts = targets if not targets.is_empty() else [to]
	for k in range(pts.size()):
		var p: Vector3 = pts[k]
		var seal = vfx.rune(p + Vector3.UP * 2.6, 0.9, tint, 0, 1.6, k * 0.05, 2.2)
		seal.rotation.x = 0.0
		vfx.rune(p, 1.2, tint, 1, 0.7, k * 0.05, 1.8)
		vfx.spray(p + Vector3.UP * 2.4, 14, "star", tint.lightened(0.3), Vector2(0.4, 1.0), Vector2(0.6, 1.2), 0.08, Vector3.DOWN, 0.6, 0.0, 0.5, 0.0, k * 0.05)
	vfx.rune(to, 2.8, tint, 1, 0.8, 0.0, 1.6)

func fx_shriek(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, t: Array) -> void:
	vfx.prop("horned_skull", from + Vector3.UP * 2.0, 1.1, {"scale": 1.6, "yaw": atan2(to.x - from.x, to.z - from.z), "tint": c.color.lerp(Color("7a5cff"), 0.45), "intensity": 0.75, "update": func(n, age): n.scale = Vector3.ONE * (1.6 + age * 1.4)})
	for i in range(3): vfx.rune(from + Vector3.UP * 0.4, 3.6, c.color, 1, 0.8, i * 0.12, 2.0)
	fx_silence(vfx, c, from, from, t)

func fx_riddle(vfx, c, f, t, x): fx_silence(vfx, c, f, t, x)

# WISPS / FOXFIRE / BARRAGE: launch flourish; the projectiles themselves carry the trails
func fx_wisps(vfx: VFX, c: Dictionary, from: Vector3, _to: Vector3, _t: Array) -> void:
	vfx.rune(from, 1.8, c.color, 0, 1.0, 0.0, 1.6)
	for i in range(3):
		var a = i * TAU / 3.0
		vfx.glow(from + Vector3(cos(a) * 0.8, 1.6, sin(a) * 0.8), 1.0, c.hot, 0.4, 0, 0.0, 2.0)

func fx_foxfire(vfx, c, f, t, x):
	vfx.prop("fox_mask", f + Vector3.UP * 2.4, 1.5, {"scale": 1.9, "intensity": 1.0, "yaw": atan2(t.x - f.x, t.z - f.z), "tint": c.color, "hot": c.hot, "update": func(n, age): n.position = f + Vector3.UP * (2.4 + sin(age * 3.0) * 0.15)})
	fx_wisps(vfx, c, f, t, x)
func fx_barrage(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, _t: Array) -> void:
	var d = _dir(from, to)
	vfx.spray(from + Vector3.UP * 1.3 + d * 0.5, 30, c.motif if c.el == "wind" else "spark", c.hot, Vector2(5, 9), Vector2(0.3, 0.6), 0.08, d, 0.3, 0.0, 0.4, 0.1)

# AMBUSH / VANISH / EXECUTE: shadow step and a cutting flash (claws are drawn by attack trails)
func fx_ambush(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3, _t: Array) -> void:
	for i in range(4): vfx.smoke(from + Vector3.UP * 0.7, 1.6, Color(0.1, 0.08, 0.14, 0.7), 0.9, i * 0.03, Vector3(0, 0.5, 0))
	vfx.spray(from + Vector3.UP * 0.8, 24, "glow", c.color, Vector2(1, 3), Vector2(0.4, 0.8), 0.1, Vector3.UP, 1.4, 0.0, 1.0)
	vfx.glow(to + Vector3.UP * 1.0, 2.0, c.hot, 0.3, 0, 0.2, 2.4)

func fx_vanish(vfx, c, f, t, x):
	vfx.prop("fox_mask", f + Vector3.UP * 1.6, 1.0, {"scale": 1.2, "tint": c.color, "update": func(n, age): n.position = f + Vector3.UP * (1.6 + age * 1.2)})
	fx_ambush(vfx, c, f, f, x)
func fx_execute(vfx: VFX, c: Dictionary, _from: Vector3, to: Vector3, _t: Array) -> void:
	# Spectral crescent blade drops onto the victim.
	vfx.prop("crescent_blade", to + Vector3.UP * 4.0, 1.0, {"scale": 2.2, "yaw": PI * 0.5, "tint": Color("ff5a4a"), "hot": Color("ffd0c0"), "intensity": 1.6, "update": func(n, age): n.position = to + Vector3.UP * maxf(0.2, 4.0 - age * age * 30.0); n.rotation.z = -1.2 + minf(age * 6.0, 1.2)})
	vfx.glow(to + Vector3.UP * 1.0, 2.6, Color("ff4a3a"), 0.35, 2, 0.0, 2.4)
	vfx.spray(to + Vector3.UP * 1.0, 26, "spark", Color("ffb0a0"), Vector2(3, 6), Vector2(0.2, 0.5), 0.05, Vector3.UP, 1.4, 4.0, 1.5, 0.1)

# BROOD / summons: web burst and a nest of glowing eyes
func fx_brood(vfx: VFX, c: Dictionary, from: Vector3, _to: Vector3, _t: Array) -> void:
	vfx.rune(from, 2.4, c.color, 0, 1.4, 0.0, 1.6)
	for i in range(3): vfx.smoke(from + Vector3(randf_range(-1, 1), 0.3, randf_range(-1, 1)), 1.6, Color(0.2, 0.12, 0.25, 0.6), 1.2, i * 0.05)
	vfx.spray(from + Vector3.UP * 0.3, 30, "glow", Color("ff4a6a"), Vector2(1, 3), Vector2(0.4, 0.8), 0.06, Vector3.UP, 1.4, 4.0, 1.0)

# Physical signatures get dust and an impact flash in addition to the anatomical trails.
func fx_gore(vfx, c, f, t, x): _dust_impact(vfx, c, t)
func fx_antlerrush(vfx, c, f, t, x): _dust_impact(vfx, c, t)
func fx_maul(vfx, c, f, t, x): _dust_impact(vfx, c, t)
func fx_skystrike(vfx, c, f, t, x): _dust_impact(vfx, c, t); vfx.spray(t + Vector3.UP * 1.5, 20, "feather", c.hot, Vector2(1, 3), Vector2(0.8, 1.4), 0.2, Vector3.UP, 1.2, 0.5, 0.8)
func fx_stonedive(vfx, c, f, t, x): fx_quake(vfx, c, t, t, x)
func fx_triplebite(vfx, c, f, t, x): _dust_impact(vfx, c, f)

func _dust_impact(vfx: VFX, c: Dictionary, at: Vector3) -> void:
	vfx.glow(at + Vector3.UP * 0.9, 2.0, c.hot, 0.3, 0, 0.0, 2.0)
	vfx.rune(at, 1.6, c.color, 1, 0.5, 0.0, 1.6)
	for i in range(4):
		var a = i * TAU / 4.0
		vfx.smoke(at + Vector3(cos(a) * 0.5, 0.25, sin(a) * 0.5), 1.4, Color(0.52, 0.46, 0.39, 0.5), 1.0, 0.0, Vector3(cos(a), 0.2, sin(a)) * 0.8)

func fx_generic(vfx: VFX, c: Dictionary, _from: Vector3, to: Vector3, _t: Array) -> void:
	_impact(vfx, c, to); _element_burst(vfx, c, to, 1.0)

# ---------------------------------------------------------------- per-recipient flourishes
static func hit(vfx: VFX, c: Dictionary, at: Vector3, big: bool) -> void:
	var s = 1.0 if big else 0.65
	vfx.glow(at + Vector3.UP * 1.3, 2.1 * s, c.hot, 0.22, 0, 0.0, 2.6)
	vfx.glow(at + Vector3.UP * 1.3, 3.2 * s, c.color, 0.3, 0, 0.0, 1.4)
	vfx.spray(at + Vector3.UP * 1.3, int(14 * s * c.boost), c.motif, c.color, Vector2(2.5, 5.5), Vector2(0.25, 0.55), 0.11, Vector3.UP, 1.4, 5.0, 1.2, 0.3 if c.motif == "spark" else 0.0, 0.0, 0.0, 0.0, c.alt)
	vfx.spray(at + Vector3.UP * 1.3, int(8 * s * c.boost), "spark", c.hot, Vector2(4.0, 8.0), Vector2(0.12, 0.3), 0.07, Vector3.UP, 1.8, 0.0, 2.0, 0.6)
	if big: vfx.rune(at, 2.2, c.color, 1, 0.4, 0.0, 2.2)

## Cast flash at the caster: a shockwave ring and a burst of the skill's colours.
static func cast_flash(vfx: VFX, c: Dictionary, at: Vector3) -> void:
	vfx.rune(at, 2.0 * (0.8 + c.boost * 0.25), c.color, 1, 0.45, 0.0, 2.4)
	vfx.rune(at, 1.4, c.alt, 0, 0.7, 0.0, 1.6)
	vfx.glow(at + Vector3.UP * 1.4, 2.6, c.hot, 0.3, 0, 0.0, 2.2)
	vfx.spray(at + Vector3.UP * 0.3, int(16 * c.boost), "glow", c.color, Vector2(2.0, 4.5), Vector2(0.35, 0.7), 0.1, Vector3.UP, 0.9, -1.0, 1.0, 0.0, 0.0, 1, 0.6, c.alt)

## Knock-out: a coloured burst and a ring as the champion drops.
static func knockout(vfx: VFX, c: Dictionary, at: Vector3) -> void:
	vfx.glow(at + Vector3.UP * 1.0, 4.0, c.hot, 0.4, 0, 0.0, 2.4)
	vfx.rune(at, 3.2, c.color, 1, 0.6, 0.0, 2.4)
	vfx.spray(at + Vector3.UP * 0.8, 40, c.motif, c.color, Vector2(3.0, 7.0), Vector2(0.5, 1.0), 0.13, Vector3.UP, 1.1, 6.0, 0.9, 0.0, 0.0, 1, 0.4, c.alt)
	vfx.smoke(at + Vector3.UP * 0.4, 2.4, c.smoke, 1.2, 0.0, Vector3(0, 0.5, 0))

# ---------------------------------------------------------------- projectiles (meteor, wisps, bolts, barrage)
static func projectile(vfx: VFX, c: Dictionary, effect: String) -> Node3D:
	# Returns a node the arena moves along the projectile path each frame; trails are emitted by `trail`.
	var root := Node3D.new()
	var core := MeshInstance3D.new(); core.mesh = VFX.quad()
	var m := ShaderMaterial.new(); m.shader = VFX.SHADERS.glow
	m.set_shader_parameter("tint", c.hot); m.set_shader_parameter("mode", 1); m.set_shader_parameter("intensity", 2.4)
	core.material_override = m; root.add_child(core)
	var halo := MeshInstance3D.new(); halo.mesh = VFX.quad()
	var m2 := ShaderMaterial.new(); m2.shader = VFX.SHADERS.glow
	m2.set_shader_parameter("tint", c.color); m2.set_shader_parameter("mode", 1); m2.set_shader_parameter("intensity", 1.4); m2.set_shader_parameter("hardness", 1.3)
	halo.material_override = m2; root.add_child(halo)
	if effect in ["meteor", "boulder"]:
		var rock := MeshInstance3D.new(); rock.mesh = VFX.rock_mesh(0.42, 3, 1)
		var rm := ShaderMaterial.new(); rm.shader = VFX.SHADERS.rock
		rm.set_shader_parameter("stone", Color("4a3b31")); rm.set_shader_parameter("molten", 1.0 if c.el in ["fire", "earth"] else 0.4); rm.set_shader_parameter("glow_color", c.color if c.el != "earth" else Color("ff7a2a"))
		rock.material_override = rm; root.add_child(rock); root.set_meta("spin", rock)
		core.scale = Vector3.ONE * 1.6; halo.scale = Vector3.ONE * 3.0
	else:
		core.scale = Vector3.ONE * 0.45; halo.scale = Vector3.ONE * 1.3
	return root

static func trail(vfx: VFX, c: Dictionary, effect: String, at: Vector3, dir: Vector3) -> void:
	# Called a few times per second by the arena for each live projectile.
	if effect in ["meteor", "boulder"]:
		vfx.flame(at - Vector3.UP * 0.4, Vector2(1.0, 1.6), c.color if c.el == "fire" else Color("ff6a1c"), 0.35)
		vfx.smoke(at, 1.2, Color(0.22, 0.18, 0.16, 0.5), 1.0, 0.0, Vector3(0, 0.3, 0))
		vfx.spray(at, 4, "ember", c.hot, Vector2(0.5, 1.5), Vector2(0.3, 0.6), 0.08, -dir, 0.6, 1.0, 0.8)
	else:
		vfx.glow(at, 0.55, c.color, 0.3, 0, 0.0, 1.6)
		vfx.spray(at, 3, c.motif if c.motif != "shard" else "spark", c.hot, Vector2(0.3, 1.0), Vector2(0.2, 0.45), 0.06, -dir, 0.8, 0.0, 1.0)

# ---------------------------------------------------------------- persistent zones (acid pools, fire waves, magma)
static func zone_pulse(vfx: VFX, c: Dictionary, effect: String, at: Vector3, radius: float) -> void:
	# Called every ~0.7s of battle time while a zone lives; pieces overlap so it reads as continuous.
	var life = 1.1
	match effect:
		"flamewave", "magma":
			vfx.rune(at, radius, Color("ff6a1c") if effect == "magma" else c.color, 4, life, 0.0, 1.0)
			for i in range(5):
				var a = randf() * TAU; var r = sqrt(randf()) * radius * 0.85
				vfx.flame(at + Vector3(cos(a) * r, 0, sin(a) * r), Vector2(0.7, 1.3) * randf_range(0.8, 1.3), c.color if effect == "flamewave" else Color("ff5a14"), life * 0.9, randf() * 0.3)
			vfx.spray(at + Vector3.UP * 0.2, 10, "ember", c.hot, Vector2(1.0, 2.5), Vector2(0.6, 1.2), 0.08, Vector3.UP, 0.8, -0.8, 0.6, 0.2, 0.0, 0.0, radius * 0.7)
			vfx.smoke(at + Vector3.UP * 1.2, radius * 0.9, c.smoke, life * 1.4, 0.0, Vector3(0, 0.4, 0))
		_:
			vfx.rune(at, radius, c.color, 3, life, 0.0, 1.0)
			vfx.spray(at + Vector3.UP * 0.1, 8, "droplet", c.hot, Vector2(0.5, 1.4), Vector2(0.5, 1.0), 0.09, Vector3.UP, 0.4, 3.0, 0.5, 0.0, 0.0, 0.0, radius * 0.7)
			for i in range(2):
				var a = randf() * TAU; var r = sqrt(randf()) * radius * 0.7
				vfx.smoke(at + Vector3(cos(a) * r, 0.3, sin(a) * r), radius * 0.5, Color(c.color.r * 0.5, c.color.g * 0.6, c.color.b * 0.4, 0.4), life * 1.3, randf() * 0.3, Vector3(0, 0.35, 0), 0.3)

# ---------------------------------------------------------------- legendary moment
static func legendary_flourish(vfx: VFX, c: Dictionary, from: Vector3, to: Vector3) -> void:
	## Gilded crown on top of the skill's own effect: light pillar, golden shockwaves, star burst.
	var gold = Color("ffcf5a"); var white = Color("fff6dc")
	vfx.beam(from, from + Vector3.UP * 7.0, 0.55, gold, 1.2, 0.0, 1.0)
	vfx.glow(from + Vector3.UP * 1.4, 3.6, gold, 0.6, 0, 0.0, 2.4)
	for i in range(3):
		vfx.rune(to, 2.2 + i * 1.4, gold, 1, 0.8, i * 0.1, 2.0)
	vfx.rune(from, 2.4, gold, 0, 1.6, 0.0, 1.6)
	vfx.spray(to + Vector3.UP * 0.8, 70, "star", white, Vector2(3, 8), Vector2(0.5, 1.2), 0.12, Vector3.UP, 1.2, 2.0, 1.0, 0.0, 0.0, 1, 0.6, gold)
	vfx.spray(from + Vector3.UP * 0.4, 40, "glow", gold, Vector2(1, 3), Vector2(0.8, 1.6), 0.1, Vector3.UP, 0.5, -1.0, 0.6, 0.0, 0.1, 1, 1.0)
