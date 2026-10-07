class_name GearUI
extends RefCounted
## Forge items UI: three slots per champion, a bag, drag-and-drop, forging and the recipe book.
const SLOT_KEYS=["0","1","2","3","4"]
static func slot_keys(h: Dictionary) -> Array:
 return SLOT_KEYS.slice(0,HeroData.item_slots(h))

static func selected(game: Node) -> Dictionary:
 var hero=game.campaign.hero_by_id(game.selected_id)
 if hero.is_empty() or hero not in game.campaign.state.roster:
  if game.campaign.state.roster.is_empty():return {}
  hero=game.campaign.state.roster[0];game.selected_id=hero.id
 return hero

static func stock_ok(c: Campaign,index: int) -> bool:
 return c.state.has("tour") and c.state.tour.shop and index>=0 and index<c.state.tour.stock.size() and str(c.state.tour.stock[index])!=""

## Would this item fit on the champion (free slot, or forging with a loose component)?
static func fits(hero: Dictionary,item_id: String) -> bool:
 var eq=hero.get("equipment",{})
 if eq.size()<HeroData.item_slots(hero):return true
 if Forge.is_component(item_id):
  for k in eq:
   if Forge.is_component(str(eq[k])) and Forge.combine(str(eq[k]),item_id)!="":return true
 return false

static func can_drop(game: Node,data: Variant,hero_id: String,_slot: String="",bag: bool=false) -> bool:
 if game==null or game.phase not in ["shop","hub","prep"] or not data is Dictionary:return false
 var id=str(data.get("id",""))
 if not Forge.valid(id):return false
 var c: Campaign=game.campaign;var kind=str(data.get("kind",""))
 if kind=="bag" and id not in c.state.inventory:return false
 elif kind=="equipped":
  var owner=c.hero_by_id(str(data.get("owner","")))
  if owner not in c.state.roster or str(owner.get("equipment",{}).get(str(data.get("slot","")),""))!=id:return false
 elif kind=="offer":
  if not stock_ok(c,int(data.get("index",-1))) or c.state.gold<Forge.info(id).price:return false
 elif kind!="bag":return false
 if bag:return kind=="equipped"
 var hero=c.hero_by_id(hero_id)
 if kind=="offer":return hero in c.state.roster
 var swap_ok=kind=="equipped" and _slot in slot_keys(hero) and hero.get("equipment",{}).has(_slot)
 return hero in c.state.roster and (kind!="equipped" or data.owner!=hero_id) and (fits(hero,id) or swap_ok)

static func apply_drop(game: Node,data: Dictionary,hero_id: String,_slot: String="",bag: bool=false) -> bool:
 if not can_drop(game,data,hero_id,_slot,bag):
  var h=game.campaign.hero_by_id(hero_id)
  if not h.is_empty() and not fits(h,str(data.get("id",""))):game.toast("%s already carries three items. Unequip one first."%h.name)
  return false
 var c: Campaign=game.campaign;var ok=false
 var swapping=data.kind=="equipped" and not bag and c.hero_by_id(hero_id).get("equipment",{}).has(_slot)
 var before=c.hero_by_id(hero_id).get("equipment",{}).values().duplicate() if not bag else []
 match data.kind:
  "bag":ok=c.equip(hero_id,data.id)
  "offer":ok=c.buy_and_equip(int(data.index),hero_id)
  "equipped":
   if bag:ok=c.unequip(data.owner,str(data.slot))
   else:ok=c.transfer_item(data.owner,hero_id,str(data.slot),_slot)
 if ok and not bag:
  for v in c.hero_by_id(hero_id).get("equipment",{}).values():
   if Forge.ITEMS.get(str(v),{}).get("wild",false) and str(v) not in before:Callable(FlowUI,"banner").call_deferred(game,"LEGENDARY!",Color("ffd36e"),Forge.ITEMS[str(v)].name+" equipped")
 if ok and data.kind=="offer" and c.last_error=="bag":
  c.last_error="";game.sound.cue("upgrade");game.toast("%s is full · sent to your bag"%c.hero_by_id(hero_id).name);game.render();return true
 if ok:
  game.sound.cue("upgrade")
  if data.kind=="equipped" and not bag:game.toast(("Swapped items with " if swapping else "Moved item to ")+c.hero_by_id(hero_id).name)
  if not bag:
   for v in c.hero_by_id(hero_id).get("equipment",{}).values():
    if Forge.is_component(str(data.id)) and Forge.is_item(str(v)) and str(v) not in before and not swapping:game.toast("Forged %s!"%Forge.ITEMS[str(v)].name);game.sound.cue("upgrade",true);break
  game.render()
 else:game.toast(c.last_error if not c.last_error.is_empty() else "Could not equip this item.")
 return ok

