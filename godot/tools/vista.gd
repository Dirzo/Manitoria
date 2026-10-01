extends SceneTree
# Offline renderer for the menu backdrops: a procedural landscape per region with a
# coliseum on a plateau, painted panorama sky, fog and themed props.
# env: THEME (forest|volcanic|coastal|glacial|desert|astral), OUT (png), W, H
var vp: SubViewport
var frames = 0
var theme = "forest"
var noise := FastNoiseLite.new()
var ridge := FastNoiseLite.new()
var T = {}

const THEMES = {
 "forest": {"sun":[35,25],"sunc":"fff0d6","sune":1.6,"fog":"cfe2f2","fogd":0.0016,"water":"water","wl":-7.0,
  "low":"5f7a3a","grass":"3d7a2a","rock":"8c8a80","peak":"f2f4f8","stone":"efe6d6","trim":"d8b25a","banner":"3f7fd0","mount":200.0,"tree":"2f6a35","trees":1400},
 "volcanic": {"sun":[-60,8],"sunc":"ff9a5a","sune":1.5,"fog":"7a3420","fogd":0.0032,"water":"lava","wl":-7.0,
  "low":"2a1a16","grass":"3a2620","rock":"2c2422","peak":"4a3a36","stone":"b89a88","trim":"e0a050","banner":"c8402a","mount":230.0,"tree":"1c1210","trees":350},
 "coastal": {"sun":[10,6],"sunc":"ffc08a","sune":1.7,"fog":"f0c6a8","fogd":0.0014,"water":"sea","wl":-7.0,
  "low":"c8b48a","grass":"6a9a52","rock":"9a8a7a","peak":"e8e0d8","stone":"f4ece0","trim":"d8b060","banner":"2a8a9a","mount":150.0,"tree":"3d7a48","trees":700},
 "glacial": {"sun":[120,15],"sunc":"eef4ff","sune":1.4,"fog":"d8e6f6","fogd":0.0022,"water":"ice","wl":-7.0,
  "low":"dfe8f2","grass":"e8eef6","rock":"6a7a8e","peak":"ffffff","stone":"dfe8f0","trim":"9fc8ff","banner":"3a6ad0","mount":280.0,"tree":"2a4a44","trees":700},
 "desert": {"sun":[-20,40],"sunc":"fff0d0","sune":1.9,"fog":"f2d8b0","fogd":0.0013,"water":"oasis","wl":-9.0,
  "low":"d8b07a","grass":"e2bc84","rock":"b07a52","peak":"c88a5a","stone":"f2dcb4","trim":"e0b050","banner":"c84a2a","mount":120.0,"tree":"4a7a3a","trees":120},
 "astral": {"sun":[80,30],"sunc":"b8a8ff","sune":0.9,"fog":"2a1d5a","fogd":0.0018,"water":"void","wl":-60.0,
  "low":"3a3a6a","grass":"4a5a8a","rock":"3a3456","peak":"8a8ad0","stone":"c8c4e8","trim":"b89aff","banner":"8a5ad0","mount":160.0,"tree":"6a4aa0","trees":500},
}

func _init():
	theme = OS.get_environment("THEME") if OS.get_environment("THEME") != "" else "forest"
	T = THEMES[theme]
	noise.seed = 11; noise.frequency = 0.0022; noise.fractal_octaves = 6; noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	ridge.seed = 4; ridge.frequency = 0.0016; ridge.fractal_octaves = 5; ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	vp = SubViewport.new(); vp.size = Vector2i(int(OS.get_environment("W")), int(OS.get_environment("H")))
	vp.msaa_3d = Viewport.MSAA_4X; vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.positional_shadow_atlas_size = 2048
	get_root().add_child(vp)
	var root = Node3D.new(); vp.add_child(root)
	build_environment(root)
	build_terrain(root)
	build_water(root)
	build_coliseum(root)
	build_props(root)
	var cam = Camera3D.new(); cam.fov = 48; cam.far = 6000; root.add_child(cam); cam.current = true
	cam.look_at_from_position(Vector3(-128, 34, 168), Vector3(-30, 22, -20))

func col(h: String) -> Color: return Color(h)

