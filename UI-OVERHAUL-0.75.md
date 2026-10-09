# Manitoria 0.75 — Visual overhaul, part 1: menus and feel

Dungeon mode is now the headline feature, the dungeon is immersive (no tournament menus), and every menu outside of combat shares one cleaner look and feel inspired by *Baldur's Gate 3* and *Guildrun*.

## Title screen

- **Dungeon first.** One large painted banner: *Into the Dungeon*, a line about the mode, fact chips (10 zones, 10 Wardens, 26 relics, endless depths, your best score) and a single gilded **Enter the dungeon ▶**. The zone's Warden glows on the right.
- **Continue descent.** If an unfinished dungeon run is saved, the banner becomes *Continue descent ▶* with that run's zone, room, lives and points, plus **New descent**.
- **Everything else is a quiet text row** under the banner: Continue guild (when your latest save is a guild run), Guild tour, Exhibition, Speedrun stat check, Saved runs, High scores.
- Atlas and Run plan moved off the floating buttons into the round header medallions.

## Inside the dungeon

- **No management tabs and no dock.** The map fills the screen (synergy column shows up to ten traits).
- The top band's tools are medallions: **Squad** (formation, items, tactics, XP), **Journal**, **Traits**, **High scores**, **Guide**. Squad and Journal open as side pages with a single **back to the map** medallion.
- The Next card handles everything the dock used to: *Level ups ▶* and *Outfitter ▶* appear there when they're waiting.
- The colosseum painting is gone from dungeon screens: the zone's own painting sits deep in shadow behind the UI.

## Guild run menus

- The management tabs are clean text tabs: small-caps serif, muted until hovered, gold with a gilded rule when active. No boxes.
- Cool blue and purple panels (roster cards and others) now use the same bronze-and-umber palette as the dungeon.

## Feel (everywhere)

- **Buttons respond:** a small lift on hover with a soft wooden tick, a squash and click on press, a spring back on release, and a hand cursor.
- **Buttons are easier to read:** labels use the book serif in a firm weight with a little tracking. The uncial display face is kept for titles and the big calls to action.
- **Floating text boxes:** every tooltip in the game now appears as a framed card that eases in beside the cursor, stays on screen and above dialogs. The first short line is a gold title; numbers and percentages are gilded; status words (stun, root, silence, slow, shield, heal, lifesteal…) take their colour.
- **Dialogs float in:** the backdrop fades, the card rises and settles, with soft open and close sounds.
- New sounds: `ui_hover`, `ui_click`, `ui_open`, `ui_close` (synthesised; in `assets/audio/fx`).

## Dungeon creatures

- Every zone now has **five mobs and a Warden**. The ten new mobs (Blightmaw Toad, Geode Mimic, Cinder Wyrmling, Icebound Revenant, Drowned Priest, Puffcap Bomber, Ossuary Priest, Tempest Elemental, Gilded Asp, Rift Horror) use recoloured stand-in models for now.
- [DUNGEON-ART-BRIEF.md](DUNGEON-ART-BRIEF.md) and `godot/data/dungeon-art-manifest.json` hold 70 ready-to-run image prompts: 50 mobs, 10 Wardens and 10 zone backdrops, plus the Meshy image-to-3D, rigging and export steps.
- The game already picks the art up: `assets/models/dungeon/<monster>.glb` replaces a monster's stand-in model, and `assets/ui/dungeon/<zone>.jpg` replaces the zone's borrowed painting.

## Research note

I read about both games' interfaces, but I could only see text sources, not screenshots. The articles describe content more than visuals. The design choices above therefore come from general knowledge of those games' menus, not a frame-by-frame comparison:

- *Baldur's Gate 3:* dark translucent panels with thin gold rims, readable serif type, rich layered tooltips.
- *Guildrun:* bold, uncluttered run screens built around a single next action.

## Validation

- **New test:** `tools/ui_feel_test.gd` (8 checks). Hovered buttons lift and settle, a floating text box appears with a gold title and hides when the cursor leaves, and the dungeon is featured on the title screen.
- **Regressions:** the existing test suite passes, including the five-mob dungeon smoke test (2,018 checks) and the full five-cup guild run (303 checks).
- **Known failure:** `speedrun_ui_test` fails one check without a previously saved benchmark in the same user-data folder.
- **Screens inspected:**
  - title screen;
  - dungeon map;
  - dungeon squad page;
  - waystone draft;
  - guild roster;
  - shop.