static func token(game: Node,parent: Node,item: Dictionary,pixels: int=72) -> GearToken:
 var button=GearToken.new();button.game=game;parent.add_child(button)
 button.custom_minimum_size=Vector2(pixels,pixels);button.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
 var wild=item.get("wild",false);var component=item.get("kind","")=="component"
 var tint=Color("ff9be0") if wild else (Color("9fd4c6") if component else Color("ffd36e"))
 if item.is_empty() or not item.has("id"):tint=Color("6c818b")
 button.glow=tint
 button.add_theme_stylebox_override("normal",game.style(Color("211b36") if not wild else Color("2c1530"),tint,4 if not component else 30,5,2))
 button.add_theme_stylebox_override("hover",game.style(Color("3b3050"),Color("ffeab1"),4 if not component else 30,5,3))
 var image=AbilityArt.icon(button,item.get("art","ward"),0);image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.offset_left=6;image.offset_top=6;image.offset_right=-6;image.offset_bottom=-6;image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if item.has("id"):RarityStyle.decorate(image,item.get("rarity","Common"))
 if item.get("rarity","")=="Legendary" and pixels>=48:
  # Legendary loot glows: a pulsing gold rim and a star, so it never hides in a bag.
  var rim=Panel.new();rim.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(rim);rim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  var rs=StyleBoxFlat.new();rs.bg_color=Color(0,0,0,0);rs.border_color=Color("ffd36e");rs.set_border_width_all(3);rs.set_corner_radius_all(6)
  rim.add_theme_stylebox_override("panel",rs)
  var pulse=rim.create_tween().set_loops();pulse.tween_property(rim,"modulate:a",0.35,0.7);pulse.tween_property(rim,"modulate:a",1.0,0.7)
  var star=game.label(button,"★",int(pixels*0.26),Color("ffd36e"),false);star.position=Vector2(3,-2);star.mouse_filter=Control.MOUSE_FILTER_IGNORE
  star.add_theme_color_override("font_outline_color",Color.BLACK);star.add_theme_constant_override("outline_size",4)
 if item.get("kind","")=="item" and pixels>=56:
  # Recipe pips: the two components this was forged from.
  for i in range(2):
   var pip=AbilityArt.icon(button,Forge.COMPONENTS[item.recipe[i]].art,0);pip.mouse_filter=Control.MOUSE_FILTER_IGNORE
   var ps=pixels*0.3;pip.position=Vector2(pixels-ps-2-i*(ps-2),pixels-ps-2);pip.size=Vector2(ps,ps)
 button.tooltip_text=tip(item)
 if item.get("kind","")=="component" and pixels>=56:button.hint_pixels=pixels;button.call_deferred("add_combo_hint")
 return button

