extends SceneTree
# Renders the 12 Forge components (tier-1 items) as lit 3D props on a transparent background.
# The Python compositor paints the backdrop, glow and particles.  env: OUTDIR, IDS (optional)
var vp: SubViewport
var cam: Camera3D
var holder: Node3D
var rim: DirectionalLight3D
var cur: Node3D
var queue: Array = []
var frames := 0
const RIM := {"fang": "ff5a4a", "hide": "c8e07a", "plate": "ffc27a", "feather": "9fd8ff", "ember": "ff8a3a", "moon": "9fc8ff",
	"seed": "b6ff7a", "storm": "7cc4ff", "silk": "c99bff", "venom": "8cff6a", "relic": "fff0b0", "coin": "ff8ce8"}

func _init():
	vp = SubViewport.new(); vp.size = Vector2i(640, 640); vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_8X; vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(vp)
	var root3 = Node3D.new(); vp.add_child(root3)
	var env = WorldEnvironment.new(); var e = Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	var sky = Sky.new(); var sm = ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.35, 0.42, 0.6); sm.sky_horizon_color = Color(0.9, 0.82, 0.7); sm.ground_bottom_color = Color(0.08, 0.06, 0.05); sm.ground_horizon_color = Color(0.5, 0.42, 0.35)
	sky.sky_material = sm; e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; e.ambient_light_energy = 0.55
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; e.tonemap_exposure = 1.05
	env.environment = e; root3.add_child(env)
	var key = DirectionalLight3D.new(); key.rotation_degrees = Vector3(-40, -35, 0); key.light_energy = 1.6; key.light_color = Color(1, 0.94, 0.85); key.shadow_enabled = true; root3.add_child(key)
	rim = DirectionalLight3D.new(); rim.rotation_degrees = Vector3(-15, 165, 0); rim.light_energy = 3.2; root3.add_child(rim)
	var rim2 = DirectionalLight3D.new(); rim2.rotation_degrees = Vector3(-10, -160, 0); rim2.light_energy = 1.2; rim2.light_color = Color(0.8, 0.85, 1.0); root3.add_child(rim2)
	cam = Camera3D.new(); cam.fov = 30; root3.add_child(cam); cam.current = true
	holder = Node3D.new(); root3.add_child(holder)
	var ids = OS.get_environment("IDS")
	queue = Array(ids.split(",")) if ids != "" else RIM.keys()

# ---------------------------------------------------------------- mesh helpers
func mat(albedo: Color, metal := 0.0, rough := 0.5, emission := Color.BLACK, energy := 0.0, vcol := false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_color = albedo; m.metallic = metal; m.roughness = rough
	if energy > 0.0: m.emission_enabled = true; m.emission = emission; m.emission_energy_multiplier = energy
	if vcol: m.vertex_color_use_as_albedo = true
	if albedo.a < 0.99: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

## Parametric surface: f(u,v) -> Vector3, optional c(u,v) -> Color. Smooth normals.
func param(f: Callable, nu: int, nv: int, m: Material, c = null, two_sided := false, flat := false) -> MeshInstance3D:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts = []; var cols = []
	for j in range(nv + 1):
		for i in range(nu + 1):
			var u = float(i) / nu; var v = float(j) / nv
			pts.append(f.call(u, v)); cols.append(c.call(u, v) if c != null else Color.WHITE)
	var idx = func(i, j): return j * (nu + 1) + i
	for j in range(nv):
		for i in range(nu):
			for k in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j], [i + 1, j + 1], [i, j + 1]]:
				var n = idx.call(k[0], k[1]); st.set_color(cols[n]); st.add_vertex(pts[n])
	if not flat: st.index()
	st.generate_normals()
	var mi = MeshInstance3D.new(); mi.mesh = st.commit(); mi.material_override = m
	if two_sided: m.cull_mode = BaseMaterial3D.CULL_DISABLED
	# The winding of parametric patches varies; render both sides so nothing goes missing.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mi

