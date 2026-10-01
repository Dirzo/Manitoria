# Manitoria 0.24 — Champion Atelier

Individual sculpt and material details across all 32 creatures. Kirin is the quality reference, not a shared design. See [CHAMPION-ATELIER.md](CHAMPION-ATELIER.md).

# Manitoria 0.23 — Attack Identity

Physical claw, bite, weapon, horn and slam trails; directional magical effects. See [ATTACK-IDENTITY.md](ATTACK-IDENTITY.md).

# Manitoria 0.22 — Card Particles

Artwork-matched particles for windups, casts, projectiles, impacts, healing and shields. See [CARD-PARTICLES.md](CARD-PARTICLES.md).

# Manitoria 0.21 — Skill Lab

Twelve discoveries per creature, persistent fresh-offer history, and real 3D skill previews with enemy/ally layouts. See [SKILL-LAB.md](SKILL-LAB.md).

# Manitoria 0.20 — Headliners

Choose the face of your club, read champion abilities while shopping, and introduce both teams before battle. See [HEADLINERS.md](HEADLINERS.md).

# Manitoria 0.19 — Living Interface

Colorful arena management, illustrated menu cards, five animated starter cards, and drag-and-drop equipment. See [FANTASY-UI.md](FANTASY-UI.md) for controls and art provenance.

# 0.16 World Tour

See [WORLD-TOUR.md](WORLD-TOUR.md) for tournament progression, regional arenas, the between-match outfitter and animated rare/legendary skills.

# 0.15 Arena Clarity

See [ARENA-CLARITY.md](ARENA-CLARITY.md) for the ring-free battlefield, readable shields and contact sounds.

# 0.14 Fluid Combat

See [FLUID-COMBAT.md](FLUID-COMBAT.md) for movement, anticipation, follow-through and impact reactions.

# 0.13 Living Skills

See [LIVING-SKILLS.md](LIVING-SKILLS.md) for timed casts, creature-colored spell effects and live damage feedback.

# 0.12 Hero Art

See [HERO-ART.md](HERO-ART.md) for 128 individual discovery paintings, four illustrated discovery options per hero, and save compatibility.

# 0.11 Arena Reports

See [ARENA-REPORTS.md](ARENA-REPORTS.md) for the new report graphs, ability breakdowns and painted cards.

# Manitoria 0.10 — Champions

An animated title gallery, save-free champion exhibition, live combat inspector, visual reports and independent audio levels. Read CHAMPIONS.md for play instructions and validation.

# Manitoria 0.9 — Hero Builds & Evolutions

Four-ability kits, shuffled discovery cards, Rank 2 upgrades and level-10 build branches. See PROGRESSION.md for mechanics and save compatibility.

# Audio update 0.8.2

Bright major-key strings and marching war drums replace the preparation and arena scores. See AUDIO.md.

# Audio refinement 0.8.1

Simpler melody-led score, synchronized preparation/arena transition and less crowded battle effects. See AUDIO.md.

# Manitoria — The Living Arena

**Playable native Godot edition 0.8 · Windows first · Godot 4.7.2**

Open `project.godot` in Godot 4.7.2 and press **F5**. No additional plugins or packages are required. The separate Windows download launches directly through `Manitoria.exe`; keep its `Manitoria.pck` beside it.

## New in 0.8 — Arena score and creature sounds

The original club music remains. Positioning now has a distinct 104 BPM preparation arrangement; entering combat crossfades into a 144 BPM arena score with driving strings, brass, bass and percussion. There are 32 creature-specific signature cues and sound families for all learned abilities, basic attacks, wind-ups, impacts, healing, interruption and defeat. The 110 original synthesized effect assets are mixed with screen-relative panning, priority limits, pause support and brief music ducking.

Audio controls still work with existing saves. This update changes presentation, not combat balance. See AUDIO.md for composition, runtime behavior and validation details. All 22 audio checks, 20 interface checks and 39 management checks passed. Complete score WAVs and a real in-engine transition/fight preview are available separately in Manitoria-Audio-0.8.

## New in 0.7 — Room to fight

The arena floor is 45% wider and deeper (about 2.1 times the area) while character models retain their scale. Wider starting columns and rows, larger body separation, allied movement avoidance, less crowding of a single target under natural independent orders, and more space for ranged retreats keep engagements readable. A higher, wider default camera shows the developing fight. Ground effects, projectiles, model picking and drag placement use the same coordinate mapping.

**Every starter now has a visible Tactics button on the positioning screen**, beside its portrait and current orders. Double-clicking a friendly 3D model also opens that hero's tactics. Formation drag-and-drop, reserve selection and a separate Scout rivals dialog remain available. Existing campaigns need no reset.

