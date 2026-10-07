# Manitoria 0.63 — Champion skill identities

The audit covers every playable action: 32 signatures, 384 normal discoveries,
32 ascended actions and 25 evolution-granted actions (473 total). Saved discovery
indices are preserved, including skills whose names or behavior changed.

Each action now has its own explicit scaling channels, damage classification,
cooldown and thematic definition in `data/skill-audit.json`. Shared combat effects
no longer dictate whether a particular champion's skill is an AD strike or an AP
spell. Defensive power uses normalized armor/health channels; ability haste remains
a separate cooldown investment. Attack speed amplifies selected rapid skills with
a capped contribution, rather than accelerating every spell's damage.

## Build identities

| Champion | Intended skill paths |
|---|---|
| Minotaur | AD/health charges and crushing slams; health/armor rally and protection |
| Stone Golem | Armor/health physical impacts; AP crystal/rune disruption |
| Cave Troll | AD/health clubs and throws; health regeneration; AP bog venom |
| Wendigo | AD hunger, claws and life drain; AP soul frost and winter curses |
| Direwolf | AD/attack-speed pack flurries and bites; health/AP pack utility |
| Manticore | AD claws and execution; AP/AD scorpion venom |
| Griffin | AD dives, talons and feather blades; AP thunder screech |
| Kitsune | AP foxfire, illusions and spirit strikes; AP/health shrine support |
| Wyvern | AD/attack-speed stingers and talons; AP acid and plague breath |
| Harpy | AD/attack-speed quills and talons; AP song and weather control |
| Phoenix | AP solar fire, ember strikes and healing; no accidental AD fire spins |
| Storm Kirin | AP celestial lightning and charged horns; AP/health blessings |
| Basilisk | AP petrifying gaze, coils and venom; AP/health defensive shell |
| Elder Treant | AP roots, sap and pollen; armor/AD branch impacts; health/armor protection |
| Naga | AP tides, water lances and siren control; AP/health pearl support |
| Unicorn | AP radiant strikes and healing; AP/health moon support |
| Cerberus | AD/attack-speed bites; AP hellfire and underworld chains |
| Nemean Lion | AD/health royal swipes and impacts; health/armor impervious hide |
| Yeti | Armor/AD snow impacts; AP/armor avalanches and frost; AP whiteout; health/armor defense |
| Zaratan | Armor/AD shell and island impacts; AP tidal currents; health recovery |
| Owlbear | AD/attack-speed mauling; AD/health heavy throws; health recovery |
| Hydra | AD bites; AP swamp poison; health/AP regeneration |
| Chimera | AD lion/goat strikes; AP dragon/serpent magic; hybrid signature |
| Gargoyle | Armor/AD stone dives; AP cathedral disruption; health/armor protection |
| Nekomata | AD shadow ambush and claws; AP ghost fire and curses |
| Jackalope | AD/attack-speed kicks and antlers; AP luck/wind utility |
| Cyclops | AD/health rocks and forge strikes; AP eye beams, thunder and furnace magic |
| Thunderbird | AD/attack-speed feather volleys and talons; AP lightning; hybrid charged gale |
| Sphinx | AP riddles, sand, oracle light and magical pounces |
| Pegasus | AP celestial strikes and winds; AP/health healing support |
| Arachne | AP webs, venom, spiderlings and venom finishers; AP/health cocoon |
| Salamander | AP magma, molten bites and fire attacks; AP/health shell |

## Notable behavior changes

- Arachne's Spider Swarm and Brood Mother hatch actual spiderlings. Signature
  and learned summons share a three-pet limit. Silk Bind and Weaver's Lure bind
  foes with webs; Poison Nest deals venom rather than fire. Venomfang Injection
  keeps a low-health finisher while scaling entirely with AP.
- Thunderbird's Thunder Barrage uses 85% AD / 15% AP plus a capped attack-speed
  contribution. Lightning Lance uses pure AP. Crackling Gale uses 80% AP / 20% AD
  with a smaller attack-speed contribution. Physical feathers and magical bolts
  interact with the corresponding defenses.
- Kitsune, Phoenix, Kirin, Basilisk, Naga, Unicorn, Sphinx, Pegasus and Salamander
  retain spell scaling even when their action uses a shared strike or spin effect.
- Direwolf's Shadow Stalk and Lunar Bite, Nekomata's Shadow Pounce, Basilisk's
  Toxic Pool and Owlbear's Moonlit Hunt now use mechanics that fit their names.
- Ordinary skill power no longer receives an invisible hash-based bonus. Skills
  with an extra rider pay a visible 8% cooldown premium. Duplicate self-haste
  riders on team rallies are replaced with protective shields.
- Recommended items evaluate the current signature, selected discoveries and
  evolution-granted action, so changing a kit changes its suggested build.
- Runeward blocks enemy physical skills as well as magical skills, matching its
  description. Basic attacks and item procs do not consume it.
- AP champion attack evolutions now grant AP and tempo where appropriate.
  Foxfire Duelist, Cinder Hawk, Storm Charger, Venomfang Basilisk, Venomous Heads
  and Venom Matriarch trade 8% health for AP and attack speed. Starlance Charger
  and Skylance Paladin strengthen AP rather than unrelated attack damage.
- Evolution burn/venom on-hit effects use the champion's AP instead of a fixed
  damage value of 1; control riders retain their fixed durations.
- Weaker poison/burn applications from the same champion do not overwrite or
  refresh a stronger active spell. This preserves its damage and graph credit
  without stacking every poison skill into an unlimited damage multiplier.
- Poison/burn ticks use passive damage credit rather than basic-attack credit,
  preventing recursive on-hit triggers and separating passive damage in graphs.
- Melee flurries, bites and drains on wolves, owlbears and other close attackers
  use one-hex reach. Their ranged throws and spells keep their separate reach.
- Salamander's Lava Pool creates actual molten terrain that burns and slows;
  Naga's Brine Spray pushes with water instead of applying a fire burn.
- Redundant riders (such as a weaker burn on a burning blast, or a shorter stun
  on an existing stun) become useful secondary effects instead of paying a
  cooldown premium for an effect that immediately gets overwritten.

## Art and verification

The built-in imagegen tool generates one original icon per action. The complete
prompt set is `data/skill-art-prompts.json`; per-asset generation records are in
`art-progress/`. Icons live in `assets/abilities/`, including dedicated signature
files and discovery/evolution files. Existing artwork remains usable until its
replacement is generated and imported.

The completed set contains all 473 original built-in imagegen icons. All 32
champion sheets passed an in-game visual review. PNG validation found no missing
or duplicate images; imported texture checks confirm every current source file.
`tools/skill_art_test.gd` passed 1,420 routing and runtime-size checks.

Original generated PNGs remain at full resolution. Godot imports skill textures
at a maximum of 256 pixels with mipmaps for small UI slots; this reduces runtime
memory and package size without altering the original art files.

`tools/skill_audit_test.gd` checks all 473 actions, normalized channels, readable
tooltips, actual spiderling behavior, AP venom and independent Thunderbird paths.
The prior recruitment, equipment, carousel and hex-combat regressions remain
part of verification. Mirrored build battles are diagnostic fixtures, not a claim
of final competitive balance; this remains a first playtest-ready balance pass.

Final validation passed 4,051 checks across the skill audit, item/recruitment,
hex artillery, navigation, shop/carousel and art integration suites. All 441
learned actions were cast and resolved without failure, and 12 mirrored team
fights completed without timeouts. The exported Windows pack passed the 473-icon
integration check, shop/carousel checks and an arena startup smoke test.
