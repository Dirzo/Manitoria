# Manitoria Atlas

Open `index.html` in a browser, or serve the repository and visit `/analytics/`. The site works offline: its data, scripts, styles and images are bundled. Every champion also has a direct page at `champions/<species>/`.

The tier list supports role, cup, difficulty, stars, purchasing policy, search and minimum-sample filters. Champion pages include observed item cores, skill contributions, star/evolution summaries and opponent samples. Item pages distinguish paired experiments from ordinary build associations. The methodology page defines each measurement and its limits.

The audit totals 8,192 matches across the initial screen and balance validation. Select patch 0.69 for the complete 136-item screen or 0.70 for the updated 1,536-match champion cohort and expanded Rosary/Sugar Rush experiments. The balance page compares the fixed cohorts. The current-patch data loads only when selected.

The source of the visual structure is the familiar tier-list/build-page pattern used by LoLalytics. The measurements and ranking rules here are specific to Manitoria; they do not use League of Legends player data or copied branding.

## Reproducing the audit

The runner is `godot/tools/analytics_audit.gd`. Run it with Godot 4.7.2 using an isolated application-data directory, `--headless --path godot --script res://tools/analytics_audit.gd`, and these environment variables:

| Label | AUDIT_MODE | AUDIT_START | AUDIT_COUNT |
| --- | --- | ---: | ---: |
| champions-a | champions | 0 | 384 |
| champions-b | champions | 384 | 384 |
| items-a | items | 0 | 34 |
| items-b | items | 34 | 34 |
| items-c | items | 68 | 34 |
| items-d | items | 102 | 34 |

Set `AUDIT_LABEL` to the label. The runner writes JSON Lines to `user://analytics-<label>.jsonl`. The completed manifest records counts and SHA-256 hashes. Raw simulations are retained separately from the compact display data. Interrupted previews are not final datasets.

The source now contains the 0.70 rules. Reverse `baseline-0.69/pre-to-post.patch` in an isolated project copy for the earlier rules. Rebuild the displayed baseline with `python analytics/build_atlas.py` from a repository beside the `qa-analytics` raw-data folder. Pillow is required for thumbnail generation. Expanded experiments set `AUDIT_ITEM_IDS=rosary,sugarrush`, `AUDIT_SCENARIOS=48`, start 0 and count 2; run the same cohort against both rule versions.

GitHub Pages publishing is configured in `.github/workflows/publish-atlas.yml`. Enable Pages with GitHub Actions as the repository's publishing source, then run that workflow. It preserves the existing browser game at the root and serves Atlas at `/analytics/`. Merely pushing the workflow does not confirm that Pages is enabled or deployed.

Champion drafts mirror both board sides, use seeded identities and randomized run tiers, buy only affordable gear/copies, and choose actual offered skills. Difficulty selects shared development floors/economy for both teams. These composition benchmarks do not measure player-versus-AI difficulty odds or replay full tournaments.

Item tests add one experimental item to a matched carrier build, remove duplicates of that item, and compare against the same team without it. The experimental item is not charged against the development wallet, so this isolates marginal combat contribution rather than equal-gold alternatives. Gold-generating items require separate economic evaluation.

Statistics describe simulated team outcomes. Mirrored matches, co-occurring champions and sparse builds limit causal conclusions. The site exposes those limits and sample counts rather than treating its provisional tier labels as definitive balance verdicts.
