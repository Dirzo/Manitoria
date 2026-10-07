# Manitoria 0.68 — Shop economy, copy rolls and stars

The item shop now contains a champion-copy offer for the selected member of your existing team. Rotate the carousel to choose another champion. The offered rolls are shown before paying. Higher offered rolls replace weaker rolls on the owned champion; lower or equal rolls never degrade it. Every purchase advances the copy counter even if none of its rolls are better. Shop rerolls change both component offers and copy rolls, at the existing escalating cost. Rolls also refresh after a purchase and when the next shop opens.

Champions need **3 total copies for two stars and 6 total copies for three stars**, including the original. Two stars grant +18% maximum health and +12% attack damage / ability power. Three stars replace those bonuses with +50% maximum health and +35% attack damage / ability power. This makes the three additional purchases after two stars a meaningful investment. Skill ranks, equipment, temperament, XP, name, formation and species evolution remain intact. Stars do not directly increase range, armor, attack speed or reduce cooldowns; improved rolls can raise their own stat channels. Each damage, healing and defensive scaling channel receives the star power multiplier once.

Copies cost the run's species tier price (Common 150g, Epic 300g, Legendary 450g). The original champion is included in the count; five additional purchases reach three stars. Copies occupy no new roster slot. Copies can be bought from the Market after founding four starters, between cups, and for owned champions in the item shop during cups. Recruiting new species remains locked inside cups. Three-star and insufficient-fund purchases are rejected; failed saves restore gold, rolls, copy count and news. Sell refunds include half of the paid copy costs. Existing saves remain compatible; old champions with more than six copies retain three-star status and their paid-cost records.

## Gold and rival progression

| Difficulty | Cup-one win / loss | Cup-five win / loss |
| --- | --- | --- |
| Keeper | 200 / 165 | 240 / 205 |
| Standard | 180 / 145 | 220 / 185 |
| Champion | 170 / 135 | 210 / 175 |

Every cup adds 10 gold to both rewards. Placement prizes and item gold effects remain additional. Losing income still buys components and helps save toward copies, limiting the advantage from a winning streak. The founding fund and draft prices are unchanged.

Rival star upgrades are deterministic, with no adjustment to your roster's strength. Nobody starts starred in cups one or two. The share of identities reaching two stars is Keeper 0/0/0/10/20%, Standard 0/0/10/25/45%, Champion 0/0/15/40/65% across the five cups. In the final Champion cup, 5% of identities reach three stars instead. Their copy rolls follow the same keep-the-higher-stat merge. Rivals gain stars once, without repeatedly rerolling or granting free improvements whenever the roster is viewed. Existing level, item-build, training, quality and skill-rarity pacing remains in place.

## Visible feedback

The shop shows the offered improvements and the price beside the featured champion. Buying plays the upgrade cue, updates the star counter, and animates the stat hex from the pre-purchase outline to the new polygon. Green labels display actual stat gains, including bonuses from crossing a star threshold. Percentage-point armor gains and relative movement-speed gains use distinct units. Numeric gains remain visible even when an axis reaches the chart's rim. The current items and bag button remain beside this panel; the previous-round graphs remain below the shop offers.

## Validation and practical limits

A 240-fight audit spans every species, all five cups and all three difficulties, using mirrored board sides. The final Champion cup was rerun with the six-copy rules. Players have reachable XP and item builds, and spend only earned remaining budgets on two-star copies; this conservative buyer keeps spare cash rather than optimizing a three-star carry. These comparisons are build samples, not guaranteed odds for a player or an actual tournament bracket.

Wins out of 16 per cup in the sample:

- Keeper: 15, 16, 16, 16, 15.
- Standard: 9, 14, 14, 13, 12.
- Champion: 7, 6, 6, 9, 9.

The export passes 109 copy/save/combat checks, 22,564 economy and rival-star checks, 13,626 tour checks, 464 skill/item/recruitment checks, and 1,228 item-feedback/audio checks. The cup-training save test passes 26 checks. Nine real UI checks exercise the Market and shop buttons, the animated hex, protected recruitment and combined rerolls. Screenshots were inspected for chart-label fit and equipment placement. Original user saves were not edited or revived. Source changes are local and unpushed.
