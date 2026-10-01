# Manitoria 0.18 — Role Arsenal

48 tactical items: twelve Tank, twelve Assassin / Flank, twelve Carry, and twelve Support. The original twelve equipment IDs are retained, so existing inventories and loadouts continue to work. The 36 additions use real combat triggers, rather than additional stat-only tiers.

## Shop

Every fresh six-item stock contains one unlocked item from each of the four styles and two additional offers. Offers remain seeded, unique within a stock, and persistent through saving and loading. Existing mid-shop saves retain their offers until the next paid refresh or match.

The style selector filters current offers for free. Turn on **Catalog · 48** to browse every item, including future unlocks; unavailable items cannot be purchased. Catalog entries are ordered by team-level unlock and price. Refreshing is disabled while browsing the catalog. All four styles are suggestions, not hero-class restrictions: any hero can equip any item that fits its weapon, armor or charm slot.

## Combat rules

Equipment still uses three slots per hero. New trigger chains ignore damage and healing credited to items, preventing recursive procs. Legacy emergency shields still respond to damage. Cooldowns and once-per-battle flags reset for each battle. Shared Rally and Weaken statuses refresh rather than stack their power. Control durations use the existing status system; Windstep still shortens incoming stun/root/slow durations. Shields retain the global 55% maximum-health cap and five-second lifetime. Emergency gear cannot rescue a lethal hit.

Damage, effective healing, item activations, granted shielding, shield breaking, healing denied, and cooldown recovery remain in the post-match breakdown. Spellguard also reports damage reduced before armor. Short item flashes and rate-limited sounds use the existing arena presentation.

## The arsenal

### Tank — 12 items

| Item | Slot | Gold / team level | Effect | Tradeoff |
| --- | --- | --- | --- | --- |
| Leather Barding | armor | 60 / 1 | Start combat with a 12% maximum-health shield for 5 seconds. | Frontline opener; wasted if contact comes too late. |
| Scale Barding | armor | 150 / 1 | Take 12% less damage from basic attacks. | Counters attack carries; does not reduce spells. |
| Spellguard Mantle | armor | 150 / 1 | Take 12% less magical damage. | Basic attacks bypass this protection. |
| Briar Carapace | armor | 180 / 2 | After taking a basic hit, retaliate for 30% attack as magic damage. 2s cooldown. | Punishes attackers; spell damage never triggers it. |
| Anchor Chains | claw | 200 / 2 | After a damaging basic hit from an enemy within 3m, root them for 0.6s. 10s cooldown. | Ranged attackers outside 3m stay free. |
| Rampart Sigil | charm | 220 / 2 | Resolving a skill grants a 6% maximum-health shield. 6s cooldown. | Needs time to finish a cast. |
| Laststand Talisman | charm | 240 / 3 | After taking damage below 40% health, heal 5% maximum health. 8s cooldown. | Cannot rescue a lethal hit; healing reduction applies. |
| Froststeel Barding | armor | 260 / 4 | Once below 40% health, slow enemies within 3m for 3s and gain a 12% maximum-health shield. | Once per battle; enemies can finish you with a lethal hit. |
| Breakwater Plate | armor | 260 / 4 | Survive a hit worth at least 12% maximum health to gain an 8% health shield. 8s cooldown. | Small hits do not trigger it. |
| Defiance Horn | claw | 360 / 5 | When damaged with 2+ enemies within 3m, weaken the attacker for 2s. 8s cooldown. | Needs a crowded frontline; weaken does not stack. |
| Wardstone Standard | charm | 400 / 6 | At combat start, shield the two nearest allies within 4m for 6% of your maximum health. | Cannot shield its wearer; shields expire after 5s. |
| Crownwarden Plate | armor | 440 / 7 | Once below 30% health, cleanse stun, root and silence and gain a 22% maximum-health shield. | Once per battle; cannot prevent a lethal hit. |

### Assassin / Flank — 12 items

