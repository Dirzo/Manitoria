# Manitoria

The native Godot edition is now **0.72**, with a populated, queryable 8,192-match Playtest Atlas plus a persistent in-game Run Atlas, player and CPU match evidence, draft statistics, a post-draft decision matrix and an opt-in Ascension ladder. It retains 0.70's measured balance pass, hex combat, stars, skills, artwork and item feedback/audio. Its editable project is in [`godot/`](godot/README.md). See [Playtest Atlas instructions](PLAYTEST-ATLAS-0.72.md) and [personal Run Atlas instructions](RUN-ATLAS-0.71.md).

Explore [`Manitoria Atlas`](analytics/index.html) for all 32 champion pages, the 136-item screen and patch comparisons from 8,192 simulated matches. See the [0.70 balance notes](BALANCE-ATLAS-0.70.md) for changes, validation and sample limitations. Pages hosting setup is documented in [`analytics/README.md`](analytics/README.md).

## Original browser edition

A pixel-art arena manager where you run a club of mythical beasts. Build a roster, set how each beast fights, and climb from the Mud Pits to the Mythic Arena while every beast writes its own history.

The whole game is a single file, `index.html`. Open it in a browser to play. There is no build step and nothing to install.

## Features

- **32 species across 14 roles**, each drawn as an animated pixel sprite with its own ability, Signature upgrade, and strengths and weaknesses.
- **Auto-battles on a large arena** with MOBA-style movement: ranged beasts kite and orb-walk, melee fighters surround their targets, and front-liners peel for their backline.
- **Per-beast tactics**: target priority, starting position, stance (advance, hold ground, bodyguard an ally, focus with an ally), ability timing, keeping distance and when to fall back.
- **Skill picks after every fight**: beasts that level up deal you three skill cards in four tiers (Common, Rare, Epic, Legendary), with rerolls.
- **Seasons**: 14 league matchdays, a 2v2 cup, a 3v3 cup and a draft cup, with promotion and relegation across four divisions.
- **Club management**: energy, fatigue and injuries, an item shop with gear and supplies, a beast market, upkeep and an itemized purse.
- **Legacy**: bonds between partners, awards, milestones, club records, a trophy cabinet and a hall of legends.
- **Synthesized soundtrack** generated live with Web Audio: an anticipation prelude, battle music, and victory or honor music after each bout.
- **Balance** tuned by simulation so every species wins roughly half its bouts in an average 5v5 lineup.

## Saving

Progress saves automatically in your browser's local storage. The Club office menu gives you a save code to back up or move a club between devices.

## Godot edition

The full Godot 4 project lives in [`godot/`](godot/). Open `godot/project.godot` with **Godot 4.7.2** (Compatibility renderer) to play from the editor or export your own build.

A ready-to-play Windows build of version 0.59 is in [`builds/v0.59/`](builds/v0.59/): download the folder, run `JOIN-ME.bat`, then `Manitoria.exe`.
