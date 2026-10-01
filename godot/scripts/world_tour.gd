class_name WorldTour
extends RefCounted

const MAX_LEVEL = 20
const REGIONS = [
 {"name":"Verdant Crown", "place":"Briarwild Conservatory", "theme":"Forest", "color":"82d99c", "floor":"345044", "sky":"a7d5b3", "roster":["golem","treant","direwolf","harpy","unicorn"]},
 {"name":"Ember Crucible", "place":"Cinderfall Caldera", "theme":"Volcanic", "color":"ffad76", "floor":"44322f", "sky":"f1ad88", "roster":["minotaur","cerberus","chimera","phoenix","salamander"]},
 {"name":"Tideglass Cup", "place":"Pearlreach Coast", "theme":"Coastal", "color":"79dedc", "floor":"35545a", "sky":"a4dce7", "roster":["zaratan","hydra","griffin","kirin","naga"]},
 {"name":"Winterfang Open", "place":"Frostspire Citadel", "theme":"Glacial", "color":"b2e8ff", "floor":"546778", "sky":"c5deff", "roster":["yeti","golem","wendigo","thunderbird","pegasus"]},
 {"name":"Gilded Sun Games", "place":"Aurelian Dunes", "theme":"Desert", "color":"f6d184", "floor":"756047", "sky":"ffe3b0", "roster":["nemean","cyclops","manticore","sphinx","unicorn"]},
 {"name":"Moonveil Invitational", "place":"The Astral Observatory", "theme":"Astral", "color":"c9a9ff", "floor":"39364f", "sky":"c4b3ea", "roster":["gargoyle","owlbear","nekomata","kitsune","arachne"]}
]

static func start(c: Campaign) -> void:
 c.state.tour = {"level":1,"bout":0,"wins":0,"attempt":1,"serial":0,"shop":false,"stock":[],"history":[],"complete":false}
 c.add_news("The World Tour opens", "Eight clubs, double elimination. Podium finishes earn medal chests; every club moves on to the next cup. Visit the outfitter after every match.")

static func region(c: Campaign) -> Dictionary:
 return REGIONS[(int(c.state.tour.level)-1)%REGIONS.size()]

static func seeded_team(c: Campaign, entrant: int) -> Dictionary:
 var t=c.state.tour;var heroes=[]
 var level=1
 var experience=3*(int(t.level)-1)*75
 while level<20 and experience>=HeroData.xp_needed(level):
  experience-=HeroData.xp_needed(level);level+=1
 for i in range(5):
  var sp=REGIONS[(int(t.level)-1+entrant/2)%REGIONS.size()].roster[i]
  var h=HeroData.make_hero(sp,"tour_%d_%d_%d" % [t.level,entrant,i],HeroData.NAMES[(i+int(t.level)*3+entrant*5)%HeroData.NAMES.size()],level)
  h.slot=Campaign.FORMATION[i]
  for k in range(mini(3,maxi(0,level-1))): h.learned[str(k)]=2 if level>=8 else 1
  if level>=5: h.signature_rank=2
  if t.level>=8:h.skill_rarity={"0":"Rare"};h.ability_bonus_0=1.1
  if t.level>=16:h.skill_rarity={"0":"Legendary"};h.ability_bonus_0=1.25
  h.equipment=Forge.rival_loadout(h,int(t.level),str(c.state.get("difficulty","Standard")))
  if level>=10: h.evolution=["guardian","ravager","arcanist"][i%3]
  heroes.append(h)
 return {"name":Campaign.CLUBS[entrant-1],"roster":heroes,"practice":false}

## Worst finish that keeps the run alive: Keeper must avoid last place (7th-8th),
## Standard must reach the top four, Champion must reach the podium.
static func survival_place(c: Campaign) -> int:
 return {"Keeper":5,"Standard":4,"Champion":3}.get(str(c.state.get("difficulty","Standard")),4)

