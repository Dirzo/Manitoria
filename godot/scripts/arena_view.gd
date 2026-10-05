class_name ArenaView
extends Node3D

signal legendary_moment(duration: float)
signal hitstop(duration: float)

## Fighters read big and chunky on the floor (was 0.72).
const MODEL_SCALE = 0.98
const BAR_LIFT = 1.32
const HITFLASH = preload("res://shaders/vfx/hitflash.gdshader")
var shake := 0.0
var shake_seed := 0.0

const FLOOR_SCALE = 1.45

static func world_point(pos: Vector2, height: float = 0.03) -> Vector3:
 return Vector3(pos.x * FLOOR_SCALE, height, pos.y * FLOOR_SCALE)

var physical_casts: Dictionary={}
var card_particles: CardParticles
var camera: Camera3D
var fighters = Node3D.new()
var effects = Node3D.new()
var models: Dictionary = {}
var resources: Dictionary = {}
var camera_yaw = 0.30
var camera_distance = 33.0
var target_yaw = 0.30
var target_distance = 33.0
var elapsed = 0.0
var inspecting = false
var flames: Array = []
var current_speed = 1.0
var effect_tweens: Array = []
var missiles: Dictionary = {}
var zone_visuals: Dictionary = {}
var telegraphs: Dictionary = {}
var clarity: SkillClarity
var combat_numbers: Dictionary = {}
var camera_pitch = 0.8
var target_pitch = 0.8
var perimeter: Array = []
var build_from_code = false
var world_stage: Node3D
var world_props: Node3D
var region_name = ""
var theme_materials: Array = []
var vfx: VFX
var sim_ref: BattleSim
var trail_clock: Dictionary = {}

func material(color: Color, metal: float = 0.0, roughness: float = 0.8, glow: bool = false) -> StandardMaterial3D:
 var m = StandardMaterial3D.new()
 m.albedo_color = color; m.metallic = metal; m.roughness = roughness
 if glow: m.emission_enabled = true; m.emission = color; m.emission_energy_multiplier = 0.35
 return m

func mesh(parent: Node3D, shape: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
 var node = MeshInstance3D.new(); node.mesh = shape; node.material_override = mat; node.position = pos
 parent.add_child(node)
 if parent == self and Vector2(pos.x, pos.z).length() > 11.5:
  perimeter.append(node); node.add_to_group("arena_perimeter", true)
 return node

func box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
 var shape = BoxMesh.new(); shape.size = size
 return mesh(parent, shape, mat, pos)

func cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, vertices: int = 48) -> MeshInstance3D:
 var shape = CylinderMesh.new(); shape.top_radius = radius; shape.bottom_radius = radius; shape.height = height; shape.radial_segments = vertices
 return mesh(parent, shape, mat, pos)

func _ready() -> void:
 add_child(fighters); add_child(effects)
 vfx = VFX.new(); vfx.name = "AbilityVFX"; add_child(vfx)
 clarity = SkillClarity.new(); clarity.name = "SkillClarity"; add_child(clarity)
 card_particles=CardParticles.new();effects.add_child(card_particles)
 effects.scale = Vector3(FLOOR_SCALE, 1, FLOOR_SCALE)
 if not build_from_code and ResourceLoader.exists("res://scenes/arena_environment.tscn"):
  var stage = load("res://scenes/arena_environment.tscn").instantiate(); add_child(stage); world_stage=stage
  for node in stage.find_children("*", "Node3D", true, false):
   if node is MeshInstance3D and node.mesh is TorusMesh: node.visible = false
   if node is MeshInstance3D and node.mesh is BoxMesh and node.position.y < 0.1 and absf(Vector2(node.position.x,node.position.z).length()-4.3)<0.1: node.visible = false
   if node is Camera3D: camera = node
   if node.is_in_group("arena_perimeter"): perimeter.append(node)
   if node.is_in_group("arena_flames"): flames.append(node)
  if RenderingServer.get_current_rendering_method() == "gl_compatibility":
   for node in stage.get_children():
    if node is WorldEnvironment: node.environment.ssao_enabled = false; node.environment.glow_enabled = false
  camera.reparent(self); camera.scale = Vector3.ONE
  stage.scale = Vector3(FLOOR_SCALE, 1, FLOOR_SCALE)
  polish_stage(stage)
  camera.make_current(); update_camera(1.0)
  return
 var env = WorldEnvironment.new()
 var environment = Environment.new()
 environment.background_mode = Environment.BG_COLOR
 environment.background_color = Color("080f1a")
 environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color = Color("83a5c6"); environment.ambient_light_energy = 0.42
 environment.tonemap_mode = Environment.TONE_MAPPER_ACES
 if RenderingServer.get_current_rendering_method() != "gl_compatibility":
  environment.ssao_enabled = true; environment.ssao_radius = 1.5; environment.ssao_intensity = 1.8
  environment.glow_enabled = true; environment.glow_intensity = 0.65
 environment.fog_enabled = true; environment.fog_light_color = Color("263442"); environment.fog_density = 0.002
 env.environment = environment; add_child(env)
 var key = DirectionalLight3D.new(); key.rotation_degrees = Vector3(-54, -34, 0)
 key.light_color = Color("ffe1b6"); key.light_energy = 1.4; key.shadow_enabled = true
 key.directional_shadow_max_distance = 65; key.shadow_bias = 0.04; add_child(key)
 var rim = DirectionalLight3D.new(); rim.rotation_degrees = Vector3(-22, 145, 0)
 rim.light_color = Color("83b6df"); rim.light_energy = 0.5; add_child(rim)
 build_architecture()
 camera = Camera3D.new(); camera.fov = 43; camera.far = 180; add_child(camera); camera.make_current()
 update_camera(1.0)

