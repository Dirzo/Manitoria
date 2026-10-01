class_name ChampionKit
extends RefCounted

static func entries(hero: Dictionary) -> Array:
 var sp=HeroData.species[hero.sp]
 var list=[{"name":sp.ability_name,"description":sp.ability_description,"rank":hero.signature_rank,"art":sp.ab,"rarity":RarityStyle.for_skill(hero,"signature"),"cooldown":CombatPacing.signature_cd(hero),"signature":true}]
 for key in hero.learned:
  var ability=HeroData.learned_ability(hero.sp,int(key))
  list.append({"name":ability.name,"description":ability.description,"rank":int(hero.learned[key]),"art":"discovery:%s:%s"%[hero.sp,key],"rarity":RarityStyle.for_skill(hero,"ability:"+key),"cooldown":CombatPacing.ability_cd(hero,key),"signature":false})
 return list

static func build(game: Node,parent: Node,hero: Dictionary,height: int=235) -> void:
 var title=game.label(parent,"CURRENT ABILITIES · %d / 4"%(hero.learned.size()+1),13,game.GOLD,false)
 title.tooltip_text="Only learned abilities are shown. Read the effects before selecting equipment."
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=height;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;parent.add_child(scroll);scroll.name="ChampionAbilities"
 var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",12);scroll.add_child(column)
 for entry in entries(hero):
  var row=HBoxContainer.new();row.add_theme_constant_override("separation",10);column.add_child(row)
  var icon=AbilityArt.icon(row,entry.art,48);icon.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;RarityStyle.decorate(icon,entry.rarity)
  var text=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(text)
  game.label(text,entry.name+" · R%d"%entry.rank,17,RarityStyle.color(entry.rarity))
  game.label(text,("Base effect: " if entry.rank>1 else "")+entry.description,15,game.WHITE)
  var info=("Signature" if entry.signature else "Learned")+" · "+entry.rarity
  if entry.cooldown>0:info+=" · %.1fs cooldown"%entry.cooldown
  if entry.rank>1:info+=" · Rank bonus +20% potency"
  game.label(text,info,12,game.MUTED)
 if not hero.get("evolution","").is_empty():
  var evolution=HeroData.evolution_info(hero);game.label(column,evolution.name,17,game.GOLD);game.label(column,evolution.description,15)