83 checks passed: 7 arena spacing/picking checks, 20 interface flow checks, 29 tactics/combat checks and 27 core regressions. The existing 130-bout balance sample produced 27/30, 21/30 and 29/30 Keeper practice wins, plus 14/40 left-side mirror wins. This sample checks playability; it is not a complete balance certification.

## New in 0.6 — Hero tactics and readable combat

Open **Prepare next match → Hero tactics**, or **Roster → hero profile → Battle tactics**. Choose an individual hero, use a quick preset, or set approach, target priority, teamwork, fighting distance, target persistence, opening move, area-cast patience, healing priority and ability order. Each option affects the simulator. Orders autosave per hero and remain after loading an existing campaign. Old saves default to natural orders.

Attacks and casts now show anticipation, a filling wind-up bar and recovery timed against the combat simulation. Stuns interrupt attacks and spells; silence interrupts spell preparation. Ranged attacks, volleys, spirits and meteors visibly travel and apply damage on arrival. Projectiles follow their intended moving target; already-launched attacks remain in flight if their caster falls. Lightning, beams, ground spikes, impact sparks, melee slashes, persistent fire/acid zones and actual shield bubbles distinguish actions. Pause freezes simulation-driven effects and projectiles; speed controls advance them together.

Earned upgrade cards now display the current hero's portrait, species, role and level. The level-up-only progression rule remains.

Health bars change their unique mesh width, fixing the old billboard scaling problem. Numeric HP and shields show actual combat state. Fallen heroes play their death animation, leave the battlefield visually after 3.5 seconds, and are counted in the result report. Heroes recover between bouts; this is not permanent roster deletion.

Keeper's opening rival health/attack multiplier is now 90% rather than 80%, increasing by 0.4 percentage points per fixture to the existing 96% cap. Standard stays at equal base stats and Champion at 108%. See **BALANCE.md** for measured samples and limitations. No save reset is required.

Validation: 29 tactics/combat checks, 27 core regressions, 18 UI-flow checks and 39 management checks passed (113 total). A 360-bout comparison sweep, 130-bout final practice/mirror check, and complete Keeper/Standard season smoke tests exercised the balance changes. The Windows executable and external pack were launched together outside the source project.

## New in 0.5 — Blender roster pass 01

All 32 creatures now have editable Blender source assets in the separate **Manitoria-Blender-Roster-Pass-01.zip**. The 31 older models have been converted from independently animated pieces to deformation skeletons with normalized skin weights. Kirin retains its dedicated 28-bone sculpt and receives material refinements.

This first pass adds PBR surfaces, selected organic remeshing with transferred weights, beveled equipment edges and consolidated material palettes. Five existing animation performances per creature are resampled onto the new rigs; idle and walk loop cleanly. This is a foundation for individual sculpting, not a claim that all 32 now match the original illustrations or have five newly authored animations.

The playable roster, profiles and arena use these GLBs, and all recruitment portraits are regenerated from them. The 0.4 management screens, saves, gold economy and individual arena-level-up rules remain. Existing native saves continue.

`tests/roster_assets.gd` provides 160 checks across all 32 characters: one skeleton and player, weighted geometry, material budgets, five animated clips, finite transforms and loop closure. The previous geometry regression now checks actual vertices per model, because requiring over 1,000 separate mesh objects would incorrectly reject the optimized assets.

The separate Blender bundle includes packed `.blend` files, GLBs, studio stills, original reference sheets, the processing scripts, baseline inputs and six actual Godot roster preview sheets. Detailed facial sculpting, hand retopology and bespoke movement polish remain future art work.

## New in 0.4 — The club management edition

The campaign now uses a full native management interface with the web game's six main sections. The arena opens for formation and combat; club management has its own full-screen workspace.

- **Overview:** next fixture, both starting fives, estimated team power, club agenda, recent events, season objectives and league impact leaders.
- **Matches:** the full 5v5 season calendar and separate saved reports for completed bouts. The first three proving bouts lead into fourteen league fixtures.
- **Roster:** five starter cards, reserves, one-click bench/replacement, suggested balanced lineup, formation access, sortable development table and two-hero comparison. Hero profiles include a live animated native model, actual stats, learned abilities and equipment.
- **Club:** rename your club and update crest initials, inspect seasonal progress, change difficulty/music/effects, save and return to the campaign menu. The armory stays locked until 300 gold has been earned in arena matches; founding gold does not unlock it.
- **Market:** role filters, the current starting-five composition, 3D model portraits, scouting and real gold-funded recruitment. Twelve contracts maximum; market refresh costs 25 gold after the founding five are signed.
- **Intel:** league standings, all 32 species, and season rankings for impact, damage, healing, absorbed shields and kills. Switch between totals and per-bout values. Rival fixtures are simulated, unplayed heroes are unranked, and proving bouts do not affect league rankings.

