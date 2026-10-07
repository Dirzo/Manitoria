class_name AbilityPreview
extends Control
var game: Node
var hero: Dictionary
var card: Dictionary
var demo: AbilityDemo
var arena: ArenaView
var view: SubViewport
var status_label: Label
var outcome_label: Label
var scenario="Clustered"
var paused=false
var accumulator=0.0
var speed=1.0
var loop_count=0
var unlocked=false

func build() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shade=ColorRect.new();add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.color=Color(.015,.02,.05,.96)
 var frame=FantasyFrame.new();add_child(frame);frame.position=Vector2(32,112);frame.size=Vector2(1536,750);frame.accent=RarityStyle.color(card.rarity)
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",12);frame.add_child(box)
 var header=HBoxContainer.new();box.add_child(header)
 var name_label=game.label(header,("SKILL LEARNED · " if unlocked else "")+card.name,30,game.GOLD,false);name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 game.button(header,"Continue ×" if unlocked else "Back to choices ×",close)
 var body=HBoxContainer.new();body.add_theme_constant_override("separation",20);box.add_child(body)
 var left=VBoxContainer.new();left.custom_minimum_size.x=995;body.add_child(left)
 var container=SubViewportContainer.new();container.custom_minimum_size=Vector2(995,484);container.stretch=true;left.add_child(container)
 view=SubViewport.new();view.size=Vector2i(995,484);view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;container.add_child(view)
 arena=ArenaView.new();view.add_child(arena);arena.target_distance=17;arena.target_pitch=.95;arena.target_yaw=0;arena.update_camera(1)
 var layout_row=HBoxContainer.new();left.add_child(layout_row)
 var group=ButtonGroup.new()
 for layout in ["Clustered","Line","Spread"]:
  var option=game.button(layout_row,layout,func():scenario=layout;restart())
  option.toggle_mode=true;option.button_group=group;option.button_pressed=layout==scenario
 game.button(layout_row,"Replay",restart)
 var pause_button=game.button(layout_row,"Pause",func():paused=not paused)
 pause_button.pressed.connect(func():pause_button.text="Resume" if paused else "Pause")
 game.button(layout_row,"Slow motion",func():speed=.5 if speed==1 else 1)
 status_label=game.label(left,"",19,game.GOLD,false)
 var right=VBoxContainer.new();right.custom_minimum_size.x=450;right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.add_theme_constant_override("separation",12);body.add_child(right)
 var art=AbilityArt.icon(right,AbilityArt.card_key(hero,card),136);RarityStyle.decorate(art,card.rarity)
 if unlocked:
  art.pivot_offset=Vector2(68,68);art.scale=Vector2.ONE*.45;art.modulate.a=0
  var reveal=create_tween().set_parallel(true)
  reveal.tween_property(art,"scale",Vector2.ONE,.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  reveal.tween_property(art,"modulate:a",1.0,.35)
 game.label(right,"YOUR NEW SKILL" if unlocked else "AFTER CHOOSING THIS CARD" if card.type in ["ability","signature"] else ("WITH THIS EVOLUTION" if card.type=="evolution" else "SIGNATURE WITH THIS UPGRADE"),13,game.GOLD)
 game.label(right,card.description,18)
 game.label(right,"Blue allies start wounded. Red enemies stay still so you can compare coverage.",16,game.MUTED)
 outcome_label=game.label(right,"",21,game.GOLD)
 game.label(right,"Real combat rules · Current hero level\nEquipment procs excluded · Preview only",13,game.MUTED)
 restart()

func restart() -> void:
 if arena==null:return
 arena.clear_fighters();accumulator=0;loop_count+=1
 demo=AbilityDemo.new();demo.setup(hero,card,scenario)
 demo.sim.action.connect(on_event)
 arena.sync(demo.sim,1.0)

func on_event(event: Dictionary) -> void:
 arena.handle_event(event)
 if not paused:game.sound.battle_event(event,demo.sim.find_unit(int(event.get("uid",-1))),0)

func _process(dt: float) -> void:
 if demo==null or not is_instance_valid(arena):return
 if not paused:
  accumulator+=minf(dt,.1)*speed
  while accumulator>=1.0/30.0:
   demo.advance(1.0/30.0);accumulator-=1.0/30.0
  if demo.elapsed>=7.5:restart()
 arena.sync(demo.sim,minf(dt,.1),0 if paused else speed)
 var phase="Get ready" if not demo.cast_started else "Windup" if demo.caster.has("pending_cast") else "Impact & aftermath"
 status_label.text="%s · %s · %.1fs · %s"%[scenario,phase,demo.sim.time,"Paused" if paused else "½ speed" if speed<1 else "Auto replay"]
 var totals=demo.totals()
 outcome_label.text="%d damage   ·   %d healing\n%d peak shield · %d affected"%[totals.damage,totals.healing,totals.shield,totals.affected]
 if not demo.control_seen.is_empty():outcome_label.text+="\n"+", ".join(demo.control_seen.keys()).capitalize()

func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  close();get_viewport().set_input_as_handled()

func close() -> void:
 set_process(false);queue_free()
