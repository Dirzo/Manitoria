# Manitoria 0.16 — World Tour

## Start playing
Found a new club from the title screen, recruit five beasts with the 1,200 gold founding fund, and open World Tour. Existing league campaigns keep their heroes, equipment, gold, reports and schedule. They can explicitly choose Enter World Tour on Overview to begin team level 1 with that roster. Existing league saves are not silently reset.

## Tournament progression
Each of 20 team levels has a three-match tournament. Win at least two matches to advance to the next team level and earn 200 + 25 × the completed team level in bonus gold. A loss or draw still awards 75 match gold; a win awards 110. Failing to qualify repeats that tournament while keeping earned gold, hero XP and equipment. Completing the level-20 tournament finishes the circuit.

Heroes retain independent arena XP, one reward per hero level-up, four equipped abilities, Rank 2 upgrades and level-10 evolution. Only fielded heroes earn XP. Team level tracks tournament progress, not an automatic roster-wide ability unlock.

## Six locations
Briarwild Conservatory (forest), Cinderfall Caldera (volcanic), Pearlreach Coast (coastal), Frostspire Citadel (glacial), Aurelian Dunes (desert) and the Astral Observatory (astral) repeat through the 20-level circuit with stronger opposition. Arenas share the tactical floor layout but change floor palette, lighting, scenery and themed rival lineups. Higher-level rivals gain equipment, ranked skills, rare/legendary effects and evolutions.

## Between-match outfitter
Every match creates a saved shop stop, after any earned hero choices. The next fight stays locked until the shop is closed. Each offered item can be bought once for that stop; offers unlock with team level. Twelve equipment types fill claw, armor and charm slots. Select a hero and Buy & equip, or attach inventory items. Replaced gear returns to the shared bag. Skipping the shop is free. Gold, purchases, loadouts and shop state persist across reloads.

## Rare and legendary skills
Ability and signature upgrade cards can be Rare (+10% potency) or, from hero level 5, Legendary (+25%). A win raises the odds: Legendary 9% vs 5%; Rare 22% vs 16% at level 5+, with the combined upgraded chance 31% vs 21%. Before level 5, Rare alone uses that combined chance. Rarity never downgrades on later rank upgrades. Previous rare bonuses infer their rarity when loaded.

Rare cards have a violet sheen; legendary cards have a stronger gold sheen. The animated treatment also appears in roster artwork and the live ability inspector. Combat uses luminous shards, larger tinted projectiles, rank-up sparks, and gold strike flashes for legendary casts. Legendary sounds get higher priority in the mix. Effects follow the battle clock and preserve the ring-free clarity pass. These are enhanced effect animations layered over the existing creature clips.

## Validation
42 tournament/data assertions and a full native UI flow check cover promotions, retries, duplicate rewards, shop gates, stock, equipment stats, save/load, final completion and legacy entry. All 128 discovery windups, 18 hero progression checks, 20 champion UI checks, audio and rarity animation checks are retained. A sample of six tournament tiers informed rival progression, with an additional early glacial adjustment for Keeper difficulty. This is an initial balance pass, not an exhaustive assessment of every build.

Extract the Windows ZIP into a fresh folder; keep Manitoria.exe and Manitoria.pck together. Title screen for the latest build: Windows edition 0.17. See TACTICAL-OUTFITTER.md for the reworked equipment, refreshed shop and current balance notes.
