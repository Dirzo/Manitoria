# Mesh2Motion animation libraries (CC0)

These are the source clips for the retargeted combat sets. They come from [Mesh2Motion](https://github.com/scottpetrovic/mesh2motion-app) by Scott Petrovic, copied unchanged from its `static/animations/` folder. All Mesh2Motion models, rigs and animations are released under CC0 1.0 (public domain; see `LICENSE-CC0.MD`). They may be shipped and modified commercially, and no attribution is required, though the project is credited here.

| File | Rig | Clips used so far |
| --- | --- | --- |
| `human-base-animations.glb` | human, 66 bones | Hit_Head, Idle_Shield_Break, Idle_Sword, Melee_Hook, NinjaJump_Land, Spell_Simple_Shoot, Sprint, Sword_Regular_A, Sword_Regular_C |
| `human-addon-animations.glb` | human, 66 bones | Attack_Ground_Pound, Death_B, Dizzy, Fighting Idle, Fighting Left Jab, Victory, Walk_Large |
| `human-mocap-animations.glb` | human, 66 bones | (not used yet) |
| `fox-animations.glb` | fox (quadruped), 49 bones | Bite, Death, Howl, Idle, Idle Alert, Jump, Run, Walk |
| `horse-animations.glb` | horse, 56 bones | Head_But |
| `kaiju-animations.glb` | kaiju (biped with tail), 58 bones | Hit |
| `snake-animations.glb` | snake, 28 bones | (not used yet) |
| `spider-animations.glb` | spider, 56 bones | (not used yet) |
| `dragon-animations.glb` | dragon, 100 bones | (not used yet) |

How they become game clips: `godot/tools/retarget_creature.gd` reads `godot/data/retarget_jobs.json`, retargets each listed clip onto the creature's own rig (`godot/tools/retargeter.gd`), and writes `godot/assets/beasts/clips/<creature>.res`. The creature's `.glb` is never modified. These files live outside `godot/`, so Godot doesn't import them.