## Surface of revolution around Y from a (radius, y) profile.
func lathe(profile: Array, segs: int, m: Material, flat := false, squash := 1.0) -> MeshInstance3D:
	return param(func(u, v):
		var t = v * (profile.size() - 1); var a = int(floor(t)); var b = mini(a + 1, profile.size() - 1)
		var p = profile[a].lerp(profile[b], t - a); var ang = u * TAU
		return Vector3(p.x * cos(ang), p.y, p.x * sin(ang) * squash), segs, (profile.size() - 1) * 6, m, null, false, flat)

func vnormals(poly: PackedVector2Array) -> Array:
	var out = []; var n = poly.size()
	for i in range(n):
		var a = poly[(i - 1 + n) % n]; var b = poly[i]; var c = poly[(i + 1) % n]
		var e1 = (b - a).normalized(); var e2 = (c - b).normalized()
		var n1 = Vector2(e1.y, -e1.x); var n2 = Vector2(e2.y, -e2.x)
		var nn = (n1 + n2).normalized(); var dd = maxf(0.35, nn.dot(n1))
		out.append(nn / dd)
	return out

## Bevelled extrusion of a 2D outline (counter-clockwise) along Z. post(p) can bend the result.
func extrude(poly: PackedVector2Array, depth: float, bevel: float, m: Material, post = null, col = null) -> MeshInstance3D:
	if Geometry2D.is_polygon_clockwise(poly): poly.reverse()
	var nrm = vnormals(poly)
	var rings = [[-bevel, depth * 0.5], [0.0, depth * 0.5 - bevel], [0.0, -depth * 0.5 + bevel], [-bevel, -depth * 0.5]]
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var P = func(p2: Vector2, z: float) -> Vector3:
		var p3 = Vector3(p2.x, p2.y, z)
		return post.call(p3) if post != null else p3
	var C = func(p2: Vector2) -> Color: return col.call(p2) if col != null else Color.WHITE
	var ring_pts = []
	for r in rings:
		var arr = []
		for i in range(poly.size()): arr.append(poly[i] - nrm[i] * r[0])
		ring_pts.append(arr)
	# caps (inset outline)
	var cap = PackedVector2Array(ring_pts[0]); var tris = Geometry2D.triangulate_polygon(poly)
	if tris.is_empty(): push_warning("extrude: triangulation failed")
	for side in [0, 3]:
		var z = rings[side][1]
		for t in range(0, tris.size(), 3):
			var order = [tris[t], tris[t + 1], tris[t + 2]] if side == 0 else [tris[t], tris[t + 2], tris[t + 1]]
			for k in order: st.set_color(C.call(cap[k])); st.add_vertex(P.call(cap[k], z))
	for r in range(3):
		for i in range(poly.size()):
			var j = (i + 1) % poly.size()
			var a = P.call(ring_pts[r][i], rings[r][1]); var b = P.call(ring_pts[r][j], rings[r][1])
			var c2 = P.call(ring_pts[r + 1][j], rings[r + 1][1]); var d = P.call(ring_pts[r + 1][i], rings[r + 1][1])
			for q in [[a, poly[i]], [d, poly[i]], [c2, poly[j]], [a, poly[i]], [c2, poly[j]], [b, poly[j]]]:
				st.set_color(C.call(q[1])); st.add_vertex(q[0])
	st.generate_normals()
	var mi = MeshInstance3D.new(); mi.mesh = st.commit(); mi.material_override = m
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mi

## A tube following a curve g(t) -> Vector3 with radius rad(t).
func tube(g: Callable, rad: Callable, m: Material, segs := 10, steps := 24) -> MeshInstance3D:
	return param(func(u, v):
		var p = g.call(v); var p2 = g.call(minf(1.0, v + 0.01)); var p0 = g.call(maxf(0.0, v - 0.01))
		var tdir = (p2 - p0).normalized()
		var side = tdir.cross(Vector3.FORWARD if absf(tdir.z) < 0.9 else Vector3.UP).normalized(); var up = side.cross(tdir)
		var a = u * TAU
		return p + (side * cos(a) + up * sin(a)) * rad.call(v), segs, steps, m)

