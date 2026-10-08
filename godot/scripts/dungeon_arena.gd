class_name DungeonArena
extends RefCounted
## Turns the colosseum into a dungeon chamber for each instance: the grandstands, banners and
## crowd are hidden; a ring of cave rock closes the arena in; each instance adds its own set
## pieces (crystals, lava, dead trees, ice, flooded columns, giant mushrooms, bone piles,
## lightning pylons, obelisks, floating void shards), coloured light, fog and drifting particles.
## Everything is built from primitives and the existing rock shader, so no new models are needed.
## The fighting floor is never covered: props stay outside the hex field, and props in front of
## the camera are kept low.

const RX := 18.6   # cave wall ellipse (stage units, before the stage scale)
const RZ := 13.4

static func dress(arena: ArenaView, region: Dictionary, root: Node3D) -> void:
 var id = str(region.dungeon); var info = DungeonInstances.info(id)
 hide_colosseum(arena)
 light(arena, info)
 var rng = RandomNumberGenerator.new(); rng.seed = hash(id + "|arena")
 cave_wall(arena, root, info, rng)
 match str(info.kit):
  "blight": blight(arena, root, info, rng)
  "crystals": crystals(arena, root, info, rng)
  "lava": lava(arena, root, info, rng)
  "ice": ice(arena, root, info, rng)
  "water": water(arena, root, info, rng)
  "fungal": fungal(arena, root, info, rng)
  "bones": bones(arena, root, info, rng)
  "storm": storm(arena, root, info, rng)
  "tomb": tomb(arena, root, info, rng)
  "void": rift(arena, root, info, rng)
 lamps(arena, root, info)
 motes(root, info)

## Undo everything dress() changed (World Tour regions, exhibitions).
static func undress(arena: ArenaView) -> void:
 if not arena.has_meta("dungeon_saved"): return
 var saved: Dictionary = arena.get_meta("dungeon_saved")
 for node in saved.hidden:
  if is_instance_valid(node): node.visible = true
 for entry in saved.lights:
  if is_instance_valid(entry.node): entry.node.light_color = entry.color; entry.node.light_energy = entry.energy
 if is_instance_valid(saved.get("env_node")):
  var env: Environment = saved.env_node.environment
  for key in saved.env: env.set(key, saved.env[key])
 var hex = arena.get_node_or_null("HexFloor")
 if hex and saved.has("floor"): hex.material_override.albedo_color = saved.floor
 arena.remove_meta("dungeon_saved")

static func hide_colosseum(arena: ArenaView) -> void:
 if arena.has_meta("dungeon_saved") or not is_instance_valid(arena.world_stage): return
 var saved = {"hidden": [], "lights": [], "env": {}}
 for node in arena.world_stage.get_children():
  var colosseum = node.is_in_group("arena_perimeter") or node.is_in_group("arena_flames") or (node is MultiMeshInstance3D and node.multimesh and node.multimesh.mesh is CapsuleMesh)
  if (node is GeometryInstance3D and (node.position.y >= 0.08 or colosseum)) or node is OmniLight3D:
   if node.visible: node.visible = false; saved.hidden.append(node)
  elif node is DirectionalLight3D:
   saved.lights.append({"node": node, "color": node.light_color, "energy": node.light_energy})
  elif node is WorldEnvironment:
   saved.env_node = node
   for key in ["background_mode", "background_color", "ambient_light_source", "ambient_light_color", "ambient_light_energy", "fog_enabled", "fog_light_color", "fog_density"]:
    saved.env[key] = node.environment.get(key)
 var hex = arena.get_node_or_null("HexFloor")
 if hex: saved.floor = hex.material_override.albedo_color
 arena.set_meta("dungeon_saved", saved)

static func light(arena: ArenaView, info: Dictionary) -> void:
 var saved: Dictionary = arena.get_meta("dungeon_saved", {})
 for entry in saved.get("lights", []):
  if not is_instance_valid(entry.node): continue
  if entry.node.shadow_enabled: entry.node.light_color = Color(info.sky).lerp(Color.WHITE, 0.35); entry.node.light_energy = 1.0
  else: entry.node.light_color = Color(info.accent); entry.node.light_energy = 0.7
 if is_instance_valid(saved.get("env_node")):
  var env: Environment = saved.env_node.environment
  env.background_mode = Environment.BG_COLOR; env.background_color = Color(info.fog).darkened(0.35)
  env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(info.ambient); env.ambient_light_energy = 0.55
  env.fog_enabled = true; env.fog_light_color = Color(info.fog); env.fog_density = 0.012
 var hex = arena.get_node_or_null("HexFloor")
 if hex: hex.material_override.albedo_color = Color(info.floor).lightened(0.12)

