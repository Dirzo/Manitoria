# Spacing update — edition 0.7

Keeper, Standard and Champion stat multipliers are unchanged. Deployment rows now have 3.1-unit gaps, columns are -10/-7.4/-5 (mirrored for rivals), and ordinary hero body radius rises from 0.58 to 0.72. Allied movement bends away from nearby teammates; natural independent targeting slightly discourages piling onto an already-engaged foe. Ranged heroes maintain a larger natural retreat distance. Explicit focus-fire/committed tactics remain effective.

The floor/render mapping expands X/Z by 1.45 with unchanged character model scale. Camera, projectiles, spell zones and 3D picking account for this mapping.

After these changes: reference team practice wins 27/30, 21/30, 29/30; equal-stat mirror left wins 14/40. These are seeded samples, not full species/composition balance coverage. No full-season remeasurement is claimed for 0.7. Earlier 0.6 results below are historical.

# Native balance — edition 0.6

## Health display and deaths

The prior health bar relied on horizontal scaling of a billboarded mesh. The new implementation changes a unique mesh's width, preserves billboard scale, and displays actual HP numerically. Tests apply real damage and verify width reduction, health text, lethal damage, death presentation and kill credit. The simulator does not grant immunity to player heroes. Heroes who fall recover between matches.

## Difficulty tuning

- Keeper: rival health and attack start at 90%, rise 0.4 percentage points per fixture, and cap at 96%. Previously they started at 80% with a 1.2-point rise.
- Standard: equal base health and attack (100%). Champion: 108%.
- Multipliers are visible in scouting/settings. They are not adjusted to recent player results.
- Five starters, existing recruitment prices and level-up-only ability choices remain. No existing roster or save is reset.
- Wind-ups are now 0.32s melee / 0.40s ranged / 0.56s signature / 0.62s learned ability, with a 0.22s visual recovery. Ranged travel is 0.18–0.90s; meteor 0.75s. These readable timings are included in the samples below.

## Measured samples

The level-one reference team is Golem / Minotaur / Direwolf / Kirin / Unicorn in the default formation, using natural orders. Each practice fixture is reset to level one, so these tests do not assume gained upgrades.

Final Keeper settings, 30 seeds per fixture:

| Practice | Wins | Losses | Draws |
|---|---:|---:|---:|
| 1 | 25 | 5 | 0 |
| 2 | 22 | 8 | 0 |
| 3 | 30 | 0 | 0 |

Equal-stat mirror teams split 20 wins / 20 losses across 40 seeded matches.

A separate 360-bout sweep tested all three practice fixtures at 80%, 90%, 96%, 100% and 108%, with 24 seeds each. At the old 80% opening setting, the reference team won all 24 opening bouts. At the new 90% setting it won 20/24; 22/24 bouts included at least one friendly hero falling, with 52 friendly deaths in total. These are deaths during the bout, not permanent losses from the roster.

Full season smoke tests recruit the reference five, always select the first upgrade card, use natural orders, and save/reload after each fight:

| Difficulty | Wins | Losses | League rank | Ending levels |
|---|---:|---:|---:|---|
| Keeper | 7 | 10 | 5/8 | Five level-7 heroes |
| Standard | 3 | 14 | 7/8 | Five level-7 heroes |

Both tests continued into season two successfully. Player tactics, different rosters and deliberate card choices are not represented by this fixed baseline policy. Standard remains demanding; the third practice matchup is still favorable for this lineup. These results demonstrate that losses and hero deaths occur, not a claim of equal win rates for every species or strategy. More player testing is needed for all compositions and late-season builds.

## Validation

113 gameplay/interface checks passed: core combat/progression (27), tactics/combat presentation (29), UI flow (18), and management (39). New coverage includes targeting, target commitment and taunt overrides, teamwork, holding/flanking/kiting, cluster patience, healing priority, saved per-hero orders, projectile delay, interruptions, HP geometry, numeric health, pause, death presentation, hero portraits and actual tactics UI selections.