## What a component would forge with components you already own: the selected champion's loose
## components first (dropping it there forges instantly), then the rest of the roster, then the bag.
static func owned_combos(game: Node,id: String,payload: Dictionary={}) -> Array:
 if game==null or game.campaign==null or not Forge.is_component(id):return []
 var c: Campaign=game.campaign;var out=[];var seen={}
 var heroes=[];var sel=selected(game)
 if not sel.is_empty():heroes.append(sel)
 for h in c.state.roster:
  if h!=sel:heroes.append(h)
 for h in heroes:
  for k in h.get("equipment",{}):
   if payload.get("kind","")=="equipped" and str(payload.get("owner",""))==str(h.id) and str(payload.get("slot",""))==str(k):continue
   var p=str(h.equipment[k])
   if not Forge.is_component(p):continue
   var m=Forge.combine(id,p)
   if m=="" or seen.has(m):continue
   seen[m]=true;out.append({"partner":p,"made":m,"where":"on "+str(h.name)})
 var bag_ids=[]
 for p in c.state.inventory:
  if Forge.is_component(str(p)) and str(p) not in bag_ids:bag_ids.append(str(p))
 for p in bag_ids:
  if p==id and payload.get("kind","")=="bag" and c.state.inventory.count(p)<2:continue
  var m=Forge.combine(id,p)
  if m=="" or seen.has(m):continue
  seen[m]=true;out.append({"partner":p,"made":m,"where":"in bag"})
 return out

static func combo_text(id: String,combos: Array) -> String:
 var t=""
 if not combos.is_empty():
  var o=combos[0];var it=Forge.ITEMS[o.made]
  t+="\n\n⚒ FORGES INTO %s%s\n(with %s %s)\n%s\n%s"%[it.name.to_upper()," · WILD" if it.get("wild",false) else "",Forge.COMPONENTS[o.partner].name,o.where,it.text,Forge.stat_line(o.made)]
 t+="\n\nOTHER PAIRINGS YOU OWN:" if combos.size()>1 else ("" if not combos.is_empty() else "\n\nYou own no component that pairs with this yet.")
 combos=combos.slice(1)
 for o in combos:t+="\n + %s (%s)  →  %s%s"%[Forge.COMPONENTS[o.partner].name,o.where,Forge.ITEMS[o.made].name," · WILD" if Forge.ITEMS[o.made].get("wild",false) else ""]
 t+="\n\nAll recipes:"
 for other in Forge.COMPONENT_ORDER:
  var m=Forge.combine(id,other)
  if m!="":t+="\n + %s  →  %s"%[Forge.COMPONENTS[other].name,Forge.ITEMS[m].name]
 return t

## A small round badge showing an item, used for "this makes…" hints.
static func result_badge(game: Node,parent: Control,made: String,size_px: float,pos: Vector2,arrow: bool=true) -> Control:
 var wild=Forge.ITEMS[made].get("wild",false)
 var holder=Control.new();holder.name="ComboHint";holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;holder.position=pos;holder.size=Vector2(size_px,size_px);parent.add_child(holder)
 var ring=Panel.new();ring.mouse_filter=Control.MOUSE_FILTER_IGNORE;ring.size=Vector2(size_px,size_px);holder.add_child(ring)
 ring.add_theme_stylebox_override("panel",game.style(Color("120d1c"),Color("ff9be0") if wild else Color("ffd36e"),int(size_px),3,2))
 var icon=AbilityArt.icon(holder,Forge.info(made).art,0);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;icon.position=Vector2(3,3);icon.size=Vector2(size_px-6,size_px-6)
 if arrow:
  var a=Label.new();a.text="⚒";a.mouse_filter=Control.MOUSE_FILTER_IGNORE;a.add_theme_font_size_override("font_size",int(size_px*0.42));a.add_theme_color_override("font_color",Color("ffd36e"));a.add_theme_color_override("font_outline_color",Color.BLACK);a.add_theme_constant_override("outline_size",4)
  a.position=Vector2(-size_px*0.34,size_px*0.42);holder.add_child(a)
 return holder

static func tip(item: Dictionary) -> String:
 if not item.has("id"):return item.get("name","")
 var t=item.name+"\n"+item.description
 if item.kind=="item":t+="\nRecipe: %s + %s"%[Forge.COMPONENTS[item.recipe[0]].name,Forge.COMPONENTS[item.recipe[1]].name]
 return t

