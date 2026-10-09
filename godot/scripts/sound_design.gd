class_name SoundDesign
extends Node

const SPECIES_FAMILY = {"minotaur":"beast", "golem":"stone", "troll":"stone", "wendigo":"shadow", "direwolf":"beast", "manticore":"venom", "griffin":"wing", "kitsune":"spirit", "wyvern":"venom", "harpy":"wing", "phoenix":"fire", "kirin":"lightning", "basilisk":"venom", "treant":"nature", "naga":"water", "unicorn":"holy", "cerberus":"beast", "nemean":"beast", "yeti":"ice", "zaratan":"shield", "owlbear":"claw", "hydra":"nature", "chimera":"fire", "gargoyle":"stone", "nekomata":"shadow", "jackalope":"nature", "cyclops":"quake", "thunderbird":"lightning", "sphinx":"spirit", "pegasus":"wing", "arachne":"venom", "salamander":"fire"}
const EFFECT_FAMILY = {"gore":"beast", "bulwark":"shield", "smash":"stone", "hunger":"shadow", "howl":"beast", "venom":"venom", "skystrike":"wing", "foxfire":"spirit", "acid":"venom", "shriek":"wing", "flamewave":"fire", "chain":"lightning", "gaze":"venom", "rootbloom":"nature", "tidal":"water", "radiance":"holy", "triplebite":"claw", "prideroar":"beast", "frostroar":"ice", "shellup":"shield", "maul":"claw", "regrowth":"nature", "threefold":"fire", "stonedive":"stone", "vanish":"shadow", "antlerrush":"nature", "boulder":"quake", "stormcall":"lightning", "riddle":"spirit", "tailwind":"wing", "brood":"venom", "magma":"fire", "quake":"quake", "ward":"shield", "meteor":"quake", "renew":"heal", "drain":"shadow", "fear":"shadow", "ambush":"claw", "toxic":"venom", "execute":"metal", "gust":"wing", "wisps":"spirit", "barrage":"bow", "silence":"shadow", "beam":"holy", "storm":"lightning", "frost":"ice", "roots":"nature", "fire":"fire", "whirl":"metal", "fissure":"stone", "rally":"holy", "rebirth":"fire"}
const MUSIC_GAIN = {"club": -2.0, "preparation": -1.0, "arena": -4.0, "battle": -3.0, "shop": -1.0, "intro": -3.5, "zone": -3.0}
## Title theme and one song per dungeon zone (files normalised to -16 LUFS). A zone's song plays
## through its map, formation, fights and results; the outfitter keeps the shop playlist.
const TITLE_TRACK := "intro"
const ZONE_TRACKS := ["blight_forest", "mana_caverns", "magma_depths", "frostbound_crypt", "drowned_sanctum", "fungal_hollows", "ossuary_of_kings", "storm_spire", "gilded_tomb", "void_rift"]
## "Unleash War Spirits": three battle tracks, each an opening that falls into a seamless loop
## (seconds into the file where the loop restarts).
const BATTLE_TRACKS := {"battle_1": 28.55, "battle_2": 35.96, "battle_3": 0.0}
## Fantasy shopkeeper songs: played as a playlist that crossfades from one song to the next.
const SHOP_TRACKS := ["shop_1", "shop_2", "shop_3", "shop_4", "shop_5"]
const SHOP_CROSSFADE := 4.0
var battle_index := -1
var shop_index := -1
var music_player: AudioStreamPlayer
var music_players: Array = []
var active_music = 0
var effects_enabled = true:
 set(value):
  effects_enabled = value
  if not value:
   for voice in voices: voice.stop()
var music_enabled = true
var scene_name = ""
var cache: Dictionary = {}
var music_cache: Dictionary = {}
var voices: Array = []
var voice_priorities: Array = []
var music_transition: Tween
var last_event: Dictionary = {}
var combat_paused = false
var duck_remaining = 0.0
var music_mix = -6.0
var effects_mix = -6.0
var played_cues = 0
var last_cue = ""