func build_architecture() -> void:
 var stone = material(Color("263841"), 0.1, 0.86)
 var dark = material(Color("131f28"), 0.18)
 var trim = material(Color("86704e"), 0.60, 0.56)
 var pale = material(Color("5e6e74"), 0.12)
 var noise = FastNoiseLite.new(); noise.frequency = 0.045; noise.fractal_octaves = 5
 var surface = NoiseTexture2D.new(); surface.width = 512; surface.height = 512; surface.seamless = true; surface.noise = noise
 var ramp = Gradient.new(); ramp.set_color(0, Color("4f5758")); ramp.set_color(1, Color("b9b5a6")); surface.color_ramp = ramp
 var normal = NoiseTexture2D.new(); normal.width = 512; normal.height = 512; normal.seamless = true; normal.noise = noise; normal.as_normal_map = true; normal.bump_strength = 1.2
 for mat in [stone, dark, pale]:
  mat.albedo_texture = surface; mat.normal_enabled = true; mat.normal_texture = normal; mat.normal_scale = 0.7
  mat.uv1_triplanar = true; mat.uv1_scale = Vector3(0.7, 0.7, 0.7)
 box(self, Vector3(180, 0.7, 180), Vector3(0, -2.0, 0), dark)
 var base = cylinder(self, 18.0, 1.1, Vector3(0, -0.8, 0), dark, 96); base.scale.z = 0.70
 var floor_node = cylinder(self, 17.1, 0.24, Vector3(0, -0.15, 0), stone, 96); floor_node.scale.z = 0.69
 # One instanced draw for the individually colored arena pavers.
 var tile_mesh = BoxMesh.new(); tile_mesh.size = Vector3(1.38, 0.045, 1.38)
 var multimesh = MultiMesh.new(); multimesh.transform_format = MultiMesh.TRANSFORM_3D; multimesh.use_colors = true; multimesh.mesh = tile_mesh
 var positions = []
 for x in range(-11, 12):
  for z in range(-7, 8):
   var pos = Vector3(x * 1.43, 0.001, z * 1.43)
   if pow(pos.x / 16.6, 2) + pow(pos.z / 11.0, 2) < 1.0: positions.append(pos)
 multimesh.instance_count = positions.size()
 var tile_mat = material(Color("515e5e"), 0.05, 0.86); tile_mat.vertex_color_use_as_albedo = true
 tile_mat.albedo_texture = surface; tile_mat.normal_enabled = true; tile_mat.normal_texture = normal; tile_mat.normal_scale = 0.8
 var rng = RandomNumberGenerator.new(); rng.seed = 1017
 for i in range(positions.size()):
  multimesh.set_instance_transform(i, Transform3D(Basis(), positions[i]))
  var shade = rng.randf_range(0.62, 0.88); multimesh.set_instance_color(i, Color(shade, shade * 1.01, shade * 0.97))
 var tiles = MultiMeshInstance3D.new(); tiles.multimesh = multimesh; tiles.material_override = tile_mat; add_child(tiles)


 for i in range(12):
  var a = i * TAU / 12
  var rune = box(self, Vector3(0.055, 0.015, 0.55), Vector3(sin(a) * 4.3, 0.045, cos(a) * 4.3), trim)
  rune.rotation.y = a
 # Central compass, four pennants and a complete low arena enclosure.
 for side in [-1, 1]:
  var line = box(self, Vector3(0.028, 0.02, 14.0), Vector3(side * 10.5, 0.035, 0), material(Color("78b6b6") if side < 0 else Color("c78771"), 0.4, 0.5))
  line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 for i in range(32):
  var angle = i * TAU / 32
  var p = Vector3(sin(angle) * 17.2, 0, cos(angle) * 11.9)
  var section = box(self, Vector3(3.0, 1.0, 0.65), p + Vector3(0, 0.42, 0), stone)
  section.rotation.y = atan2(p.x / 17.2, p.z / 11.9)
  var cap = box(section, Vector3(3.1, 0.13, 0.84), Vector3(0, 0.55, 0), trim)
  cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  if i % 4 == 0:
   cylinder(self, 0.57, 4.8, p + Vector3(0, 2.2, 0), pale, 12)
   cylinder(self, 0.79, 0.32, p + Vector3(0, 4.7, 0), trim, 8)
   cylinder(self, 0.84, 0.4, p + Vector3(0, -0.02, 0), dark, 8)
  if i % 8 == 2:
   var post = p + Vector3(0, 0.3, 0)
   cylinder(self, 0.18, 3.5, post + Vector3(0, 1.7, 0), trim, 8)
   var cloth_mesh = PlaneMesh.new(); cloth_mesh.size = Vector2(1.65, 2.6); cloth_mesh.subdivide_width = 8; cloth_mesh.subdivide_depth = 16
   var fabric = ShaderMaterial.new(); var cloth_shader = Shader.new()
   cloth_shader.code = "shader_type spatial; render_mode cull_disabled; uniform vec4 color : source_color = vec4(0.1,0.3,0.4,1.0); void vertex(){float weight=(VERTEX.z+1.3)/2.6; VERTEX.y+=sin(TIME*1.8+VERTEX.x*2.7+VERTEX.z*2.0)*0.16*weight; VERTEX.x+=sin(TIME*1.4+VERTEX.z*2.1)*0.04*weight;} void fragment(){float stripe=1.0-step(0.045,abs(UV.x-0.5)); ALBEDO=mix(color.rgb,vec3(0.66,0.48,0.25),stripe); ROUGHNESS=0.95;}"
   fabric.shader = cloth_shader; fabric.set_shader_parameter("color", Color("276c77") if i < 16 else Color("a85741"))
   var cloth = mesh(self, cloth_mesh, fabric, post + Vector3(0, 2.1, 0)); cloth.rotation = Vector3(PI / 2, angle, 0)
  if i % 4 == 1:
   cylinder(self, 0.32, 1.7, p + Vector3(0, 1, 0), dark, 10)
   var bowl = cylinder(self, 0.64, 0.24, p + Vector3(0, 1.85, 0), trim, 12)
   var flame_shape = SphereMesh.new(); flame_shape.radius = 0.19; flame_shape.height = 0.62
   var flame = mesh(self, flame_shape, material(Color("e48739"), 0, 0.6, true), p + Vector3(0, 2.16, 0))
   flames.append(flame)
   flame.add_to_group("arena_flames", true)
   var light = OmniLight3D.new(); light.position = bowl.position + Vector3(0, 0.7, 0); light.light_color = Color("ffc07c"); light.light_energy = 2.0; light.omni_range = 6.0; add_child(light)
 # Grandstand steps rise beyond the combat area; they never hide fighters.
 for tier in range(3):
  for side in [-1, 1]:
   box(self, Vector3(26.0, 0.55 + tier * 0.35, 1.1), Vector3(0, tier * 0.55, side * (13.2 + tier * 1.1)), dark if tier % 2 else stone)
   box(self, Vector3(0.9, 0.55 + tier * 0.35, 14.0), Vector3(side * (19.0 + tier), tier * 0.55, 0), stone)
 # Strong doorway silhouette behind the far stand.
 for x in [-4.6, 4.6]: box(self, Vector3(1.2, 7.4, 2.0), Vector3(x, 3.2, -16.4), stone)
 for i in range(15):
  var a = i * PI / 14
  var block = box(self, Vector3(1.06, 1.1, 2.1), Vector3(cos(a) * 4.6, 4.3 + sin(a) * 3.5, -16.4), pale)
  block.rotation.z = a - PI * 0.5
 for x in range(-4, 5): box(self, Vector3(0.09, 6.2, 0.15), Vector3(x, 2.9, -16.1), trim)
 var title = Label3D.new(); title.text = "M A N I T O R I A"; title.font_size = 60; title.pixel_size = 0.011; title.position = Vector3(0, 7.1, -15.2); title.modulate = Color("ead5a9"); title.outline_size = 3; add_child(title)
 # Distant spectators are instanced silhouettes, separate from combat simulation.
 var crowd_mesh = CapsuleMesh.new(); crowd_mesh.radius = 0.13; crowd_mesh.height = 0.6
 var crowd = MultiMesh.new(); crowd.transform_format = MultiMesh.TRANSFORM_3D; crowd.use_colors = true; crowd.mesh = crowd_mesh; crowd.instance_count = 192
 var crowd_mat = material(Color("73817c"), 0, 0.95); crowd_mat.vertex_color_use_as_albedo = true
 for i in range(192):
  var side = -1 if i < 96 else 1; var n = i % 96; var tier = n / 32
  var pos = Vector3((n % 32 - 15.5) * 0.74, tier * 0.73 + 0.60, side * (13.2 + tier * 1.1))
  crowd.set_instance_transform(i, Transform3D(Basis(), pos))
  crowd.set_instance_color(i, Color.from_hsv(rng.randf(), 0.25, rng.randf_range(0.30, 0.70)))
 var spectators = MultiMeshInstance3D.new(); spectators.multimesh = crowd; spectators.material_override = crowd_mat; add_child(spectators)

func update_camera(dt: float) -> void:
 camera_yaw = lerp_angle(camera_yaw, target_yaw, 1.0 - exp(-dt * 8.0))
 camera_distance = lerpf(camera_distance, target_distance, 1.0 - exp(-dt * 8.0))
 var target = Vector3(0, 0.9, 0)
 camera_pitch = lerpf(camera_pitch, target_pitch, 1.0 - exp(-dt * 8.0))
 var pitch = camera_pitch
 camera.position = target + Vector3(sin(camera_yaw) * cos(pitch), sin(pitch), cos(camera_yaw) * cos(pitch)) * camera_distance
 camera.look_at(target)
 if shake > 0.0:
  # Trauma-style shake: squared falloff so small knocks stay subtle and big ones really jolt.
  shake = maxf(0.0, shake - dt * 2.4); shake_seed += dt * 38.0
  var k = shake * shake
  camera.position += camera.basis.x * sin(shake_seed * 1.7) * 0.55 * k + camera.basis.y * sin(shake_seed * 2.3 + 1.1) * 0.4 * k
  camera.rotation.z += sin(shake_seed * 1.3) * 0.012 * k

