class_name BattleDashboard
extends Control
var game: Node
var rows: Dictionary = {}
var selected_uid = -1
var detail: VBoxContainer
var cooldowns: Array = []
var detail_panel: PanelContainer
var team_totals: Array = []
## Click a portrait to inspect a champion; the panel stays hidden otherwise.
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 visible = game.hud_stats
 for team in range(2):
  # No box: the panel fades in from its screen edge.
  HudKit.edge_fade(self, Rect2(0 if team == 0 else 1260, 200, 340, 480), team == 0, 0.78)
  var panel = PanelContainer.new(); add_child(panel); panel.position = Vector2(22 if team == 0 else 1338, 232); panel.size = Vector2(240, 0)
  panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
  var list = VBoxContainer.new(); list.add_theme_constant_override("separation",10); panel.add_child(list)
  var head = HBoxContainer.new(); list.add_child(head)
  var head_label = game.label(head,"YOUR TEAM" if team == 0 else "OPPONENTS",14,Color("e3c589"),false); head_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  head_label.add_theme_font_override("font", load(game.TITLE_FONT))
  team_totals.append(game.label(head,"0 dmg",12,Color("8fd7ff") if team == 0 else Color("ffa98f"),false))
  for u in game.sim.units:
   if u.team != team or u.summon: continue
   var row = HBoxContainer.new(); list.add_child(row)
   var portrait = TextureButton.new(); portrait.custom_minimum_size = Vector2(46,52); portrait.ignore_texture_size = true; portrait.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
   portrait.texture_normal = load("res://assets/portraits/%s.png" % u.hero.sp); row.add_child(portrait)
   portrait.tooltip_text = "Inspect " + u.hero.name; portrait.pressed.connect(func(): inspect(u.uid))
   var stack = VBoxContainer.new(); stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL; stack.add_theme_constant_override("separation",3); row.add_child(stack)
   var name_label = game.label(stack,u.hero.name,16,game.WHITE,false)
   var bar = ProgressBar.new(); bar.max_value = u.max_hp; bar.value = u.hp; bar.show_percentage = false; bar.custom_minimum_size.y = 7; stack.add_child(bar)
   bar.add_theme_stylebox_override("background",DungeonUI.skin(Color("5a4a34"),Color(0.05,0.04,0.06,0.9),3,false,1))
   bar.add_theme_stylebox_override("fill",DungeonUI.skin(Color(0,0,0,0),Color("70d6bd") if team == 0 else Color("ed9c80"),3,false,0))
   # Live damage meter: scaled to the biggest hitter on the field.
   var dmg_row = HBoxContainer.new(); dmg_row.add_theme_constant_override("separation",4); stack.add_child(dmg_row)
   var dmg = ProgressBar.new(); dmg.max_value = 1; dmg.value = 0; dmg.show_percentage = false; dmg.custom_minimum_size = Vector2(110,6); dmg.size_flags_vertical = Control.SIZE_SHRINK_CENTER; dmg_row.add_child(dmg)
   dmg.add_theme_stylebox_override("background",game.style(Color(0,0,0,0.25),Color.TRANSPARENT,2,0,0))
   dmg.add_theme_stylebox_override("fill",game.style(Color("5fb7d9") if team == 0 else Color("e0735f"),Color.TRANSPARENT,2,0,0))
   var dmg_label = game.label(dmg_row,"0",11,Color("c9d6dc"),false)
   var status = game.label(stack,"",11,game.MUTED,false); status.visible = false
   rows[u.uid] = {"bar":bar,"status":status,"portrait":portrait,"name":name_label,"dmg":dmg,"dmg_label":dmg_label,"team":team}
 var panel = PanelContainer.new(); add_child(panel); panel.position = Vector2(385,652); panel.size = Vector2(830,127)
 panel.add_theme_stylebox_override("panel",DungeonUI.skin(Color("8a6a3a"),Color(0.05,0.04,0.07,0.94),8,true,2))
 detail = VBoxContainer.new(); detail.add_theme_constant_override("separation",7); panel.add_child(detail)
 detail_panel = panel; panel.visible = false
 var hint = game.label(self,"Click a portrait to inspect",12,Color(1,1,1,0.45),false); hint.position = Vector2(26,560)
func inspect(id: int) -> void:
 if id == selected_uid and detail_panel.visible:
  detail_panel.visible = false; selected_uid = -1; return
 detail_panel.visible = true
 selected_uid = id; cooldowns.clear()
 for child in detail.get_children(): detail.remove_child(child); child.queue_free()
 var u = game.sim.find_unit(id)
 if u.is_empty(): return
 var branch = u.hero.get("evolution", "")
 var top = HBoxContainer.new(); detail.add_child(top)
 game.label(top,u.hero.name + "  /  " + HeroData.species[u.hero.sp].n + ("  ·  " + HeroData.evolution_info(u.hero).name if not branch.is_empty() else ""),13,game.GOLD,false).size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var close = HudKit.medallion(top,game,"close","","Close",func(): detail_panel.visible = false; selected_uid = -1,false,32)
 var row = HBoxContainer.new(); row.add_theme_constant_override("separation",12); detail.add_child(row)
 add_ability(row,HeroData.species[u.hero.sp].ability_name,HeroData.signature_summary(u.hero.sp)+"\n\n"+HeroData.species[u.hero.sp].ability_description,"signature",u.hero.signature_rank)
 for key in u.hero.learned:
  var a = HeroData.learned_ability(u.hero.sp,int(key)); add_ability(row,a.name,a.summary+"\n\n"+a.description,key,int(u.hero.learned[key]))
 for i in range(maxi(0,HeroData.ABILITY_SLOTS-1-u.hero.learned.size())):
  var empty = game.label(row,"UNDISCOVERED\nEarn an arena level",12,game.MUTED); empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
