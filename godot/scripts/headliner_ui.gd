class_name HeadlinerUI
extends RefCounted

static func strongest(heroes: Array) -> Dictionary:
 var best={}
 for hero in heroes:
  if best.is_empty() or HeroData.power(hero)>HeroData.power(best):best=hero
 return best

static func power(heroes: Array) -> int:
 var total=0
 for h in heroes:total+=HeroData.power(h)
 return total

static func portrait(parent: Node,hero: Dictionary,pixels: int) -> Control:
 return SplashArt.make(parent,hero.sp,Vector2(int(pixels*0.8),pixels))

static func starter(game: Node) -> void:
 var chosen=str(game.get_meta("starter_species",""))
 if League.tier(chosen)!="Legendary":chosen=str(League.tiers().Legendary[0])
 var pool=game.campaign.legend_pool()
 var hero=pool.get(chosen,HeroData.make_hero(chosen,"preview","Your headliner"))
 var heading=game.label(game.ui,"Pick one champion to lead your guild. Click a card to see its stats and skills, then sign it on the right.",17,Color("e8e2d2"),false);heading.position=Vector2(34,140)
 var bar=HBoxContainer.new();game.ui.add_child(bar);bar.position=Vector2(34,180);bar.size=Vector2(960,44)
 DraftBoard.view_bar(game,bar)
 var left=game.scroll_panel(Rect2(26,232,970,645))
 var legends=TraitUI.sorted(League.tiers().Legendary.map(func(sp):return pool.get(sp,{})).filter(func(h):return not h.is_empty()),str(game.desk_state.get("sort","Board")))
 var opts=func(h):
  return {"selected":h.sp==chosen,"on_select":func():game.set_meta("starter_species",h.sp);game.sound.cue("contest_reveal");game.sound.announce(h.sp);game.render()}
 if DraftBoard.view(game)=="Table":
  DraftBoard.table(game,left,legends,opts,[["","",56],["Champion","Board",176],["Power","Power",64],["Trait","Ideal",122],["Scale","Scale",80],["HP","hp",48],["DMG","attack",48],["ARM","armor",48],["AS","haste",48],["MOV","speed",48],["AP","potency",48],["","",96]])
 else:
  DraftBoard.grid(game,left,legends,opts,4,200,166)
 var detail=game.panel(Rect2(1016,128,558,652));game.label(detail,hero.name+"  ·  "+HeroData.species[chosen].n,28,game.GOLD)
 game.label(detail,"%s  ·  %s"%[HeroData.species[chosen].role.to_upper(),League.NICHE.get(chosen,"")],15,Color(League.TIER_COLOR.Legendary))
 if Dungeon.active(game.campaign):game.label(detail,"RUN TRAITS · "+RunTraits.tag_text(game.campaign,chosen).to_upper(),14,Color("9fd8ff")).tooltip_text="\n\n".join(RunTraits.of(game.campaign,chosen).map(func(t):return DungeonUI.trait_tooltip(t)))
 SplashArt.make(detail,chosen,Vector2(0,150),true)
 TraitUI.line(game,detail,hero,true)
 # Stat hexagon beside a short guide: where this champion excels, and what each stat does (hover).
 var stat_row=HBoxContainer.new();stat_row.add_theme_constant_override("separation",8);detail.add_child(stat_row)
 StatHex.make(stat_row,hero,Vector2(330,210))
 var side=VBoxContainer.new();side.add_theme_constant_override("separation",4);stat_row.add_child(side)
 var ph=HBoxContainer.new();ph.add_theme_constant_override("separation",8);side.add_child(ph)
 var p=HeroData.power(hero);game.label(ph,"POWER %d"%p,16,TraitUI.power_color(hero),false)
 var hb=StatHex.help_button(game,ph,hero,"?");hb.custom_minimum_size=Vector2(34,28);hb.add_theme_font_size_override("font_size",14)
 StatHex.guide(game,side,hero,true)
 game.label(side,Traits.scaling_text(hero.sp),12,Color("ffd36e"),false).tooltip_text="Health and damage grow every level; this curve decides when this champion peaks."
 ChampionKit.build(game,detail,hero,110)
 var pick=FlowUI.cta(game,game.ui,"Sign  ·  %d gold  ▶"%League.cost(chosen),func():
  if game.campaign.choose_starter(chosen):
   game.selected_id=game.campaign.state.selected;game.sound.cue("contest_lock");game.phase="hub";game.tab="market";game.render();FlowUI.banner(game,"DRAFT YOUR SQUAD",Color("ffd36e"))
  else:game.toast(game.campaign.last_error if not game.campaign.last_error.is_empty() else "Could not sign this champion."))
 pick.position=Vector2(1016,798);pick.size=Vector2(558,66)

