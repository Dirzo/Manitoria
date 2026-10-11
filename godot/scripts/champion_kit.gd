class_name ChampionKit
extends RefCounted
## v0.76: a champion's kit is one signature ability, cast when its mana bar fills.

static func entries(hero: Dictionary) -> Array:
 var sp=HeroData.species[hero.sp]
 var sig=Signatures.of(hero.sp)
 var m=Signatures.mana(hero)
 return [{"name":sig.name,"summary":Signatures.fill(str(sig.text),hero,HeroData.stats(hero)),"description":Signatures.description(hero),"rank":1,"art":sp.ab,"rarity":"Signature","mana":m,"builds":sig.builds,"signature":true}]

static func build(game: Node,parent: Node,hero: Dictionary,height: int=235) -> void:
 var head=HBoxContainer.new();parent.add_child(head)
 var title=game.label(head,"SIGNATURE ABILITY",13,game.GOLD,false);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 title.tooltip_text="Cast every time the mana bar fills. Mana comes from basic attacks (+10) and from taking damage."
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=height;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;parent.add_child(scroll);scroll.name="ChampionAbilities"
 var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",6);scroll.add_child(column)
 for entry in entries(hero):
  row(game,column,entry,true)
 evolutions(game,column,hero)

## The signature as a card: icon, name, mana, what it builds into, and the live text.
static func row(game: Node,parent: Node,entry: Dictionary,detailed: bool) -> void:
 var line=HBoxContainer.new();line.add_theme_constant_override("separation",10);parent.add_child(line)
 var icon=AbilityArt.icon(line,entry.art,48);icon.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 var text=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",2);line.add_child(text)
 var head=HBoxContainer.new();text.add_child(head)
 var nm=game.label(head,entry.name,17,game.GOLD,false);nm.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 game.label(head,"Mana %d / %d"%[entry.mana[0],entry.mana[1]],12,Color("6fb8ff"),false)
 game.label(text,"Builds: "+str(entry.builds),12,Color("bba2ff"))
 var body=game.label(text,entry.description if detailed else entry.summary,13,game.WHITE)
 body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var tip=entry.name+"\n"+entry.description+"\nCast when the mana bar fills: +10 mana per basic attack, plus mana from damage taken. The Mana stat multiplies all mana earned."
 for c in [icon,nm,body]:c.tooltip_text=tip;c.mouse_filter=Control.MOUSE_FILTER_STOP

## The evolution taken, or the three it can take at level HeroData.EVOLVE_LEVEL.
static func evolutions(game: Node,parent: Node,hero: Dictionary) -> void:
 var taken=str(hero.get("evolution",""))
 if Evolutions.has(taken):
  var e=Evolutions.entry(taken)
  game.label(parent,"EVOLUTION · %s · %s"%[e.name,e.tag],14,Color(str(e.color)))
  var t=game.label(parent,Evolutions.text(taken,hero),13,game.MUTED);t.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  return
 game.label(parent,"EVOLUTIONS · choose one at level %d"%HeroData.EVOLVE_LEVEL,13,game.GOLD)
 for key in Evolutions.options(hero.sp):
  var e=Evolutions.entry(key)
  var t=game.label(parent,"%s (%s): %s"%[e.name,e.tag,Evolutions.text(key)],12,game.MUTED);t.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