Four supported equipment pieces are available after the armory unlock: Iron Claw Caps, Leather Barding, Scale Barding and Hunter's Totem. Purchased items go into shared inventory; attach them through an owned hero's profile. Equipping replaces the same slot and returns the previous item to inventory. The listed bonuses change the actual combat stats.

The cards use newly rendered portraits of the current native GLBs, including the 0.3 Kirin. Opening a profile creates one animated 3D preview; the rest of the management interface uses inexpensive portraits.

Existing native saves are preserved. Older saves gain the new management fields and retain their most recent report. Earlier reports and season-only combat breakdowns cannot be reconstructed from old saves; those begin recording with this build. Native 0.4 continues the same application save location. Browser saves are not imported.

Abilities still come only from each fielded hero's arena level-ups, with slightly higher rare odds after wins. This update does not add out-of-arena ability purchases or preset starting teams.

The core management and arena loop is now native. The browser's academy facilities, aging, expiring contracts, cup/draft formats and wider equipment catalogue are not included in 0.4. Those systems are not represented by nonfunctional controls. The Cloudflare web build remains separate.

Verification includes 39 new management checks, the 27 existing combat/campaign regressions and 13 interface-flow checks. Full Keeper and Standard seasons are also played through with reloads after every result. The new management screens and live model profile are captured from Godot itself in `screenshots/`.

## New in 0.3 — Kirin character study

Choose **Inspect Kirin · character study** on the main menu to compare the original artwork with the live model, orbit it and play all five animations. The new Kirin is a dedicated Blender asset with a continuous skin, a 28-bone skeleton, ten skinned material surfaces and baked textures. It is used in the arena and roster as well as the study viewer.

Only the Kirin changes in this edition. The other 31 creatures retain their 0.2 models. This is an editable art study, not a finished match for the concept illustration. The separate **Kirin-Blender-Study.zip** contains the Blender source, packed textures, authoring script, original art and actual Godot animation recording. Native 0.1/0.2 saves continue; no balance or progression rules changed. Browser development is left at its prior version.

The 27 native regressions and 13 interface checks pass, alongside 12 new asset/viewer checks in `tests/kirin_asset.gd` (52 checks total). The imported skeletal actions, walk-loop endpoints, sideways death pose, skin weights and textures are checked, and the real arena and compatibility renderer were inspected.

## New in 0.2

All 32 creature models are rebuilt using the original renderings as references. Campaign play stays 5v5 throughout, including the first practice. The menu displays **Windows edition 0.2**. Existing native saves continue. Review all species in `screenshots/creatures-01.png` through `creatures-06.png`.

## Your first match

1. Found a club in one of three save slots. Recruit five heroes with your **1,200 gold**; each opening recruit costs 200.
2. Prepare the formation. Drag names between tiles, select a hero and click a tile, or drag your 3D beasts on the arena floor. Occupied tiles swap heroes. Keep tanks forward and fragile heroes behind them.
3. Fight, earn XP, then choose upgrades for heroes who level up. The next hero gets a separate choice. Reserves earn no XP.

Start on **Keeper**, the default forgiving setting. The rival's health/attack multiplier is shown before the match. Standard uses equal stats; Champion gives rivals an 8% stat advantage. There are no hidden changes based on your winning or losing streak.

## What is playable

- A complete 3D arena with textured stone, animated banners, grandstands, lighting, shadows, spell effects and an orbiting camera. Near-side architecture cuts away at low camera angles.
- All 32 beasts rebuilt against the original character-sheet art direction and imported as real, textured GLB scenes. Each has idle, walk, attack, cast and death animation clips. The roster viewer includes animation controls.
- Thirty-two signature abilities, including dives that seek the back line, chain lightning, taunts, summons, healing, shields, roots, confusion, silence, poison and rebirth.
- **Sixty-four species-specific learned abilities:** two additional actions per species, independently learned and ranked by each hero. Signatures can also evolve. These are functioning actions, not stat-only upgrade names.
- Committed attack and spell wind-ups, interruption, traveling projectiles, movement, spacing, kiting, damage-over-time effects and double/triple/quadra-kill announcements. Both sides use the same combat system.
- Three practice bouts and a fourteen-week, eight-club league. Other league fixtures are actually simulated. Impact rankings use recorded damage, healing, shielding and kills. Practice results do not grant league-table points.
- Recruitment, reserves, formation swaps, three campaign slots, automatic saves, next-season continuation and post-match reports. Save & menu preserves pending upgrade cards. An unfinished fight restarts from preparation.
- Distinct club and battle music, crossfades, individual ability sounds, independent music/effect toggles, pause and 1×/2×/4× playback.

