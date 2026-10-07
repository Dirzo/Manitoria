Latest: see [0.62 skill and item balance](BALANCE-0.62.md) for the current recruitment rules, scaling, item tuning and hex skill reach.

# Windows edition 0.61 — Hex Combat & Shop

The playable arena has 30% more area than 0.59. Champion models retain their original scale. Deployment and combat use the same regular hex grid and existing formation slot IDs remain compatible.

Combatants reserve an open adjacent hex, travel along its edge and stop exactly at its center. Shortest open paths avoid occupied and reserved cells. Basic attack ranges are fixed integer hex distances, derived from each champion's equipped range at battle setup (minimum one hex). Attacks and casts start from a hex center. Movement speed, slow, root and stun still apply; ranged kite tactics can retreat one cell. Leap, knockback, summoned units and wild position swaps also land on free hex centers. Attack ranges appear on the featured champion panel.

Ranged champions retain increased reach and artillery retains stronger, slower shells with heavier arcs and impacts. The outfitter has a rotating champion stage with six offers below. The lower panel restores all four last-round graphs: damage, crowd control, healing and damage taken. The Bag button sits next to current equipment, glows for newly received inventory, and acknowledges it when opened. Swap opens a team equipment view. Dropping a worn item on an occupied slot exchanges both items, including when both champions are full; an empty slot transfers it. Clicking worn gear also provides destination choices. Components still forge through normal bag and champion drops.

Draft-table Fit descriptions wrap inside their fixed column, with a taller row and full-detail tooltips. All 90 newly supplied item renderings are included.

## Verification

Official Godot 4.7.2 on Windows: 239 mechanics/artwork checks, 33 hex navigation checks across six complete fights, and 29 rendered interface checks. Coverage includes unique cell reservations, adjacent-cell movement, standing and attacking on centers, fixed attack distance, summons/leaps/position swaps, carousel selection, purchases, forging, full-inventory item exchange, bag notification acknowledgement, visible graphs and wrapped Fit descriptions. Rendered screenshots were visually inspected.

Run `godot --headless --path godot --script res://tools/hex_artillery_test.gd` and `godot --headless --path godot --script res://tools/hex_navigation_test.gd`. Run the rendered test with `godot --path godot --script res://tools/shop_carousel_test.gd -- --qa=tour_shop` using an isolated APPDATA directory; it changes a generated QA campaign.

Existing Windows saves remain compatible. These checks verify behavior, not roster-wide competitive balance. The browser edition is unchanged.

