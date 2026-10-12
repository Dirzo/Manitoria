class_name PlaytestRecorder
extends Node
## Opt-in local facts. Observes state; never uses gameplay RNG or writes campaign data.
var enabled = false
var session = ""
var build = ""
var archive = ""
var actor_class = "human"
var game: Node
var actors = {}
var next_actor = 2
var battle_number = 0
var battle_instance = 0
var lines = PackedStringArray()
var bytes = 0
var flush_age = 0.0
var snapshot_age = 0.0
var performance_age = 0.0
var sequence = 0
var worker: Thread
var inflight = PackedStringArray()
var failed = false
var spent_usec = 0
var last_input = 0
var previous_phase = ""
var previous_choices = ""
var narration_folder = ""
var narration_label: Label
var narration_age = 0.0

func start(owner: Node, directory: String, automated: bool = false) -> bool:
 game = owner; archive = directory; actor_class = "agent" if automated else "human"
 if DirAccess.make_dir_recursive_absolute(archive) != OK: return false
 var identity = Crypto.new().generate_random_bytes(16).hex_encode()
 session = identity; last_input = Time.get_ticks_msec()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--playtest-session="):
   var requested = arg.trim_prefix("--playtest-session=")
   var valid = requested.length()==32
   for character in requested: valid = valid and character in "0123456789abcdef"
   if valid: session = requested
 var stamp = "res://data/playtest-build.json"
 if not FileAccess.file_exists(stamp): push_error("Generate playtest-build.json before recording."); return false
 var metadata = JSON.parse_string(FileAccess.get_file_as_string(stamp))
 if not metadata is Dictionary or not metadata.has("build"): return false
 build = metadata.build; enabled = true
 record("session_start",{"schema":1,"game_version":ProjectSettings.get_setting("application/config/version")})
 if "--narration" in OS.get_cmdline_user_args() and not automated:
  narration_folder = archive.path_join("narration").path_join(session)
  var overlay = CanvasLayer.new(); overlay.layer = 100; add_child(overlay)
  narration_label = Label.new(); overlay.add_child(narration_label)
  narration_label.position = Vector2(580,6); narration_label.text = "MIC STARTING · F8 PAUSE"
  narration_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  narration_label.add_theme_font_size_override("font_size",16)
  narration_label.add_theme_color_override("font_outline_color",Color.BLACK)
  narration_label.add_theme_constant_override("outline_size",4)
 return true

func record(kind: String, data: Dictionary = {}, actor: int = 1, who: String = "") -> void:
 if not enabled or failed: return
 var started = Time.get_ticks_usec()
 var fact = data.duplicate(true)
 fact.merge({"kind":kind,"t":int(Time.get_unix_time_from_system()*1000),"session":session,"build":build,"actor":str(actor),"who":actor_class if who.is_empty() else who,"schema":1,"phase":game.phase,"mode":"dungeon" if Dungeon.active(game.campaign) else "tournament","seq":sequence},true)
 sequence += 1
 var line = JSON.stringify(fact); lines.append(line); bytes += line.to_utf8_buffer().size()+1
 spent_usec += Time.get_ticks_usec()-started

func unit_actor(u: Dictionary) -> int:
 var key = str(battle_number)+":"+str(u.uid)
 if not actors.has(key): actors[key] = next_actor; next_actor += 1
 return actors[key]

func combat(e: Dictionary, sim: BattleSim) -> void:
 if not enabled: return
 if sim.get_instance_id() != battle_instance:
  battle_instance = sim.get_instance_id(); battle_number += 1
  record("battle_start",{"battle":battle_number,"seed":sim.battle_seed})
 var u = sim.find_unit(int(e.get("source",e.get("uid",-1))))
 var actor = unit_actor(u) if not u.is_empty() else 1
 var data = {"battle":battle_number,"sim_time":sim.time}
 # Explicit allowlist excludes player-chosen names and free text.
 for key in ["amount","effect","credit","rarity","count","stage","item_id","heavy","small"]:
  if e.has(key): data[key] = e[key]
 for key in ["pos","target"]:
  if e.get(key) is Vector2: data[key] = [e[key].x,e[key].y]
 if not u.is_empty(): data.species = u.hero.sp; data.team = u.team
 var victim = sim.find_unit(int(e.get("uid",-1)))
 if e.type in ["hit","blocked","heal"] and not victim.is_empty(): data.target_actor = str(unit_actor(victim))
 record("combat_"+str(e.type),data,actor,"agent" if actor_class=="agent" else "bot" if not u.is_empty() else "system")

func choices() -> Array:
 var roster = []
 for h in game.campaign.state.get("roster",[]):
  roster.append({"species":h.sp,"level":h.level,"slot":h.slot,"equipment":h.get("equipment",{}),"learned":h.learned,"signature_rank":h.signature_rank,"tactics":h.get("tactics",{}),"evolution":h.get("evolution",""),"stats":HeroData.stats(h)})
 return roster

func screen() -> void:
 if not enabled: return
 if game.phase != previous_phase:
  record("phase",{"from":previous_phase,"to":game.phase}); previous_phase = game.phase
 var current = JSON.stringify(choices())
 if current != previous_choices:
  previous_choices = current
  record("roster",{"champions":choices(),"gold":game.campaign.state.get("gold",0)})

