class_name ChampionKit
extends RefCounted

static func entries(hero: Dictionary) -> Array:
 var sp=HeroData.species[hero.sp]
 var list=[{"name":sp.ability_name,"summary":HeroData.signature_summary(hero.sp),"description":sp.ability_description,"rank":hero.signature_rank,"art":sp.ab,"rarity":RarityStyle.for_skill(hero,"signature"),"cooldown":CombatPacing.signature_cd(hero),"signature":true}]
 for key in hero.learned:
  var ability=HeroData.learned_ability(hero.sp,int(key))
  list.append({"name":ability.name,"summary":ability.summary,"description":ability.description,"rank":int(hero.learned[key]),"art":"discovery:%s:%s"%[hero.sp,key],"rarity":RarityStyle.for_skill(hero,"ability:"+key),"cooldown":CombatPacing.ability_cd(hero,key),"signature":false})
 # An evolution's own ability joins the kit.
 var gi=Evolutions.grant_index(str(hero.get("evolution","")))
 if gi>=0:
  var g=HeroData.learned_ability(hero.sp,gi)
  list.append({"name":g.name,"summary":"EVOLUTION · "+g.summary,"description":g.description,"rank":1,"art":g.effect,"rarity":"Rare","cooldown":g.cooldown,"signature":false})
 return list

static func build(game: Node,parent: Node,hero: Dictionary,height: int=235) -> void:
 var head=HBoxContainer.new();parent.add_child(head)
 var title=game.label(head,"CURRENT ABILITIES · %d / 4"%(hero.learned.size()+1),13,game.GOLD,false);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var detailed=FlowUI.detailed(game)
 title.tooltip_text="Only learned abilities are shown. Read the effects before selecting equipment."
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=height;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;parent.add_child(scroll);scroll.name="ChampionAbilities"
 var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",6);scroll.add_child(column)
 for entry in entries(hero):
  row(game,column,entry,detailed)
 if not hero.get("evolution","").is_empty():
  var evolution=HeroData.evolution_info(hero);game.label(column,evolution.name,17,game.GOLD);game.label(column,evolution.description,15)

## One compact line per skill: icon, name and rank, one-line summary, then rarity and cooldown.
## With "Detailed descriptions" on, the full text sits under the summary.
static func row(game: Node,parent: Node,entry: Dictionary,detailed: bool) -> void:
 var line=HBoxContainer.new();line.add_theme_constant_override("separation",10);parent.add_child(line)
 var icon=AbilityArt.icon(line,entry.art,40);icon.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;RarityStyle.decorate(icon,entry.rarity)
 var text=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",0);line.add_child(text)
 var head=HBoxContainer.new();text.add_child(head)
 var nm=game.label(head,entry.name+" · R%d"%entry.rank,15,RarityStyle.color(entry.rarity),false);nm.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var info=("Signature" if entry.signature else entry.rarity)
 if entry.cooldown>0:info+=" · %.1fs"%entry.cooldown
 game.label(head,info,11,game.MUTED,false)
 var sm=game.label(text,entry.summary,13,game.WHITE,false);sm.clip_text=true;sm.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;sm.custom_minimum_size.x=60
 var tip=entry.name+"\n"+entry.description+"\n"+info+(" · +%d%% from rank"%((entry.rank-1)*20) if entry.rank>1 else "")
 for c in [icon,nm,sm]:c.tooltip_text=tip;c.mouse_filter=Control.MOUSE_FILTER_STOP
 if detailed:game.label(text,entry.description,12,Color("c9d6dc"))