func _ready() -> void:
 for i in range(2):
  var player = AudioStreamPlayer.new(); player.bus = "Music"; player.volume_db = -50; add_child(player); music_players.append(player)
 music_player = music_players[0]
 for i in range(8):
  var player = AudioStreamPlayer2D.new(); player.bus = "Effects"; player.max_distance = 3000; player.attenuation = 0.2; player.panning_strength = 0.8
  add_child(player); voices.append(player); voice_priorities.append(0)
 for track in ["club", "preparation", "arena"]:
  # "Glory of the Arena" — club theme (full song), pre-fight intro loop, battle climax loop.
  var path = "res://assets/audio/" + track + ".ogg"
  if ResourceLoader.exists(path):
   var stream = load(path).duplicate()
   stream.loop = true
   music_cache[track] = stream
 for track in BATTLE_TRACKS:
  var bp = "res://assets/audio/music/" + track + ".ogg"
  if ResourceLoader.exists(bp):
   var bs = load(bp).duplicate(); bs.loop = true; bs.loop_offset = BATTLE_TRACKS[track]; music_cache[track] = bs
 for track in [TITLE_TRACK] + ZONE_TRACKS.map(func(z): return "zone_" + z):
  var zp = "res://assets/audio/music/" + track + ".ogg"
  if ResourceLoader.exists(zp):
   var zs = load(zp).duplicate(); zs.loop = true; music_cache[track] = zs
 for track in SHOP_TRACKS:
  var sp = "res://assets/audio/music/" + track + ".ogg"
  if ResourceLoader.exists(sp):
   var ss = load(sp).duplicate(); ss.loop = false; music_cache[track] = ss
 # Decode/load outside combat so the first spell cannot stall a fight.
 var keys = []
 var families = []
 for family in EFFECT_FAMILY.values():
  if family not in families: families.append(family)
 for family in families:
  for prefix in ["", "attack_", "charge_", "death_"]: keys.append(prefix + family)
 for species in SPECIES_FAMILY: keys.append("hero_" + species)
 keys.append_array(["contest_reveal", "contest_lock", "contest_versus", "victory", "honor", "upgrade", "multikill", "arena_gate", "interrupt", "impact_flesh", "impact_stone", "impact_metal", "impact_arcane", "ui_hover", "ui_click", "ui_open", "ui_close"])
 # Enumerate logical resource paths: exported WAVs have .import sidecars,
 # unlike their loose source files. ResourceLoader resolves either form.
 for key in keys:
  var path = "res://assets/audio/fx/" + key + ".wav"
  if ResourceLoader.exists(path): cache[key] = load(path)
  else: push_error("Missing combat audio: " + path)
 setup_announcer()
 load_settings()
 print("Audio loaded: ", music_cache.size(), " tracks; ", cache.size(), " effects")
 var master = AudioServer.get_bus_index("Master")
 if AudioServer.get_bus_effect_count(master) == 0:
  var limiter = AudioEffectLimiter.new(); limiter.ceiling_db = -1.0; limiter.threshold_db = -2.0
  AudioServer.add_bus_effect(master, limiter)
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_mix)
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), effects_mix)

static func music_for_phase(phase: String) -> String:
 return "arena" if phase == "battle" else "preparation" if phase in ["prep","intro"] else "shop" if phase == "shop" else "club"

## Scene names map to concrete tracks: every battle picks the next war track, the shop runs its playlist.
func resolve_track(which: String) -> String:
 if which == "arena":
  var keys = BATTLE_TRACKS.keys().filter(func(k): return music_cache.has(k))
  if keys.is_empty(): return "arena"
  if scene_name.begins_with("battle_"): return scene_name
  battle_index = (battle_index + 1 + randi() % 2) % keys.size() if battle_index >= 0 else randi() % keys.size()
  return keys[battle_index]
 if which == "shop":
  var songs = SHOP_TRACKS.filter(func(k): return music_cache.has(k))
  if songs.is_empty(): return "club"
  if scene_name.begins_with("shop_"): return scene_name
  shop_index = (shop_index + 1) % songs.size() if shop_index >= 0 else randi() % songs.size()
  return songs[shop_index]
 return which

