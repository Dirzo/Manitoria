# Direwolf: pilot brief (quadruped)

Skirmisher · fast and light · melee, attack speed 1.35 (the fastest swing in the pilot) · basic attack: bite · signature **Pack Howl** (buff howl).

**Rig route:** Meshy quadruped rig. Use whatever presets fit (walk, run and idle are likely), and expect to key the attacks, hit reacts, stun and victory by hand. Weight the tail, ears and jaw separately; the jaw must open.

At 1.35 attacks a second, swings chain almost back to back. Keep `attack_1` and `attack_2` short (about 0.6 s) and make each end close to where the other begins.

| Clip | Motion |
| --- | --- |
| `idle` | Panting, ears flicking, tail low sway. |
| `idle_combat` | Low stalking crouch, hackles up, lip curled, small weight shifts. |
| `walk` | Trotting gait with diagonal legs in sync. Keep feet planted. |
| `run` | Full gallop with spine flex. |
| `attack_1` | Lunging bite to the front-left: coil, snap, jaw closes at contact, hop back. |
| `attack_2` | Low bite and head-shake to the right: grab, rip sideways, release. |
| `attack_heavy` | Pounce: crouch and hold, leap, forepaws strike, bite at landing (contact). |
| `cast` | Pack Howl: plant the paws, raise the head and howl. The release is the moment the howl begins. |
| `hit_light` | Flinch and yelp, head ducks, feet planted. |
| `hit_heavy` | Knocked sideways a step, stumbles, recovers to crouch. |
| `stun` | Dizzy: head low, unsteady legs, slow head shake. |
| `death` | Collapses onto its side and holds. |
| `spawn` | Bounds in and skids to a stop in a crouch. |
| `victory` | Sits up and howls, tail wagging. Loops. |
