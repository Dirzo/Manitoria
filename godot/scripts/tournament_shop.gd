class_name TournamentShop
extends RefCounted

static func build(game: Node) -> void:
 var c: Campaign=game.campaign
 if not c.state.has("tour") or not c.state.tour.shop:game.phase="hub";game.render();return
 var hero=GearUI.selected(game)
 if hero.is_empty():return
 var tabs=HBoxContainer.new();game.ui.add_child(tabs);tabs.position=Vector2(26,140);tabs.size=Vector2(1030,50)
 var title=game.label(tabs,"SHOP",40,game.WHITE,false);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 title.mouse_filter=Control.MOUSE_FILTER_STOP;title.tooltip_text="Drag gear onto a champion. Two components on one champion forge a finished item."
 title.size_flags_horizontal=0;title.custom_minimum_size.x=150
 FlowUI.fight_summary(game,tabs)
 var has_report=not c.state.get("report",{}).get("rows",[]).is_empty()
 var carousel=game.get_meta("retained_shop_carousel") if game.has_meta("retained_shop_carousel") else null
 if carousel==null:carousel=ChampionCarousel.new()
 else:game.remove_meta("retained_shop_carousel")
 carousel.game=game;carousel.position=Vector2(26,198);carousel.size=Vector2(1030,300);game.ui.add_child(carousel)
 if not carousel.entries.is_empty():carousel.refresh_selection()
 var left=game.scroll_panel(Rect2(26,506,1030,212));left.add_theme_constant_override("separation",8)
 var grid=GridContainer.new();grid.columns=6;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);left.add_child(grid)
 for index in range(c.state.tour.stock.size()):offer(game,grid,hero,index)
 var right=game.scroll_panel(Rect2(1080,140,494,636));right.add_theme_constant_override("separation",10)
 game.label(right,"FEATURED CHAMPION  ·  "+ChampionStars.label(hero),14,game.GOLD,false).tooltip_text=ChampionStars.description(hero)
 game.label(right,ChampionStars.evolution_label(hero),13,HeroData.evolution_color(hero) if not str(hero.get("evolution","")).is_empty() else game.MUTED)
 var name_label=game.label(right,hero.name+" · "+HeroData.species[hero.sp].n,24);name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var stats=HeroData.stats(hero);game.label(right,"Lv %d · %s · %d HP · %d ATK"%[hero.level,HeroData.species[hero.sp].role,stats.hp,stats.attack],15,game.GOLD,false)
 if hero.get("build_goal","Adaptive")!="Adaptive":game.label(right,"RUN PLAN · %s item priority"%hero.build_goal,13,Color("8effac"))
 game.label(right,"%d AP · %.2f attacks/s · %d%% shorter skill cooldowns"%[stats.ability_power,1.0/stats.interval,roundi((1.0-HeroData.cooldown_factor(hero))*100)],12,Color("bba2ff"))
 game.label(right,"Attack range: %d hexes · Move one hex at a time"%ArenaGrid.attack_hexes(stats.range),13,game.MUTED)
 var copy_box=VBoxContainer.new();right.add_child(copy_box)
 game.label(copy_box,"CHAMPION MARKET · improve this champion",14,game.GOLD,false)
 var offered=c.copy_offer(hero);var current=HeroData.rolls(hero);var improvements=[]
 for key in HeroData.ROLL_KEYS:
  if int(offered[key])>int(current[key]):improvements.append("%s %d→%d"%[StatHex.GUIDE[key].name,current[key],offered[key]])
 game.label(copy_box,"Fully upgraded · strongest rolls retained" if ChampionStars.tier(hero)==3 else " · ".join(improvements) if not improvements.is_empty() else "No higher rolls this offer · still advances stars",12,Color("8effac"))
 var copy_button=game.button(copy_box,"Three stars · complete" if ChampionStars.tier(hero)==3 else "Buy "+HeroData.species[hero.sp].n+" copy · %d gold"%League.cost(hero.sp),func():
  if c.buy_champion_copy(hero.id):
   game.sound.cue("upgrade",true);game.render();game.toast(hero.name+" · "+ChampionStars.label(hero))
  else:game.toast(c.last_error),true,ChampionStars.tier(hero)==3 or c.state.gold<League.cost(hero.sp))
 copy_button.name="ShopChampionCopy";copy_button.add_theme_font_size_override("font_size",16)
 copy_button.tooltip_text=ChampionStars.description(hero)+"\nOnly your existing champion improves. Recruit new species between cups. Item rerolls also change these offers."
 var hex=StatHex.make(right,hero,Vector2(470,160));hex.name="ShopChampionStatHex"
 game.label(right,"Green = current stats · gold outline = before last copy purchase",11,game.MUTED)
 var gear=VBoxContainer.new();right.add_child(gear)
 var equipment_heading=HBoxContainer.new();gear.add_child(equipment_heading)
 game.label(equipment_heading,"CURRENT ITEMS",13,game.GOLD,false).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var bag_button=game.button(equipment_heading,"",func():GearUI.open_bag(game),false)
 bag_button.add_theme_font_size_override("font_size",16);bag_button.custom_minimum_size.y=34
 var slots=HBoxContainer.new();slots.add_theme_constant_override("separation",12);gear.add_child(slots)
 for key in GearUI.slot_keys(hero):
  GearUI.slot(game,slots,hero,key,54)
 bag_button.name="ShopBagButton"
 var seen=c.state.get("bag_seen",[])
 var fresh=c.state.get("bag_unread",false)
 for id in c.state.inventory:
  if c.state.inventory.count(id)>seen.count(id):fresh=true
 bag_button.text=("● NEW · " if fresh else "")+"Bag (%d)"%c.state.inventory.size()
 if fresh:bag_button.add_theme_stylebox_override("normal",game.style(Color("225344"),Color("c8ff9d"),6,8,3))
 var swap_button=game.button(slots,"Swap",func():GearUI.manage_team(game))
 swap_button.add_theme_font_size_override("font_size",14);swap_button.custom_minimum_size=Vector2(62,54)
 swap_button.tooltip_text="Manage the whole team's equipment. Drag items onto another champion's slots to transfer or swap."
 TraitUI.rolls(game,gear,hero,true)
 GearUI.recommended_row(game,right,hero,40)
 game.label(right,"Counter healing: Grievous Thorns · Counter armor/shields: Shieldbreaker Tusk. Use Tactics to focus healers or the back line.",12,game.GOLD)
 var support_count=c.lineup().filter(func(h):return HeroData.species[h.sp].role=="Support").size()
 if support_count>1:game.label(right,"%d Supports · healing at %d%% while they are alive. A single Support heals at full strength."%[support_count,roundi(CombatPacing.support_heal_factor(support_count)*100)],12,game.MUTED)
 ChampionKit.build(game,right,hero,170)
 var graphs=game.panel(Rect2(26,726,1030,155))
 graphs.name="ShopGraphs"
 if has_report:LastRoundGraph.make(game,graphs,130)
 else:game.label(graphs,"LAST ROUND · Damage / Crowd control / Healing / Damage taken\nYour champion graphs appear here after the first fight.",16,game.MUTED)
 var actions=HBoxContainer.new();game.ui.add_child(actions);actions.position=Vector2(1080,780);actions.size=Vector2(494,62);actions.add_theme_constant_override("separation",10)
 var cost=25+15*int(c.state.tour.get("rerolls",0))
 var roll=game.button(actions,"",func():
  if c.reroll_shop():game.sound.cue("upgrade");game.render()
  else:game.toast(c.last_error),false,c.state.gold<cost)
 roll.custom_minimum_size=Vector2(150,58);roll.tooltip_text="Roll new offers · %d gold (costs 15 more each roll)"%cost
 var rr=HBoxContainer.new();rr.mouse_filter=Control.MOUSE_FILTER_IGNORE;rr.alignment=BoxContainer.ALIGNMENT_CENTER;roll.add_child(rr);rr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 FlowUI.glyph(rr,"roll",26);game.label(rr,"Roll",22,game.WHITE,false).mouse_filter=Control.MOUSE_FILTER_IGNORE
 FlowUI.glyph(rr,"coin",18);game.label(rr,str(cost),18,Color("ffdf7e"),false).mouse_filter=Control.MOUSE_FILTER_IGNORE
 var scout_b=game.button(actions,"Scout",func():
  ScoutUI.open(game,WorldTour.next_opponent(c),scout(c)))
 scout_b.custom_minimum_size=Vector2(96,58)
 var go=FlowUI.cta(game,actions,"Ready  ▶",func():
  if not WorldTour.leave_shop(c):game.toast(c.last_error);return
  game.tab="overview";game.introduce_match()
  if game.phase=="shop":game.phase="hub";game.render(),false,210)
 go.size_flags_horizontal=Control.SIZE_EXPAND_FILL

