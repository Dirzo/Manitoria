class_name PlayTelemetry
extends Node
## Local, bounded diagnostics. No network calls or raw keyboard/text capture.
const ROOT = "user://play_logs"
const MAX_BYTES = 32 * 1024 * 1024
const KEEP_PARTS = 10
var storage_root = ROOT
var engine_log_path = "user://logs/godot.log"
const FEATURES = ["equipment", "bag", "forge", "recipes", "tactics", "formation", "scouting", "upgrades", "shop", "dungeon", "combat_inspection", "settings"]
var game: Node
var enabled = true
var session = ""
var part = 0
var file: FileAccess
var pending: Array[String] = []
var counts: Dictionary = {}
var features: Dictionary = {}
var screens: Dictionary = {}
var last_screen = ""
var elapsed = 0.0
var since_flush = 0.0
var since_snapshot = 0.0
var worst_frame = 0.0
var frames = 0
var closed = false
var write_failed = false
var engine_offset = 0
var last_error = ""
var since_exposure = 0.0
var last_controls = ""

func _ready() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--qa="): enabled = false
 if not enabled: return
 if DirAccess.make_dir_recursive_absolute(storage_root) != OK:
  write_failed = true; return
 session = str(int(Time.get_unix_time_from_system())) + "_" + Crypto.new().generate_random_bytes(4).hex_encode()
 var previous = JSON.parse_string(FileAccess.get_file_as_string(storage_root + "/active.json")) if FileAccess.file_exists(storage_root + "/active.json") else null
 _prune()
 _open_part()
 _prune()
 _write_json(storage_root + "/active.json", {"session":session, "started_utc":Time.get_datetime_string_from_system(true)})
 for key in FEATURES: features[key] = {"presented":0, "used":0}
 record("session_start", {"diagnostics_build":"range-prep-telemetry-1", "version":ProjectSettings.get_setting("application/config/version"), "engine":Engine.get_version_info(), "os":OS.get_name(), "display":DisplayServer.get_name(), "viewport":get_viewport().get_visible_rect().size, "previous_unclean_session":previous})
 get_tree().node_added.connect(_node_added)
 flush()

func _open_part() -> void:
 if file: file.flush(); file.close()
 file = FileAccess.open(storage_root + "/" + session + "_%03d.jsonl" % part, FileAccess.WRITE)
 if file == null: write_failed = true

func record(kind: String, data: Dictionary = {}) -> void:
 if not enabled or closed or write_failed: return
 counts[kind] = int(counts.get(kind, 0)) + 1
 pending.append(JSON.stringify({"schema":1, "session":session, "seconds":snappedf(elapsed, .001), "utc":Time.get_datetime_string_from_system(true), "event":kind, "phase":str(game.phase) if is_instance_valid(game) else "", "data":_safe(data)}))
 if pending.size() >= 128: flush()

func _safe(value: Variant) -> Variant:
 if value is Dictionary:
  var out = {}
  for key in value: out[str(key)] = _safe(value[key])
  return out
 if value is Array:
  var out = []
  for entry in value: out.append(_safe(entry))
  return out
 if value is Vector2 or value is Vector2i: return [value.x, value.y]
 if value is Vector3 or value is Vector3i: return [value.x, value.y, value.z]
 if value is Object or value is Callable: return "<runtime object>"
 return value

func feature(key: String, used: bool = false) -> void:
 if not enabled or not features.has(key): return
 var field = "used" if used else "presented"
 features[key][field] += 1
 record("feature_" + field, {"feature":key})

func _feature_key(button: BaseButton) -> String:
 var value = (str(button.name) + " " + str(button.get("text"))).to_lower()
 for pair in [["recipe","recipes"],["forge","forge"],["equipment","equipment"],["bag","bag"],["tactic","tactics"],["scout","scouting"],["upgrade","upgrades"],["shop","shop"],["dungeon","dungeon"],["settings","settings"]]:
  if pair[0] in value: return pair[1]
 return ""

