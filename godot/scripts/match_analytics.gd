class_name MatchAnalytics
extends VBoxContainer
var game: Node
var report: Dictionary
var metric = "damage"
var team_filter = 0
var selected_id = ""
var detail_mode = "Timeline"
const COLORS = {"damage":Color("e7bb79"),"healing":Color("7de0c1"),"taken":Color("ed9d80"),"blocked":Color("9fb8f4")}
func _ready() -> void: rebuild()
func text(parent: Node, value: String, size_value: int = 16, color: Color = Color("eef0e8")) -> Label:
 return game.label(parent,value,size_value,color)
func rebuild() -> void:
 for child in get_children(): remove_child(child); child.queue_free()
 add_theme_constant_override("separation",12)
 var controls = HBoxContainer.new(); add_child(controls)
 for entry in [["damage","Damage dealt"],["healing","Healing"],["taken","Damage taken"],["blocked","Damage blocked"]]:
  game.button(controls,entry[1],func(): metric = entry[0]; rebuild(),metric == entry[0],entry[0] == "taken" and not report.rows[0].has("taken"))
 var teams = OptionButton.new(); controls.add_child(teams)
 for title in ["Your club","Opposition","All heroes"]: teams.add_item(title)
 teams.selected = team_filter; teams.item_selected.connect(func(i): team_filter=i; selected_id=""; rebuild())
 var total_row = HBoxContainer.new(); add_child(total_row)
 for key in ["damage","healing","taken"]:
  var total = 0.0
  for hero in report.rows:
   if team_filter == 2 or int(hero.team) == team_filter: total += hero.get(key,0.0)
  var box = VBoxContainer.new(); box.size_flags_horizontal = Control.SIZE_EXPAND_FILL; total_row.add_child(box)
  text(box,{"damage":"DAMAGE DEALT","healing":"EFFECTIVE HEALING","taken":"HEALTH DAMAGE TAKEN"}[key],12,COLORS[key])
  text(box,"%s   /   %.1f per second" % [str(roundi(total)) if key != "taken" or report.rows[0].has("taken") else "Unavailable",total/maxf(1,report.duration)],24,COLORS[key])
 text(self,"Damage is actual health lost after mitigation; shields are separate. Summons are credited to their owner.",12,game.MUTED)
 var split = HBoxContainer.new(); split.add_theme_constant_override("separation",24); add_child(split)
 var left = VBoxContainer.new(); left.custom_minimum_size.x=470; left.add_theme_constant_override("separation",6); split.add_child(left)
 text(left,"HERO PERFORMANCE · SELECT A HERO",12,game.GOLD)
 var heroes = report.rows.filter(func(h): return team_filter == 2 or int(h.team) == team_filter)
 heroes.sort_custom(func(a,b): return a.get(metric,0)>b.get(metric,0))
 if selected_id.is_empty() or not heroes.any(func(h): return h.id == selected_id): selected_id = heroes[0].id
 var max_value = maxf(1,heroes[0].get(metric,0))
 for hero in heroes:
  var row = HBoxContainer.new(); row.add_theme_constant_override("separation",10); left.add_child(row)
  var picture = TextureButton.new(); picture.custom_minimum_size=Vector2(45,42); picture.ignore_texture_size=true; picture.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED; picture.texture_normal=load("res://assets/portraits/%s.png" % hero.sp); row.add_child(picture); picture.pressed.connect(func(): selected_id=hero.id; rebuild())
  var stack = VBoxContainer.new(); stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL; stack.add_theme_constant_override("separation",3); row.add_child(stack)
  var select = game.button(stack,"%s   ·   %d" % [hero.name,roundi(hero.get(metric,0))],func(): selected_id=hero.id; rebuild(),hero.id==selected_id); select.custom_minimum_size.y=30; select.add_theme_font_size_override("font_size",14)
  select.add_theme_stylebox_override("normal",game.style(game.GOLD if hero.id==selected_id else Color("203744"),Color("54727d"),8,6))
  var bar = ProgressBar.new(); stack.add_child(bar); bar.max_value=max_value; bar.show_percentage=false; bar.custom_minimum_size.y=7
  bar.add_theme_stylebox_override("background",game.style(Color("243a46"),Color.TRANSPARENT,3,0,0)); bar.add_theme_stylebox_override("fill",game.style(COLORS[metric],Color.TRANSPARENT,3,0,0))
  create_tween().tween_property(bar,"value",float(hero.get(metric,0)),0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  picture.tooltip_text="%s · %d kills · %s" % [HeroData.species[hero.sp].n,hero.kills,"Survived" if hero.alive else "Fallen"]
 var right = VBoxContainer.new(); right.size_flags_horizontal=Control.SIZE_EXPAND_FILL; right.add_theme_constant_override("separation",8); split.add_child(right)
 var hero = heroes.filter(func(h): return h.id == selected_id)[0]
 text(right,hero.name+" · "+HeroData.species[hero.sp].n,23,game.GOLD)
 text(right,"%d dealt  ·  %d healed  ·  %s taken  ·  %d blocked  ·  %d kills" % [roundi(hero.damage),roundi(hero.healing),str(roundi(hero.taken)) if hero.has("taken") else "?",roundi(hero.blocked),hero.kills],14)
 if hero.has("healing_received"): text(right,"Healing received: %d · Effective healing excludes overheal." % roundi(hero.healing_received),12,game.MUTED)
 if not hero.has("ability_stats"):
  text(right,"This older report has totals only. Detailed ability tracking starts with your next match.",17,game.MUTED); return
 var tabs=HBoxContainer.new(); right.add_child(tabs)
 for mode in ["Timeline","Abilities"]:
  var tab=game.button(tabs,mode,func(): detail_mode=mode; rebuild(),detail_mode==mode); tab.add_theme_font_size_override("font_size",13); tab.custom_minimum_size.y=32
 if detail_mode == "Timeline":
  var graph_metric = metric
  var legend=HBoxContainer.new(); right.add_child(legend)
  game.label(legend,"YOUR CLUB",11,Color("7de0c1"),false); game.label(legend,"OPPOSITION · CUMULATIVE "+graph_metric.to_upper(),11,Color("ed9d80"),false)
  var graph=CombatGraph.new(); graph.rows=report.rows; graph.metric=graph_metric; graph.duration=report.duration; right.add_child(graph)
  return
 text(right,"ABILITY BREAKDOWN   /   USES · DAMAGE · HEALING · OVERHEAL",12,game.GOLD)
 var keys = hero.ability_stats.keys().filter(func(k): return k != "incoming")
 keys.sort_custom(func(a,b): return hero.ability_stats[a].get("damage",0)+hero.ability_stats[a].get("healing",0)>hero.ability_stats[b].get("damage",0)+hero.ability_stats[b].get("healing",0))
 for key in keys:
  var values = hero.ability_stats[key]; var info=AbilityArt.metric_info(hero.sp,key)
  var row=HBoxContainer.new(); right.add_child(row)
  var icon=TextureRect.new(); icon.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS; icon.texture=AbilityArt.texture(info.art); icon.custom_minimum_size=Vector2(44,44); icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; row.add_child(icon)
  var stack=VBoxContainer.new(); stack.add_theme_constant_override("separation",2); stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(stack)
  text(stack,info.name,16)
  text(stack,"%d uses   ·   %d damage   ·   %d healed   ·   %d overheal" % [values.get("casts",0),roundi(values.get("damage",0)),roundi(values.get("healing",0)),roundi(values.get("overheal",0))],12,game.MUTED)

  if values.get("shielding",0)>0 or values.get("shield_break",0)>0:
   text(stack,"%d shielding granted · %d shield broken" % [roundi(values.get("shielding",0)),roundi(values.get("shield_break",0))],12,game.MUTED)

  if values.get("healing_denied",0)>0:text(stack,"%d effective healing denied"%roundi(values.healing_denied),12,game.MUTED)
  if values.get("cooldown_recovered",0)>0:text(stack,"%.1fs signature cooldown recovered"%values.cooldown_recovered,12,game.MUTED)

  if values.get("mitigated",0)>0:text(stack,"%d damage reduced before armor"%roundi(values.mitigated),12,game.MUTED)
