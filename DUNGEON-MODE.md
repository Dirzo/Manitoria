# Dungeon mode

A run type next to the guild run (World Tour). It's inspired by the map-crawl of *The Last Flame* and *Slay the Spire*, and by the relic and synergy builds of *Guildrun* and auto-chess games.

The opening is the same as the guild run: found a guild, sign a Legendary headliner, then draft a squad. After that you descend through three depths one room at a time. Wins earn components, items and relics; your squad builds run-trait synergies; and the run ends with a score on your local high-score table.

## How to start

On the main menu, choose **Dungeon** (between **New club** and **Exhibition**). Name the guild and forge its crest, then press **Enter the dungeon ▶**.

**Dungeon high scores** on the main menu (and **High scores** in the Dungeon tab) shows your best 15 banked runs.

## The descent: ten instances

Each run is three depths, then optional endless depths. At the top of every staircase you choose between **two instances** you haven't visited this cycle. Each instance has its own monsters, Warden, arena, palette and map art.

| Instance | Arena | Monsters | Warden |
| --- | --- | --- | --- |
| The Blight Forest | Dead trees, toxic pools, thorns, drifting spores | Gloomfang, Thornback Troll, Sporeling, Rotwing | **The Rootmother**: summons Sporelings, regrows |
| The Mana Caverns | Glowing crystal clusters and giant crystal spires | Mana Wisp, Crystal Golem, Glimmerfox, Shardscale | **The Prismatic Archon**: mana surge silences the whole squad; shield and Mana Wisps at half health |
| The Magma Depths | Lava pools, molten-veined basalt, lavafalls, embers | Ember Imp, Magma Hound, Slagbrute, Ash Golem | **Magmaw, the Forge Tyrant**: stunning slams, enrage |
| The Frostbound Crypt | Ice shards, snow drifts, frozen pillars, snowfall | Rimefang, Frost Wraith, Glacier Yeti, Rime Harpy | **The Frost Matriarch**: blizzard damages and slows everyone; enrage |
| The Drowned Sanctum | Flooded floor, broken marble columns, coral | Tide Naga, Brine Serpent, Shellback, Siren | **The Drowned Leviathan**: tidal slams, Sirens, regeneration |
| The Fungal Hollows | Giant glowing mushrooms in three colours | Mycelid, Spore Spider, Capbear, Glowmoth | **The Spore Queen**: hatches Spore Spiders; choking spore clouds |
| The Ossuary of Kings | Bone piles, horned skulls, candles, falling ash | Bone Gargoyle, Grave Hound, Crypt Knight, Wight | **The Bone King**: raises Bone Gargoyles behind shields; enrages near death |
| The Storm Spire | Iron lightning pylons, floating rocks, sparks | Storm Harpy, Thunderhawk, Spark Kirin, Galvanic Golem | **The Tempest Roc**: chain lightning stuns the whole squad |
| The Gilded Tomb | Sandstone obelisks with gold caps, sarcophagi, braziers | Sand Manticore, Tomb Jackal, Mummified Lion, Scarab Golem | **The Sun-Eater Pharaoh**: sunfire slams; golden wards with Tomb Jackals |
| The Void Rift | Floating void shards, glowing rune halos | Shade Stalker, Void Weaver, Star Wraith, Mind Eater | **The Abyssal Keeper**: shielded phases with Shade Stalkers; slams |

Each depth is a branching map of eight rows: seven rows of rooms, then the Warden. Every room is reachable. Wardens scale with the depth they guard, not with the instance, so any instance is fair at any depth. Each Warden also has a mechanics weight so that, for example, Magmaw's slams and enrage don't make him harder than the Rootmother's summons.

### Arenas

In a dungeon fight the whole colosseum is replaced by a cave chamber for that instance:

- **Ground:** a rock-shader floor in the instance's colours, with glowing seams in the Magma Depths, Void Rift, Mana Caverns and Storm Spire.
- **Hex grid:** only a faint overlay. Hexes are also softer in the colosseum now (lower contrast, thinner gaps).
- **Walls:** cave rock and stalactites close the chamber in.
- **Set pieces:** the instance's own (crystals, lava pools, dead trees, ice, flooded columns, mushrooms, bones, pylons, obelisks, void shards).
- **Atmosphere:** flickering coloured lamps, light shafts falling from the ceiling, two layers of drifting ground mist, two layers of floating particles, thicker fog, and a screen-edge vignette in the instance's colour.

Props stay outside the fighting field and are kept low on the camera side. Leaving the dungeon restores the colosseum exactly.

### The Dungeon screen

The Dungeon tab is one game-style screen in the dungeon's own look: bronze-trimmed plates, title-font headings and gold buttons. The management tabs and dock button switch to the same look during a dungeon run.

- **Top band:**
  - the instance seal and name;
  - depth pips coloured by the instances already conquered;
  - the relic belt;
  - Traits, Scores and Guide.
