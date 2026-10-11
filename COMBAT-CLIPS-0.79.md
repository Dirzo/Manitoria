# Manitoria 0.79 (in progress) — Combat clip set: pipeline and first pilot creatures

Step 2 of the fluid-combat plan replaces each creature's five thin clips with a 14-clip combat set. The **minotaur, direwolf and naga** now fight with new clips:

- **Minotaur:** all 14 clips.
- **Direwolf and naga:** 12 each, falling back cleanly for the rest.

The clips are retargeted from Mesh2Motion's public-domain (CC0) animation libraries onto each creature's existing Meshy rig. Models and skin weights are unchanged, no Meshy credits were used, and the simulation and balance are untouched. The other 29 creatures look exactly as they did in 0.78.

## Why not Meshy for these clips

Meshy's 631 animation presets are humanoid only; four-legged rigs get a walk and nothing else. Meshy could have animated the minotaur, but not the direwolf, wyvern or naga. Mesh2Motion's libraries are public domain and include fox, horse, snake, spider, kaiju, dragon and human rigs with attacks, hits, deaths and more. A retargeter maps any of them onto Manitoria's rigs by body shape.

## The retargeter (godot/tools/retargeter.gd)

- **Chains by shape:** both skeletons are split into spine, neck, two arm or front-leg chains, two legs and a tail. This works on the generic `Bone_###` rigs; odd rigs like the naga name their chains in the job file.
- **Limbs copy direction:** each limb bone points where the matching source segment points.
- **Spine, neck and tail copy rotation:** they copy the source's full change of rotation from its reference pose, twist included. The minotaur keeps its hunch and copies the motion, not the human posture.
- **Hips:** the hips copy orientation change plus a scaled, in-place version of the travel. Feet are pulled back onto the floor each frame.
- **Per-clip tuning:** `twist` keeps part of the body's turn (sword combos spin up to 145°), `amplify` exaggerates subtle motion, and there are also speed, trim, grounding, and hand-picked contact points.
- **Output:** `assets/beasts/clips/<creature>.res`, layered over the model's own clips at runtime. Every bone gets a track.

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

## Pilot results

| Creature | Source | Clips | Highlights |
| --- | --- | --- | --- |
| minotaur | human | 14/14 | Guard stance, axe swing, hooking lunge, overhead heavy slash, ground-pound cast, head-snap and shield-break hits, dizzy stun, ninja landing, victory raise. |
| direwolf | fox, horse, kaiju | 12/14 | Stalking alert idle, real gallop, amplified bite, head-butt, pounce, howl cast and victory, leap-in spawn. |
| naga | human (upper body) | 12/14 | Trident guard, sweep, left-hand jab, overhead thrust, thrust cast, staggers, dizzy, slumping death. The tail and hair don't move yet. |
| wyvern | — | 0/14 | The dragon library has no attacks, so this needs another source. |

Share of the rig each attack moves (`anim_audit`): minotaur 7% → 26%, direwolf 46% → 63–78%, naga 8% → 13–14%. The minotaur and naga numbers stay low because their rigs carry many accessory bones (fingers, hair, tail, cloth) that no source rig has. A spring-bone pass for hair, tails and cloth is the next improvement.

## Validation

- `combat_clipset_test` (new): synthetic 14-clip direwolf. Swings alternate, the heavy attack lands contact, hit reactions play and end and never interrupt a windup, stun takes over and releases, run blends in and out by speed, spawn plays while the clock is stopped, and victory loops. Five-clip creatures fall back on every path. 0 failures.
- `build_creature_test` (new): fake Meshy exports (Meshy-style names, 2.5× scale, off-centre, walk with 1.5 units of root travel, a stray file). Clips are renamed, poses match the source exactly, travel is stripped, the model is normalised to 1.700 tall and centred, the stray file is skipped, and detected feet match the hand-made `feet.json` entry. 0 failures.
- `combat_animator_test`: 0 failures, now running on the direwolf's retargeted clips. It caught a dip toward idle between back-to-back swings with the longer new clips. A finished swing now holds its last frame when the next swing is due, so the two cross-fade directly.
- `fluid_combat_test`: the seeded 5v5 includes the minotaur, direwolf and naga on their new clips. All 91 of 91 melee hits land on the attacker's contact frame, with `attack_1` and `attack_2` alternating, and no swing snaps to idle. The result is identical with and without the arena.
- `dungeon_smoke`: 2008 checks pass.
- Every retargeted clip was reviewed in rendered contact sheets (`tools/clip_sheet.gd`), and the pilot trio was recorded in a seeded fight before and after.

## Next

- **Secondary motion:** spring bones for the tails, hair and cloth that no source rig drives (naga hair and tail, minotaur tail and loincloth). Godot 4.7 has a spring-bone simulator built in.
- **Wyvern:** the dragon library has no attacks. Try the kaiju library's attacks on its body, key a bite by hand, or use Meshy if its creature tools improve.
- **Roll out by body family**, using the pilot's job files as templates:
  - **Bipeds:** human library (cyclops, troll, yeti, wendigo, golem, treant, owlbear).
  - **Quadrupeds:** fox and horse libraries (cerberus, nemean, chimera, manticore, sphinx, kirin, unicorn, nekomata, kitsune, jackalope, salamander, zaratan).
  - **Arachne:** spider library.
  - **Basilisk and hydra:** snake library.
  - **Winged creatures:** dragon and bird locomotion plus another source for attacks.
