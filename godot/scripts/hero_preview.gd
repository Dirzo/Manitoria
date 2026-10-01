class_name HeroPreview
extends SubViewportContainer

var species_id = "kirin"
var player: AnimationPlayer
var portrait_camera: Camera3D
var portrait_extent = Vector2.ONE

func _ready() -> void:
 stretch = true
 var viewport = SubViewport.new(); viewport.size = Vector2i(400, 320); viewport.own_world_3d = true; viewport.transparent_bg = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; viewport.msaa_3d = Viewport.MSAA_2X; add_child(viewport)
 var env = WorldEnvironment.new(); env.environment = Environment.new(); viewport.add_child(env)
 env.environment.background_mode = Environment.BG_CLEAR_COLOR; env.environment.background_color = Color(0,0,0,0)
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_energy = 0.6
 env.environment.ambient_light_color = Color("acc9dd"); env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
 for spec in [[Vector3(-35, -40, 0), Color("ffe4bf"), 1.5], [Vector3(-20, 135, 0), Color("9fcff3"), 1.3]]:
  var light = DirectionalLight3D.new(); light.rotation_degrees = spec[0]; light.light_color = spec[1]; light.light_energy = spec[2]; viewport.add_child(light)
 var model = load("res://assets/beasts/%s.glb" % species_id).instantiate(); viewport.add_child(model)
 var players = model.find_children("*", "AnimationPlayer", true, false)
 if not players.is_empty(): player = players[0]; play("idle")
 var bounds = AABB(); var first = true
 for mesh in model.find_children("*", "MeshInstance3D", true, false):
  var b = mesh.global_transform * mesh.get_aabb(); bounds = b if first else bounds.merge(b); first = false
 var center = bounds.get_center()
 var camera = Camera3D.new(); viewport.add_child(camera); camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.position = center + Vector3(.85, .30, 1.25).normalized() * 20; camera.look_at(center)
 var extent = Vector2.ZERO
 for i in range(8):
  var corner = camera.global_transform.affine_inverse() * bounds.get_endpoint(i)
  extent.x = maxf(extent.x, absf(corner.x)); extent.y = maxf(extent.y, absf(corner.y))
 portrait_camera = camera; portrait_extent = extent
 camera.make_current(); resized.connect(fit_camera); call_deferred("fit_camera")

func fit_camera() -> void:
 if is_instance_valid(portrait_camera): portrait_camera.size = maxf(portrait_extent.y*2.35,portrait_extent.x*2.35/maxf(0.5,size.x/maxf(1,size.y)))

func play(clip: String) -> void:
 if player and player.has_animation(clip):
  if clip in ["idle","walk"]: player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
  player.play(clip, 0.18)
  if clip not in ["idle","walk"]: player.queue("idle")
