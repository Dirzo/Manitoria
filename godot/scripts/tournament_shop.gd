class_name TournamentShop
extends RefCounted

static func build(game: Node) -> void:
 var c: Campaign=game.campaign
 if not c.state.has("tour") or not c.state.tour.shop:game.phase="hub";game.render();return
 var hero=GearUI.selected(game)
 if hero.is_empty():return
 var tabs=HBoxContainer.new();game.ui.add_child(tabs);tabs.position=Vector2(26,140);tabs.size=Vector2(950,60)
 var title=game.label(tabs,"SHOP",40,game.WHITE,false);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 title.mouse_filter=Control.MOUSE_FILTER_STOP;title.tooltip_text="Drag gear onto a champion. Two components on one champion forge a finished item."
 var left=game.scroll_panel(Rect2(26,212,950,475));left.add_theme_constant_override("separation",8)
 var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);left.add_child(grid)
 for index in range(c.state.tour.stock.size()):offer(game,grid,hero,index)
 var right=game.panel(Rect2(993,130,581,626));right.add_theme_constant_override("separation",10)
 game.label(right,"YOUR TEAM",14,game.GOLD,false)
 GearUI.team_strip(game,right,31)
 var name_label=game.label(right,hero.name+" · "+HeroData.species[hero.sp].n,24);name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var loadout=HBoxContainer.new();loadout.add_theme_constant_override("separation",14);right.add_child(loadout)
 var preview=SplashArt.make(loadout,hero.sp,Vector2(116,145))
 var gear=VBoxContainer.new();gear.size_flags_horizontal=Control.SIZE_EXPAND_FILL;loadout.add_child(gear)
 var stats=HeroData.stats(hero);game.label(gear,"Lv %d · %d HP · %d ATK"%[hero.level,stats.hp,stats.attack],15,game.GOLD,false)
 var slots=HBoxContainer.new();slots.add_theme_constant_override("separation",12);gear.add_child(slots)
 for key in GearUI.SLOT_KEYS:
  GearUI.slot(game,slots,hero,key,62)
 TraitUI.line(game,gear,hero)
 TraitUI.rolls(game,gear,hero,true)
 ChampionKit.build(game,right,hero,150)
 var bag=game.panel(Rect2(26,703,950,178));bag.add_theme_constant_override("separation",8);GearUI.bag(game,bag,hero)
 var actions=HBoxContainer.new();game.ui.add_child(actions);actions.position=Vector2(993,780);actions.size=Vector2(581,62);actions.add_theme_constant_override("separation",10)
 var cost=25+15*int(c.state.tour.get("rerolls",0))
 var roll=game.button(actions,"",func():
  if c.reroll_shop():game.sound.cue("upgrade");game.render()
  else:game.toast(c.last_error),false,c.state.gold<cost)
 roll.custom_minimum_size=Vector2(150,58);roll.tooltip_text="Roll new offers · %d gold (costs 15 more each roll)"%cost
 var rr=HBoxContainer.new();rr.mouse_filter=Control.MOUSE_FILTER_IGNORE;rr.alignment=BoxContainer.ALIGNMENT_CENTER;roll.add_child(rr);rr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 FlowUI.glyph(rr,"roll",26);game.label(rr,"Roll",22,game.WHITE,false).mouse_filter=Control.MOUSE_FILTER_IGNORE
 FlowUI.glyph(rr,"coin",18);game.label(rr,str(cost),18,Color("ffdf7e"),false).mouse_filter=Control.MOUSE_FILTER_IGNORE
 var scout_b=game.button(actions,"Scout",func():
  var dialog=GearUI.modal(game,"Next opponent");game.label(dialog.box,scout(c),24);game.label(dialog.box,WorldTour.next_opponent(c).name,19,game.GOLD))
 scout_b.custom_minimum_size=Vector2(96,58)
 var go=FlowUI.cta(game,actions,"Ready  ▶",func():
  if WorldTour.leave_shop(c):game.phase="hub";game.tab="overview";game.render();game.prepare_match()
  else:game.toast(c.last_error),false,300)
 go.size_flags_horizontal=Control.SIZE_EXPAND_FILL

