# Manitoria 0.62 — first skill and item balance pass

Recruitment is available for the founding draft and between cups. Starting a cup locks new signings and releases; existing reserves, formations, tactics, skills and equipment remain available. After cup results, Keep team returns to the fresh recruit board. Starting the next cup locks recruitment again. Existing in-cup saves are covered too.

## Stat trade-offs

Attack damage strengthens basic attacks and physical skill portions. Ability power is a separate stat: attack-damage items do not strengthen pure spells. Armor and health strengthen selected defensive skills as well as survivability. Attack speed improves basic attacks and selected rapid skills, with a capped contribution to skill damage. Ability haste shortens cooldowns independently, with a 40% cap on the combined stat-based reduction. Ranks and rarity multiply the skill's resulting power, rather than changing which stat it uses.

| Skill family | First-pass scaling |
| --- | --- |
| Ambush, execute, maul, dives | Mostly attack damage, with a small AP portion |
| Boulder / Cyclops meteor | 80% attack damage, 20% AP |
| Thunderbird lightning, fire, poison clouds, spirit bolts | Ability power |
| Quake / fissure | 35% attack damage, 65% armor power |
| Shields / taunts | 25% AP, 35% armor power, 40% health power |
| Healing | Mostly AP, with a health contribution |
| Barrage / whirlwind / triple bite | Physical or hybrid damage plus an attack-speed contribution |
| Summons | Direwolf mixes attack damage and AP; Arachne and Kitsune favor AP |

Armor power uses the champion's base skill budget, increasing with armor above its natural base. Health power uses maximum health relative to natural health. This keeps a point of armor or health from being numerically compared directly with a point of attack damage. The in-game ability panel and tooltips display each skill's stat mixture. Fit and growth priorities now follow each species' signature and combat niche. AP appears as a separate shop stat.

## Item changes

- Sharpened Fang: 12% attack damage, down from 15%. Ember Shard: 12% AP, down from 14%. Moonstone: 8% shorter cooldowns, down from 12%.
- Archmage Orb: 20% extra AP plus both components (44% total), down from 32% extra.
- Blue Crown: 12% extra cooldown reduction plus its Moonstone. Hourglass: 10% extra plus both Moonstones. Stat-based reduction is capped at 40%, including traits and evolutions.
- Titan: 1.5% attack damage per stack, 16 stacks, down from 2% and 25. Frenzy: 3% attack speed per stack, 8 stacks, down from 4% and 10.
- Sugar Rush: 40% bonus attack speed, down from 60%, keeping its health drain.
- Quicksilver: 0.25s cooldown refund per basic attack, down from 0.4s. Overcharge: 0.65s per critical proc with a 1s internal cooldown, down from unrestricted 1.5s refunds.
- Mirror: reflects 25% of skill damage, down from 40%. Runeward: 12s protection cooldown, up from 8s.
- Bloodfeast: kills restore 30% maximum health instead of fully healing; allied heals are now 25% weaker instead of 50%.
- Arcane Quiver, Stormhide Mantle, Judgement Bolt and Chaos Die blasts use AP. Their descriptions and displayed item stats match their effects.

Recommendations score the actual signature, learned skills, evolution modifiers, basic-attack role, item stats and relevant passives. Healing items receive their extra preference only on kits that heal. Unpredictable WILD items remain optional choices rather than automatic suggestions. Shop component highlights use the same current build as the recommended-item row.

## Hex combat and long fights

Skill reach and area effects now measure hex distance, allowing short-range skills to reach adjacent hexes. Pools cover a one-hex radius. At 70 seconds, overtime gradually reduces healing and newly generated shields, reaching a 75% reduction at 120 seconds. The combat clock shows OVERTIME and its tooltip reports the current reduction.

## Verification

768 checks pass: 464 skill/item/recruitment, 239 mechanics/artwork, 33 navigation and 32 rendered UI checks. They cover all 384 ordinary learned-skill descriptions, all 32 champion recommendation lists, real casts with different stat items, founding/in-cup/between-cup recruitment, save compatibility guards, inventory swaps, UI fit, hex movement and delayed projectiles.