func punch(amount: float) -> void:
 shake = clampf(maxf(shake, amount), 0.0, 1.0)

func flash(uid: int, col: Color, amount: float = 1.0) -> void:
 if not models.has(uid): return
 models[uid].flash.set_shader_parameter("tint", col)
 models[uid].flash_amt = maxf(models[uid].flash_amt, amount)

func orbit(amount: float) -> void:
 target_yaw += amount

func zoom(amount: float) -> void:
 target_distance = clampf(target_distance + amount, 9.0, 62.0)

func clear_fighters() -> void:
 physical_casts.clear()
 for child in fighters.get_children(): child.queue_free()
 for child in effects.get_children():
  if child!=card_particles:child.queue_free()
 if card_particles:card_particles.clear()
 for id in missiles:
  if is_instance_valid(missiles[id].node): missiles[id].node.queue_free()
 if vfx: vfx.clear()
 if clarity: clarity.clear()
 trail_clock.clear()
 for tween in effect_tweens: tween.kill()
 effect_tweens.clear(); missiles.clear(); zone_visuals.clear(); telegraphs.clear(); combat_numbers.clear()
 models.clear()

func spawn(u: Dictionary) -> void:
 if models.has(u.uid): return
 var holder = Node3D.new(); holder.name = "Hero" + str(u.uid); fighters.add_child(holder)
 var path = "res://assets/beasts/" + u.hero.sp + ".glb"
 if not resources.has(path): resources[path] = load(path)
 var motion = Node3D.new(); motion.name = "CombatMotion"; holder.add_child(motion)
 var model = resources[path].instantiate(); motion.add_child(model)
 model.scale = Vector3.ONE * (0.48 if u.summon else MODEL_SCALE)
 if not u.summon and "giant" in Forge.carried(u.hero): model.scale *= 1.25   # Giant's Draught
 var players = model.find_children("*", "AnimationPlayer", true, false)
 var player: AnimationPlayer = players[0] if not players.is_empty() else null
 if player:
  for anim in ["idle", "walk"]:
   if player.has_animation(anim): player.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
  if player.has_animation("idle"):
   # Desynchronise idles so a squad of the same creature doesn't breathe in lockstep.
   player.play("idle"); player.seek(randf() * player.get_animation("idle").length, true)
 var team_color = Color("70d6dd") if u.team == 0 else Color("eb987b")
 var circle = Node3D.new(); holder.add_child(circle) # Legacy selection anchor; team identity is in the health bar.
 var aura = Node3D.new(); holder.add_child(aura); aura.name = "EvolutionAura"
 var evolution = Evolutions.look(str(u.hero.get("evolution", "")))   # species evolutions map onto three aura styles
 if not str(u.hero.get("evolution", "")).is_empty() and not u.summon:
  var tint = HeroData.evolution_color(u.hero)
  if Evolutions.has(str(u.hero.evolution)): model.scale *= 1.06   # an evolved champion stands a little taller
  if HeroData.is_awakened(u.hero) and evolution != "ascended":
   # Awakened on top of an evolution: the crest of shards still crowns it.
   for i in range(5):
    var crest=PrismMesh.new();crest.size=Vector3(0.08,0.28+0.07*(2-abs(i-2)),0.1)
    mesh(aura,crest,material(Color("ffd36e"),0.4,0.2,true),Vector3((i-2)*0.14,2.25+0.08*(2-abs(i-2)),0))
  if evolution == "ascended":
   model.scale*=1.13
   for i in range(5):
    var shard=PrismMesh.new();shard.size=Vector3(0.08,0.28+0.07*(2-abs(i-2)),0.1)
    mesh(aura,shard,material(tint,0.4,0.2,true),Vector3((i-2)*0.14,2.25+0.08*(2-abs(i-2)),0))
  elif evolution == "guardian":
   for i in range(4):
    var a = i * TAU / 4
    box(aura,Vector3(0.09,0.3,0.09),Vector3(cos(a)*0.9,1.7,sin(a)*0.9),material(tint,0.2,0.4,true))
  else:
   for i in range(3):
    var angle = i * TAU / 3
    var shape = SphereMesh.new(); shape.radius = 0.075; shape.height = 0.6 if evolution == "ravager" else 0.15
    mesh(aura, shape, material(tint, 0, 0.3, true), Vector3(cos(angle)*0.88, 0.5 if evolution == "ravager" else 1.6, sin(angle)*0.88))
 var bars = Node3D.new(); holder.add_child(bars); bars.position.y = ((3.05 if u.hero.sp == "kirin" else 2.72) if not u.summon else 1.2) * BAR_LIFT
 var back_shape = QuadMesh.new(); back_shape.size = Vector2(1.75, 0.10)
 var back_mat = material(Color("14242f")); back_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; back_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
 mesh(bars, back_shape, back_mat)
 var health_mat = material(team_color); health_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; health_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
 health_mat.billboard_keep_scale = true
 var fill_shape = QuadMesh.new(); fill_shape.size = Vector2(1.75, 0.10)
 var bar = mesh(bars, fill_shape, health_mat, Vector3(0, 0.01, 0.015))
 var hp_label = Label3D.new(); hp_label.font_size = 27; hp_label.pixel_size = 0.008; hp_label.outline_size = 6; hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; hp_label.position.y = -0.17; bars.add_child(hp_label)
 var cast_shape = QuadMesh.new(); cast_shape.size = Vector2(1.75, 0.045)
 var cast_mat = health_mat.duplicate(); cast_mat.albedo_color = Color("f5d190")
 var cast_bar = mesh(bars, cast_shape, cast_mat, Vector3(0, -0.32, 0.02)); cast_bar.visible = false
 var shield_shape = QuadMesh.new(); shield_shape.size = Vector2(1.75,0.035)
 var shield_mat = health_mat.duplicate(); shield_mat.albedo_color = Color("a8d9ef")
 var shield_bar = mesh(bars,shield_shape,shield_mat,Vector3(0,0.075,0.02)); shield_bar.visible = false
 var bubble_shape = SphereMesh.new(); bubble_shape.radius = 1.25; bubble_shape.height = 2.9
 var bubble_mat = material(Color(0.35, 0.82, 0.95, 0.16), 0.2, 0.3, true); bubble_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 var bubble = mesh(holder, bubble_shape, bubble_mat, Vector3(0, 1.1, 0)); bubble.visible = false

 var name_label = Label3D.new(); name_label.text = u.hero.name; name_label.position.y = 0.22; name_label.font_size = 29; name_label.pixel_size = 0.010; name_label.modulate = team_color.lightened(0.4); name_label.outline_size = 8; name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; bars.add_child(name_label)
 if u.summon: bars.visible = false
 # Every mesh shares one overlay so the whole body flashes when struck or casting.
 var flash_mat = ShaderMaterial.new(); flash_mat.shader = HITFLASH
 for mi in model.find_children("*", "MeshInstance3D", true, false): mi.material_overlay = flash_mat
 models[u.uid] = {"root": holder, "motion":motion, "stride":0.0, "recoil":Vector3.ZERO, "aura": aura, "model": model, "player": player, "bar": bar, "bars": bars, "ring": circle, "state": "idle", "lock": 0.0, "dead": false, "hp_label": hp_label, "cast_bar": cast_bar, "bubble": bubble, "shield_bar":shield_bar, "stagger": 0.0, "death_elapsed": 0.0, "arc": {}, "last_target": world_point(u.pos), "ground_speed": 0.0, "walk_hold": 0.0, "turn_rate": 0.0, "name_label": name_label, "tempo": randf_range(0.92, 1.08), "flash": flash_mat, "flash_amt": 0.0, "born": 0.0 if (u.summon or (sim_ref != null and sim_ref.time > 0.5)) else 1.0}
 holder.position = world_point(u.pos)
 model.rotation.y = u.heading

