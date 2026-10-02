class_name SkillClarity
extends Node3D
## Makes fights readable: team rings under every fighter, ground footprints that show exactly where
## and when a skill will land, crisp cast callouts, and (in Tactical view) target lines + status tags.

const ALLY := Color("5fd3e0")
const ENEMY := Color("f08a6a")
const FOOT_SHADER := preload("res://shaders/vfx/footprint.gdshader")
const STATUS_TEXT := {"stun": ["STUNNED", "ffe36e"], "root": ["ROOTED", "9be06a"], "silence": ["SILENCED", "c49cff"],
	"taunt": ["TAUNTED", "ff9a6a"], "confuse": ["CONFUSED", "f0a0ff"], "slow": ["SLOWED", "8fd8ff"],
	"weaken": ["WEAKENED", "b48cff"], "stealth": ["HIDDEN", "c0c8d8"], "shell": ["SHELLED", "7fe0d0"], "rally": ["RALLIED", "ffd27a"]}
const HARD_CC := ["stun", "root", "silence", "taunt", "confuse"]

var tactical := false
var t := 0.0
var rings := {}       # uid -> MeshInstance3D
var feet := {}        # uid -> {nodes: [...], mats: [...]}
var lines := {}       # uid -> MeshInstance3D (tactical target line)
var tags := {}        # uid -> Label3D
var callouts: Array = []

func clear() -> void:
	for c in get_children(): c.queue_free()
	rings.clear(); feet.clear(); lines.clear(); tags.clear(); callouts.clear()

static func team_color(team: int) -> Color:
	return ALLY if team == 0 else ENEMY

func _mat(mode: int, edge: Color, fill: Color, strength: float = 1.0, priority: int = -2) -> ShaderMaterial:
	var m := ShaderMaterial.new(); m.shader = FOOT_SHADER; m.render_priority = priority
	m.set_shader_parameter("mode", mode); m.set_shader_parameter("edge", edge); m.set_shader_parameter("fill", fill)
	m.set_shader_parameter("strength", strength)
	return m

