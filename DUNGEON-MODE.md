# Dungeon mode

A run type next to the guild run (World Tour). It's inspired by the map-crawl of *The Last Flame* and *Slay the Spire*, and by the relic and synergy builds of *Guildrun* and auto-chess games.

The opening is the same as the guild run: found a guild, sign a Legendary headliner, then draft a squad. After that you descend through three depths one room at a time. Wins earn components, items and relics; your squad builds run-trait synergies; and the run ends with a score on your local high-score table.

## How to start

On the main menu, choose **Dungeon** (between **New club** and **Exhibition**). Name the guild and forge its crest, then press **Enter the dungeon ▶**.

**Dungeon high scores** on the main menu (and **High scores** in the Dungeon tab) shows your best 15 banked runs.

## The descent

| Depth | Name | Warden |
| --- | --- | --- |
| 1 | The Rootbound Halls | The Rootmother |
| 2 | The Cinder Vaults | Magmaw, the Forge Tyrant |
| 3 | The Starless Deep | The Abyssal Keeper |
| 4+ | Endless depths (The Hollow Below, The Drowned Crypt, …) | The three Wardens return, stronger each cycle |

Each depth is a branching map of eight rows: seven rows of rooms, then a Warden. Every room is reachable. The **Dungeon** tab shows the map; glowing rooms are on your path.

| Room | What happens | Reward |
| --- | --- | --- |
| Skirmish | A pack of dungeon monsters | 1 of 3 components |
| Elite | An alpha monster pack, or a rival guild lost in the dark (+6% strength) | 1 of 3 relics |
| Outfitter | The guild-run shop: buy, forge, reroll | — |
| Campfire | **Rest** (restore 1 life) or **Train** (+120 XP for fielded champions) | — |
| Unknown | One of eight events with a choice | varies |
| Treasure | A chest | Gold + 1 of 3 finished items |
| Warden | Boss + two escorts | A finished item, a Warden relic and a medal chest |

Any reward can be skipped for 25 gold. When a fight earns several rewards, they queue up one after another.

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

Every run rolls **8 of 13 traits**: Wildheart, Bloodfang, Stormcaller, Ironhide, Swiftwing, Moonshadow, Sunforged, Venomkin, Everbloom, Ancient, Packhunter, Runebound and Gravebound.

- **Dealing:** every species is dealt **two** of the 8 for this run, spread evenly. The same Minotaur can be Bloodfang and Ironhide in one run and Stormcaller and Packhunter in the next.
- **Thresholds:** field **2** or **4** different champions that share a trait to unlock its tiers. Emblem relics add one.
- **Where they show:** trait chips appear on every draft-board card and on the headliner signing screen. The Dungeon tab shows your squad's active traits, and **Run traits** lists all eight with their tiers and which species carry them.
- **Scope:** run traits apply only to the player's squad, and only in dungeon mode. The guild run is unchanged.

## Monsters and Wardens

Skirmishes and alpha packs are made of dungeon monsters: 15 mobs, five per depth. Each has its own name, skin colour, size, stat profile, and sometimes an item behaviour. Some examples:

- **Gloomfang:** a fast violet wolf.
- **Thornback Troll:** its hide stuns attackers.
- **Ember Imp:** a small, fragile fire caster.
- **Ash Golem:** shields itself when cracked.
- **Shade Stalker:** dodges and crits.
- **Mind Eater:** a petrifying basilisk.

Wardens are oversized bosses with fight mechanics:

- **The Rootmother:** summons two Sporelings every 13 s and slowly regrows.
- **Magmaw, the Forge Tyrant:** a ground slam every 11 s stuns everyone nearby; enrages below 40% health.
- **The Abyssal Keeper:** at ⅔ and ⅓ health it shields itself and calls two Shade Stalkers; it also slams.

**Art note:** monsters reuse the existing 32 creature models, with a recolouring skin shader, size changes and a glowing rim on bosses. Truly new creature models and portraits would need new art assets. Their draft-style portraits still show the base creature.

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

## Balance (auto-player probe)

`tools/dungeon_balance_probe.gd` plays full runs with real fights. Its auto-player drafts normally, picks rooms at random, equips everything it gets and buys gear. It has no formation or tactics planning, so real players should do better.

Standard, 16 runs:

| Room | Depth 1 | Depth 2 | Depth 3 |
| --- | --- | --- | --- |
| Skirmish | 78% | 83% | 97% |
| Elite | 90% | 63% | 80% |
| Warden (per attempt) | 67% | 47% | 58% |

- **Full clears:** 7 of 16 runs cleared all three depths.
- **Endless (8 runs):** the runs that cleared depth 3 ended between endless depths 2 and 3, at scores around 15,000–22,000. Every run ends somewhere.

These are first-pass numbers, and Magmaw is the hardest Warden. Treat them as a starting point for playtesting.

## Files

- `godot/scripts/dungeon.gd`: map generation, rooms, events, lives, rewards, opponents, endless and scoring.
- `godot/scripts/dungeon_ui.gd`: the map screen, relic and trait panels, spoils and relic pickers, event/campfire dialogs, the endless choice, high scores and the guide.
- `godot/scripts/relics.gd`: the relic catalogue and the shared combat-modifier code (also used by traits and monsters).
- `godot/scripts/run_traits.gd`: the trait pool, per-run rolls, counting and synergy bonuses.
- `godot/scripts/bestiary.gd`: monsters, Wardens and their fight mechanics, and the monster skins.
- `godot/shaders/vfx/monster_skin.gdshader`: the monster recolour and rim-glow pass.
- `godot/tools/dungeon_smoke.gd`: a headless routing test (map shape, traits, relics in battle, all room types, endless, scores, save migration, running out of lives).
- `godot/tools/dungeon_balance_probe.gd`: the auto-player balance probe (`PROBE_RUNS`, `PROBE_DIFFICULTY`, `PROBE_ENDLESS=1`). It restores your high-score file when it finishes.

```
godot --headless --path godot -s tools/dungeon_smoke.gd
PROBE_RUNS=16 godot --headless --path godot -s tools/dungeon_balance_probe.gd
```

QA captures:

- `--qa=dungeon_menu`, `dungeon_trail`, `dungeon_fight`, `dungeon_loot`, `dungeon_event`, `dungeon_intro`, `dungeon_result`
- `dungeon_market`, `dungeon_endless`, `dungeon_scores`, `dungeon_boss`

Saves from the first dungeon build (which used "flames") load as lives automatically.
