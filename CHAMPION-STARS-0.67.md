# Manitoria 0.67 — Champion Stars

Buy champion copies from the Market while founding your squad (after fielding four starters) or between cups after keeping the team. Each owned champion has an explicit copy offer, including Legendary headliners. Choose the exact champion to upgrade; existing duplicate heroes remain separate. Copies do not take roster or formation slots. Owned species are represented by copy offers rather than appearing again in the recruit table.

The original counts as one copy. Three total copies grant two stars; nine total copies grant three stars. Two stars give +18% health and +12% attack damage / ability power. Three stars give +38% health and +25% attack damage / ability power. The latter replaces the former. Armor, attack range, attack speed and cooldowns keep their existing item and skill tradeoffs. Damage, healing and defensive skill channels receive the star damage multiplier once, without double-counting star health.

A copy costs the species' current run tier price: Common 150g, Epic 300g, Legendary 450g. Existing names, stat rolls, skills, XP, equipment, formation positions and level-eight evolutions stay intact. Progress saves with the champion. The three-star cap and insufficient gold reject purchases. Failed saves restore the purchase state. Selling returns half of the original paid price plus paid copy costs. Star progress is shown in the Market, roster and featured shop panel; upgraded combatants have a star badge. Purchasing uses the upgrade sound and promotion toast.

Copy purchasing and recruiting remain locked during a cup. These star upgrades are separate from skill ranks and species evolutions. Existing saves default to one star; no original save was edited or revived. Rival clubs retain their fixed growth policy and do not receive new automatic stars.

## Later-cup balance

Champion rival level floors now follow [1, 6, 9, 10, 12], with the existing one-level stagger on 40% of identities. Keeper and Standard are unchanged. Match XP, camp training, equipment budgets, skill rarity progression and quality bonuses retain 0.66 rules. Existing stronger rivals are never downleveled.

The saved Soggy roster's controlled Champion replay sample now yields:

| Cup | Wins | Rate |
| --- | --- | --- |
| 3 | 22 / 28 | 79% |
| 4 | 20 / 28 | 71% |
| 5 | 19 / 28 | 68% |

Each cup uses two fixed seeds mirrored across both sides against the seven saved rival clubs. Later player teams receive four-win match XP plus camp per prior cup and spend level rewards on their existing build. Items remain as saved, and no copies are purchased. These are controlled cup-opening comparisons, not promised odds for an actual bracket. Fresh choices, purchases, accumulated rival XP and matchups change actual outcomes. The original fallen run is untouched. Detailed samples are in CHAMPION-STARS-0.67-results.json.

## Validation

The exported Windows pack passes 114 star purchase/save/combat checks, 13,626 tour balance checks, 464 skill/item/recruitment checks and the existing item-feedback suite. Four real UI checks exercise copy buttons, promotion and the roster display; Market and roster screenshots were inspected. Export completes successfully. Source changes are local and unpushed.
