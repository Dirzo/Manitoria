# Manitoria — Epic Wardens + Meshy fight guide

Ten original ImageGen boss references, one for every thematic dungeon zone. These are concept images, not rigged 3D models. The kit includes individual Meshy briefs, full ImageGen prompts and a production manifest. Actual Meshy generation, rig cleanup, animation and in-game profiling still need to happen; the settings below are production targets, not measured performance claims.

## Quick start

1. Open Meshy **Image to 3D**. Upload the matching PNG from `references/`. Use the matching brief from `meshy-instructions/` as a reconstruction and cleanup checklist; paste it into Meshy 3D Agent if using that route. Preserve the silhouette; inspect the model from all sides before spending time on animations.
2. Remesh before rigging. Aim for **20,000–30,000 final triangles** for the close model. If choosing quads, about 10,000–15,000 quads become about 20,000–30,000 triangles after export; inspect the actual GLB count. Do not enter 30,000 quads and call the export 30,000 triangles.
3. Use opaque PBR materials: base color, normal, roughness/metalness and modest emission where useful. Begin with a **single 2K material atlas**, at most two materials. Use painted/normal-map detail for tiny chain links, spores, barnacles, cloth embroidery and feather grooves. Avoid transparent glass, dense individual fur strands and physics cloth in the battle asset.
4. Texture and repair obvious geometry problems, then rig. Use the boss-specific rig route below. Meshy's humanoid, quadruped and Smart Rig workflows have different animation support; nonstandard rigs are not guaranteed one-click results.
5. Obtain six clips on **one identical skeleton**: `idle`, `walk`, `attack`, `cast`, `hit`, `death`. Preview all six, combine separate exports in Blender if needed, then export a single GLB. Rename clips exactly and remove duplicate skeletons/animation-library prefixes. Do not assume the app will produce these exact names or all six custom motions automatically.
6. Export to the matching `godot/assets/models/dungeon/<boss_id>.glb` path. Import in Godot, verify animation names and scale, then run a watched boss fight. The current native project already looks for those paths. Until a valid model exists, it keeps using its stand-in.

## Which rig for which boss?

| Zone | Boss / PNG | Meshy route | Additional animation work |
| --- | --- | --- | --- |
| Blight Forest | Rootmother / `rootmother.png` | Humanoid if trunk/limbs are recognized; otherwise custom | Branch fingers and crown can stay rigid; avoid arbitrary disconnected roots. |
| Mana Caverns | Prismatic Archon / `prismatic_archon.png` | Quadruped for the four-legged body | Add wing bones for all six wings; author casts and other non-walk clips. |
| Magma Depths | Forge Tyrant / `forge_tyrant.png` | Humanoid | Bind hammer to hand; author a heavy planted slam. |
| Frostbound Crypt | Frost Matriarch / `frost_matriarch.png` | Humanoid | Bind staff; cloth is skinned to simple bones, not simulated. |
| Drowned Sanctum | Drowned Leviathan / `leviathan.png` | Quadruped for the four-legged body | Add jaw, tail and fin chains; author non-walk clips. |
| Fungal Hollows | Spore Queen / `spore_queen.png` | Smart Rig Beta if available, or manual spider rig | Eight independent leg chains and custom clips; not a quadruped. |
| Ossuary of Kings | Bone King / `bone_king.png` | Humanoid | Rigid plate/bone segments; bind sceptre to hand. |
| Storm Spire | Tempest Roc / `tempest_roc.png` | Custom bird rig; try Smart Rig Beta if available | Two legs, two wing chains and tail; do not assign a dog skeleton. |
| Gilded Tomb | Sun-Eater Pharaoh / `sun_pharaoh.png` | Humanoid | This design is bipedal despite its old sphinx stand-in; bind props. |
| Void Rift | Abyssal Keeper / `abyssal_keeper.png` | Humanoid | This design is bipedal despite its old hydra stand-in; halos are rigid attachments. |

Meshy's Help Center currently says quadruped preset animation is limited to walking and Smart Rig models do not support the preset animation library. Treat those as limits: export the rigged mesh and author/retarget the missing clips in Blender. The API rigging docs are narrower still: they describe textured humanoid assets. This guide uses the **web app** route for creature rigs, not a claim that the API supports every boss.

## Animation contract for smooth fights

| Exact clip | Suggested authored duration | Loop | Motion design |
| --- | --- | --- | --- |
| `idle` | 2–4 s | Yes | Restrained breathing, crown/wing motion. Same root transform at both ends. |
| `walk` | 0.8–1.4 s | Yes | In-place locomotion; clean foot plants and matching start/end pose. No forward root translation. |
| `attack` | 0.8–1.2 s | No | Clear anticipation, contact around normalized frame **0.46**, readable follow-through. |
| `cast` | 1.0–1.5 s | No | Gather power through the first 46%; release around **0.46**; follow through in the remainder. |
| `hit` | 0.20–0.35 s | No | Short torso recoil that can blend away without snapping feet. |
| `death` | 2–3 s | No | Collapse, then hold the final pose; avoid a last-frame return to idle. |

These are authored-clip targets. **The simulation controls real attack/cast timing**, not the animation's length. In the current arena renderer, `pose_phase()` samples the attack/cast clip through 0–0.46 during anticipation and 0.46–0.99 during recovery. The new Warden windup is 1.25 simulation seconds. Put the motion's impact/release near 0.46 so visual contact lines up; do not put the impact at the clip's final frame. Test the transition into recovery and interrupting mid-windup. There are short existing blends (0.07 s when phase sampling changes state, 0.16 s on normal playback).

Use eased rotations and arcs; avoid one-frame hammer snaps or wings teleporting between poses. Keep root position and heading fixed in the file: the game positions and rotates the model. Do not include attack animation events that also deal damage, create summons or play another attack sound. That would compete with the simulation's authoritative event/audio path.

