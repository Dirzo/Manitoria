# Local play diagnostics

The native Godot source now starts a recorder for normal play. It never uploads logs. The previously exported Windows executable must be rebuilt to include this change.

In **Settings → Export play logs**, export a ZIP, then attach it to the conversation. The game opens the export folder and copies the path to the clipboard. Tell us what felt wrong and roughly when it happened. The ZIP includes recent sessions, so a restart after a crash preserves useful evidence. This assistant cannot automatically watch the installation on Beast Edit or read its files.

Recorded evidence:

- Screen/tab changes and button actions; visible, enabled feature controls and their use. The summary separates `seen_but_unused` from `not_observed`. Counts describe observed controls/actions, not proof that a player understood a feature.
- Equipment transfers, formation changes, selected champions, pause/speed/tactical controls, and UI feedback.
- Every battle action emitted by the simulation, battle seed/quality/modifiers, opening and closing state, and final report rows. Background bracket simulations remain in the existing Run Atlas; this recorder observes the active match.
- Campaign state and live unit snapshots on screen/action changes, battle boundaries, errors, exit, and every 15 seconds. State includes game-created names, roster, inventory, dungeon progress and run seeds. It is useful reproduction context, not a frame-perfect replay.
- Fifteen-second performance samples (FPS, worst frame, engine memory), Godot error/warning breadcrumbs, and the original engine logs, including stack traces. An unfinished session marker indicates an unclean exit or another still-running instance; it cannot establish the cause by itself.

No raw keyboard stream, screenshots, microphone recording, unrelated computer files, credentials, or network upload. Button labels and game state can contain custom club/champion names: review the ZIP before sharing it externally.

Files live under Godot's Manitoria user-data directory: `play_logs/` and `play_log_exports/`. On Windows this is normally `%APPDATA%/Godot/app_userdata/Manitoria — The Living Arena/`. JSONL has schema 1 and contains an event type, session ID, elapsed seconds, UTC timestamp, phase and structured data. Each session also has a readable JSON usage summary.

The recorder buffers writes, flushes every two seconds or 128 events, and rotates at 32 MiB per part. It retains ten log parts total (approximately 320 MiB plus the last event and small summaries), pruning older parts. Explicitly exported ZIPs and Godot's five engine log files are separate from this budget. The final buffered seconds can be lost in a hard crash. On disk failure the recorder stops without stopping gameplay, and export reports failure. Logging is disabled for `--qa=` runs. Full-state snapshots are deferred while the results worker mutates campaign state.

## Validation

Run from the repository root:

```
Godot --headless --path godot --script res://tools/play_telemetry_test.gd
Godot --headless --path godot --script res://tools/range_prep_test.gd -- --qa=dungeon_fight
```

The diagnostics test checks JSON event/state serialization, visible/hidden feature classification, actual usage, screen deduplication, engine error capture, worker snapshot deferral, file rollover, retention, ZIP contents, interrupted-session recovery and clean exit. Tested with Godot 4.5.1 headless; a native Windows playthrough/export remains to be verified on Beast Edit.
