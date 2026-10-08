class_name SkillScaling
extends RefCounted
## Weights mix independent stat channels. AS amplifies only selected rapid skills.
const PHYSICAL = {"ad":0.85,"ap":0.15}
const SPELL = {"ap":1.0}
const GUARD = {"ap":0.25,"armor":0.35,"hp":0.40}
const HEAL = {"ap":0.80,"hp":0.20}
const PROFILES = {
 "gore":{"ad":0.70,"armor":0.30},"maul":PHYSICAL,"skystrike":PHYSICAL,"antlerrush":{"ad":0.80,"ap":0.20,"as":0.25},
 "vanish":PHYSICAL,"ambush":PHYSICAL,"execute":PHYSICAL,
 "smash":{"ad":0.55,"hp":0.45},"quake":{"ad":0.35,"armor":0.65},"fissure":{"ad":0.35,"armor":0.65},
 "whirl":{"ad":0.85,"armor":0.15,"as":0.35},"triplebite":{"ad":0.85,"ap":0.15,"as":0.40},
 "threefold":{"ad":0.55,"ap":0.45,"as":0.35},"barrage":{"ad":0.75,"ap":0.25,"as":0.40},
 "venom":{"ad":0.55,"ap":0.45},"drain":{"ad":0.60,"ap":0.40},"boulder":{"ad":0.80,"ap":0.20},
 "bulwark":GUARD,"shellup":GUARD,"prideroar":GUARD,"frostroar":GUARD,"stonedive":{"ad":0.30,"armor":0.70},"ward":GUARD,
 "radiance":HEAL,"rootbloom":HEAL,"renew":HEAL,"tidal":{"ap":0.65,"hp":0.35},"regrowth":{"ap":0.20,"hp":0.80},
 "rally":{"ap":0.50,"hp":0.50},"tailwind":{"ap":0.75,"hp":0.25},"hunger":{"ad":0.75,"hp":0.25,"as":0.25},
 "howl":{"ad":0.55,"ap":0.45},"brood":SPELL,"foxfire":SPELL,
 "acid":SPELL,"flamewave":SPELL,"magma":SPELL,"chain":SPELL,"stormcall":SPELL,"gaze":SPELL,"riddle":SPELL,
 "meteor":SPELL,"toxic":SPELL,"gust":SPELL,"wisps":SPELL,"silence":SPELL,"beam":SPELL,"storm":SPELL,"frost":SPELL,"roots":SPELL,"fire":SPELL,"fear":SPELL,
}

static var audit_book: Dictionary = {}
static func audited(sp: String,key: String) -> Dictionary:
 if audit_book.is_empty():audit_book=JSON.parse_string(FileAccess.get_file_as_string("res://data/skill-audit.json"))
 return audit_book.get(sp,{}).get(key,{})

static func profile(sp: String,effect: String,key: String="") -> Dictionary:
 var entry=audited(sp,key if not key.is_empty() else "signature")
 if not entry.is_empty() and entry.effect==effect:return entry.scaling
 var fallback=PROFILES.get(effect,SPELL).duplicate(true)
 var primary=audited(sp,"signature").get("build_path","ap")
 fallback[primary]=fallback.get("ad",0.0)+fallback.get("ap",0.0)
 fallback.erase("ap" if primary=="ad" else "ad")
 return fallback

static func power(unit: Dictionary,effect: String,key: String="") -> float:
 var p=profile(unit.hero.sp,effect,key)
 var armor_power=unit.skill_base*(1.0+clampf((unit.armor-unit.base_armor)*3.0,-0.35,1.0))
 var health_power=unit.skill_base*unit.max_hp/(unit.base_hp*CombatPacing.HP_SCALE)
 var value=unit.attack*p.get("ad",0.0)+unit.ability_power*p.get("ap",0.0)+armor_power*p.get("armor",0.0)+health_power*p.get("hp",0.0)
 var rate=clampf(unit.base_interval/unit.interval,0.65,1.75)
 return value*(1.0+p.get("as",0.0)*(rate-1.0))

static func description(sp: String,effect: String,skill_key: String="") -> String:
 var p=profile(sp,effect,skill_key);var parts=[]
 for key in ["ad","ap","armor","hp"]:
  if p.get(key,0.0)>0:parts.append("%d%% %s"%[roundi(p[key]*100),{"ad":"attack damage","ap":"ability power","armor":"armor power","hp":"health power"}[key]])
 var text="Scaling: "+" + ".join(parts)+"."
 if p.get("as",0.0)>0:text+=" Attack speed also boosts this skill (capped)."
 return text+" Ability haste lowers cooldowns; it does not increase hit damage."

static func magical(sp: String,effect: String,key: String="") -> bool:
 var entry=audited(sp,key if not key.is_empty() else "signature")
 if not entry.is_empty() and entry.effect==effect:return entry.magical
 if effect=="meteor":return sp!="cyclops"
 return effect not in ["gore","maul","skystrike","antlerrush","vanish","ambush","execute","smash","quake","fissure","whirl","triplebite","barrage","boulder","stonedive"]

static func build_weights(hero: Dictionary) -> Dictionary:
 HeroData.load_data()
 var out={"ad":0.0,"ap":0.0,"armor":0.0,"hp":0.0,"as":0.0,"cd":0.55}
 var profiles=[profile(hero.sp,HeroData.species[hero.sp].ab)]
 for key in hero.get("learned",{}):
  var a=HeroData.learned_ability(hero.sp,int(key));profiles.append(profile(hero.sp,a.effect,str(key)))
 var gi=Evolutions.grant_index(str(hero.get("evolution","")))
 if gi>=0:
  var a=HeroData.learned_ability(hero.sp,gi);profiles.append(profile(hero.sp,a.effect,str(gi)))
 for p in profiles:
  for key in ["ad","ap","armor","hp","as"]:out[key]+=p.get(key,0.0)/profiles.size()
 var role=HeroData.species[hero.sp].role
 var primary=audited(hero.sp,"signature").get("build_path","ap")
 if role in ["Ranged","Duelist","Skirmisher","Assassin","Diver","Bruiser"]:out[primary]+=0.40;out["as"]+=0.40
 if role=="Artillery":out[primary]+=0.40;out["as"]+=0.20
 if role in ["Tank","Warden","Bruiser"]:out.armor+=0.50;out.hp+=0.50
 if role=="Support":out.hp+=0.15;out.cd+=0.20
 var on_hit=Evolutions.perk(hero,"on_hit",null)
 if on_hit is Array:
  out["as"]+=0.30
  if str(on_hit[0]) in ["burn","venom"]:out[primary]+=0.15
 if float(Evolutions.perk(hero,"lifesteal",0.0))>0.0:
  out.ad+=0.15;out["as"]+=0.15
 var goal={"Attack damage":"ad","Ability power":"ap","Attack speed":"as","Armor":"armor","Cooldowns":"cd"}.get(str(hero.get("build_goal","Adaptive")),"")
 if not goal.is_empty():out[goal]*=1.5
 out.ap*=Evolutions.mod(hero,"potency")
 out.ad*=Evolutions.mod(hero,"attack")
 out["as"]*=Evolutions.mod(hero,"haste")
 return out
