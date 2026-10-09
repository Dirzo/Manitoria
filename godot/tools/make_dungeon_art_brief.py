"""Builds the dungeon art brief: 10 zones x (5 mobs + 1 Warden) + 10 zone backdrops.
Writes godot/data/dungeon-art-manifest.json and DUNGEON-ART-BRIEF.md. Run from the repo root: python3 godot/tools/make_dungeon_art_brief.py"""
import json, os

STYLE_CREATURE = ("Rich hand-painted fantasy concept art in the style of a premium dark-fantasy auto-battler, "
    "chunky readable stylised proportions, crisp sculptural forms, clear material separation (hide, bone, metal, crystal, cloth). "
    "Full body, standing in a neutral ready pose, three-quarter front view, whole creature in frame with a little margin, "
    "plain flat light-grey background, soft even studio lighting, no cast shadow, no motion blur, no particles hiding the body, "
    "no text, no UI, no watermark. One creature only. Designed so it can be turned into a 3D model.")
STYLE_BOSS = ("Rich hand-painted dark-fantasy concept art of a dungeon boss, heroic scale, imposing silhouette, ornate signature details, "
    "full body in a menacing neutral stance, three-quarter front view, whole figure in frame with margin, plain flat dark-grey background, "
    "dramatic but even key light with a coloured rim light, no cast shadow, no text, no UI, no watermark. One creature only. Designed so it can be turned into a 3D model.")
STYLE_BACKDROP = ("Wide 16:9 painted dark-fantasy environment matte painting for a game map screen, atmospheric depth, strong value structure "
    "with a darker centre band where UI will sit, no characters, no text, no UI, no watermark.")

