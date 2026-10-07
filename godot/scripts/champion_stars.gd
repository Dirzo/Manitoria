class_name ChampionStars
extends RefCounted
## Copies belong to a specific hero, independent of XP and species evolution.
static func copies(hero: Dictionary) -> int:
 return clampi(int(hero.get("copies",1)),1,6)
static func tier(hero: Dictionary) -> int:
 return 3 if copies(hero)>=6 else 2 if copies(hero)>=3 else 1
static func health(hero: Dictionary) -> float:
 return [1.0,1.18,1.50][tier(hero)-1]
static func damage(hero: Dictionary) -> float:
 return [1.0,1.12,1.35][tier(hero)-1]
static func label(hero: Dictionary) -> String:
 return "★".repeat(tier(hero))+" · %d-star · "%tier(hero)+("MAX" if tier(hero)==3 else "%d/%d copies"%[copies(hero),3 if tier(hero)==1 else 6])
static func description(hero: Dictionary) -> String:
 return label(hero)+"\n3 total copies: +18% health, +12% attack damage and ability power.\n6 total copies: +50% health, +35% attack damage and ability power.\nBonuses replace the previous star bonus. Higher copy rolls replace weaker stats; stronger rolls are protected. Skills, equipment, XP and evolution stay with this champion."

static func offer(hero: Dictionary,salt: String) -> Dictionary:
 var rng=RandomNumberGenerator.new();rng.seed=hash(str(hero.id)+"|copy|"+str(copies(hero))+"|"+salt)
 return HeroData.roll_stats(rng,HeroData.roll_floor(hero.sp))
static func merge(hero: Dictionary,offered: Dictionary) -> Array:
 var original=HeroData.rolls(hero);var improved=[];hero.rolls=original.duplicate(true)
 for key in HeroData.ROLL_KEYS:
  var value=clampi(int(offered.get(key,original[key])),0,HeroData.ROLL_MAX)
  if value>int(original[key]):hero.rolls[key]=value;improved.append(key)
 return improved

static func evolution_label(hero: Dictionary) -> String:
 if not str(hero.get("evolution","")).is_empty():return "EVOLVED · "+HeroData.evolution_info(hero).get("name","Evolution")
 return "EVOLUTION READY" if int(hero.level)>=HeroData.EVOLVE_LEVEL else "Evolution at Lv %d"%HeroData.EVOLVE_LEVEL