# ------------------------------------------------------------------ Shared pieces
static func ring(t: float, scale := 1.0) -> Vector3:
 return Vector3(cos(t) * RX * scale, 0.0, sin(t) * RZ * scale)

## Front of the stage faces the camera (positive z): keep it low there.
static func height_cap(p: Vector3) -> float:
 return 1.3 if p.z > RZ * 0.35 else 99.0

static func rock_mat(color: Color, glow: Color = Color.BLACK, molten := 0.0, seed := 0.0) -> ShaderMaterial:
 var m = ShaderMaterial.new(); m.shader = load("res://shaders/vfx/rock.gdshader")
 m.set_shader_parameter("stone", color); m.set_shader_parameter("glow_color", glow)
 m.set_shader_parameter("molten", molten); m.set_shader_parameter("seed", seed)
 return m

static func glow_mat(color: Color, energy := 1.2, alpha := 1.0) -> StandardMaterial3D:
 var m = StandardMaterial3D.new(); m.albedo_color = Color(color, alpha)
 m.emission_enabled = true; m.emission = color; m.emission_energy_multiplier = energy * 0.5
 if alpha < 1.0: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 return m

static func boulder(arena: ArenaView, root: Node3D, pos: Vector3, size: Vector3, mat: Material, rng: RandomNumberGenerator) -> MeshInstance3D:
 var shape = SphereMesh.new(); shape.radius = 0.5; shape.height = 1.0; shape.radial_segments = 7; shape.rings = 4
 var m = arena.mesh(root, shape, mat, pos + Vector3(0, size.y * 0.35, 0))
 m.scale = size; m.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, rng.randf_range(-0.2, 0.2))
 return m

static func spike(arena: ArenaView, root: Node3D, pos: Vector3, w: float, h: float, mat: Material, tilt: float = 0.0) -> MeshInstance3D:
 var shape = PrismMesh.new(); shape.size = Vector3(w, h, w)
 var m = arena.mesh(root, shape, mat, pos + Vector3(0, h * 0.5, 0)); m.rotation.z = tilt; m.rotation.y = pos.x * 0.7
 return m

static func cave_wall(arena: ArenaView, root: Node3D, info: Dictionary, rng: RandomNumberGenerator) -> void:
 var stone = Color(info.floor).lightened(0.15)
 var mats = [rock_mat(stone, Color(info.accent), 0.0, 1.0), rock_mat(stone.darkened(0.2), Color(info.accent), 0.0, 7.0)]
 for i in range(40):
  var t = i * TAU / 40.0 + rng.randf_range(-0.04, 0.04)
  var p = ring(t, rng.randf_range(1.0, 1.12))
  var h = minf(rng.randf_range(2.6, 6.5), height_cap(p))
  boulder(arena, root, p, Vector3(rng.randf_range(2.8, 4.6), h, rng.randf_range(2.4, 3.8)), mats[i % 2], rng)
 # A ceiling of hanging stone far behind the fight sells the cavern from the battle camera.
 for i in range(9):
  var p = Vector3((i - 4) * 4.4, 0, -RZ * 1.18)
  var stalactite = spike(arena, root, p + Vector3(0, 6.0, 0), 2.2, 4.0, mats[i % 2]); stalactite.rotation.z = PI

static func scatter(count: int, rng: RandomNumberGenerator, inner := 0.9, outer := 1.0) -> Array:
 var out = []
 for i in range(count):
  var t = rng.randf() * TAU
  out.append(ring(t, rng.randf_range(inner, outer)))
 return out

static func lamps(arena: ArenaView, root: Node3D, info: Dictionary) -> void:
 for i in range(6):
  var p = ring(PI * 1.1 + i * PI * 0.8 / 5.0, 0.86) + Vector3(0, 2.4, 0)
  var l = OmniLight3D.new(); l.light_color = Color(info.accent); l.light_energy = 1.6; l.omni_range = 9.0; l.position = p; root.add_child(l)