Z = [
 ("blight_forest","The Blight Forest","sickly lime green, rotten brown and bone white","dead black trees, toxic green pools, thorn thickets, drifting spores, a rotted cathedral of roots",[
  ("gloomfang","Gloomfang","mob","direwolf","Fast pack hunter","A gaunt, mange-ridden wolf with bark-like scabs, glowing lime eyes, moss and fungus growing along its spine, long yellowed fangs, ragged ears."),
  ("thornback","Thornback Troll","mob","troll","Tank; thorns stun attackers","A hulking hunched troll whose back is a forest of black thorns and bramble, mossy green-grey skin, a gnarled root club, small angry eyes under a heavy brow."),
  ("sporeling","Sporeling","mob","treant","Small healer that spreads spores","A knee-high walking sapling-mushroom creature, a puffball cap that leaks glowing green spores, twig limbs, a sleepy hollow face, roots for feet."),
  ("rotwing","Rotwing","mob","wyvern","Ranged; blighted venom","A lean two-legged wyvern with torn, leaf-veined wings, rotting olive scales, a dripping acid-green throat sac, a barbed tail."),
  ("blightmaw_toad","Blightmaw Toad","mob","basilisk","NEW · ranged acid artillery","A bloated giant toad covered in pustules and lichen, a wide maw dripping glowing acid, warty mottled green-black skin, stubby powerful legs, little bone charms tangled on its back."),
  ("rootmother","The Rootmother","boss","treant","Summons Sporelings, regrows","A towering ancient tree-matriarch, a hollow mother's face carved into a cracked trunk, a crown of dead branches hung with glowing spore pods, root-tendril arms, a cradle of sporelings nestled in her chest, toxic green inner light."),
 ]),
 ("mana_caverns","The Mana Caverns","electric cyan, deep sapphire and white light","giant glowing crystal clusters, crystal spires, mirror-still underground lakes, veins of raw mana in the rock",[
  ("mana_wisp","Mana Wisp","mob","kirin","Fragile arcane caster","A small floating spirit-deer made of flowing cyan light, a crystal shard core in its chest, wisp tail, translucent body with sparkles, gentle glowing eyes."),
  ("crystal_golem","Crystal Golem","mob","golem","Slow, armoured","A blocky stone golem studded with huge cyan crystal growths on shoulders and back, glowing seams, heavy fists, a faceted gem for a face."),
  ("glimmerfox","Glimmerfox","mob","kitsune","Dodgy skirmisher","A sleek fox with prismatic crystalline fur tips, three tails that end in glowing shards, mirrored eyes, light refracting off its coat."),
  ("shardscale","Shardscale","mob","basilisk","Crystallising gaze","A low six-legged lizard covered in overlapping crystal scales, a frilled crest of shards, a glowing cyan gaze."),
  ("geode_mimic","Geode Mimic","mob","zaratan","NEW · ambusher tank","A large cracked geode boulder that splits open into a toothy maw lined with amethyst crystals, stubby stone legs, a long crystal tongue, curious glinting eyes inside the shell."),
  ("prismatic_archon","The Prismatic Archon","boss","sphinx","Mana surge silences the squad; shields at half health","A majestic crystal sphinx-angel, a lion's body of faceted glass, six prism wings fanned like a halo, a serene masked face, a floating ring of rotating crystal shards, cyan and violet light bleeding from its cracks."),
 ]),
 ("magma_depths","The Magma Depths","molten orange, ember red and basalt black","lava rivers, molten-veined basalt, lavafalls, ruined dwarven forges, chains and anvils",[
  ("ember_imp","Ember Imp","mob","salamander","Explosive caster","A small impish fire salamander with a mischievous grin, cracked charcoal skin over glowing magma, flame tongue, tiny horns, a burning tail."),
  ("magma_hound","Magma Hound","mob","cerberus","Molten jaws","A muscular hound of cooled black lava with molten orange cracks, a mane of flame, glowing jaws dripping magma, obsidian claws."),
  ("slagbrute","Slagbrute","mob","minotaur","Hulking forge guard","A massive bull-headed forge guardian in slag-encrusted iron armour, a cooling ingot hammer, soot-black hide, glowing furnace chest vents."),
  ("ash_golem","Ash Golem","mob","golem","Shields itself when cracked","A golem of grey compacted ash and cinder with embers glowing in its cracks, smoke rising from its shoulders, crumbling heavy fists."),
  ("cinder_wyrmling","Cinder Wyrmling","mob","wyvern","NEW · ranged fire breather","A young lava drake with small ember wings, obsidian horn nubs, a glowing belly, a smoking snout and a tail ending in a coal-like club."),
  ("forge_tyrant","Magmaw, the Forge Tyrant","boss","minotaur","Stunning slams; enrages","A colossal molten minotaur king, horns of black iron, a crown of chains fused to his skull, a furnace for a chest with roaring flame inside, a gigantic anvil-headed warhammer, lava dripping from his armour plates."),
 ]),
 ("frostbound_crypt","The Frostbound Crypt","ice blue, pale silver and grave white","ice shards, frozen sarcophagi, snow drifts, frozen pillars, falling snow in a tomb",[
  ("rimefang","Rimefang","mob","direwolf","Numbing bite","A white wolf with icicles forming along its ruff and spine, frosted pale blue eyes, a breath of cold mist, crystallised claws."),
  ("frost_wraith","Frost Wraith","mob","wendigo","Fast, hungry","A tall emaciated ice spirit with antlers of frost, a skull-like face, tattered robes of frozen mist, long clawed hands, a cold blue inner glow."),
  ("glacier_yeti","Glacier Yeti","mob","yeti","Tanky snowdrift","A huge shaggy yeti with blue-white fur, glacier ice plates grown over its shoulders and forearms, a broad flat face, enormous hands."),
  ("rime_harpy","Rime Harpy","mob","harpy","Diving striker","A harpy with frost-white feathers tipped in ice crystals, a pale blue face mask of frost, talons of ice, a frozen tattered shawl."),
  ("icebound_revenant","Icebound Revenant","mob","minotaur","NEW · armoured melee","An undead knight partly encased in a block of clear ice, an old crypt helm and rusted plate armour, a frost-covered greatsword, cold blue eyes glowing through the visor."),
  ("frost_matriarch","The Frost Matriarch","boss","yeti","Blizzard slows everyone; enrages","An ancient queen of the crypt, a towering frost giantess with a crown of icicles, a long cloak of snow and frozen fur, a staff topped with a frozen heart, a swirling blizzard around her hem, glowing pale eyes."),
 ]),
 ("drowned_sanctum","The Drowned Sanctum","deep teal, sea-glass green and pearl","a flooded temple, broken marble columns, coral and barnacles, shafts of light through water, kelp",[
  ("tide_naga","Tide Naga","mob","naga","Caster that sings the sea","A serpent-tailed sea priestess with teal scales, a fin crest, pearl jewellery, a coral trident, flowing kelp hair."),
  ("brine_serpent","Brine Serpent","mob","basilisk","Coiling bruiser","A thick sea serpent with barnacled dark-blue scales, a frilled head, rows of needle teeth, kelp hanging from its coils."),
  ("shellback","Shellback","mob","zaratan","Small fortress","A squat turtle-crab with a coral-encrusted shell, oversized armoured claws, barnacles and small anemones on its back."),
  ("siren","Siren","mob","harpy","Charming caster","A beautiful but eerie bird-woman with sea-green feathers, a pearl-white face, webbed talons, a shell ornament on her brow."),
  ("drowned_priest","Drowned Priest","mob","naga","NEW · healer","A fish-headed cleric in waterlogged temple robes, barnacles on the shoulders, a censer that leaks glowing sea mist, webbed hands, sad pale eyes."),
  ("leviathan","The Drowned Leviathan","boss","basilisk","Tidal slams, Sirens, regeneration","An enormous ancient sea-wyrm rising from the flood, a temple bell and broken columns tangled in its coils, coral armour plates, a vast mouth of jagged teeth, bioluminescent teal spots, kelp streaming from its fins."),
 ]),
 ("fungal_hollows","The Fungal Hollows","violet, magenta and bioluminescent cyan","giant glowing mushrooms in three colours, spore clouds, mycelium threads, damp caves",[
  ("mycelid","Mycelid","mob","treant","Walking grove","A humanoid made of stacked mushroom caps and mycelium threads, a frilly cap head with glowing gills, fibrous limbs, a peaceful empty face."),
  ("spore_spider","Spore Spider","mob","arachne","Leaves spores behind","A spider with a bulbous glowing mushroom on its abdomen, fuzzy violet legs, many tiny glowing eyes, spore dust drifting from its body."),
  ("capbear","Capbear","mob","owlbear","Plated bruiser","A big bear covered in shelf-fungus plates like armour, a mushroom-cap hood over its head, glowing magenta spots, strong claws."),
  ("glowmoth","Glowmoth","mob","pegasus","Healing dust","A large moth with luminous lilac wings patterned like eyes, a fuzzy body, feathered antennae, glowing dust falling from its wings."),
  ("puffcap_bomber","Puffcap Bomber","mob","jackalope","NEW · explodes on death","A round waddling puffball mushroom creature with a big grin, swollen cap ready to burst, tiny legs, bright warning-orange spots, a lit fuse-like stem."),
  ("spore_queen","The Spore Queen","boss","arachne","Hatches Spore Spiders; choking clouds","A regal spider-queen with a huge glowing mushroom crown, a towering bloated abdomen full of spore sacs, elegant long legs, a veil of mycelium threads, magenta and cyan bioluminescence."),
 ]),
 ("ossuary_of_kings","The Ossuary of Kings","bone ivory, candle gold and black","bone piles, stacked skulls, horned skulls, guttering candles, falling ash, crumbling royal tombs",[
  ("bone_gargoyle","Bone Gargoyle","mob","gargoyle","Armoured striker","A gargoyle built from fused ribs and skulls, bone wings with no membrane, a horned skull face, glowing ember eyes."),
  ("grave_hound","Grave Hound","mob","cerberus","Three-headed skeletal hound","A three-headed skeletal hound with a spiked collar, ghostly green flame in its ribcage, cracked yellowed bones."),
  ("crypt_knight","Crypt Knight","mob","minotaur","Armoured guard","A horned skeletal knight in ancient royal plate armour with a tattered tabard, a great axe, a faded crown sigil on its shield."),
  ("wight","Wight","mob","nekomata","Quick killer","A pale undead cat-like stalker, stretched grey skin over bone, two tails, long dagger claws, burning white pupils."),
  ("ossuary_priest","Ossuary Priest","mob","sphinx","NEW · necromancer caster","A hunched skeletal priest in black and gold funeral robes, a mitre made of finger bones, a censer of grave smoke, candles melted onto its shoulders."),
  ("bone_king","The Bone King","boss","minotaur","Raises Bone Gargoyles behind shields; enrages","A gigantic skeletal king on a pile of crowns, a great horned crown fused to his skull, a cloak of royal velvet rotted to rags, a sceptre topped with a screaming skull, ghostly gold fire in his eye sockets."),
 ]),
 ("storm_spire","The Storm Spire","electric yellow, slate grey and storm violet","iron lightning pylons, floating rocks, a tower in the clouds, sparks and rain",[
  ("storm_harpy","Storm Harpy","mob","harpy","Fast striker","A harpy with slate-grey feathers crackling with yellow lightning, a copper face guard, wind-swept crest."),
  ("thunderhawk","Thunderhawk","mob","griffin","Burst striker","A griffin with storm-cloud grey plumage, golden lightning streaks along its wings, a beak of polished brass."),
  ("spark_kirin","Spark Kirin","mob","kirin","Chain caster","A slender kirin with a mane of crackling electric arcs, yellow-white scales, a single lightning-rod horn."),
  ("galvanic_golem","Galvanic Golem","mob","golem","Answers spells with lightning","An iron and copper construct with coils on its shoulders, a glass capacitor chest glowing with trapped lightning, riveted plates."),
  ("tempest_elemental","Tempest Elemental","mob","phoenix","NEW · flying caster","A living storm cloud shaped like a winged figure, swirling dark vapour, a bright lightning core, rain trailing from its lower body."),
  ("tempest_roc","The Tempest Roc","boss","griffin","Chain lightning stuns the squad","A colossal storm bird with a wingspan full of thunderclouds, feathers like iron blades, lightning crackling between its talons, a crown of floating rocks orbiting its head."),
 ]),
 ("gilded_tomb","The Gilded Tomb","burnished gold, lapis blue and sandstone","sandstone obelisks with gold caps, painted sarcophagi, braziers, hieroglyph walls, drifting sand",[
  ("sand_manticore","Sand Manticore","mob","manticore","Critical striker","A manticore with a sand-coloured lion body, a scorpion tail of gold-plated segments, a lapis-blue mane braided with gold rings."),
  ("tomb_jackal","Tomb Jackal","mob","jackalope","Fast guardian","A gilded jackal guardian with long ears, a golden collar and headdress, black fur and gold markings, glowing amber eyes."),
  ("mummified_lion","Mummified Lion","mob","nemean","Tank","A lion wrapped in ancient linen bandages, a golden funerary mask, a mane of dried papyrus, gaps showing dark dried flesh."),
  ("scarab_golem","Scarab Golem","mob","golem","Armoured","A golem shaped like a giant upright scarab beetle, emerald and gold shell plates, a sun disc on its brow, stone limbs."),
  ("gilded_asp","Gilded Asp","mob","basilisk","NEW · venom ranged","A huge cobra with gold-and-lapis banded scales, a hood painted like a sun disc, ruby eyes, a jewelled crown on its head."),
  ("sun_pharaoh","The Sun-Eater Pharaoh","boss","sphinx","Sunfire slams; golden wards with Tomb Jackals","A towering undead pharaoh in golden armour and a tall double crown, a radiant sun disc held behind him like a halo, bandaged limbs, a crook and flail, burning gold eyes in a dark mummified face."),
 ]),
 ("void_rift","The Void Rift","deep violet, black and starlight white","floating void shards, glowing rune halos, broken reality, a starfield bleeding through the walls",[
  ("shade_stalker","Shade Stalker","mob","nekomata","Ambush assassin","A shadowy panther made of living darkness, its outline flickering, white star-like eyes, wisps of smoke instead of fur."),
  ("void_weaver","Void Weaver","mob","arachne","Web caster","A spider of black chitin with constellations glowing on its abdomen, legs that fade into nothing, spinning violet threads."),
  ("star_wraith","Star Wraith","mob","wendigo","Fast and hungry","A tall gaunt wraith made of night sky, stars visible through its body, antlers of black crystal, long reaching claws."),
  ("mind_eater","Mind Eater","mob","basilisk","Petrifying caster","A tentacle-faced serpent with a huge glowing third eye, violet skin, a crown of floating runes."),
  ("rift_horror","Rift Horror","mob","hydra","NEW · multi-headed bruiser","A writhing mass of black tentacles and three eyeless heads with glowing mouths, violet runes carved into its hide, small void shards orbiting it."),
  ("abyssal_keeper","The Abyssal Keeper","boss","sphinx","Shielded phases with Shade Stalkers; slams","A colossal void guardian, a faceless armoured titan whose head is a hole into the starfield, rune halos orbiting its shoulders, a cloak of darkness, great hands of black crystal."),
 ]),
]

