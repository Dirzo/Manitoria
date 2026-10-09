class_name DungeonInstances
extends RefCounted
## The ten dungeon instances. Every depth of a run is one of them, chosen from two offers at the
## top of the stairs. Each instance has its own monsters, Warden, arena dressing and palette.
##   kit       which arena set-dressing DungeonArena builds
##   art       which painted backdrop (assets/ui/regions) frames the map screen
##   accent    UI and light colour · floor / fog / sky: arena palette · motes: floating particles

const ALL := {
 "blight_forest": {"name": "The Blight Forest", "kit": "blight", "art": "forest", "accent": "a6e05a", "floor": "3a4630", "fog": "26301c", "sky": "d8f0a0", "ambient": "8aa860", "motes": "c8f070",
  "tagline": "Rot, roots and things that heal as fast as they bleed.", "mobs": ["gloomfang", "thornback", "sporeling", "rotwing", "blightmaw_toad"], "boss": "rootmother"},
 "mana_caverns": {"name": "The Mana Caverns", "kit": "crystals", "art": "astral", "accent": "5ad8ff", "floor": "26364a", "fog": "102030", "sky": "a8e8ff", "ambient": "6ab0e0", "motes": "8af0ff",
  "tagline": "Raw magic grows here like crystal. So do the things that feed on it.", "mobs": ["mana_wisp", "crystal_golem", "glimmerfox", "shardscale", "geode_mimic"], "boss": "prismatic_archon"},
 "magma_depths": {"name": "The Magma Depths", "kit": "lava", "art": "volcanic", "accent": "ff7a30", "floor": "3a2622", "fog": "2a1008", "sky": "ffb070", "ambient": "c86a40", "motes": "ffa040",
  "tagline": "Rivers of fire and the forges of a fallen empire.", "mobs": ["ember_imp", "magma_hound", "slagbrute", "ash_golem", "cinder_wyrmling"], "boss": "forge_tyrant"},
 "frostbound_crypt": {"name": "The Frostbound Crypt", "kit": "ice", "art": "glacial", "accent": "a8e0ff", "floor": "4a5a6a", "fog": "1a2838", "sky": "e0f4ff", "ambient": "9ac0e0", "motes": "ffffff",
  "tagline": "A tomb sealed in ice. The cold here is hungry.", "mobs": ["rimefang", "frost_wraith", "glacier_yeti", "rime_harpy", "icebound_revenant"], "boss": "frost_matriarch"},
 "drowned_sanctum": {"name": "The Drowned Sanctum", "kit": "water", "art": "coastal", "accent": "4ab8e0", "floor": "24424a", "fog": "0c2430", "sky": "9ad8f0", "ambient": "5a9ab8", "motes": "a8e8ff",
  "tagline": "A temple the sea swallowed whole. Its priests never left.", "mobs": ["tide_naga", "brine_serpent", "shellback", "siren", "drowned_priest"], "boss": "leviathan"},
 "fungal_hollows": {"name": "The Fungal Hollows", "kit": "fungal", "art": "forest", "accent": "c08aff", "floor": "2e2638", "fog": "1a1028", "sky": "e0b8ff", "ambient": "9a70c8", "motes": "e8a8ff",
  "tagline": "Glowing caps the size of houses, and spores in every breath.", "mobs": ["mycelid", "spore_spider", "capbear", "glowmoth", "puffcap_bomber"], "boss": "spore_queen"},
 "ossuary_of_kings": {"name": "The Ossuary of Kings", "kit": "bones", "art": "desert", "accent": "e8dcc0", "floor": "3a3630", "fog": "1a1814", "sky": "f0e0c0", "ambient": "a89a80", "motes": "d8d0b8",
  "tagline": "Every king of the old realm, stacked to the ceiling.", "mobs": ["bone_gargoyle", "grave_hound", "crypt_knight", "wight", "ossuary_priest"], "boss": "bone_king"},
 "storm_spire": {"name": "The Storm Spire", "kit": "storm", "art": "coastal", "accent": "ffe85a", "floor": "343a44", "fog": "141820", "sky": "fff4b0", "ambient": "a0a8c0", "motes": "fff08a",
  "tagline": "A tower that drinks lightning. The air itself crackles.", "mobs": ["storm_harpy", "thunderhawk", "spark_kirin", "galvanic_golem", "tempest_elemental"], "boss": "tempest_roc"},
 "gilded_tomb": {"name": "The Gilded Tomb", "kit": "tomb", "art": "desert", "accent": "f0c050", "floor": "5a4a30", "fog": "2a2010", "sky": "ffe0a0", "ambient": "c8a060", "motes": "ffd890",
  "tagline": "Gold, sand and a pharaoh who refuses to stay dead.", "mobs": ["sand_manticore", "tomb_jackal", "mummified_lion", "scarab_golem", "gilded_asp"], "boss": "sun_pharaoh"},
 "void_rift": {"name": "The Void Rift", "kit": "void", "art": "astral", "accent": "b9a2ff", "floor": "221a34", "fog": "0a0614", "sky": "c8b8ff", "ambient": "7a6ab0", "motes": "c8a8ff",
  "tagline": "Where the dungeon ends and something else begins.", "mobs": ["shade_stalker", "void_weaver", "star_wraith", "mind_eater", "rift_horror"], "boss": "abyssal_keeper"},
}
const ORDER := ["blight_forest", "mana_caverns", "magma_depths", "frostbound_crypt", "drowned_sanctum", "fungal_hollows", "ossuary_of_kings", "storm_spire", "gilded_tomb", "void_rift"]

static func info(id: String) -> Dictionary:
 return ALL.get(id, ALL.blight_forest)

## Two instances the guild has not visited this cycle (every instance is visited once before any repeats).
static func offer(visited: Array, salt: String) -> Array:
 var cycle = visited.slice(visited.size() - (visited.size() % ORDER.size()))
 var fresh = ORDER.filter(func(id): return id not in cycle)
 var rng = RandomNumberGenerator.new(); rng.seed = hash(salt + "|instances|" + str(visited.size()))
 RunTraits.shuffle(fresh, rng)
 if fresh.size() >= 2: return fresh.slice(0, 2)
 # The last unvisited instance, paired with any other except the one just cleared.
 var others = ORDER.filter(func(id): return id not in fresh and (visited.is_empty() or id != visited[-1]))
 RunTraits.shuffle(others, rng)
 return fresh + others.slice(0, 2 - fresh.size())

## The painted backdrop for an instance (one of the six region paintings).
static func art(id: String) -> Texture2D:
 # A zone's own painting (see DUNGEON-ART-BRIEF.md) when it exists; otherwise the closest region painting.
 var own = "res://assets/ui/dungeon/%s.jpg" % id
 if ResourceLoader.exists(own): return load(own)
 return load("res://assets/ui/regions/%s.jpg" % str(info(id).art))

static func theme_name(id: String) -> String:
 return {"forest": "Forest", "astral": "Astral", "volcanic": "Volcanic", "glacial": "Glacial", "coastal": "Coastal", "desert": "Desert"}.get(str(info(id).art), "Astral")