func sync(sim: BattleSim, dt: float, speed: float = 1.0) -> void:
 current_speed = speed
 if card_particles:card_particles.sync(sim,dt*speed)
 sim_ref = sim
 if vfx: vfx.advance(dt * speed)
 for data in models.values():
  data.aura.rotation.y = 0
  data.aura.visible = not data.dead
 for tween in effect_tweens.duplicate():
  if not tween.is_valid(): effect_tweens.erase(tween)
  elif speed > 0 and not tween.custom_step(dt * speed): effect_tweens.erase(tween)
 for id in physical_casts.keys():
  physical_casts[id].remaining-=dt*speed
  if physical_casts[id].remaining<=0:physical_casts.erase(id)
 sync_projectiles(sim)
 sync_zones(sim)
 sync_telegraphs(sim)
 sync_numbers(dt * speed)
 for u in sim.units:
  if not models.has(u.uid): spawn(u)
  var visual = models[u.uid]
  follow(u, visual, dt * speed)
  # Billboard vertex transforms discard nonuniform scale by default. Change
  # the actual unique mesh width so HP always visibly drains in every renderer.
  var health_ratio = clampf(u.hp / u.max_hp, 0.0, 1.0)
  visual.bar.mesh.size.x = maxf(0.005, 1.75 * health_ratio)
  visual.bar.material_override.albedo_color = Color("ee806c") if health_ratio < 0.3 else Color("e7c36f") if health_ratio < 0.6 else Color("70d6dd") if u.team == 0 else Color("eb987b")
  visual.hp_label.text = "%d / %d%s" % [ceili(u.hp), ceili(u.max_hp), " +%d" % ceili(u.shield) if u.shield > 0 else ""]
  visual.bubble.visible = false
  visual.shield_bar.visible = u.alive and u.shield > 0
  visual.shield_bar.mesh.size.x = maxf(0.01,1.75*minf(1,u.shield/(u.max_hp*0.55)))
  visual.cast_bar.visible = u.alive and (u.windup > 0 or u.has("pending_cast"))
  if visual.cast_bar.visible:
   var remaining = u.pending_cast.delay / u.pending_cast.total if u.has("pending_cast") else u.windup / maxf(0.01, u.windup_total)
   visual.cast_bar.mesh.size.x = maxf(0.01, 1.75 * (1.0 - remaining))
  visual.stagger = maxf(0, visual.stagger - dt * speed)
  visual.flash_amt = maxf(0.0, visual.flash_amt - dt * 6.0)
  visual.flash.set_shader_parameter("flash", visual.flash_amt)
  visual.name_label.visible = not (clarity and clarity.tactical)   # team rings identify sides in Tactical view
  animate_weight(u, visual, dt * speed)
  visual.lock = maxf(0, visual.lock - dt * speed)
  if visual.player: visual.player.speed_scale = speed * visual.tempo
  if visual.born < 1.0:
   # Summons and late arrivals grow in with a small overshoot instead of popping into existence.
   visual.born = minf(1.0, visual.born + dt * speed / 0.35)
   var b = visual.born
   visual.motion.scale = Vector3.ONE * maxf(0.05, 1.0 + 2.70158 * pow(b - 1.0, 3) + 1.70158 * pow(b - 1.0, 2))   # ease-out-back
  if not u.alive and not visual.dead:
   visual.dead = true; play(u.uid, "death", 999)
   visual.bars.visible = false; visual.ring.visible = false
  elif u.alive:
   if u.has("pending_cast"):
    pose_phase(visual, "attack" if not AttackVisuals.style(u.hero.sp,u.pending_cast.effect).is_empty() else "cast", (1.0 - u.pending_cast.delay / u.pending_cast.total) * 0.46)
   elif u.windup > 0:
    pose_phase(visual, "attack", (1.0 - u.windup / maxf(0.01, u.windup_total)) * 0.46)
   elif u.recovery > 0:
    var clip=u.get("recovery_clip","attack")
    if clip=="cast":
     var skill_effect=HeroData.species[u.hero.sp].ab if u.credit=="signature" else HeroData.learned_ability(u.hero.sp,int(u.credit.trim_prefix("ability:"))).effect if u.credit.begins_with("ability:") else "basic"
     if not AttackVisuals.style(u.hero.sp,skill_effect).is_empty():clip="attack"
    pose_phase(visual,clip,0.46 + (1.0 - u.recovery / 0.22) * 0.53)
   elif visual.lock <= 0:
    # Walk while the body is really travelling (incl. shoves), with a short hold so
    # stop-start steering doesn't chatter between idle and walk.
    var travelling = (u.moving or visual.ground_speed > 1.0) and visual.arc.is_empty()
    if travelling: visual.walk_hold = 0.16
    play(u.uid, "walk" if visual.walk_hold > 0 else "idle")
    if visual.player and visual.state == "walk":
     visual.player.speed_scale = speed * GaitRates.walk_rate(u.hero.sp, maxf(visual.ground_speed, 0.6))

  if not u.alive:
   visual.death_elapsed += dt * speed
   visual.model.position.y = -maxf(0, visual.death_elapsed - 1.0) * 0.22
   visual.model.visible = visual.death_elapsed < 3.5
 if clarity: clarity.sync(sim, dt * speed, models)

func pose_phase(visual: Dictionary, clip: String, fraction: float) -> void:
 if not visual.player or not visual.player.has_animation(clip): return
 if visual.state != clip: visual.player.play(clip, 0.07); visual.state = clip
 visual.player.speed_scale = 0.0
 visual.player.seek(visual.player.get_animation(clip).length * clampf(fraction, 0, 0.99), true)

func effect_tween() -> Tween:
 var tween = create_tween(); tween.pause(); effect_tweens.append(tween); return tween

func play(id: int, clip: String, lock: float = 0.0) -> void:
 if not models.has(id): return
 var v = models[id]
 if v.player and v.player.has_animation(clip) and (v.state != clip or lock > 0):
  v.player.play(clip, 0.16); v.state = clip
 v.lock = maxf(v.lock, lock)

func _process(dt: float) -> void:
 elapsed += dt
 if camera: update_camera(dt)
 for node in perimeter:
  # Lower camera angles cut away near-side architecture to keep the heroes visible.
  var facing = Vector2(node.position.x, node.position.z).normalized().dot(Vector2(camera.position.x, camera.position.z).normalized())
  node.visible = camera_pitch > 0.69 or facing < 0.30
 for i in range(flames.size()):
  flames[i].scale = Vector3(1.0 + sin(elapsed * 7 + i) * 0.1, 1.0 + sin(elapsed * 10 + i) * 0.16, 1)

func color_for(effect: String) -> Color:
 if effect in ["fire", "flamewave", "magma", "rebirth", "threefold"]: return Color("ffac63")
 if effect in ["poison", "venom", "toxic", "acid", "brood", "roots", "rootbloom"]: return Color("a4df80")
 if effect in ["renew", "ward", "radiance", "tidal", "rally", "tailwind"]: return Color("8ce4d9")
 if effect in ["chain", "stormcall", "storm", "frost", "frostroar", "gaze"]: return Color("85c4ff")
 if effect in ["vanish", "foxfire", "riddle", "fear", "wisps", "silence"]: return Color("c09df0")
 return Color("eed199")

func ripple(pos: Vector2, color: Color, _radius: float = 2.5, _duration: float = 0.55) -> void:
 sparks(pos,color,3)

