# Manitoria 0.78

This release integrates the v0.76 mana-signature/stat-card rework, v0.77 items,
Claude's fluid-combat branch, the Warden/preparation/diagnostics branch, the local
dungeon team drawer and presentation work, and all 91 new item icons.

Attacks use the new forward-playing contact animator. The dungeon map keeps equipment,
crafting, tactics and formation within reach. Warden warnings and interruption mechanics
are included. Music-only playback follows the latest diagnostics branch: nonmusic effects
and announcer cues remain disabled. This integration adds no independent balance pass.

The newer mana-signature and stat-card model replaces the historical four-skill-kit
progression. Historical fresh-skill work is preserved in Git, not reintroduced into the
new progression rules. Old saves use the v0.76 migration.

## Play and narrate

Download the complete [Windows folder](builds/v0.78), run `JOIN-ME.bat`, then
`Manitoria.exe`. Keep the executable and PCK together. For spoken feedback, install
Python 3.14, run `Setup-Narration.cmd` once, then `Narrate-Manitoria.cmd`.
The narration launcher shows MIC REC; F8 pauses/resumes the microphone. Close the game
normally and allow the offline transcription to finish. WAV clips and transcripts stay
in the build folder's `facts-archive/narration/`. Ordinary play never records the microphone.

Structured diagnostic logs remain local and can be exported in Settings. Spoken transcripts
can be inaccurate; check the original WAV before interpreting feedback as a requested change.
Owner acceptance of combat feel, audio and the drawer remains a playtest outcome.

## Verification

Integrated validation: v0.76 save migration (13 checks), v0.77 items, all 416 skill casts, combat animator, fluid-combat performance, saved dungeon progression (11 checks), dungeon smoke (2,008 checks), tournament tour (303 checks), preparation/range (1,763 checks), telemetry (35 checks), recorder RNG parity, dungeon continuation (24 checks), rendered dungeon drawer (58 checks) and four synthetic narration tests passed. The exported Windows executable starts a dungeon fight with no script errors. Recorder teardown reports known resource cleanup warnings; its assertions pass. Signature smoke completed across every species/evolution: NO CASTS: []. Exported-pack narration controls also passed.

