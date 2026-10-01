# Manitoria 0.21 — Skill Lab

## Fresh discovery choices
Every creature now has 12 distinct executable discovery options instead of four eligible choices. Across 32 creatures, that is 384 named hero/skill entries, using shared combat effect families with species-specific identities. Indices 0–7 retain their meaning; appended discoveries never remap saved skills.

The first three discovery decisions can present nine different options: offered discoveries are recorded per hero, persisted on choosing, and preferred against the complete seen history on subsequent rewards. Reloading keeps already-generated offers. Existing pending cards and chosen skills are preserved; the new pool applies when subsequent rewards are generated. Earlier versions did not store a complete offer history, so old campaigns retain their known recent offers and start accumulating full history from this release.

A kit still contains its signature plus three chosen skills. Once full, cards intentionally return to those selected skills for Rank 2. Level-10 evolution and later mastery choices remain intact. Winning still improves rare-card odds.

## Preview before committing
Every level-up card has Preview in arena. This opens an isolated 3D demonstration with the actual hero level and the proposed card applied to a copy. No reward, gold, XP, save, equipment or campaign result is changed by watching it.

- Clustered, Line and Spread arrange enemies and wounded allies differently.
- Replay restarts; Pause/Resume freezes the demonstration; Slow motion toggles half speed.
- Real windups, cast poses, projectiles, impacts, damage numbers, healing, shield bars and status effects use the combat engine and arena renderer.
- A results panel reports damage, effective healing, peak shield on a unit, affected units and observed status effects.
- Back to choices or Escape closes without learning the card. Choose the card normally afterward.

The stationary targets make coverage readable. Allies start wounded, one enemy starts below the finisher threshold, and gear procs are excluded to keep the demonstration focused. Evolution/mastery cards showcase the signature with the proposed upgrade; this is a controlled demonstration, not a prediction of a live match. The scene replays every 7.5 seconds.

## Art and compatibility
The 128 individual original skill paintings remain unchanged. Additional discoveries use existing effect artwork, so this update does not claim 384 new paintings. Dedicated art and fallback effect art both work in upgrade cards, combat, profiles and reports.

## Validation
All 32 heroes were checked for nine nonrepeating offers across the initial three discoveries. All 384 available discovery actions resolve through real preview windups. Checks compare line and spread piercing damage, clustered area damage, ally healing, shields, control-only actions, rarity potency, pause, scenario changes, save isolation and persistent discovery history. Progression, real combat windups, artwork mapping, world-tour and headliner regressions also passed. Windows upgrade and preview layouts were visually checked.
