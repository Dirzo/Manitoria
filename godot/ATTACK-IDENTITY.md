# Manitoria 0.23 — Attack Identity

Physical beasts now strike with anatomical contact trails: three claw cuts, closing jaws, paired horn thrusts, broad weapon sweeps and heavy downward slams. Basic melee attacks use the creature's attack family. Physical skills use the attack animation for anticipation and recovery, then draw trails on their actual victims. Multi-target hits draw separate contacts; shield absorption and health damage do not duplicate the same slash, and later bleed ticks do not create new bites.

Magical learned abilities remain magical regardless of the caster. Card colors are preserved with different motion: forward breath cones, narrow directed jets, ground eruptions, falling storm strikes and rising healing/support motes. The universal cast explosion, melee magic windup, extra radial impact sparks and circular spell fallback have been removed. Frost/root fields use scattered ground positions and fissures use a line. This is a visual and animation presentation change, not a damage-type rebalance.

Trails draw progressively and fade using the same paused/speed-controlled effect clock. Skill Lab visual timing now clamps slow frames consistently with its simulation. This release reuses the current rigged character models; it does not replace their meshes or add new skeletal animation clips.

Tests cover five physical families, genuinely magical learned skills, forward-only breath particles, ground and falling effects, actual multi-bite victims, cleanup, all card profiles, pause, particle budgets and ring-free battle clarity. Windows native visual checks cover claw, bite, weapon, slam, thrust and breath.

Extract the whole Windows ZIP into a new folder, keep Manitoria.exe beside Manitoria.pck, and launch. The title screen identifies Windows edition 0.23. Existing saves and the 128 individual ability paintings are preserved.