static func offer(game: Node,parent: Node,hero: Dictionary,index: int) -> void:
 var c: Campaign=game.campaign;var id=str(c.state.tour.stock[index]);var sold=id==""
 var item=Forge.info(id) if not sold else {}
 var tint=Color("6c818b") if sold else (Color("ff9be0") if item.get("wild",false) else (Color("9fd4c6") if item.kind=="component" else Color("ffd36e")))
 var tile=FantasyFrame.new();tile.accent=tint;tile.custom_minimum_size=Vector2(158,165);parent.add_child(tile)
 tile.add_theme_stylebox_override("panel",game.style(Color(.09,.06,.17,.94),tint,10,8,0))
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",3);tile.add_child(box)
 if sold:
  game.label(box,"SOLD",22,game.MUTED);game.label(box,"Refresh for new offers.",14,game.MUTED);return
 var row=HBoxContainer.new();box.add_child(row)
 var data={"kind":"offer","id":id,"index":index}
 var art=GearUI.token(game,row,item,48);art.payload=data;art.pressed.connect(func():GearUI.inspect(game,item,data))
 var info=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;info.add_theme_constant_override("separation",4);row.add_child(info)
 game.label(info,item.name,14)
 game.label(box,("★ LEGENDARY · WILD" if item.get("wild",false) else "FINISHED ITEM") if item.kind=="item" else "COMPONENT",10,Color("ffd36e") if item.get("wild",false) else tint)
 var rec=Forge.rec_match(hero.sp,id,hero)
 if rec[0]!="":
  var rl=game.label(box,"★ CORE ITEM" if rec[0]=="core" else "★ Builds "+Forge.ITEMS[rec[1]].name,11,Color("ffd36e"),false)
  rl.clip_text=true;rl.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;rl.custom_minimum_size.x=80
  rl.tooltip_text="Part of the recommended build for "+HeroData.species[hero.sp].n;rl.mouse_filter=Control.MOUSE_FILTER_STOP
  tile.add_theme_stylebox_override("panel",game.style(Color(.12,.09,.04,.95),Color("ffd36e"),4,8,2))
 game.label(box,Forge.stat_line(id) if item.kind=="item" else item.short,12,game.MUTED)
 if item.kind=="component":
  var combos=GearUI.owned_combos(game,id,data)
  if not combos.is_empty():
   art.tooltip_text+=GearUI.combo_text(id,combos)
 var fits=GearUI.fits(hero,id)
 var buy=game.button(box,("Equip · %d" if fits else "Bag · %d")%item.price,func():GearUI.apply_drop(game,data,hero.id),true,c.state.gold<item.price)
 buy.custom_minimum_size.y=36;buy.add_theme_font_size_override("font_size",14);buy.tooltip_text=GearUI.tip(item)+"\nBuy for "+hero.name
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