func build_environment(root: Node3D) -> void:
	var img = Image.load_from_file("/home/claude/work/vista/sky_%s.png" % theme)
	var pano = PanoramaSkyMaterial.new(); pano.panorama = ImageTexture.create_from_image(img); pano.energy_multiplier = 1.0
	var sky = Sky.new(); sky.sky_material = pano; sky.radiance_size = Sky.RADIANCE_SIZE_256
	var e = Environment.new(); e.background_mode = Environment.BG_SKY; e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; e.ambient_light_energy = float(OS.get_environment("AMB")) if OS.get_environment("AMB") != "" else 0.55
	e.fog_enabled = OS.get_environment("NOFOG") == ""
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_ACES; e.tonemap_exposure = 0.85 if theme != "astral" else 1.1
	e.fog_light_color = col(T.fog); e.fog_density = T.fogd * 0.28; e.fog_sky_affect = 0.15; e.fog_aerial_perspective = 0.5
	e.glow_enabled = true; e.glow_intensity = 0.7; e.glow_bloom = 0.08; e.glow_hdr_threshold = 1.3
	e.adjustment_enabled = true; e.adjustment_saturation = 1.12; e.adjustment_contrast = 1.06
	var we = WorldEnvironment.new(); we.environment = e; root.add_child(we)
	var sun = DirectionalLight3D.new(); root.add_child(sun)
	var lon = deg_to_rad(float(T.sun[0])); var el = deg_to_rad(float(T.sun[1]))
	# Panorama convention: u=0.5 looks down -Z. Light points away from the sun.
	var to_sun = Vector3(sin(lon) * cos(el), sin(el), -cos(lon) * cos(el))
	sun.look_at_from_position(Vector3.ZERO, -to_sun, Vector3.UP if abs(to_sun.y) < 0.95 else Vector3.FORWARD)
	sun.light_color = col(T.sunc); sun.light_energy = T.sune; sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 700; sun.shadow_blur = 1.5
	if theme == "volcanic":
		var lava_light = OmniLight3D.new(); lava_light.position = Vector3(-60, 6, 60); lava_light.omni_range = 260; lava_light.light_color = Color("ff6a20"); lava_light.light_energy = 2.5; root.add_child(lava_light)
	if theme == "astral":
		var moon = OmniLight3D.new(); moon.position = Vector3(0, 120, 0); moon.omni_range = 400; moon.light_color = Color("a890ff"); moon.light_energy = 1.2; root.add_child(moon)

func height(x: float, z: float) -> float:
	var r = Vector2(x, z).length()
	var n = noise.get_noise_2d(x, z) * 0.5 + 0.5
	var g = ridge.get_noise_2d(x, z) * 0.5 + 0.5
	var amp = lerp(10.0, float(T.mount), smoothstep(160.0, 900.0, r))
	var h = n * amp * 0.7 + g * g * amp * 0.8 - 3.0
	if theme == "desert":
		h = h * 0.6 + sin(x * 0.018 + n * 4.0) * 6.0 * smoothstep(80.0, 200.0, r)
	if theme == "volcanic":
		var d = Vector2(x + 520, z + 700).length()
		h += 420.0 * exp(-pow(d / 260.0, 2)) - 120.0 * exp(-pow(d / 60.0, 2))
	if theme == "coastal":
		# open sea toward the camera's left
		h -= 60.0 * smoothstep(-100.0, -500.0, x + z * 0.2) * (1.0 - smoothstep(700.0, 1100.0, -z))
	# The coliseum plateau, a lake moat around it, then the land rises.
	var plateau = 1.0 - smoothstep(58.0, 78.0, r)
	var moat = smoothstep(58.0, 80.0, r) * (1.0 - smoothstep(110.0, 230.0, r))
	h = lerp(h - 12.0 * moat, 0.0, plateau)
	if theme == "astral":
		h = lerp(-400.0, 0.0, plateau)   # the arena floats on a shard; the land is islands
	return h