entries = []
for zid, zname, palette, setting, mobs in Z:
    for mid, name, kind, sp, role, desc in mobs:
        style = STYLE_BOSS if kind == "boss" else STYLE_CREATURE
        prompt = f"{desc} Creature of {zname}; colour palette: {palette}. {style}"
        entries.append({"id": mid, "zone": zid, "zone_name": zname, "kind": kind, "name": name, "role": role,
            "stand_in_model": sp, "new": role.startswith("NEW"), "prompt": prompt,
            "image_file": f"godot/assets/art/dungeon/{zid}/{mid}.png",
            "meshy": {"mode": "image-to-3d", "target_polycount": 30000 if kind == "boss" else 18000, "topology": "quad", "texture": "PBR",
                      "rig": "quadruped" if sp in ("direwolf","cerberus","nemean","manticore","kitsune","nekomata","jackalope","basilisk","zaratan","hydra","owlbear","griffin","wyvern","pegasus","arachne","kirin","sphinx") else "biped",
                      "animations": ["idle", "walk", "attack", "cast", "hit", "death"],
                      "model_file": f"godot/assets/models/dungeon/{mid}.glb"}})
    entries.append({"id": f"{zid}_backdrop", "zone": zid, "zone_name": zname, "kind": "backdrop", "name": f"{zname} map backdrop", "role": "Map-screen painting",
        "prompt": f"{zname}: {setting}. Colour palette: {palette}. {STYLE_BACKDROP}", "image_file": f"godot/assets/ui/dungeon/{zid}.jpg"})