func gain_for(track: String) -> float:
 return MUSIC_GAIN.get("battle" if track.begins_with("battle_") else "shop" if track.begins_with("shop_") else "zone" if track.begins_with("zone_") else track, 0.0)

func scene_music(which: String) -> void:
 which = resolve_track(which)
 if scene_name == which or not music_cache.has(which): return
 _crossfade_to(which)

func _crossfade_to(which: String) -> void:
 if not music_cache.has(which): return
 if (scene_name == "arena" or scene_name.begins_with("battle_")) and not (which == "arena" or which.begins_with("battle_")):
  for voice in voices: voice.stop()
  last_event.clear()
 var previous_scene = scene_name
 scene_name = which
 if music_transition: music_transition.kill()
 var next = 1 - active_music
 for i in range(2):
  if music_players[i].stream == music_cache[which]: next = i
 var incoming = music_players[next]; var outgoing = music_players[1 - next]
 if incoming.stream != music_cache[which]: incoming.stop(); incoming.stream = music_cache[which]; incoming.volume_db = -50
 active_music = next; music_player = incoming
 if not music_enabled: return
 var aligned = previous_scene in ["preparation", "arena"] and which in ["preparation", "arena"]
 var song_to_song = which.begins_with("shop_") and previous_scene.begins_with("shop_")
 # Song-to-song in the shop overlaps (a DJ-style blend); entering or leaving the shop eases over 2 s.
 var fade_time = SHOP_CROSSFADE if song_to_song else (2.0 if which.begins_with("shop_") or previous_scene.begins_with("shop_") else 1.1)
 aligned = aligned or song_to_song
 if not incoming.playing:
  incoming.play(outgoing.get_playback_position() if aligned and not song_to_song and outgoing.playing else 0.0)
 var start_in = db_to_linear(incoming.volume_db); var start_out = db_to_linear(outgoing.volume_db)
 var target_gain = db_to_linear(gain_for(which))
 music_transition = create_tween()
 music_transition.tween_method(func(t):
  # Aligned stems use a linear blend; unrelated music fades through silence.
  var blend_in = t if aligned else maxf(0.0, (t - 0.5) * 2.0)
  var blend_out = 1.0 - t if aligned else maxf(0.0, 1.0 - t * 2.0)
  incoming.volume_db = linear_to_db(maxf(0.0001, lerpf(start_in, target_gain, blend_in)))
  outgoing.volume_db = linear_to_db(maxf(0.0001, start_out * blend_out)), 0.0, 1.0, fade_time)
 music_transition.tween_callback(func(): outgoing.stop())

func set_music(enabled: bool) -> void:
 music_enabled = enabled
 if music_transition: music_transition.kill()
 if not enabled:
  for player in music_players: player.stop()
 elif music_player.stream:
  music_player.volume_db = gain_for(scene_name); music_player.play()

func set_combat_paused(value: bool) -> void:
 combat_paused = value
 for voice in voices: voice.stream_paused = value

func reset_battle() -> void:
 for voice in voices: voice.stop(); voice.stream_paused = false
 combat_paused = false; last_event.clear()

func stop_all() -> void:
 if music_transition: music_transition.kill()
 music_transition = null
 for player in music_players: player.stop(); player.stream = null
 for voice in voices: voice.stop(); voice.stream = null
 cache.clear(); music_cache.clear()

func _exit_tree() -> void:
 stop_all()

func _process(dt: float) -> void:
 if combat_paused:
  for voice in voices:
   if voice.playing: voice.stream_paused = true
 duck_remaining = maxf(0, duck_remaining - dt)
 # Shop playlist: begin the crossfade into the next song a few seconds before this one ends.
 if music_enabled and scene_name.begins_with("shop_") and music_player and music_player.playing and music_player.stream:
  if music_player.get_playback_position() >= music_player.stream.get_length() - SHOP_CROSSFADE:
   var songs = SHOP_TRACKS.filter(func(k): return music_cache.has(k))
   shop_index = (shop_index + 1) % songs.size()
   var nxt = songs[shop_index]
   if nxt != scene_name: _crossfade_to(nxt)
 announce_cooldown = maxf(0, announce_cooldown - dt)
 var bus = AudioServer.get_bus_index("Music")
 var goal = music_mix - (3.0 if duck_remaining > 0 else 0.0)
 AudioServer.set_bus_volume_db(bus, lerpf(AudioServer.get_bus_volume_db(bus), goal, 1.0 - exp(-dt * 9.0)))

