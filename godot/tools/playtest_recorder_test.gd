extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 HeroData.load_data()
 var game = load("res://scripts/main.gd").new()
 game.campaign.new_run("Private name must not be logged",97,731)
 var recorder = PlaytestRecorder.new(); root.add_child(recorder)
 assert(recorder.start(game,ProjectSettings.globalize_path("res://../../tools/telemetry-fixture"),true))
 var left = []; var right = []
 for i in range(3):
  var h = HeroData.make_hero(["cyclops","zaratan","unicorn"][i],"private-id", "Private champion",8)
  h.slot = Campaign.FORMATION[i]; left.append(h)
  var enemy = HeroData.make_hero(["golem","manticore","hydra"][i],"private-enemy", "Private enemy",8)
  enemy.slot = Campaign.FORMATION[i]; right.append(enemy)
 var outcomes = []
 for observed in [false,true]:
  var sim = BattleSim.new()
  if observed: sim.action.connect(func(e):recorder.combat(e,sim))
  sim.setup(left,right,731)
  for tick in range(6000):
   if sim.finished: break
   sim.step(1.0/30.0)
  outcomes.append([sim.winner,sim.time,sim.rng.state,sim.units.map(func(u):return [u.hp,u.shield,u.damage,u.healing,u.blocked,u.kills,u.pos,u.cd])])
 assert(outcomes[0]==outcomes[1],"Recording must preserve simulation and RNG")
 recorder.record("battle_result",{"winner":outcomes[1][0],"duration":outcomes[1][1]})
 recorder.flush()
 recorder.record("decision",{"action":"Shop"})
 recorder.finish()
 assert(not recorder.enabled)
 print("PASS: recording preserves combat and RNG; background and exit archive paths exercised")
 game.free(); recorder.queue_free(); quit()
