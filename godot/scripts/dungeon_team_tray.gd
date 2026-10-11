class_name DungeonTeamTray
extends Control
## Map-side management reuses the campaign's existing equipment and formation actions.
var game: Node
var desk: ManagementDesk
var frame: PanelContainer
var opened=false
var pinned=false
var outside_time=0.0
var motion: Tween
var pointer_position=Vector2(-1,-1)
var hover_armed=true
const HEIGHT=366.0
const HANDLE=44.0
func _ready() -> void:
 name="DungeonTeamTray";mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 pinned=game.desk_state.get("dungeon_tray_pinned",false)
 opened=game.desk_state.get("dungeon_tray_open",false) or pinned
 pointer_position=game.desk_state.get("dungeon_tray_pointer",Vector2(-1,-1))
 hover_armed=game.desk_state.get("dungeon_tray_hover_armed",true)
 GearUI.selected(game)
 frame=PanelContainer.new();frame.name="TeamTrayFrame";add_child(frame)
 frame.position=Vector2(26,expanded_y() if opened else collapsed_y());frame.size=Vector2(1548,HEIGHT)
 frame.add_theme_stylebox_override("panel",game.style(Color("131c24"),game.GOLD,10,10,2))
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",6);frame.add_child(box)
 var head=HBoxContainer.new();head.custom_minimum_size.y=HANDLE-20;box.add_child(head)
 var title=game.label(head,"CHAMPIONS & FORGE  ·  hover here to plan your team",16,game.GOLD,false);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var toggle=game.button(head,"Open / close",toggle_open);toggle.name="TeamTrayToggle";toggle.custom_minimum_size.y=28;toggle.add_theme_font_size_override("font_size",13)
 var pin=game.button(head,"Unpin" if pinned else "Pin open",func():
  pinned=not pinned;game.desk_state.dungeon_tray_pinned=pinned;pin_text();set_open(pinned or opened))
 pin.name="TeamTrayPin";pin.custom_minimum_size.y=28;pin.add_theme_font_size_override("font_size",13)
 var scroll=ScrollContainer.new();scroll.name="TeamTrayScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;box.add_child(scroll)
 var row=HBoxContainer.new();row.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_theme_constant_override("separation",18);scroll.add_child(row)
 roster(row);champion(row);inventory(row)
func collapsed_y() -> float:return get_viewport_rect().size.y-HANDLE
func expanded_y() -> float:return get_viewport_rect().size.y-HEIGHT-12
func pin_text() -> void:
 (find_child("TeamTrayPin",true,false) as Button).text="Unpin" if pinned else "Pin open"
func toggle_open() -> void:
 if opened:
  pinned=false;game.desk_state.dungeon_tray_pinned=false;pin_text()
  hover_armed=false;game.desk_state.dungeon_tray_hover_armed=false
  set_open(false)
 else:set_open(true)
