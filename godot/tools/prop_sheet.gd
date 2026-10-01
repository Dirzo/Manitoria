extends SceneTree
## Renders each prop mesh (front + side) for identification. env: NAMES, OUT
var names: Array; var i := 0; var holder: Node3D; var cam: Camera3D; var w := 0
func _init() -> void:
	names = Array(OS.get_environment("NAMES").split(","))
	var r3 = Node3D.new(); get_root().add_child(r3)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.12, 0.13, 0.16)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.6, 0.6, 0.65); env.environment = e; r3.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, -35, 0); r3.add_child(sun)
	holder = Node3D.new(); r3.add_child(holder)
	cam = Camera3D.new(); r3.add_child(cam); cam.current = true; cam.look_at_from_position(Vector3(0, 0.6, 2.6), Vector3(0, 0.45, 0))
	_load()
func _load() -> void:
	for c in holder.get_children(): c.queue_free()
	for k in range(2):
		var m := MeshInstance3D.new(); m.mesh = load("res://assets/vfx_props/%s.res" % names[i]); m.position = Vector3(-0.6 + k * 1.2, 0, 0); m.rotation.y = k * PI * 0.5
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.8, 0.75, 0.68); m.material_override = mat; holder.add_child(m)
func _process(_d) -> bool:
	w += 1
	if w < 4: return false
	w = 0
	get_root().get_texture().get_image().save_png("%s/%s.png" % [OS.get_environment("OUT"), names[i]])
	i += 1
	if i >= names.size(): quit(); return true
	_load(); return false
