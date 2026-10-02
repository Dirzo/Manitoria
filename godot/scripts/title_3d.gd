class_name Title3D
extends SubViewportContainer
## The MANITORIA signature title: extruded Uncial letters in burnished gold over a dark bronze
## backing, lit by warm key and rim lights, with a slow sway and a glint that sweeps across.
var text := "MANITORIA"
var vp: SubViewport
var pivot: Node3D
var glint: OmniLight3D
var t := 0.0
var cam: Camera3D
var face_mesh: TextMesh

func _ready() -> void:
	stretch = true; mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp = SubViewport.new(); vp.transparent_bg = true; vp.msaa_3d = Viewport.MSAA_4X; vp.size = Vector2i(size) if size.x > 8 else Vector2i(1600, 220)
	add_child(vp)
	var env = WorldEnvironment.new(); var e = Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	var sky = Sky.new(); var sm = ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.25, 0.2, 0.15); sm.sky_horizon_color = Color(1.0, 0.85, 0.55); sm.ground_bottom_color = Color(0.45, 0.3, 0.15); sm.ground_horizon_color = Color(0.85, 0.65, 0.35)
	sky.sky_material = sm; e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; e.ambient_light_energy = 0.5
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; e.tonemap_exposure = 1.1
	env.environment = e; vp.add_child(env)
	cam = Camera3D.new(); cam.fov = 22; cam.position = Vector3(0, 0, 9.5); vp.add_child(cam); cam.current = true
	var key = DirectionalLight3D.new(); key.rotation_degrees = Vector3(-30, -25, 0); key.light_energy = 1.4; key.light_color = Color(1, 0.92, 0.78); vp.add_child(key)
	var rim = DirectionalLight3D.new(); rim.rotation_degrees = Vector3(-10, 160, 0); rim.light_energy = 2.5; rim.light_color = Color(1.0, 0.6, 0.25); vp.add_child(rim)
	var fill = DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-8, 0, 0); fill.light_energy = 0.7; fill.light_color = Color(1, 0.9, 0.7); vp.add_child(fill)
	glint = OmniLight3D.new(); glint.light_energy = 6.0; glint.omni_range = 3.0; glint.light_color = Color(1, 0.95, 0.8); glint.position = Vector3(-6, 0.4, 1.2); vp.add_child(glint)
	pivot = Node3D.new(); vp.add_child(pivot)
	var font = load("res://assets/fonts/uncialantiqua.ttf")
	# Gold face
	var face = TextMesh.new(); face.text = text; face.font = font; face.font_size = 64; face.depth = 0.18; face.pixel_size = 0.012; face.curve_step = 0.5
	var gold = StandardMaterial3D.new(); gold.albedo_color = Color(1.0, 0.78, 0.36); gold.metallic = 0.85; gold.roughness = 0.32
	gold.rim_enabled = true; gold.rim = 0.4; gold.rim_tint = 0.3
	face_mesh = face
	var fm = MeshInstance3D.new(); fm.mesh = face; fm.material_override = gold; pivot.add_child(fm)
	# Dark bronze backing, slightly larger and deeper: reads as a bevelled outline.
	var back = TextMesh.new(); back.text = text; back.font = font; back.font_size = 64; back.depth = 0.30; back.pixel_size = 0.012; back.curve_step = 0.5
	var bronze = StandardMaterial3D.new(); bronze.albedo_color = Color(0.32, 0.15, 0.06); bronze.metallic = 0.9; bronze.roughness = 0.45
	var bm = MeshInstance3D.new(); bm.mesh = back; bm.material_override = bronze; bm.position = Vector3(0.035, -0.045, -0.16); pivot.add_child(bm)
	resized.connect(func(): fit())
	fit()

## Frame the word so it fills ~92% of the control's width at any size.
func fit() -> void:
	if vp == null or face_mesh == null or size.x < 8: return
	vp.size = Vector2i(size)
	var w = face_mesh.get_aabb().size.x * 1.03
	var aspect = size.x / maxf(1.0, size.y)
	var d = w / (0.92 * 2.0 * tan(deg_to_rad(cam.fov * 0.5)) * aspect)
	var h = face_mesh.get_aabb().size.y
	d = maxf(d, h / (0.8 * 2.0 * tan(deg_to_rad(cam.fov * 0.5))))
	cam.position = Vector3(0, 0, d + 0.2)

func _process(dt: float) -> void:
	t += dt
	if pivot:
		pivot.rotation.y = sin(t * 0.45) * 0.05
		pivot.rotation.x = sin(t * 0.33) * 0.04 - 0.05
	if glint:
		# The glint sweeps left to right every few seconds.
		var phase = fmod(t, 5.5) / 5.5
		glint.position.x = lerpf(-7.0, 7.0, phase); glint.light_energy = 4.0 * sin(phase * PI)
