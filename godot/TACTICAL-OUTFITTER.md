# Manitoria 0.17 — Tactical Outfitter

The between-match shop now builds roles rather than just increasing stats. Existing saves and all twelve equipment IDs remain compatible. Their effects and prices use the new definitions; no campaign reset is needed.

## Shopping loop

After each tournament match and any earned hero choices, inspect six offers and a scout summary of the next opponent. Select a hero, buy directly into their equipment slot, or buy into the shared bag. Hover an offer for its tradeoff and replacement comparison. Replaced equipment returns to the bag; equipping and unequipping cost nothing.

Each offer supplies one copy. Refresh costs 25 gold, then 40, 55, and so on during that stop; the price resets after the next match. A refresh can contain previously seen equipment. When every unlocked item is already on sale, refreshing is disabled until a purchase makes restocking useful. Spare equipment sells for half its purchase price; equipped gear must first return to the bag. Sales are final. Saving gold and leaving without purchasing are always valid choices.

Gold, remaining offers, refresh count, bag and equipped items persist in saves. Failed refresh or sale saves roll back the transaction. Save loading normalizes offer IDs so purchases work after JSON loading.

## Item identities

| Item | Gold / unlock | Tactical effect | Tradeoff |
| --- | --- | --- | --- |
| Iron Claw Caps | 60 / level 1 | Basic attacks strip extra shield equal to 35% attack. +3% attack. | Extra shield damage never spills into health. |
| Leather Barding | 60 / level 1 | Opening shield: 12% maximum health for 5 seconds. +4% health. | Needs early contact to matter. |
| Scale Barding | 150 / level 1 | 12% less basic-attack damage. +4% health. | Spells bypass the passive. |
| Hunter’s Totem | 120 / level 1 | On casting, shield the nearest other ally within 4m for 5% wearer maximum health; 6s cooldown. +5% movement. | Cannot protect its wearer; positioning matters. |
| Briar Carapace | 180 / level 2 | Retaliate after a damaging basic hit for 30% attack as magic damage; 2s cooldown. +6% health. | Does not retaliate against spells or other item procs. |
| Ember Fangs | 200 / level 2 | Damaging basic hits reduce the target’s healing by 35% for 3s. +6% attack. | Does not stack; focus the enemy receiving heals. |
| Tideheart Pearl | 220 / level 3 | Effective healing on another ally grants 25% of that heal as a shield, capped at 6% target maximum health; 2s cooldown. +5% health. | No overhealing or self-heal conversion. |
| Froststeel Barding | 260 / level 4 | Once below 40% health, gain a 12% maximum-health shield and slow nearby enemies for 3s. +8% health. | Once per fight; lethal damage bypasses the rescue. |
| Sovereign Talons | 400 / level 5 | Basic hits on a target below 35% health trigger 45% attack bonus magic damage; 2s cooldown. +8% attack. | Finisher, not an opening burst item. |
| Astral Heart | 420 / level 6 | Resolving a learned spell recovers 1.5s of signature cooldown; 4s cooldown. +5% health. | Requires learned skills; never skips windups. |
| Crownwarden Plate | 440 / level 7 | Once below 30% health, cleanse stun/root/silence and gain a 22% maximum-health shield. +10% health. | Once per fight; does not prevent lethal hits. |
| Windstep Charm | 110 / level 1 | Incoming stuns, roots and slows last 30% less time. +4% health. | Silence is unaffected. |

Three slots—weapon, armor and charm—force tradeoffs. There are no duplicate passives on one wearer, and summons do not inherit equipment. Item damage cannot trigger retaliation or another offensive item proc. Existing global shield limits still apply. Shields last five seconds unless refreshed by another shield.

## Combat feedback

Item activations use brief colored sparks and connecting streaks, without adding arena circles. Short, quiet equipment cues share a global rate limit. Post-match ability breakdowns name item damage and activations, shielding granted, shield broken, effective healing denied, and signature cooldown recovered. Shielding granted is not the same as shield damage actually absorbed; the latter remains in the unit’s blocked total.

## Balance and validation

- 28 focused assertions cover all twelve effects, cooldowns, positioning, proc recursion, lethal-finisher kill credit, overhealing, emergency defenses, purchasing loaded stock, resale, refresh pricing, persistence, and failed-save rollback.
- 208 mirrored level-six 5v5 simulations compare one role-appropriate item against the same unequipped team over eight seeds on both sides. Baseline won 8/16; eleven items won 7–9/16. Windstep initially won 4/16 because its speed changed engagement timing; replacing speed with +4% health brought it to 8/16 in a 32-match baseline/retest. These are controlled samples, not exhaustive balance certification.
- Thirty tournament simulations sampled team levels 1, 4, 8, 12, 16 and 20. Keeper’s first glacial event was softened; its final-bout sample improved from 0/5 to 2/5, with earlier bouts easier and failed tournaments retaining progress.
- Native report → shop → buy/equip → save/load → next-match flow passes. The 42 World Tour checks, 128 living-skill checks, progression, champion UI, combat clarity, fluid motion, audio, and 12 analytics checks pass.
- The exported Windows build was visually inspected in the shop and arena. Preview footage is captured from the native build.

Future tuning should cover more team compositions, multiple item combinations, and player-selected tactics. This release adds passive tactical gear; component recipes and item crafting are not implemented.

## Play

Extract the complete Windows ZIP into a fresh folder, then launch Manitoria.exe with its matching Manitoria.pck beside it. The title screen reads Windows edition 0.17. Continue an existing World Tour or start a new club and reach the outfitter after your first match.