func beam(a: Vector3, b: Vector3, color: Color, thickness: float = 0.06, duration: float = 0.25) -> void:
 var shape = CylinderMesh.new(); shape.top_radius = thickness; shape.bottom_radius = thickness; shape.height = a.distance_to(b); shape.radial_segments = 6
 var mat = material(color, 0.2, 0.4, true); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 var node = mesh(effects, shape, mat, (a + b) * 0.5)
 var direction = (b - a).normalized()
 node.quaternion = Quaternion(Vector3.UP, direction)
 var tween = effect_tween(); tween.tween_property(node, "scale", Vector3(0.01, 1, 0.01), duration); tween.tween_callback(node.queue_free)

func floating_text(pos: Vector2, text_value: String, color: Color, size: int = 45) -> void:
 var label = Label3D.new(); label.text = text_value; label.font_size = size; label.pixel_size = 0.014; label.modulate = color; label.outline_size = 8; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 effects.add_child(label); label.position = Vector3(pos.x, 3.2, pos.y)
 var tween = effect_tween().set_parallel(true)
 tween.tween_property(label, "position:y", 4.0, 0.8)
 tween.tween_property(label, "modulate:a", 0.0, 0.8)
 tween.tween_property(label, "outline_modulate:a", 0.0, 0.8)
 tween.chain().tween_callback(label.queue_free)

func handle_event(e: Dictionary) -> void:
 var effect = e.get("effect", "basic"); var color = color_for(effect)
 if e.has("species"): color = CardParticles.profile(e.species,e.get("credit","basic"),effect).color
 if card_particles:card_particles.event(e)
 match e.type:
  "item_proc":
   var item=ItemEffects.definition(str(e.credit).trim_prefix("item:"))
   var tint=RarityStyle.color(item.get("rarity","Common"))
   sparks(e.target,tint,5)
   if e.pos.distance_to(e.target)>0.1:beam(Vector3(e.pos.x,1.2,e.pos.y),Vector3(e.target.x,1.2,e.target.y),tint,0.045,0.25)
  "attack": pass
  "release":
   if not e.ranged: AttackVisuals.strike(self,e.pos,e.target,e.get("species",""))
  "interrupt":
   floating_text(e.pos, "INTERRUPTED", Color("ef9b83"), 30)
   if models.has(e.uid): models[e.uid].lock = 0
  "death":
   if models.has(e.uid):
    models[e.uid].bubble.visible = false; models[e.uid].cast_bar.visible = false
    flash(e.uid, Color.WHITE, 1.4)
    if vfx: AbilityFX.knockout(vfx, fx_context(e, color), world_point(e.pos, 0.0))
    punch(0.55); hitstop.emit(0.09)
  "telegraph":
   # One callout per skill: it appears as the windup starts and pops when the skill lands.
   if clarity and sim_ref: clarity.callout(sim_ref, e, models, SkillCombat.windup(effect))
  "cast":
   # The overhead windup identifies the skill; avoid a duplicate cast banner.
   if not AttackVisuals.style(e.get("species",""),effect).is_empty():physical_casts[e.uid]={"remaining":.3,"targets":{}}
   fx_cast(e, color)
   if e.get("credit", "basic") != "basic" and vfx:
    var cc = fx_context(e, color)
    AbilityFX.cast_flash(vfx, cc, world_point(e.pos, 0.0))
    flash(e.uid, cc.hot, 0.9)
   if clarity and sim_ref: clarity.release(sim_ref, e, models)
   if e.get("rarity", "") == "Legendary" and e.get("credit", "basic") != "basic" and vfx:
    # Legendary skills get a moment: gilded flourish, and the game slows briefly to let it land.
    AbilityFX.legendary_flourish(vfx, fx_context(e, color), world_point(e.pos, 0.0), world_point(e.get("target", e.pos), 0.0))
    legendary_moment.emit(0.9)
   # Rarity enriches the attack itself instead of adding a universal radial explosion.
  "hit":
   physical_contact(e)
   fx_hit(e, color)
   var skill = e.get("credit", "basic") != "basic"
   var amount = float(e.get("amount", 0.0))
   if amount >= 3: flash(e.uid, fx_context(e, color).hot if skill else Color(1, 0.95, 0.9), clampf(0.35 + amount / 60.0, 0.4, 1.2))
   if models.has(e.uid) and amount >= 6:
    models[e.uid].stagger = 0.20
    if models.has(e.get("source",-1)):
     var away = models[e.uid].root.position-models[e.source].root.position
     models[e.uid].recoil = away.normalized()*minf(0.45,amount*0.004)
   if skill and amount >= 30: punch(clampf(amount / 140.0, 0.2, 0.6))
   if skill and amount >= 55: hitstop.emit(0.06)
   number_event(e)
  "heal":
   number_event(e)
   fx_heal(e, color)
  "blocked":
   physical_contact(e);number_event(e)
  "impact":
   pass # Card particles already provide directional impact debris.
  "bolt":
   fx_bolt(e, color)
  "projectile": pass # Visuals track live simulation projectiles, including pause and target movement.

func physical_contact(e: Dictionary) -> void:
 var source_id=e.get("source",-1)
 if e.get("credit","basic")=="basic" or not physical_casts.has(source_id) or not models.has(source_id):return
 var cast=physical_casts[source_id]
 if cast.targets.has(e.uid):return # A blocked+health hit is one contact; bleed ticks are not new bites.
 if AttackVisuals.style(e.get("species",""),e.get("effect","")).is_empty():return
 cast.targets[e.uid]=true
 var source=models[source_id].root.position
 AttackVisuals.strike(self,Vector2(source.x,source.z)/FLOOR_SCALE,e.pos,e.species,e.effect,e.get("rarity","Uncommon"))

func charge(pos: Vector2, color: Color) -> void:
 for i in range(5):
  var angle = i * TAU / 5
  var shape = SphereMesh.new(); shape.radius = 0.08; shape.height = 0.16
  var node = mesh(effects, shape, material(color, 0, 0.3, true), Vector3(pos.x + cos(angle) * 0.9, 0.25, pos.y + sin(angle) * 0.9))
  var tween = effect_tween()
  tween.tween_property(node, "position", Vector3(pos.x, 1.4, pos.y), 0.52)
  tween.tween_callback(node.queue_free)

func sparks(pos: Vector2, color: Color, count: int = 8) -> void:
 for i in range(count):
  var angle = i * TAU / count
  var shape = SphereMesh.new(); shape.radius = 0.055; shape.height = 0.16
  var node = mesh(effects, shape, material(color, 0, 0.3, true), Vector3(pos.x, 0.8, pos.y))
  var tween = effect_tween().set_parallel(true)
  tween.tween_property(node, "position", node.position + Vector3(cos(angle) * 0.75, 0.15 + (i % 3) * 0.2, sin(angle) * 0.75), 0.32)
  tween.tween_property(node, "scale", Vector3.ONE * 0.03, 0.32)
  tween.chain().tween_callback(node.queue_free)

func slash(pos: Vector2, target: Vector2, color: Color) -> void:
 var direction = (target - pos).normalized()
 var center = Vector3(pos.x + direction.x * 0.75, 1.0, pos.y + direction.y * 0.75)
 var angle = atan2(direction.x, direction.y)
 var previous = center + Vector3(sin(angle - 0.9), 0.05, cos(angle - 0.9)) * 0.65
 for i in range(1, 8):
  var a = angle - 0.9 + i * 1.8 / 7
  var point = center + Vector3(sin(a), sin(i * 0.4) * 0.25, cos(a)) * 0.65
  beam(previous, point, color, 0.025, 0.16); previous = point