The current walking-speed calibration uses the stand-in **species**, not the new monster ID. After replacing a model, inspect foot sliding and calibrate `GaitRates.PLANT`/a future per-monster override against that new clip; exported in-place animation alone does not guarantee planted feet. Calibrate at the final rendered scale and normal movement speed.

## Geometry and materials

These are project targets, not Meshy account limits:

- Close model: <=30k final triangles; medium LOD ~12–15k; distant LOD ~4–6k. Start with Godot's generated LODs and inspect thin horns/wings; author replacements if the silhouette breaks.
- One skeleton, preferably <=64 deform bones and <=4 bone influences per vertex. Use rigid bone attachments for weapons, crowns and rings.
- One 2K atlas, ideally one draw material; two if absolutely needed. Use 1K for a low-memory variant. Keep texture mipmaps and the project's platform compression.
- Keep crystal, ice and void armor **opaque**. Fake inner light using emission and painted highlights; avoid full-screen refraction and many overlapping alpha surfaces.
- Emitters, poison spores, storms, water, fire and void clouds belong in game VFX. Do not bake smoke meshes and dozens of lights into every GLB.
- Reduce or bake the concept's smallest chains, branch twigs, spikes, barnacles and embroidered details. Preserve the large silhouette first.
- Skin cloth and kelp with a few bones; no cloth/rigid-body simulation is needed for the boss model.

## Godot import / placement

The expected basename is the boss ID in the table. For example:

`godot/assets/models/dungeon/forge_tyrant.glb`

1. Export GLB with embedded textures, skeleton, skin weights, UVs, normals and all six animation clips. If working in Blender, apply mesh transforms before skinning or recheck weights after transform changes. Use Y-up in the exported glTF and face **+Z** in the Godot model scene; the arena's heading math assumes +Z forward.
2. Put the root origin at the ground under the body. Keep root transforms stable in all loops. Inspect the Godot scene after import rather than trusting Blender's display orientation.
3. Start with a humanoid around **2 local units tall**; normalize quadrupeds/birds by their body volume, not their wing or tail span. Compare with an existing champion. The arena applies `MODEL_SCALE` (0.98) and the Warden's scale (~1.7–1.8) again, so do not export a pre-enlarged giant. Adjust mesh dimensions in the authoring file, not gameplay stats.
4. Keep the central body footprint consistent with the unit's existing simulation radius. Wings, horns and tail may extend visually, but must not conceal the target marker, HP bars or adjacent champions. The art's overall dimensions are not collision dimensions.
5. Confirm one `AnimationPlayer` contains exactly accessible `idle`, `walk`, `attack`, `cast`, `hit`, `death` names. If the importer adds `Armature|` or library prefixes, rename/combine clips and reimport. Runtime currently finds the first `AnimationPlayer`.
6. Enable LOD import, check imported material count, and inspect skinning in all clips. Keep hit/death clips nonlooping; the runtime explicitly loops idle/walk.
7. Do not add physics colliders to the visual GLB as a substitute for the sim's hex occupancy and body radius. Combat navigation, targeting and damage stay in `BattleSim`.
8. Check the existing hit-flash overlay and Warden rim pass on every material surface. Strong emission should not wash out the warning marker or make the hit flash unreadable.

## Practical acceptance test

Use the actual supported editor and a representative player PC. Target **60 FPS (16.7 ms/frame)** at the ordinary battle camera; measure the result rather than assuming the budget guarantees it.

- Run a Warden fight with a full six-champion player party plus that boss's live summons. Rotate and zoom the camera; watch material overdraw and geometry cost.
- At 1×, 2× and 4× playback, inspect foot plants, turns, attack impact, cast warning/release, stagger, interruption and death. Test pause/resume during a warning.
- Stun or silence mid-cast. The model must blend out while the cancelled attack does no damage or extra sound. Confirm one cue per resolved boss event.
- Walk outside a marked floor area. The visual warning and actual hit must agree. Include adjacent occupied hexes in the check.
- Watch multiple summon/death cycles for invisible leftover meshes, orphan particles or needless skeletons. Verify the scene's draw calls, texture memory and frame-time spikes after warmup.
- Compare quick-result and watched-fight outcomes for identical seeds. New models and effects must not consume gameplay randomness or change combat timing.
- Review silhouettes at battle zoom and without emission: each boss should still be identifiable by its body plan, crown and major prop.

If a boss is too costly, first reduce material count and alpha overdraw, then small geometry and texture size; keep its silhouette and motion. No measured FPS, playable boss model or successful Meshy generation is claimed by this concept kit.

## Reference sources (checked 9 October 2026)

- [Meshy Image to 3D](https://help.meshy.ai/en/articles/9996860-how-to-use-meshy-image-to-3d): image upload and reconstruction workflow.
- [Meshy Auto Rigging / Animation help](https://help.meshy.ai/en/articles/16231707-how-to-create-3d-animation-with-auto-rigging): web-app rig types, quadruped walking-only and Smart Rig preset limitations.
- [Meshy Animate docs](https://docs.meshy.ai/en/webapp/guides/animate): custom motion routes and FBX/GLB export.
- [Meshy Rigging API](https://docs.meshy.ai/en/api/rigging): narrower humanoid API support and forward-axis requirements.
- [Meshy Remesh cookbook](https://www.meshy.ai/developers/cookbook/recipes/simplify-3d-model/): quad face count versus exported triangles.

Project-specific timing, path and scaling details come from `arena_view.gd`, `bestiary.gd`, `gait_rates.gd` and `warden_mechanics.gd` on the `codex/boss-audio-challenge` branch. Exact Meshy presets and availability can vary with the current product; choose by motion category and inspect the result.