static func motes(root: Node3D, info: Dictionary) -> void:
 var kit = str(info.kit)
 var p = CPUParticles3D.new(); root.add_child(p)
 p.amount = 140; p.lifetime = 7.0; p.preprocess = 7.0; p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
 p.emission_box_extents = Vector3(RX * 0.95, 3.0, RZ * 0.95); p.position = Vector3(0, 3.5, 0)
 var dot = SphereMesh.new(); dot.radius = 0.05; dot.height = 0.1; dot.radial_segments = 4; dot.rings = 2
 var mat = glow_mat(Color(info.motes), 2.0); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 dot.material = mat; p.mesh = dot
 p.direction = Vector3.UP; p.spread = 30.0; p.initial_velocity_min = 0.05; p.initial_velocity_max = 0.25
 p.gravity = {"lava": Vector3(0, 0.45, 0), "ice": Vector3(0.05, -0.35, 0), "storm": Vector3(0.6, 0, 0), "tomb": Vector3(0.25, -0.02, 0), "water": Vector3(0, 0.12, 0), "bones": Vector3(0.05, -0.08, 0)}.get(kit, Vector3(0, 0.03, 0))
 p.scale_amount_min = 0.6; p.scale_amount_max = 1.6 if kit != "ice" else 2.2

# ------------------------------------------------------------------ Instance kits
static func blight(arena: ArenaView, root: Node3D, info: Dictionary, rng: RandomNumberGenerator) -> void:
 var bark = arena.material(Color("3a3024"), 0.0, 0.95)
 var toxic = glow_mat(Color(info.accent), 1.4, 0.85)
 for p in scatter(10, rng, 0.82, 0.95):
  if p.z > RZ * 0.35: continue
  var trunk = arena.cylinder(root, 0.28, 4.6, p + Vector3(0, 2.3, 0), bark, 7); trunk.rotation.z = rng.randf_range(-0.25, 0.25)
  for j in range(3):
   var branch = arena.box(root, Vector3(0.14, 1.9, 0.14), p + Vector3(rng.randf_range(-0.5, 0.5), 3.4 + j * 0.5, 0), bark)
   branch.rotation = Vector3(rng.randf_range(-0.9, 0.9), 0, rng.randf_range(-1.1, 1.1))
 for p in scatter(7, rng, 0.84, 0.93):
  var pool = arena.cylinder(root, rng.randf_range(0.9, 1.6), 0.04, p + Vector3(0, 0.03, 0), toxic, 16); pool.scale.z = 0.7
 for p in scatter(12, rng, 0.86, 0.98): spike(arena, root, p, 0.25, rng.randf_range(0.8, 1.6), arena.material(Color("4a5a2a")), rng.randf_range(-0.5, 0.5))

static func crystals(arena: ArenaView, root: Node3D, info: Dictionary, rng: RandomNumberGenerator) -> void:
 var cols = [Color(info.accent), Color("b38aff"), Color("8af0ff")]
 for p in scatter(16, rng, 0.84, 0.97):
  var c = cols[rng.randi_range(0, 2)]
  for j in range(rng.randi_range(2, 4)):
   var h = minf(rng.randf_range(1.2, 3.8), height_cap(p))
   spike(arena, root, p + Vector3(rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-0.4, 0.4)), rng.randf_range(0.35, 0.7), h, glow_mat(c.darkened(0.25), 0.55, 0.9), rng.randf_range(-0.35, 0.35))
 for i in range(3):
  var big = Vector3((i - 1) * 9.0, 0, -RZ * 1.02)
  spike(arena, root, big, 1.8, 7.5, glow_mat(cols[i].darkened(0.3), 0.5, 0.85), (i - 1) * 0.12)

static func lava(arena: ArenaView, root: Node3D, info: Dictionary, rng: RandomNumberGenerator) -> void:
 var basalt = rock_mat(Color("2a2220"), Color("ff6a1a"), 0.8, 3.0)
 var molten = glow_mat(Color("ff6a1a"), 2.2)
 for p in scatter(8, rng, 0.84, 0.94):
  var pool = arena.cylinder(root, rng.randf_range(1.0, 1.8), 0.05, p + Vector3(0, 0.03, 0), molten, 18); pool.scale.z = 0.7
 for p in scatter(14, rng, 0.86, 0.99): boulder(arena, root, p, Vector3(1.4, minf(rng.randf_range(0.8, 2.4), height_cap(p)), 1.2), basalt, rng)
 for x in [-10.0, 0.0, 10.0]:
  arena.box(root, Vector3(1.6, 9.0, 0.3), Vector3(x, 4.0, -RZ * 1.06), molten)   # lava falls behind the far wall

