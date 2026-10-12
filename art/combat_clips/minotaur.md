# Minotaur: pilot brief (biped)

Bruiser · slow, heavy hitter · melee, attack speed 0.9 · basic attack: overhead axe sweep · signature **Gore Charge** (horns-down charge).

**Rig route:** Meshy humanoid rig. This is the creature most likely to get every clip from the preset library. Look for two-handed or heavy weapon sets. Check that the horns and tail are weighted to the head and hips, and that the axe follows the right hand.

| Clip | Motion |
| --- | --- |
| `idle` | Heavy breathing, shoulders rise and fall, axe resting low. |
| `idle_combat` | Crouched, axe raised across the body, weight shifting foot to foot. |
| `walk` | Slow, weighty stride. Each footfall lands hard and the upper body dips. |
| `run` | Head-down lumbering charge, axe trailing. |
| `attack_1` | Overhead chop: big wind-up behind the head, chop down, hold at contact, recover. |
| `attack_2` | Horizontal sweep from the right. A different silhouette from `attack_1`. |
| `attack_heavy` | Gore Charge: drop the head, paw the ground (hold), drive the horns forward. Contact is horns at full extension. |
| `cast` | War stomp: rear up and slam a hoof. For any magical skills it learns. |
| `hit_light` | Head snaps back, small step, feet planted. |
| `hit_heavy` | Staggers back a full step, axe dips, recovers to guard. |
| `stun` | Dazed: head lolling, axe hanging, slow sway. |
| `death` | Drops to the knees, then falls forward onto the axe. Holds. |
| `spawn` | Lands from a jump with a two-footed stomp and a dust-ready pose. |
| `victory` | Roars with the axe raised overhead and beats its chest. Loops. |

Heavy body: use the slower 50 : 10 : 40 timing ratio on attacks.
