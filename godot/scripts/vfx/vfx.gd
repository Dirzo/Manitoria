class_name VFX
extends Node3D
## Manitoria ability effects runtime.
## Every effect is driven by an `age` that advances with the battle clock (pause, slow motion and
## battle speed all flow through `advance`). Nothing here uses wall-clock tweens.

const SHADERS := {
	"flame": preload("res://shaders/vfx/flame.gdshader"),
	"glow": preload("res://shaders/vfx/glow.gdshader"),
	"bolt": preload("res://shaders/vfx/bolt.gdshader"),
	"swirl": preload("res://shaders/vfx/swirl.gdshader"),
	"beam": preload("res://shaders/vfx/beam.gdshader"),
	"shield": preload("res://shaders/vfx/shield.gdshader"),
	"rune": preload("res://shaders/vfx/rune.gdshader"),
	"smoke": preload("res://shaders/vfx/smoke.gdshader"),
	"crystal": preload("res://shaders/vfx/crystal.gdshader"),
	"rock": preload("res://shaders/vfx/rock.gdshader"),
	"thorn": preload("res://shaders/vfx/thorn.gdshader"),
	"prop_spectral": preload("res://shaders/vfx/prop_spectral.gdshader"),
	"prop_solid": preload("res://shaders/vfx/prop_solid.gdshader"),
	"spray": preload("res://shaders/vfx/spray.gdshader"),
}
const MOTIFS := {"glow": 0, "ember": 1, "spark": 1, "feather": 2, "leaf": 3, "snow": 4, "droplet": 5, "shard": 6, "star": 7, "petal": 8}
const MAX_LIVE := 260

var live: Array = []     # {node, age, life, mats:[ShaderMaterial], update:Callable}
var rng := RandomNumberGenerator.new()
static var _quad: QuadMesh
static var _ground_quad: PlaneMesh
static var _cone_cache := {}
static var props := {}   # optional Meshy prop scenes by name, registered by the arena

func _init() -> void:
	rng.seed = 7

func clear() -> void:
	for fx in live: fx.node.queue_free()
	live.clear()

func count() -> int:
	return live.size()

func advance(dt: float) -> void:
	for i in range(live.size() - 1, -1, -1):
		var fx = live[i]
		fx.age += dt
		for m in fx.mats: m.set_shader_parameter("age", fx.age - fx.get("delay", 0.0))
		var local = fx.age - fx.get("delay", 0.0)
		fx.node.visible = local >= 0.0
		if fx.update.is_valid() and local >= 0.0: fx.update.call(fx.node, local)
		if fx.age >= fx.life + fx.get("delay", 0.0):
			fx.node.queue_free(); live.remove_at(i)

func _track(node: Node3D, life: float, mats: Array, update: Callable = Callable(), delay: float = 0.0) -> Node3D:
	if live.size() >= MAX_LIVE:
		var old = live.pop_front(); old.node.queue_free()
	add_child(node)
	for m in mats:
		m.set_shader_parameter("age", -delay); m.set_shader_parameter("life", life)
	node.visible = delay <= 0.0
	live.append({"node": node, "age": 0.0, "life": life, "mats": mats, "update": update, "delay": delay})
	return node

func _mat(kind: String, params: Dictionary = {}) -> ShaderMaterial:
	var m := ShaderMaterial.new(); m.shader = SHADERS[kind]
	for k in params: m.set_shader_parameter(k, params[k])
	m.set_shader_parameter("seed", rng.randf() * 10.0)
	return m

static func quad() -> QuadMesh:
	if _quad == null: _quad = QuadMesh.new(); _quad.size = Vector2(1, 1)
	return _quad

static func ground_quad() -> PlaneMesh:
	if _ground_quad == null: _ground_quad = PlaneMesh.new(); _ground_quad.size = Vector2(2, 2)
	return _ground_quad