static func stock(c: Campaign) -> Array:
 # Four components, one finished item, and (from cup 3) a wild card that may be a WILD item.
 var level=int(c.state.tour.level)
 var rng=RandomNumberGenerator.new();rng.seed=c.state.seed+c.state.tour.serial*97+int(c.state.tour.get("rerolls",0))*7919
 var result=[]
 for i in range(4): result.append(Forge.COMPONENT_ORDER[rng.randi_range(0,Forge.COMPONENT_ORDER.size()-1)])
 var tame=Forge.ITEMS.keys().filter(func(k): return not Forge.ITEMS[k].get("wild",false))
 result.append(tame[rng.randi_range(0,tame.size()-1)])
 if level>=3:
  var all=Forge.ITEMS.keys()
  result.append(all[rng.randi_range(0,all.size()-1)] if rng.randf()<0.5 else "coin")
 return result

static func resolve(c: Campaign, sim: BattleSim) -> bool:
 if c.state.tour.complete or c.state.tour.shop or not sim.finished or sim.battle_seed!=c.match_seed(): return false
 var before=c.state.duplicate(true);var t=c.state.tour;var r=region(c)
 var rng=RandomNumberGenerator.new();rng.seed=c.match_seed()+801
 var reward=110 if sim.winner==0 else 75
 var rival=opponent(c);var m=current_match(c)
 c.record_team(c.state.roster,sim,0,true,rng);c.record_club(c.state,sim.winner)
 var rival_club=club(c,int(m.team_b) if int(m.team_a)==0 else int(m.team_a))
 if not rival_club.is_empty():c.record_team(rival_club.roster,sim,1,false,rng);c.record_club(rival_club,1 if sim.winner==0 else 0 if sim.winner==1 else -1)
 var report={"winner":sim.winner,"gold":reward,"duration":sim.time,"rows":sim.report_rows(),"opponent":rival.name,"round":t.serial,"season":c.state.season,"tour_level":t.level,"location":r.place,"bout":t.bout+1,"stage":m.label}
 report.ais=sim.units.filter(func(u):return not u.summon).map(func(u):return {"uid":u.uid,"team":u.team,"name":u.hero.name,"sp":u.hero.sp,"ais":League.ais(sim,u),"ovr":League.ovr(u.hero)})
 record_player(c,sim.winner==0)
 if sim.winner==0:
  for h in c.lineup():
   if "idol" in Forge.carried(h):reward+=60
 t.wins+=int(sim.winner==0);t.serial+=1
 var bracket=t.bracket
 if bracket.finished:
  var place=placement(c,0)
  var promoted=place==1
  t.history.append({"level":t.level,"location":r.place,"wins":t.wins,"attempt":t.attempt,"promoted":promoted,"place":place,"bracket":bracket.duplicate(true)})
  report.tournament_won=promoted;report.place=place
  reward+={1:150+int(t.level)*15,2:90,3:60,4:40}.get(place,20)
  League.weekly_update(c)
  # Podium finishes earn a medal chest; everyone moves on to the next cup regardless.
  var medal={1:"Gold",2:"Silver",3:"Bronze"}.get(place,"")
  if promoted:c.state.trophies+=1
  if medal!="":
   TrophyVault.award(c,medal)
   report.chest=true;report.medal=medal
  # Knocked out below the difficulty's survival line: the run ends here.
  var cutoff=survival_place(c)
  if place>cutoff:
   c.state.run_over=true;report.run_over=true;report.cutoff=cutoff
   c.add_news("The run is over","%s finished %s at %s. %s runs must finish %s or better."%[c.state.name,TournamentRewardsUI._place_text(place),r.place,c.state.difficulty,TournamentRewardsUI._place_text(cutoff)])
  elif t.level==MAX_LEVEL:t.complete=true
  else:t.level+=1
  t.attempt=1
  t.bout=0;t.wins=0
 else:t.bout=mini(16,int(t.bout)+1)
 report.gold=reward;c.state.gold+=reward;c.state.earned_gold+=reward
 c.state.report=report;c.state.archive.append(report.duplicate(true))
 t.shop=not c.state.get("run_over",false);t.rerolls=0;t.stock=stock(c) if t.shop else []
 c.add_news("Tournament match complete", "%s · %s · %dg. Visit the outfitter before your next match." % [r.place,m.label,reward])
 if c.save(): return true
 c.state=before;return false