func _node_added(node: Node) -> void:
 if node is BaseButton:
  node.ready.connect(func(): _hook_button(node), CONNECT_ONE_SHOT)

func _hook_button(button: BaseButton) -> void:
 if not is_instance_valid(button): return
 # Exposure is observed only once the control is actually visible and usable.
 button.set_meta("play_log_exposed", false)
 button.pressed.connect(func():
  if not is_instance_valid(button): return
  var key = _feature_key(button)
  record("ui_action", {"control":str(button.name), "label":str(button.get("text")), "feature":key})
  if key != "": feature(key, true)
  call_deferred("snapshot", "ui_action"))

func screen(phase_name: String, tab_name: String) -> void:
 if not enabled: return
 if is_instance_valid(game):
  var controls = str([game.paused, game.speed, game.tactical])
  if controls != last_controls:
   last_controls = controls
   record("combat_controls", {"paused":game.paused,"speed":game.speed,"tactical":game.tactical})
 var key = phase_name + "/" + tab_name
 if key == last_screen: return
 last_screen = key
 screens[key] = int(screens.get(key, 0)) + 1
 record("screen", {"screen":key})
 if phase_name == "prep": feature("formation"); feature("equipment")
 if phase_name == "upgrade": feature("upgrades")
 call_deferred("snapshot", "screen")

func snapshot(reason: String = "periodic") -> void:
 if not enabled or not is_instance_valid(game): return
 if game.resolving and game.phase == "battle":
  record("snapshot_deferred", {"reason":reason, "resolving_results":true}); return
 var state: Dictionary = game.campaign.state
 var data = {"reason":reason, "campaign":state, "tab":game.tab, "selected":game.selected_id, "paused":game.paused, "speed":game.speed, "tactical":game.tactical, "campaign_error":game.campaign.last_error}
 if game.sim != null:
  data["battle"] = {"time":game.sim.time, "winner":game.sim.winner, "units":game.sim.units}
 record("snapshot", data)

func _process(dt: float) -> void:
 if not enabled or closed: return
 elapsed += dt; since_flush += dt; since_snapshot += dt
 worst_frame = maxf(worst_frame, dt); frames += 1
 since_exposure += dt
 if since_exposure >= 1.0 and is_instance_valid(game) and is_instance_valid(game.ui):
  since_exposure = 0.0
  for button in game.ui.find_children("*", "BaseButton", true, false):
   var key = _feature_key(button)
   if key != "" and not button.get_meta("play_log_exposed", false) and button.is_visible_in_tree() and not button.disabled:
    button.set_meta("play_log_exposed", true); feature(key)
 if since_flush >= 2.0:
  _read_engine_errors(); flush(); since_flush = 0.0
 if since_snapshot >= 15.0:
  record("performance", {"fps":Engine.get_frames_per_second(), "frames":frames, "worst_frame_ms":worst_frame * 1000, "memory_bytes":OS.get_static_memory_usage()})
  snapshot(); since_snapshot = 0.0; worst_frame = 0.0; frames = 0
  _write_json(storage_root + "/" + session + "_summary.json", summary())

func _read_engine_errors() -> void:
 if is_instance_valid(game) and game.campaign.last_error != last_error:
  last_error = game.campaign.last_error
  if last_error != "": record("campaign_error", {"message":last_error}); snapshot("campaign_error")
 var log_file = FileAccess.open(engine_log_path, FileAccess.READ)
 if log_file == null: return
 if engine_offset > log_file.get_length(): engine_offset = 0
 log_file.seek(engine_offset)
 var lines: Array[String] = []
 var scan_end = mini(log_file.get_length(), engine_offset + 65536)
 while not log_file.eof_reached() and log_file.get_position() < scan_end and lines.size() < 200:
  var line = log_file.get_line()
  if "ERROR" in line or "WARNING" in line or "   at:" in line: lines.append(line)
 engine_offset = log_file.get_position()
 if not lines.is_empty():
  record("engine_diagnostic", {"lines":lines})
  snapshot("engine_diagnostic")