func build_terrain(root: Node3D) -> void:
	if theme == "astral":
		build_islands(root); build_shard(root); return
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var N = 300; var size = 2600.0; var cell = size / N
	var hs = []
	for j in range(N + 1):
		var row = []
		for i in range(N + 1):
			row.append(height(-size * 0.5 + cell * i, -size * 0.5 + cell * j))
		hs.append(row)
	for j in range(N + 1):
		for i in range(N + 1):
			var hl = hs[j][max(i - 1, 0)]; var hr = hs[j][min(i + 1, N)]; var hd = hs[max(j - 1, 0)][i]; var hu = hs[min(j + 1, N)][i]
			var nrm = Vector3(hl - hr, 2.0 * cell, hd - hu).normalized()
			var v = Vector3(-size * 0.5 + cell * i, hs[j][i], -size * 0.5 + cell * j)
			st.set_color(ground_color(v, nrm)); st.set_normal(nrm); st.add_vertex(v)
	for j in range(N):
		for i in range(N):
			var k = j * (N + 1) + i
			for idx in [k, k + 1, k + N + 2, k, k + N + 2, k + N + 1]: st.add_index(idx)
	var mesh = st.commit()
	var mi = MeshInstance3D.new(); mi.mesh = mesh
	var m = StandardMaterial3D.new(); m.vertex_color_use_as_albedo = true; m.roughness = 0.95; m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_texture = detail_tex(0.03, Color(0.72, 0.72, 0.72), Color(1.12, 1.12, 1.12)); m.uv1_triplanar = true; m.uv1_scale = Vector3(0.02, 0.02, 0.02)
	mi.material_override = m; root.add_child(mi)

func detail_tex(freq: float, lo: Color, hi: Color) -> NoiseTexture2D:
	var tex = NoiseTexture2D.new(); var nz = FastNoiseLite.new(); nz.frequency = freq; nz.fractal_octaves = 5; tex.noise = nz; tex.seamless = true; tex.width = 512; tex.height = 512
	var g = Gradient.new(); g.set_color(0, lo); g.set_color(1, hi); tex.color_ramp = g
	return tex

func ground_color(v: Vector3, n: Vector3) -> Color:
	var slope = 1.0 - n.y
	var c = col(T.grass)
	var hn = noise.get_noise_2d(v.x * 3.0, v.z * 3.0) * 0.5 + 0.5
	c = c.lerp(col(T.low), clamp((float(T.wl) + 6.0 - v.y) / 6.0, 0.0, 1.0))
	c = c.lerp(col(T.rock), clamp((slope - 0.18) * 3.0, 0.0, 1.0))
	c = c.lerp(col(T.peak), clamp((v.y - float(T.mount) * 0.55) / 40.0, 0.0, 1.0) * clamp(1.2 - slope * 1.6, 0.0, 1.0))
	if theme == "glacial": c = c.lerp(col(T.peak), clamp(0.8 - slope * 1.5, 0.0, 1.0))
	return c.darkened(0.12 * hn).lightened(0.06 * (1.0 - hn))

func build_water(root: Node3D) -> void:
	if T.water == "void" or OS.get_environment("NOWATER") != "": return
	var plane = MeshInstance3D.new(); var pm = PlaneMesh.new(); pm.size = Vector2(6000, 6000); plane.mesh = pm
	plane.position.y = T.wl
	var m = StandardMaterial3D.new()
	match T.water:
		"water", "oasis":
			m.albedo_color = Color("16485a") if T.water == "water" else Color("1f7a7a"); m.metallic = 0.0; m.roughness = 0.28; m.metallic_specular = 0.35
		"sea":
			m.albedo_color = Color("143e58"); m.metallic = 0.0; m.roughness = 0.25; m.metallic_specular = 0.4
		"lava":
			var tex = NoiseTexture2D.new(); var nz = FastNoiseLite.new(); nz.frequency = 0.02; nz.fractal_octaves = 4; tex.noise = nz; tex.seamless = true; tex.width = 512; tex.height = 512
			var ramp = Gradient.new(); ramp.set_color(0, Color("3a0a04")); ramp.set_color(1, Color("ffb040")); tex.color_ramp = ramp
			m.albedo_texture = tex; m.emission_enabled = true; m.emission_texture = tex; m.emission_energy_multiplier = 2.6; m.uv1_scale = Vector3(30, 30, 30); m.roughness = 0.6
		"ice":
			m.albedo_color = Color("bfe6f6"); m.metallic = 0.2; m.roughness = 0.18
	plane.material_override = m; root.add_child(plane)