static func ice(arena: ArenaView, root: Node3D, info: Dictionary, rng: RandomNumberGenerator) -> void:
 var shard = glow_mat(Color("bfe8ff"), 0.6, 0.8)
 var snow = arena.material(Color("eef6ff"), 0.0, 0.7)
 for p in scatter(14, rng, 0.84, 0.97):
  spike(arena, root, p, rng.randf_range(0.4, 0.9), minf(rng.randf_range(1.4, 4.2), height_cap(p)), shard, rng.randf_range(-0.4, 0.4))
 for p in scatter(10, rng, 0.86, 0.98):
  var mound = SphereMesh.new(); mound.radius = 1.0; mound.height = 0.8
  arena.mesh(root, mound, snow, p).scale = Vector3(rng.randf_range(1.2, 2.2), 0.6, 1.2)
 for x in [-7.0, 7.0]:
  arena.cylinder(root, 0.7, 6.0, Vector3(x, 3.0, -RZ * 0.98), shard, 8)

static func water(arena: ArenaView, root: Node3D, info: Dictionary, rng: RandomNumberGenerator) -> void:
 var sea = glow_mat(Color(info.accent).darkened(0.3), 0.5, 0.55)
 var plane = PlaneMesh.new(); plane.size = Vector2(RX * 2.4, RZ * 2.4)
 arena.mesh(root, plane, sea, Vector3(0, -0.02, 0))   # shallow flood beneath the raised floor
 var marble = arena.material(Color("8aa0a8"), 0.1, 0.6)
 for i in range(8):
  var p = ring(PI * 1.05 + i * PI * 0.9 / 7.0, 0.9)
  var h = rng.randf_range(2.0, 5.5)
  arena.cylinder(root, 0.55, h, p + Vector3(0, h * 0.5, 0), marble, 10).rotation.z = rng.randf_range(-0.15, 0.15)
 for p in scatter(14, rng, 0.85, 0.98):
  for j in range(3):
   var coral = arena.box(root, Vector3(0.14, minf(1.4, height_cap(p)), 0.14), p + Vector3(j * 0.3, 0.6, 0), glow_mat(Color("ff8aa8") if j % 2 else Color(info.accent), 0.8))
   coral.rotation.z = (j - 1) * 0.35

static func fungal(arena: ArenaView, root: Node3D, info: Dictionary, rng: RandomNumberGenerator) -> void:
 var stem = arena.material(Color("e8dcd0"), 0.0, 0.8)
 var caps = [glow_mat(Color(info.accent), 1.4), glow_mat(Color("7affd8"), 1.2), glow_mat(Color("ff8ad0"), 1.2)]
 for p in scatter(18, rng, 0.83, 0.97):
  var h = minf(rng.randf_range(0.8, 4.5), height_cap(p))
  arena.cylinder(root, 0.12 + h * 0.06, h, p + Vector3(0, h * 0.5, 0), stem, 8)
  var cap = SphereMesh.new(); cap.radius = 0.4 + h * 0.28; cap.height = cap.radius
  arena.mesh(root, cap, caps[rng.randi_range(0, 2)], p + Vector3(0, h, 0)).scale.y = 0.55

static func bones(arena: ArenaView, root: Node3D, info: Dictionary, rng: RandomNumberGenerator) -> void:
 var bone = arena.material(Color("e8dcc0"), 0.0, 0.7)
 var skull: Mesh = load("res://assets/vfx_props/horned_skull.res")
 for p in scatter(16, rng, 0.84, 0.98):
  for j in range(5):
   var shaft = CapsuleMesh.new(); shaft.radius = 0.08; shaft.height = rng.randf_range(0.8, 1.6)
   var b = arena.mesh(root, shaft, bone, p + Vector3(rng.randf_range(-0.6, 0.6), 0.15 + j * 0.08, rng.randf_range(-0.4, 0.4)))
   b.rotation = Vector3(PI * 0.5, rng.randf() * TAU, rng.randf_range(-0.3, 0.3))
 for i in range(6):
  var p = ring(PI * 1.15 + i * PI * 0.7 / 5.0, 0.9)
  if skull: arena.mesh(root, skull, bone, p + Vector3(0, 0.6, 0)).scale = Vector3.ONE * 1.8
  var candle = arena.cylinder(root, 0.08, 0.5, p + Vector3(0.9, 0.25, 0), bone, 6)
  arena.mesh(root, SphereMesh.new(), glow_mat(Color("ffcf7a"), 2.0), candle.position + Vector3(0, 0.35, 0)).scale = Vector3.ONE * 0.12

