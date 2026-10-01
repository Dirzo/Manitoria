class_name ChampionEvolution
extends RefCounted
const NAMES={
 "minotaur":"Labyrinth Sovereign","golem":"Living Mountain","troll":"Mossblood Colossus","wendigo":"Winter Devourer",
 "direwolf":"Moonfang Alpha","manticore":"Venom Sovereign","griffin":"Crown of the Skies","kitsune":"Ninefold Oracle",
 "wyvern":"Plaguewing","harpy":"Storm Siren","phoenix":"Dawn Eternal","kirin":"Heaven's Thunder",
 "basilisk":"Obsidian Monarch","treant":"Worldroot Ancient","naga":"Pearl Empress","unicorn":"Astral Paragon",
 "cerberus":"Hellgate Warden","nemean":"Sunmane Sovereign","yeti":"Avalanche King","zaratan":"Wandering Continent",
 "owlbear":"Ironfeather Apex","hydra":"Undying Crown","chimera":"Threefold Tyrant","gargoyle":"Cathedral Sentinel",
 "nekomata":"Twilight Reaver","jackalope":"Briarwild Trickster","cyclops":"Mountain's Eye","thunderbird":"Tempest Incarnate",
 "sphinx":"Oracle of Ages","pegasus":"Dawn Herald","arachne":"Widow Empress","salamander":"Molten Heart"}
const EFFECTS={
 "minotaur":"fissure","golem":"ward","troll":"renew","wendigo":"drain","direwolf":"rally","manticore":"toxic",
 "griffin":"gust","kitsune":"wisps","wyvern":"toxic","harpy":"silence","phoenix":"renew","kirin":"storm",
 "basilisk":"frost","treant":"roots","naga":"renew","unicorn":"ward","cerberus":"fire","nemean":"rally",
 "yeti":"meteor","zaratan":"quake","owlbear":"whirl","hydra":"renew","chimera":"fire","gargoyle":"ward",
 "nekomata":"execute","jackalope":"ambush","cyclops":"beam","thunderbird":"storm","sphinx":"silence",
 "pegasus":"gust","arachne":"roots","salamander":"fire"}
static func info(hero: Dictionary) -> Dictionary:
 var sp=hero.get("sp","minotaur");var effect=EFFECTS[sp]
 return {"name":NAMES[sp],"color":color(sp).to_html(false),"description":"Ascended action: "+HeroData.EFFECTS[effect][0]+" Every 20s. Keeps your four abilities; -10% attack. A larger silhouette and elemental crest mark your evolution."}
static func color(sp: String) -> Color:
 var colors={"fire":"ffa35b","storm":"8bdfff","renew":"97eda6","ward":"ffe3a1","roots":"78ce92","toxic":"b7ed69","frost":"a9e5ff","drain":"d591d8","silence":"cbb1ff"}
 return Color(colors.get(EFFECTS[sp],"ffca83"))
static func action(sp: String) -> Dictionary:
 var effect=EFFECTS[sp];var spec=HeroData.EFFECTS[effect]
 return {"key":"12","name":NAMES[sp],"effect":effect,"description":spec[0],"cooldown":20.0,"range":spec[2]}
