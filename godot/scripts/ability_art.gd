class_name AbilityArt
extends RefCounted
const KEYS = ["gore","bulwark","smash","hunger","howl","venom","skystrike","foxfire","acid","shriek","flamewave","chain","gaze","rootbloom","tidal","radiance","triplebite","prideroar","frostroar","shellup","maul","regrowth","threefold","stonedive","vanish","antlerrush","boulder","stormcall","riddle","tailwind","brood","magma","quake","rally","fissure","ward","meteor","renew","drain","fear","ambush","toxic","execute","gust","wisps","barrage","silence","beam","storm","frost","roots","fire","whirl","ravager","guardian","arcanist","vigor","force","focus","basic","blocked","rebirth","victory","summons"]
static func texture(key: String) -> Texture2D:
 if key.begins_with("item:"):
  var ipath="res://assets/items/i_%s.png" % key.trim_prefix("item:")
  if ResourceLoader.exists(ipath): return load(ipath)
  key=Forge.ITEMS.get(key.trim_prefix("item:"),{}).get("art","ward")
 if key.begins_with("comp:"):
  var cpath="res://assets/items/%s.png" % key.trim_prefix("comp:")
  if ResourceLoader.exists(cpath): return load(cpath)
  key="ward"
 if key.begins_with("discovery:"):
  var parts=key.split(":")
  var path="res://assets/abilities/%s-%s.png" % [parts[1],parts[2]]
  if ResourceLoader.exists(path): return load(path)
  key=HeroData.learned_ability(parts[1],int(parts[2])).effect
 var atlas = load("res://assets/ability-atlas.png") as Texture2D
 var index = KEYS.find(key)
 if index < 0: index = 58
 var tile = Vector2(atlas.get_width()/8.0,atlas.get_height()/8.0)
 var image = AtlasTexture.new(); image.atlas = atlas; image.filter_clip = true
 image.region = Rect2(Vector2(index%8,index/8)*tile+Vector2(2,2),tile-Vector2(4,4))
 return image
static func card_key(hero: Dictionary, card: Dictionary) -> String:
 if card.type == "ability": return "discovery:%s:%s" % [hero.sp,card.key]
 if card.type == "signature": return HeroData.species[hero.sp].ab
 if card.type == "evolution" and Evolutions.has(str(card.key)): return Evolutions.art(card.key)
 if card.type == "apex":
  if card.key == "apex_skill" and Evolutions.has(str(hero.get("evolution", ""))): return Evolutions.art(hero.evolution)
  return {"apex_stats": "renew", "apex_slot": "ward"}.get(str(card.key), "ward")
 return card.key
static func metric_info(sp: String, key: String) -> Dictionary:
 if key.begins_with("item:"):
  var item=ItemEffects.definition(key.trim_prefix("item:"))
  return {"name":item.get("name","Equipment"),"art":item.get("art","ward")}
 if key == "signature": return {"name":HeroData.species[sp].ability_name,"art":HeroData.species[sp].ab}
 if key.begins_with("ability:"):
  var a = HeroData.learned_ability(sp,int(key.trim_prefix("ability:"))); return {"name":a.name,"art":"discovery:%s:%s" % [sp,a.key]}
 return {"name":{"basic":"Basic attacks","summons":"Summoned allies","lifesteal":"Ravager lifesteal","regeneration":"Natural regeneration","incoming":"Incoming damage"}.get(key,key.capitalize()),"art":{"lifesteal":"drain","regeneration":"renew"}.get(key,key)}

static func icon(parent: Node,key: String,pixels: int) -> TextureRect:
 var image=TextureRect.new(); image.texture=texture(key)
 image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 image.custom_minimum_size=Vector2(pixels,pixels)
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 parent.add_child(image)
 return image
