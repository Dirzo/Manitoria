# Run Atlas and decision matrix — 0.71

Open **Atlas** from the menu, draft, roster, preparation or shop. Champion cards show your own collected sample size and team win rate. The Atlas ranks all champions and opens champion item/ability breakdowns, an item table and a run history.

## Your data

Completed player matches record both teams; simulated CPU bracket matches are also captured. Compact records include patch, difficulty, Ascension rank, cup, stars, evolution, equipped items, learned skills, tactics, damage, healing and per-ability output. Filter player champions, CPU champions, all champions, difficulty, cup, stars, rules version and challenge rank. A separate Research view contains the measured 0.70 champion audit (1,536 mirrored battles); it never contributes to personal statistics.

Run files live in Godot's application user directory under `atlas_runs`. They survive starting new runs or replacing a campaign slot. Collection starts with 0.71; earlier reports do not have complete build snapshots and are not fabricated into matches. Exhibition matches are excluded. Draws count as half a win. Appearances share team results and are correlated; win associations are not isolated champion/item strength or purchase advice.

Campaign saves commit first, then pending records flush into the independent run database. Stable match IDs prevent duplicate counting after retries and reloads. Files use temporary replacement and retain a backup. If an Atlas write fails, the pending queue stays in the campaign save for retry; a corrupt database file is preserved rather than overwritten. Aggregations and run reads are cached until new records arrive. No networking, account or telemetry upload is required.

## Draft → plan → scout → fight → learn

After drafting, open **Run plan**. Each champion has two editable ordered rules. Conditions include always, cup 3+, enemy support champions, ranged majority and the previous match being a defeat. The first matching rule selects a legal tactics preset plus a build priority (adaptive, AD, AP, attack speed, armor or cooldowns).

Save the plan, preview it against the next opponent, then explicitly apply it. Applied priorities affect item recommendation scoring; tactics drive combat through the existing tactics engine. The plan does not spend gold, change skills, automatically rearrange equipment or apply itself each round. Review and re-apply after scouting. This makes the decision system inspectable while keeping buying and draft decisions in the player's hands.

## Ascension prototype

The new-run charter offers Ascension 1 immediately. Ascension uses Champion rules and a fixed additional 2% rival combat-strength multiplier per rank; it never reacts to the player's lineup or collected statistics. Finish all five cups without falling to unlock the next rank, up to 10. Normal difficulty and economy remain unchanged. The ladder's persistence, unlocks and strength progression are tested; completion rates across all ranks have not yet been calibrated with a large run-level study.

## Verification

- Database/rules integration: 27 checks, no failures.
- Native Atlas/plan UI: 7 checks, no failures (champion navigation, item rendering, save and opponent preview).
- Packaged game database/rules integration: 27 checks, no failures.
- Existing targeted mechanics: 41 checks, no failures.
- Full five-cup campaign/save routing: 293 checks, no failures.
- Test saves and recordings use isolated application directories; personal saves are untouched.
