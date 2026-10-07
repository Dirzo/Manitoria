# Manitoria 0.69 — Playtesting, shop clarity and rival economy

This update keeps the three-copy / six-copy upgrade rules and improves the shop, rival spending and combat balance after simulated matches, purchase stress tests and a complete five-cup save-flow test.

## Shop and upgrades

The shop retains its shared 3D stage when rotating champions, buying copies or changing equipment. Rapid selection changes interrupt the previous animation and continue from the models' current positions. The selected champion remains prominent; background champions recede and only the selected plinth is highlighted. Roster changes create a fresh stage.

Stars now include explicit `1-star`, `2-star` or `3-star` text, copy progress and `MAX`. Carousel captions also show stars. Evolution has its own named label: the species evolution is distinct from a copy upgrade. The wardrobe's evolution goals display readable names instead of internal identifiers. At the six-copy cap the offer says that the champion is fully upgraded rather than previewing an unavailable purchase. The stat hex retains its animated before/after outline and gain labels; its comparison ranges refresh when the run's species tiers change.

The equipment, bag notification and previous-round graphs remain in the shop. Counter-build advice identifies Grievous Thorns against healing and Shieldbreaker Tusk against armor/shields. Teams with multiple Supports see their current healing multiplier in the shop.

## Funded rival progression

Rivals now have saved development wallets and ledgers. Their initial wallet is the founding fund minus their roster's draft prices, floored at zero. Match victories and defeats pay the same difficulty/cup rewards as the player, and cup placements pay prizes once. Rivals spend those funds on equipment and champion copies; opening their roster does not grant free upgrades. Equipment is distributed across the fielded team before copy purchases, and duplicate equipment is avoided. Upgrading an ingredient into its recipe credits its full value; other replacements credit half the old item's value.

Copies use the run's species prices and the same keep-the-higher-roll merge as the player. Partial progress is retained; three total copies grant two stars and six grant three stars. Two stars give +18% HP and +12% AD/AP; three stars replace those bonuses with +50% HP and +35% AD/AP. Rivals can only reach their development targets when they can afford them. Their existing difficulty-based training, level, skill-quality and evolution progression still applies; the economic flow is shared, rather than every AI decision or XP rule being identical to the player's.

Two-star-or-better target shares by cup:

| Difficulty | Cup 1 | Cup 2 | Cup 3 | Cup 4 | Cup 5 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Keeper | 0% | 0% | 5% | 20% | 40% |
| Standard | 0% | 5% | 25% | 55% | 80% |
| Champion | 0% | 10% | 40% | 75% | 95% |

Within those targets, three-star shares are Keeper 0/0/0/0/5%, Standard 0/0/0/5/15% and Champion 0/0/5/15/30%. These are deterministic identity-based purchase goals, not guaranteed roster outcomes or adjustments to player strength. Older saves keep previously granted gear and stars without retroactive debt.

## Gold and combat balance

The increased 0.68 match income remains in place:

| Difficulty | Cup-one win / loss | Cup-five win / loss |
| --- | --- | --- |
| Keeper | 200 / 165 | 240 / 205 |
| Standard | 180 / 145 | 220 / 185 |
| Champion | 170 / 135 | 210 / 175 |

Every cup adds 10g to each match reward. Placement prizes and item effects are additional. Copies cost 150/300/450g by the run's tier; six-copy investment therefore competes with equipment purchases. No additional blanket gold increase was needed in this pass.

- Champions whose audited signature build path is AD gain 12% base attack power. This improves their basic attacks and AD-scaling skills while retaining separate AP build channels.
- Grievous Thorns reduces affected healing by 50%, up from 35%.
- Chalice of Renewal strengthens outgoing healing by 25%, down from 40%; its AP bonus remains.
- A single living Support heals at full strength. Two living Supports on the same team heal at 70%; three or more at 40%. If a Support falls, surviving Supports regain the corresponding multiplier. Non-Support regeneration and lifesteal keep their normal rules.
- Overtime sustain reduction begins at 60 seconds, decreases healing/shields by two percentage points per second, and bottoms out at 5%. This targets long sustain stalemates without adding an overtime damage multiplier.

## Validation and limits

The exported pack passed these automated checks:

| Test | Checks | Failures |
| --- | ---: | ---: |
| Champion copies, stars and save behavior | 109 | 0 |
| Rival funded development, three seeds/all difficulties | 9,181 | 0 |
| Shop economy and difficulty/star targets | 22,564 | 0 |
| Tour progression | 13,626 | 0 |
| Skill/item/recruitment rules | 464 | 0 |
| Item visual/audio feedback | 1,228 | 0 |
| Healing, Support stacking and overtime | 9 | 0 |
| Shop/carousel interactions | 32 | 0 |
| Rapid rotation and repeated copy purchases | 221 | 0 |
| Star purchase UI and stat-hex feedback | 9 | 0 |
| Five-cup save flow | 293 | 0 |

The source cup-training/save test also passed 26 checks. The five-cup test advances twenty matches, buys a six-copy champion with earned funds, handles upgrade choices and intermissions, and verifies player/rival wallets. It deliberately strengthens the player to exercise every transition; it is a flow test, not a balance win-rate measurement. UI stress includes thirty rapid selections, retained model identities, mid-animation continuity, selection/item-recipient agreement, named evolution labels and equipment slots. Screenshots were inspected.

Exploratory mirrored matchups compared attack tempo, spell control, sustain support and a tank carry using actual offered skill choices and budgeted purchases. After correcting Support skill selection/tactics in the attack fixture, its eighteen-match sample split the spell matchup on all three difficulties and beat or split the tank matchup. This sample preceded the final Chalice reduction. A final twelve-match anti-sustain sample with the shipping combat values had no timeouts, but sustain won eleven matches. Support-heavy compositions remain strong in this fixed cohort; these small samples are not population win rates or proof of equal power for every composition. A six-copy tank also has a substantial equipment opportunity cost. The audit tool is included for further matchup testing.

Tests use isolated application-data directories and do not edit or revive the user's original runs. The Windows environment reports a certificate-store diagnostic; gameplay checks still pass. Deep test-directory paths caused shader-cache creation diagnostics; repeating rapid rotation with a shorter isolated application-data path passed without those diagnostics. No frame-rate benchmark or exhaustive device compatibility test is claimed. Source changes remain local and unpushed.
