class_name ChampionCarousel
extends Control
## A shared 3D stage: the equipped champion steps forward, the rest recede.
## Invisible GearTokens preserve champion selection and item drop / forge targets.
var game: Node
var heroes: Array = []
var selected_index = 0
var camera: Camera3D
var entries: Array = []
var stage: SubViewportContainer

static func offset_for(index: int, selected: int, count: int) -> int:
 var offset = posmod(index - selected, count)
 if offset > int(count / 2): offset -= count
 return offset

func select_hero(id: String) -> void:
 if id == game.selected_id: return
 game.set_meta("shop_carousel_from", game.selected_id)
 game.selected_id = id
 game.render()

func rotate(direction: int) -> void:
 if heroes.size() < 2: return
 select_hero(heroes[posmod(selected_index + direction, heroes.size())].id)

func _ready() -> void:
 name = "ChampionCarousel"
 clip_contents = true
 heroes = game.campaign.lineup().duplicate()
 for h in game.campaign.state.roster:
  if h not in heroes: heroes.append(h)
 if heroes.is_empty(): return
 var previous_id = str(game.get_meta("shop_carousel_from", game.selected_id))
 if game.has_meta("shop_carousel_from"): game.remove_meta("shop_carousel_from")
 var previous_index = 0
 for i in range(heroes.size()):
  if heroes[i].id == game.selected_id: selected_index = i
  if heroes[i].id == previous_id: previous_index = i

 stage = SubViewportContainer.new(); stage.stretch = true; stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(stage); stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var viewport = SubViewport.new(); viewport.own_world_3d = true; viewport.transparent_bg = true
 viewport.size = Vector2i(1030, 300); viewport.msaa_3d = Viewport.MSAA_2X
 stage.add_child(viewport)
 var env = WorldEnvironment.new(); env.environment = Environment.new(); viewport.add_child(env)
 env.environment.background_mode = Environment.BG_CLEAR_COLOR
 env.environment.background_color = Color(0, 0, 0, 0)
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color("a4bbda"); env.environment.ambient_light_energy = 0.65
 for spec in [[Vector3(-40, -35, 0), Color("ffe0ad"), 1.8], [Vector3(-25, 145, 0), Color("b3bdff"), 1.4]]:
  var light = DirectionalLight3D.new(); light.rotation_degrees = spec[0]
  light.light_color = spec[1]; light.light_energy = spec[2]; viewport.add_child(light)
 camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 6.0
 viewport.add_child(camera); camera.position = Vector3(0, 4.5, 15); camera.look_at(Vector3(0, 1.7, 0)); camera.make_current()
 for i in range(heroes.size()):
  var hero = heroes[i]
  var pivot = Node3D.new(); viewport.add_child(pivot)
  var model = load("res://assets/beasts/%s.glb" % hero.sp).instantiate(); pivot.add_child(model)
  var bounds = AABB(); var first = true
  for mesh in model.find_children("*", "MeshInstance3D", true, false):
   var b = mesh.global_transform * mesh.get_aabb(); bounds = b if first else bounds.merge(b); first = false
  var height_scale = 3.2 / maxf(0.1, bounds.size.y)
  model.scale = Vector3.ONE * height_scale
  model.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * height_scale
  model.rotation.y = 0.15
  var plinth = MeshInstance3D.new(); var disc = CylinderMesh.new()
  disc.top_radius = 1.1; disc.bottom_radius = 1.2; disc.height = 0.08; plinth.mesh = disc
  var mat = StandardMaterial3D.new();mat.albedo_color=Color("735088");mat.emission_enabled=true;mat.emission=Color("764aad");mat.emission_energy_multiplier=0.4
  plinth.name="FeaturedPlinth";plinth.visible=hero.id==game.selected_id;plinth.material_override=mat;plinth.position.y=-0.04;pivot.add_child(plinth)
  for player in model.find_children("*", "AnimationPlayer", true, false):
   if player.has_animation("idle"):
    player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR; player.play("idle")
  var off = offset_for(i, selected_index, heroes.size())
  var old_off = offset_for(i, previous_index, heroes.size())
  var destination = pose(off)
  pivot.position = pose(old_off).position; pivot.scale = Vector3.ONE * pose(old_off).scale
  pivot.visible = abs(off) <= 2 or abs(old_off) <= 2
  for mesh in model.find_children("*", "MeshInstance3D", true, false): mesh.transparency = 0.0 if off == 0 else 0.32
  var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  tween.tween_property(pivot, "position", destination.position, 0.42)
  tween.tween_property(pivot, "scale", Vector3.ONE * destination.scale, 0.42)
  tween.chain().tween_callback(func(): pivot.visible = abs(off) <= 2)
  var target = GearToken.new(); target.game = game; target.target_hero = hero.id; target.name = "CarouselHero_" + hero.id
  add_child(target)
  for state in ["normal", "hover", "pressed"]: target.add_theme_stylebox_override(state, StyleBoxEmpty.new())
  target.add_theme_stylebox_override("focus", game.style(Color(0, 0, 0, 0), game.GOLD, 6, 0, 2))
  target.tooltip_text = "%s · %s\nClick to feature · drop equipment here" % [hero.name, HeroData.species[hero.sp].n]
  target.pressed.connect(func(): select_hero(hero.id))
  var caption = game.label(self, hero.name+" "+"★".repeat(ChampionStars.tier(hero)), 20 if off == 0 else 14, game.GOLD if off == 0 else game.MUTED, false)
  caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
  entries.append({"model":model,"tween":tween,"root": pivot, "target": target, "caption": caption, "offset": off})
 # Put the selected champion's hit target above the receding ones.
 for entry in entries:
  if entry.offset == 0: move_child(entry.target, -1); move_child(entry.caption, -1)
 refresh_selection()
 var previous = game.button(self, "‹", func(): rotate(-1)); previous.name = "CarouselPrevious"
 previous.position = Vector2(8, 118); previous.size = Vector2(48, 56); previous.tooltip_text = "Previous champion (Left arrow)"
 var next = game.button(self, "›", func(): rotate(1)); next.name = "CarouselNext"
 next.position = Vector2(974, 118); next.size = Vector2(48, 56); next.tooltip_text = "Next champion (Right arrow)"
 previous.disabled = heroes.size() < 2; next.disabled = heroes.size() < 2