# ------------------------------------------------------------------ geometry helpers
static func open_cone(bottom: float, top: float, height: float, segments: int = 40, rings: int = 12) -> ArrayMesh:
	var key = "%s/%s/%s/%s" % [bottom, top, height, segments]
	if _cone_cache.has(key): return _cone_cache[key]
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rings):
		for s in range(segments):
			for c in [[0, 0], [1, 0], [1, 1], [0, 0], [1, 1], [0, 1]]:
				var u = float(s + c[0]) / segments; var v = float(r + c[1]) / rings
				var rad = lerpf(bottom, top, pow(v, 0.8)); var ang = u * TAU
				st.set_uv(Vector2(u, v)); st.set_normal(Vector3(cos(ang), 0.3, sin(ang)).normalized())
				st.add_vertex(Vector3(cos(ang) * rad, v * height, sin(ang) * rad))
	var mesh = st.commit(); _cone_cache[key] = mesh; return mesh

static func ribbon_mesh(points: PackedVector3Array, widths: PackedFloat32Array, facing: Vector3 = Vector3.UP) -> ArrayMesh:
	# Flat ribbon through points, widened perpendicular to both the path and `facing`.
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n = points.size()
	var total = 0.0
	var lengths = [0.0]
	for i in range(1, n): total += points[i].distance_to(points[i - 1]); lengths.append(total)
	var left = []; var right = []
	for i in range(n):
		var d = (points[mini(i + 1, n - 1)] - points[maxi(i - 1, 0)]).normalized()
		var side = d.cross(facing).normalized()
		if side.length() < 0.1: side = d.cross(Vector3.RIGHT).normalized()
		left.append(points[i] - side * widths[i] * 0.5); right.append(points[i] + side * widths[i] * 0.5)
	for i in range(n - 1):
		var v0 = lengths[i] / maxf(total, 0.001); var v1 = lengths[i + 1] / maxf(total, 0.001)
		for q in [[left[i], 0.0, v0], [right[i], 1.0, v0], [right[i + 1], 1.0, v1], [left[i], 0.0, v0], [right[i + 1], 1.0, v1], [left[i + 1], 0.0, v1]]:
			st.set_uv(Vector2(q[1], q[2])); st.set_normal(facing); st.add_vertex(q[0])
	return st.commit()

static func tube_mesh(points: PackedVector3Array, radius0: float, radius1: float, sides: int = 7, thorns: bool = false) -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n = points.size()
	var frames = []
	for i in range(n):
		var d = (points[mini(i + 1, n - 1)] - points[maxi(i - 1, 0)]).normalized()
		var a = d.cross(Vector3.FORWARD if absf(d.y) > 0.9 else Vector3.UP).normalized()
		frames.append([a, d.cross(a).normalized()])
	for i in range(n - 1):
		for s in range(sides):
			for c in [[0, 0], [1, 0], [1, 1], [0, 0], [1, 1], [0, 1]]:
				var idx = i + c[1]; var ang = float(s + c[0]) / sides * TAU
				var r = lerpf(radius0, radius1, float(idx) / (n - 1))
				var off = (frames[idx][0] * cos(ang) + frames[idx][1] * sin(ang))
				st.set_uv(Vector2(float(s + c[0]) / sides, float(idx) / (n - 1))); st.set_normal(off)
				st.add_vertex(points[idx] + off * r)
	if thorns:
		for i in range(2, n - 1, 2):
			var r = lerpf(radius0, radius1, float(i) / (n - 1))
			var ang = i * 2.4
			var off = (frames[i][0] * cos(ang) + frames[i][1] * sin(ang))
			var base = points[i] + off * r * 0.8; var tip = points[i] + off * r * 3.2 + (points[i + 1] - points[i]) * 0.6
			var w = frames[i][1] * r * 0.45; var h = frames[i][0] * r * 0.45
			var v = float(i) / (n - 1)
			for tri in [[base - w, base + w, tip], [base - h, base + h, tip]]:
				for p in tri: st.set_uv(Vector2(0.5, v)); st.set_normal(off); st.add_vertex(p)
	return st.commit()

