extends SceneTree
# Action renders for skill icons: each job poses one creature (clip, time, yaw, zoom) under a
# coloured rim light. env JOBS = path to a JSON list of {sp, pose, t, yaw, zoom, dx, dy, rim, out}
var frames = 0
var queue = []
var cur = null
var cam: Camera3D
var holder: Node3D
var rim: DirectionalLight3D
var rim2: DirectionalLight3D
var vp: SubViewport
var job = {}
func _init():
	vp = SubViewport.new(); vp.size = Vector2i(400, 400)
	vp.transparent_bg = true; vp.msaa_3d = Viewport.MSAA_4X; vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(vp)
	var root3 = Node3D.new(); vp.add_child(root3)
	var env = WorldEnvironment.new(); var e = Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.6, 0.62, 0.72); e.ambient_light_energy = 0.35
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; e.tonemap_exposure = 1.1
	env.environment = e; root3.add_child(env)
	var key = DirectionalLight3D.new(); key.rotation_degrees = Vector3(-32, -42, 0); key.light_energy = 1.5; key.light_color = Color(1.0, 0.95, 0.88); root3.add_child(key)
	rim = DirectionalLight3D.new(); rim.rotation_degrees = Vector3(-18, 160, 0); rim.light_energy = 4.0; root3.add_child(rim)
	rim2 = DirectionalLight3D.new(); rim2.rotation_degrees = Vector3(-8, -150, 0); rim2.light_energy = 2.2; root3.add_child(rim2)
	cam = Camera3D.new(); cam.fov = 34; root3.add_child(cam); cam.current = true
	holder = Node3D.new(); root3.add_child(holder)
	queue = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("JOBS")))
	cache = {}
var cache = {}
func load_next():
	if cur: holder.remove_child(cur); cur.queue_free()
	job = queue[0]
	var c = Color(job.get("rim", "ffffff")); rim.light_color = c; rim2.light_color = c.lerp(Color.WHITE, 0.35)
	if not cache.has(job.sp): cache[job.sp] = load("res://assets/beasts/%s.glb" % job.sp)
	cur = cache[job.sp].instantiate()
	cur.rotation_degrees.y = float(job.get("yaw", -28))
	holder.add_child(cur)
	var aps = cur.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		var ap = aps[0]; var clip = job.get("pose", "idle")
		if not ap.has_animation(clip): clip = "idle"
		if ap.has_animation(clip):
			ap.play(clip); ap.seek(ap.get_animation(clip).length * float(job.get("t", 0.0)), true); ap.pause()
func fit():
	var box = AABB(); var first = true
	for mi in cur.find_children("*", "MeshInstance3D", true, false):
		if not mi.visible: continue
		var b = mi.global_transform * mi.get_aabb()
		if first: box = b; first = false
		else: box = box.merge(b)
	var c = box.get_center()
	var vh = tan(deg_to_rad(cam.fov * 0.5))
	var ext = maxf(box.size.y, maxf(box.size.x, box.size.z)) * 0.5
	var dist = ext / vh * float(job.get("zoom", 1.0)) + maxf(box.size.x, box.size.z) * 0.3
	var off = Vector3(float(job.get("dx", 0)) * ext, float(job.get("dy", 0)) * ext, 0)
	var dir = Vector3(0.08, 0.10 + float(job.get("pitch", 0.0)), 1).normalized()
	cam.look_at_from_position(c + off + dir * dist, c + off)
func _process(_d):
	if queue.is_empty():
		quit(); return false
	if frames == 0: load_next()
	if frames == 2: fit()
	frames += 1
	if frames == 6:
		vp.get_texture().get_image().save_png(job.out)
		queue.remove_at(0); frames = 0
		if queue.size() % 20 == 0: print("LEFT ", queue.size())
	return false
