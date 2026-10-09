extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func fixture(key: String) -> Dictionary:
 var sim = BattleSim.new(); sim.elite_squads = false; sim.rng.seed = 4177
 var h = Bestiary.make(key, "boss", 5, 2, "Keeper", 0); h.party = 3
 var boss = sim.add_unit(h, 1, Vector2(1, 0))
 var victims: Array = []
 for i in range(3):
  var v = sim.add_unit(HeroData.make_hero("golem", "v%d" % i, "Victim", 5), 0, Vector2(-2, i * 2))
  v.fx.dodge = 0.0; v.dodge = 0.0; v.max_hp *= 10; v.hp = v.max_hp; victims.append(v)
 return {"sim":sim, "boss":boss, "victims":victims}
func run() -> void:
 HeroData.load_data()
 var sound = SoundDesign.new(); root.add_child(sound)
 await process_frame
 for key in Bestiary.BOSSES:
  var f = fixture(key); var sim: BattleSim = f.sim; var u: Dictionary = f.boss
  var events: Array = []; sim.action.connect(func(e): events.append(e.duplicate(true)))
  check(WardenMechanics.KITS.has(key), key + " has a unique kit")
  check(Bestiary.info(key).text.contains(WardenMechanics.KITS[key].name), key + " scouting includes the new ability")
  for action in ["entrance", "warning", "attack", "summon", "phase", "enrage", "death"]:
   var cue = "boss_%s_%s" % [key, action]
   check(sound.cache.has(cue), "Preloaded " + cue)
   var kind = "spawn" if action == "entrance" else "death" if action == "death" else "telegraph" if action == "warning" else "cast"
   var mapped = SoundDesign.event_sound({"type":kind, "boss_action":action, "effect":"quake", "uid":u.uid}, u)
   check(mapped.key == cue, key + " routes " + action)
  var kit = WardenMechanics.KITS[key]
  var target: Dictionary = f.victims[0]
  var before = target.hp
  WardenMechanics.begin(sim, u, "special", kit, target.pos)
  WardenMechanics.tick(sim, u, 0.4)
  check(target.hp == before and u.has("boss_pending"), key + " warning does not hit early")
  check(events[0].type == "telegraph" and events[0].duration == WardenMechanics.WINDUP, key + " warning has explicit duration")
  var locked: Vector2 = u.boss_pending.target
  sim.relocate_hex(target, Vector2(-9, -7))
  check(u.boss_pending.target == locked, key + " target floor stays fixed")
  WardenMechanics.tick(sim, u, 1.0)
  check(not u.has("boss_pending") and target.hp == before, key + " moving outside the marker avoids initial damage")
  sim.relocate_hex(target, Vector2(-2, 0)); before = target.hp
  u.recovery = 0.0
  WardenMechanics.begin(sim, u, "special", kit, target.pos)
  WardenMechanics.tick(sim, u, 2.0)
  check(target.hp < before, key + " special applies damage")
  if kit.has("status"): check(sim.active(target, str(kit.status)), key + " special applies control")
  if key == "forge_tyrant": check(not sim.zones.is_empty() and sim.zones[-1].remaining == 4.0, "Crucible leaves a four-second zone")
  if key in ["spore_queen", "sun_pharaoh"]: check(not target.dots.is_empty(), key + " applies a damage-over-time effect")
  for control in ["stun", "silence"]:
   before = target.hp
   WardenMechanics.begin(sim, u, "special", kit, target.pos)
   u.status[control] = 1.0
   WardenMechanics.tick(sim, u, 2.0)
   check(not u.has("boss_pending") and target.hp == before, key + " interrupted by " + control)
   var timer = u.boss.special_t
   WardenMechanics.tick(sim, u, 1.0)
   check(u.boss.special_t == timer, key + " timers stop under " + control)
   u.status.clear()
  var no_summon = SoundDesign.event_sound({"type":"summon", "boss_action":"summon"}, u)
  check(no_summon.key.is_empty(), key + " add spawning does not double the cast sound")
  # Existing summons, slams and pulses now follow the same interruptible warning path.
  var m = Bestiary.BOSSES[key]
  for kind in ["summon", "slam", "pulse"]:
   if not m.has(kind): continue
   var spec = m[kind].duplicate(true); spec.effect = "quake"; spec.name = kind
   u.status.clear(); before = target.hp; var count_before = sim.units.size()
   WardenMechanics.begin(sim, u, kind, spec, target.pos)
   u.status.stun = 2.0; WardenMechanics.tick(sim, u, 2.0)
   check(target.hp == before and sim.units.size() == count_before, key + " legacy " + kind + " cancels without effects")
   u.status.clear(); WardenMechanics.begin(sim, u, kind, spec, target.pos)
   WardenMechanics.tick(sim, u, 2.0)
   check(sim.units.size() > count_before if kind == "summon" else target.hp < before, key + " legacy " + kind + " resolves")
  var generic = SoundDesign.event_sound({"type":"cast", "effect":"quake"}, u)
  check(generic.key == "boss_%s_attack" % key, key + " innate signature has custom audio")
  # Real hex spacing: adjacent foes must be inside an actual Warden slam's marker.
 var slam_f = fixture("forge_tyrant"); var slam_sim: BattleSim = slam_f.sim; var slammer: Dictionary = slam_f.boss
 slammer.boss.slam_t = 0.0; slammer.boss.special_t = 100.0
 WardenMechanics.tick(slam_sim, slammer, 0.01)
 check(slammer.has("boss_pending") and slammer.boss_pending.kind == "slam", "Adjacent enemy starts a real slam warning")
 var hp_before = slam_f.victims[0].hp
 WardenMechanics.tick(slam_sim, slammer, 2.0)
 check(slam_f.victims[0].hp < hp_before, "Real slam reaches an adjacent hex")
 var root_f = fixture("rootmother"); var root_sim: BattleSim = root_f.sim
 var mark: Vector2 = root_f.victims[0].pos
 check(WardenMechanics.area_foes(root_sim, root_f.boss, mark, 4.0).size() >= 2, "Cluster punishment includes neighboring hexes")
 var storm_f = fixture("tempest_roc"); var storm_sim: BattleSim = storm_f.sim
 for i in range(3): storm_sim.relocate_hex(storm_f.victims[i], Vector2(-2.85 * i, 0))
 WardenMechanics.begin(storm_sim, storm_f.boss, "special", WardenMechanics.KITS.tempest_roc, storm_f.victims[0].pos)
 var hp_list = storm_f.victims.map(func(v): return v.hp)
 WardenMechanics.tick(storm_sim, storm_f.boss, 2.0)
 check(storm_f.victims.filter(func(v): return v.hp < hp_list[storm_f.victims.find(v)]).size() == 3, "Lightning jumps across three adjacent hexes")
 # Verify observed and silent/headless simulations retain the same gameplay and seed stream.
 for key in Bestiary.BOSSES:
  var a = fixture(key); var b = fixture(key); b.sim.silent = true
  for i in range(600): a.sim.step(1.0/30.0); b.sim.step(1.0/30.0)
  check(a.sim.units.size() == b.sim.units.size(), key + " deterministic summon count")
  check(a.sim.units.all(func(u): return is_equal_approx(u.hp, b.sim.find_unit(u.uid).hp) and u.cell == b.sim.find_unit(u.uid).cell), key + " watched/silent parity")
 # The warning must be audible even when all eight voices are playing ordinary effects.
 sound.reset_battle()
 for i in range(8): sound.play_sample("hero_treant", -20.0, 1)
 var f = fixture("rootmother"); var prior = sound.played_cues
 sound.battle_event({"type":"telegraph", "uid":f.boss.uid, "boss_action":"warning", "duration":1.25}, f.boss)
 check(sound.played_cues == prior + 1 and sound.last_cue == "boss_rootmother_warning", "Warnings preempt ordinary sounds")
 sound.effects_enabled = false; prior = sound.played_cues
 sound.battle_event({"type":"cast", "uid":f.boss.uid, "boss_action":"special"}, f.boss)
 check(sound.played_cues == prior, "Mute blocks boss cues")
 sound.effects_enabled = true; sound.set_combat_paused(true)
 check(not sound.play_sample("boss_rootmother_attack", -8, 3), "Pause blocks new boss sounds")
 sound.reset_battle(); check(not sound.combat_paused, "Battle reset resumes sound")
 # Rapid zone changes must cancel old transition callbacks; stop_all really stops ambience.
 sound.set_ambience("magma_depths"); sound.set_ambience("void_rift")
 await create_timer(2.1).timeout
 check(sound.ambience_name == "void_rift" and sound.ambience_player.playing, "Rapid ambience changes keep the latest zone")
 sound.set_combat_paused(true); check(sound.ambience_player.stream_paused, "Ambience pauses with combat")
 sound.stop_all(); check(not sound.ambience_player.playing and sound.ambience_name.is_empty(), "stop_all stops environmental audio")
 sound.queue_free(); await process_frame
 print("WARDEN AUDIO: %d checks, %d failures" % [checks, failures])
 quit(1 if failures else 0)
