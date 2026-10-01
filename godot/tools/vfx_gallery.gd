extends SceneTree
## Offline VFX gallery: stages an effect, steps the VFX clock deterministically and saves frames.
## env: SCENE (callable name in VfxGallery cases), TIMES (comma list), OUT (dir), SIZE (e.g. 640x400)

var vfx: VFX
var cam: Camera3D
var frames: Array = []
var step := 0
var times: Array = []
var clock := 0.0
var out_dir := ""
var case_name := ""
var case_list: Array = []
var ci := 0
var stage_root: Node3D

func _init() -> void:
	var root3 = Node3D.new(); get_root().add_child(root3)
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.09, 0.1, 0.13)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.5, 0.52, 0.6); e.ambient_light_energy = 0.5
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; e.glow_enabled = true; e.glow_intensity = 0.9; e.glow_bloom = 0.15
	env.environment = e; root3.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, -30, 0); sun.light_energy = 1.1; root3.add_child(sun)
	var floor := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(30, 30); floor.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.23, 0.21, 0.19); fm.roughness = 0.95; floor.material_override = fm; root3.add_child(floor)
	cam = Camera3D.new(); cam.fov = 42; root3.add_child(cam); cam.current = true
	cam.look_at_from_position(Vector3(0, 5.2, 9.5), Vector3(0, 1.2, 0))
	stage_root = Node3D.new(); root3.add_child(stage_root)
	vfx = VFX.new(); root3.add_child(vfx)
	times = Array(OS.get_environment("TIMES").split(",")).map(func(s): return float(s))
	out_dir = OS.get_environment("OUT")
	case_list = OS.get_environment("CASES").split(",")
	var cam_env = OS.get_environment("CAM")
	if cam_env != "":
		var v = cam_env.split(",")
		cam.look_at_from_position(Vector3(float(v[0]), float(v[1]), float(v[2])), Vector3(float(v[3]), float(v[4]), float(v[5])))
	_start_case()

func _start_case() -> void:
	vfx.clear(); clock = 0.0; step = 0
	for c in stage_root.get_children(): c.queue_free()
	case_name = case_list[ci]
	var cases = load("res://tools/vfx_cases.gd").new()
	cases.stage(case_name, vfx, stage_root)

func _process(_dt: float) -> bool:
	# Advance to the next capture time in fixed 1/60 steps, render, capture.
	if step >= times.size():
		ci += 1
		if ci >= case_list.size(): quit(); return true
		_start_case(); return false
	var target: float = times[step]
	while clock + 1.0 / 60.0 <= target:
		vfx.advance(1.0 / 60.0); clock += 1.0 / 60.0
	if not has_meta("wait"):
		set_meta("wait", 2); return false
	var w = get_meta("wait") - 1
	if w > 0: set_meta("wait", w); return false
	remove_meta("wait")
	var img = get_root().get_texture().get_image()
	img.save_png("%s/%s_%02d.png" % [out_dir, case_name, step])
	step += 1
	return false