static func pose(offset: int) -> Dictionary:
 return {"position": Vector3(offset * 3.3, 0, -abs(offset) * 1.5), "scale": 1.35 if offset == 0 else maxf(0.55, 0.78 - abs(offset) * 0.08)}

func refresh_selection() -> void:
 for i in range(heroes.size()):
  heroes[i]=game.campaign.hero_by_id(heroes[i].id)
  if heroes[i].id==game.selected_id:selected_index=i
 for i in range(entries.size()):
  var entry=entries[i];var hero=heroes[i];var off=offset_for(i,selected_index,heroes.size());var destination=pose(off)
  if entry.tween and entry.tween.is_valid():entry.tween.kill()
  var was_visible=entry.root.visible;entry.root.visible=abs(off)<=2 or was_visible
  entry.offset=off;entry.root.get_node("FeaturedPlinth").visible=off==0
  for mesh in entry.model.find_children("*","MeshInstance3D",true,false):mesh.transparency=0.0 if off==0 else .32
  entry.caption.text=hero.name+" "+"★".repeat(ChampionStars.tier(hero))
  entry.caption.add_theme_font_size_override("font_size",20 if off==0 else 14)
  entry.caption.modulate=game.GOLD if off==0 else game.MUTED
  entry.target.tooltip_text=hero.name+" · "+ChampionStars.label(hero)+"\n"+ChampionStars.evolution_label(hero)+"\nClick to feature · drop equipment here"
  var tween=create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  tween.tween_property(entry.root,"position",destination.position,.42)
  tween.tween_property(entry.root,"scale",Vector3.ONE*destination.scale,.42)
  tween.chain().tween_callback(func():entry.root.visible=abs(off)<=2)
  entry.tween=tween
  if off==0:move_child(entry.target,-1);move_child(entry.caption,-1)
 if game.has_meta("shop_carousel_from"):game.remove_meta("shop_carousel_from")

func _process(_dt: float) -> void:
 if not camera: return
 for entry in entries:
  var root: Node3D = entry.root
  var foot = camera.unproject_position(root.position)
  var head = camera.unproject_position(root.position + Vector3.UP * 3.5 * root.scale.y)
  var h = maxf(40.0, foot.y - head.y)
  var target: Control = entry.target
  target.visible = root.visible; target.position = Vector2(foot.x - h * 0.42, head.y)
  target.size = Vector2(h * 0.84, h)
  entry.caption.visible = root.visible
  entry.caption.position = Vector2(foot.x - 110, foot.y + 2)
  entry.caption.size = Vector2(220, 30)

func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_LEFT, KEY_RIGHT]:
  rotate(-1 if event.keycode == KEY_LEFT else 1)
  get_viewport().set_input_as_handled()