func _quad(m: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh = VFX.ground_quad(); n.material_override = m
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(n); return n

# ------------------------------------------------------------------ shapes (sim units)
## Returns the area a pending cast will hit: {kind: circle|line|target, center, radius | from, to, width, leap}
static func shape(sim: BattleSim, u: Dictionary) -> Dictionary:
	var pc = u.pending_cast; var effect: String = pc.effect
	var tgt = sim.find_unit(int(pc.get("target", -1)))
	var tp: Vector2 = tgt.pos if not tgt.is_empty() else u.pos
	var rng = float(pc.get("ability", {}).get("range", 6.0))
	match effect:
		"quake", "whirl", "fear", "shriek", "triplebite": return {"kind": "circle", "center": u.pos, "radius": 3.0}
		"bulwark", "prideroar", "shellup", "frostroar": return {"kind": "circle", "center": u.pos, "radius": 3.4}
		"meteor", "toxic", "fire", "gust", "silence", "frost", "roots", "acid", "flamewave", "magma": return {"kind": "circle", "center": tp, "radius": 2.5}
		"boulder": return {"kind": "circle", "center": tp, "radius": 2.4}
		"smash": return {"kind": "circle", "center": tp, "radius": 3.0}
		"renew", "ward", "rally": return {"kind": "circle", "center": u.pos, "radius": minf(rng, 6.0), "support": true}
		"tidal", "radiance": return {"kind": "circle", "center": u.pos, "radius": 5.2, "support": true}
		"tailwind": return {"kind": "circle", "center": u.pos, "radius": 6.0, "support": true}
		"beam", "fissure":
			var dir = (tp - u.pos).normalized() if tp.distance_to(u.pos) > 0.01 else Vector2.RIGHT
			return {"kind": "line", "from": u.pos, "to": u.pos + dir * rng, "width": 2.8}
		"antlerrush": return {"kind": "line", "from": u.pos, "to": tp, "width": 3.4, "leap": true}
		"gore", "venom", "skystrike", "maul", "stonedive", "vanish", "foxfire", "ambush": return {"kind": "target", "center": tp, "from": u.pos, "leap": true}
		"rootbloom", "regrowth", "hunger", "howl", "brood": return {"kind": "circle", "center": u.pos, "radius": 1.6, "support": true}
	return {"kind": "target", "center": tp, "from": u.pos}

# ------------------------------------------------------------------ per-frame
func sync(sim: BattleSim, dt: float, models: Dictionary) -> void:
	t += dt
	var live_feet := {}
	for u in sim.units:
		if not models.has(u.uid): continue
		var vis = models[u.uid]
		var pos: Vector3 = vis.root.position
		_ring(u, pos, vis)
		if u.alive and u.has("pending_cast"):
			live_feet[u.uid] = true; _footprint(sim, u)
		_tag(u, pos, vis)
		_line(sim, u, pos, models)
	for id in feet.keys():
		if not live_feet.has(id):
			for n in feet[id].nodes: n.queue_free()
			feet.erase(id)
	for c in callouts.duplicate():
		c.age += dt; c.pop = maxf(0.0, c.pop - dt * 4.0)
		if c.age >= c.life or not is_instance_valid(c.node): 
			if is_instance_valid(c.node): c.node.queue_free()
			callouts.erase(c); continue
		_place(c)

func _ring(u: Dictionary, pos: Vector3, vis: Dictionary) -> void:
	if not rings.has(u.uid):
		var m = _mat(3, team_color(u.team), team_color(u.team), 1.0, -3)
		rings[u.uid] = _quad(m)
	var r: MeshInstance3D = rings[u.uid]
	r.visible = u.alive
	var size = (0.8 if u.summon else 1.5)
	r.position = Vector3(pos.x, 0.04, pos.z); r.scale = Vector3(size, 1, size)
	r.material_override.set_shader_parameter("strength", 0.95 if tactical else 0.6)

func _footprint(sim: BattleSim, u: Dictionary) -> void:
	var pc = u.pending_cast
	var sh = shape(sim, u)
	var progress = clampf(1.0 - pc.delay / maxf(0.01, pc.total), 0.0, 1.0)
	var team = team_color(u.team)
	var element = AbilityFX.ctx(u.hero.sp).color
	var support = sh.get("support", false)
	var edge = team.lerp(Color("9dffb0"), 0.35) if support else team
	var rarity = RarityStyle.for_skill(u.hero, str(pc.get("credit", "signature")))
	if rarity == "Legendary": edge = Color("ffd166"); element = Color("ffb84a")
	elif rarity == "Rare": edge = edge.lerp(Color("c9a8ff"), 0.45)
	if not feet.has(u.uid):
		var nodes = []
		match sh.kind:
			"circle": nodes.append(_quad(_mat(0, edge, element)))
			"line": nodes.append(_quad(_mat(1, edge, element)))
			_:
				nodes.append(_quad(_mat(2, edge, element)))
				nodes.append(_quad(_mat(1, edge, element, 0.55)))   # path from caster to the target
		feet[u.uid] = {"nodes": nodes, "kind": sh.kind}
	var f = feet[u.uid]
	var strength = 1.0 if tactical else 0.8
	if support: strength *= 0.35
	for n in f.nodes:
		n.material_override.set_shader_parameter("progress", progress if not support else 0.0)
		n.material_override.set_shader_parameter("t", t)
		n.material_override.set_shader_parameter("strength", strength)
	var S = ArenaView.FLOOR_SCALE
	match f.kind:
		"circle":
			var c = ArenaView.world_point(sh.center, 0.05); var r = sh.radius * S
			f.nodes[0].position = c; f.nodes[0].scale = Vector3(r, 1, r); f.nodes[0].rotation = Vector3.ZERO
		"line":
			_strip(f.nodes[0], ArenaView.world_point(sh.from, 0.05), ArenaView.world_point(sh.to, 0.05), sh.width * S)
		_:
			var c = ArenaView.world_point(sh.center, 0.06)
			f.nodes[0].position = c; f.nodes[0].scale = Vector3.ONE * 1.25
			_strip(f.nodes[1], ArenaView.world_point(sh.from, 0.05), c, 0.35 if not sh.get("leap", false) else 0.6)

func _strip(n: MeshInstance3D, a: Vector3, b: Vector3, width: float) -> void:
	var d = b - a; d.y = 0
	var length = maxf(0.1, d.length())
	n.position = (a + b) * 0.5
	n.rotation = Vector3(0, atan2(d.x, d.z), 0)
	n.scale = Vector3(width * 0.5, 1, length * 0.5)
	n.material_override.set_shader_parameter("aspect", length / maxf(0.1, width))

func _tag(u: Dictionary, pos: Vector3, vis: Dictionary) -> void:
	var parts = []; var col = Color.WHITE
	if u.alive:
		for k in STATUS_TEXT:
			if u.status.get(k, 0.0) > 0.05 and k in HARD_CC:
				if parts.is_empty(): col = Color(STATUS_TEXT[k][1])
				parts.append(STATUS_TEXT[k][0])
	if parts.is_empty():
		if tags.has(u.uid): tags[u.uid].visible = false
		return
	if not tags.has(u.uid):
		var l := Label3D.new(); l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.no_depth_test = true
		l.font_size = 30; l.pixel_size = 0.011; l.outline_size = 9; l.outline_modulate = Color(0.05, 0.05, 0.08, 0.95)
		add_child(l); tags[u.uid] = l
	var lab: Label3D = tags[u.uid]
	lab.visible = true; lab.text = parts[0]; lab.modulate = col
	lab.position = pos + Vector3.UP * (vis.bars.position.y + 0.45)

func _line(sim: BattleSim, u: Dictionary, pos: Vector3, models: Dictionary) -> void:
	var show = tactical and u.alive and int(u.get("target", -1)) >= 0 and models.has(int(u.target))
	if show:
		var tg = sim.find_unit(int(u.target))
		show = not tg.is_empty() and tg.alive and tg.team != u.team
	if not show:
		if lines.has(u.uid): lines[u.uid].visible = false
		return
	if not lines.has(u.uid):
		lines[u.uid] = _quad(_mat(1, team_color(u.team), team_color(u.team), 0.35, -3))
	var n: MeshInstance3D = lines[u.uid]; n.visible = true
	var tp: Vector3 = models[int(u.target)].root.position
	var d = tp - pos; d.y = 0
	var inset = d.normalized() * 0.9
	_strip(n, pos + inset + Vector3.UP * 0.045, tp - inset + Vector3.UP * 0.045, 0.16)
	n.material_override.set_shader_parameter("progress", 0.0); n.material_override.set_shader_parameter("t", t)

# ------------------------------------------------------------------ cast callouts
## Shown when a windup starts (hold = windup seconds); release() pops it when the skill lands.
func callout(sim: BattleSim, e: Dictionary, models: Dictionary, hold: float = 0.0) -> void:
	var u = sim.find_unit(int(e.get("uid", -1)))
	if u.is_empty() or not models.has(u.uid) or u.summon: return
	for c in callouts:
		if c.uid == u.uid: c.age = c.life   # replace this unit's previous callout
	var label := Label3D.new(); label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; label.no_depth_test = true
	var rarity = str(e.get("rarity", "Uncommon"))
	var legendary = rarity == "Legendary"
	label.text = ("LEGENDARY\n%s" if legendary else "%s") % str(e.get("name", "")).to_upper()
	label.font_size = (48 if legendary else 38 if rarity == "Rare" else 34) if tactical else (44 if legendary else 34 if rarity == "Rare" else 30)
	label.pixel_size = 0.011; label.outline_size = 14 if legendary else 11
	var team = team_color(u.team)
	label.modulate = Color("ffd77a") if legendary else Color("dcc8ff") if rarity == "Rare" else Color(1.0, 0.97, 0.9).lerp(AbilityFX.ctx(u.hero.sp).color, 0.2)
	label.outline_modulate = Color(0.35, 0.2, 0.02, 1.0) if legendary else Color(team.r * 0.32, team.g * 0.32, team.b * 0.32, 1.0)
	label.render_priority = 4
	add_child(label)
	var c = {"node": label, "age": 0.0, "life": hold + (1.1 if tactical else 0.8) + (0.9 if legendary else 0.0), "hold": hold, "uid": u.uid, "follow": models[u.uid], "pop": 0.0}
	# Neighbouring callouts fade out early instead of stacking into towers of text.
	var here: Vector3 = models[u.uid].root.position
	for o in callouts:
		if o.age < o.life and Vector2(o.follow.root.position.x - here.x, o.follow.root.position.z - here.z).length() < 2.6:
			o.age = maxf(o.age, o.life - 0.25)
	callouts.append(c)
	_place(c)

func release(sim: BattleSim, e: Dictionary, models: Dictionary) -> void:
	for c in callouts:
		if c.uid == int(e.get("uid", -1)) and c.age < c.life:
			c.pop = 1.0; c.age = maxf(c.age, c.hold); return
	callout(sim, e, models, 0.0)   # skills without a windup (e.g. rebirth)

func _place(c: Dictionary) -> void:
	var v = c.follow
	var k = clampf((c.age - c.hold) / maxf(0.01, c.life - c.hold), 0.0, 1.0) if c.age > c.hold else 0.0
	c.node.position = v.root.position + Vector3.UP * (v.bars.position.y + 0.9 + 0.45 * k)
	var a = 1.0 - smoothstep(0.65, 1.0, k)
	if c.age < 0.12: a *= c.age / 0.12
	c.node.modulate.a = a; c.node.outline_modulate.a = a
	c.node.scale = Vector3.ONE * (1.0 + 0.3 * c.pop)
