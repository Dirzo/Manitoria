# Populated Playtest Atlas — 0.72

The game opens its Atlas with the actual playtest database already populated. No personal match is needed to see results. This replaces 0.71's summary-only Research view.

## Complete audit, separate cohorts

- 0.69 full screen: 5,888 matches (1,536 champion battles plus 4,352 item/control battles), all 32 champions and all 136 items.
- 0.70 validation: 1,920 matches (1,536 same-draft champion battles plus 384 expanded item/control battles). Only the two changed items have post-patch controlled results; others remain explicitly untested in that cohort.
- 0.69 expanded item follow-up: 384 matches, separately queryable for comparison with 0.70.
- Total: 8,192 unique simulated matches across 12 audited raw batches. Patch cohorts never mix. Forced-win routing checks and personal QA saves are excluded.

Match-level champion observations and matched item/control effects drive the native query views. All original raw records are also bundled in `data/playtests/raw-audit.zip`. Exact dataset membership, raw batch hashes and file checksums are in `manifest.json`. **Export database** writes the raw archive, query datasets, balance report and manifest to the game's user directory and offers its folder path.

## HTML-style browsing inside the game

Champion, item, skill, balance and methodology navigation; patch/cohort, difficulty, cup, star, build-policy and role filters; search; minimum sample thresholds; sorting and clickable drill-downs.

Champion pages include pair-based confidence intervals, tiers, most sampled cores, strongest supported cores (minimum 20 draft pairs), cup/policy/star/evolution breakdowns, observed item choices, measured skills, opponent-team matchup associations and the complete historical ability catalog.

Item pages include matched outcome shifts, t intervals over mirrored setup means, test/control wins, DPS/HPS changes, logged activations, test carriers and champion associations. No interval is presented with fewer than two independent setups. Historical item descriptions come from the chosen patch. This is native Godot UI rather than a browser embed.

Draft cards show personal evidence when available and otherwise show labeled 0.70 playtest evidence. **My runs** retains the independent local database from 0.71; future player and CPU records continue to accumulate without contaminating the fixed audit. Decision matrices and Ascension remain available.

## Interpretation

These are simulated team associations, not human ladder statistics or isolated champion strength. Champion intervals use unique mirrored draft pairs as an approximate effective sample size. Skills pool ranks/rarities; damage alone misses shields, control and other utility. Item experiments add a free item to the carrier's existing build versus no added item, rather than equal-gold alternatives. Gold generation needs separate economic analysis. The current game retains the balance rules tested in 0.70; Ascension modifiers were not part of that audit.

## Verification

Database tests verify exact cohort counts, unique batch membership, all catalogs, native/HTML Naga parity, live filtering, controlled item effects and uncertainty, skill measurements, untested post-patch items and separation from personal saves. Native UI checks cover default population, champion/catalog/matchups, all-item browsing, expanded item details, global skills, balance comparisons, database export and personal-data navigation. Packed-game checks ensure all datasets and the raw archive are available after export.
