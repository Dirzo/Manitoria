# Manitoria 0.12 — Hero Art

This update gives every hero four individually painted discovery artworks: 32 heroes × 4 = 128 PNGs. Each image depicts the creature performing the named skill. Level-up cards give the painting more space than the description; the same skill art appears in learned-skill profiles, the battle inspector and post-match ability breakdowns.

New campaigns draw discovery offers from four abilities per hero. A developed hero still equips its signature and three learned skills, then ranks those skills up. Rank 2 keeps the same painting. Existing saved skills outside this discovery pool continue working, can still be ranked, and retain their previous mechanic artwork. Existing signatures, evolution branches and mastery art remain available.

## Assets and provenance

- Individual paintings: `assets/abilities/{species}-{index}.png`, indices 0–3.
- Exact prompts, skill names and original generated-file provenance: `data/art-generation-manifest.json`.
- Full ability catalog, including legacy skills: `data/discovery-art.json`.
- Art was generated individually with the built-in image-generation tool. No API/CLI generation was used.
- Original PNGs are preserved. Godot uses mipmaps and linear filtering to keep small icons smooth.

## Play

Open `project.godot` in Godot 4.7.2 and press F5, or extract the Windows release and open `Manitoria.exe` with its matching `Manitoria.pck` beside it. The title screen identifies Windows edition 0.12. Continue a saved campaign or found a club, recruit five heroes, set formation and tactics, and fight to earn individual level-up choices.

The combat rules, models, music and detailed arena reports carry forward from the previous release. This update changes discovery selection and artwork; it does not replace the 3D models.

## Validation

All 128 PNGs are distinct square images at least 1024 pixels wide, and every hero has exactly four catalog-matched images with recorded prompts. Godot verifies all 128 imported textures, card/report mappings, the new discovery pool and legacy skill fallbacks. Progression, management, campaign UI flow, champion interface and combat analytics tests pass. Level-up cards, a developed hero profile and the live battle inspector were rendered and visually checked.