func add_ability(row: HBoxContainer, title: String, description: String, key: String, rank: int) -> void:
 var stack = VBoxContainer.new(); stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL; stack.add_theme_constant_override("separation",3); row.add_child(stack)
 var heading=HBoxContainer.new(); stack.add_child(heading)
 var unit=game.sim.find_unit(selected_uid)
 var art_key=HeroData.species[unit.hero.sp].ab if key=="signature" else "discovery:%s:%s" % [unit.hero.sp,key]
 var art=AbilityArt.icon(heading,art_key,34); art.tooltip_text=description
 RarityStyle.decorate(art,RarityStyle.for_skill(unit.hero,"signature" if key=="signature" else "ability:"+key))
 var title_label = game.label(heading,title,13,RarityStyle.color(RarityStyle.for_skill(unit.hero,"signature" if key=="signature" else "ability:"+key))); title_label.tooltip_text = description; title_label.custom_minimum_size.x = 110; title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var status = game.label(stack,"RANK %d" % rank,11,game.GOLD,false)
 var bar = ProgressBar.new(); bar.max_value = 1; bar.value = 1; bar.show_percentage = false; bar.custom_minimum_size.y = 4; stack.add_child(bar)
 bar.add_theme_stylebox_override("background",game.style(Color("293d49"),Color.TRANSPARENT,2,0,0))
 bar.add_theme_stylebox_override("fill",game.style(game.GOLD,Color.TRANSPARENT,2,0,0))
 var totals = game.label(stack,"0 DMG  ·  0 HEAL",11,game.MUTED,false)
 cooldowns.append({"totals":totals,"key":key,"rank":rank,"status":status,"bar":bar})
func _process(dt: float) -> void:
 if not is_instance_valid(game) or game.sim == null: return
 var top_dmg = 1.0; var totals = [0.0, 0.0]
 for id in rows:
  var uu = game.sim.find_unit(id)
  if uu.is_empty(): continue
  top_dmg = maxf(top_dmg, uu.damage); totals[rows[id].team] += uu.damage
 for t in range(mini(2, team_totals.size())):
  team_totals[t].text = ("%.1fk dmg" % (totals[t] / 1000.0)) if totals[t] >= 1000 else ("%d dmg" % totals[t])
 for id in rows:
  var u = game.sim.find_unit(id)
  if u.is_empty(): continue
  var row = rows[id]
  row.dmg.value = lerpf(row.dmg.value, u.damage / top_dmg, 1 - exp(-dt * 6))
  row.dmg_label.text = ("%.1fk" % (u.damage / 1000.0)) if u.damage >= 1000 else str(roundi(u.damage))
  row.bar.value = lerpf(row.bar.value,u.hp,1-exp(-dt*14))
  row.status.text = "%d / %d HP%s" % [ceili(u.hp),ceili(u.max_hp),"  +%d" % ceili(u.shield) if u.shield > 0 else ""] if u.alive else "FALLEN"
  row.portrait.modulate = Color.WHITE if u.alive else Color(0.35,0.4,0.45)
  row.name.modulate = Color.WHITE if id == selected_uid else Color(0.8,0.88,0.92)
 var u = game.sim.find_unit(selected_uid)
 if u.is_empty(): return
 for card in cooldowns:
  var remaining = u.cd if card.key == "signature" else u.ability_cds.get(card.key,0.0)
  var total = CombatPacing.signature_cd(u.hero) if card.key == "signature" else CombatPacing.ability_cd(u.hero, card.key)
  card.bar.value = clampf(1-remaining/total,0,1)
  card.status.text = "FALLEN" if not u.alive else "RANK %d  ·  %.1fs" % [card.rank,remaining] if remaining > 0 else "RANK %d  ·  READY" % card.rank
  var credit = "signature" if card.key == "signature" else "ability:" + card.key
  var stats = u.ability_stats.get(credit,{})
  card.totals.text = "%d DMG  ·  %d HEAL" % [roundi(stats.get("damage",0)),roundi(stats.get("healing",0))]
  if u.alive and u.has("pending_cast") and u.pending_cast.credit == credit:
   card.status.text = "CASTING  %.1fs" % maxf(0,u.pending_cast.delay)
   card.bar.value = 1-u.pending_cast.delay/u.pending_cast.total
