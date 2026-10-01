class_name SoundDesign
extends Node

const SPECIES_FAMILY = {"minotaur":"beast", "golem":"stone", "troll":"stone", "wendigo":"shadow", "direwolf":"beast", "manticore":"venom", "griffin":"wing", "kitsune":"spirit", "wyvern":"venom", "harpy":"wing", "phoenix":"fire", "kirin":"lightning", "basilisk":"venom", "treant":"nature", "naga":"water", "unicorn":"holy", "cerberus":"beast", "nemean":"beast", "yeti":"ice", "zaratan":"shield", "owlbear":"claw", "hydra":"nature", "chimera":"fire", "gargoyle":"stone", "nekomata":"shadow", "jackalope":"nature", "cyclops":"quake", "thunderbird":"lightning", "sphinx":"spirit", "pegasus":"wing", "arachne":"venom", "salamander":"fire"}
const EFFECT_FAMILY = {"gore":"beast", "bulwark":"shield", "smash":"stone", "hunger":"shadow", "howl":"beast", "venom":"venom", "skystrike":"wing", "foxfire":"spirit", "acid":"venom", "shriek":"wing", "flamewave":"fire", "chain":"lightning", "gaze":"venom", "rootbloom":"nature", "tidal":"water", "radiance":"holy", "triplebite":"claw", "prideroar":"beast", "frostroar":"ice", "shellup":"shield", "maul":"claw", "regrowth":"nature", "threefold":"fire", "stonedive":"stone", "vanish":"shadow", "antlerrush":"nature", "boulder":"quake", "stormcall":"lightning", "riddle":"spirit", "tailwind":"wing", "brood":"venom", "magma":"fire", "quake":"quake", "ward":"shield", "meteor":"quake", "renew":"heal", "drain":"shadow", "fear":"shadow", "ambush":"claw", "toxic":"venom", "execute":"metal", "gust":"wing", "wisps":"spirit", "barrage":"bow", "silence":"shadow", "beam":"holy", "storm":"lightning", "frost":"ice", "roots":"nature", "fire":"fire", "whirl":"metal", "fissure":"stone", "rally":"holy", "rebirth":"fire"}
const MUSIC_GAIN = {"club": -2.0, "preparation": -1.0, "arena": -4.0}
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
 # Decode/load outside combat so the first spell cannot stall a fight.
 var keys = []
 var families = []
 for family in EFFECT_FAMILY.values():
  if family not in families: families.append(family)
 for family in families:
  for prefix in ["", "attack_", "charge_", "death_"]: keys.append(prefix + family)
 for species in SPECIES_FAMILY: keys.append("hero_" + species)
 keys.append_array(["contest_reveal", "contest_lock", "contest_versus", "victory", "honor", "upgrade", "multikill", "arena_gate", "interrupt", "impact_flesh", "impact_stone", "impact_metal", "impact_arcane"])
 # Enumerate logical resource paths: exported WAVs have .import sidecars,
 # unlike their loose source files. ResourceLoader resolves either form.
 for key in keys:
  var path = "res://assets/audio/fx/" + key + ".wav"
  if ResourceLoader.exists(path): cache[key] = load(path)
  else: push_error("Missing combat audio: " + path)
 setup_announcer()
 print("Audio loaded: ", music_cache.size(), " tracks; ", cache.size(), " effects")
 var master = AudioServer.get_bus_index("Master")
 if AudioServer.get_bus_effect_count(master) == 0:
  var limiter = AudioEffectLimiter.new(); limiter.ceiling_db = -1.0; limiter.threshold_db = -2.0
  AudioServer.add_bus_effect(master, limiter)
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_mix)
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), effects_mix)

static func music_for_phase(phase: String) -> String:
 return "arena" if phase == "battle" else "preparation" if phase in ["prep","intro"] else "club"

func scene_music(which: String) -> void:
 if scene_name == which or not music_cache.has(which): return
 if scene_name == "arena" and which != "arena":
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
 if not incoming.playing:
  incoming.play(outgoing.get_playback_position() if aligned and outgoing.playing else 0.0)
 var start_in = db_to_linear(incoming.volume_db); var start_out = db_to_linear(outgoing.volume_db)
 var target_gain = db_to_linear(MUSIC_GAIN[which])
 music_transition = create_tween()
 music_transition.tween_method(func(t):
  # Aligned stems use a linear blend; unrelated music fades through silence.
  var blend_in = t if aligned else maxf(0.0, (t - 0.5) * 2.0)
  var blend_out = 1.0 - t if aligned else maxf(0.0, 1.0 - t * 2.0)
  incoming.volume_db = linear_to_db(maxf(0.0001, lerpf(start_in, target_gain, blend_in)))
  outgoing.volume_db = linear_to_db(maxf(0.0001, start_out * blend_out)), 0.0, 1.0, 1.1)
 music_transition.tween_callback(func(): outgoing.stop())

func set_music(enabled: bool) -> void:
 music_enabled = enabled
 if music_transition: music_transition.kill()
 if not enabled:
  for player in music_players: player.stop()
 elif music_player.stream:
  music_player.volume_db = MUSIC_GAIN.get(scene_name, 0.0); music_player.play()

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
 announce_cooldown = maxf(0, announce_cooldown - dt)
 var bus = AudioServer.get_bus_index("Music")
 var goal = music_mix - ((9.0 if announcer and announcer.playing else 3.0) if duck_remaining > 0 else 0.0)
 AudioServer.set_bus_volume_db(bus, lerpf(AudioServer.get_bus_volume_db(bus), goal, 1.0 - exp(-dt * 9.0)))

# Announcer: recorded voice lines in res://assets/audio/announcer/<key>.ogg
# (welcome, battle, and one per species). Lines play on their own channel,
# never overlap each other, and duck the music while they speak.
var announcer: AudioStreamPlayer
var announcer_lines: Dictionary = {}
var last_announce := ""
var announce_cooldown := 0.0

func setup_announcer() -> void:
 announcer = AudioStreamPlayer.new(); announcer.bus = "Effects"; announcer.volume_db = 1.0; add_child(announcer)
 var dir = "res://assets/audio/announcer/"
 for key in ["welcome", "battle"] + SPECIES_FAMILY.keys():
  if ResourceLoader.exists(dir + key + ".ogg"): announcer_lines[key] = load(dir + key + ".ogg")

func announce(key: String, force: bool = false) -> void:
 if announcer == null or not effects_enabled or not announcer_lines.has(key): return
 if not force and key == last_announce and announce_cooldown > 0.0: return
 announcer.stop(); announcer.stream = announcer_lines[key]; announcer.play()
 last_announce = key; announce_cooldown = 1.2
 duck_remaining = maxf(duck_remaining, announcer_lines[key].get_length())

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
  "item_proc":
   var item=ItemEffects.definition(str(e.get("credit","")).trim_prefix("item:"))
   result.key=EFFECT_FAMILY.get(item.get("art","ward"),"shield");result.gain=-22;result.gap=0.45
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
 var gate = e.type + (str(e.get("uid", -1)) if e.type in ["death", "interrupt"] else "")
 if now - last_event.get(gate, -100.0) < sound.gap: return
 last_event[gate] = now
 var variant = 0.97 + float(int(e.get("uid", 0)) % 5) * 0.015
 play_sample(sound.key, sound.gain, sound.priority, pan, variant)

func set_mix(music_volume: float, effects_volume: float) -> void:
 music_mix = linear_to_db(maxf(0.0001,clampf(music_volume,0,1)))
 effects_mix = linear_to_db(maxf(0.0001,clampf(effects_volume,0,1)))
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),music_mix)
 AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"),effects_mix)
