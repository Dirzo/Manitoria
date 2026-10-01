extends SceneTree
## Side-view strip of a creature's walk cycle at 8 phases (facing right = model +Z).
var sp_list: Array; var si := 0; var k := 0; var w := 0
var holder: Node3D; var ap: AnimationPlayer; var cam: Camera3D
func _init() -> void:
	sp_list = Array(OS.get_environment("SPS").split(","))
	var r3 = Node3D.new(); get_root().add_child(r3)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.5, 0.55, 0.6)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.7, 0.7, 0.7); env.environment = e; r3.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, 30, 0); sun.shadow_enabled = true; r3.add_child(sun)
	var fl := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(40, 40); fl.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.3, 0.3, 0.28); fl.material_override = fm; r3.add_child(fl)
	holder = Node3D.new(); r3.add_child(holder)
	cam = Camera3D.new(); r3.add_child(cam); cam.current = true; cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.size = float(OS.get_environment("CSIZE")) if OS.get_environment("CSIZE") != "" else 3.2
	cam.look_at_from_position(Vector3(8, 0.9, 0), Vector3(0, 0.9, 0))   # looking along -X: model +Z points to screen-left? 
	_load()
func _load() -> void:
	for c in holder.get_children(): c.free()
	var m: Node3D = load("res://assets/beasts/%s.glb" % sp_list[si]).instantiate(); holder.add_child(m); m.scale = Vector3.ONE * 0.72
	ap = m.find_children("*", "AnimationPlayer", true, false)[0]; ap.play("walk"); ap.speed_scale = 0
	k = 0
func _process(_d) -> bool:
	var L = ap.get_animation("walk").length
	ap.seek(L * k / 12.0, true)
	w += 1
	if w < 3: return false
	w = 0
	get_root().get_texture().get_image().save_png("/home/claude/strip/%s_%d.png" % [sp_list[si], k])
	k += 1
	if k >= 12:
		si += 1
		if si >= sp_list.size(): quit(); return true
		_load()
	return false