static func storm(arena: ArenaView, root: Node3D, info: Dictionary, rng: RandomNumberGenerator) -> void:
 var iron = arena.material(Color("5a6470"), 0.7, 0.4)
 var spark = glow_mat(Color(info.accent), 2.4)
 for i in range(8):
  var p = ring(PI * 1.05 + i * PI * 0.9 / 7.0, 0.9)
  var h = rng.randf_range(3.5, 6.5)
  arena.cylinder(root, 0.18, h, p + Vector3(0, h * 0.5, 0), iron, 8)
  var orb = SphereMesh.new(); orb.radius = 0.35; orb.height = 0.7
  arena.mesh(root, orb, spark, p + Vector3(0, h + 0.3, 0))
 for p in scatter(10, rng, 1.0, 1.1):
  var floating = boulder(arena, root, p + Vector3(0, rng.randf_range(4.0, 7.5), 0), Vector3(1.6, 1.0, 1.4), rock_mat(Color("4a5260"), Color(info.accent), 0.25), rng)
  floating.visible = p.z < RZ * 0.3

static func tomb(arena: ArenaView, root: Node3D, info: Dictionary, rng: RandomNumberGenerator) -> void:
 var sandstone = arena.material(Color("c8a870"), 0.1, 0.8)
 var gold = arena.material(Color("f0c050"), 0.8, 0.3)
 for i in range(6):
  var p = ring(PI * 1.12 + i * PI * 0.76 / 5.0, 0.9)
  arena.box(root, Vector3(0.9, 5.0, 0.9), p + Vector3(0, 2.5, 0), sandstone)
  var cap = PrismMesh.new(); cap.size = Vector3(0.95, 0.9, 0.95); arena.mesh(root, cap, gold, p + Vector3(0, 5.45, 0))
 for p in scatter(8, rng, 0.86, 0.96):
  if p.z > RZ * 0.35: continue
  arena.box(root, Vector3(2.0, 0.8, 0.9), p + Vector3(0, 0.4, 0), sandstone).rotation.y = rng.randf() * TAU   # sarcophagi
 for p in scatter(6, rng, 0.84, 0.9):
  arena.cylinder(root, 0.35, 0.9, p + Vector3(0, 0.45, 0), gold, 10)
  var fire = SphereMesh.new(); fire.radius = 0.3; fire.height = 0.7
  arena.mesh(root, fire, glow_mat(Color("ffb050"), 2.6), p + Vector3(0, 1.15, 0))

static func rift(arena: ArenaView, root: Node3D, info: Dictionary, rng: RandomNumberGenerator) -> void:
 var dark = rock_mat(Color("1a1428"), Color(info.accent), 0.6, 11.0)
 for p in scatter(14, rng, 0.95, 1.12):
  if p.z > RZ * 0.3: continue
  var shard = spike(arena, root, p + Vector3(0, rng.randf_range(2.0, 6.0), 0), rng.randf_range(0.6, 1.4), rng.randf_range(1.5, 3.5), dark, rng.randf_range(-1.0, 1.0))
  shard.rotation.x = rng.randf_range(-0.6, 0.6)
 for i in range(3):
  var halo = TorusMesh.new(); halo.inner_radius = 2.6 + i * 1.6; halo.outer_radius = 2.75 + i * 1.6
  var h = arena.mesh(root, halo, glow_mat(Color(info.accent), 1.6, 0.8), Vector3(0, 6.0 + i * 0.6, -RZ * 1.05))
  h.rotation.x = PI * 0.5 - 0.2
 for p in scatter(10, rng, 0.86, 0.98): spike(arena, root, p, 0.4, minf(rng.randf_range(0.8, 2.6), height_cap(p)), glow_mat(Color(info.accent).darkened(0.3), 1.0, 0.9))
