# Dungeon mode

A new run type next to the guild run (World Tour). It is modelled on the map-crawl of *The Last Flame* and *Slay the Spire*. You found a guild, sign a Legendary headliner and draft your squad as usual. Then, instead of cup brackets, you descend through three depths one room at a time.

## How to start

On the main menu, choose **Dungeon** (between **New club** and **Exhibition**). Name the guild and forge its crest as usual, then press **Enter the dungeon ▶**. The run uses the normal save slots and appears in **Saved campaigns** as "Dungeon depth N".

## The descent

| Depth | Name | Warden |
| --- | --- | --- |
| 1 | The Rootbound Halls | Warden of Roots |
| 2 | The Cinder Vaults | Warden of Embers |
| 3 | The Starless Deep | Keeper of the Last Flame |

Each depth is a branching map of eight rows. Seven rows of rooms lead to a single Warden. Every room is reachable, and each room links to one or two rooms in the next row. The **Dungeon** tab shows the map; glowing rooms are on your path.

| Room | What happens |
| --- | --- |
| Skirmish | A pack of dungeon beasts from the depth's region. Win, then pick one of three components. |
| Elite | A rival guild lost in the dark (stronger: +6% rival strength). Win, then pick one of three finished items. Every depth has at least one. |
| Outfitter | The guild-run shop: buy, forge and reroll, then move on. This is the only shop. |
| Campfire | **Rekindle** one flame, or **Train** (fielded champions gain 120 XP). Always the row before the Warden. |
| Unknown | One of seven events with a choice: the Wandering Smith, the Ember Shrine, the Lost Caravan, a Mentor's Ghost, the Cursed Hoard, the Hearth Spirit and the Masked Gambler. |
| Treasure | Gold, plus one of three components. Always row 4. |
| Warden | The strongest rival guilds (+10% strength). Win, then pick one of three finished items and open a medal chest (bronze, silver, gold). |

Any spoils can be skipped for 25 gold.

## Flames

Flames are your lives: Keeper starts with 4, Standard with 3 and Champion with 2.

- **Losing a skirmish or elite** costs one flame. The guild still pushes past the room.
- **Losing to a Warden** costs one flame, and you must fight it again.
- **Campfires**, the Hearth Spirit event and every Warden victory rekindle one flame, up to your maximum.
- **When the last flame goes out**, the run is over. Events never let you spend your last flame.

## Between depths

When a Warden falls, these things happen:

- The squad trains (160 XP for every fielded champion).
- One flame rekindles.
- A fresh recruit board opens on the stairs.

Recruit, set formation and tactics, then press **Descend ▶**.

## Progression

The guild run's systems are reused: rival levels, rival gear, skill rarity, shop stock and gold all follow `TourBalance`. The difference is that the tour level comes from depth. Across the 24 rows it climbs from 1 to 5, as it does across five cups. Dungeon fights award 2.6× match XP, since there are fewer fights than in five full brackets. Ascension ranks apply as usual.

The values in this document are first-pass numbers. Win rates have **not** been simulated. A balance pass with `tools/balance_sim.gd`-style sampling is still needed.

## Files

- `godot/scripts/dungeon.gd`: map generation, rooms, events, flames, opponents and fight resolution.
- `godot/scripts/dungeon_ui.gd`: the map screen, spoils picker, event/campfire dialogs and guide.
- `godot/tools/dungeon_smoke.gd`: a headless routing test. It walks all three depths through every room type, forces losses and confirms that running out of flames ends the run.

```
godot --headless --path godot -s tools/dungeon_smoke.gd
```

QA captures: `--qa=dungeon_menu`, `dungeon_trail`, `dungeon_fight`, `dungeon_loot`, `dungeon_event`, `dungeon_intro`, `dungeon_result`.
