class_name CombatRange
extends RefCounted
## Hex reach is the public combat contract. Moving targets must remain inside it.
static func contains(a: Dictionary, b: Dictionary, hexes: int) -> bool:
 if a.has("next_cell"): return false
 if ArenaGrid.distance(a.cell, b.cell) > hexes: return false
 return not b.has("next_cell") or ArenaGrid.distance(a.cell, b.next_cell) <= hexes

static func signature_world(u: Dictionary) -> float:
 var key: String = HeroData.species[u.hero.sp].ab
 if key in ["shriek", "triplebite"]: return 3.2
 if key in ["gore", "venom", "skystrike", "foxfire", "stonedive", "vanish", "antlerrush", "maul"]: return 8.5
 return maxf(9.5, u.range + 1.0) if u.range > 2 else 3.2

static func basic_label(world_range: float) -> String:
 var hexes = ArenaGrid.attack_hexes(world_range)
 return "Attack · %d hex%s" % [hexes, "" if hexes == 1 else "es"]