# ---------- the coliseum ----------
func ring(st: SurfaceTool, r_in: float, r_out: float, y0: float, y1: float, seg: int = 96, a0: float = 0.0, a1: float = TAU) -> void:
	for k in range(seg):
		var t0 = a0 + (a1 - a0) * k / seg; var t1 = a0 + (a1 - a0) * (k + 1) / seg
		var d0 = Vector3(cos(t0), 0, sin(t0)); var d1 = Vector3(cos(t1), 0, sin(t1))
		quad(st, d0 * r_out + Vector3(0, y1, 0), d1 * r_out + Vector3(0, y1, 0), d1 * r_in + Vector3(0, y1, 0), d0 * r_in + Vector3(0, y1, 0))  # top
		quad(st, d0 * r_out + Vector3(0, y0, 0), d1 * r_out + Vector3(0, y0, 0), d1 * r_out + Vector3(0, y1, 0), d0 * r_out + Vector3(0, y1, 0))  # outer
		quad(st, d1 * r_in + Vector3(0, y0, 0), d0 * r_in + Vector3(0, y0, 0), d0 * r_in + Vector3(0, y1, 0), d1 * r_in + Vector3(0, y1, 0))  # inner

func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var n = (b - a).cross(c - a).normalized()
	for v in [a, c, b, a, d, c]:
		st.set_normal(n); st.add_vertex(v)

