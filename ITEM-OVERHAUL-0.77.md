# Manitoria 0.77 — Item overhaul

Items now change how a champion looks and fights: champions grow huge, blur with attack speed, or land crits that explode across the screen. The catalog is 9 components, 36 finished items and 9 Wild items, and every item has a Legendary version from the new Mythic Anvil. Size and Crit join the stats, making an octagon of eight.

## Stats 7 and 8: Size and Crit

- **Size** is rolled by role (tanks and wardens big, assassins and casters small). Every +10% Size above a champion's natural size gives +5% HP, +5% AD and wider attacks and spells; the model grows on screen, and big champions are easier to hit with area effects. Cap 2.0× (2.4× with a Giant Legendary).
- **Crit** is crit chance, rolled by role (assassins and carries high, tanks low). Basic attacks crit for 2× (more with Crit items); crit chance over 100% turns into crit damage.
- Both have birth rolls, temperament effects and level-up cards. The stat hexagon is now an octagon.

## Items

- **Components:** Sharpened Fang (AD), Roc Feather (AS), Ember Shard (AP), Moonstone (Mana), Troll Hide (HP), Bronze Plate (Resistance), Storm Glass (Crit), **Titan Marrow** (Size, new) and Trickster's Coin (Wild).
- **36 finished items** across six paths: Giant, Tempo, Crit, Spell, Tank and Sustain. Each one has one fantasy, a visible change and a felt moment.
- **9 Wild items** (Coin + a component): a huge upside with a real downside.
- **Mythic Anvil:** turns one finished item into its Legendary (one per champion). On a Wild item it's a 50/50: Legendary or shattered. Anvils come from opt-in Anvil rooms on dungeon paths from depth 2, Wardens from depth 2, and World Tour Gold chests.
- **Six risky relics** replace retired wild items: Chaos Die, Puppet Strings, Doppelganger Cloak, Golden Idol, Sugar Rush and Berserker's Totem.
- Rivals and mobs field Legendaries from cup 4 and dungeon depth 3.
- The full item list, with every effect and Legendary, is in the v0.77 plan doc and `godot/scripts/forge.gd`.

## Feedback

- Champions grow smoothly as Size rises; giants above 1.5× shake the camera when they walk.
- Crits get their own orange numbers with "!"; **MEGA CRITS** (3× or more) are big and gold, with a hit-stop, a camera kick and a loud crack.
- Afterimages from 2 attacks per second, and a wind ring from 3.
- A ring in the build path's colour under each champion, a ×N badge for stacking items, and a gold ★ nameplate for Legendary carriers.
- The first time each item triggers in a fight, its name pops over the champion. Stomps, shockwaves, bounces and rebirths each have their own effect and sound.
- The match report shows the biggest crit of the fight.

## Pacing and saves

- The first dungeon Warden gives a second finished item, so a carry can hold three items before the first Anvil room.
- Old saves convert automatically: every retired item and component becomes its closest new one.

## Art

New items borrow older icons until their own art exists. The art brief lists all 91 icons; the prompts are in `godot/data/item-art-manifest.json`, and `godot/tools/item_art_sheet.py` makes a contact sheet. Titan Marrow's icon is a placeholder.

## Validation

- `tools/v077_items.gd`: every item and Legendary triggers in real fights. Against a team holding the same two components as loose stats, finished items win 25–92% (most 50–75%) and Legendaries 42–100% (12 fights each, so ±14%). The outliers were tuned.
- `tools/v077_item_test.gd`: recipes, conversion of old ids, the Anvil and the Size/Crit stats (0 failures).
- Full tour (303 checks), dungeon (2,008 checks), save migration (13 checks) and the signature smoke test: 0 failures.
- Base balance (`tools/v076_balance.gd`): fights about 35s. Phoenix is strong at level 20 (80%); Pegasus and Cyclops are weak.
