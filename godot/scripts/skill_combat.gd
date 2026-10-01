class_name SkillCombat
extends RefCounted

const COLORS = {"minotaur":"ffb657","golem":"70e3ff","troll":"9cde72","wendigo":"a7e8ff","direwolf":"98caff","manticore":"d896ff","griffin":"ffe39a","kitsune":"d1a0ff","wyvern":"b3e86f","harpy":"88eadc","phoenix":"ffab61","kirin":"ffeab1","basilisk":"88eead","treant":"abe87c","naga":"70e6cb","unicorn":"fff0bd","cerberus":"ff9870","nemean":"ffcf70","yeti":"b0edff","zaratan":"78dfd7","owlbear":"e9c184","hydra":"a4ec77","chimera":"ffb881","gargoyle":"baa4ff","nekomata":"efa1ee","jackalope":"d7ec97","cyclops":"ffca79","thunderbird":"8cd9ff","sphinx":"e3c5ff","pegasus":"d7eeff","arachne":"d6a2fa","salamander":"ff9966"}

static func tint(species: String) -> Color:
 return Color(COLORS.get(species, "ffe0a1"))

static func windup(effect: String) -> float:
 match effect:
  "ambush", "vanish", "execute", "venom", "antlerrush": return 0.40
  "barrage", "wisps", "gust", "silence", "gore", "maul": return 0.50
  "renew", "ward", "rally", "radiance", "rootbloom", "tidal", "regrowth": return 0.65
  "quake", "whirl", "fear", "roots", "frost", "smash", "frostroar": return 0.80
  "beam", "fissure", "storm", "stormcall", "flamewave": return 0.90
  "meteor", "boulder", "magma": return 1.05
 return 0.60

static func self_centered(effect: String) -> bool:
 return effect in ["renew", "ward", "rally", "quake", "whirl", "fear", "shriek", "triplebite", "bulwark", "prideroar", "shellup", "frostroar", "radiance", "rootbloom", "tidal", "regrowth", "tailwind", "hunger", "howl", "brood"]
