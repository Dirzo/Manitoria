# Manitoria 0.73 — Speedrun Stat Check

Open **Speedrun stat check** on the title screen. Sign a Legendary headliner and draft an elite four or a full five using the normal 1,200-gold budget. Click **Plan speedrun** when your squad is ready.

1. Select a champion and click a deployment hex to set its formation. Occupied hexes swap champions. Tactics remain available for each champion.
2. Add up to **20 ordered item purchases**. Each row represents one finished Forge item for a specific champion or the champion with the best build fit. Reorder or remove rows, search the catalog, or start with **Suggested team build**.
3. Choose each champion's build path, preferred species evolution and Apex evolution. The skill policy chooses from the actual earned reward offers. It does not grant free skills or evolutions.
4. Select **5 cups** or **10 cups**, choose Keeper, Standard or Champion, and click **Simulate**.

The simulation runs actual hex combat and the eight-club double-elimination brackets, including CPU-only matches. XP, training, legal item slots and earned gold govern development. Champions stay on your drafted team throughout the benchmark.

## What the benchmark means

- It completes the requested number of cups even after a poor placement. Results explicitly mark the first cup where a **regular run would have ended** and each cup's survival cutoff.
- Priority items are forged at their actual two-component cost, without random shop offers or reroll spending. Each row is bought once. Duplicate items cannot stack on one champion. Full recipients wait for evolution slots; unaffordable eligible rows reserve their position ahead of cheaper purchases. Rows with no legal recipient are skipped so other champions can develop.
- Skills follow the chosen build path and offered rarity; the chosen evolution is taken when its XP threshold is reached. Species evolution is level 8; Apex is level 16. XP remains capped at level 20.
- Cups 1–5 keep the regular strength schedule. Cups 6–10 extend enemy target levels by two per cup (cap 20), combat quality by 2.5 percentage points per cup, and match income by ten gold per cup. Regions cycle; equipment pacing reaches its existing late-game ceiling. These extended cups are a first-pass benchmark, not a newly calibrated difficulty ladder.
- The same draft, formation, priorities, tactics and seed reproduce the same combat outcomes. The elapsed wall time can differ.
- The benchmark grants no campaign trophies, medal chests or Ascension unlocks, and does not mix its continued-after-elimination results into personal Run Atlas statistics. The historical 8,192-match Playtest Atlas remains available with its original patch labels.

## Results and persistence

Results show cup placements, wins/losses, gold, final champion stat hexes, equipment, skill/evolution decisions and CPU brackets. **History** opens the latest twenty benchmarks. **Export JSON** writes detailed player and CPU combat rows, purchases, decisions, unfilled priorities and wallet snapshots to the Godot user-data directory.

**Resume speedrun draft** restores the separate laboratory draft and priorities after restarting. Normal campaign slots are independent. **Cancel** keeps partial results; CPU bracket advancement completes its current batch before yielding.

## Champion-copy retirement

Champion-copy purchases, star thresholds and their combat/power multipliers are removed for players and rivals. Champions improve through XP, skills, equipment, species evolution and Apex choices. Existing saves keep their identities, equipment, XP, evolutions and previously improved stat rolls; legacy copy counters and copy comparison feedback are cleared when loaded. Previously paid copy gold remains part of the existing resale accounting. Historical Atlas star filters describe older measured patches only.

## Validation

- Full five- and ten-cup integration runs with real combat, CPU brackets, legal item slots, actual reward offers, selected evolutions, gold conservation and deterministic replay: 201 checks passed before the performance cache change.
- Cached hex geometry preserves every neighbor and cell ordering. Silent presentation skips preserve combat, metrics and RNG: 100 checks passed. Optimized five-cup player combat rows, outcomes, purchases and gold match the original implementation exactly.
- Copy retirement across all 32 species and legacy copy counts: 544 checks passed. Economy and extended progression: 105 checks passed. Historical Playtest Atlas regression: 37 checks passed.
- Native planner/results screenshots were inspected and layout widths corrected. Thirteen UI checks cover paid drafting, planner routing, formation cells, final stat hexes, cancellation, resumed champions/priorities and independent save files. Packaged Windows planner/results smoke captures also passed.

These are integration and functional checks, not a claim that ten-cup balance has already been tuned across thousands of new runs.
