# Dungeon art brief — mobs, Wardens and zone backdrops

Seventy images for the dungeon visual overhaul: for each of the ten zones, **five unique mobs, one Warden boss and one map backdrop**. The four existing mobs per zone keep their names and roles; the fifth (marked **NEW**) is a new design to add to the bestiary. Every prompt is in [`godot/data/dungeon-art-manifest.json`](godot/data/dungeon-art-manifest.json), ready to paste into an image generator.

## Pipeline

1. **Concept image.** Generate each creature from its prompt (square, at least 1024×1024). The prompts ask for a full-body three-quarter view on a plain background with even light, which is what image-to-3D tools reconstruct best. Save to the `image_file` path.
2. **Meshy image-to-3D.** Upload the concept to Meshy, quad topology, PBR textures, the polycount in the manifest (18k mobs, 30k Wardens). Regenerate until the silhouette matches; small props can be fixed in the texture pass.
3. **Rig and animate in Meshy.** Use the rig type in the manifest (biped or quadruped) and export clips named exactly `idle`, `walk`, `attack`, `cast`, `hit` and `death` — the names the arena plays for the 32 champions.
4. **Export GLB** to the `model_file` path. The game already looks for it (`Bestiary.model_path`): when the file exists it replaces the recoloured stand-in model (`stand_in_model`), which stays as the fallback. Wardens keep their glowing rim light.
5. **Portrait.** The existing portrait renderer can frame the new model for draft cards and the map; no extra art needed.
6. **Backdrops** saved to `godot/assets/ui/dungeon/<zone>.jpg` are picked up automatically and replace the six reused region paintings on the dungeon map and in the cave fights' UI (the Ossuary currently borrows the desert painting, the Fungal Hollows the forest one).

## Consistency rules

- One creature per image, whole body in frame, no text or UI.
- Stylised, chunky proportions that read at small size on the battlefield; distinct silhouette per mob within a zone (no two mobs of a zone share a body plan).
- Each zone keeps its palette across its six creatures; Wardens add a coloured rim light and an ornate signature detail.
- Keep the same lighting and background across a zone so Meshy's textures match.

## The Blight Forest

*Palette:* sickly lime green, rotten brown and bone white. *Setting:* dead black trees, toxic green pools, thorn thickets, drifting spores, a rotted cathedral of roots.

| | Creature | Role | Stand-in model |
|---|---|---|---|
| Mob | **Gloomfang** — A gaunt, mange-ridden wolf with bark-like scabs, glowing lime eyes, moss and fungus growing along its spine, long yellowed fangs, ragged ears. | Fast pack hunter | direwolf |
| Mob | **Thornback Troll** — A hulking hunched troll whose back is a forest of black thorns and bramble, mossy green-grey skin, a gnarled root club, small angry eyes under a heavy brow. | Tank; thorns stun attackers | troll |
| Mob | **Sporeling** — A knee-high walking sapling-mushroom creature, a puffball cap that leaks glowing green spores, twig limbs, a sleepy hollow face, roots for feet. | Small healer that spreads spores | treant |
| Mob | **Rotwing** — A lean two-legged wyvern with torn, leaf-veined wings, rotting olive scales, a dripping acid-green throat sac, a barbed tail. | Ranged; blighted venom | wyvern |
| Mob | **Blightmaw Toad** — A bloated giant toad covered in pustules and lichen, a wide maw dripping glowing acid, warty mottled green-black skin, stubby powerful legs, little bone charms tangled on its back. | NEW · ranged acid artillery | basilisk |
| Warden | **The Rootmother** — A towering ancient tree-matriarch, a hollow mother's face carved into a cracked trunk, a crown of dead branches hung with glowing spore pods, root-tendril arms, a cradle of sporelings nestled in her chest, toxic green inner light. | Summons Sporelings, regrows | treant |

## The Mana Caverns

*Palette:* electric cyan, deep sapphire and white light. *Setting:* giant glowing crystal clusters, crystal spires, mirror-still underground lakes, veins of raw mana in the rock.