- **Map:**
  - painted with the instance's art under a vignette;
  - medallion rooms with bronze rims; open rooms pulse;
  - the walked path in gold, and animated paths to the rooms you can reach;
  - unexplored rows fading into darkness;
  - your headliner's portrait bobbing where the guild stands;
  - the **Synergies** column on the left, and a **Warden card** (portrait, name, mechanics) on the right.
- **Squad strip:**
  - each fielded champion with portrait, level and trait chips;
  - a **Next** card: the fight with Scout, Formation and Fight, or a pointer to the map.
- **Overlays and dialogs:**
  - *Choose your path:* instance cards with art, Warden portrait and monster portraits;
  - *Bank or go endless*, and *run complete / out of lives*;
  - framed dialogs for rewards (cards that rise in one by one), events, traits, high scores and the guide.

## Lives

Keeper starts with 4 lives, Standard with 3 and Champion with 2.

- **Losing a normal fight** costs a life, and the guild still pushes past the room.
- **Losing to a Warden** costs a life, and you must fight it again.
- **Restoring lives:** campfires, the Healing Spring event and every defeated Warden restore one life, up to your maximum.
- **Out of lives:** the run ends and its score is banked. Events never let you spend your last life.

## Relics

Relics are passive bonuses that last the whole run, applied at the start of every fight. There are 26 in total:

- **12 Common:** for example, +10% health; front line +5 armor; back line +14% damage; an opening 12% shield; +40 gold per win; +30% XP.
- **9 Rare:** for example, 8% lifesteal; signatures ready twice as fast; headliner +22% health and damage; Bastion Shell for the front line; +1 max life; a **Trait Emblem** that counts as one extra champion for a run trait.
- **6 Warden relics** with trade-offs:
  - **Ember Heart:** your headliner revives once per fight.
  - **Warlord's Horn:** +14% damage and attack speed, but campfires can't restore lives.
  - **Golden Idol:** +90 gold per win, but −1 max life.
  - **Titan Core**, **Abyssal Eye** and **Everflame Brazier** round out the set.

Effects reuse the game's existing combat hooks (item behaviours, crit, dodge, lifesteal, tenacity, shields, regeneration), so they show up in battle exactly like item effects. The Dungeon tab lists your relics with tooltips.

## Run traits (auto-chess synergies)

Every creature has real tags on three axes, so its synergies make sense:

| Axis | Traits |
| --- | --- |
| **Kin**: what it is | Avian, Ursine, Canine, Feline, Scaled, Draconic, Hoofed, Stoneborn, Giant, Sylvan, Venomous, Spirit |
| **Element**: what it wields | Fire, Frost, Storm, Tide, Earth, Radiant, Shadow |
| **Class**: how it fights (from its role) | Bruiser, Guardian, Hunter, Marksman, Mystic, Mender |

Some examples:

- **Owlbear:** Avian, Ursine, Bruiser. It synergises with birds, bears and other bruisers.
- **Phoenix:** Avian, Spirit, Fire, Mystic.
- **Zaratan:** Scaled, Stoneborn, Tide, Earth, Guardian.

**Fresh every run:**

- **Awakening:** 14 of the 25 traits awaken. Every species keeps two or three of its own awakened traits; species with only two tags always keep both.
- **Flavour:** each awakened trait rolls one of two flavours. Avian is *Skyborne* (dodge and speed) one run and *Raptors* (crits) the next. Ursine is *Thick Hide* or *Mauling*; Feline is *Pounce* or *Nine Lives*, which revives at 3.
- **Thresholds:** small families (four members or fewer) light up at 2 and 3; larger ones at 2 and 4. Each species counts once, and Trait Emblem relics add one.
- **Scope:** run traits apply to your squad in dungeon mode only.

**Where you see them:**

- trait chips on every draft card and on the headliner signing screen;
- the **Synergies** column on the map, auto-chess hexagon badges with counts;
- each champion's chips in the squad strip (lit when active);
- **Traits**, which lists every awakened trait with its flavour, both tiers and which species carry it.

## Monsters and Wardens (details)

There are 40 dungeon monsters, four per instance, and 10 Wardens. Each monster has its own name, skin colour, size and stat profile; some also borrow an item behaviour, like the Thornback Troll's stunning thorns, the Ash Golem's crack-shield or the Galvanic Golem's lightning rod. Skirmishes and alpha packs draw from the current instance's four monsters, and Wardens bring two of them as escorts.

Warden mechanics are built from six parts:

- **Summons:** adds on a timer.
- **Slam:** stuns everyone close by.
- **Enrage:** at low health.
- **Phases:** a shield plus adds at health thresholds.
- **Pulse:** damage and a status (slow, silence or stun) on the whole squad.
- **Regeneration.**

**Art note:** monsters reuse the existing 32 creature models, with a recolouring skin shader, size changes and a glowing rim on Wardens. Truly new creature models and portraits would need new art assets (for example from Meshy, imported as `.glb` like the existing creatures). Their draft-style portraits still show the base creature.

