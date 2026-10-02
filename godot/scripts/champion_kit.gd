class_name ChampionKit
extends RefCounted

static func entries(hero: Dictionary) -> Array:
 var sp=HeroData.species[hero.sp]
 var list=[{"name":sp.ability_name,"summary":HeroData.signature_summary(hero.sp),"description":sp.ability_description,"rank":hero.signature_rank,"art":sp.ab,"rarity":RarityStyle.for_skill(hero,"signature"),"cooldown":CombatPacing.signature_cd(hero),"signature":true}]
 for key in hero.learned:
  var ability=HeroData.learned_ability(hero.sp,int(key))
  list.append({"name":ability.name,"summary":ability.summary,"description":ability.description,"rank":int(hero.learned[key]),"art":"discovery:%s:%s"%[hero.sp,key],"rarity":RarityStyle.for_skill(hero,"ability:"+key),"cooldown":CombatPacing.ability_cd(hero,key),"signature":false})
 return list

static func build(game: Node,parent: Node,hero: Dictionary,height: int=235) -> void:
 var head=HBoxContainer.new();parent.add_child(head)
 var title=game.label(head,"CURRENT ABILITIES · %d / 4"%(hero.learned.size()+1),13,game.GOLD,false);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 FlowUI.detail_toggle(game,head)
 var detailed=FlowUI.detailed(game)
 title.tooltip_text="Only learned abilities are shown. Read the effects before selecting equipment."
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=height;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;parent.add_child(scroll);scroll.name="ChampionAbilities"
 var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",12);scroll.add_child(column)
 for entry in entries(hero):
  var row=HBoxContainer.new();row.add_theme_constant_override("separation",10);column.add_child(row)
  var icon=AbilityArt.icon(row,entry.art,48);icon.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;RarityStyle.decorate(icon,entry.rarity)
  var text=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(text)
  game.label(text,entry.name+" · R%d"%entry.rank,17,RarityStyle.color(entry.rarity))
  var sm=game.label(text,entry.summary,15,game.WHITE);sm.mouse_filter=Control.MOUSE_FILTER_STOP
  var info=("Signature" if entry.signature else "Learned")+" · "+entry.rarity
  if entry.cooldown>0:info+=" · %.1fs"%entry.cooldown
  if entry.rank>1:info+=" · +%d%% from rank"%((entry.rank-1)*20)
  var det=game.label(text,info+"  ·  details ▾",12,game.MUTED);det.mouse_filter=Control.MOUSE_FILTER_STOP
  var tip=entry.description+"\n"+info
  sm.tooltip_text=tip;det.tooltip_text=tip;icon.tooltip_text=tip
  # Click "details" to unfold the full text in place.
  var full=game.label(text,entry.description,14,Color("c9d6dc"));full.visible=detailed
  if detailed:det.text=info+"  ·  details ▴"
  det.gui_input.connect(func(ev):
   if ev is InputEventMouseButton and ev.pressed and ev.button_index==MOUSE_BUTTON_LEFT:full.visible=not full.visible;det.text=info+("  ·  details ▴" if full.visible else "  ·  details ▾"))
 if not hero.get("evolution","").is_empty():
  var evolution=HeroData.evolution_info(hero);game.label(column,evolution.name,17,game.GOLD);game.label(column,evolution.description,15)