func spell(e: Dictionary, color: Color) -> void:
 var effect = e.effect
 if not AttackVisuals.style(e.get("species",""),effect).is_empty(): return
 if effect in ["meteor", "boulder", "barrage", "wisps"]: return
 if effect in ["ward", "tidal", "radiance", "renew", "rootbloom", "regrowth", "rally", "prideroar", "tailwind", "shellup", "bulwark"]:
  for side in [-1,1]:
   var node = box(effects,Vector3(0.055,0.5,0.055),Vector3(e.pos.x+side*0.45,0.6,e.pos.y),material(color,0,0.4,true))
   var tween = effect_tween().set_parallel(true)
   tween.tween_property(node,"position:y",1.8,0.4)
   tween.tween_property(node,"scale",Vector3.ONE*0.01,0.4)
   tween.chain().tween_callback(node.queue_free)
 elif effect in ["quake", "smash", "fissure", "roots", "frost"]:
  for i in range(8):
   var offset=Vector2((i%3-1)*.8,(i/3-1)*.7)
   if effect=="fissure":offset=(e.target-e.pos).normalized()*(i*.6-2.1)+Vector2(0,.15 if i%2 else -.15)
   var node = box(effects, Vector3(0.16, 1.1, 0.16), Vector3(e.target.x + offset.x, -0.6, e.target.y + offset.y), material(color, 0.25, 0.5, true))
   var tween = effect_tween(); tween.tween_property(node, "position:y", 0.5, 0.15); tween.tween_property(node, "scale", Vector3.ONE * 0.01, 0.55); tween.tween_callback(node.queue_free)
 elif effect in ["fear", "silence"]:
  var root = Node3D.new(); effects.add_child(root); root.position = Vector3(e.target.x,0.3,e.target.y)
  for i in range(3):
   var arc = box(root,Vector3(1.1-i*0.15,0.025,0.05),Vector3(0,i*0.28,0),material(color,0,0.4,true))
   arc.rotation.x = 0.15+i*0.14
  var tween = effect_tween().set_parallel(true)
  tween.tween_property(root,"rotation:y",TAU,0.65)
  tween.tween_property(root,"scale",Vector3(1.8,1.5,1.8),0.65)
  tween.chain().tween_property(root,"scale",Vector3.ONE*0.01,0.18)
  tween.chain().tween_callback(root.queue_free)
 elif effect in ["fire", "toxic", "flamewave", "acid","gust"]:
  pass # Directed breath particles travel from the mouth toward the target.
 elif effect in ["drain", "gaze", "riddle", "threefold"]:
  beam(Vector3(e.pos.x, 1.4, e.pos.y), Vector3(e.target.x, 1.1, e.target.y), color, 0.11, 0.35)
 elif effect in ["gore", "venom", "skystrike", "stonedive", "maul", "antlerrush", "ambush", "vanish"]:
  pass # Physical attacks are rendered at actual hit recipients.
 else:
  pass # Skill-specific particles replace the old generic radial fallback.

func sync_projectiles(sim: BattleSim) -> void:
 var live = {}
 for p in sim.projectiles:
  live[p.id] = true
  var source = sim.find_unit(p.source)
  if not missiles.has(p.id):
   var color = color_for(p.effect)
   if not source.is_empty(): color = CardParticles.profile(source.hero.sp,p.get("credit","basic"),p.effect).color
   var rarity=RarityStyle.for_skill(source.hero,p.get("credit","basic")) if not source.is_empty() else "Uncommon"
   var c = AbilityFX.ctx(source.hero.sp if not source.is_empty() else "", color, rarity)
   var root = AbilityFX.projectile(vfx, c, p.effect); vfx.add_child(root)
   if rarity in ["Rare","Legendary"]: root.scale=Vector3.ONE*(1.4 if rarity=="Legendary" else 1.18)
   missiles[p.id] = {"node": root, "ctx": c, "last": Vector3.ZERO}
  var target = sim.find_unit(p.target)
  if not target.is_empty(): p.last_pos = target.pos
  var arc = 4.0 if p.effect in ["meteor", "boulder"] else 0.35
  var start = world_point(p.origin, 1.25); var end = world_point(p.last_pos, 1.15)
  var t = clampf(1.0 - p.remaining / p.duration, 0, 1)
  var entry = missiles[p.id]; var node: Node3D = entry.node
  node.position = start.lerp(end, t) + Vector3.UP * sin(t * PI) * arc
  var tangent = (end - start + Vector3.UP * cos(t * PI) * PI * arc).normalized()
  if node.has_meta("spin"): node.get_meta("spin").rotation = Vector3(t * 9.0, t * 5.0, 0)
  # Emit trail puffs on the simulation clock (pause-safe).
  var key = str(p.id)
  trail_clock[key] = trail_clock.get(key, 0.0) + (sim.time - trail_clock.get(key + "t", sim.time))
  trail_clock[key + "t"] = sim.time
  if trail_clock[key] >= 0.05:
   trail_clock[key] = 0.0
   AbilityFX.trail(vfx, entry.ctx, p.effect, node.position, tangent)
 for id in missiles.keys():
  if not live.has(id):
   missiles[id].node.queue_free(); missiles.erase(id); trail_clock.erase(str(id)); trail_clock.erase(str(id) + "t")

func sync_zones(sim: BattleSim) -> void:
 var live = {}
 for zone in sim.zones:
  var key = "%s:%s:%s" % [zone.source, zone.pos, zone.effect]; live[key] = true
  var source = sim.find_unit(zone.source)
  if not zone_visuals.has(key):
   var color = color_for(zone.effect)
   if not source.is_empty(): color = CardParticles.profile(source.hero.sp, zone.get("credit","signature"), zone.effect).color
   zone_visuals[key] = {"next": 0.0, "ctx": AbilityFX.ctx(source.hero.sp if not source.is_empty() else "", color, "Uncommon")}
  var z = zone_visuals[key]
  if sim.time >= z.next:
   # Persistent ground effects renew themselves on the battle clock.
   z.next = sim.time + 0.7
   AbilityFX.zone_pulse(vfx, z.ctx, zone.effect, world_point(zone.pos, 0.0), zone.get("radius", 2.5) * FLOOR_SCALE * 0.8)
 for key in zone_visuals.keys():
  if not live.has(key): zone_visuals.erase(key)

func ground_position(screen: Vector2) -> Vector3:
 var origin = camera.project_ray_origin(screen)
 var direction = camera.project_ray_normal(screen)
 var point = Plane(Vector3.UP, 0).intersects_ray(origin, direction)
 return Vector3(point.x / FLOOR_SCALE, point.y, point.z / FLOOR_SCALE) if point != null else Vector3.ZERO

func polish_stage(stage: Node3D) -> void:
 for node in stage.get_children():
  if node is WorldEnvironment:
   var env = node.environment
   env.ambient_light_energy = 0.58
   env.ambient_light_color = Color("b2cde5")
   env.ssao_intensity = 1.1
   env.fog_density = 0.0013
   # Let skill effects bloom (Forward+ only; the compatibility renderer has no glow).
   env.glow_intensity = 0.95; env.glow_bloom = 0.06; env.glow_hdr_threshold = 0.95
  elif node is DirectionalLight3D:
   if node.shadow_enabled: node.light_energy = 1.65; node.light_color = Color("ffe4c0")
# Windups are state-driven, so pausing, speed changes and interrupts cannot
# leave a misleading warning behind or release a visual before the skill.
func sync_telegraphs(sim: BattleSim) -> void:
 var live = {}
 for u in sim.units:
  if not u.alive or not u.has("pending_cast"): continue
  live[u.uid] = true
  if telegraphs.has(u.uid): continue
  var pending = u.pending_cast
  var color = CardParticles.profile(u.hero.sp,pending.get("credit","signature"),pending.effect).color
  telegraphs[u.uid] = true
  if vfx and AttackVisuals.style(u.hero.sp,pending.effect).is_empty():
   AbilityFX.windup(vfx, AbilityFX.ctx(u.hero.sp, color, RarityStyle.for_skill(u.hero, pending.get("credit","signature"))), world_point(u.pos, 0.0), pending.total)
 for id in telegraphs.keys():
  if not live.has(id): telegraphs.erase(id)

