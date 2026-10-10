# Warden audio and counterplay

Based on native Godot source at `efbc696` (Windows build 0.75.4). The browser editions are separate and unchanged. This branch updates the native source; the checked-in Windows executable/PCK have not been rebuilt.

## Audio findings and changes

The asset audit decodes all 248 shipped audio files, including 70 new Warden cues. All decode, all have a non-silent signal, none have full-scale samples, and none have identical decoded waveforms. This measures decoded sample peaks and RMS: it is not a true-peak/LUFS measurement or a listening assessment on a playback device. Full measurements are in `godot/data/audio-audit.json`; rerun `python3 godot/tools/audit_audio.py` with NumPy and ffmpeg installed.

Before this pass, boss casts selected the same species/family cues as champions, telegraphs were silent, summon events had no cue, and all Warden deaths used the same heavy fall with a slowed champion cry. Each Warden now has original entrance, warning, attack, summon, phase, enrage and death assets. Innate signature casts also use the Warden's attack cue. The shared heavy body fall remains below the new death cry. Clips are mono Vorbis, preloaded, position-panned, gated per boss and routed through existing Effects controls and the master limiter. Warnings have higher priority than ordinary combat and duck music for their warning duration. DoT ticks stay quiet. Summon resolution does not double-play its cast cue.

Rapid ambience changes previously left older tween callbacks alive. Transitions now cancel the previous tween, effects mute stops pending ambience transitions and voice playback, combat pause also pauses ambience and voice, and stop_all stops environmental audio. Battle generation guards prevent a delayed champion death cry leaking into a new fight.

Regenerate only the new original audio with `python3 godot/tools/generate_boss_audio.py`. Asset credits are retained. The original synthesis is deterministic; encoded Vorbis bytes can differ with ffmpeg versions.

## Boss abilities

| Warden | New technique | Threat / counterplay |
| --- | --- | --- |
| Rootmother | Bramble Cage | Roots a marked cluster; spread out or interrupt. |
| Prismatic Archon | Mana Fracture | Marks the strongest caster's position and silences the area. |
| Forge Tyrant | Crucible Brand | Marks the backline and leaves a four-second burning floor. |
| Frost Matriarch | Icebound Prison | Roots the strongest attacker's cluster. |
| Leviathan | Undertow | Pulls distant clustered enemies toward the boss and slows them. |
| Spore Queen | Virulent Bloom | Poisons a marked cluster for four seconds; spread out and sustain. |
| Bone King | Soul Tithe | Targets wounded allies and heals from health damage actually dealt. |
| Tempest Roc | Storm Conductor | Lightning jumps through at most three nearby opponents; spread out. |
| Sun-Eater Pharaoh | Solar Judgment | Backline area hit with a three-second burn. |
| Abyssal Keeper | Rift Collapse | Pulls clustered enemies toward the marked point and weakens them. |

New techniques begin after six eligible simulation seconds and recur on 13–15 second timers. The first cast may be delayed by existing attacks. Every offensive Warden mechanic, including the old slams, pulses and timed summons, has a 1.25-second warning. Only one warning can run at a time; normal attacks stop during it. Target positions remain fixed, so leaving the marked area avoids the hit. Stun or silence cancels a warning and the attempt consumes its cooldown. Timers stop while controlled. Phase shields/enrage remain threshold events; regeneration remains passive.

The cast bar and animation show the warning. Targeted areas have a floor marker whose radius matches the initial damage check; squad-wide pulses use the overhead warning. Scouting tooltips include the new technique and counterplay. AI movement follows the existing tactics; this is an autobattler, so preparation, control timing and mobile formations remain the player's tools. Techniques have separate `boss:*` combat attribution. Champion PvP mechanics and existing Warden stat weights are unchanged. This is a mechanics pass, not a new difficulty calibration.

## Validation

Executed with Godot 4.5.1 headless, rather than the repository's documented 4.7.2 runtime:

- 331 Warden/audio checks: all ten kits, loading/routing all 70 cues, no early hits, locked targets, out-of-area avoidance, statuses, zones and DoTs, interrupting old and new mechanics, muted/paused playback, saturated voice priority, ambience transitions and watched/silent seed parity.
- 33 hex-navigation checks passed.
- 441 existing champion skill casts passed.
- 9 healing/sustain checks passed.
- All 248 audio assets decoded without failure or full-scale samples.
- Godot editor import and script parsing completed; git whitespace checks passed.

Headless tests do not validate the finished Windows executable, human fight difficulty or visual layout on a real display. The repository's existing hex tests emit an ObjectDB leak warning at shutdown despite passing their assertions. No Windows build or browser deployment is claimed. Import the source in the project's supported editor and export the Windows build for distribution.