static func rival_face(c: Campaign, rival: Dictionary) -> Dictionary:
 var cl=WorldTour.club(c,int(rival.get("club",-1)))
 for h in rival.roster:
  if h.id==cl.get("headliner",""):return h
 return strongest(rival.roster)

static func overview(desk: ManagementDesk) -> void:
 var game=desk.game;var c=desk.campaign;var t=c.state.tour;var region=WorldTour.display_region(c)
 var top=desk.horizontal(desk.body);desk.text(top,region.name,34).size_flags_horizontal=Control.SIZE_EXPAND_FILL;desk.text(top,"LEVEL %d · %s"%[t.level,WorldTour.stage_label(c).to_upper()],19,desk.GOLD)
 var navigation=desk.horizontal(desk.body)
 desk.action(navigation,"View tournament bracket",func():TournamentRewardsUI.open_screen(game,"bracket"),true)
 desk.action(navigation,"Champion's vault · %d chests"%TrophyVault.unopened(c).size(),func():TournamentRewardsUI.open_screen(game,"vault"),true)
 if t.complete:
  var done=desk.card(desk.body);desk.text(done,"WORLD CHAMPIONS",40,desk.GOLD)
  if not c.headliner().is_empty():portrait(done,c.headliner(),200)
  desk.text(done,"All five cups conquered.",24);return
 var rival=c.opponent();var home=c.lineup();var away=rival.roster
 var panels=desk.horizontal(desk.body)
 for side in range(2):
  var heroes=home if side==0 else away;var leader=strongest(heroes);var face=c.headliner() if side==0 else rival_face(c,rival)
  var panel=desk.card(panels);panel.get_parent().custom_minimum_size.x=755
  var title=desk.horizontal(panel);Crest.make(title,Crest.of_campaign(c) if side==0 else Crest.default_for(rival.name),c.state.name if side==0 else rival.name,Vector2(34,40));var tl=desk.text(title,c.state.name if side==0 else rival.name,24,Color("7ddcf2") if side==0 else Color("ffa093"));FlowUI.fit_label(tl,520,24,12);tl.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  desk.text(title,"%d power"%League.team_power(heroes),22,desk.GOLD).tooltip_text="Team power: the average Power of the five starters. Matchups and tactics still matter."
  if not face.is_empty():
   var banner=desk.horizontal(panel);portrait(banner,face,124)
   var words=desk.column(banner);desk.text(words,"YOUR HEADLINER" if side==0 else "RIVAL HEADLINER",12,desk.GOLD);desk.text(words,face.name+" · "+HeroData.species[face.sp].n,24)
   desk.text(words,"%s · %s"%[League.tier(face.sp).to_upper(),League.rating_badge_text(face)],16,League.tier_color(face.sp))
   if side==0 and face.slot<0:desk.text(words,"Headliner is on the bench",13,desk.MUTED)
  var strip=desk.horizontal(panel)
  for h in heroes:
   var tile=desk.column(strip);var button=Button.new();tile.add_child(button);button.custom_minimum_size=Vector2(128,120)
   for st in ["normal","hover","pressed","focus"]:button.add_theme_stylebox_override(st,StyleBoxEmpty.new())
   var art=SplashArt.new();art.sp=h.sp;art.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(art);art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
   button.mouse_entered.connect(func():art.modulate=Color(1.15,1.15,1.15));button.mouse_exited.connect(func():art.modulate=Color.WHITE)
   button.pressed.connect(func():desk.profile(h,side==0));button.tooltip_text=HeroData.species[h.sp].n+" · Inspect abilities and equipment"
   desk.text(tile,h.name,16,desk.GOLD if h.id==leader.get("id","") else desk.WHITE)
   desk.text(tile,League.rating_badge_text(h),14,League.tier_color(h.sp))
 var delta=League.team_power(home)-League.team_power(away)
 var edge=desk.text(desk.body,"EVEN MATCH" if delta==0 else ("YOU +%d" if delta>0 else "RIVALS +%d")%abs(delta),26,Color("6fe08a") if delta>0 else (Color("ff8a7a") if delta<0 else desk.GOLD))
 edge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;edge.tooltip_text="Team rating difference (average power of the starters)";edge.mouse_filter=Control.MOUSE_FILTER_STOP
 if not c.state.report.is_empty():desk.action(desk.body,"Last match · Damage & healing",func():desk.report_dialog(c.state.report))