Every arena level-up grants one choice to that hero. The first two bouts normally reach level two. Wins give 80 XP and losses/draws 65; the threshold rises with level. Rare ability-card odds are 22% after a win and 16% otherwise. A rare learned-ability card adds 10% potency. Ranks improve potency or effect duration; each learned ability reaches rank III. Choices are generated once and preserved in saves.

## Controls

| Action | Control |
|---|---|
| Orbit the arena/model | Hold right mouse and drag |
| Zoom | Mouse wheel |
| Move a hero in preparation | Left-drag a beast or drag a formation tile |
| Click alternative | Select a hero, then click a formation tile |
| Pause/resume a fight | Space or Escape |
| Battle speed | 1, 2, 4, or the buttons |
| Fullscreen | F11 |
| Save and leave a run | Save & menu |

## Editing in Godot

- `scenes/arena_environment.tscn` is a fully editable arena scene with meshes, lights, materials, a camera and spectator instances. The running game loads this scene. Keep the fighting floor clear within **x ±12.2, z ±7.5**.
- `assets/beasts/` contains the 32 GLB models. Godot's scene importer exposes their geometry, materials and AnimationPlayers. A replacement model should keep the five animation names: `idle`, `walk`, `attack`, `cast`, `death`. The models face +Z and their feet rest at y=0.
- `scripts/hero_data.gd` defines starting stats and the two learned abilities for each species.
- `scripts/battle_sim.gd` owns simulation, targeting and real ability effects. `arena_view.gd` presents the simulation in 3D.
- `scripts/campaign.gd` owns recruitment, formations, experience, league fixtures and saves.
- `scripts/management_desk.gd` builds the six management screens; `hero_preview.gd` renders live profile models; `main.gd` owns menus and arena transitions. `sound_design.gd` handles music and synthesized effects.

The environment builder remains in `arena_view.gd`. `tests/bake_arena.gd` regenerates the editable arena from that builder; only run it deliberately because it replaces the scene with the generated version. Run this baker with a real renderer, without `--headless`, so the instanced mesh buffers are preserved.

Use **Project → Export → Windows Desktop** to create your own Windows export after installing matching Godot export templates. The supplied portable build uses the official Godot 4.7.2 Windows binary with a separate packed game, so it is larger than a stripped release-template export. A Web export is not included in this edition; its renderer and delivery need a separate pass.

## Saves and scope

Native saves are stored under Godot's `user://` application-data directory, named `campaign_1.json` through `campaign_3.json`, with recovery backups. The menu keeps three independent campaigns. Do not copy the automated-test saves from a development profile into your own save directory.

This is a playable native arena/campaign foundation, not a complete feature-for-feature replacement of the browser edition. Existing native 0.1 saves continue in 0.2. Browser save files are not imported, so a browser player starts a new native campaign. A four-item armory and the core management screens are now native. The browser's academy facilities, aging, expiring contracts, cup formats and draft competitions are not yet ported. The existing Cloudflare site is unchanged by this native build.

Edition 0.2 rebuilds every species with longer anatomical profiles, new muzzles, layered coats, antlers, feathers, metalwork and reference-based palettes. The original two character sheets are included in `reference/`. The models are still stylized procedural interpretations, not exact studio-quality reproductions of those illustrations. Individual GLBs can now be replaced with professionally modeled and animated assets without rebuilding the campaign.

## Verification

The supplied Godot scripts run headlessly through `godot --headless --path . --script tests/regression.gd` and `tests/ui_flow.gd`. The first has 27 regression checks; the second exercises 13 interface transitions/actions. `tests/season.gd` plays complete Keeper and Standard seasons, reloads after every result, spends individual upgrades, and starts the next season. `tests/balance.gd` measures opening matches and identical-team symmetry. See `BALANCE.md` for results and limits.

The standalone executable was also launched from outside the source-project directory, and its rendered menu, closer battle camera, formation and upgrade screens were inspected. Screenshots are supplied in `screenshots/`. Test previews can show developed heroes to exercise additional abilities.

Godot, its bundled third-party libraries, the DM Sans and Cinzel fonts, and the Three.js asset-generation dependency are credited in `licenses/`. Music and ability effects are original synthesized audio.