func input(event: InputEvent) -> void:
 if not enabled: return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F8 and not narration_folder.is_empty():
  var path = narration_folder.path_join("control.json")
  var request = FileAccess.open(path+".tmp",FileAccess.WRITE)
  if request:
   request.store_string(JSON.stringify({"id":Time.get_ticks_usec()}))
   var ok = request.get_error()==OK; request.close()
   if not ok or DirAccess.rename_absolute(path+".tmp",path)!=OK:
    push_error("Could not send microphone pause request.")
    record("narration_error",{"stage":"control","reason":"request_write_failed"})
  else:
   push_error("Could not send microphone pause request.")
   record("narration_error",{"stage":"control","reason":"request_open_failed"})
  record("narration_control",{"action":"toggle_requested"})
 if event is InputEventMouseButton:
  last_input = Time.get_ticks_msec()
  record("input",{"button":event.button_index,"pressed":event.pressed,"p":[event.position.x,event.position.y]})
 elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_ESCAPE,KEY_ENTER,KEY_1,KEY_2,KEY_4,KEY_F11]:
  last_input = Time.get_ticks_msec(); record("input",{"key":event.keycode})

func snapshot(elapsed: float) -> void:
 var units = []
 if game.sim:
  for u in game.sim.units:
   units.append({"actor":str(unit_actor(u)),"species":u.hero.sp,"team":u.team,"p":[u.pos.x,u.pos.y],"hp":u.hp,"shield":u.shield,"cooldown":u.cd,"alive":u.alive,"status":u.status})
 var engaged = actor_class=="human" and DisplayServer.window_is_focused() and ((game.phase=="battle" and not game.paused) or Time.get_ticks_msec()-last_input<60000)
 record("snapshot",{"units":units,"battle":battle_number,"sim_time":game.sim.time if game.sim else 0,"gold":game.campaign.state.get("gold",0),"speed":game.speed,"paused":game.paused,"exposure_seconds":elapsed if engaged else 0})

func _process(dt: float) -> void:
 if not enabled: return
 if narration_label:
  narration_age += dt
  if narration_age >= .5:
   narration_age = 0
   var status_path = narration_folder.path_join("status.json")
   if FileAccess.file_exists(status_path):
    var status = JSON.parse_string(FileAccess.get_file_as_string(status_path))
    if status is Dictionary:
     var state = str(status.get("state","error"))
     if int(Time.get_unix_time_from_system()*1000)-int(status.get("updated_ms",0))>5000: state="error"
     narration_label.text = "MIC REC · F8 PAUSE" if state=="recording" else "MIC PAUSED · F8 RESUME" if state=="paused" else "MIC OFF · CHECK RECORDER"
     narration_label.modulate = Color("ff7777") if state=="recording" else Color("ffd36e")
 poll_worker()
 snapshot_age += dt; performance_age += dt; flush_age += dt
 if snapshot_age >= 1:
  snapshot(snapshot_age); snapshot_age = 0
 if performance_age >= 30:
  record("performance",{"fps":Engine.get_frames_per_second(),"process_seconds":Performance.get_monitor(Performance.TIME_PROCESS),"recorder_usec":spent_usec}); performance_age = 0; spent_usec = 0
 if bytes >= 2097152 or flush_age >= 300: flush()

func write_chunk(path: String, payload: PackedByteArray) -> bool:
 var f = FileAccess.open(path+".partial",FileAccess.WRITE)
 if f == null: return false
 f.store_buffer(payload.compress(FileAccess.COMPRESSION_GZIP)); f.flush()
 var ok = f.get_error()==OK; f.close()
 return ok and DirAccess.rename_absolute(path+".partial",path)==OK

func poll_worker() -> void:
 if worker == null or worker.is_alive(): return
 var ok = worker.wait_to_finish(); worker = null
 if not ok:
  lines = inflight + lines; failed = true
  push_error("Playtest archive write failed; recording stopped. Buffered facts retained until exit.")
 inflight = PackedStringArray()

func flush() -> void:
 poll_worker()
 if worker != null or lines.is_empty() or failed: return
 inflight = lines; lines = PackedStringArray(); bytes = 0; flush_age = 0
 var path = archive.path_join("%013d-%s-%06d.jsonl.gz"%[int(Time.get_unix_time_from_system()*1000),session,sequence])
 worker = Thread.new()
 var error = worker.start(write_chunk.bind(path,("\n".join(inflight)+"\n").to_utf8_buffer()))
 if error != OK: worker = null; lines = inflight + lines; inflight = PackedStringArray(); failed = true

func finish() -> void:
 if not enabled: return
 record("session_end",{"recorder_usec":spent_usec})
 if worker != null:
  if not worker.wait_to_finish(): lines = inflight + lines
  worker = null; inflight = PackedStringArray()
 # Previously failed buffers remain visible as a diagnostic; never silently claim success.
 if not lines.is_empty():
  var path = archive.path_join("%013d-%s-end.jsonl.gz"%[int(Time.get_unix_time_from_system()*1000),session])
  if not write_chunk(path,("\n".join(lines)+"\n").to_utf8_buffer()): push_error("Playtest final archive write failed.")
 enabled = false

func _exit_tree() -> void: finish()