| | Creature | Role | Stand-in model |
|---|---|---|---|
| Mob | **Mana Wisp** — A small floating spirit-deer made of flowing cyan light, a crystal shard core in its chest, wisp tail, translucent body with sparkles, gentle glowing eyes. | Fragile arcane caster | kirin |
| Mob | **Crystal Golem** — A blocky stone golem studded with huge cyan crystal growths on shoulders and back, glowing seams, heavy fists, a faceted gem for a face. | Slow, armoured | golem |
| Mob | **Glimmerfox** — A sleek fox with prismatic crystalline fur tips, three tails that end in glowing shards, mirrored eyes, light refracting off its coat. | Dodgy skirmisher | kitsune |
| Mob | **Shardscale** — A low six-legged lizard covered in overlapping crystal scales, a frilled crest of shards, a glowing cyan gaze. | Crystallising gaze | basilisk |
| Mob | **Geode Mimic** — A large cracked geode boulder that splits open into a toothy maw lined with amethyst crystals, stubby stone legs, a long crystal tongue, curious glinting eyes inside the shell. | NEW · ambusher tank | zaratan |
| Warden | **The Prismatic Archon** — A majestic crystal sphinx-angel, a lion's body of faceted glass, six prism wings fanned like a halo, a serene masked face, a floating ring of rotating crystal shards, cyan and violet light bleeding from its cracks. | Mana surge silences the squad; shields at half health | sphinx |

## The Magma Depths

*Palette:* molten orange, ember red and basalt black. *Setting:* lava rivers, molten-veined basalt, lavafalls, ruined dwarven forges, chains and anvils.

| | Creature | Role | Stand-in model |
|---|---|---|---|
| Mob | **Ember Imp** — A small impish fire salamander with a mischievous grin, cracked charcoal skin over glowing magma, flame tongue, tiny horns, a burning tail. | Explosive caster | salamander |
| Mob | **Magma Hound** — A muscular hound of cooled black lava with molten orange cracks, a mane of flame, glowing jaws dripping magma, obsidian claws. | Molten jaws | cerberus |
| Mob | **Slagbrute** — A massive bull-headed forge guardian in slag-encrusted iron armour, a cooling ingot hammer, soot-black hide, glowing furnace chest vents. | Hulking forge guard | minotaur |
| Mob | **Ash Golem** — A golem of grey compacted ash and cinder with embers glowing in its cracks, smoke rising from its shoulders, crumbling heavy fists. | Shields itself when cracked | golem |
| Mob | **Cinder Wyrmling** — A young lava drake with small ember wings, obsidian horn nubs, a glowing belly, a smoking snout and a tail ending in a coal-like club. | NEW · ranged fire breather | wyvern |
| Warden | **Magmaw, the Forge Tyrant** — A colossal molten minotaur king, horns of black iron, a crown of chains fused to his skull, a furnace for a chest with roaring flame inside, a gigantic anvil-headed warhammer, lava dripping from his armour plates. | Stunning slams; enrages | minotaur |

## The Frostbound Crypt

*Palette:* ice blue, pale silver and grave white. *Setting:* ice shards, frozen sarcophagi, snow drifts, frozen pillars, falling snow in a tomb.

| | Creature | Role | Stand-in model |
|---|---|---|---|
| Mob | **Rimefang** — A white wolf with icicles forming along its ruff and spine, frosted pale blue eyes, a breath of cold mist, crystallised claws. | Numbing bite | direwolf |
| Mob | **Frost Wraith** — A tall emaciated ice spirit with antlers of frost, a skull-like face, tattered robes of frozen mist, long clawed hands, a cold blue inner glow. | Fast, hungry | wendigo |
| Mob | **Glacier Yeti** — A huge shaggy yeti with blue-white fur, glacier ice plates grown over its shoulders and forearms, a broad flat face, enormous hands. | Tanky snowdrift | yeti |
| Mob | **Rime Harpy** — A harpy with frost-white feathers tipped in ice crystals, a pale blue face mask of frost, talons of ice, a frozen tattered shawl. | Diving striker | harpy |
| Mob | **Icebound Revenant** — An undead knight partly encased in a block of clear ice, an old crypt helm and rusted plate armour, a frost-covered greatsword, cold blue eyes glowing through the visor. | NEW · armoured melee | minotaur |
| Warden | **The Frost Matriarch** — An ancient queen of the crypt, a towering frost giantess with a crown of icicles, a long cloak of snow and frozen fur, a staff topped with a frozen heart, a swirling blizzard around her hem, glowing pale eyes. | Blizzard slows everyone; enrages | yeti |

## The Drowned Sanctum

*Palette:* deep teal, sea-glass green and pearl. *Setting:* a flooded temple, broken marble columns, coral and barnacles, shafts of light through water, kelp.

