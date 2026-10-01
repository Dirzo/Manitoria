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
 var chosen=str(game.get_meta("starter_species","jackalope"))
 if League.tier(chosen)!="Legendary":chosen="jackalope"
 var hero=HeroData.make_hero(chosen,"preview","Your headliner")
 var heading=game.label(game.ui,"SIGN YOUR LEGENDARY HEADLINER",36,game.GOLD,false);heading.position=Vector2(34,132)
 var hint=game.label(game.ui,"Eight legends, one per club. The other seven become your rivals' headliners. Headliners cost ×3 (%dg)."%League.cost(chosen),18,game.WHITE,false);hint.position=Vector2(35,183)
 var left=game.scroll_panel(Rect2(26,230,970,645));var grid=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",12);left.add_child(grid)
 for sp in League.TIERS.Legendary:
  var box=VBoxContainer.new();box.custom_minimum_size.x=225;grid.add_child(box)
  var b=Button.new();box.add_child(b);b.custom_minimum_size=Vector2(225,262)
  for state in ["normal","hover","pressed","focus"]:b.add_theme_stylebox_override(state,game.style(Color(0,0,0,0),game.GOLD if sp==chosen else Color(0,0,0,0),4,0,4 if sp==chosen else 0))
  b.tooltip_text=HeroData.species[sp].role+" · "+HeroData.species[sp].ability_name
  var art=SplashArt.new();art.sp=sp;art.caption=HeroData.species[sp].n;art.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(art);art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  if sp!=chosen:art.modulate=Color(0.78,0.78,0.82)
  b.mouse_entered.connect(func():art.modulate=Color(1.08,1.08,1.08));b.mouse_exited.connect(func():art.modulate=Color.WHITE if sp==chosen else Color(0.78,0.78,0.82))
  b.pressed.connect(func():game.set_meta("starter_species",sp);game.sound.cue("contest_reveal");game.sound.announce(sp);game.render())
  var niche=game.label(box,League.NICHE.get(sp,""),14,game.GOLD if sp==chosen else game.MUTED);niche.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var detail=game.panel(Rect2(1016,132,558,645));game.label(detail,HeroData.species[chosen].n,30,game.GOLD)
 game.label(detail,"LEGENDARY HEADLINER · %s · %s"%[HeroData.species[chosen].role,League.NICHE.get(chosen,"")],15,Color(League.TIER_COLOR.Legendary))
 game.label(detail,"Starting rating %d OVR"%League.ovr(hero),17)
 TraitUI.species_line(game,detail,chosen)
 SplashArt.make(detail,chosen,Vector2(0,250),true)
 ChampionKit.build(game,detail,hero,220)
 var pick=game.button(game.ui,"Sign headliner · %dg →"%League.cost(chosen),func():
  if game.campaign.choose_starter(chosen):
   game.selected_id=game.campaign.state.selected;game.sound.cue("contest_lock");game.phase="hub";game.tab="market";game.render();game.toast("Headliner signed. Rival clubs have drafted. Fill your four open slots from the draft board.")
  else:game.toast(game.campaign.last_error if not game.campaign.last_error.is_empty() else "Could not sign this champion."),true)
 pick.position=Vector2(1016,798);pick.size=Vector2(558,66)

static func rival_face(c: Campaign, rival: Dictionary) -> Dictionary:
 var cl=WorldTour.club(c,int(rival.get("club",-1)))
 for h in rival.roster:
  if h.id==cl.get("headliner",""):return h
 return strongest(rival.roster)

static func overview(desk: ManagementDesk) -> void:
 var game=desk.game;var c=desk.campaign;var t=c.state.tour;var region=WorldTour.region(c)
 var top=desk.horizontal(desk.body);desk.text(top,region.name,34).size_flags_horizontal=Control.SIZE_EXPAND_FILL;desk.text(top,"LEVEL %d · %s"%[t.level,WorldTour.stage_label(c).to_upper()],19,desk.GOLD)
 var navigation=desk.horizontal(desk.body)
 desk.action(navigation,"View tournament bracket",func():TournamentRewardsUI.open_screen(game,"bracket"),true)
 desk.action(navigation,"Champion's vault · %d chests"%TrophyVault.unopened(c).size(),func():TournamentRewardsUI.open_screen(game,"vault"),true)
 if t.complete:
  var done=desk.card(desk.body);desk.text(done,"WORLD CHAMPIONS",40,desk.GOLD)
  if not c.headliner().is_empty():portrait(done,c.headliner(),200)
  desk.text(done,"All twenty tournaments conquered.",24);return
 var rival=c.opponent();var home=c.lineup();var away=rival.roster
 var panels=desk.horizontal(desk.body)
 for side in range(2):
  var heroes=home if side==0 else away;var leader=strongest(heroes);var face=c.headliner() if side==0 else rival_face(c,rival)
  var panel=desk.card(panels);panel.get_parent().custom_minimum_size.x=755
  var title=desk.horizontal(panel);Crest.make(title,Crest.of_campaign(c) if side==0 else Crest.default_for(rival.name),c.state.name if side==0 else rival.name,Vector2(34,40));desk.text(title,c.state.name if side==0 else rival.name,24,Color("7ddcf2") if side==0 else Color("ffa093")).size_flags_horizontal=Control.SIZE_EXPAND_FILL
  desk.text(title,"%d OVR"%League.team_ovr(heroes),22,desk.GOLD).tooltip_text="Team rating: the average OVR of the five starters. Matchups and tactics still matter."
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
 var footer=desk.horizontal(desk.body)
 var delta=League.team_ovr(home)-League.team_ovr(away)
 desk.text(footer,"EVENLY MATCHED" if delta==0 else ("YOUR TEAM" if delta>0 else "RIVALS")+" RATED %d OVR HIGHER"%abs(delta),17,desk.GOLD).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 desk.action(footer,"Enter the arena →",game.introduce_match,true,not c.lineup_ready() or t.shop or not c.pending_heroes().is_empty())
 var steps=desk.horizontal(desk.body)
 var lost=WorldTour.losses(c,0)
 for info in [["CUP RECORD","%d W  ·  %d L"%[int(t.wins),lost]],["BRACKET",("Winners side" if lost==0 else "Losers side · one more loss and you are out")],["NEXT",WorldTour.stage_label(c)]]:
  var tile=desk.card(steps);desk.text(tile,info[0],12,desk.GOLD);desk.text(tile,info[1],19,Color(region.color))
 if not c.state.report.is_empty():desk.action(desk.body,"Last match · Damage & healing",func():desk.report_dialog(c.state.report))