# Coalesce rapid ticks for a short window without discarding small hits.
# The displayed amount is effective HP damage/healing, not nominal power.
func number_event(e: Dictionary) -> void:
 var key = "%s:%s" % [e.uid,e.type]
 # Small damage-over-time ticks pool for longer so the fight isn't buried in "0.7"s.
 var window = 0.48 if e.amount >= 6.0 else 0.9
 if combat_numbers.has(key) and combat_numbers[key].age < window:
  combat_numbers[key].amount += e.amount
  combat_numbers[key].pop = 0.0   # re-pop as the number grows
  update_number(combat_numbers[key])
  return
 if e.type == "blocked" and (e.amount < 10.0 or (clarity and clarity.tactical)): return   # minor absorbs read as noise
 if clarity and clarity.tactical and e.type == "hit" and e.amount < 12.0: return
 var label = Label3D.new(); effects.add_child(label)
 var skill_hit = e.type == "hit" and e.get("credit", "basic") != "basic"
 label.font_size = (52 if skill_hit else 40) if e.type == "hit" else 32 if e.type == "heal" else 24; label.pixel_size = 0.014; label.no_depth_test = true; label.outline_size = 12; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 label.modulate = Color("ffe4c0") if e.type == "hit" else Color("7dffb0") if e.type == "heal" else Color("9edbff")
 if skill_hit:
  label.modulate = fx_context(e, color_for(e.get("effect", "basic"))).color.lightened(0.18)
  if e.amount >= 80.0: label.font_size = 64
 label.outline_modulate = Color(0.08, 0.02, 0.04) if skill_hit else Color(0, 0, 0)
 label.font = load("res://assets/fonts/uncialantiqua.ttf") if skill_hit else null
 var lane = (int(e.get("source",0)) % 3 - 1)*0.7
 label.position = Vector3(e.pos.x+lane,4.3+(0.65 if e.type == "heal" else -0.35 if e.type == "blocked" else 0.0),e.pos.y)
 var entry = {"node":label,"amount":e.amount,"type":e.type,"age":0.0,"base_y":label.position.y}
 # A previous burst can finish its flight while the next one accumulates.
 if combat_numbers.has(key): combat_numbers[key+":"+str(label.get_instance_id())] = combat_numbers[key]
 combat_numbers[key] = entry
 update_number(entry)

func update_number(entry: Dictionary) -> void:
 var amount = str(maxi(1, roundi(entry.amount)))
 entry.node.text = ("+" if entry.type == "heal" else "" ) + amount + (" blocked" if entry.type == "blocked" else "")

func sync_numbers(dt: float) -> void:
 var occupied: Array[Rect2] = []
 for key in combat_numbers.keys():
  var entry = combat_numbers[key]; entry.age += dt
  entry.node.position.y = entry.base_y+entry.age*1.1
  # Pop in big, settle, then drift up and fade.
  entry.pop = entry.get("pop", 0.0) + dt
  entry.node.scale = Vector3.ONE * (1.0 + 0.9 * exp(-entry.pop * 16.0))
  entry.node.modulate.a = clampf((0.95-entry.age)/0.4,0,1)
  entry.node.outline_modulate.a = entry.node.modulate.a
  if entry.age >= 0.95:
   entry.node.queue_free(); combat_numbers.erase(key); continue
  # Separate floating results in screen space when fighters converge.
  if camera and is_inside_tree():
   for attempt in range(12):
    var screen = camera.unproject_position(entry.node.global_position)
    var rect = Rect2(screen-Vector2(32,10),Vector2(64,20))
    var overlaps = false
    for previous in occupied:
     if previous.intersects(rect): overlaps = true; break
    if not overlaps: occupied.append(rect); break
    entry.node.position.y += 0.55

# Layer weight shifts over the authored skeletal clips, keeping the combat
# root, target positions and hit calculations untouched.
func animate_weight(u: Dictionary, visual: Dictionary, dt: float) -> void:
 if dt <= 0: return
 visual.recoil = visual.recoil.lerp(Vector3.ZERO,1-exp(-dt*12))
 if not u.alive:
  visual.motion.position = visual.motion.position.lerp(Vector3.ZERO,1-exp(-dt*10))
  visual.motion.rotation = visual.motion.rotation.lerp(Vector3.ZERO,1-exp(-dt*10))
  return
 var pace = u.get("velocity",Vector2.ZERO).length()/maxf(0.1,u.speed) if u.moving else 0.0
 var heavy = u.hero.sp in ["golem","cyclops","zaratan","treant","yeti","minotaur"]
 visual.stride += dt * (7.0 if heavy else 10.0) * pace
 var forward = Vector3(sin(u.heading),0,cos(u.heading))
 var shift = 0.0
 var lean = 0.0
 var lift = absf(sin(visual.stride)) * pace * (0.025 if heavy else 0.045)
 if u.windup > 0:
  var phase = 1-u.windup/maxf(0.01,u.windup_total)
  shift = -sin(phase*PI*0.5)*0.12
  lean = -0.045*phase
 elif u.recovery > 0 and u.get("recovery_clip","") == "attack":
  var phase = 1-u.recovery/0.22
  shift = sin((0.18+phase*0.82)*PI)*(0.28 if u.range <= 2 else 0.09)
  lean = sin(phase*PI)*0.07
 elif u.has("pending_cast"):
  var phase = 1-u.pending_cast.delay/u.pending_cast.total
  lift += sin(phase*PI)*0.045
  lean = -0.035*sin(phase*PI)
 else:
  lean = pace*(0.025 if heavy else 0.06)
 var target = forward*shift+visual.recoil+Vector3.UP*lift
 visual.motion.position = visual.motion.position.lerp(target,1-exp(-dt*24))
 visual.motion.rotation.x = lerpf(visual.motion.rotation.x,cos(u.heading)*lean,1-exp(-dt*12))
 visual.motion.rotation.z = lerpf(visual.motion.rotation.z,-sin(u.heading)*lean,1-exp(-dt*12))