| | Creature | Role | Stand-in model |
|---|---|---|---|
| Mob | **Tide Naga** — A serpent-tailed sea priestess with teal scales, a fin crest, pearl jewellery, a coral trident, flowing kelp hair. | Caster that sings the sea | naga |
| Mob | **Brine Serpent** — A thick sea serpent with barnacled dark-blue scales, a frilled head, rows of needle teeth, kelp hanging from its coils. | Coiling bruiser | basilisk |
| Mob | **Shellback** — A squat turtle-crab with a coral-encrusted shell, oversized armoured claws, barnacles and small anemones on its back. | Small fortress | zaratan |
| Mob | **Siren** — A beautiful but eerie bird-woman with sea-green feathers, a pearl-white face, webbed talons, a shell ornament on her brow. | Charming caster | harpy |
| Mob | **Drowned Priest** — A fish-headed cleric in waterlogged temple robes, barnacles on the shoulders, a censer that leaks glowing sea mist, webbed hands, sad pale eyes. | NEW · healer | naga |
| Warden | **The Drowned Leviathan** — An enormous ancient sea-wyrm rising from the flood, a temple bell and broken columns tangled in its coils, coral armour plates, a vast mouth of jagged teeth, bioluminescent teal spots, kelp streaming from its fins. | Tidal slams, Sirens, regeneration | basilisk |

## The Fungal Hollows

*Palette:* violet, magenta and bioluminescent cyan. *Setting:* giant glowing mushrooms in three colours, spore clouds, mycelium threads, damp caves.

| | Creature | Role | Stand-in model |
|---|---|---|---|
| Mob | **Mycelid** — A humanoid made of stacked mushroom caps and mycelium threads, a frilly cap head with glowing gills, fibrous limbs, a peaceful empty face. | Walking grove | treant |
| Mob | **Spore Spider** — A spider with a bulbous glowing mushroom on its abdomen, fuzzy violet legs, many tiny glowing eyes, spore dust drifting from its body. | Leaves spores behind | arachne |
| Mob | **Capbear** — A big bear covered in shelf-fungus plates like armour, a mushroom-cap hood over its head, glowing magenta spots, strong claws. | Plated bruiser | owlbear |
| Mob | **Glowmoth** — A large moth with luminous lilac wings patterned like eyes, a fuzzy body, feathered antennae, glowing dust falling from its wings. | Healing dust | pegasus |
| Mob | **Puffcap Bomber** — A round waddling puffball mushroom creature with a big grin, swollen cap ready to burst, tiny legs, bright warning-orange spots, a lit fuse-like stem. | NEW · explodes on death | jackalope |
| Warden | **The Spore Queen** — A regal spider-queen with a huge glowing mushroom crown, a towering bloated abdomen full of spore sacs, elegant long legs, a veil of mycelium threads, magenta and cyan bioluminescence. | Hatches Spore Spiders; choking clouds | arachne |

## The Ossuary of Kings

*Palette:* bone ivory, candle gold and black. *Setting:* bone piles, stacked skulls, horned skulls, guttering candles, falling ash, crumbling royal tombs.

| | Creature | Role | Stand-in model |
|---|---|---|---|
| Mob | **Bone Gargoyle** — A gargoyle built from fused ribs and skulls, bone wings with no membrane, a horned skull face, glowing ember eyes. | Armoured striker | gargoyle |
| Mob | **Grave Hound** — A three-headed skeletal hound with a spiked collar, ghostly green flame in its ribcage, cracked yellowed bones. | Three-headed skeletal hound | cerberus |
| Mob | **Crypt Knight** — A horned skeletal knight in ancient royal plate armour with a tattered tabard, a great axe, a faded crown sigil on its shield. | Armoured guard | minotaur |
| Mob | **Wight** — A pale undead cat-like stalker, stretched grey skin over bone, two tails, long dagger claws, burning white pupils. | Quick killer | nekomata |
| Mob | **Ossuary Priest** — A hunched skeletal priest in black and gold funeral robes, a mitre made of finger bones, a censer of grave smoke, candles melted onto its shoulders. | NEW · necromancer caster | sphinx |
| Warden | **The Bone King** — A gigantic skeletal king on a pile of crowns, a great horned crown fused to his skull, a cloak of royal velvet rotted to rags, a sceptre topped with a screaming skull, ghostly gold fire in his eye sockets. | Raises Bone Gargoyles behind shields; enrages | minotaur |

