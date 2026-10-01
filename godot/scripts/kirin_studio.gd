extends Control
## A live art-review scene. The comparison image is concept art; the left-hand
## character is the same imported, skinned GLB used by the arena.

var camera: Camera3D
var player: AnimationPlayer
var viewport: SubViewport
var model: Node3D
var yaw = 0.72
var pitch = 0.13
var distance = 8.9
var spinning = false
var dragging = false
var chosen = "idle"
var capture = ""
var capture_time = 0.0
var capture_pose = "idle"
var capture_angle = 0.72
var elapsed = 0.0
var captured = false
var pose_buttons: Array[Button] = []
var pause_button: Button
var film = false
var film_elapsed = 0.0

func text(parent: Node, value: String, size: int, color = Color("e8e6df")) -> Label:
 var label = Label.new(); label.text = value; label.add_theme_font_size_override("font_size", size); label.add_theme_color_override("font_color", color); parent.add_child(label)
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 return label

func button(parent: Node, title: String, callback: Callable) -> Button:
 var b = Button.new(); parent.add_child(b); b.text = title; b.custom_minimum_size.y = 44
 b.add_theme_font_size_override("font_size", 16)
 var style = StyleBoxFlat.new(); style.bg_color = Color("203845"); style.border_color = Color("4b6973"); style.set_border_width_all(1); style.set_corner_radius_all(7); style.content_margin_left = 16; style.content_margin_right = 16
 b.add_theme_stylebox_override("normal", style)
 var hover = style.duplicate(); hover.bg_color = Color("365461"); b.add_theme_stylebox_override("hover", hover)
 var pressed = style.duplicate(); pressed.bg_color = Color("665638"); pressed.border_color = Color("c1a577"); b.add_theme_stylebox_override("pressed", pressed)
 b.pressed.connect(callback)
 return b

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 theme = Theme.new(); theme.default_font = load("res://assets/fonts/dmsans.ttf")
 for arg in OS.get_cmdline_user_args():
  if arg == "--kirin-film": film = true
  if arg.begins_with("--kirin-capture="): capture = arg.trim_prefix("--kirin-capture=")
  if arg.begins_with("--kirin-pose="): capture_pose = arg.trim_prefix("--kirin-pose=")
  if arg.begins_with("--kirin-time="): capture_time = float(arg.trim_prefix("--kirin-time="))
  if arg.begins_with("--kirin-angle="): capture_angle = float(arg.trim_prefix("--kirin-angle="))
 var bg = ColorRect.new(); add_child(bg); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.color = Color("0c1822")
 var frame = SubViewportContainer.new(); add_child(frame); frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); frame.anchor_right = 0.73; frame.stretch = true
 viewport = SubViewport.new(); viewport.size = Vector2i(1168, 900); viewport.own_world_3d = true; viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; viewport.msaa_3d = Viewport.MSAA_4X; frame.add_child(viewport)
 var stage = Node3D.new(); viewport.add_child(stage)
 var world = WorldEnvironment.new(); stage.add_child(world); world.environment = Environment.new()
 var env = world.environment; env.background_mode = Environment.BG_COLOR; env.background_color = Color("14212b")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color("a3b4c9"); env.ambient_light_energy = 0.48
 env.tonemap_mode = Environment.TONE_MAPPER_ACES
 if RenderingServer.get_current_rendering_method() != "gl_compatibility":
  env.ssao_enabled = true; env.ssao_intensity = 1.3; env.glow_enabled = true; env.glow_intensity = 0.35
 var key = DirectionalLight3D.new(); stage.add_child(key); key.rotation_degrees = Vector3(-35, -40, 0); key.light_color = Color("ffe9ce"); key.light_energy = 1.35; key.shadow_enabled = true
 var fill = DirectionalLight3D.new(); stage.add_child(fill); fill.rotation_degrees = Vector3(-18, 58, 0); fill.light_color = Color("a1c0ea"); fill.light_energy = 0.75
 var rim = DirectionalLight3D.new(); stage.add_child(rim); rim.rotation_degrees = Vector3(-25, 150, 0); rim.light_color = Color("b6ddec"); rim.light_energy = 1.7
 model = load("res://assets/beasts/kirin.glb").instantiate(); stage.add_child(model)
 player = model.find_children("*", "AnimationPlayer", true, false)[0]
 for clip in ["idle", "walk"]: player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
 var ground = MeshInstance3D.new(); stage.add_child(ground); var shape = CylinderMesh.new(); shape.top_radius = 2.5; shape.bottom_radius = 2.55; shape.height = .14; shape.radial_segments = 96; ground.mesh = shape; ground.position.y = -.09
 var material = StandardMaterial3D.new(); material.albedo_color = Color("253741"); material.metallic = .25; material.roughness = .42; ground.material_override = material
 var ring = MeshInstance3D.new(); stage.add_child(ring); var torus = TorusMesh.new(); torus.inner_radius = 2.43; torus.outer_radius = 2.45; torus.rings = 96; torus.ring_segments = 6; ring.mesh = torus; ring.position.y = -.006
 var gold = StandardMaterial3D.new(); gold.albedo_color = Color("b29362"); gold.metallic = .7; gold.roughness = .36; ring.material_override = gold
 camera = Camera3D.new(); stage.add_child(camera); camera.fov = 34; camera.make_current(); update_camera()
 var top = VBoxContainer.new(); add_child(top); top.position = Vector2(44, 28); top.size.x = 640
 text(top, "MANITORIA  /  CHARACTER STUDY 01", 14, Color("b9a37d"))
 var title = text(top, "KIRIN", 48); title.add_theme_font_override("font", load("res://assets/fonts/cinzel.ttf"))
 text(top, "The storm-crowned", 18, Color("99b1bd"))
 var right = PanelContainer.new(); add_child(right); right.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); right.anchor_left = .73; right.offset_left = 0
 var panel = StyleBoxFlat.new(); panel.bg_color = Color("0b1720"); panel.content_margin_left = 28; panel.content_margin_right = 28; panel.content_margin_top = 34; panel.content_margin_bottom = 24; panel.border_color = Color("384952"); panel.border_width_left = 1; right.add_theme_stylebox_override("panel", panel)
 var stack = VBoxContainer.new(); right.add_child(stack); stack.add_theme_constant_override("separation", 15)
 text(stack, "THE ORIGINAL DESIGN", 15, Color("c7b28b"))
 var art = TextureRect.new(); stack.add_child(art); art.custom_minimum_size = Vector2(0, 290); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 var atlas = AtlasTexture.new(); atlas.atlas = load("res://assets/art/kirin-concept-sheet.png"); var sheet = atlas.atlas.get_size(); atlas.region = Rect2(sheet * Vector2(.759, .473), sheet * Vector2(.241, .251)); art.texture = atlas
 text(stack, "Silver-blue hide. A branching gold crown. A flowing mane and tail.", 18)
 text(stack, "Compare the shape and movement from every angle. This is the live game model.", 16, Color("94abb7"))
 var spacer = Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL; stack.add_child(spacer)
 button(stack, "Return to club menu", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
 var bottom = VBoxContainer.new(); add_child(bottom); bottom.anchor_top = 1; bottom.anchor_bottom = 1; bottom.anchor_right = .73; bottom.offset_left = 42; bottom.offset_top = -128; bottom.offset_right = -24; bottom.offset_bottom = -24
 var clips = HBoxContainer.new(); bottom.add_child(clips); clips.add_theme_constant_override("separation", 8)
 for clip in ["idle", "walk", "attack", "cast", "death"]:
  var b = button(clips, clip.capitalize(), func(): play_clip(clip)); b.toggle_mode = true; b.set_meta("clip", clip); pose_buttons.append(b)
 var controls = HBoxContainer.new(); bottom.add_child(controls); controls.add_theme_constant_override("separation", 8)
 pause_button = button(controls, "Pause", toggle_pause)
 var spin = button(controls, "Turntable", func(): spinning = not spinning); spin.toggle_mode = true
 button(controls, "Reset view", func(): yaw = .72; pitch = .13; distance = 8.9; update_camera())
 var hint = text(controls, "  Drag to orbit · Scroll to zoom", 14, Color("94abb7")); hint.autowrap_mode = TextServer.AUTOWRAP_OFF; hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 play_clip("idle")
 if not capture.is_empty():
  yaw = capture_angle; update_camera(); play_clip(capture_pose); player.seek(capture_time, true); player.pause()

func update_camera() -> void:
 var center = Vector3(1.25, .72, -.1) if chosen == "death" else Vector3(0, 1.55, -.1)
 camera.position = center + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
 camera.look_at(center)

func play_clip(clip: String) -> void:
 chosen = clip; player.stop(); player.play(clip, 0.12)
 update_camera()
 for b in pose_buttons: b.set_pressed_no_signal(b.get_meta("clip") == clip)
 if pause_button: pause_button.text = "Pause"

func toggle_pause() -> void:
 if player.is_playing(): player.pause(); pause_button.text = "Play"
 else: player.play(); pause_button.text = "Pause"

func _input(event: InputEvent) -> void:
 if event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
   dragging = event.pressed and event.position.x < size.x * .72 and event.position.y > 140 and event.position.y < size.y - 150
  if event.pressed and event.position.x < size.x * .72:
   if event.button_index == MOUSE_BUTTON_WHEEL_UP: distance = maxf(4.5, distance - .35); update_camera()
   elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance = minf(10.5, distance + .35); update_camera()
 elif event is InputEventMouseMotion and dragging:
  yaw -= event.relative.x * .008; pitch = clampf(pitch + event.relative.y * .006, -.08, .8); update_camera()
 elif event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_SPACE: toggle_pause()
  elif event.keycode == KEY_ESCAPE: get_tree().change_scene_to_file("res://scenes/main.tscn")

func _process(dt: float) -> void:
 if film:
  film_elapsed += dt
  var clip = "idle" if film_elapsed < 3 else "walk" if film_elapsed < 6 else "attack" if film_elapsed < 8 else "cast" if film_elapsed < 11 else "death" if film_elapsed < 13 else "idle"
  if chosen != clip: play_clip(clip)
  elif clip in ["attack", "cast"] and not player.is_playing(): play_clip(clip)
  yaw = .72 + film_elapsed * .12 if film_elapsed < 6 else 1.05 if film_elapsed < 13 else 2.0 - (film_elapsed - 13.0) * .32
  update_camera()
 if spinning: yaw += dt * .28; update_camera()
 if not capture.is_empty() and not captured:
  elapsed += dt
  if elapsed > 3.0:
   captured = true
   await RenderingServer.frame_post_draw
   get_viewport().get_texture().get_image().save_png(capture)
   print("KIRIN STUDIO CAPTURE ", capture, " / ", capture_pose, " @ ", capture_time)
   get_tree().quit()
