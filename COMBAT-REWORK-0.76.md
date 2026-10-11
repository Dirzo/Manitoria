# Manitoria 0.76 — Combat and leveling rework

Manitoria now plays like *TFT* meets *The Last Flame*: six stats, one signature ability per champion cast when its mana bar fills, and level-ups that deal three stat cards to choose from. The old four-skill kits, the 12-skill book, skill ranks and ability upgrades are gone. The full design (every signature, its scaling and its three evolutions) is in the review doc; the numbers in the game are the source of truth and the champion card always shows live values.

## The six stats

| Stat | What it does |
| --- | --- |
| **AD** | Damage of each basic attack, and every signature number marked `% AD`. |
| **AS** | Attacks per second. More attacks also means more mana. |
| **AP** | Multiplies every signature number marked `AP`. Everyone starts at 100. AP numbers also grow 4.5% per level. |
| **Mana** | Multiplies all mana earned, so the signature casts more often. |
| **HP** | Health. |
| **Resistance** | Reduces all damage: Resistance ÷ (100 + Resistance). 50 blocks 33%, 100 blocks 50%. |

Armor, move speed as a stat, ability haste and cooldowns are gone. Move speed and range are fixed per species. Three signatures deal **true damage** (ignores Resistance): Manticore's poison, Nekomata's second strike and Harpy's last feather (plus Cyclops with Unerring Eye).

## Mana and casting

- Each champion has a fixed starting and max mana (e.g. `30 / 80`). The signature casts the moment the bar is full, then it empties.
- **+10 mana per basic attack**, plus mana from taking damage (1% of the hit before Resistance + 3% after, up to 40).
- No mana while silenced, channeling, or during a signature's own effect (a frenzy, a shell, stone form).
- Mana bars sit under the health bars in the arena and in the team panels, and glow when the next cast is one attack away.

## Level-ups

- Every level-up deals **three cards, each a different random stat at a random rarity** (Common 55%, Rare 28%, Epic 13%, Legendary 4%; better from level 15). Keep one. Each card previews the stat change and the signature's new numbers.
- Every level also adds **+3% base HP and +2% base AD**.
- **Card rerolls:** every run starts with 3. Dungeon elites give 1 and Wardens give 2.
- Rivals and dungeon mobs pick automatically, favouring what their signature scales with.

## Evolutions and Apex

- The 96 evolutions (three per champion, at level 8) are rewritten. Each only changes the signature, the six stats, or adds movement (dashes, leaps, pulls, knockbacks, untargetable). None grants a second ability.
- **Apex** (level 16) is now Apex Body (+15% HP, AD, AP), Apex Signature (signature +25%, max mana −10) or Apex Instinct (+15% AS and Mana, first cast at full mana).

## Items, relics and old saves

- Item stats convert: Attack → AD, Attack speed → AS, Ability power → AP, Health → HP, Armor → Resistance (+0.05 armor = +8), Move speed and cooldown items → Mana. Item effects (crit, dodge, lifesteal, procs) are unchanged; cooldown-refund effects now grant mana.
- Relic and run-trait move speed bonuses now give Mana.
- **Old saves migrate automatically:** champions keep level, rolls, evolution and items. Skills are removed, past level-ups become auto-picked cards, pending level-ups become stat cards, Apex Mastery becomes Apex Signature, and every migrated champion gets **one free card reset** on its profile.

## Review notes applied

- Harpy and Wyvern are AD carries now (Featherstorm, Corrosive Spit).
- Manticore (poison) and Harpy (last feather) gained true damage.
- 3 card rerolls at the start of a run, more from the dungeon.
- Sphinx's confusion was trimmed to 1.5s after the balance sweep.

## Balance and pacing

Tuned with `tools/v076_balance.gd` (random mirrored-level 5v5s at levels 1, 10 and 20):

| Level | Fight length | First cast | Casts per champion | Signature share of damage |
| --- | --- | --- | --- | --- |
| 1 | 35.9s | 10.6s | 1.8 | 30% |
| 10 | 35.8s | 9.4s | 2.2 | 45% |
| 20 | 36.1s | 5.2s | 3.2 | 58% |

AD and AP champions deal about the same damage by level 20 (1,802 vs 1,768 per fight). Most champions win 40–60% of fights at every level. Still outside that band and first in line for the next pass:

- **Strong:** Thunderbird (69% at level 20), Nekomata (67% at 10, 64% at 20), Phoenix (63% at 20), Cerberus (76% at level 1 only), Kirin (66% at 20, but 38% at 1).
- **Weak:** Wendigo (36–40%), Zaratan (27% at 10), Chimera (34% at 10), Cyclops (37–38% at 1 and 20), Owlbear (37% at 20), Minotaur (38–40% after level 1).

Mana costs were cut 20% and base HP lowered so fights run about 36 seconds with the first casts 5–10 seconds in. Per-species win rates use about 60 appearances each, so ±7% is noise.

## Validation

- `tools/signature_smoke.gd` — every species with no evolution and each of its three evolutions casts in real fights (128 configurations, no errors).
- `tools/v076_migration_test.gd` — an old 0.75 champion with skills, ranks, Apex Mastery and pending skill cards: 13 checks, 0 failures.
- `tools/full_tour_smoke.gd` — 303 checks, 0 failures. `tools/dungeon_smoke.gd` — 2,018 checks, 0 failures.
- `tools/parse_check.gd` — every script loads.
- In-engine captures of the level-up cards, the evolution choice, the champion view and a live fight.
