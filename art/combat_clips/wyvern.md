# Wyvern: pilot brief (winged quadruped)

Ranged · basic attack: acid spit (a projectile; the game launches it on the release frame) · signature **Acid Pool** · moves on the ground on hind legs and wing-knuckles, so it is not a flyer.

**Rig route:** Meshy quadruped rig if it accepts the wing-forelimbs. Otherwise use a custom rig with two wing chains. Wing folding and flaring carries most of the readability. Key the wing membranes' outer bones so they trail the arms.

| Clip | Motion |
| --- | --- |
| `idle` | Wings half-folded, slow breathing, tail curling, head tilts. |
| `idle_combat` | Wings flared wide, neck coiled back, tail raised. |
| `walk` | Knuckle-walk on folded wings and hind legs, head low. |
| `run` | Faster knuckle-gallop with a wing beat every other stride. |
| `attack_1` | Spit: the neck coils back (hold), then snaps forward. Release is at full neck extension. |
| `attack_2` | Side spit: head swings from the left and spits on the follow-through. |
| `attack_heavy` | Tail lash: turn and whip the stinger over the shoulder. Contact is the stinger at full reach. For physical skills. |
| `cast` | Acid Pool: rear up with wings fully spread, inhale (hold), then spray down in an arc. Release starts the spray. |
| `hit_light` | Wings flinch in, head jerks away. |
| `hit_heavy` | Knocked back with a big defensive wing flap, landing heavily. |
| `stun` | Wings drooped on the ground, head swaying. |
| `death` | Wings crumple, then it rolls onto its side with one wing over the body. Holds. |
| `spawn` | Glides in with two wing beats and lands on all fours. |
| `victory` | Rears up, roars and spreads the wings. Loops with slow beats. |