func box(st: SurfaceTool, center: Vector3, ext: Vector3, yaw: float) -> void:
	var bas = Basis(Vector3.UP, yaw)
	var c = []
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			for sz in [-1, 1]:
				c.append(center + bas * Vector3(sx * ext.x, sy * ext.y, sz * ext.z))
	# corners index: x(-1,1) y(-1,1) z(-1,1) -> i = (sx>0)*4+(sy>0)*2+(sz>0)
	var f = [[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]
	for q in f: quad(st, c[q[0]], c[q[1]], c[q[2]], c[q[3]])

func mat(color: Color, rough := 0.85, metal := 0.0, emit := 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_color = color; m.roughness = rough; m.metallic = metal; m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emit > 0.0: m.emission_enabled = true; m.emission = color; m.emission_energy_multiplier = emit
	return m

func add_mesh(root: Node3D, st: SurfaceTool, m: Material) -> void:
	var mi = MeshInstance3D.new(); mi.mesh = st.commit(); mi.material_override = m; root.add_child(mi)

func build_coliseum(root: Node3D) -> void:
	var stone = SurfaceTool.new(); stone.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trim = SurfaceTool.new(); trim.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dark = SurfaceTool.new(); dark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var banner = SurfaceTool.new(); banner.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sand = SurfaceTool.new(); sand.begin(Mesh.PRIMITIVE_TRIANGLES)
	ring(sand, 0.0, 30.0, -0.5, 0.4)
	ring(stone, 0.0, 62.0, -14.0, 0.0, 64)          # plinth
	ring(trim, 61.0, 62.5, -0.4, 0.6)
	# seating bowl
	for i in range(9):
		ring(stone, 30.0 + i * 2.4, 47.0, 0.0, 1.4 + i * 1.6, 96)
	ring(dark, 31.0, 31.6, 0.0, 2.2, 96)
	# outer arcade: three storeys of pillars with continuous bands
	var R = 48.0; var n = 56
	for level in range(3):
		var y0 = level * 7.0; var y1 = y0 + 7.0
		ring(dark, R - 2.0, R - 1.2, y0, y1 - 1.0, 96)   # shadowed interior behind the arches
		for k in range(n):
			var a = TAU * k / n
			box(stone, Vector3(cos(a) * R, y0 + 3.0, sin(a) * R), Vector3(0.9, 3.0, 1.0), -a)
		ring(stone, R - 1.4, R + 1.1, y1 - 1.0, y1, 112)
		ring(trim, R + 1.0, R + 1.35, y1 - 0.9, y1 - 0.5, 112)
	ring(stone, R - 1.4, R + 0.8, 21.0, 24.0, 112)    # attic storey
	ring(trim, R + 0.7, R + 1.0, 23.4, 24.0, 112)
	for k in range(28):
		var a = TAU * (k + 0.5) / 28
		box(stone, Vector3(cos(a) * R, 25.6, sin(a) * R), Vector3(0.6, 1.6, 0.6), -a)   # crown posts
		box(banner, Vector3(cos(a) * (R + 1.3), 19.0, sin(a) * (R + 1.3)), Vector3(0.06, 4.0, 1.3), -a)
	# four towers with gilded roofs
	var gold = SurfaceTool.new(); gold.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(4):
		var a = TAU * k / 4 + PI / 4
		var c = Vector3(cos(a), 0, sin(a)) * (R + 4.0)
		cone(gold, c + Vector3(0, 30, 0), 6.0, 14.0)
		ring_at(stone, c, 0.0, 5.0, 0.0, 30.0)
		ring_at(trim, c, 4.9, 5.4, 29.0, 30.5)
		box(banner, c + Vector3(0, 46, 0), Vector3(0.05, 1.4, 2.4), -a)
	var sm = mat(col(T.stone).darkened(0.12), 0.82); sm.albedo_texture = detail_tex(0.05, Color(0.78, 0.76, 0.72), Color(1.05, 1.04, 1.0)); sm.uv1_triplanar = true; sm.uv1_scale = Vector3(0.12, 0.12, 0.12); add_mesh(root, stone, sm)
	add_mesh(root, trim, mat(col(T.trim), 0.35, 0.8))
	add_mesh(root, gold, mat(col(T.trim), 0.3, 0.9))
	add_mesh(root, dark, mat(Color(0.05, 0.05, 0.06), 1.0))
	add_mesh(root, banner, mat(col(T.banner), 0.7, 0.0, 0.25))
	add_mesh(root, sand, mat(Color("c8a878") if theme != "glacial" else Color("e8f0f8"), 1.0))

func ring_at(st: SurfaceTool, c: Vector3, r_in: float, r_out: float, y0: float, y1: float) -> void:
	for k in range(24):
		var t0 = TAU * k / 24; var t1 = TAU * (k + 1) / 24
		var d0 = Vector3(cos(t0), 0, sin(t0)); var d1 = Vector3(cos(t1), 0, sin(t1))
		quad(st, c + d0 * r_out + Vector3(0, y0, 0), c + d1 * r_out + Vector3(0, y0, 0), c + d1 * r_out + Vector3(0, y1, 0), c + d0 * r_out + Vector3(0, y1, 0))
		quad(st, c + d0 * r_out + Vector3(0, y1, 0), c + d1 * r_out + Vector3(0, y1, 0), c + d1 * r_in + Vector3(0, y1, 0), c + d0 * r_in + Vector3(0, y1, 0))

func cone(st: SurfaceTool, base: Vector3, r: float, h: float, seg: int = 16) -> void:
	for k in range(seg):
		var t0 = TAU * k / seg; var t1 = TAU * (k + 1) / seg
		var a = base + Vector3(cos(t0) * r, 0, sin(t0) * r); var b = base + Vector3(cos(t1) * r, 0, sin(t1) * r)
		var tip = base + Vector3(0, h, 0)
		var nrm = (b - a).cross(tip - a).normalized()
		for v in [a, tip, b]:
			st.set_normal(nrm); st.add_vertex(v)

# ---------- props ----------
func build_props(root: Node3D) -> void:
	var rng = RandomNumberGenerator.new(); rng.seed = 7
	var trees = SurfaceTool.new(); trees.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trunks = SurfaceTool.new(); trunks.begin(Mesh.PRIMITIVE_TRIANGLES)
	var placed = 0; var tries = 0
	while placed < int(T.trees) and tries < 40000 and theme != "astral":
		tries += 1
		var x = rng.randf_range(-900, 900); var z = rng.randf_range(-1100, 400)
		var r = Vector2(x, z).length(); if r < 85: continue
		var y = height(x, z); if y < float(T.wl) + 1.0 or y > float(T.mount) * 0.5: continue
		var slope = abs(height(x + 3, z) - y) + abs(height(x, z + 3) - y); if slope > 4.0: continue
		var s = rng.randf_range(0.7, 1.5)
		if theme == "desert":
			ring_at(trunks, Vector3(x, y, z), 0.0, 0.5 * s, 0, 9 * s)
			for k in range(6): var a = TAU * k / 6; box(trees, Vector3(x + cos(a) * 3 * s, y + 9 * s, z + sin(a) * 3 * s), Vector3(3.2 * s, 0.2, 0.7 * s), -a)
		elif theme == "volcanic":
			ring_at(trunks, Vector3(x, y, z), 0.0, 0.4 * s, 0, 8 * s)
		else:
			ring_at(trunks, Vector3(x, y, z), 0.0, 0.6 * s, 0, 3 * s)
			cone(trees, Vector3(x, y + 2.5 * s, z), 4.2 * s, 11 * s, 9)
			cone(trees, Vector3(x, y + 7.0 * s, z), 3.2 * s, 9 * s, 9)
		placed += 1
	var leaf = mat(col(T.tree), 0.9)
	if theme == "glacial": leaf = mat(Color("dfeaf2"), 0.8)
	if theme == "coastal" or theme == "forest": leaf.albedo_color = col(T.tree)
	add_mesh(root, trees, leaf); add_mesh(root, trunks, mat(Color("4a3424"), 1.0))
	match theme:
		"glacial":
			var ice = SurfaceTool.new(); ice.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in range(70):
				var x = rng.randf_range(-500, 500); var z = rng.randf_range(-700, -120); var y = height(x, z)
				cone(ice, Vector3(x, y - 2, z), rng.randf_range(4, 12), rng.randf_range(25, 90), 5)
			add_mesh(root, ice, mat(Color("a8dcff"), 0.15, 0.1, 0.15))
		"desert":
			var pyr = SurfaceTool.new(); pyr.begin(Mesh.PRIMITIVE_TRIANGLES)
			for p in [[-380, -620, 120], [-230, -760, 80], [160, -900, 140]]:
				cone(pyr, Vector3(p[0], height(p[0], p[1]) - 4, p[1]), p[2], p[2] * 0.95, 4)
			for k in range(6):
				var a = PI * 0.8 + k * 0.18; var c = Vector3(cos(a), 0, sin(a)) * 95
				box(pyr, c + Vector3(0, height(c.x, c.z) + 14, 0), Vector3(1.6, 16, 1.6), 0)
			add_mesh(root, pyr, mat(Color("e0b880"), 0.9))
		"coastal":
			var lh = SurfaceTool.new(); lh.begin(Mesh.PRIMITIVE_TRIANGLES)
			var c = Vector3(-260, 0, -120); c.y = max(height(c.x, c.z), float(T.wl))
			ring_at(lh, c, 0.0, 6.0, -10, 46); cone(lh, c + Vector3(0, 46, 0), 7.0, 10)
			add_mesh(root, lh, mat(Color("f2ece4"), 0.7))
			var lamp = OmniLight3D.new(); lamp.position = c + Vector3(0, 44, 0); lamp.light_color = Color("ffd890"); lamp.light_energy = 3.0; lamp.omni_range = 60; root.add_child(lamp)
			for i in range(5):
				var sail = SurfaceTool.new(); sail.begin(Mesh.PRIMITIVE_TRIANGLES)
				var b = Vector3(rng.randf_range(-700, -250), float(T.wl), rng.randf_range(-600, 100))
				box(sail, b + Vector3(0, 1, 0), Vector3(6, 1, 2), 0.3); cone(sail, b + Vector3(0, 2, 0), 3.0, 14, 3)
				add_mesh(root, sail, mat(Color("f6f0e6"), 0.8))
		"volcanic":
			var ember = CPUParticles3D.new(); ember.amount = 400; ember.lifetime = 8; ember.preprocess = 8
			ember.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; ember.emission_box_extents = Vector3(400, 5, 400)
			ember.direction = Vector3.UP; ember.initial_velocity_min = 4; ember.initial_velocity_max = 12; ember.gravity = Vector3(0, 0.5, 0)
			var q = QuadMesh.new(); q.size = Vector2(0.8, 0.8); var em = mat(Color("ffa040"), 1.0, 0.0, 6.0); em.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; q.material = em
			ember.mesh = q; root.add_child(ember)

func build_shard(root: Node3D) -> void:
	# The arena's floating rock: an inverted, ragged cone hanging under the plateau.
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng = RandomNumberGenerator.new(); rng.seed = 3
	for k in range(40):
		var t0 = TAU * k / 40; var t1 = TAU * (k + 1) / 40
		var r0 = 66.0 + rng.randf_range(-4, 4); var r1 = 66.0 + rng.randf_range(-4, 4)
		var a = Vector3(cos(t0) * r0, -14, sin(t0) * r0); var b = Vector3(cos(t1) * r1, -14, sin(t1) * r1)
		var tip = Vector3(rng.randf_range(-8, 8), -190, rng.randf_range(-8, 8))
		var n = (b - a).cross(tip - a).normalized()
		for v in [a, tip, b]: st.set_normal(n); st.add_vertex(v)
	ring(st, 0.0, 70.0, -14.0, -0.2, 40)
	add_mesh(root, st, mat(Color("3a3256"), 0.9))
	var grass = SurfaceTool.new(); grass.begin(Mesh.PRIMITIVE_TRIANGLES); ring(grass, 60.0, 70.5, -0.3, 0.0, 64)
	add_mesh(root, grass, mat(Color("5a6aa8"), 0.9))
	var crystals = SurfaceTool.new(); crystals.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(30):
		var a = rng.randf() * TAU; var r = rng.randf_range(62, 70)
		cone(crystals, Vector3(cos(a) * r, -1, sin(a) * r), rng.randf_range(1, 2.5), rng.randf_range(5, 14), 5)
	for i in range(14):
		var a = rng.randf() * TAU
		cone(crystals, Vector3(cos(a) * 30, -60 - rng.randf() * 80, sin(a) * 30), 3, -14, 5)
	add_mesh(root, crystals, mat(Color("9a7aff"), 0.2, 0.0, 2.2))

func build_islands(root: Node3D) -> void:
	var rng = RandomNumberGenerator.new(); rng.seed = 21
	var rock = SurfaceTool.new(); rock.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top = SurfaceTool.new(); top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var glow = SurfaceTool.new(); glow.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(26):
		var c = Vector3(rng.randf_range(-900, 700), rng.randf_range(-90, 140), rng.randf_range(-1300, -150))
		if c.length() < 200: continue
		var r = rng.randf_range(14, 60)
		ring_at(top, c, 0.0, r, -2, 0)
		cone(rock, c + Vector3(0, -2, 0), r, -r * rng.randf_range(1.6, 3.0), 9)
		for k in range(rng.randi_range(2, 6)):
			var a = rng.randf() * TAU; var d = rng.randf() * r * 0.7
			cone(glow, c + Vector3(cos(a) * d, 0, sin(a) * d), r * 0.06 + 0.8, r * rng.randf_range(0.2, 0.5), 5)
	add_mesh(root, rock, mat(Color("2e2846"), 0.9))
	add_mesh(root, top, mat(Color("4a5a96"), 0.9))
	add_mesh(root, glow, mat(Color("8ad8ff"), 0.2, 0.0, 2.5))
	# a ringed planet hanging over the horizon
	var planet = MeshInstance3D.new(); var sm = SphereMesh.new(); sm.radius = 520; sm.height = 1040; planet.mesh = sm
	planet.position = Vector3(-1400, 380, -2600)
	var tex = GradientTexture2D.new(); var g = Gradient.new(); g.set_color(0, Color("6a3aa8")); g.add_point(0.35, Color("e0a0ff")); g.add_point(0.55, Color("4a2a8a")); g.add_point(0.8, Color("c890ff")); g.set_color(g.get_point_count() - 1, Color("3a2070")); tex.gradient = g; tex.fill_from = Vector2(0, 0); tex.fill_to = Vector2(0, 1)
	var pm = StandardMaterial3D.new(); pm.albedo_texture = tex; pm.emission_enabled = true; pm.emission_texture = tex; pm.emission_energy_multiplier = 0.55; pm.roughness = 1.0
	planet.material_override = pm; planet.rotation_degrees = Vector3(0, 0, 18); root.add_child(planet)
	var rings = MeshInstance3D.new(); var tm = TorusMesh.new(); tm.inner_radius = 640; tm.outer_radius = 900; tm.rings = 96; tm.ring_segments = 3; rings.mesh = tm
	rings.scale = Vector3(1, 0.02, 1); rings.position = planet.position; rings.rotation_degrees = Vector3(12, 0, 18)
	var rm = StandardMaterial3D.new(); rm.albedo_color = Color(0.85, 0.75, 1.0, 0.55); rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; rm.emission_enabled = true; rm.emission = Color("b090ff"); rm.emission_energy_multiplier = 0.6; rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rings.material_override = rm; root.add_child(rings)

func _process(_d):
	frames += 1
	if frames == 30:
		vp.get_texture().get_image().save_png(OS.get_environment("OUT"))
		print("VISTA ", theme); quit()
	return false