| Item | Slot | Gold / team level | Effect | Tradeoff |
| --- | --- | --- | --- | --- |
| Windstep Charm | charm | 110 / 1 | Stuns, roots and slows applied to the wearer last 30% less time. | Helps mobile hunters; silence duration is unchanged. |
| Duskveil Cloak | armor | 110 / 1 | Your first damaging basic hit grants an 8% maximum-health shield. | Once per fight; survives contact instead of the march. |
| Hookblade | claw | 120 / 1 | Basic hits on a ranged enemy slow them for 1.5s. 5s cooldown. | No effect against melee opponents. |
| Pursuit Talon | claw | 210 / 2 | Basic hits against enemies still above 75% health deal 40% attack bonus magic damage. 3s cooldown. | Stops working as the target weakens. |
| Ambush Knife | claw | 220 / 2 | Basic hits on an enemy with no ally within 3m deal 45% attack bonus magic damage. 4s cooldown. | Enemy formations can deny the bonus. |
| Shadeguard | armor | 230 / 2 | Survive a hit from beyond 3m to gain a 10% maximum-health shield. 8s cooldown. | Protection begins after the triggering hit. |
| Nightleech Fang | claw | 240 / 3 | Basic hits on isolated enemies heal 30% of actual damage dealt. 4s cooldown. | Only effective health damage counts. |
| Duelist Seal | charm | 260 / 3 | Every third damaging basic hit on the same target deals 35% attack bonus magic damage. 3s cooldown. | Changing target resets the hit count. |
| Crescent Spurs | charm | 250 / 4 | Resolving a skill clears your roots and slows. 8s cooldown. | Cannot remove stun or silence to start a cast. |
| Silence Pin | charm | 380 / 5 | Resolving a skill silences your current enemy target within 4m for 1.2s. 10s cooldown. | Requires a nearby living target; cannot skip windups. |
| Sovereign Talons | claw | 400 / 5 | Basic hits against enemies below 35% health deal an extra 45% attack as magic damage. 2s cooldown. | Pick weakened targets; no bonus against healthy enemies. |
| Smokeweave | armor | 400 / 6 | Survive damage below 30% health to gain 1.2s stealth and a 5% health shield. | Once per fight; existing projectiles can still hit. |

### Carry — 12 items

| Item | Slot | Gold / team level | Effect | Tradeoff |
| --- | --- | --- | --- | --- |
| Iron Claw Caps | claw | 60 / 1 | Basic attacks against shields deal an extra 35% attack to the shield. | Counters shields; no bonus against exposed health. |
| Steadyshot Bow | claw | 130 / 1 | Every third damaging basic hit deals 35% attack bonus magic damage. 3s cooldown. | Spell hits do not build the counter. |
| Ember Fangs | claw | 200 / 2 | Damaging basic hits inflict Scorch: 35% less healing for 3s. | Hunt healers’ targets; does not stack with more Fangs. |
| Siege Pennant | charm | 200 / 2 | Basic hits against a shield grant Rally for 1.5s. 6s cooldown. | Rally does not stack with other Rally sources. |
| Longshot Lens | charm | 220 / 2 | Basic hits from at least 4m deal 25% attack bonus magic damage. 3s cooldown. | Melee pressure denies the bonus. |
| Runic Capacitor | charm | 240 / 2 | Resolving a skill zaps your current target within 5m for 25% attack magic damage. 6s cooldown. | Needs a living target in range. |
| Focus Lens | charm | 230 / 3 | Every third basic hit on the same target recovers 1s of signature cooldown. 4s cooldown. | Target changes reset the sequence. |
| Giantbane Arrow | claw | 270 / 4 | Basic hits on enemies with 25% more maximum health deal 2% of their maximum health as magic damage, capped at 70% attack. 4s cooldown. | No proc on smaller enemies. |
| Lifeline Harness | armor | 380 / 5 | Survive damage below 35% health to gain a 14% maximum-health shield. | Once per battle; not protection against a lethal hit. |
| Echo Edge | claw | 400 / 5 | A resolved learned skill primes your next basic hit within 5s for 60% attack bonus magic damage. 6s cooldown. | Must weave an attack between skills. |
| Astral Heart | charm | 420 / 6 | Resolving a learned ability removes 1.5s from signature cooldown. 4s cooldown. | Needs learned spells; never bypasses a windup. |
| Stormwire | claw | 420 / 6 | Basic hits arc to one other enemy within 3m of the target for 35% attack magic damage. 4s cooldown. | Deals no bonus to the original target. |

