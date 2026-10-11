# Manitoria 0.79 (in progress) — Combat clip set, part 1: pipeline and pilot brief

Step 2 of the fluid-combat plan replaces each creature's five thin clips with a 14-clip combat set. This first half is everything except the art itself. The game can now play all 14 clips, a Meshy export drops into the game with one command, and the four pilot creatures have a production brief. Until new clips are imported, the game looks and plays exactly like 0.78.

## Why the clips need replacing

`tools/anim_audit.gd` measures how much of each rig a clip actually moves. Today the minotaur's attack moves 7% of its bones and its cast 6%. The naga's attack moves 8%, and the direwolf's and wyvern's attacks 45–46%. The target is 80% or more. No creature has hit reactions, a stun, a run, a second attack, a spawn or a victory.

## The 14 clips

`idle`, `idle_combat`, `walk`, `run`, `attack_1`, `attack_2`, `attack_heavy`, `cast`, `hit_light`, `hit_heavy`, `stun`, `death`, `spawn`, `victory`. Each is optional except `idle`. The full table, timing rules and export contract are in [art/combat_clips/README.md](art/combat_clips/README.md).

## What the game does with them (scripts/combat_animator.gd)

- **Two swings:** basic attacks alternate `attack_1` and `attack_2`. Contact is still measured per clip, so each one lands on the hit.
- **Heavy attack:** physical skills (charges, slams, pounces) play `attack_heavy`. Magical skills play `cast`.
- **Combat idle:** `idle_combat` blends in while a fighter is engaged.
- **Run:** `run` takes over from `walk` when travelling well above the walk's foot-planted speed.
- **Hit reactions:** `hit_light` (2%+ of max HP) and `hit_heavy` (6%+) play on top of everything, on top of the spine flinch. They never interrupt the fighter's own windup.
- **Stun:** `stun` loops while stunned (a slowed idle otherwise).
- **Spawn:** `spawn` plays as fighters take the board, in real time during the countdown.
- **Victory:** `victory` loops for the winning team while results are tallied.
- **Fallbacks:** without the new clips, every path falls back to the original five. The old `attack` is used as `attack_1`.

## Pipeline (godot/tools)

- `build_creature.gd` / `creature_builder.gd`: reads a folder of Meshy exports (`<creature>__<clip>.glb|fbx`, FBX through Godot's built-in reader, no Blender needed). It renames clips, points every track at one skeleton, strips root motion, scales to the standard 1.7 height on the ground and centred, and detects foot bones for the gait tools. It writes `assets/beasts/<creature>.glb` after backing up the old model.
- `anim_audit.gd`: clip presence, rig coverage, loop seams, root drift, measured contact and feet. Writes `data/anim_audit.json`. `--strict` gates the pilot creatures.
- `anim_contact_probe.gd`: now also measures `attack_1`, `attack_2` and `attack_heavy`.

## Pilot brief (art/combat_clips)

Minotaur (biped, Meshy humanoid rig and presets), direwolf (quadruped), wyvern (winged quadruped) and naga (serpent, custom rig). Each has 14 clips with motion notes tied to its attack style and signature. A pilot log tracks which clips came from presets, which were keyed, and the hours per creature.

## Validation

- `combat_clipset_test` (new): synthetic 14-clip direwolf. Swings alternate, the heavy attack lands contact, hit reactions play and end and never interrupt a windup, stun takes over and releases, run blends in and out by speed, spawn plays while the clock is stopped, and victory loops. Five-clip creatures fall back on every path. 0 failures.
- `build_creature_test` (new): fake Meshy exports (Meshy-style names, 2.5× scale, off-centre, walk with 1.5 units of root travel, a stray file). Clips are renamed, poses match the source exactly, travel is stripped, the model is normalised to 1.700 tall and centred, the stray file is skipped, and detected feet match the hand-made `feet.json` entry. 0 failures.
- 0.78 suites unchanged: `combat_animator_test` 0 failures, `fluid_combat_test` 91/91 hits on contact, `dungeon_smoke` 2008 checks, `all_skill_cast_test` 416 casts.

## Next

Produce the pilot clips in Meshy per the briefs, run `build_creature`, `anim_contact_probe`, `gait_probe` and `anim_audit --strict minotaur,direwolf,wyvern,naga`, review in game, and fill in the pilot log. The log decides the schedule for the other 28.
