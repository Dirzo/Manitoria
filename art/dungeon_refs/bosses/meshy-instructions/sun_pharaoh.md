# The Sun-Eater Pharaoh — Gilded Tomb

Reference: `references/sun_pharaoh.png`
Final game asset: `godot/assets/models/dungeon/sun_pharaoh.glb`

## Reconstruction and rigging
Upload the matching PNG to Meshy Image to 3D. Use this brief as a reconstruction/cleanup checklist; paste it into Meshy 3D Agent if using that route. Inspect the hidden back and underside manually; the image does not define them. Remove any reconstructed grey backdrop or floor. Remesh before rigging and inspect all joints.

Target 20–30k final triangles, one 2K PBR atlas, at most two materials, <=64 deform bones and <=4 weights per vertex. Bake minor details. Use opaque materials; gameplay particles belong outside the model. Creature rigs require custom non-walk clips; Smart Rig does not imply access to the animation preset library.

**Rig route:** Humanoid: this reference is bipedal.

**Cleanup priorities:** Rigid headdress and weapon attachments; simple skirt bones. Bake hieroglyphs and chains. Maintain dark readable separation around gold surfaces.

## Six exact animation names

| Clip | Motion |
| --- | --- |
| `idle` | Regal chest motion and small prop sway; loop 2–4 seconds. |
| `walk` | Even ceremonial steps; loop 0.8–1.4 seconds, in place. |
| `attack` | Weapon sweep; contact near normalized 0.46. |
| `cast` | Solar Judgment: Raise the sun insignia/weapon and open the other arm; direct the judgment at 46%. |
| `hit` | Short 0.20–0.35 second torso recoil, feet stable. |
| `death` | Kneel, lower sun prop and settle the crown; hold the final pose, no loop. |

Attack/cast authoring length can be about 0.8–1.5 seconds. The renderer samples windup through 0–0.46 and recovery through 0.46–0.99; animation length does not control damage timing. The current Warden warning is 1.25 simulation seconds. Do not attach damage or sound events to these clips. One cast clip also serves the boss's existing slam/pulse/summon warnings, so keep its silhouette readable across those events.

## Export and fight check

Combine all six clips on one skeleton/AnimationPlayer; humanoid presets are starting points, not guaranteed matches for these custom motions. Export GLB with embedded textures, Y-up, +Z forward in Godot, ground-centered root, no root translation and no visual physics colliders. Begin around champion-sized local body dimensions: the renderer adds Warden scaling.

Check feet and turns at final scale, interruption during windup, contact at 46%, death holding, warning marker visibility, and no duplicate audio. Review six-player fights with summons at 1×, 2× and 4×. Measure frame time on the target PC; reduce materials, overdraw and minor geometry if needed. See START-HERE.md for gait calibration, exact import contract, LOD targets and acceptance checks.

These are concept and production instructions. This kit contains no Meshy-generated model or measured gameplay performance.