static func slot(game: Node,parent: Node,hero: Dictionary,key: String,pixels: int=70) -> GearToken:
 var id=str(hero.get("equipment",{}).get(key,""));var item=Forge.info(id)
 var button=token(game,parent,item if not item.is_empty() else {"art":"focus","name":"Empty slot"},pixels)
 button.target_hero=hero.id;button.target_slot=key;button.name="Slot_"+hero.id+"_"+key
 if not item.is_empty():button.payload={"kind":"equipped","owner":hero.id,"id":id,"slot":key}
 else:
  button.get_child(0).modulate=Color(.3,.3,.42,.6)
  var plus=game.label(button,"+",30,game.GOLD,false);plus.position=Vector2(0,12);plus.size=Vector2(pixels,pixels-24);plus.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;plus.mouse_filter=Control.MOUSE_FILTER_IGNORE
 button.tooltip_text=("Empty slot" if item.is_empty() else tip(item))+"\nClick to choose. Drag items here; a second component forges with a loose one."
 button.pressed.connect(func():picker(game,hero,key))
 return button

static func hero_button(game: Node,parent: Node,hero: Dictionary,pixels: int=82,selectable: bool=true) -> GearToken:
 var button=GearToken.new();button.game=game;button.target_hero=hero.id;parent.add_child(button)
 button.custom_minimum_size=Vector2(pixels,pixels+28);button.name="Hero_"+hero.id
 button.add_theme_stylebox_override("normal",game.style(Color("162b36"),game.GOLD if hero.id==game.selected_id else Color("557879"),5,6,2))
 var art=SplashArt.new();art.sp=hero.sp;button.add_child(art);art.position=Vector2(5,3);art.size=Vector2(pixels-10,pixels-3);art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var name_label=game.label(button,hero.name,14,game.GOLD if hero.id==game.selected_id else game.WHITE,false);name_label.position=Vector2(4,pixels);name_label.size=Vector2(pixels-8,24);name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 # Item pips along the bottom of the portrait.
 var i=0
 for k in SLOT_KEYS:
  var v=str(hero.get("equipment",{}).get(k,""))
  if v=="":continue
  var pip=AbilityArt.icon(button,Forge.info(v).art,0);pip.mouse_filter=Control.MOUSE_FILTER_IGNORE;pip.position=Vector2(6+i*22,pixels-24);pip.size=Vector2(20,20);i+=1
 button.tooltip_text=HeroData.species[hero.sp].n+" · Drop items here"
 if selectable:button.pressed.connect(func():game.selected_id=hero.id;game.render())
 return button

static func modal(game: Node,title: String,size: Vector2=Vector2(920,520)) -> Dictionary:
 var shade=ColorRect.new();game.ui.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.color=Color(.02,.02,.06,.82)
 var frame=FantasyFrame.new();shade.add_child(frame);frame.size=size;frame.position=(Vector2(1600,900)-size)*0.5
 var box=VBoxContainer.new();frame.add_child(box);var row=HBoxContainer.new();box.add_child(row)
 var label=game.label(row,title,28);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 game.button(row,"×",func():shade.queue_free()).tooltip_text="Close"
 return {"root":shade,"box":box}

