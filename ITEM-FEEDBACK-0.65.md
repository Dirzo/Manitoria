# Manitoria 0.65 — Item feedback and audio

Every supported equipment ID now has engine feedback: 12 components, 78 forged items and 46 older equipment entries (136 total).

Equipment produces a brief opening signature. Stat bonuses augment the actions they affect: attack damage and attack speed accent successful basics, ability power and cooldown items accent casts, armor and health respond to damage, movement items leave step cues, and dodge, critical chance and control resistance show their successful responses. These subtle cues indicate a stat contribution; they do not claim a conditional proc occurred.

Actual item activations have stronger compositions, a floating item artwork badge, a name and a matching sound. Missing feedback was added to stacking, poison application, healing, reflection, cooldown recovery, immunity, stealth and critical interactions. Existing gameplay effects are preserved rather than adding extra damage or shields for visual purposes.

Ten animation families cover striking, lightning, poison, healing, guards, shadow effects, tempo/cooldown runes, growth vines, fire and arcane effects. Item recipe colors, motifs and identity select the presentation. Giant's Draught retains its larger champion model. Shared effect families are used, rather than 136 separate Meshy models.

Item sounds use the existing game sound library: metal impacts, shield responses, healing tones, lightning, venom, shadow, spirit chimes, fire, nature and holy effects. Wild item activations get stronger gain and higher playback priority. Passive cues are quieter. Simulation-time visual throttles and wall-clock audio gates prevent repeated hits, regeneration and accelerated combat from flooding the presentation. Pause suppresses item audio and freezes item VFX. Effects expire and share the arena's existing 260-object limit.

Presentation hooks do not roll random numbers, alter stats or trigger further items. Item activation counts continue to use item credits in combat metrics; presentation-only opening and stat cues do not add casts.

Validation: 1,228 item feedback/audio checks across all 136 equipment IDs, including paired combat comparisons with presentation on and off; five arena/audio integration checks; 464 skill/item/recruitment checks; 1,863 skill audit checks; and 441 actual skill casts. All passed. Representative item compositions were rendered and visually inspected on the GPU. Packaged verification is reported with the download.

This build includes the prior 174 AD / 174 AP skill balance, all item and skill artwork, new-skill replay, hex combat and shop improvements. Windows saves remain compatible. Source changes are local and have not been pushed to GitHub.