static func offer(game: Node,parent: Node,hero: Dictionary,index: int) -> void:
 var c: Campaign=game.campaign;var id=str(c.state.tour.stock[index]);var sold=id==""
 var item=Forge.info(id) if not sold else {}
 var tint=Color("6c818b") if sold else (Color("ff9be0") if item.get("wild",false) else (Color("9fd4c6") if item.kind=="component" else Color("ffd36e")))
 var tile=FantasyFrame.new();tile.accent=tint;tile.custom_minimum_size=Vector2(290,190);parent.add_child(tile)
 tile.add_theme_stylebox_override("panel",game.style(Color(.09,.06,.17,.94),tint.darkened(.25),4,10,2))
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",5);tile.add_child(box)
 if sold:
  game.label(box,"SOLD",22,game.MUTED);game.label(box,"Refresh for new offers.",14,game.MUTED);return
 var row=HBoxContainer.new();box.add_child(row)
 var data={"kind":"offer","id":id,"index":index}
 var art=GearUI.token(game,row,item,96);art.payload=data;art.pressed.connect(func():GearUI.inspect(game,item,data))
 var info=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;info.add_theme_constant_override("separation",4);row.add_child(info)
 game.label(info,item.name,18)
 game.label(info,("WILD ITEM" if item.get("wild",false) else "FINISHED ITEM") if item.kind=="item" else "COMPONENT",12,tint)
 game.label(info,Forge.stat_line(id) if item.kind=="item" else item.short,13,game.MUTED)
 if item.kind=="component":
  var combos=GearUI.owned_combos(game,id,data)
  if not combos.is_empty():
   var o=combos[0];var wild=Forge.ITEMS[o.made].get("wild",false)
   var hint=game.label(info,"⚒ %s · %s %s%s"%[Forge.ITEMS[o.made].name,Forge.COMPONENTS[o.partner].name.split(" ")[-1],o.where.replace("in bag","(bag)").replace("on ","@"),"  +%d"%(combos.size()-1) if combos.size()>1 else ""],12,Color("ff9be0") if wild else Color("c8ff9d"),true)
   hint.tooltip_text=GearUI.combo_text(id,combos)
 game.button(box,"Buy & equip · %d gold"%item.price,func():GearUI.apply_drop(game,data,hero.id),true,c.state.gold<item.price or not GearUI.fits(hero,id)).tooltip_text=GearUI.tip(item)
 tile.tooltip_text=GearUI.tip(item)

static func scout(c: Campaign) -> String:
 var sim=BattleSim.new();sim.silent=true
 for h in WorldTour.next_opponent(c).roster:sim.add_unit(h,1,Vector2.ZERO)
 var healers=0;var ranged=0
 for u in sim.units:
  if sim.can_heal(u):healers+=1
  if u.range>2:ranged+=1
 if healers>0 and c.state.tour.level==1:return "Next rival has healing. Use hero tactics to focus healers; focus them with Berserker's Totem or a backline dive."
 if healers>0:return "Next rival: %d healer%s. Burst them down or Weaken them with Hunter's Mark."%[healers,"s" if healers>1 else ""]
 if ranged>=3:return "Next rival: %d ranged fighters. Ironbark and Spiked Gauntlet punish basic attacks."%ranged
 return "Next rival: %d close-range / %d ranged. Keep protectors near your carries."%[5-ranged,ranged]

static func base_stats(item: Dictionary) -> String:
 var parts=[]
 for key in ["hp","attack","speed"]:
  if item.has(key):parts.append("+%d%% %s"%[roundi(item[key]*100),{"hp":"health","attack":"attack","speed":"move"}[key]])
 return " · ".join(parts)