static func picker(game: Node,hero: Dictionary,key: String) -> void:
 var dialog=modal(game,hero.name+" · Items");var c: Campaign=game.campaign
 var id=str(hero.get("equipment",{}).get(key,""))
 if not id.is_empty():
  var item=Forge.info(id);var row=HBoxContainer.new();dialog.box.add_child(row)
  token(game,row,item,96)
  var info=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(info);game.label(info,item.name,24);game.label(info,item.description,16,game.MUTED)
  game.button(info,"Unequip",func():
   if c.unequip(hero.id,key):game.render()
   else:game.toast(c.last_error))
  game.label(dialog.box,"MOVE OR SWAP · Choose a slot on another champion",14,game.GOLD)
  var destinations=HFlowContainer.new();dialog.box.add_child(destinations)
  for other in c.state.roster:
   if other.id==hero.id:continue
   var card=VBoxContainer.new();destinations.add_child(card);game.label(card,other.name,14,game.GOLD)
   var targets=HBoxContainer.new();card.add_child(targets)
   for destination in slot_keys(other):
    var worn=str(other.get("equipment",{}).get(destination,""))
    var button=token(game,targets,Forge.info(worn) if worn!="" else {"art":"focus","name":"Empty slot"},48)
    button.tooltip_text=("Swap with "+Forge.info(worn).name if worn!="" else "Move to empty slot")+" on "+other.name
    button.pressed.connect(func():apply_drop(game,{"kind":"equipped","owner":hero.id,"slot":key,"id":id},other.id,destination))
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;dialog.box.add_child(scroll)
 var grid=GridContainer.new();grid.columns=8;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);scroll.add_child(grid)
 var seen=[]
 for item_id in c.state.inventory:
  if item_id in seen or not Forge.valid(str(item_id)):continue
  seen.append(item_id);var button=token(game,grid,Forge.info(item_id),84);button.payload={"kind":"bag","id":item_id}
  button.pressed.connect(func():apply_drop(game,{"kind":"bag","id":item_id},hero.id))
 game.label(dialog.box,"Your bag is empty. Buy components at the outfitter or win medal chests." if seen.is_empty() else "Choose an item. A component placed on a champion holding a loose component forges a finished item.",16,game.MUTED)

static func inspect(game: Node,item: Dictionary,data: Dictionary={}) -> void:
 var dialog=modal(game,item.name);var row=HBoxContainer.new();dialog.box.add_child(row)
 token(game,row,item,150)
 var box=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(box)
 game.label(box,("WILD ITEM" if item.get("wild",false) else "FINISHED ITEM") if item.kind=="item" else "COMPONENT",16,Color("ff9be0") if item.get("wild",false) else game.GOLD)
 game.label(box,item.description,20)
 if item.kind=="component":
  game.label(box,"Forges into:",15,game.GOLD)
  var flow=HFlowContainer.new();box.add_child(flow)
  for other in Forge.COMPONENT_ORDER:
   var made=Forge.combine(item.id,other);if made=="":continue
   var t=token(game,flow,Forge.info(made),46);t.pressed.connect(func():inspect(game,Forge.info(made)))
 var hero=selected(game)
 if not hero.is_empty() and not data.is_empty():
  game.button(dialog.box,("Buy & equip on %s · %dg"%[hero.name,item.price] if data.kind=="offer" else "Equip on "+hero.name),func():apply_drop(game,data,hero.id),true,not can_drop(game,data,hero.id))
  if data.kind=="offer":game.button(dialog.box,"Buy to bag · %dg"%item.price,func():
   if game.campaign.buy_item(int(data.index)):game.render()
   else:game.toast(game.campaign.last_error),false,not stock_ok(game.campaign,int(data.index)) or game.campaign.state.gold<item.price)
  elif data.kind=="bag" and game.campaign.state.get("tour",{}).get("shop",false):game.button(dialog.box,"Sell · %dg"%int(item.price/2),func():
   if game.campaign.sell_item(item.id):game.render()
   else:game.toast(game.campaign.last_error))

