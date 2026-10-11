# Manitoria 0.78 — Fluid combat, part 1

Fights now flow. Swings play forward and land on the frame where the claw, jaw or club makes contact. A fighter that strikes again before its last recovery finishes rolls swing into swing instead of snapping back to idle. Hits bend the victim's body away from the blow. This release changes code only: same models, same clips, same simulation. Damage, timing, balance and seeded results are unchanged.

## What changed on screen

- **Attacks play, not scrub.** Before, the arena paused each attack clip and dragged it frame by frame through the windup, then raced the recovery at about 1.7× speed. Now each fighter has its own animation tree, and the clip plays forward at a speed the simulation's clock sets.
- **Contact on the hit.** Every creature's attack and cast clip was measured (`tools/anim_contact_probe.gd` → `godot/data/anim_contact.json`): where the anticipation ends, where the strike makes contact, and where motion resumes. The damage tick, impact trail, flash and number now land on the contact frame.
- **Wind up, hold, strike.** Long windups (artillery, physical signatures) play the anticipation at natural speed and hold it, then snap the strike so contact still lands on release. Short windups simply speed the whole move up.
- **Swing into swing.** Two action slots cross-fade, so a fast attacker blends the end of one swing into the start of the next. When there's time, recoveries play out at natural speed and speed up only if the next swing is due.
- **Casting holds.** Casters raise their arms, hold the raised pose while charging, and skip the clips' long dead hold after release.
- **Combat idle and smooth locomotion.** Idle and walk blend by actual ground speed instead of hard switching. Engaged fighters breathe faster. Bone tracks now use cubic interpolation, so slowed clips no longer look faceted.
- **Skeletal flinch.** Hits bend the spine away from the attacker with a damped spring, scaled by the share of health the hit took. Heavy creatures (golem, cyclops, zaratan, treant, yeti, minotaur, troll, hydra) flinch less. Each rig's spine is found automatically from its bone layout.
- **Per-unit hit-stop.** Solid hits freeze just the attacker and victim for 35–90 ms, and the victim shudders. The rest of the board keeps moving. Kills, quakes and MEGA CRITS keep the global hit-stop. A fighter mid-windup keeps animating, so its own strike still lands on time.
- **Contact squash.** Melee attackers squash briefly on contact, longer for heavy bodies.
- **Punchier deaths.** The body is thrown back along the killing blow, the death clip plays 1.3× faster, and the body settles and shrinks away by 2.6 s instead of sinking for 3.5 s.
- **Afterimages** copy the live skeleton pose.

## Files

- `godot/scripts/combat_animator.gd` (new): per-fighter AnimationTree (idle/walk blend, two action slots, death), contact timing, flinch spring, hit-stop.
- `godot/scripts/arena_view.gd`: spawns the animator, feeds it sim state each frame, and handles hit reactions, squash, death knockback and afterimage poses. The old `pose_phase()` and `play()` scrubbing is gone.
- `godot/data/anim_contact.json` (new): measured clip landmarks for all 32 creatures. Regenerate with `tools/anim_contact_probe.gd` whenever clips change. Dungeon models in `assets/models/dungeon/` are picked up automatically.

## Validation

- `tools/combat_animator_test.gd`: on golem, direwolf, wyvern and naga, 0.32/0.44/0.62 s windups land exactly on the measured contact frame. The release pose matches the raw clip sampled at that frame, and long windups hold the anticipation. Back-to-back swings never drop to idle. Hit-stop holds and releases the pose, paused frames never accumulate a flinch, and the flinch settles. All 32 creatures build an animator and find a spine (arachne has no branching chest and gets no flinch).
- `tools/fluid_combat_test.gd`: a seeded 5v5 runs through the real arena at 60 fps. All 91 of 91 melee basic hits landed on the attacker's contact frame. 142 swings played out and 24 cross-faded, with none snapping to idle. Hit-stop and flinch fire, and the fallen are thrown back and gone by 2.6 s. The fight's result is identical with and without the arena. Headless arena cost was 2.7 ms median, 3.9 ms p95 for 10 fighters.
- `tools/fluid_combat_capture.gd` records a seeded skirmish through the real arena with Godot's movie writer, for before/after reviews.
- Existing tests: `dungeon_smoke` (2008 checks) and `all_skill_cast_test` (416 casts) pass. `item_feedback_test` has the same 3 failures as on 0.77. `skill_vfx_test`, `skill_unlock_test`, `item_feedback_ui_test` and `shop_carousel_test` already fail on 0.77 (stale learned-skill and UI-boot assumptions, unrelated to combat), so they were not affected.

## Next

Part 2 replaces the 5-clip Meshy sets with a 14-clip combat set (two attacks, heavy attack, hit reacts, stun, spawn, victory, run). It starts with a pilot on minotaur, direwolf, wyvern and naga. The new clips drop straight into this animator: contact timing comes from the probe, and the action slots already alternate.
