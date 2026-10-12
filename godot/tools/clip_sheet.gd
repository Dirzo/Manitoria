extends SceneTree
## Renders contact sheets of a model's clips: one row per clip, FRAMES evenly spaced poses per row.
## Needs a renderer (not --headless). Example on a display-less box:
##   xvfb-run -a godot --path godot --rendering-driver opengl3 -s tools/clip_sheet.gd -- \
##       --model res://assets/beasts/direwolf.glb --clips idle,attack_1,death --out /tmp/direwolf.png
## Options: --frames 6  --size 220  --yaw 35 (camera yaw, degrees)  --library <AnimationLibrary .res to add>
var args := {}

func _initialize() -> void:
	var raw = OS.get_cmdline_user_args()
	for i in range(0, raw.size() - 1, 2): args[raw[i].trim_prefix("--")] = raw[i + 1]
	run.call_deferred()

func opt(k: String, d: String) -> String:
	return str(args.get(k, d))

func run() -> void:
	var size = int(opt("size", "220"))
	var frames = int(opt("frames", "6"))
	var view = SubViewport.new(); view.size = Vector2i(size, size); view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS; view.msaa_3d = Viewport.MSAA_4X
	get_root().add_child(view)
	var world = Node3D.new(); view.add_child(world)
	var env = WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color("2b3a42")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.55, 0.55, 0.6)
	world.add_child(env)
	var sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-70, 20, 0); sun.shadow_enabled = true; world.add_child(sun)
	var floor_mesh = MeshInstance3D.new(); var plane = PlaneMesh.new(); plane.size = Vector2(40, 40); floor_mesh.mesh = plane
	var fm = StandardMaterial3D.new(); fm.albedo_color = Color("3d6b70"); floor_mesh.material_override = fm; world.add_child(floor_mesh)
	var path = opt("model", "")
	var model: Node3D = load(path).instantiate() if path.begins_with("res://") else null
	if model == null:
		var doc = GLTFDocument.new(); var state = GLTFState.new()
		if doc.append_from_file(path, state) == OK: model = doc.generate_scene(state)
	if model == null: print("cannot load ", path); quit(1); return
	world.add_child(model)
	var ap: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
	if path.begins_with("res://assets/beasts/") and not args.has("library") and not args.has("raw"):
		CombatAnimator.apply_clip_library(ap, path.get_file().get_basename())
	if args.has("library"):
		var lib = load(opt("library", ""))
		if lib: ap.add_animation_library("rt", lib)
	var box := AABB(); var first = true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var b = mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b); first = false
	var cam = Camera3D.new(); world.add_child(cam)
	var c = box.get_center(); var r = maxf(box.size.y, maxf(box.size.x, box.size.z))
	var yaw = deg_to_rad(float(opt("yaw", "35")))
	cam.position = c + Vector3(sin(yaw), float(opt("elev", "0.22")), cos(yaw)).normalized() * r * 1.6
	cam.look_at(c); cam.fov = 50
	var clips = Array(opt("clips", "idle").split(","))
	var sheet = Image.create(size * frames, size * clips.size(), false, Image.FORMAT_RGB8)
	for row in clips.size():
		var name = clips[row]
		var anim_name = name if ap.has_animation(name) else "rt/" + name
		if not ap.has_animation(anim_name): print("missing clip ", name); continue
		var length = ap.get_animation(anim_name).length
		ap.play(anim_name); ap.speed_scale = 0.0
		for f in frames:
			ap.seek(length * float(f) / maxf(1, frames - 1) * 0.999, true)
			await process_frame
			await RenderingServer.frame_post_draw
			var img = view.get_texture().get_image()
			img.convert(Image.FORMAT_RGB8)
			sheet.blit_rect(img, Rect2i(0, 0, size, size), Vector2i(f * size, row * size))
	sheet.save_png(opt("out", "/tmp/sheet.png"))
	print("wrote ", opt("out", "/tmp/sheet.png"))
	quit()
