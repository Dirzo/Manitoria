extends SceneTree
var failures = 0
var checks = 0
class FakeGame extends Node:
 var campaign = Campaign.new()
 var phase = "prep"
 var tab = "roster"
 var selected_id = "test"
 var paused = false
 var speed = 1.0
 var tactical = false
 var resolving = false
 var sim = null
 var ui: Control
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game = FakeGame.new(); root.add_child(game)
 game.ui = Control.new(); game.add_child(game.ui)
 game.campaign.state = {"seed":42,"roster":[{"id":"test","equipment":{"0":"blade"}}]}
 var logger = PlayTelemetry.new(); logger.game = game
 logger.storage_root = "user://telemetry_test_" + str(Time.get_ticks_usec())
 game.add_child(logger)
 check(logger.file != null, "Session file opened")
 logger.record("combat", {"type":"damage", "pos":Vector2(2,3), "value":19})
 logger.screen("prep","roster"); logger.screen("prep","roster")
 check(logger.screens["prep/roster"] == 1, "Repeated render is not a screen visit")
 var button = Button.new(); game.ui.add_child(button); button.text = "Recipe book"
 await process_frame
 logger._process(1.1)
 check(logger.features.recipes.presented > 0, "Visible control records exposure")
 button.pressed.emit()
 check(logger.features.recipes.used == 1, "Click records actual usage")
 var hidden = Button.new(); hidden.text = "Forge"; hidden.visible = false; game.ui.add_child(hidden)
 await process_frame; logger._process(1.1)
 check(logger.features.forge.presented == 0, "Hidden feature is not counted as seen")
 logger.feature("bag")
 check("bag" in logger.summary().seen_but_unused, "Seen unused feature distinguished")
 check("forge" in logger.summary().not_observed, "Unseen feature distinguished")
 logger.engine_log_path = logger.storage_root + "/engine_fixture.log"
 var engine_fixture = FileAccess.open(logger.engine_log_path, FileAccess.WRITE)
 engine_fixture.store_string("SCRIPT ERROR: example failure\n   at: fake_scene.gd:12\n"); engine_fixture.close()
 logger._read_engine_errors()
 check(logger.counts.get("engine_diagnostic",0) == 1, "Engine errors captured with context")
 logger.snapshot("test")
 game.resolving = true; game.phase = "battle"; logger.snapshot("worker"); game.resolving = false; game.phase = "prep"
 check(logger.counts.snapshot_deferred == 1, "Avoid reading state while result worker mutates it")
 logger.flush()
 var text = FileAccess.get_file_as_string(logger.storage_root + "/" + logger.session + "_000.jsonl")
 var found_combat = false; var found_state = false
 for line in text.strip_edges().split("\n"):
  var event = JSON.parse_string(line)
  check(event is Dictionary, "Each event is valid JSON")
  if event.event == "combat": found_combat = event.data.pos[0] == 2 and event.data.pos[1] == 3 and event.data.value == 19
  if event.event == "snapshot": found_state = event.data.campaign.seed == 42
 check(found_combat, "Combat vectors serialized as coordinates")
 check(found_state, "Reproduction state included")
 # Force rollover without writing 32 MB; exercise the same part opening and retention path.
 logger.file.seek(PlayTelemetry.MAX_BYTES); logger.flush()
 check(logger.part == 1, "Size limit rotates file")
 var path = logger.export_bundle()
 var zip = ZIPReader.new()
 check(not path.is_empty() and zip.open(path) == OK, "Export is a readable ZIP")
 check(zip.get_files().has("play_logs/" + logger.session + "_summary.json"), "ZIP includes usage summary")
 var summary = JSON.parse_string(zip.read_file("play_logs/" + logger.session + "_summary.json").get_string_from_utf8())
 check("bag" in summary.seen_but_unused, "Export preserves unused features")
 zip.close(); DirAccess.remove_absolute(path)
 # Simulate interrupted previous session: leave active marker and create another recorder.
 logger.flush(); logger.file.close(); logger.file = null; logger.closed = true
 var recovered = PlayTelemetry.new(); recovered.game = game; recovered.storage_root = logger.storage_root
 game.add_child(recovered)
 var events = FileAccess.get_file_as_string(recovered.storage_root + "/" + recovered.session + "_000.jsonl").strip_edges().split("\n")
 var start = JSON.parse_string(events[0])
 check(start.data.previous_unclean_session.session == logger.session, "Interrupted session recovered at next launch")
 recovered.finish()
 for index in range(12):
  var old = FileAccess.open(logger.storage_root + "/0000_old_%03d.jsonl" % index, FileAccess.WRITE); old.store_line("{}"); old.close()
 recovered._prune()
 var parts = 0
 for name in DirAccess.get_files_at(logger.storage_root):
  if name.ends_with(".jsonl"): parts += 1
 check(parts <= PlayTelemetry.KEEP_PARTS, "Old log parts pruned to retention limit")
 check(not FileAccess.file_exists(recovered.storage_root + "/active.json"), "Clean exit removes marker")
 var clean = JSON.parse_string(FileAccess.get_file_as_string(recovered.storage_root + "/" + recovered.session + "_summary.json"))
 check(clean.clean_exit, "Clean exit in report")
 for name in DirAccess.get_files_at(logger.storage_root): DirAccess.remove_absolute(logger.storage_root + "/" + name)
 DirAccess.remove_absolute(logger.storage_root)
 game.queue_free(); await process_frame
 print("PLAY TELEMETRY: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
