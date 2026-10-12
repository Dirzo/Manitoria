extends SceneTree
## Rendered integration check in an isolated APPDATA profile. Run with -- --qa=shop_after.
var checks = 0
var failures = 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
 await create_timer(.6).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../../tools/"+name+".png"))
func state(sim: BattleSim) -> Array:
 return [sim.winner,sim.time,sim.rng.state,sim.units.map(func(u):return [u.hp,u.shield,u.damage,u.healing,u.blocked,u.kills,u.cd,u.ability_cds.duplicate(true),u.pos])]
func run() -> void:
 var game = load("res://scripts/main.gd").new(); root.add_child(game)
 game.qa = ""; game.set_process(false)
 await create_timer(.5).timeout
 game.phase = "result"; game.render()
 check(game.ui.find_children("*","MatchAnalytics",true,false).is_empty(),"Detailed report is optional initially")
 await capture("result")
 var pending = game.campaign.pending_heroes().size()
 game.show_bracket_then_shop()
 check(game.phase == ("upgrade" if pending else "shop"),"Next action preserves required upgrades and reaches shop directly")
 for h in game.campaign.state.roster: h.pending = []; h.rewards = []
 game.show_bracket_then_shop()
 check(game.phase == "shop","No mandatory bracket screen before shop")
 await capture("shop")
 game.sound.scene_music("arena"); await create_timer(1.3).timeout
 game.sound.scene_music("shop"); await create_timer(1.0).timeout
 check(game.sound.music_players.all(func(p):return p.playing and p.volume_db > -35),"Music overlaps through the shop transition midpoint")
 game.sound.reset_battle()
 game.sound.play_sample("impact_stone",-14,2)
 game.sound.scene_music("club")
 check(game.sound.voices.any(func(v):return v.playing),"Final impact tail survives music transition")
 var left = []; var right = []
 for i in range(3):
  var h = HeroData.make_hero(["zaratan","cyclops","unicorn"][i],"p%d"%i,"Presentation %d"%i,8)
  h.slot = [0,8,9][i]; h.learned = {"0":2,"1":2}; h.signature_rank = 2
  h.equipment = {"0":"bell","1":"colossus","2":"runeward"} if i==0 else {"0":"tusk","1":"executioner","2":"spellblade"} if i==1 else {}
  left.append(h)
  var foe = HeroData.make_hero(["golem","cyclops","manticore"][i],"e%d"%i,"Opponent %d"%i,8)
  foe.slot = Campaign.FORMATION[i]; foe.learned = {"0":2,"1":2}; right.append(foe)
 var snapshots = []; var shell_seen = false
 for rate in [0,1,2,4]:
  var rendered = rate > 0
  var sim = BattleSim.new(); sim.silent = not rendered; sim.setup(left,right,731)
  var feedback = Callable()
  if rendered:
   game.sim = sim; game.phase = "battle"; game.paused = true; game.countdown = 0
   game.arena.clear_fighters(); game.render(); game.sound.reset_battle()
   game.arena.sync(sim,0,1)
   feedback = func(e):game.arena.handle_event(e);game.sound.battle_event(e,sim.find_unit(int(e.get("uid",-1))))
   sim.action.connect(feedback)
  for tick in range(900):
   if sim.finished: break
   sim.step(1.0/30.0)
   if rendered:
    game.arena.sync(sim,1.0/(30.0*rate),rate)
    var tank = sim.units[0]
    if not shell_seen and float(tank.status.get("shell",0)) > 0:
     shell_seen = true
     check(game.arena.models[tank.uid].bubble.visible,"Shell defense stays visible during actual status")
     await capture("zaratan-combat")
    if tick==180 and rate==1: await capture("cyclops-combat")
    if tick%30==0: await process_frame
  snapshots.append(state(sim))
  if feedback.is_valid(): sim.action.disconnect(feedback)
 check(shell_seen,"Fixture exercises real Shell Up")
 for i in range(1,snapshots.size()):
  check(snapshots[0]==snapshots[i],"Rendered feedback at %dx preserves outcomes, timing, totals, cooldowns, positions and RNG"%[1,2,4][i-1])
 game.sound.stop_all(); game.queue_free(); await process_frame
 print("Presentation flow: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
