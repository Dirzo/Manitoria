# Manitoria 0.79 — Permadeath

Champions now die for good in the dungeon. When you lose a fight, you lose a life and the first of your champions to fall is gone. The run still ends when your lives run out. Five new relics let a sixth champion fight, each with a different price.

## How death works

- **A lost fight costs a life and the first champion to fall.** Its items go back to your bag. If it was your headliner, your highest-level survivor takes the crown.
- **Grace:** in the first three rooms of a run, that champion is only Wounded.
- **Wounds:** a Wounded champion fights at −15% HP, AD and AP until a campfire, a healing spring or the next descent mends it.
- **Legacy:** when a champion dies, every survivor gains 60 XP.
- **Recruits** from checkpoints, Warden stairs and outfitters join 2 levels below your guild's average.
- **The guild holds 7** (was 6), and **5 take the field**, so you can keep a bench.
- **The Pale Ferryman** can bring back your most recent fallen champion for 120 gold, without items.
- **On screen:** a skull chip in the run bar lists the fallen. The result screen names who fell for good and who is Wounded. Wounded champions show orange in the squad drawer.

## Fielding six

Five relics let a sixth champion fight. You can hold one.

| Relic | Where | Price |
| --- | --- | --- |
| War Council | Warden relic pick | Takes your Warden relic pick |
| The Sixth Standard | Recruiting Sergeant event (new) | 200 gold |
| Mercenary Contract | Elite and event relic picks | 35 gold after every fight |
| Reaper's Bargain | Elite and event relic picks | Wounds no longer heal when you descend |
| Crowded Banner | Elite and event relic picks | Your team has −8% HP, AD and AP |

## Balance

- **Warden fix:** a Warden now brings at most one escort. Before, a second escort joined once you fielded five, which made five-champion Warden fights much harder than four-champion ones.
- **Threat curve:** opponents are ×1.0 / ×1.18 / ×1.24 stronger by depth (Champion: ×1.0 / ×1.06 / ×1.1).
- Auto-played clear rates, 80 runs each, on the v0.79 code (v0.78's fluid combat and Warden counterplay included), old lives-only rules → v0.79:

| Difficulty | Old rules | v0.79 | Deaths per run |
| --- | --- | --- | --- |
| Keeper | 95% | 85% | 2.1 |
| Standard | 69% | 49% | 2.9 |
| Champion | 34% | 20% | 1.7 |

Both columns include the Warden escort fix. v0.78's Warden counterplay made the dungeon easier (Standard 54% → 69% under the old rules), so the act 2–3 threat was raised to bring permadeath Standard back near 45–50%. v0.77 as shipped cleared about 38% on Standard.

## Saves and tools

- Runs started before v0.79 finish under the old lives-only rules with six fielded. New runs use permadeath.
- Rules live in `Dungeon.DEFAULT_RULES` (`godot/scripts/dungeon.gd`). The dormant options `wounds`, `hard`, `headliner_fatal` and `wound_others` are kept for future modes.
- `tools/dungeon_balance_probe.gd` takes `PROBE_RULES` (JSON) and `PROBE_DIFFICULTY` to playtest rule sets. `tools/v079_permadeath_test.gd` checks the rules.
