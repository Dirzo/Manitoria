# 0.13 Living Skills

All 128 discovery skills use their existing combat mechanics with differentiated, interruptible windups (0.40–1.05 seconds). The creature cast animation and overhead countdown follow the same simulation clock as release. Quick ambushes release sooner than earthquakes, beams and meteors.

Persistent ground warnings track the pending target. Line spells preview their forward lane. Warnings disappear when the caster is interrupted or falls. Pause and battle speed apply to warnings, projectiles, spell effects and floating numbers.

Creature palettes carry into spells and projectiles. Cyclones spiral, fire and toxin bursts expand, ground effects rise, and existing lightning, projectiles and wards continue to follow combat events. These are shared effect families with hero colors, not 128 separately rigged animation clips.

All effective damage and healing emit combat feedback, including small hits. Rapid ticks on the same target combine for 0.48 seconds. Blue blocked numbers distinguish shield absorption from health damage. Amounts below 10 display one decimal; larger amounts round to whole numbers. The live hero inspector shows per-skill damage, healing, cooldowns and active cast time; exact underlying values remain in the report.

Refreshing damage-over-time now attributes subsequent ticks to the skill that refreshed it. Delayed hits retain their original skill identity even after the hero starts a different action.

Play: extract the Windows ZIP into a new folder, keep Manitoria.exe and Manitoria.pck together, then choose Watch champion exhibition or continue your campaign. Existing saves and skill artwork remain compatible.

Validation: all 128 discovery skills resolve once after their windup; interrupted casts, delayed attribution, shielding, pause, number aggregation and cleanup tested. Existing tactics/combat, progression, analytics and champion UI tests pass. Native visual smoke test uses the built game.