func sphere(pos: Vector3, r: float, m: Material, scl := Vector3.ONE) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); var s = SphereMesh.new(); s.radius = r; s.height = r * 2; s.radial_segments = 32; s.rings = 16
	mi.mesh = s; mi.material_override = m; mi.position = pos; mi.scale = scl; return mi

func torus(pos: Vector3, inner: float, outer: float, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); var t = TorusMesh.new(); t.inner_radius = inner; t.outer_radius = outer; t.rings = 48; t.ring_segments = 16
	mi.mesh = t; mi.material_override = m; mi.position = pos; mi.rotation_degrees = rot; return mi

func circle(r: float, n := 48, c := Vector2.ZERO) -> PackedVector2Array:
	var p = PackedVector2Array()
	for i in range(n): var a = TAU * i / n; p.append(c + Vector2(cos(a), sin(a)) * r)
	return p

func hn(x: float, y: float, s: int = 0) -> float:
	# cheap smooth value noise
	return 0.5 + 0.25 * sin(x * 3.1 + s * 1.7 + sin(y * 2.3 + s)) + 0.25 * sin(y * 4.7 - s * 0.9 + sin(x * 1.9 - s))

# ---------------------------------------------------------------- props
func build(id: String) -> Node3D:
	var n = Node3D.new()
	var gold = mat(Color(1.0, 0.77, 0.34), 1.0, 0.26)
	var bronze = mat(Color(0.82, 0.5, 0.26), 1.0, 0.34)
	match id:
		"fang":
			var ivory = mat(Color.WHITE, 0.0, 0.32, Color.BLACK, 0.0, true)
			n.add_child(param(func(u, v):
				var r = 0.30 * pow(1.0 - v, 0.72) + 0.004; var a = u * TAU
				return Vector3(r * cos(a) + 0.55 * v * v, v * 1.7, r * sin(a) * 0.78), 40, 60, ivory,
				func(u, v):
					var base = Color(0.95, 0.9, 0.76).lerp(Color(0.78, 0.68, 0.5), v * 0.6)
					return base.lerp(Color(0.5, 0.03, 0.04), smoothstep(0.62, 0.95, v) * 0.85)))
			n.add_child(torus(Vector3(0, 0.1, 0), 0.27, 0.36, gold))
			n.add_child(torus(Vector3(0, -0.02, 0), 0.25, 0.33, gold))
			var cord = mat(Color(0.32, 0.18, 0.1), 0.0, 0.8)
			n.add_child(tube(func(t): return Vector3(sin(t * PI) * 0.5 - 0.0, -0.05 - sin(t * PI) * 0.55, cos(t * PI) * 0.35), func(_t): return 0.035, cord))
			n.rotation_degrees = Vector3(10, 20, 152)
		"hide":
			var leather = mat(Color.WHITE, 0.0, 0.72, Color.BLACK, 0.0, true)
			var R = func(th): return 1.0 + 0.10 * sin(3 * th + 0.4) + 0.07 * sin(7 * th) + 0.32 * pow(maxf(0.0, cos(2 * th + 0.785)), 10.0)
			n.add_child(param(func(u, v):
				var th = v * TAU; var s = u; var r = R.call(th) * s
				var x = cos(th) * r * 1.1; var y = sin(th) * r * 0.85
				var z = 0.10 * sin(x * 3.0 + y * 2.0) * s - 0.38 * pow(maxf(0.0, absf(x) - 0.3), 1.6)
				return Vector3(x, z, y), 40, 96, leather,
				func(u, v):
					var th = v * TAU; var x = cos(th) * u; var y = sin(th) * u
					var spots = smoothstep(0.62, 0.8, hn(x * 3.3, y * 3.3, 3))
					var c = Color(0.66, 0.56, 0.34).lerp(Color(0.48, 0.5, 0.28), hn(x * 2, y * 2, 1)).lerp(Color(0.26, 0.2, 0.12), spots * 0.75)
					return c.lerp(Color(0.24, 0.17, 0.1), smoothstep(0.86, 1.0, u))))
			var thread = mat(Color(0.85, 0.75, 0.55), 0.0, 0.7)
			for i in range(22):
				var th = TAU * i / 22.0; var r = R.call(th) * 0.9
				var x = cos(th) * r * 1.1; var y = sin(th) * r * 0.85
				var z = 0.10 * sin(x * 3.0 + y * 2.0) * 0.9 - 0.38 * pow(maxf(0.0, absf(x) - 0.3), 1.6)
				var st = sphere(Vector3(x, z + 0.02, y), 0.035, thread, Vector3(1.6, 0.6, 0.6)); st.rotation.y = -th; n.add_child(st)
			# A bone toggle and leather thong across the middle.
			n.add_child(tube(func(t): return Vector3(-0.15 + t * 0.3, 0.13, 0.05 - t * 0.1), func(t): return 0.06 + 0.02 * pow(absf(t - 0.5) * 2.0, 4.0), mat(Color(0.9, 0.86, 0.74), 0, 0.4)))
			n.rotation_degrees = Vector3(-62, 0, 4)
		"plate":
			var shape = PackedVector2Array()
			for i in range(64):
				var a = TAU * i / 64.0; var cx = signf(cos(a)); var cy = signf(sin(a))
				var c = Vector2(cos(a), sin(a)); var p = Vector2(pow(absf(c.x), 0.35) * cx * 0.9, pow(absf(c.y), 0.35) * cy * 1.05)
				if p.y < 0: p.x *= 1.0 - 0.25 * absf(p.y)
				shape.append(p)
			var bend = func(p): return Vector3(p.x, p.y, p.z - 0.32 * p.x * p.x - 0.12 * p.y * p.y)
			n.add_child(extrude(shape, 0.12, 0.05, bronze, bend))
			var inner = PackedVector2Array(); for p in shape: inner.append(p * 0.72)
			var dark = mat(Color(0.42, 0.24, 0.12), 1.0, 0.45)
			n.add_child(extrude(inner, 0.14, 0.02, dark, func(p): return bend.call(p) + Vector3(0, 0, 0.02)))
			var boss = sphere(Vector3(0, 0.05, 0.12), 0.28, bronze, Vector3(1, 1, 0.45)); n.add_child(boss)
			n.add_child(torus(Vector3(0, 0.05, 0.1), 0.27, 0.34, gold, Vector3(90, 0, 0)))
			for p in [Vector2(-0.68, 0.82), Vector2(0.68, 0.82), Vector2(-0.6, -0.8), Vector2(0.6, -0.8), Vector2(-0.82, 0.0), Vector2(0.82, 0.0)]:
				var q = bend.call(Vector3(p.x, p.y, 0.06)); n.add_child(sphere(q, 0.06, gold))
			n.rotation_degrees = Vector3(-14, -24, 8)
		"feather":
			var vane = PackedVector2Array(); var L = 2.0
			for i in range(41):
				var t = float(i) / 40.0; var y = 0.18 + t * (L - 0.18)
				var w = 0.36 * pow(sin(PI * clampf((y - 0.1) / (L - 0.1), 0.0, 1.0)), 0.6) * (1.0 - 0.1 * (1 if i % 7 == 3 else 0))
				vane.append(Vector2(w * 1.15, y))
			for i in range(40, -1, -1):
				var t = float(i) / 40.0; var y = 0.18 + t * (L - 0.18)
				var w = 0.3 * pow(sin(PI * clampf((y - 0.1) / (L - 0.1), 0.0, 1.0)), 0.6) * (1.0 - 0.14 * (1 if i % 9 == 4 else 0))
				vane.append(Vector2(-w, y))
			var curl = func(p): return Vector3(p.x + 0.18 * pow(p.y / L, 2.0), p.y, p.z + 0.25 * sin(p.y / L * PI) - 0.12 * p.x * p.x)
			var fm = mat(Color.WHITE, 0.0, 0.55, Color.BLACK, 0.0, true)
			n.add_child(extrude(vane, 0.02, 0.008, fm, curl, func(p):
				var t = p.y / L; var band = 0.5 + 0.5 * sin(t * 28.0 + absf(p.x) * 4.0)
				var c = Color(0.98, 0.9, 0.72).lerp(Color(0.92, 0.55, 0.18), smoothstep(0.15, 0.6, t)).lerp(Color(0.55, 0.16, 0.08), smoothstep(0.7, 1.0, t))
				c = c.lerp(Color(0.35, 0.2, 0.12), smoothstep(0.7, 1.0, band) * 0.8 * smoothstep(0.25, 0.45, t))
				return c.lerp(Color(1, 1, 1), smoothstep(0.85, 1.0, 1.0 - absf(p.x) * 3.0) * 0.4)))
			var quill = mat(Color(0.95, 0.9, 0.78), 0.0, 0.3)
			n.add_child(tube(func(t): return curl.call(Vector3(0, -0.15 + t * (L + 0.1), 0.01)), func(t): return 0.045 * (1.0 - t * 0.85), quill))
			n.rotation_degrees = Vector3(-12, -10, -38)
		"ember":
			var crystal = mat(Color(0.95, 0.32, 0.08, 0.92), 0.0, 0.12, Color(0.9, 0.22, 0.03), 0.9)
			var specs = [[Vector3(0, 0, 0), Vector3(0, 0, 0), 1.6, 0.24], [Vector3(-0.22, -0.05, 0.1), Vector3(0, 0, 28), 1.05, 0.17], [Vector3(0.24, -0.06, 0.05), Vector3(0, 30, -32), 1.15, 0.18],
				[Vector3(0.05, -0.08, 0.25), Vector3(30, 0, -8), 0.8, 0.14], [Vector3(-0.1, -0.08, -0.22), Vector3(-28, 0, 12), 0.75, 0.13]]
			for s in specs:
				var h = s[2]; var r = s[3]
				var c = lathe([Vector2(r * 0.8, 0), Vector2(r, 0.1), Vector2(r, h * 0.72), Vector2(0.0, h)], 6, crystal, true)
				c.position = s[0]; c.rotation_degrees = s[1]; n.add_child(c)
			var rock = mat(Color.WHITE, 0.0, 0.9, Color(1, 0.3, 0.05), 0.0, true)
			n.add_child(param(func(u, v):
				var a = u * TAU; var b = v * PI; var r = 0.55 * (1.0 + 0.18 * hn(cos(a) * 2, b * 2, 4))
				return Vector3(r * sin(b) * cos(a), -0.22 + r * cos(b) * 0.4, r * sin(b) * sin(a)), 40, 20, rock,
				func(u, v): return Color(0.12, 0.09, 0.08).lerp(Color(1.0, 0.42, 0.08), smoothstep(0.93, 1.0, 1.0 - absf(sin(u * 40.0 + v * 9.0))) * 0.9)))
			n.rotation_degrees = Vector3(14, 20, -6)
		"moon":
			var outer = circle(0.9, 72); var cut = circle(0.78, 72, Vector2(0.42, 0.22))
			var cres = Geometry2D.clip_polygons(outer, cut)[0]
			var pearl = mat(Color(0.52, 0.64, 0.9), 0.25, 0.1, Color(0.3, 0.45, 0.95), 0.25)
			n.add_child(extrude(cres, 0.28, 0.12, pearl))
			var silver = mat(Color(0.86, 0.9, 0.96), 1.0, 0.22)
			n.add_child(sphere(Vector3(0.55, 0.55, 0.1), 0.12, mat(Color(0.7, 0.85, 1.0), 0.1, 0.05, Color(0.6, 0.8, 1), 1.4)))
			n.add_child(sphere(Vector3(0.75, 0.15, 0.1), 0.07, mat(Color(0.7, 0.85, 1.0), 0.1, 0.05, Color(0.6, 0.8, 1), 1.4)))
			n.add_child(torus(Vector3(-0.36, 0.84, 0), 0.06, 0.13, silver, Vector3(90, 0, 20)))
			n.rotation_degrees = Vector3(-6, -28, 14)
		"seed":
			var heart = PackedVector2Array()
			for i in range(80):
				var t = TAU * i / 80.0
				heart.append(Vector2(16 * pow(sin(t), 3), 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)) * 0.05)
			var wood = mat(Color.WHITE, 0.0, 0.38, Color(0.5, 1.0, 0.3), 0.0, true)
			var hp = func(t): return Vector2(16 * pow(sin(t), 3), 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)) * 0.05
			var hcol = func(u, v):
				var p2 = hp.call(v * TAU) * u
				var vein = smoothstep(0.86, 1.0, 1.0 - absf(sin(p2.x * 8.0 + sin(p2.y * 5.0) * 1.8)))
				return Color(0.45, 0.24, 0.1).lerp(Color(0.7, 0.42, 0.16), hn(p2.x * 2, p2.y * 3, 2)).lerp(Color(0.62, 1.0, 0.35), vein * 0.85)
			for side in [1.0, -1.0]:
				n.add_child(param(func(u, v):
					var p2 = hp.call(v * TAU) * u
					return Vector3(p2.x, p2.y, side * 0.26 * sqrt(maxf(0.0, 1.0 - u * u))), 40, 120, wood, hcol))
			var stem = mat(Color(0.36, 0.62, 0.2), 0.0, 0.5)
			var sg = func(t): return Vector3(0.02 + 0.12 * sin(t * 2.4), 0.45 + t * 0.62, 0.05 * t)
			n.add_child(tube(sg, func(t): return 0.045 * (1.0 - 0.5 * t), stem))
			var leaf = PackedVector2Array()
			for i in range(30): var t = TAU * i / 30.0; leaf.append(Vector2(cos(t) * 0.26, sin(t) * 0.12 * (1.0 - 0.6 * cos(t))))
			var lm = mat(Color(0.42, 0.82, 0.28), 0.0, 0.4, Color(0.4, 0.9, 0.2), 0.25)
			for s in [[Vector3(0.24, 0.9, 0.04), 30.0], [Vector3(-0.12, 1.02, 0.04), 150.0]]:
				var lf = extrude(leaf, 0.02, 0.006, lm, func(p): return Vector3(p.x, p.y, p.z + 0.25 * p.x * p.x))
				lf.position = s[0]; lf.rotation_degrees = Vector3(20, 0, s[1]); n.add_child(lf)
			n.rotation_degrees = Vector3(-6, 20, 0)
		"storm":
			var glass = mat(Color(0.55, 0.75, 1.0, 0.38), 0.5, 0.02, Color(0.2, 0.4, 0.9), 0.25); glass.rim_enabled = true; glass.rim = 1.0
			n.add_child(sphere(Vector3(0, 0.62, 0), 0.62, glass))
			var bolt = mat(Color(0.75, 0.92, 1.0), 0.0, 0.3, Color(0.55, 0.85, 1.0), 4.0)
			var rng = RandomNumberGenerator.new(); rng.seed = 7
			for b in range(4):
				var pts = [Vector3(0, 0.62, 0)]; var dir = Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.8, 1), rng.randf_range(-1, 1)).normalized()
				for k in range(5): pts.append(pts[-1] + (dir * 0.11 + Vector3(rng.randf_range(-0.07, 0.07), rng.randf_range(-0.07, 0.07), rng.randf_range(-0.07, 0.07))))
				n.add_child(tube(func(t):
					var f = t * (pts.size() - 1); var a = int(floor(f)); var c2 = mini(a + 1, pts.size() - 1)
					return pts[a].lerp(pts[c2], f - a), func(t): return 0.018 * (1.0 - t * 0.7), bolt, 6, 30))
			n.add_child(sphere(Vector3(0, 0.62, 0), 0.07, bolt))
			n.add_child(lathe([Vector2(0.0, -0.32), Vector2(0.5, -0.32), Vector2(0.52, -0.26), Vector2(0.4, -0.18), Vector2(0.22, -0.08), Vector2(0.26, 0.02), Vector2(0.34, 0.1), Vector2(0.0, 0.12)], 48, bronze))
			for k in range(3):
				var a = TAU * k / 3.0
				n.add_child(tube(func(t): return Vector3(cos(a) * (0.3 + 0.35 * sin(t * 1.6)), 0.08 + t * 0.62, sin(a) * (0.3 + 0.35 * sin(t * 1.6))), func(t): return 0.05 * (1.0 - 0.7 * t), bronze))
			n.rotation_degrees = Vector3(6, 0, 0)
		"silk":
			var cloth = mat(Color(0.26, 0.12, 0.42), 0.0, 0.24); cloth.rim_enabled = true; cloth.rim = 0.7; cloth.rim_tint = 0.6
			n.add_child(param(func(u, v):
				var y = 1.0 - v * 2.1; var sway = 0.45 * sin(v * 3.2) * v
				var x = (u - 0.5) * (0.7 + 0.5 * v) + sway; var z = 0.07 * sin(u * 20.0 + v * 3.0) * (0.3 + v) + 0.35 * sin(v * 4.0 + u * 1.5) * v
				return Vector3(x, y, z), 60, 80, cloth))
			n.add_child(torus(Vector3(0, 1.02, 0), 0.08, 0.2, mat(Color(0.86, 0.9, 0.96), 1.0, 0.2), Vector3(90, 0, 0)))
			n.add_child(sphere(Vector3(0, 1.02, 0.02), 0.08, mat(Color(0.7, 0.4, 1.0), 0.0, 0.05, Color(0.6, 0.3, 1.0), 2.0)))
			n.rotation_degrees = Vector3(0, -25, -10)
		"venom":
			var sac = mat(Color.WHITE, 0.0, 0.14, Color(0.3, 0.9, 0.1), 0.18, true); sac.rim_enabled = true; sac.rim = 0.5
			n.add_child(param(func(u, v):
				var a = u * TAU; var b = v * PI; var y = cos(b)
				var r = 0.62 * (1.0 + 0.07 * sin(a * 5.0 + b * 3.0) + 0.05 * sin(a * 11.0 - b * 7.0)) * (1.0 - 0.28 * maxf(0.0, y)) * (1.0 + 0.1 * maxf(0.0, -y))
				return Vector3(r * sin(b) * cos(a), y * 0.7, r * sin(b) * sin(a)), 56, 32, sac,
				func(u, v):
					var vein = smoothstep(0.9, 1.0, 1.0 - absf(sin(u * 30.0 + sin(v * 9.0) * 2.0)))
					return Color(0.16, 0.36, 0.08).lerp(Color(0.45, 0.8, 0.12), v * 0.7).lerp(Color(0.35, 0.05, 0.3), vein * 0.85)))
			n.add_child(tube(func(t): return Vector3(0.0 + 0.1 * sin(t * 3), 0.62 + t * 0.35, 0.0), func(t): return 0.12 * (1.0 - 0.4 * t), mat(Color(0.45, 0.2, 0.3), 0.0, 0.3)))
			var drop = mat(Color(0.6, 1.0, 0.3, 0.85), 0.0, 0.05, Color(0.5, 1.0, 0.2), 1.2)
			for d in [[Vector3(0.05, -0.92, 0.0), 0.11], [Vector3(-0.08, -1.3, 0.05), 0.07]]:
				n.add_child(lathe([Vector2(0, -d[1]), Vector2(d[1] * 0.9, -d[1] * 0.5), Vector2(d[1], 0), Vector2(d[1] * 0.6, d[1] * 0.8), Vector2(0, d[1] * 2.2)], 24, drop))
				n.get_child(n.get_child_count() - 1).position = d[0]
			n.rotation_degrees = Vector3(6, 0, -8)
		"relic":
			var rays = PackedVector2Array()
			for i in range(24):
				var a = TAU * i / 24.0 + PI / 2.0; var r = (1.0 if i % 4 == 0 else 0.72) if i % 2 == 0 else 0.42
				rays.append(Vector2(cos(a), sin(a)) * r)
			n.add_child(extrude(rays, 0.08, 0.035, gold))
			n.add_child(lathe([Vector2(0, 0.12), Vector2(0.36, 0.08), Vector2(0.4, 0.0), Vector2(0.36, -0.08), Vector2(0, -0.1)], 48, gold))
			n.get_child(1).rotation_degrees = Vector3(90, 0, 0)
			n.add_child(torus(Vector3(0, 0, 0.06), 0.3, 0.38, mat(Color(1, 0.9, 0.6), 1.0, 0.15), Vector3(90, 0, 0)))
			var gem = mat(Color(1.0, 0.98, 0.9), 0.0, 0.05, Color(1, 0.92, 0.65), 2.4)
			var g = lathe([Vector2(0, -0.08), Vector2(0.22, 0.02), Vector2(0.16, 0.12), Vector2(0, 0.14)], 8, gem, true); g.rotation_degrees = Vector3(90, 0, 0); g.position = Vector3(0, 0, 0.1); n.add_child(g)
			n.add_child(torus(Vector3(0, 1.08, 0), 0.07, 0.15, gold, Vector3(0, 90, 0)))
			n.rotation_degrees = Vector3(-8, -24, 6)
		"coin":
			var face = Image.load_from_file(OS.get_environment("COINFACE"))
			var H = func(x, y):
				var px = clampi(int((x * 0.5 + 0.5) * 255), 0, 255); var py = clampi(int((0.5 - y * 0.5) * 255), 0, 255)
				return face.get_pixel(px, py).r
			n.add_child(lathe([Vector2(0, -0.07), Vector2(0.86, -0.07), Vector2(0.9, -0.04), Vector2(0.9, 0.04), Vector2(0.86, 0.07), Vector2(0.76, 0.08), Vector2(0.74, 0.05)], 96, gold))
			n.get_child(0).rotation_degrees = Vector3(90, 0, 0)
			n.add_child(param(func(u, v):
				var r = u * 0.75; var a = v * TAU; var x = cos(a) * r; var y = sin(a) * r
				return Vector3(x, y, 0.05 + 0.07 * H.call(x / 0.75, y / 0.75)), 70, 160, gold))
			var back = lathe([Vector2(0, -0.06), Vector2(0.6, -0.06), Vector2(0.62, 0.0), Vector2(0.6, 0.06), Vector2(0, 0.06)], 64, mat(Color(0.95, 0.7, 0.32), 1.0, 0.3))
			back.position = Vector3(0.55, -0.6, -0.5); back.rotation_degrees = Vector3(20, 0, 30); n.add_child(back)
			n.rotation_degrees = Vector3(-12, -26, 8)
	return n

func fit():
	var box = AABB(); var first = true
	for mi in cur.find_children("*", "MeshInstance3D", true, false):
		var b = mi.global_transform * mi.get_aabb()
		if first: box = b; first = false
		else: box = box.merge(b)
	var c = box.get_center(); var ext = maxf(box.size.x, box.size.y) * 0.5
	var dist = ext / tan(deg_to_rad(cam.fov * 0.5)) * 1.12 + box.size.z * 0.5
	cam.look_at_from_position(c + Vector3(0, 0.0, dist), c)

func _process(_d):
	if queue.is_empty():
		quit(); return false
	if frames == 0:
		if cur: cur.queue_free()
		cur = build(queue[0]); holder.add_child(cur)
		rim.light_color = Color(RIM.get(queue[0], "ffffff"))
	if frames == 2: fit()
	frames += 1
	if frames == 8:
		vp.get_texture().get_image().save_png(OS.get_environment("OUTDIR") + "/" + queue[0] + ".png")
		print("COMP ", queue[0]); queue.remove_at(0); frames = 0
	return false