static func leave_shop(c: Campaign) -> bool:
 if not c.state.tour.shop: return false
 var before=c.state.duplicate(true)
 c.state.tour.shop=false
 if c.state.tour.get("bracket",{}).get("finished",false) and not c.state.tour.complete:c.state.tour.erase("bracket");ensure_bracket(c)
 if c.save(): return true
 c.state=before;return false

# ------------------------------------------------------------------ Melee-style double elimination
# Eight clubs seeded by team rating. Lose twice and you are out. The losers-bracket champion
# must beat the winners-bracket champion twice in the grand final (bracket reset).
const MATCHES = [
 {"key":"W1","label":"Winners Round 1","a":{"seed":0},"b":{"seed":7}},
 {"key":"W1","label":"Winners Round 1","a":{"seed":3},"b":{"seed":4}},
 {"key":"W1","label":"Winners Round 1","a":{"seed":1},"b":{"seed":6}},
 {"key":"W1","label":"Winners Round 1","a":{"seed":2},"b":{"seed":5}},
 {"key":"W2","label":"Winners Semifinal","a":{"w":0},"b":{"w":1}},
 {"key":"W2","label":"Winners Semifinal","a":{"w":2},"b":{"w":3}},
 {"key":"WF","label":"Winners Final","a":{"w":4},"b":{"w":5}},
 {"key":"L1","label":"Losers Round 1","a":{"l":0},"b":{"l":1}},
 {"key":"L1","label":"Losers Round 1","a":{"l":2},"b":{"l":3}},
 {"key":"L2","label":"Losers Round 2","a":{"w":7},"b":{"l":5}},
 {"key":"L2","label":"Losers Round 2","a":{"w":8},"b":{"l":4}},
 {"key":"L3","label":"Losers Semifinal","a":{"w":9},"b":{"w":10}},
 {"key":"LF","label":"Losers Final","a":{"w":11},"b":{"l":6}},
 {"key":"GF","label":"Grand Final","a":{"w":6},"b":{"w":12}},
 {"key":"GF2","label":"Grand Final · Reset","a":{"w":13},"b":{"l":13}},
]
const ORDER = [0,1,2,3,4,5,7,8,9,10,6,11,12,13,14]

static func club(c: Campaign, team: int) -> Dictionary:
 if team<=0 or team>c.state.clubs.size():return {}
 return c.state.clubs[team-1]

static func team_roster(c: Campaign, team: int) -> Array:
 return c.lineup() if team==0 else club(c,team).get("roster",[])

static func team_name(c: Campaign, team: int) -> String:
 return c.state.name if team==0 else club(c,team).get("name","?")

## Rival clubs grow with the tour: gear and rarer skills arrive as the team level rises.
static func outfit_clubs(c: Campaign) -> void:
 var lvl=int(c.state.tour.level)
 for cl in c.state.clubs:
  for h in cl.roster:
   h.equipment=Forge.rival_loadout(h,lvl,str(c.state.get("difficulty","Standard")))
   if lvl>=8 and h.learned.has("0") and RarityStyle.for_skill(h,"ability:0")=="Uncommon":h.skill_rarity=h.get("skill_rarity",{});h.skill_rarity["0"]="Rare"
   if lvl>=16 and h.learned.has("0"):h.skill_rarity=h.get("skill_rarity",{});h.skill_rarity["0"]="Legendary"
   if int(h.level)>=10 and h.get("evolution","").is_empty():h.evolution=["guardian","ravager","arcanist"][hash(h.id)%3]

static func ensure_bracket(c: Campaign) -> void:
 var t=c.state.tour
 if t.has("bracket") and t.bracket.get("format","")=="double":return
 if c.state.clubs.size()<7:c.draft_rivals()
 outfit_clubs(c)
 var teams=range(8)
 teams.sort_custom(func(x,y):return League.team_ovr(team_roster(c,x))>League.team_ovr(team_roster(c,y)))
 var matches=[]
 for m in MATCHES:
  var d=m.duplicate(true);d.team_a=-1;d.team_b=-1;d.winner=-1;d.loser=-1;d.skipped=false
  matches.append(d)
 t.bracket={"format":"double","seeds":teams,"matches":matches,"finished":false,"level":t.level,"champion":-1}
 for i in range(8):t.bracket["ovr_%d"%i]=League.team_ovr(team_roster(c,i))
 step(c)

