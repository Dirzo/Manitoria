extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 HeroData.load_data()
 for sp in HeroData.species:
  var h = HeroData.make_hero(sp, "test-" + sp, sp, 5)
  var sim = BattleSim.new(); var a = sim.add_unit(h, 0, ArenaGrid.point(Vector2i(-4,0)))
  var enemy = HeroData.make_hero("golem", "enemy", "Enemy", 5)
  var b = sim.add_unit(enemy, 1, ArenaGrid.point(Vector2i(4,0)))
  check(CombatRange.basic_label(a.range).contains(str(a.attack_hexes)), sp + " label matches combat reach")
  for cell in ArenaGrid.cells():
   b.cell = cell; b.pos = ArenaGrid.point(cell)
   check(sim.in_attack_range(a,b) == (ArenaGrid.distance(a.cell,cell) <= a.attack_hexes), sp + " exact boundary")
  b.cell=Vector2i(4,0); b.pos=ArenaGrid.point(b.cell)
  var hp = b.hp; sim.attack(a,b)
  check(is_equal_approx(hp,b.hp) and sim.projectiles.is_empty(), sp + " direct out-of-range attack rejected")
  a.next_cell=ArenaGrid.neighbors(a.cell)[0]
  check(not sim.in_attack_range(a,b), sp + " walking attacker cannot attack")
 var a={"cell":Vector2i.ZERO}; var b={"cell":Vector2i(1,0),"next_cell":Vector2i(2,0)}
 check(not CombatRange.contains(a,b,1), "Moving target leaving reach cannot be hit across the boundary")
 check(CombatRange.contains(a,b,2), "Moving target wholly inside reach remains hittable")
 for component in Forge.COMPONENT_ORDER:
  var recipes = GearUI.component_recipes(component)
  for partner in Forge.COMPONENT_ORDER:
   var made=Forge.combine(component,partner)
   if made != "": check(recipes.contains(Forge.info(partner).name) and recipes.contains(Forge.info(made).name), "Reward recipe includes partner and result")
 var game = load("res://scripts/main.gd").new(); root.add_child(game)
 await create_timer(1.0).timeout; game.qa=""
 for h in game.campaign.state.roster: h.pending=[]; h.rewards=[]
 game.campaign.state.tour.shop=false
 game.introduce_match()
 check(game.phase=="prep", "Dungeon fight entry stops at equipment prep")
 await process_frame
 check(game.ui.find_child("PrepBag",true,false)!=null and game.ui.find_child("PrepEquipment",true,false)!=null,"Prep has bag and equipment actions")
 check(game.ui.find_children("Slot_*","",true,false).size() >= game.campaign.lineup().size()*3,"Every starter has live equipment slots")
 var selected=game.sim.units.filter(func(u):return u.hero.id==game.selected_id)
 check(not selected.is_empty() and game.arena.range_mesh!=null,"Selected formation champion has hex reach overlay")
 check(game.arena.models[game.sim.units[0].uid].name_label.text.contains("ATK"),"Character label shows attack reach")
 var hero = game.campaign.lineup()[0]
 hero.equipment={}
 var first: String = Forge.COMPONENT_ORDER[0]; var second: String = Forge.COMPONENT_ORDER[1]
 game.campaign.state.inventory.append(first); game.campaign.state.inventory.append(second)
 check(GearUI.apply_drop(game,{"kind":"bag","id":first},hero.id), "Equip component from bag during prep")
 check(GearUI.apply_drop(game,{"kind":"bag","id":second},hero.id), "Forge a second component during prep")
 check(Forge.combine(first,second) in game.campaign.hero_by_id(hero.id).equipment.values(), "Combined item is worn before battle")
 await create_timer(4.0).timeout
 check(game.phase=="prep", "Prep never auto-starts after introduction duration")
 Dungeon.offer_loot(game.campaign,"component"); game.phase="hub"; game.tab="overview"; game.render()
 await process_frame; await process_frame
 check(game.ui.find_children("DungeonRecipes_*","",true,false).size()==3,"All dungeon component offers show recipes")
 game.campaign.state.dungeon.loot=[]; game.campaign.state.dungeon.event=Dungeon.EVENTS[1].duplicate(true); game.render()
 await process_frame; await process_frame
 check(game.ui.find_child("EncounterEquipment",true,false)!=null,"Noncombat encounter offers equipment before decision")
 var sound: SoundDesign = game.sound
 sound.effects_enabled=true; sound.set_level("effects",1.0); sound.set_level("voice",1.0)
 check(not sound.effects_enabled,"Old saves/toggles cannot re-enable retired effects")
 var before=sound.played_cues
 sound.gold(300); sound.cue("victory",true); sound.announce("fight",true); sound.set_ambience("magma_depths")
 check(not sound.play_sample("boss_rootmother_attack",0.0,3),"Forced playback is silent")
 await create_timer(.3).timeout
 check(sound.played_cues==before and sound.duck_remaining==0.0,"No cues or music ducking in music-only mode")
 check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")) and AudioServer.is_bus_mute(AudioServer.get_bus_index("Voice")),"Effects and voice buses remain muted")
 sound.set_music(true); sound.scene_music("zone_magma_depths")
 check(sound.music_enabled and sound.music_player.playing,"Zone music still plays")
 sound.stop_all(); game.queue_free(); await process_frame
 print("RANGE / PREP / MUSIC: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
