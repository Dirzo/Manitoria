# Combat clip set: Meshy pilot (step 2 of fluid combat)

Pilot creatures: **minotaur** (biped), **direwolf** (quadruped), **wyvern** (winged quadruped), **naga** (serpent). One per body family. The pilot answers two questions before the other 28 creatures are scheduled:

1. Which of the 14 clips can Meshy's preset library supply for each rig type, and which need custom keying?
2. How many hours does one creature take, start to finish?

Record both in the table at the bottom as you go.

Briefs: [minotaur](minotaur.md) · [direwolf](direwolf.md) · [wyvern](wyvern.md) · [naga](naga.md)

## The 14 clips

The game looks clips up by these exact names. Every name except the original five is optional, and the game falls back cleanly when one is missing, so you can import a creature halfway through and keep playing.

| Clip | Loop | Length | Used for | Fallback today |
| --- | --- | --- | --- | --- |
| `idle` | yes | 2–4 s | shop, bench, pre-fight | required |
| `idle_combat` | yes | 1–1.5 s | standing in range between swings | `idle`, sped up |
| `walk` | yes | 0.6–0.9 s | moving | required |
| `run` | yes | 0.4–0.6 s | closing distance fast, dives | `walk`, sped up |
| `attack_1` | no | 0.6–0.9 s | basic attack, odd swings | `attack` |
| `attack_2` | no | 0.6–0.9 s | basic attack, even swings: a different swing, not a copy | `attack_1` |
| `attack_heavy` | no | 0.9–1.3 s | physical signatures and skills (charges, slams, bites) | `attack_1` |
| `cast` | no | 1.0–1.6 s | magical signatures and skills | required |
| `hit_light` | no | 0.2–0.35 s | small hits; feet stay planted | spine flinch only |
| `hit_heavy` | no | 0.5–0.7 s | big hits; stagger a step back | spine flinch only |
| `stun` | yes | 1–1.5 s | stunned: dazed sway, head low | `idle`, slowed |
| `death` | no | 0.8–1.2 s | falls and holds the last pose | required |
| `spawn` | no | 0.5–0.8 s | leaps or lands onto the board as the fight starts | none |
| `victory` | yes | 2–3 s | winners celebrate while results are tallied | `idle` |

`attack` (the old single attack) still works as a name and is treated as `attack_1`.

## Timing rules for every attack and cast

You don't set damage timing in Meshy. `tools/anim_contact_probe.gd` measures each clip, and the game lines the clip's contact frame up with the simulation's hit. The clip still has to read clearly:

- **Anticipation, then contact, then recovery**, at roughly 35 : 10 : 55 of the clip (heavy bodies 50 : 10 : 40). The probe finds contact where the fast strike motion stops, so end the strike crisply. A slow drift into contact measures late.
- **Hold the contact pose for 2–3 frames.** It sells the impact, and hit-stop freezes it.
- **Hold a still beat at the end of the anticipation** for `attack_heavy` and `cast`. Long windups pause there, then snap.
- **Ranged attackers:** contact is the release frame, when the spit or bolt leaves the mouth or hands.
- **Overlap:** tails, ears, wings and heads trail the body by 2–4 frames. The current clips animate only a third to two-thirds of the bones, which is why they look stiff.

## Export contract

1. Animate on **one rig**. Every clip for a creature must come from the same rigged model, so all of them share a skeleton.
2. Export each clip as **GLB or FBX**, **in place** (no root motion; the game moves the creature), 30 fps.
3. Name the files `<creature>__<clip>.glb`, with a double underscore. For example: `direwolf__attack_1.glb`, `direwolf__hit_heavy.fbx`. Meshy's download names are random, so rename them. If one file holds several clips, name it `<creature>__set.glb`; clips inside it that already have the exact names above are used.
4. Also export the rigged model once in its rest pose as `<creature>__model.glb`. Any clip file works as the model if this is missing.
5. Put all of a creature's files in one folder, for example `Downloads/Manitoria_Meshy/clips/direwolf/`.

Then build it into the game:

```
godot --headless --path godot -s tools/build_creature.gd -- --in "C:/Users/<you>/Downloads/Manitoria_Meshy/clips/direwolf" --species direwolf
godot --headless --path godot --import
godot --headless --path godot -s tools/anim_contact_probe.gd
godot --headless --path godot -s tools/anim_audit.gd
```

`build_creature.gd` merges the clips onto one model and renames them. It scales the creature to the game's standard 1.7-unit height, sits it on the ground facing +Z, strips any root motion, and writes `godot/assets/beasts/<creature>.glb`. The model it replaces is first copied into your clips folder as `<creature>.previous.glb`. `anim_audit.gd` then reports which clips are present, how much of the rig each clip moves, loop seams, root drift and whether contact was found.

Where the current clips stand (`anim_audit`, share of the rig each clip moves): the minotaur's attack moves 7%, its cast 6%. The direwolf's and wyvern's attacks move 45–46%, and the naga's attack 8%. The target for new attack, cast and hit clips is 80% or more.

## Acceptance check per creature

- `anim_audit` shows all 14 clips. Each attack, cast and hit clip moves at least 80% of the bones, and every loop seam is under 2°.
- `fluid_combat_test` and `combat_clipset_test` still pass.
- In game at 1×, 2× and 4×: feet don't slide on walk or run, `attack_1` and `attack_2` read as different swings, nothing pops between swings, death holds its last pose, and the victory loop is seamless.

## Pilot log

| Creature | Rig route | Clips from presets | Clips keyed by hand | Hours | Notes |
| --- | --- | --- | --- | --- | --- |
| minotaur | | | | | |
| direwolf | | | | | |
| wyvern | | | | | |
| naga | | | | | |