func flush() -> void:
 if file == null: pending.clear(); return
 for line in pending:
  file.store_line(line)
 pending.clear(); file.flush()
 if file.get_error() != OK: write_failed = true
 if file.get_position() >= MAX_BYTES:
  part += 1; _open_part(); _prune()

func summary() -> Dictionary:
 var unused = []; var unseen = []
 for key in features:
  if features[key].used == 0:
   if features[key].presented > 0: unused.append(key)
   else: unseen.append(key)
 return {"schema":1, "session":session, "seconds":elapsed, "clean_exit":closed, "events":counts, "screens":screens, "features":features, "seen_but_unused":unused, "not_observed":unseen, "write_failed":write_failed}

func export_bundle() -> String:
 if not enabled or write_failed: return ""
 record("export_requested"); snapshot("export"); flush()
 _write_json(storage_root + "/" + session + "_summary.json", summary())
 var export_dir = "user://play_log_exports"
 if DirAccess.make_dir_recursive_absolute(export_dir) != OK: return ""
 var path = export_dir + "/manitoria_play_" + session + ".zip"
 var zip = ZIPPacker.new()
 if zip.open(path) != OK: return ""
 var failed = false
 for name in DirAccess.get_files_at(storage_root):
  if name.ends_with(".jsonl") or name.ends_with("_summary.json"):
   if zip.start_file("play_logs/" + name) != OK: failed = true; break
   if zip.write_file(FileAccess.get_file_as_bytes(storage_root + "/" + name)) != OK: failed = true
   if zip.close_file() != OK: failed = true
 for name in DirAccess.get_files_at("user://logs"):
  if name.begins_with("godot"):
   if zip.start_file("engine/" + name) != OK: failed = true; break
   if zip.write_file(FileAccess.get_file_as_bytes("user://logs/" + name)) != OK: failed = true
   if zip.close_file() != OK: failed = true
 if zip.close() != OK: failed = true
 if failed:
  DirAccess.remove_absolute(path); return ""
 return ProjectSettings.globalize_path(path)

func finish() -> void:
 if closed or not enabled: return
 _read_engine_errors(); snapshot("exit"); record("session_end"); flush(); closed = true
 _write_json(storage_root + "/" + session + "_summary.json", summary())
 var marker = JSON.parse_string(FileAccess.get_file_as_string(storage_root + "/active.json")) if FileAccess.file_exists(storage_root + "/active.json") else null
 if marker is Dictionary and marker.get("session") == session: DirAccess.remove_absolute(storage_root + "/active.json")
 if file: file.close(); file = null

func _exit_tree() -> void:
 finish()

func _write_json(path: String, data: Dictionary) -> void:
 var output = FileAccess.open(path, FileAccess.WRITE)
 if output:
  output.store_string(JSON.stringify(_safe(data)))
  if output.get_error() != OK: write_failed = true
  output.close()
 else: write_failed = true

func _prune() -> void:
 var names: Array[String] = []
 for name in DirAccess.get_files_at(storage_root):
  if name.ends_with(".jsonl"): names.append(name)
 names.sort()
 # Ten bounded parts total, including prior sessions, approximately 320 MB maximum.
 while names.size() > KEEP_PARTS:
  var name = names.pop_front(); DirAccess.remove_absolute(storage_root + "/" + name)
 var sessions = {}
 for name in names: sessions[name.get_slice("_", 0) + "_" + name.get_slice("_", 1)] = true
 for name in DirAccess.get_files_at(storage_root):
  if name.ends_with("_summary.json") and not sessions.has(name.trim_suffix("_summary.json")):
   DirAccess.remove_absolute(storage_root + "/" + name)