static func crystal_mesh(height: float, radius: float, sides: int = 6, seed: int = 0) -> ArrayMesh:
	var r := RandomNumberGenerator.new(); r.seed = seed
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shoulder = height * r.randf_range(0.62, 0.8)
	var tip = Vector3(r.randf_range(-0.05, 0.05), height, r.randf_range(-0.05, 0.05))
	for s in range(sides):
		var a0 = float(s) / sides * TAU; var a1 = float(s + 1) / sides * TAU
		var b0 = Vector3(cos(a0), 0, sin(a0)) * radius; var b1 = Vector3(cos(a1), 0, sin(a1)) * radius
		var m0 = b0 * 0.92 + Vector3.UP * shoulder; var m1 = b1 * 0.92 + Vector3.UP * shoulder
		var n = ((b0 + b1) * 0.5).normalized()
		for p in [b0, b1, m1, b0, m1, m0]: st.set_normal(n); st.set_uv(Vector2(float(s) / sides, p.y / height)); st.add_vertex(p)
		var nt = ((m0 + m1) * 0.5 - tip).cross(m1 - m0).normalized() * -1.0
		for p in [m0, m1, tip]: st.set_normal(nt); st.set_uv(Vector2(float(s) / sides, p.y / height)); st.add_vertex(p)
	return st.commit()

static func rock_mesh(radius: float, seed: int = 0, detail: int = 2) -> ArrayMesh:
	var sphere := SphereMesh.new(); sphere.radius = radius; sphere.height = radius * 2; sphere.radial_segments = 10 + detail * 4; sphere.rings = 6 + detail * 3
	var arrays = sphere.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var noise := FastNoiseLite.new(); noise.seed = seed; noise.frequency = 1.6 / radius
	for i in range(verts.size()):
		var v = verts[i]; var d = 1.0 + noise.get_noise_3dv(v) * 0.38
		var flat = clampf(noise.get_noise_3dv(v * 0.5 + Vector3(9, 9, 9)) * 2.0, -0.2, 0.2)
		verts[i] = v * d * (1.0 - absf(flat) * 0.5)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = null
	var st := SurfaceTool.new(); st.create_from_arrays(arrays); st.deindex(); st.generate_normals()
	return st.commit()

# ------------------------------------------------------------------ primitives
func flame(pos: Vector3, size: Vector2, tint: Color, life: float = 0.9, delay: float = 0.0, core: Color = Color("fff3c4"), update: Callable = Callable()) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh = quad(); n.position = pos; n.scale = Vector3(size.x, size.y, 1)
	n.position.y += size.y * 0.5
	var m = _mat("flame", {"tint": tint, "core": core}); n.material_override = m
	_track(n, life, [m], update, delay); return n

func glow(pos: Vector3, size: float, tint: Color, life: float = 0.5, mode: int = 0, delay: float = 0.0, intensity: float = 2.0, update: Callable = Callable()) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh = quad(); n.position = pos; n.scale = Vector3.ONE * size
	var m = _mat("glow", {"tint": tint, "mode": mode, "intensity": intensity}); n.material_override = m
	_track(n, life, [m], update, delay); return n

func bolt(from: Vector3, to: Vector3, tint: Color, width: float = 0.22, life: float = 0.45, branches: int = 2, delay: float = 0.0, jag: float = 0.35) -> Node3D:
	var root := Node3D.new(); var mats = []
	var paths = [_jagged(from, to, 12, jag)]
	for b in range(branches):
		var main: PackedVector3Array = paths[0]
		var k = rng.randi_range(3, main.size() - 4)
		var start = main[k]
		var dir = (to - from).normalized()
		var end = start + (dir * rng.randf_range(0.6, 1.4) + Vector3(rng.randf_range(-1, 1), -0.3, rng.randf_range(-1, 1)).normalized() * rng.randf_range(0.8, 1.6))
		paths.append(_jagged(start, end, 6, jag * 0.7))
	for i in range(paths.size()):
		var pts: PackedVector3Array = paths[i]
		var ws := PackedFloat32Array()
		for j in range(pts.size()): ws.append(width * (1.0 if i == 0 else 0.55) * lerpf(1.0, 0.45, float(j) / pts.size()))
		for facing in [Vector3.RIGHT, Vector3.FORWARD]:
			var n := MeshInstance3D.new(); n.mesh = ribbon_mesh(pts, ws, facing)
			var m = _mat("bolt", {"tint": tint}); n.material_override = m; mats.append(m); root.add_child(n)
	_track(root, life, mats, Callable(), delay); return root

