# Work log: fluid combat

Read this first when resuming. Each step is committed and pushed as it lands.

## Done
- 0.78 fluid combat: PR #4 (`fluid-combat-0.78`).
- 0.79 pilot, PR #5 (draft, `combat-clips-pilot`): 14-clip support, Meshy import tool, audit, retargeter. Retargeted clips for the minotaur (14), direwolf (12) and naga (12).

## In progress (branch `combat-clips-pilot`)
1. DONE: spring bones. `tools/spring_chains_probe.gd` writes `data/spring_chains.json` (75 chains, 26 creatures). CombatAnimator adds a SpringBoneSimulator3D anchored to the fighter's holder. It swings from lunges, turns and flinches, not from sliding. It skips tails that retargeted clips already drive and the naga's body coil (`no_springs`). Test: `--fixed-fps 60 -s tools/spring_chains_test.gd`. Re-run the probe after adding retarget jobs.
2. DONE: wyvern (kaiju attacks, roar, hit and death; dragon idle; original walk).
3. Roll out by family with `data/retarget_jobs.json` templates:
   - DONE bipeds (minotaur template): cyclops, troll, wendigo, golem, treant (14 clips each); yeti upper body only (`body` 0.35, its rig has one leg chain). The owlbear is four-legged, so it moved to the quadrupeds.
   - Quadrupeds (fox and horse libraries): owlbear, cerberus, nemean, chimera, manticore, sphinx, kirin, unicorn, nekomata, kitsune, jackalope, salamander, zaratan.
   - Arachne (spider), basilisk and hydra (snake), winged creatures (dragon or bird, plus attacks from elsewhere).

## Notes
- Contact points (`ready`/`hit` in jobs) are fractions of the source clip, so a pick carries over to every creature using the same source clip and trim.
- Godot 4.7.2 binary: /home/claude/godot-bin. Render with `xvfb-run ... tools/clip_sheet.gd`.