# Announcer: recorded voice lines in res://assets/audio/announcer/<key>.ogg
# (welcome, battle, and one per species). Lines play on their own channel,
# never overlap each other, and duck the music while they speak.
var announcer: AudioStreamPlayer
var announcer_lines: Dictionary = {}
var last_announce := ""
var announce_cooldown := 0.0

func setup_announcer() -> void:
 # The announcer has its own bus so its volume is independent of music and effects.
 if AudioServer.get_bus_index("Voice") < 0:
  AudioServer.add_bus(); var vb = AudioServer.bus_count - 1
  AudioServer.set_bus_name(vb, "Voice"); AudioServer.set_bus_send(vb, "Master")
 announcer = AudioStreamPlayer.new(); announcer.bus = "Voice"; announcer.volume_db = 1.0; add_child(announcer)
 var dir = "res://assets/audio/announcer/"
 # Menu line, new-guild line, the battle countdown and the kill-streak calls. (No champion-name lines.)
 for key in ["guild", "found_guild", "count_3", "count_2", "count_1", "fight", "call_1", "call_2", "call_3", "call_4"]:
  if ResourceLoader.exists(dir + key + ".ogg"): announcer_lines[key] = load(dir + key + ".ogg")

## Play several lines back to back (e.g. the title call, then the welcome).
func announce_chain(keys: Array, gap: float = 0.15) -> void:
 var t = 0.0
 for k in keys:
  if not announcer_lines.has(k): continue
  var key = k
  get_tree().create_timer(t).timeout.connect(func(): announce(key, true))
  t += announcer_lines[k].get_length() + gap

func announce(key: String, force: bool = false) -> void:
 if announcer == null or not effects_enabled or not announcer_lines.has(key): return
 if not force and key == last_announce and announce_cooldown > 0.0: return
 announcer.stop(); announcer.stream = announcer_lines[key]; announcer.play()
 last_announce = key; announce_cooldown = 1.2   # music keeps playing at full level under the announcer

func cue(key: String, strong: bool = false) -> void:
 play_sample(key.get_slice("|", 0), -2 if strong else -7, 3 if strong else 2)

func play_sample(key: String, gain: float, priority: int, pan: float = 0.0, pitch: float = 1.0) -> bool:
 if not effects_enabled or combat_paused or voices.is_empty() or not cache.has(key): return false
 var index = -1
 for i in range(voices.size()):
  if not voices[i].playing: index = i; break
 if index < 0:
  for i in range(voices.size()):
   if voice_priorities[i] < priority: index = i; break
 if index < 0: return false
 var player = voices[index]; player.stop(); player.stream = cache[key]; player.pitch_scale = pitch; player.volume_db = gain
 var view = get_viewport().get_visible_rect().size
 player.position = view * 0.5 + Vector2(clampf(pan,-1,1) * view.x * 0.35, 0)
 player.stream_paused = false; voice_priorities[index] = priority; player.play()
 played_cues += 1; last_cue = key
 if priority >= 2: duck_remaining = maxf(duck_remaining, 0.22 if priority == 2 else 0.45)
 return true