static func bag(game: Node,parent: Node,hero: Dictionary,compact: bool=false) -> void:
 var c: Campaign=game.campaign
 var row=HBoxContainer.new();parent.add_child(row)
 var title=game.label(row,"BAG",16,game.GOLD,false);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var n=forgeable(c).size()
 game.button(row,"Forge (%d)"%n if n>0 else "Forge",func():forge_dialog(game),n>0).tooltip_text="Combine components from your bag"
 game.button(row,"Recipe book",func():recipe_book(game)).tooltip_text="Every component pair and what it forges"
 var target=GearToken.new();target.game=game;target.bag_target=true;target.text="↓ Unequip";target.custom_minimum_size=Vector2(120,36);row.add_child(target);target.tooltip_text="Drop worn items here to return them to your bag."
 if compact:
  for child in row.get_children():
   if child is Button:child.custom_minimum_size.y=36;child.add_theme_font_size_override("font_size",16)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=64 if compact else 82;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;parent.add_child(scroll)
 var strip=HBoxContainer.new();strip.add_theme_constant_override("separation",10);scroll.add_child(strip)
 var seen=[]
 for id in c.state.inventory:
  if id in seen or not Forge.valid(str(id)):continue
  seen.append(id);var item=Forge.info(id)
  var button=token(game,strip,item,52 if compact else 70);button.payload={"kind":"bag","id":id};button.name="Bag_"+id
  button.pressed.connect(func():apply_drop(game,{"kind":"bag","id":id},hero.id))
  button.gui_input.connect(func(event):
   if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:inspect(game,item,{"kind":"bag","id":id}))
  if c.state.inventory.count(id)>1:
   var count=game.label(button,str(c.state.inventory.count(id)),16,game.GOLD,false);count.position=Vector2(35,31) if compact else Vector2(52,45);count.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if seen.is_empty():game.label(strip,"Your spare items appear here.",16,game.MUTED,false)

static func open_bag(game: Node) -> void:
 game.campaign.state.bag_seen=game.campaign.state.inventory.duplicate()
 game.campaign.state.bag_unread=false
 game.campaign.save()
 game.render()
 var dialog=modal(game,"Bag · Equip, forge and store",Vector2(1100,620))
 bag(game,dialog.box,selected(game))
 game.label(dialog.box,"Drag spare items to a champion. Drag worn items to ↓ Unequip. Right-click a spare item for details.",15,game.MUTED)
 team_strip(game,dialog.box,44)

static func manage_team(game: Node) -> void:
 var dialog=modal(game,"Team equipment · Move / swap",Vector2(1160,600))
 game.label(dialog.box,"Drag a worn item to another champion's slot. An occupied slot swaps both items; an empty slot transfers. Click any worn item to choose a destination.",17,game.MUTED)
 team_strip(game,dialog.box,48)
 bag(game,dialog.box,selected(game),true)

static func forgeable(c: Campaign) -> Array:
 var comps=[]
 for id in c.state.inventory:
  if Forge.is_component(str(id)) and str(id) not in comps:comps.append(str(id))
 var out=[]
 for i in range(comps.size()):
  for j in range(i,comps.size()):
   var a=comps[i];var b=comps[j]
   if a==b and c.state.inventory.count(a)<2:continue
   out.append([a,b,Forge.combine(a,b)])
 return out

static func forge_dialog(game: Node) -> void:
 var c: Campaign=game.campaign;var dialog=modal(game,"The Forge",Vector2(1000,640))
 var options=forgeable(c)
 game.label(dialog.box,"Combine two components from your bag into a finished item." if not options.is_empty() else "You need two components in your bag to forge.",16,game.MUTED)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;dialog.box.add_child(scroll)
 var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
 for o in options:
  var row=HBoxContainer.new();list.add_child(row)
  token(game,row,Forge.info(o[0]),52);game.label(row,"+",24,game.GOLD,false);token(game,row,Forge.info(o[1]),52);game.label(row,"→",24,game.GOLD,false)
  token(game,row,Forge.info(o[2]),64)
  var info=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(info)
  game.label(info,Forge.ITEMS[o[2]].name,19,Color("ff9be0") if Forge.ITEMS[o[2]].get("wild",false) else game.GOLD,false);game.label(info,Forge.ITEMS[o[2]].text,13,game.MUTED)
  game.button(row,"Forge",func():
   var result=c.forge_bag(o[0],o[1])
   if result!="":game.sound.cue("upgrade",true);game.toast("Forged %s!"%Forge.ITEMS[result].name);game.render()
   else:game.toast(c.last_error),true)

