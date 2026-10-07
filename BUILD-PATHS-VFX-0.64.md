# Manitoria 0.64 — Build paths and skill VFX

This release supersedes the damage-channel assignments in the 0.63 notes.

## Equal offensive pools

The audited roster has 348 direct-damage actions: exactly **174 scale with attack damage and 174 with ability power**. The remaining 125 actions are utility (healing, shielding, buffs or summons), so they are counted separately. All 32 champions use one primary offensive channel, split evenly into 16 AD and 16 AP champions. Armor and health remain secondary defensive coefficients, capped at a combined 35% on damaging skills. Selected rapid skills retain attack-speed amplification; cooldown reduction remains a separate build lever.

AD: Minotaur, Golem, Troll, Wendigo, Direwolf, Manticore, Griffin, Wyvern, Harpy, Nemean, Owlbear, Hydra, Cerberus, Chimera, Jackalope, Cyclops.

AP: Kitsune, Phoenix, Kirin, Basilisk, Treant, Naga, Unicorn, Yeti, Zaratan, Gargoyle, Nekomata, Thunderbird, Sphinx, Pegasus, Arachne, Salamander.

Scaling and damage type are independent: a magical poison can scale with an AD predator's attack stat. AP champions still use attack damage for basic attacks. Thunderbird now has an AP primary path with an attack-speed volley branch. Evolution bonuses and suggested-item weights follow the champion's primary stat. Max-rank AD champions can choose attack speed instead of an unused AP growth reward. Existing saves retain their learned skills, equipment and progression.

## Engine animation pass

All 473 actions have a stable skill identity, a palette matching the new icons and a themed effect composition. This is a first pass using shared effect families with champion-specific treatments, rather than 473 individually handcrafted animations.

Arachne gains purple binding webs, cocoon shielding, green brood hatching and poison accents. Salamander's lava terrain uses animated molten cracks and erupting rocks. Bird volleys gain emissive feather projectiles; claw attacks get curved strike trails. Spell bindings use coils instead of wooden roots when appropriate. Water, ice and poison artillery use matching projectile materials and trails. Rider effects add poison, burning or binding accents.

Effects use the battle clock, respect pause and speed changes, expire automatically and retain a live-effect cap. Existing body attack poses and combat audio remain integrated.

## Learning feedback

Learning a new skill opens a SKILL LEARNED replay with an animated icon reveal, the real combat effect and damage/healing/control feedback. The replay supports pause, slow motion and different target arrangements. It operates on a disposable hero snapshot and does not upgrade or mutate the campaign hero a second time. Continue returns to the game.

## Validation

Source checks passed: 2,410 build-path/VFX checks over all 473 actions; 1,863 skill audit checks; 464 balance checks; 441 actual skill casts; 12 mirrored build fights; and 6 new-skill UI checks. Representative web, brood, lava, feather, binding and melee effects were rendered on the GPU and visually inspected. Packaged-build verification is recorded in the delivery message.

All earlier arena, shop, item artwork, bag, graphs, roster-lock and 473 skill-icon improvements are included. Source changes are local and have not been pushed to GitHub.