Monster stats ignore the run's random draft tiers, so a Warden is equally strong whichever tier its model rolled.

## Score

- **Points:** room entered +10, skirmish win +100, elite +250, Warden +800, relic +25. Each is multiplied by the depth number, so depth 2 is worth double and endless depth 4 is worth ×7.
- **When it's banked:** when you run out of lives, bank after the third Warden, or retire from the endless depths.
- **Final score:** points, plus 150 per remaining life (not if you fell), times a difficulty multiplier (Keeper ×0.8, Standard ×1, Champion ×1.35) and +10% per Ascension rank.
- **The table:** banked scores go to `user://dungeon_scores.json`, top 20, shown 15 at a time.

## Endless

After the third Warden you choose between two options:

- **Bank score:** the run ends as *Conquered*.
- **Into the endless depths:** the run continues through new depths. Enemy strength compounds by +20% per endless depth, and Wardens return with +35% health and damage per depth number. Each depth still opens with a recruit board, one restored life and training. Use **Retire** in the Dungeon tab at any time to bank the score; otherwise the run ends when your lives run out.

## Balance

Two probes, both headless:

- **`tools/dungeon_balance_probe.gd`** plays full runs with real fights. Its auto-player drafts normally, picks instances and rooms at random, equips everything it gets and buys gear. It has no formation or tactics planning, so real players should do better.
- **`tools/warden_probe.gd`** fights every Warden against the same reference squads at each depth and finds the stat weight that hits a target win rate. Each Warden has one weight per depth. Summoners need more at depth 2–3, where their adds fall behind your squad. The weights are scaled against the Wardens tuned in real runs (the Rootmother at depth 1, Magmaw at depth 2, the Keeper at depth 3).

Standard, 24 full runs, with random instances:

| Room | Depth 1 | Depth 2 | Depth 3 |
| --- | --- | --- | --- |
| Skirmish | 76% | 89% | 78% |
| Elite | 93% | 83% | 89% |
| Warden (per attempt) | 74% | 47% | 74% |

- **Full clears:** 14 of 24 runs cleared all three depths.
- **Endless:** earlier probes had runs end between endless depths 2 and 3 (enemy strength compounds +20% per endless depth).

Each Warden appears only a handful of times in 24 runs, so per-Warden numbers are noisy. Magmaw has consistently been the hardest and the Frost Matriarch the easiest, and both have since been nudged toward the middle. Treat all of this as a starting point for playtesting.

## Files

- `godot/scripts/dungeon.gd`: map generation, rooms, events, lives, rewards, opponents, endless and scoring.
- `godot/scripts/dungeon_ui.gd`: the map screen, relic and trait panels, spoils and relic pickers, event/campfire dialogs, the endless choice, high scores and the guide.
- `godot/scripts/relics.gd`: the relic catalogue and the shared combat-modifier code (also used by traits and monsters).
- `godot/scripts/run_traits.gd`: the trait pool, per-run rolls, counting and synergy bonuses.
- `godot/scripts/dungeon_instances.gd`: the ten instances (palette, arena kit, art, monsters, Warden) and the two-choice offers.
- `godot/scripts/dungeon_arena.gd`: turns the colosseum into each instance's cave chamber, and restores it afterwards.
- `godot/scripts/bestiary.gd`: monsters, Wardens and their fight mechanics, Warden strength by depth, and the monster skins.
- `godot/shaders/vfx/monster_skin.gdshader`: the monster recolour and rim-glow pass.
- `godot/tools/dungeon_smoke.gd`: a headless routing test (map shape, traits, relics in battle, all room types, endless, scores, save migration, running out of lives).
- `godot/tools/warden_probe.gd`: Warden calibration; sweeps each Warden's weight against the same reference squads (`PROBE_DEPTH`, `PROBE_SQUADS`, `PROBE_TARGET`, `PROBE_BOSS`).
- `godot/tools/dungeon_balance_probe.gd`: the auto-player balance probe (`PROBE_RUNS`, `PROBE_DIFFICULTY`, `PROBE_ENDLESS=1`). It restores your high-score file when it finishes.

```
godot --headless --path godot -s tools/dungeon_smoke.gd
PROBE_RUNS=16 godot --headless --path godot -s tools/dungeon_balance_probe.gd
```

QA captures:

- `--qa=dungeon_menu`, `dungeon_trail`, `dungeon_fight`, `dungeon_loot`, `dungeon_event`, `dungeon_intro`, `dungeon_result`
- `dungeon_market`, `dungeon_endless`, `dungeon_scores`, `dungeon_boss`, `dungeon_paths`, `dungeon_stage`
- Add `QA_INSTANCE=<id>` to pick the instance, for example `QA_INSTANCE=storm_spire … --qa=dungeon_stage`.

Saves from the first dungeon build (which used "flames") load as lives automatically.