## The Storm Spire

*Palette:* electric yellow, slate grey and storm violet. *Setting:* iron lightning pylons, floating rocks, a tower in the clouds, sparks and rain.

| | Creature | Role | Stand-in model |
|---|---|---|---|
| Mob | **Storm Harpy** — A harpy with slate-grey feathers crackling with yellow lightning, a copper face guard, wind-swept crest. | Fast striker | harpy |
| Mob | **Thunderhawk** — A griffin with storm-cloud grey plumage, golden lightning streaks along its wings, a beak of polished brass. | Burst striker | griffin |
| Mob | **Spark Kirin** — A slender kirin with a mane of crackling electric arcs, yellow-white scales, a single lightning-rod horn. | Chain caster | kirin |
| Mob | **Galvanic Golem** — An iron and copper construct with coils on its shoulders, a glass capacitor chest glowing with trapped lightning, riveted plates. | Answers spells with lightning | golem |
| Mob | **Tempest Elemental** — A living storm cloud shaped like a winged figure, swirling dark vapour, a bright lightning core, rain trailing from its lower body. | NEW · flying caster | phoenix |
| Warden | **The Tempest Roc** — A colossal storm bird with a wingspan full of thunderclouds, feathers like iron blades, lightning crackling between its talons, a crown of floating rocks orbiting its head. | Chain lightning stuns the squad | griffin |

## The Gilded Tomb

*Palette:* burnished gold, lapis blue and sandstone. *Setting:* sandstone obelisks with gold caps, painted sarcophagi, braziers, hieroglyph walls, drifting sand.

| | Creature | Role | Stand-in model |
|---|---|---|---|
| Mob | **Sand Manticore** — A manticore with a sand-coloured lion body, a scorpion tail of gold-plated segments, a lapis-blue mane braided with gold rings. | Critical striker | manticore |
| Mob | **Tomb Jackal** — A gilded jackal guardian with long ears, a golden collar and headdress, black fur and gold markings, glowing amber eyes. | Fast guardian | jackalope |
| Mob | **Mummified Lion** — A lion wrapped in ancient linen bandages, a golden funerary mask, a mane of dried papyrus, gaps showing dark dried flesh. | Tank | nemean |
| Mob | **Scarab Golem** — A golem shaped like a giant upright scarab beetle, emerald and gold shell plates, a sun disc on its brow, stone limbs. | Armoured | golem |
| Mob | **Gilded Asp** — A huge cobra with gold-and-lapis banded scales, a hood painted like a sun disc, ruby eyes, a jewelled crown on its head. | NEW · venom ranged | basilisk |
| Warden | **The Sun-Eater Pharaoh** — A towering undead pharaoh in golden armour and a tall double crown, a radiant sun disc held behind him like a halo, bandaged limbs, a crook and flail, burning gold eyes in a dark mummified face. | Sunfire slams; golden wards with Tomb Jackals | sphinx |

## The Void Rift

*Palette:* deep violet, black and starlight white. *Setting:* floating void shards, glowing rune halos, broken reality, a starfield bleeding through the walls.

| | Creature | Role | Stand-in model |
|---|---|---|---|
| Mob | **Shade Stalker** — A shadowy panther made of living darkness, its outline flickering, white star-like eyes, wisps of smoke instead of fur. | Ambush assassin | nekomata |
| Mob | **Void Weaver** — A spider of black chitin with constellations glowing on its abdomen, legs that fade into nothing, spinning violet threads. | Web caster | arachne |
| Mob | **Star Wraith** — A tall gaunt wraith made of night sky, stars visible through its body, antlers of black crystal, long reaching claws. | Fast and hungry | wendigo |
| Mob | **Mind Eater** — A tentacle-faced serpent with a huge glowing third eye, violet skin, a crown of floating runes. | Petrifying caster | basilisk |
| Mob | **Rift Horror** — A writhing mass of black tentacles and three eyeless heads with glowing mouths, violet runes carved into its hide, small void shards orbiting it. | NEW · multi-headed bruiser | hydra |
| Warden | **The Abyssal Keeper** — A colossal void guardian, a faceless armoured titan whose head is a hole into the starfield, rune halos orbiting its shoulders, a cloak of darkness, great hands of black crystal. | Shielded phases with Shade Stalkers; slams | sphinx |