func _jagged(a: Vector3, b: Vector3, steps: int, jag: float) -> PackedVector3Array:
	var pts := PackedVector3Array(); var d = a.distance_to(b)
	for i in range(steps + 1):
		var t = float(i) / steps; var p = a.lerp(b, t)
		if i > 0 and i < steps: p += Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.4), rng.randf_range(-1, 1)) * jag * d * 0.12
		pts.append(p)
	return pts

func swirl(pos: Vector3, bottom: float, top: float, height: float, tint: Color, tint2: Color, life: float = 1.6, spin: float = 8.0, density: float = 1.0, delay: float = 0.0, update: Callable = Callable()) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh = open_cone(bottom, top, height); n.position = pos
	var m = _mat("swirl", {"tint": tint, "tint2": tint2, "spin": spin, "density": density}); n.material_override = m
	_track(n, life, [m], update, delay); return n

func beam(from: Vector3, to: Vector3, radius: float, tint: Color, life: float = 0.8, delay: float = 0.0, pillar: float = 0.0) -> MeshInstance3D:
	var len = from.distance_to(to)
	var c := CylinderMesh.new(); c.top_radius = radius; c.bottom_radius = radius; c.height = len; c.radial_segments = 16; c.rings = 6
	var n := MeshInstance3D.new(); n.mesh = c; n.position = (from + to) * 0.5
	var dir = (to - from).normalized()
	n.quaternion = Quaternion(Vector3.UP, dir) if dir.dot(Vector3.UP) > -0.999 else Quaternion(Vector3.RIGHT, PI)
	var m = _mat("beam", {"tint": tint, "span": len, "pillar": pillar}); n.material_override = m
	_track(n, life, [m], Callable(), delay); return n

func shield(pos: Vector3, radius: float, tint: Color, life: float = 1.4, hold: float = 0.0, delay: float = 0.0, update: Callable = Callable()) -> MeshInstance3D:
	var s := SphereMesh.new(); s.radius = radius; s.height = radius * 2; s.radial_segments = 32; s.rings = 16
	var n := MeshInstance3D.new(); n.mesh = s; n.position = pos
	var m = _mat("shield", {"tint": tint, "hold": hold}); n.material_override = m
	_track(n, life, [m], update, delay); return n

func rune(pos: Vector3, radius: float, tint: Color, mode: int = 0, life: float = 1.2, delay: float = 0.0, intensity: float = 1.8) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh = ground_quad(); n.position = pos + Vector3.UP * 0.035; n.scale = Vector3(radius, 1, radius)
	n.rotation.y = rng.randf() * TAU
	var m = _mat("rune", {"tint": tint, "mode": mode, "intensity": intensity}); n.material_override = m
	_track(n, life, [m], Callable(), delay); return n

func smoke(pos: Vector3, size: float, tint: Color, life: float = 1.6, delay: float = 0.0, drift: Vector3 = Vector3(0, 0.6, 0), glow_amount: float = 0.0) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh = quad(); n.position = pos; n.scale = Vector3.ONE * size
	var m = _mat("smoke", {"tint": tint, "glow": glow_amount}); n.material_override = m
	var start = pos
	_track(n, life, [m], func(node, a): node.position = start + drift * a, delay); return n