os.makedirs("godot/data", exist_ok=True)
json.dump(entries, open("godot/data/dungeon-art-manifest.json", "w"), indent=1, ensure_ascii=False)

md = ["# Dungeon art brief — mobs, Wardens and zone backdrops", "",
 "Seventy images for the dungeon visual overhaul: for each of the ten zones, **five unique mobs, one Warden boss and one map backdrop**. "
 "The four existing mobs per zone keep their names and roles; the fifth (marked **NEW**) is a new design to add to the bestiary. "
 "Every prompt is in [`godot/data/dungeon-art-manifest.json`](godot/data/dungeon-art-manifest.json), ready to paste into an image generator.", "",
 "## Pipeline", "",
 "1. **Concept image.** Generate each creature from its prompt (square, at least 1024×1024). The prompts ask for a full-body three-quarter view on a plain background with even light, which is what image-to-3D tools reconstruct best. Save to the `image_file` path.",
 "2. **Meshy image-to-3D.** Upload the concept to Meshy, quad topology, PBR textures, the polycount in the manifest (18k mobs, 30k Wardens). Regenerate until the silhouette matches; small props can be fixed in the texture pass.",
 "3. **Rig and animate in Meshy.** Use the rig type in the manifest (biped or quadruped) and export clips named exactly `idle`, `walk`, `attack`, `cast`, `hit` and `death` — the names the arena plays for the 32 champions.",
 "4. **Export GLB** to the `model_file` path. The game already looks for it (`Bestiary.model_path`): when the file exists it replaces the recoloured stand-in model (`stand_in_model`), which stays as the fallback. Wardens keep their glowing rim light.",
 "5. **Portrait.** The existing portrait renderer can frame the new model for draft cards and the map; no extra art needed.",
 "6. **Backdrops** saved to `godot/assets/ui/dungeon/<zone>.jpg` are picked up automatically and replace the six reused region paintings on the dungeon map and in the cave fights' UI (the Ossuary currently borrows the desert painting, the Fungal Hollows the forest one).", "",
 "## Consistency rules", "",
 "- One creature per image, whole body in frame, no text or UI.",
 "- Stylised, chunky proportions that read at small size on the battlefield; distinct silhouette per mob within a zone (no two mobs of a zone share a body plan).",
 "- Each zone keeps its palette across its six creatures; Wardens add a coloured rim light and an ornate signature detail.",
 "- Keep the same lighting and background across a zone so Meshy's textures match.", ""]
for zid, zname, palette, setting, mobs in Z:
    md += [f"## {zname}", "", f"*Palette:* {palette}. *Setting:* {setting}.", "", "| | Creature | Role | Stand-in model |", "|---|---|---|---|"]
    for mid, name, kind, sp, role, desc in mobs:
        md.append(f"| {'Warden' if kind=='boss' else 'Mob'} | **{name}** — {desc} | {role} | {sp} |")
    md.append("")
open("DUNGEON-ART-BRIEF.md", "w").write("\n".join(md))
print(len(entries), "entries")