static func _resolve_source(b: Dictionary, src: Dictionary) -> int:
 if src.has("seed"):return int(b.seeds[int(src.seed)])
 var m=b.matches[int(src.get("w",src.get("l",-1)))]
 if int(m.winner)<0:return -1
 return int(m.winner) if src.has("w") else int(m.loser)

## Advance every AI-only match that is ready, stopping at the player's next match.
static func step(c: Campaign) -> void:
 var b=c.state.tour.bracket
 var rng=RandomNumberGenerator.new();rng.seed=int(c.state.seed)+int(c.state.tour.level)*977+int(c.state.tour.serial)*13
 for i in ORDER:
  var m=b.matches[i]
  if int(m.winner)>=0 or m.skipped:continue
  m.team_a=_resolve_source(b,m.a);m.team_b=_resolve_source(b,m.b)
  if m.team_a<0 or m.team_b<0:return
  if i==14 and int(b.matches[13].winner)==int(b.matches[13].team_a):m.skipped=true;continue
  if m.team_a==0 or m.team_b==0:return
  var sim=BattleSim.new();sim.silent=true
  sim.setup(team_roster(c,m.team_a),team_roster(c,m.team_b),int(c.state.seed)+int(c.state.tour.level)*900+i*31+int(c.state.tour.attempt)*7)
  sim.run_to_end()
  var won_a=sim.winner!=1
  m.winner=m.team_a if won_a else m.team_b;m.loser=m.team_b if won_a else m.team_a
  for side in [0,1]:
   var team=m.team_a if side==0 else m.team_b
   c.record_team(team_roster(c,team),sim,side,false,rng,0.6);c.record_club(club(c,team),0 if (sim.winner==side) else 1 if sim.winner==1-side else -1)
 b.finished=true
 var last=b.matches[14] if not b.matches[14].skipped else b.matches[13]
 b.champion=int(last.winner)

static func current_match(c: Campaign) -> Dictionary:
 ensure_bracket(c)
 var b=c.state.tour.bracket
 for i in ORDER:
  var m=b.matches[i]
  if int(m.winner)<0 and not m.skipped and (int(m.team_a)==0 or int(m.team_b)==0):return m
 return b.matches[13]

static func record_player(c: Campaign, won: bool) -> void:
 var m=current_match(c)
 var mine_a=int(m.team_a)==0
 m.winner=(m.team_a if won==mine_a else m.team_b);m.loser=(m.team_b if won==mine_a else m.team_a)
 step(c)

static func losses(c: Campaign, team: int) -> int:
 var n=0
 for m in c.state.tour.bracket.matches:
  if int(m.loser)==team:n+=1
 return n

## Final standing: 1, 2, 3, 4, 5 (5th-6th) or 7 (7th-8th); 0 while still alive.
static func placement(c: Campaign, team: int) -> int:
 var b=c.state.tour.bracket
 if b.finished and int(b.champion)==team:return 1
 var where={13:2,14:2,12:3,11:4,9:5,10:5,7:7,8:7}
 for i in where:
  if int(b.matches[i].loser)==team and losses(c,team)>=2:return where[i]
 return 0

static func opponent(c: Campaign) -> Dictionary:
 var m=current_match(c)
 var other=int(m.team_b) if int(m.team_a)==0 else int(m.team_a)
 if other<0:other=1
 return {"name":team_name(c,other),"roster":team_roster(c,other),"practice":false,"club":other}

static func stage_label(c: Campaign) -> String:
 return str(current_match(c).get("label","Grand Final"))

static func next_opponent(c: Campaign) -> Dictionary:
 if c.state.tour.get("bracket",{}).get("finished",false) and not c.state.tour.complete:
  var preview=Campaign.new();preview.state=c.state.duplicate(true);preview.state.tour.erase("bracket")
  return opponent(preview)
 return opponent(c)
