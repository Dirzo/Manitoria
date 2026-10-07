class_name TourBalance
extends RefCounted
## Fixed, transparent progression. Never scales against the player's current strength.
const LEVELS={"Keeper":[1,4,7,9,11],"Standard":[1,5,8,10,12],"Champion":[1,6,9,10,12]}
const TRAINING_XP=160
static func level(cup: int,difficulty: String,id: String="") -> int:
 var base=int(LEVELS.get(difficulty,LEVELS.Standard)[clampi(cup-1,0,4)])
 # Stagger evolution thresholds across the squad, rather than unlocking five at once.
 if cup>1 and not id.is_empty() and abs(hash(id+"|training"))%5<2:base-=1
 return maxi(1,base)
static func quality(cup: int,bout: int,difficulty: String) -> float:
 var progress=clampf(float(cup-1)/4,0,1)
 var base={"Keeper":.94,"Standard":1.0,"Champion":1.04}.get(difficulty,1.0)
 var growth={"Keeper":.025,"Standard":.025,"Champion":.04}.get(difficulty,.025)
 return base+progress*growth+minf(3,bout)*.008
static func rarity(stage: int,difficulty: String,id: String) -> String:
 var roll=abs(hash(id+"|rarity"))%5
 if stage>=19 and difficulty=="Champion" and roll==0:return "Legendary"
 var threshold={"Keeper":14,"Standard":10,"Champion":7}.get(difficulty,10)
 return "Rare" if stage>=threshold+roll*3 else "Uncommon"
static func gear_budget(stage: int,difficulty: String) -> float:
 var progress=clampf(float(stage-1)/19,0,1)
 return progress*({"Keeper":2.6,"Standard":2.9,"Champion":3.1}.get(difficulty,2.9))

static func match_gold(cup: int,difficulty: String,won: bool) -> int:
 return (180 if won else 145)+10*(clampi(cup,1,5)-1)+int({"Keeper":20,"Standard":0,"Champion":-10}.get(difficulty,0))

static func rival_copies(cup: int,difficulty: String,id: String) -> int:
 var chances={"Keeper":[0,0,5,20,40],"Standard":[0,5,25,55,80],"Champion":[0,10,40,75,95]}
 var chance=chances.get(difficulty,chances.Standard)[clampi(cup-1,0,4)]
 var roll=abs(hash(id+"|stars"))%100
 var apex={"Keeper":[0,0,0,0,5],"Standard":[0,0,0,5,15],"Champion":[0,0,5,15,30]}.get(difficulty,[0,0,0,5,15])[clampi(cup-1,0,4)]
 if roll<apex:return 6
 return 3 if roll<chance else 1
