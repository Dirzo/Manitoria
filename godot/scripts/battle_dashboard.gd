class_name BattleDashboard
extends Control
var game: Node
var rows: Dictionary = {}
var selected_uid = -1
var detail: VBoxContainer
var cooldowns: Array = []
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 for team in range(2):
  var panel = PanelContainer.new(); add_child(panel); panel.position = Vector2(26 if team == 0 else 1334, 236); panel.size = Vector2(240, 0)
  panel.add_theme_stylebox_override("panel",game.style(Color(0.025,0.06,0.085,0.92),Color("314c58"),12,12))
  var list = VBoxContainer.new(); list.add_theme_constant_override("separation",10); panel.add_child(list)
  game.label(list,"YOUR CHAMPIONS" if team == 0 else "THE OPPOSITION",12,game.GOLD)
  for u in game.sim.units:
   if u.team != team or u.summon: continue
   var row = HBoxContainer.new(); list.add_child(row)
   var portrait = TextureButton.new(); portrait.custom_minimum_size = Vector2(46,52); portrait.ignore_texture_size = true; portrait.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
   portrait.texture_normal = load("res://assets/portraits/%s.png" % u.hero.sp); row.add_child(portrait)
   portrait.tooltip_text = "Inspect " + u.hero.name; portrait.pressed.connect(func(): inspect(u.uid))
   var stack = VBoxContainer.new(); stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL; stack.add_theme_constant_override("separation",3); row.add_child(stack)
   var name_label = game.label(stack,u.hero.name,16,game.WHITE,false)
   var bar = ProgressBar.new(); bar.max_value = u.max_hp; bar.value = u.hp; bar.show_percentage = false; bar.custom_minimum_size.y = 7; stack.add_child(bar)
   bar.add_theme_stylebox_override("background",game.style(Color("263641"),Color.TRANSPARENT,3,0,0))
   bar.add_theme_stylebox_override("fill",game.style(Color("70d6bd") if team == 0 else Color("ed9c80"),Color.TRANSPARENT,3,0,0))
   var status = game.label(stack,"",11,game.MUTED,false)
   rows[u.uid] = {"bar":bar,"status":status,"portrait":portrait,"name":name_label}
 var panel = PanelContainer.new(); add_child(panel); panel.position = Vector2(385,652); panel.size = Vector2(830,127)
 panel.add_theme_stylebox_override("panel",game.style(Color(0.025,0.06,0.085,0.95),Color("395561"),12,12))
 detail = VBoxContainer.new(); detail.add_theme_constant_override("separation",7); panel.add_child(detail)
 for u in game.sim.units:
  if u.team == 0 and not u.summon: inspect(u.uid); break
func inspect(id: int) -> void:
 selected_uid = id; cooldowns.clear()
 for child in detail.get_children(): detail.remove_child(child); child.queue_free()
 var u = game.sim.find_unit(id)
 if u.is_empty(): return
 var branch = u.hero.get("evolution", "")
 game.label(detail,u.hero.name + "  /  " + HeroData.species[u.hero.sp].n + ("  ·  " + HeroData.evolution_info(u.hero).name if not branch.is_empty() else "") + "  ·  ABILITIES",13,game.GOLD,false)
 var row = HBoxContainer.new(); row.add_theme_constant_override("separation",12); detail.add_child(row)
 add_ability(row,HeroData.species[u.hero.sp].ability_name,HeroData.species[u.hero.sp].ability_description,"signature",u.hero.signature_rank)
 for key in u.hero.learned:
  var a = HeroData.learned_ability(u.hero.sp,int(key)); add_ability(row,a.name,a.description,key,int(u.hero.learned[key]))
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
 for id in rows:
  var u = game.sim.find_unit(id)
  if u.is_empty(): continue
  var row = rows[id]
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