static func recipe_book(game: Node) -> void:
 var dialog=modal(game,"Recipe book",Vector2(1180,860))
 game.label(dialog.box,"Any two components forge the item where their row and column meet. Pink items are WILD and change how a champion fights.",16,game.MUTED)
 var grid=GridContainer.new();grid.columns=Forge.COMPONENT_ORDER.size()+1;grid.add_theme_constant_override("h_separation",4);grid.add_theme_constant_override("v_separation",4);dialog.box.add_child(grid)
 var corner=Control.new();corner.custom_minimum_size=Vector2(50,50);grid.add_child(corner)
 for a in Forge.COMPONENT_ORDER:token(game,grid,Forge.info(a),50)
 for a in Forge.COMPONENT_ORDER:
  token(game,grid,Forge.info(a),50)
  for b in Forge.COMPONENT_ORDER:
   var made=Forge.combine(a,b);var t=token(game,grid,Forge.info(made),50)
   t.pressed.connect(func():inspect(game,Forge.info(made)))

## The whole team at a glance: every champion with their three item slots. Slots are live drop
## targets (and forge on drop); clicking a portrait selects that champion.
static func team_strip(game: Node,parent: Node,slot_px: int=34) -> void:
 var c: Campaign=game.campaign
 var scroll=ScrollContainer.new();scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.custom_minimum_size.y=slot_px+112;parent.add_child(scroll)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",4);scroll.add_child(row)
 var heroes=c.lineup().duplicate()
 for h in c.state.roster:
  if h not in heroes:heroes.append(h)
 for h in heroes:
  var sel=h.id==game.selected_id;var starter=h in c.lineup()
  var card=PanelContainer.new();row.add_child(card)
  card.add_theme_stylebox_override("panel",game.style(Color(.08,.06,.14,.95) if starter else Color(.05,.05,.08,.85),game.GOLD if sel else (Color("557879") if starter else Color("33404a")),6,3,3 if sel else 1))
  var box=VBoxContainer.new();box.add_theme_constant_override("separation",3);card.add_child(box)
  var face=GearToken.new();face.game=game;face.target_hero=h.id;face.name="Team_"+h.id;face.custom_minimum_size=Vector2(slot_px*3+6,62);box.add_child(face)
  for st in ["normal","hover","pressed","focus"]:face.add_theme_stylebox_override(st,StyleBoxEmpty.new())
  var art=SplashArt.new();art.sp=h.sp;art.mouse_filter=Control.MOUSE_FILTER_IGNORE;face.add_child(art);art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  if not starter:art.modulate=Color(.6,.6,.66)
  face.tooltip_text="%s · %s%s\nClick to select · drop items here"%[h.name,HeroData.species[h.sp].n,"" if starter else " (reserve)"]
  face.pressed.connect(func():game.selected_id=h.id;game.render())
  var nm=game.label(box,h.name,12,game.GOLD if sel else game.WHITE,false);nm.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;nm.clip_text=true;nm.custom_minimum_size.x=slot_px*3+6
  var slots=HBoxContainer.new();slots.add_theme_constant_override("separation",3);box.add_child(slots)
  for key in slot_keys(h):slot(game,slots,h,key,slot_px)

## "RECOMMENDED" row: the champion's core build, ticked when equipped.
static func recommended_row(game: Node,parent: Node,hero: Dictionary,px: int=46) -> void:
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",8);parent.add_child(row)
 var cap=game.label(row,"RECOMMENDED",12,Color("ffd36e"),false);cap.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 cap.tooltip_text="Suggested for %s's signature, learned skills and stat scaling. Shop components for these items are marked ★."%HeroData.species[hero.sp].n;cap.mouse_filter=Control.MOUSE_FILTER_STOP
 var owned=hero.get("equipment",{}).values()
 for id in Forge.recommended(hero.sp,hero):
  var item=Forge.info(id);var t=token(game,row,item,px)
  if id in owned:
   var ok=game.label(t,"✓",18,Color("6fe08a"),false);ok.position=Vector2(px-16,-4);ok.mouse_filter=Control.MOUSE_FILTER_IGNORE
  t.tooltip_text=tip(item)+"\n\nRecommended for "+HeroData.species[hero.sp].n
  t.pressed.connect(func():inspect(game,item))