func set_open(value: bool) -> void:
 opened=value;game.desk_state.dungeon_tray_open=value;outside_time=0
 if motion and motion.is_running():motion.kill()
 motion=create_tween();motion.tween_property(frame,"position:y",expanded_y() if value else collapsed_y(),.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
func _input(event: InputEvent) -> void:
 if event is InputEventMouse:
  pointer_position=event.position;game.desk_state.dungeon_tray_pointer=pointer_position
func _process(dt: float) -> void:
 if not is_instance_valid(frame):return
 var inside=frame.get_global_rect().has_point(pointer_position)
 if inside:
  outside_time=0
  if not opened and hover_armed:set_open(true)
 else:
  hover_armed=true;game.desk_state.dungeon_tray_hover_armed=true
  if opened and not pinned and not get_viewport().gui_is_dragging():
   outside_time+=dt
   if outside_time>.55:set_open(false)
 # Keep the drawer against the viewport edge when the window changes shape.
 if not motion or not motion.is_running():frame.position.y=expanded_y() if opened else collapsed_y()
func column(parent: Node,width: float) -> VBoxContainer:
 var col=VBoxContainer.new();col.custom_minimum_size.x=width;col.add_theme_constant_override("separation",6);parent.add_child(col);return col
func compact_button(parent: Node,title: String,action: Callable,id: String="") -> Button:
 var b=game.button(parent,title,action);b.custom_minimum_size.y=30;b.add_theme_font_size_override("font_size",13)
 if id!="":b.name=id
 return b
func roster(parent: Node) -> void:
 var col=column(parent,390);game.label(col,"YOUR TEAM · select a champion",14,game.GOLD,false)
 var roster_scroll=ScrollContainer.new();roster_scroll.name="TrayRosterScroll";roster_scroll.custom_minimum_size.y=90;roster_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(roster_scroll)
 var flow=HFlowContainer.new();flow.size_flags_horizontal=Control.SIZE_EXPAND_FILL;roster_scroll.add_child(flow)
 for h in game.campaign.state.roster:
  var face=GearUI.hero_button(game,flow,h,54);face.name="TrayHero_"+h.id
  for label_node in face.find_children("*","Label",true,false):label_node.clip_text=true;label_node.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  face.tooltip_text=h.name+" · "+HeroData.species[h.sp].n+" · select or drop equipment here"
 game.label(col,"FORMATION · select a hero, then click a position",12,game.MUTED)
 var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",4);grid.add_theme_constant_override("v_separation",3);col.add_child(grid)
 for slot in range(15):
  var here=game.campaign.lineup().filter(func(h):return int(h.slot)==slot)
  var text=here[0].name if not here.is_empty() else ["Back","Middle","Front"][slot%3]+" · %d"%(slot/3+1)
  var b=compact_button(grid,text,func():game.place_hero(game.selected_id,slot),"TrayFormation%d"%slot)
  b.custom_minimum_size.x=120;b.clip_text=true;b.tooltip_text="Move the selected champion here, or swap with its occupant."
func champion(parent: Node) -> void:
 var col=column(parent,430);var h=GearUI.selected(game)
 if h.is_empty():game.label(col,"Your roster is empty.",16);return
 game.label(col,h.name+" · Lv %d · %s"%[h.level,HeroData.species[h.sp].n],18,game.GOLD)
 var s=HeroData.stats(h)
 game.label(col,"%d HP · %d AD · %d AP · %d%% armor"%[s.hp,s.attack,s.ability_power,s.armor*100],13,game.WHITE,false)
 var gear=HBoxContainer.new();gear.add_theme_constant_override("separation",6);col.add_child(gear)
 for key in GearUI.slot_keys(h):GearUI.slot(game,gear,h,key,48)
 game.label(col,"Click a slot to equip, remove or transfer.\nDrop a component onto a loose component to forge.",12,game.MUTED)
 var tools=HBoxContainer.new();col.add_child(tools)
 compact_button(tools,"Hero details",func():desk.profile(h,true),"TrayDetails")
 compact_button(tools,"Tactics",func():game.show_tactics(h.id),"TrayTactics")
 compact_button(tools,"Bench",func():
  if game.campaign.bench(h.id):game.render(),"TrayBench")
 compact_button(tools,"Standard formation",func():
  if game.campaign.standard_formation():game.render(),"TrayStandard")
 game.label(col,BattleTactics.summary(h),12,game.MUTED)
func inventory(parent: Node) -> void:
 var col=column(parent,620);col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var h=GearUI.selected(game)
 if h.is_empty():return
 GearUI.bag(game,col,h,true)
 game.label(col,"Click an item to equip the selected champion. Drag to another portrait or slot. Right-click for details. Forge uses your bag components.",13,game.MUTED)
 var options=GearUI.forgeable(game.campaign)
 game.label(col,"%d items in your bag · %d available recipes"%[game.campaign.state.inventory.size(),options.size()],14,game.GOLD,false)
 if not options.is_empty():
  var option=options[0];var made=Forge.info(option[2])
  game.label(col,"Ready to forge: "+made.name,14,game.WHITE)
  compact_button(col,"Forge "+made.name,func():
   var result=game.campaign.forge_bag(option[0],option[1])
   if result!="":game.sound.cue("upgrade",true);game.toast("Forged "+made.name);game.render()
   else:game.toast(game.campaign.last_error),"TrayForgeReady")
