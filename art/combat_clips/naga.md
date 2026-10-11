# Naga: pilot brief (serpent)

Support · basic attack: water bolt (a projectile; released from the hands) · signature **Tidal Ward** (a protective ward on allies).

**Rig route:** This is the hardest one. Meshy's humanoid and quadruped rigs won't drive a serpent tail. Use a custom rig: humanoid upper body and one spline or chain tail. Plan to key the upper-body clips by hand (or in Cascadeur). Keep tail motion simple: the game can add a procedural slither later, so the tail only needs a gentle S-curve in `walk` and `run`.

There are no feet, so foot-slip checks don't apply. Watch that the tail stays on the ground plane.

| Clip | Motion |
| --- | --- |
| `idle` | Upper body sways, hands drift, tail tip curls. |
| `idle_combat` | Coiled lower, hands raised with water gathering, tail tensed. |
| `walk` (slither) | S-curve wave travelling down the tail, upper body steady. |
| `run` (slither) | Faster, deeper S-curve with the body leaning forward. |
| `attack_1` | Two-handed push: draw the hands back (hold), thrust forward. Release is arms at full extension. |
| `attack_2` | One-handed whip throw from the side. |
| `attack_heavy` | Tail sweep: coil, then whip the tail around low. For physical skills. |
| `cast` | Tidal Ward: rise tall on the tail, arms sweep up and outward (hold the raised pose), release. |
| `hit_light` | Upper body recoils, tail steady. |
| `hit_heavy` | Pushed back along the tail, then rights itself. |
| `stun` | Slumped forward, swaying, hands limp. |
| `death` | Collapses down the tail and curls. Holds. |
| `spawn` | Rises up out of a coil. |
| `victory` | Spins in place with arms raised and a water flourish. Loops. |
