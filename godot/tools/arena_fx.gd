extends SceneTree
## Arena-scale ability capture using real combat (AbilityDemo) and the real ArenaView.
## env: SHOTS="sp:key,sp:sig,..." TIMES="1.0,1.4,2.0" OUT=dir DIST=17 PITCH=0.95
var arena: ArenaView
var demo: AbilityDemo
var shots: Array
var times: Array
var si := 0
var ti := 0
var out := ""
var wait := 0

func _init() -> void:
	shots = Array(OS.get_environment("SHOTS").split(","))
	times = Array(OS.get_environment("TIMES").split(",")).map(func(s): return float(s))
	out = OS.get_environment("OUT")
	arena = ArenaView.new(); get_root().add_child(arena)
	arena.target_distance = float(OS.get_environment("DIST")) if OS.get_environment("DIST") != "" else 17.0
	arena.target_pitch = float(OS.get_environment("PITCH")) if OS.get_environment("PITCH") != "" else 0.95
	arena.target_yaw = 0
	_start()

func _start() -> void:
	var parts = shots[si].split(":"); var sp = parts[0]
	var h = HeroData.make_hero(sp, "c", "Caster", 7)
	var card: Dictionary
	if parts[1] == "sig":
		card = {"type": "signature", "key": "signature", "name": "sig", "description": "", "rarity": "Rare", "bonus": 1.1}
	else:
		var a = HeroData.learned_ability(sp, int(parts[1]))
		card = {"type": "ability", "key": parts[1], "name": a.name, "description": a.description, "rarity": "Rare", "bonus": 1.1}
	arena.clear_fighters(); ti = 0
	demo = AbilityDemo.new(); demo.setup(h, card, "Clustered")
	demo.sim.action.connect(func(e): arena.handle_event(e))
	arena.sync(demo.sim, 1.0)
	if arena.camera: arena.update_camera(1)

func _process(_dt: float) -> bool:
	if ti >= times.size():
		si += 1
		if si >= shots.size(): quit(); return true
		_start(); return false
	var dt = 1.0 / 30.0
	if demo.elapsed < times[ti]:
		for k in range(6):
			if demo.elapsed >= times[ti]: break
			demo.advance(dt); arena.sync(demo.sim, dt, 1.0)
		return false
	wait += 1
	if wait < 3: arena.sync(demo.sim, 0.0, 0.0); return false
	wait = 0
	get_root().get_texture().get_image().save_png("%s/%s_%d.png" % [out, shots[si].replace(":", "-"), ti])
	ti += 1
	return false
