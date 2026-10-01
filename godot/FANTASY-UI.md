# Manitoria 0.19 — Living Interface

A colorful arena valley now frames the native Godot management screens. The title has three illustrated choices, ornate frames, and a dedicated saved-campaign chooser. Roster management puts five animated champions and their equipment up front. Tournament overview emphasizes the matchup and world route. Details and comparison tables remain available on demand.

## Equipment

- Select a champion, then click an item in the bag to equip it.
- Drag a bag item onto a champion or matching equipment slot.
- Drag a shop offer onto a champion to buy and equip in one step, or use its Equip button.
- Drag worn equipment onto another champion to transfer it.
- Drop worn equipment on Unequip to return it to the shared bag.
- Click an empty or occupied slot to pick compatible gear or unequip it.
- Click shop art or right-click bag art for full effects, tradeoffs, replacement details, and buy/sell options.

Replaced equipment returns to the bag. Gear changes save automatically. Invalid drops, unaffordable purchases and mid-battle changes do not modify the campaign. The existing 48-item arsenal, combat behavior, 128 skill paintings and saved campaigns remain compatible.

## Validation

Equipment transaction and native pointer-drag checks passed, including save/load, replacement, invalid drops, duplicate-purchase prevention, and rollback on failed saves. Shop, title, champion exhibition, world tour, tactical items, role items, audio, analytics, combat tactics and progression regression scripts passed. Menu, roster, shop and tournament overview were visually checked at the game's native layout.

## Original environment art

Asset: `assets/ui/arena-valley-v1.png` in the Godot project (embedded in the Windows pack).
Created using the built-in image generation tool. The user's menu screenshot and roster recording informed composition and interaction; no reference game artwork or video is bundled.

Generation prompt:

Use case: stylized-concept. Project asset: original widescreen 16:9 high-resolution background painting for the native fantasy creature arena autobattler Manitoria. A stunning colorful elevated tournament colosseum in a lush enchanted valley, inviting heroic daylight, turquoise river and waterfalls, jade foliage, violet flowering trees, ivory stone arena architecture with tasteful ancient gold trims, pennants fluttering, sunlit mountains and mist. Painterly premium fantasy strategy-game key art, rich crafted materials and luminous saturated color, sophisticated rather than childish. Composition: dramatic panoramic landscape, grand arena visible on the right middle distance, forest and river framing the bottom and sides, soft open luminous sky in the upper center where our own title will overlay, lower center terrain quieter to support three game menu cards. Deep teal shadows, gold sunlight, emerald and orchid accents. Entire image is environmental artwork only. No interface, no text, no logos, no watermark, no legible banners, no humans or creatures. Must be an original world, not an existing game's scene. Crisp art detail at edges, atmospheric depth; avoid dark horror mood or grey corporate dashboard aesthetic.
