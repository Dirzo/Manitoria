extends SceneTree
# Dramatic hero render for splash cards: low 3/4 camera, element-coloured rim light,
# tight framing so the creature fills (and slightly breaks) a tall card. Transparent output.
# env: SPS (comma list), OUTDIR, W, H, POSE (idle|attack|cast), T (0..1 of clip)
var frames = 0
var queue = []
var cur = null
var cam : Camera3D
var holder : Node3D
var rim : DirectionalLight3D
var rim2 : DirectionalLight3D
var vp : SubViewport
const ELEM = {"beast":"ffae5c","stone":"7fe0d0","shadow":"b07cff","venom":"8cff6a","wing":"9fd8ff","spirit":"ff8ce8","fire":"ff7a2e","lightning":"7cc4ff","nature":"b6ff7a","water":"4fe0e8","holy":"ffd36e","ice":"9ff0ff","shield":"ffc27a","claw":"ff6a5a","quake":"ff9f50"}
func _init():
	vp = SubViewport.new(); vp.size = Vector2i(int(OS.get_environment("W")), int(OS.get_environment("H")))
	vp.transparent_bg = true; vp.msaa_3d = Viewport.MSAA_4X; vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(vp)
	var root3 = Node3D.new(); vp.add_child(root3)
	var env = WorldEnvironment.new(); var e = Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.6,0.62,0.72); e.ambient_light_energy = 0.3
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; e.tonemap_exposure = 1.1
	env.environment = e; root3.add_child(env)
	var key = DirectionalLight3D.new(); key.rotation_degrees = Vector3(-32, -42, 0); key.light_energy = 1.55; key.light_color = Color(1.0,0.95,0.88); key.shadow_enabled = true; root3.add_child(key)
	rim = DirectionalLight3D.new(); rim.rotation_degrees = Vector3(-18, 160, 0); rim.light_energy = 4.0; root3.add_child(rim)
	rim2 = DirectionalLight3D.new(); rim2.rotation_degrees = Vector3(-8, -150, 0); rim2.light_energy = 2.2; root3.add_child(rim2)
	var fill = DirectionalLight3D.new(); fill.rotation_degrees = Vector3(10, 40, 0); fill.light_energy = 0.25; fill.light_color = Color(0.6,0.7,1.0); root3.add_child(fill)
	cam = Camera3D.new(); cam.fov = 34; root3.add_child(cam); cam.current = true
	holder = Node3D.new(); root3.add_child(holder)
	queue = OS.get_environment("SPS").split(",")
func load_next():
	if cur: cur.queue_free()
	var sp = queue[0]
	var fam = SoundDesign.SPECIES_FAMILY.get(sp, "beast")
	var c = Color(ELEM.get(fam, "ffffff")); rim.light_color = c; rim2.light_color = c.lerp(Color.WHITE, 0.35)
	cur = load("res://assets/beasts/%s.glb" % sp).instantiate()
	cur.rotation_degrees.y = float(OS.get_environment("YAW") if OS.get_environment("YAW") != "" else "-28")
	holder.add_child(cur)
	var aps = cur.find_children("*","AnimationPlayer",true,false)
	var pose = OS.get_environment("POSE"); if pose == "": pose = "idle"
	if aps.size() > 0:
		var ap = aps[0]; var clip = pose if ap.has_animation(pose) else "idle"
		if ap.has_animation(clip):
			ap.play(clip); ap.seek(ap.get_animation(clip).length * float(OS.get_environment("T") if OS.get_environment("T") != "" else "0.0"), true); ap.pause()
func fit():
	var box = AABB(); var first = true
	for mi in cur.find_children("*","MeshInstance3D",true,false):
		if not mi.visible: continue
		var b = mi.global_transform * mi.get_aabb()
		if first: box = b; first = false
		else: box = box.merge(b)
	var aspect = float(OS.get_environment("W")) / float(OS.get_environment("H"))
	var c = box.get_center()
	var vh = tan(deg_to_rad(cam.fov * 0.5))
	# Fit whichever dimension binds, then push in ~12% so the creature breaks the frame edges.
	var need_h = box.size.y * 0.5 / vh
	var need_w = max(box.size.x, box.size.z) * 0.5 / (vh * aspect)
	var dist = max(need_h, need_w) * 1.0 + max(box.size.x, box.size.z) * 0.3
	var dir = Vector3(0.05, -0.02, 1).normalized()
	cam.look_at_from_position(c + dir * dist, c + Vector3(0, box.size.y * 0.02, 0))
func _process(d):
	if queue.is_empty():
		quit(); return false
	if frames == 0: load_next()
	if frames == 2: fit()
	frames += 1
	if frames == 8:
		var img = vp.get_texture().get_image()
		img.save_png(OS.get_environment("OUTDIR") + "/" + queue[0] + ".png")
		print("SPLASH ", queue[0])
		queue.remove_at(0); frames = 0
	return false