### Support — 12 items

| Item | Slot | Gold / team level | Effect | Tradeoff |
| --- | --- | --- | --- | --- |
| Pilgrim Medal | armor | 110 / 1 | At combat start, grant the nearest other ally within 4m Rally for 2.5s. | Once per fight; arrange allies for early contact. |
| Hunter’s Totem | charm | 120 / 1 | On casting, shield the nearest other ally within 4m for 5% of your maximum health. 6s cooldown. | Stay beside a carry; cannot shield its wearer. |
| Mercy Bell | charm | 130 / 1 | On casting, heal the most wounded other ally within 5m for 4% of your maximum health. 6s cooldown. | Must finish a cast near an injured ally. |
| Frost Censer | claw | 180 / 2 | Damaging basic hits weaken the enemy for 2s. 6s cooldown. | Requires attacking; weaken does not stack. |
| Guardian Lantern | armor | 220 / 2 | On casting, shield the most wounded other ally within 5m below 50% health for 8% of your maximum health. 8s cooldown. | Healthy allies do not consume the trigger. |
| Cleansing Incense | charm | 240 / 2 | Effective healing on another ally clears their stun, root and silence. 6s cooldown. | Needs effective healing and removable control. |
| Tideheart Pearl | charm | 220 / 3 | Effective healing on another ally grants a shield equal to 25% of that heal, capped at 6% of their maximum health. 2s cooldown. | Needs real healing; overhealing and self-heals do not trigger. |
| Rally Banner | claw | 240 / 3 | Effective healing on another ally grants them Rally for 2s. 6s cooldown. | No self-buff; Rally does not stack. |
| Echo Chalice | charm | 260 / 4 | Healing another ally also heals one injured ally within 3m of them for 30% of actual healing, capped at 4% recipient maximum health. 4s cooldown. | Cannot echo back to the original target or caster. |
| Rescue Cord | armor | 360 / 5 | Survive damage below 35% health to heal the most wounded other ally within 5m for 8% of your maximum health. | Once per battle; helps an ally, not its wearer. |
| Concord Staff | claw | 400 / 5 | On casting, shield yourself and the nearest other ally within 4m for 4% of your maximum health. 8s cooldown. | Requires another ally nearby. |
| Kindred Hourglass | charm | 420 / 6 | Effective healing on another ally recovers 1s of their signature cooldown. 6s cooldown. | No benefit when their signature is already ready. |

## Validation

253 catalog, item-trigger, cooldown, cap and stock-distribution checks pass. Seven native catalog UI checks cover browsing, role filtering, locked purchases and free navigation. Fourteen interaction checks cover multi-item healing, cast-to-attack weaving, tank defenses, and four completed battles with mixed loadouts. The previous 28 tactical-item checks, 42 tournament checks, native campaign flow, all 128 living skills, progression, fluid movement, clarity, audio and analytics checks pass.

A mirrored simulation sample tests each item individually on a fixed level-six squad over three seeds on both sides (294 fights including the baseline). A further 64 mirrored fights retested Silence Pin, Rally Banner and Kindred Hourglass with a baseline. The follow-up baseline won 8/16; Silence Pin and Rally Banner each won 10/16, and Kindred Hourglass won 8/16. This is a limited regression and outlier screen, not an exhaustive assessment of every hero, gear combination, or player tactic.

Extract the full Windows archive into a fresh folder and launch Manitoria.exe beside its matching Manitoria.pck. The title screen reads Windows edition 0.18. Continue an existing campaign or play a tournament match to enter the outfitter.