func crystal(pos: Vector3, height: float, radius: float, tint: Color, life: float = 1.6, delay: float = 0.0, tilt: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh = crystal_mesh(height, radius, 6, rng.randi()); n.position = pos; n.rotation = tilt
	var m = _mat("crystal", {"tint": tint}); n.material_override = m
	_track(n, life, [m], Callable(), delay); return n

func rock(pos: Vector3, radius: float, stone: Color, molten: float = 0.0, life: float = 1.0, delay: float = 0.0, update: Callable = Callable()) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh = rock_mesh(radius, rng.randi(), 1); n.position = pos
	n.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
	var m = _mat("rock", {"stone": stone, "molten": molten, "glow_color": Color("ff7a2a")}); n.material_override = m
	_track(n, life, [m], update, delay); return n

func vine(points: PackedVector3Array, radius: float, bark: Color, glow_color: Color, life: float = 1.8, delay: float = 0.0, thorns: bool = true) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh = tube_mesh(points, radius, radius * 0.15, 7, thorns)
	var m = _mat("thorn", {"bark": bark, "glow_color": glow_color}); n.material_override = m
	_track(n, life, [m], Callable(), delay); return n

func spray(pos: Vector3, count: int, motif: String, tint: Color, speed: Vector2, life: Vector2, size: float, dir: Vector3 = Vector3.UP, cone: float = 1.0, gravity: float = 0.0, drag: float = 0.8, stretch: float = 0.0, delay: float = 0.0, size_curve: float = 0.0, spread_radius: float = 0.0, tint2: Color = Color(0, 0, 0, 0)) -> MultiMeshInstance3D:
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true; mm.use_custom_data = true
	mm.mesh = quad(); mm.instance_count = count
	var longest = 0.0
	for i in range(count):
		var v = (dir.normalized() + Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * cone).normalized() * rng.randf_range(speed.x, speed.y)
		var l = rng.randf_range(life.x, life.y); longest = maxf(longest, l)
		var off = Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * spread_radius
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * size * rng.randf_range(0.6, 1.3)), off))
		var c = tint if tint2.a <= 0.0 else tint.lerp(tint2, rng.randf())
		mm.set_instance_color(i, c)
		mm.set_instance_custom_data(i, Color(v.x, v.y, v.z, l))
	var n := MultiMeshInstance3D.new(); n.multimesh = mm; n.position = pos
	n.custom_aabb = AABB(Vector3(-12, -12, -12), Vector3(24, 24, 24))
	var m = _mat("spray", {"motif": MOTIFS.get(motif, 0), "gravity": gravity, "drag": drag, "stretch": stretch, "size_curve": size_curve})
	n.material_override = m
	_track(n, longest, [m], Callable(), delay); return n

func prop(name: String, pos: Vector3, life: float, opts: Dictionary = {}, delay: float = 0.0) -> Node3D:
	## Meshy props live in assets/vfx_props/<name>.res (unit-sized, base at y=0).
	## opts: scale, yaw, tint, hot, base, solid(bool), rise, intensity, update(Callable)
	if not props.has(name):
		var path = "res://assets/vfx_props/%s.res" % name
		props[name] = load(path) if ResourceLoader.exists(path) else null
	var mesh: Mesh = props[name]
	if mesh == null: return null
	# Meshy gave us alternate takes of some props; mix them so repeats don't look stamped.
	if not props.has(name + "_b"):
		var alt = "res://assets/vfx_props/%s_b.res" % name
		props[name + "_b"] = load(alt) if ResourceLoader.exists(alt) else null
	if props[name + "_b"] != null and rng.randf() < 0.5: mesh = props[name + "_b"]
	var n := MeshInstance3D.new(); n.mesh = mesh; n.position = pos
	n.scale = Vector3.ONE * opts.get("scale", 1.0); n.rotation.y = opts.get("yaw", 0.0)
	var solid = opts.get("solid", false)
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if solid else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m: ShaderMaterial
	if solid:
		m = _mat("prop_solid", {"base": opts.get("base", Color(0.32, 0.24, 0.17)), "tint": opts.get("tint", Color.WHITE), "rise": opts.get("rise", 0.25)})
	else:
		m = _mat("prop_spectral", {"tint": opts.get("tint", Color(0.6, 0.4, 1.0)), "hot": opts.get("hot", Color.WHITE), "intensity": opts.get("intensity", 1.3)})
	n.material_override = m
	_track(n, life, [m], opts.get("update", Callable()), delay); return n
