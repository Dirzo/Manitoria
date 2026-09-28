# Manitoria — The Beasts, build 3.5

A browser club autobattler with original stylized 3D beasts, a short introduction, and an earned progression campaign.

## Play

Run `node server.mjs` in this folder and open http://127.0.0.1:4177/. Node 18+ is sufficient; the Three.js renderer is bundled locally. No package installation is needed. The top bar reads **The Beasts · 3.5**. The hosted Workers website has not been updated.

The game opens at a main menu. Continue your latest campaign, choose a saved campaign, start from a named checkpoint, or start a fresh team. Your previous single-save campaign is added to this library automatically.

**Run menu** offers Save campaign now, Save checkpoint, and Save & quit to main menu. Every fresh team has its own autosave. Loading a named checkpoint creates a separate playable copy and keeps the checkpoint unchanged. An unfinished fight saves at its preparation screen and restarts when you return; completed results and pending upgrade cards resume exactly. The cards also offer Save & quit.

Saves live in this browser. Local and hosted addresses have separate saves. Use **Club office → Save a backup or load another club** to export a code; imports create separate campaigns. Keep an exported backup before clearing browser storage.

## Start a new club

1. Choose a name and crest. Begin with an empty roster and **1,200 gold**. Recruit five starters from twelve level-one candidates, including frontline, flank, and backline options. Every opening market includes a tank and a support. All heroes begin with their species' signature and no assigned upgrades. The opening prices guarantee any five are affordable.
2. Use the Overview to see your next opponent, club agenda, and real league impact leaders. The optional Quick start has three prompts: recruit five, arrange formation, enter the arena.
3. Play four preseason bouts: 1v1, 3v3, 3v3, 5v5. Earn 50, 60, 75, and 90 gold, win or lose. Fighting heroes gain experience; only heroes who level up earn upgrade cards. Preseason does not injure or tire your beasts.
4. Enter the league, improve the roster, rotate tired beasts, and compete in cups. Equipment opens after 300 cumulative arena gold. Starting funds and sales do not count.

Older clubs keep their learned powers, equipment, gold, and season and skip preseason. Unspent legacy choices are held back for future arena level-ups; an already-paid result keeps a single pending choice for each eligible hero. Existing equipment retains Armory access. Purchases go into the stash; equip them on a selected beast once the Armory is open.

## 3D beasts

All 32 species use original articulated meshes rendered with WebGL/Three.js. The old illustrated and pixel portraits are no longer used. Build 3.5 adds original seamless color, normal, and roughness maps for fur, scales, bark, stone, feathers, hide, chitin, silk, bone, and metal. Instanced fur, overlapping scales, carved details, feather vanes, and mineral accents add silhouette detail. Warm key lighting, a cool rim, environment reflections, and contact shadows bring out those surfaces.

Each profile has a 640-pixel 3D viewer with a close-up toggle: drag to rotate or use the arrow buttons; preview Idle, Walk, Strike, and Cast. Formation dragging remains independent of model rotation. Knees and wrists articulate; tails move through four joints; wing tips and feathers follow the wing root. Breathing, blinks, jaw movement, attack anticipation, quadruped lunges, and eased walking/casting transitions give the beasts more life. Arena animation targets 60 updates per simulation second; actual display performance depends on the browser and hardware.

One WebGL renderer draws the team into an atlas, then copies it once for the arena. Rigid pieces are combined within each joint and repeated surface details are instanced. Preview and arena animation states are independent, including duplicate species. Model construction and posing do not consume gameplay randomness.

These are stylized procedural models, not high-detail studio sculpts. The existing arena composition contains live 3D-rendered beasts; its floor is still drawn on a 2D canvas. Hardware acceleration/WebGL is required. A clear 3D placeholder appears when unavailable instead of silently restoring old portraits. Reduced motion disables model animation.

## Controls and development

Drag a hero from the bench onto an empty formation tile to field it. Drop onto a fielded hero to replace it, or drag between occupied tiles to swap positions. Click controls provide the same actions: Field hero, Bench, and Swap in. The match format and selected count are explicit: league matches have five places; cups retain their own two-, three-, or five-hero format. All three formation columns fit narrow windows, and overlapping saved positions are repaired.

Heroes develop independently. Only an arena level-up earns a choice; heroes who remain at the same level and benched heroes receive none. Active abilities replace the normal power choice at levels 3, 7, 11, 15, 19, and 23 when a legal ability remains. Awakening levels offer a trait. Each eligible hero gets one decision, presented separately. Roster-wide auto-upgrading, upfront spending, and bulk retraining are removed. Match reports show each fighting hero's experience progress.

