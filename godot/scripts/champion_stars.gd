class_name ChampionStars
extends RefCounted
## Legacy save/report compatibility. Copies no longer affect gameplay.
static func copies(_hero: Dictionary) -> int:
 return 1
static func tier(_hero: Dictionary) -> int:
 return 1
static func health(_hero: Dictionary) -> float:
 return 1.0
static func damage(_hero: Dictionary) -> float:
 return 1.0
static func label(hero: Dictionary) -> String:
 return "Level %d"%int(hero.get("level",1))
static func description(_hero: Dictionary) -> String:
 return "Earn XP to improve skills and unlock your species evolution."

static func evolution_label(hero: Dictionary) -> String:
 if not str(hero.get("evolution","")).is_empty():return "EVOLVED · "+HeroData.evolution_info(hero).get("name","Evolution")
 return "EVOLUTION READY" if int(hero.level)>=HeroData.EVOLVE_LEVEL else "Evolution at Lv %d"%HeroData.EVOLVE_LEVEL
