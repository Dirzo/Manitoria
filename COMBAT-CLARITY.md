# Combat reach, equipment preparation and music-only audio

Native source changes for the next export. The checked-in Windows executable remains 0.75.4.

Champions show `ATK N HEX` above their body and their equipment/formation card shows the same attack reach. Selecting a champion in formation or through a battle portrait outlines its reachable floor hexes in cyan. The footprint is hidden during a move, when the unit cannot attack, and updates after arrival. Tactical view retains the range badge. Champion stat panels now report hex reach rather than ambiguous world units. Skills keep separate ranges, shown in their battle tooltips.

`ArenaGrid.attack_hexes()` remains the conversion from authored reach to grid reach. `CombatRange.contains()` is shared by basic attacks and offensive skills: a moving attacker cannot start a hit, and a moving target's departure and arrival hexes must both remain in reach. Basic attacks recheck at release and the direct attack entry point rejects invalid reach. Projectiles already fired retain normal travel; a subsequent retreat does not erase an in-flight shot. Navigation continues to find an open firing hex with no teleporting between ordinary steps.

Every normal dungeon/tournament match entry now stops at formation and equipment. The battle countdown starts only after the player presses Fight on that screen. Every starter has live item slots; Bag & forge and Team equipment are available before starting. Noncombat dungeon events include an equipment action before resolving their choices. Dungeon component rewards visibly list partner + component → result recipes in scrollable cards, and item tooltips use the same recipe formatter. Existing drag/drop crafting and inventory rules remain authoritative.

All nonmusic audio is temporarily disabled: combat, boss, UI, gold, death, ambience, sweeteners and announcer playback. Effects/Voice buses are muted, playback guards reject samples, legacy save settings cannot enable effects, and music volume/crossfades remain available. Effects files are retained for future redesign; no new sound competes with music.

## Validation

Godot 4.5.1 headless import/parse completed. Real source models and portraits were materialized for the UI checks. This environment has no graphical display; rendered visual review and target-PC performance remain to be checked in the editor.

- `range_prep_test.gd`: 1,826 checks, including all species/grid boundaries, moving-target exits, direct invalid attacks, reward recipes, prep controls, live equip/forge, no automatic fight start, encounter equipment access, forced silence and music playback.
- `hex_navigation_test.gd`: 33 checks.
- `all_skill_cast_test.gd`: 441 actual skill casts.
- `sustain_balance_test.gd`: 9 checks.
- `warden_audio_test.gd`: 331 checks; retained cue routing/assets and boss counterplay, now asserting silent playback.
- `sound_events_test.gd`: 23 checks; retained assets and silent gold/death/ambience events.
- `item_feedback_ui_test.gd`: 5 checks; item VFX and pause behavior remain while audio is silent.

All assertions passed. The range/prep and pre-existing navigation harnesses emit Godot resource-retention warnings during shutdown; no parse error or runtime script error occurred in the successful UI run. No new Windows executable or measured FPS is claimed.

## Dungeon map continuation

Closing a checkpoint/warden/shop champion draft used to leave a pending decision that disabled the map with no reopen action. The current-room card now provides **Choose champion**, **Claim spoils**, or **Resolve event**, preserving the saved offers until a choice is made. Pending level-ups are shown before a fight's Prepare action; direct match entry also routes to the skill picker. Resolving the final level-up returns to the map, where Prepare resumes formation and equipment. Existing blocked saves use this same path; no run reset is required.

`dungeon_continue_test.gd` reproduces the missing draft/level-up actions before the fix and checks reopening, save reload, unchanged offers, passing a draft, path unlocking, level choices, equipment preparation, and loot/event recovery after the fix. Headless tests verify flow, not native visual layout.