static func event_sound(e: Dictionary, unit: Dictionary) -> Dictionary:
 var sp = e.get("species",unit.get("hero", {}).get("sp", "minotaur"))
 var family = SPECIES_FAMILY.get(sp, "beast")
 var effect = EFFECT_FAMILY.get(e.get("effect", ""), family)
 var result = {"key": "", "gain": -9.0, "priority": 1, "gap": 0.1}
 match e.type:
  "item_feedback":
   if e.stage=="equip":return result
   var item_family=ItemFeedback.profile(e.item_id).family
   result.key={"strike":"impact_metal","guard":"shield","heal":"heal","lightning":"lightning","poison":"venom","shadow":"shadow","tempo":"spirit","fire":"fire","growth":"nature","arcane":"holy"}.get(item_family,"spirit")
   result.gain=-16 if e.stage=="proc" else -27
   result.priority=2 if e.stage=="proc" else 1;result.gap=.20 if e.stage=="proc" else .5
   if e.stage=="proc" and ItemEffects.definition(e.item_id).get("wild",false):result.priority=3;result.gain=-12
  "telegraph": return result
  "cast":
   result.key = "hero_" + sp if HeroData.species.has(sp) and e.effect == HeroData.species[sp].ab else effect
   result.gain = -14; result.priority = 2; result.gap = 0.22
  "release": result.key = "attack_" + family; result.gain = -24; result.gap = 0.24
  "impact":
   if not e.has("effect") or e.get("credit","") == "basic": return result
   result.key = "impact_stone" if effect in ["stone","quake"] else "impact_arcane"
   result.gain = -14 if e.get("small",false) else -10; result.priority = 2; result.gap = 0.16
  "hit":
   # Single physical hits get a contact transient. Spell/DoT ticks stay
   # silent; the cast or projectile impact already carries their identity.
   if e.get("credit", "") != "basic" or e.get("amount",0) < 4: return result
   result.key = "impact_stone" if family in ["stone","quake"] else "impact_metal" if family in ["shield","metal"] else "impact_flesh"
   result.gain = -17; result.gap = 0.12
  "heal", "blocked": return result
  "death":
   if unit.get("summon", false): return result
   result.key = "death_" + family; result.gain = -9; result.priority = 3; result.gap = 0.25
  "interrupt": result.key = "interrupt"; result.gain = -8; result.priority = 2; result.gap = 0.12
 if e.type=="cast" and e.get("rarity","")=="Legendary":result.priority=3;result.gain+=2
 return result

func battle_event(e: Dictionary, unit: Dictionary, pan: float = 0.0) -> void:
 if not effects_enabled or combat_paused: return
 var sound = event_sound(e, unit)
 if sound.key.is_empty(): return
 var now = Time.get_ticks_msec() / 1000.0
 # Wall-clock limits prevent 4x speed, DoTs and summons becoming an audio flood.
 var gate = ("item_"+str(e.get("stage","")) if e.type=="item_feedback" else e.type) + (str(e.get("uid", -1)) if e.type in ["death", "interrupt"] else "")
 if now - last_event.get(gate, -100.0) < sound.gap: return
 last_event[gate] = now
 var variant = 0.97 + float(int(e.get("uid", 0)) % 5) * 0.015
 play_sample(sound.key, sound.gain, sound.priority, pan, variant)

# ---------------------------------------------------------------- volume settings (global, saved)
const SETTINGS_PATH := "user://settings.cfg"
var levels := {"music": 0.5, "effects": 0.5, "voice": 0.85}

func load_settings() -> void:
 var cfg = ConfigFile.new()
 if cfg.load(SETTINGS_PATH) == OK:
  for k in levels: levels[k] = clampf(float(cfg.get_value("audio", k, levels[k])), 0.0, 1.0)
 apply_levels()
 ArenaView.load_follow()

func save_settings() -> void:
 var cfg = ConfigFile.new(); cfg.load(SETTINGS_PATH)
 for k in levels: cfg.set_value("audio", k, levels[k])
 cfg.save(SETTINGS_PATH)

func set_level(kind: String, value: float) -> void:
 levels[kind] = clampf(value, 0.0, 1.0); apply_levels()

func apply_levels() -> void:
 set_mix(levels.music, levels.effects)
 var vb = AudioServer.get_bus_index("Voice")
 if vb >= 0: AudioServer.set_bus_volume_db(vb, linear_to_db(maxf(0.0001, levels.voice)))

func set_mix(music_volume: float, effects_volume: float) -> void:
 music_mix = linear_to_db(maxf(0.0001,clampf(music_volume,0,1)))
 effects_mix = linear_to_db(maxf(0.0001,clampf(effects_volume,0,1)))
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),music_mix)
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"),effects_mix)
