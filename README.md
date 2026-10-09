# Manitoria

**New: Dungeon mode.** A branching descent in the spirit of *The Last Flame* and *Guildrun*. Choose your path through ten themed instances, from the Blight Forest and Mana Caverns to the Magma Depths and the Void Rift. Each has its own monsters, Warden boss and cave arena. Start with your headliner and a partner, then draft more champions from picks of five at checkpoints, on the stairs and at outfitters, up to six. Read each fight's threat on the map. Chase Flawless wins, reroll offers for gold, and trade relics or champions at the Ember Altar and the Pale Ferryman. Collect relics, build run-trait synergies, climb eight Ascension ranks, and chase a high score in the endless depths. Each zone has its own song, and the title screen has its own theme. Choose **Dungeon** on the main menu, next to **New club**. See [Dungeon mode](DUNGEON-MODE.md).

**New: game-style UI.** Battles now use round medallion controls and a carved scoreboard. The team damage panels fade in from the screen edges and hide with one click. Every screen shares one material: dark lacquer, bronze rims and gold on hover.

The native Godot edition is now **0.73 — Speedrun Stat Check**. Draft normally, choose a hex formation, up to twenty ordered item purchases and champion evolution/build priorities, then simulate five or ten full cups with player and CPU match evidence. Champion-copy purchases and star bonuses have been retired. The populated 8,192-match Playtest Atlas, personal Run Atlas and regular campaigns remain available. See [Speedrun controls and benchmark rules](SPEEDRUN-STAT-CHECK-0.73.md), [Playtest Atlas instructions](PLAYTEST-ATLAS-0.72.md) and the editable [godot/](godot/README.md) project.

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

A ready-to-play Windows build of version 0.73 is in [`builds/v0.73/`](builds/v0.73/): download the folder, run `JOIN-ME.bat`, then `Manitoria.exe`.
