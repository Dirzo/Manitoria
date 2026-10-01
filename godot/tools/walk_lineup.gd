extends SceneTree
## Parade: creatures walk across a checkered floor at their real combat speed with the arena's
## walk-rate rule, so foot planting can be judged on video. env: SPS (comma list), OUT, SECS
var sps: Array; var items := []; var frame := 0; var out := ""; var total := 60
func _init() -> void:
	HeroData.load_data()
	sps = Array(OS.get_environment("SPS").split(",")); out = OS.get_environment("OUT")
	total = int(float(OS.get_environment("SECS") if OS.get_environment("SECS") != "" else "2.5") * 30.0)
	RenderingServer.render_loop_enabled = false
	var r3 = Node3D.new(); get_root().add_child(r3)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.16, 0.18, 0.22)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.6, 0.6, 0.65); e.ambient_light_energy = 0.8
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.environment = e; r3.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55, -20, 0); sun.shadow_enabled = true; sun.light_energy = 1.2; r3.add_child(sun)
	var fl := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(80, 60); fl.mesh = pm
	var sm := ShaderMaterial.new(); var sh := Shader.new()
	sh.code = "shader_type spatial; varying vec3 wp; void vertex(){ wp = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; } void fragment(){ vec2 c = floor(wp.xz/1.0); float k = mod(c.x+c.y,2.0); ALBEDO = mix(vec3(0.20,0.21,0.19), vec3(0.30,0.31,0.28), k); ROUGHNESS = 0.9; }"
	sm.shader = sh; fl.material_override = sm; r3.add_child(fl)
	var cam := Camera3D.new(); r3.add_child(cam); cam.current = true; cam.fov = 38
	var n = sps.size()
	cam.look_at_from_position(Vector3(0, 4.0 + n * 1.2, -6.5 - n * 1.0), Vector3(0, 0.6, (n - 1) * 1.4), Vector3.UP)
	for i in range(n):
		var sp = sps[i]
		var holder := Node3D.new(); r3.add_child(holder)
		var m: Node3D = load("res://assets/beasts/%s.glb" % sp).instantiate(); holder.add_child(m); m.scale = Vector3.ONE * 0.72
		m.rotation.y = PI * 0.5
		var ap: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
		ap.get_animation("walk").loop_mode = Animation.LOOP_LINEAR; ap.play("walk")
		var v = HeroData.species[sp].mv * 0.036 * ArenaView.FLOOR_SCALE
		ap.speed_scale = GaitRates.walk_rate(sp, v)
		holder.position = Vector3(-5.0 + randf() * 2.0, 0, i * 2.8)
		var lab := Label3D.new(); lab.text = sp.capitalize(); lab.position = Vector3(0, 0.05, -1.0); lab.rotation_degrees = Vector3(-90, 180, 0); lab.font_size = 64; lab.pixel_size = 0.01; holder.add_child(lab)
		items.append({"h": holder, "v": v, "ap": ap})
func _process(_d) -> bool:
	var dt = 1.0 / 30.0
	for it in items:
		it.h.position.x += it.v * dt
		if it.h.position.x > 6.5: it.h.position.x -= 13.0
	RenderingServer.force_draw(false)
	get_root().get_texture().get_image().save_jpg("%s/f%04d.jpg" % [out, frame], 0.88)
	frame += 1
	if frame >= total: quit(); return true
	return false