Power cards use potential-based rarity weights. A win moves five percentage points of draw weight from Common to Rare (+3), Epic (+1.5), and Legendary (+0.5), before filtering tiers unavailable in a given card pool. Wins improve the odds without guaranteeing a high-rarity card. Choices remain distinct, the first favors the hero's role, and every sixth power choice offers an Epic or better when available. The victory bonus belongs to that earned offer and survives saves and rerolls.

Cards open above the match report. Choose an upgrade, review the report, then return to the club overview. Prepare the next match when ready. Offers and unspent choices survive reloads. Review match temporarily dismisses the cards; the result button reopens pending choices. A repeated click cannot spend a second choice.

Arena beasts smoothly turn toward their target while attacking and along their movement while chasing or retreating. The raised camera shows their volume and direction. Space pauses battle, 1/2/4 change speed, M toggles music, and Escape closes dialogs. Sound, volume, motion, and effects are in Club office.

Nine active techniques complement three-card passive powers. Each hero can learn two techniques and raise each to rank III through earned arena level-ups. The Skills page shows learned powers and allows ability timing changes; it does not sell or bulk-spend upgrades. Club facilities, tactics, potential, bonds, aging, retirement, league promotion, cups and drafting remain available. Previously learned specializations are preserved.

## The roster desk

The Roster page shows the first team above the reserves, with separate saved teams for 1v1, 2v2, 3v3, and league 5v5. Field, Bench, and Swap in update those saved teams immediately. When full, choose Swap in and then click the starter to replace. Injured heroes cannot be newly fielded from this page. Match preparation remains the place to drag their positions; short saved lineups are filled when preparing the actual fixture.

The compact register switches between Development and Combat stats. Sort by hero, level, rating, impact per bout, energy, and combat attributes; filter by role. Set growth focus inline, inspect signature and learned abilities, open tactics, or compare two heroes side by side. Energy, fatigue, injury status, XP, and potential are visible. Setting growth focus grants no immediate XP or skill choices.

Intel ranks actual season contribution across the current division, including preseason and cup appearances. Unplayed heroes remain unranked. Switch between totals and per-bout averages and inspect damage, healing, control, kills, and assists. No fabricated impact scores are seeded into fresh campaigns.

## Readable autobattles and sound

The rectangular arena gives heroes more room. Melee attacks wind up before landing, cancel if interrupted, and use steady targets and approach positions. Ranged heroes launch visible projectiles, hold firing distance, and kite melee threats when instructed. Channels, taunts, silence, roots, summons, and earned techniques retain their combat effects. Both watched and quick-result fights advance at 60 simulation steps per second.

Select a hero on the field or in the live status bar to see health, target, signature cooldown, impact, and K/D/A. Playback supports 0.5×, 0.75×, 1×, 2×, and 4×. Sound settings pause the fight while open and restore its previous pause state when closed.

Two final hero eliminations by the same hero within six seconds announce a Double Kill. Further eliminations build Triple Kill, Quadra Kill, and Team Sweep callouts. Summoned victims and revivals do not count; summoned attackers credit their owner. Each hero's best chain is kept in the saved match report.

All 32 signatures and nine learned techniques have distinct original synthesized sounds, emitted only on successful casts. Effects pan across the arena and have independent volume and mute controls. Quiet damage-over-time ticks reduce clutter. Sound settings include previews. Landing uses a separate harp-and-choir theme; the club, preparation, arena, victory, and defeat each have their own music, with crossfades. Browser interaction is needed before audio starts. This is original synthesized music, not a recorded orchestral soundtrack.

## Verification

Run `npm test`, or run `node tests.mjs`, `node campaign-tests.mjs`, `node desk-tests.mjs`, `node arena-tests.mjs`, and `node model-tests.mjs` individually. Together they contain 108 checks: 33 engine/legacy checks, 20 campaign checks, 16 recruitment/overview checks, 27 combat/audio/roster checks, and 12 model/material/animation checks. The latter suites load the complete current game stack and cover all 32 species, attack interruptions, projectiles, kill attribution, saved highlights, all 41 audio envelopes, music routing, roster swaps, and save compatibility. Model checks cover all 32 species in idle, walk, cast, strike, and death states; UV seams; texture reuse; full-view bounds at eight angles; reduced motion; and isolation from combat randomness. Browser checks include the larger viewer, animation controls, close-up toggle, and a watched 5v5 fight, plus earlier checks of recruitment, a watched 3v3 bout, paused sound previews, the updated roster, and narrow layouts. This is functional validation, not a complete balance study.

## Build

Run `node build.mjs` to create the static `dist/` files. Three.js 0.160.1 is vendored from the official npm package; its MIT license is in `assets/vendor/THREE-LICENSE.txt`.

The Workers site has not been deployed. The existing `wrangler.jsonc` remains prepared for the `manitoria` Worker. Review its existing routes and bindings in the authenticated deployment project before publishing.

See `REFERENCE-NOTES.md` for the complete-video study, implemented decisions, and features that remain outside this pass.