Twelve mirrored full-team build comparisons across six archetypes completed without timeouts after the reach/overtime fixes. Suggested builds won nine and the alternative builds won three. This is a small diagnostic sample, not a claim of competitive balance across every champion, evolution, item combination or matchup.

## Example suggested builds

These examples use level-5 champions with their first two learned skills. Suggestions update when the kit changes.

| Champion | Signature scaling | Suggested items |
| --- | --- | --- |
| Minotaur | 70% attack damage + 30% armor power | Stoneskin, Bloodmaw, Mirror Carapace |
| Stone Golem | 25% ability power + 35% armor power + 40% health power | Mirror Carapace, Bastion Shell, Taunting Bell |
| Cave Troll | 55% attack damage + 45% health power | Colossus Heart, Stoneskin, World Tree Seed |
| Wendigo | 75% attack damage + 25% health power | Bloodmaw, Frenzy Horn, Executioner's Edge |
| Direwolf | 55% attack damage + 45% ability power | Executioner's Edge, Frenzy Horn, Bloodmaw |
| Manticore | 55% attack damage + 45% ability power | Bloodmaw, Executioner's Edge, Frenzy Horn |
| Griffin | 85% attack damage + 15% ability power | Executioner's Edge, Crusader's Edge, Shadowblade |
| Kitsune | 100% ability power | Archmage Orb, Blue Crown, Witherbloom |
| Wyvern | 100% ability power | Archmage Orb, Blue Crown, Plague Tome |
| Harpy | 100% ability power | Archmage Orb, Frenzy Horn, Tempest Talons |
| Phoenix | 100% ability power | Archmage Orb, Blue Crown, Chalice of Renewal |
| Storm Kirin | 100% ability power | Archmage Orb, Blue Crown, Stormcaller Orb |
| Basilisk | 100% ability power | Archmage Orb, Blue Crown, Witherbloom |
| Elder Treant | 80% ability power + 20% health power | Chalice of Renewal, Verdant Scepter, Archmage Orb |
| Naga | 65% ability power + 35% health power | Chalice of Renewal, Archmage Orb, Saint's Rosary |
| Unicorn | 80% ability power + 20% health power | Halo of Dawn, Archmage Orb, Saint's Rosary |
| Cerberus | 85% attack damage + 15% ability power | Bloodmaw, Frenzy Horn, Spellblade |
| Nemean Lion | 25% ability power + 35% armor power + 40% health power | Colossus Heart, Sanctified Aegis, Ironbark |
| Yeti | 25% ability power + 35% armor power + 40% health power | Stoneskin, Ironbark, Mirror Carapace |
| Zaratan | 25% ability power + 35% armor power + 40% health power | Colossus Heart, Taunting Bell, Mirror Carapace |
| Owlbear | 85% attack damage + 15% ability power | Crusader's Edge, Thornroot Lash, Bloodmaw |
| Hydra | 20% ability power + 80% health power | Colossus Heart, Stoneskin, World Tree Seed |
| Chimera | 55% attack damage + 45% ability power | Spellblade, Crusader's Edge, Archmage Orb |
| Gargoyle | 30% attack damage + 70% armor power | Mirror Carapace, Bloodmaw, Runeward |
| Nekomata | 85% attack damage + 15% ability power | Bloodmaw, Shadowblade, Executioner's Edge |
| Jackalope | 80% attack damage + 20% ability power | Executioner's Edge, Frenzy Horn, Bloodmaw |
| Cyclops | 80% attack damage + 20% ability power | Executioner's Edge, Shieldbreaker Tusk, Bloodmaw |
| Thunderbird | 100% ability power | Archmage Orb, Blue Crown, Stormcaller Orb |
| Sphinx | 100% ability power | Archmage Orb, Blue Crown, Witherbloom |
| Pegasus | 75% ability power + 25% health power | Archmage Orb, Blue Crown, Saint's Rosary |
| Arachne | 100% ability power | Archmage Orb, Blue Crown, Plague Tome |
| Salamander | 100% ability power | Archmage Orb, Plague Tome, Blue Crown |