func rarity_burst(pos: Vector2, rarity: String, rank: int = 1) -> void:
 if rarity not in ["Rare","Legendary"]: return
 var legendary=rarity=="Legendary"
 var tint=RarityStyle.color(rarity)
 var count=10 if legendary else 5
 for i in range(count):
  var angle=i*2.39996
  var shape=PrismMesh.new();shape.size=Vector3(0.045,0.3 if legendary else 0.18,0.045)
  var shard=mesh(effects,shape,material(tint,0.5,0.2,true),Vector3(pos.x,0.65,pos.y))
  shard.rotation=Vector3(i*0.4,angle,0.4)
  var reach=(0.7+float(i%3)*0.15)*(1.15 if rank>=2 else 1.0)
  var tween=effect_tween().set_parallel(true)
  tween.tween_property(shard,"position",shard.position+Vector3(cos(angle)*reach,1.2+float(i%3)*0.3,sin(angle)*reach),0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  tween.tween_property(shard,"rotation:y",angle+2.0,0.45)
  tween.tween_property(shard,"scale",Vector3.ONE*0.01,0.55)
  tween.chain().tween_callback(shard.queue_free)
 if legendary:
  var flash=OmniLight3D.new();effects.add_child(flash);flash.position=Vector3(pos.x,1.4,pos.y);flash.light_color=tint;flash.light_energy=2.0;flash.omni_range=4.0;flash.shadow_enabled=false
  var fade=effect_tween();fade.tween_property(flash,"light_energy",0.0,0.4);fade.tween_callback(flash.queue_free)
  for side in [-1,1]:
   beam(Vector3(pos.x+side*0.6,0.2,pos.y),Vector3(pos.x+side*0.2,2.8,pos.y),tint,0.045,0.35)

func set_region(region: Dictionary) -> void:
 var title=region.get("place","")
 if title==region_name:return
 region_name=title
 if is_instance_valid(world_props):world_props.queue_free()
 world_props=Node3D.new();add_child(world_props)
 if is_instance_valid(world_stage):
  if theme_materials.is_empty():
   for node in world_stage.find_children("*","GeometryInstance3D",true,false):
    if node.position.y<0.1 and node.material_override is StandardMaterial3D:
     theme_materials.append({"node":node,"original":node.material_override})
  for entry in theme_materials:
   entry.node.material_override=entry.original.duplicate()
   if not region.is_empty():entry.node.material_override.albedo_color=Color(region.floor)
  for node in world_stage.get_children():
   if node is DirectionalLight3D and node.shadow_enabled:node.light_color=Color(region.get("sky","ffe4c0"))
 if region.is_empty():return
 var tint=Color(region.color);var theme=region.theme
 for side in [-1,1]:
  for i in range(7):
   var point=Vector3((i-3)*4.4,0.05,side*12.8)
   if theme=="Forest":
    cylinder(world_props,0.18,2.4,point+Vector3.UP*1.2,material(Color("514537")),7)
    var leaf=SphereMesh.new();leaf.radius=1.1;leaf.height=2.3;leaf.radial_segments=8;leaf.rings=4
    mesh(world_props,leaf,material(tint.darkened(0.35)),point+Vector3.UP*2.7)
   elif theme in ["Glacial","Astral"]:
    for j in range(3):
     var crystal=PrismMesh.new();crystal.size=Vector3(0.5,1.8+j*0.5,0.5)
     var gem=mesh(world_props,crystal,material(tint,0.45,0.2,true),point+Vector3(j*0.5,1.1,0));gem.rotation.z=(j-1)*0.18
   elif theme=="Volcanic":
    var stone=PrismMesh.new();stone.size=Vector3(1.5,2.2,1.2)
    mesh(world_props,stone,material(Color("302c31"),0.2),point+Vector3.UP)
    box(world_props,Vector3(0.08,1.8,0.09),point+Vector3(0,0.9,-side*0.65),material(tint,0.2,0.3,true))
   elif theme=="Desert":
    box(world_props,Vector3(0.65,2.8,0.65),point+Vector3.UP*1.4,material(Color("b39b70"),0.25))
    var cap=PrismMesh.new();cap.size=Vector3(0.7,0.6,0.7);mesh(world_props,cap,material(tint,0.5),point+Vector3.UP*3.1)
   else:
    for j in range(3):
     var coral=box(world_props,Vector3(0.13,1.4,0.13),point+Vector3(j*0.3,0.65,0),material(tint,0.2,0.6));coral.rotation.z=(j-1)*0.3
 # Location is named in the HUD; keep oversized lettering off the battlefield.


# ---------------------------------------------------------------- ability VFX (shader library)
const BOLT_FAMILIES = ["storm", "stormcall", "chain", "beam", "fissure"]
const SUPPORT_FAMILIES = ["ward", "renew", "rally", "tidal", "radiance", "regrowth", "bulwark", "shellup", "tailwind", "prideroar", "rootbloom", "howl", "hunger"]

func fx_context(e: Dictionary, color: Color) -> Dictionary:
 return AbilityFX.ctx(e.get("species", ""), color, e.get("rarity", "Uncommon"))

func fx_cast(e: Dictionary, color: Color) -> void:
 var effect = e.get("effect", "basic")
 if not vfx or effect in BOLT_FAMILIES: return
 var c = fx_context(e, color)
 var from = world_point(e.pos, 0.0); var to = world_point(e.get("target", e.pos), 0.0)
 var targets = []
 if sim_ref:
  var caster = sim_ref.find_unit(e.uid)
  if not caster.is_empty():
   if effect in SUPPORT_FAMILIES:
    for u in sim_ref.units:
     if u.alive and u.team == caster.team and u.pos.distance_to(caster.pos) <= 5.5: targets.append(world_point(u.pos, 0.0))
   else:
    for u in sim_ref.units:
     if u.alive and u.team != caster.team and u.pos.distance_to(e.get("target", e.pos)) <= 2.6: targets.append(world_point(u.pos, 0.0))
 AbilityFX.play(vfx, effect, c, from, to, targets)

func fx_bolt(e: Dictionary, color: Color) -> void:
 if not vfx: return
 var effect = e.get("effect", "basic"); var c = fx_context(e, color)
 var from = world_point(e.pos, 0.0); var to = world_point(e.target, 0.0)
 match effect:
  "storm", "stormcall": AbilityFX.play(vfx, "storm", c, from, to, [to])
  "chain": AbilityFX.play(vfx, "chain", c, from, to, [to])
  "beam", "fissure": AbilityFX.play(vfx, effect, c, from, to, [])
  _: vfx.bolt(from + Vector3.UP * 1.4, to + Vector3.UP * 1.0, c.color, 0.16, 0.35, 1)

func fx_hit(e: Dictionary, color: Color) -> void:
 if not vfx or e.get("credit", "basic") == "basic" or e.get("amount", 0.0) < 4.0: return
 if not AttackVisuals.style(e.get("species", ""), e.get("effect", "")).is_empty(): return
 AbilityFX.hit(vfx, fx_context(e, color), world_point(e.pos, 0.0), e.get("amount", 0.0) > 40.0)

func fx_heal(e: Dictionary, color: Color) -> void:
 if not vfx or e.get("amount", 0.0) < 5.0: return
 var c = fx_context(e, color); var at = world_point(e.pos, 0.0)
 vfx.spray(at + Vector3.UP * 0.4, 8, "star" if c.el == "holy" else "petal", Color("b9ffd8"), Vector2(0.6, 1.4), Vector2(0.6, 1.0), 0.1, Vector3.UP, 0.5, -0.4, 0.5, 0.0, 0.0, 1, 0.6)

# Smooth body motion: ordinary steering follows the sim closely; sudden displacements
# (leaps, dashes, knockbacks, blinks) become a short arcing hop instead of a zip across the floor.
func follow(u: Dictionary, visual: Dictionary, dt: float) -> void:
 if dt <= 0: return
 var target = world_point(u.pos)
 var before = visual.root.position
 var jump = target - visual.last_target
 visual.last_target = target
 if jump.length() > 0.9 and u.alive:
  var dist = (target - before).length()
  var own_move = u.windup > 0 or u.recovery > 0 or u.has("pending_cast")
  visual.arc = {"from": before, "t": 0.0, "dur": clampf(dist / (8.5 if own_move else 7.0), 0.22, 0.5), "h": dist * (0.2 if own_move else 0.09)}
 if not visual.arc.is_empty():
  var a = visual.arc
  a.t += dt
  var k = clampf(a.t / a.dur, 0.0, 1.0)
  var e = k * k * (3.0 - 2.0 * k)
  visual.root.position = a.from.lerp(target, e) + Vector3.UP * a.h * sin(PI * k)
  if k >= 1.0: visual.arc = {}; visual.root.position = target
 else:
  visual.root.position = visual.root.position.lerp(target, 1.0 - exp(-dt * 18.0))
 var moved = visual.root.position - before; moved.y = 0
 visual.ground_speed = lerpf(visual.ground_speed, moved.length() / dt, 1.0 - exp(-dt * 20.0))
 visual.walk_hold = maxf(0.0, visual.walk_hold - dt)
 if u.alive:
  # Turn with momentum: eased, but never faster than the creature could plausibly pivot.
  var heavy = u.hero.sp in ["golem","cyclops","zaratan","treant","yeti","minotaur","troll","hydra"]
  var max_rate = 5.0 if heavy else 8.0
  if u.windup > 0 or u.has("pending_cast"): max_rate *= 2.2   # snap onto the target when committing to a strike
  var diff = angle_difference(visual.model.rotation.y, u.heading)
  var want = diff * (1.0 - exp(-dt * 10.0))
  visual.model.rotation.y += clampf(want, -max_rate * dt, max_rate * dt)
