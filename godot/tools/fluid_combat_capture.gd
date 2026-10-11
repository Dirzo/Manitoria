extends SceneTree
## Records a seeded melee skirmish through the real ArenaView for before/after animation reviews.
## Run with Godot's movie writer so every frame is captured at a fixed 60 fps:
##   godot --path godot --rendering-driver opengl3 --write-movie /tmp/fc/frame.png --fixed-fps 60 \
##         -s tools/fluid_combat_capture.gd
## env: SECONDS=8  START=2.0 (sim seconds skipped before recording)  DIST=12  PITCH=0.62  YAW=0.55
##      LEFT=minotaur,direwolf  RIGHT=troll,nemean  SEED=77
var arena: ArenaView
var sim: BattleSim
var frames := 0
var limit := 480
var accumulator := 0.0

func env(key: String, fallback: String) -> String:
	var v = OS.get_environment(key)
	return v if v != "" else fallback

func team(names: Array, tag: String) -> Array:
	var out = []
	for i in names.size():
		var h = HeroData.make_hero(names[i], "%s%d" % [tag, i], "%s %d" % [tag, i], 7)
		h.slot = Campaign.FORMATION[i]
		out.append(h)
	return out

func _initialize() -> void:
	HeroData.load_data()
	arena = ArenaView.new(); get_root().add_child(arena)
	sim = BattleSim.new()
	sim.setup(team(Array(env("LEFT", "minotaur,direwolf").split(",")), "L"), team(Array(env("RIGHT", "troll,nemean").split(",")), "R"), int(env("SEED", "77")))
	sim.action.connect(func(e): arena.handle_event(e))
	ArenaView.follow_on = true
	arena.live = true
	arena.target_distance = float(env("DIST", "12")); arena.target_pitch = float(env("PITCH", "0.62")); arena.target_yaw = float(env("YAW", "0.55"))
	limit = int(float(env("SECONDS", "8")) * 60.0)
	var skip = float(env("START", "2.0"))
	arena.sync(sim, 1.0 / 60.0, 0.0)
	# Fast-forward to the clash (the arena still sees every event so state stays consistent).
	while sim.time < skip and not sim.finished:
		sim.step(1.0 / 30.0); arena.sync(sim, 1.0 / 30.0, 1.0)
	if arena.camera: for i in 120: arena.update_camera(1.0 / 60.0)

func _process(dt: float) -> bool:
	accumulator += dt
	while accumulator >= 1.0 / 30.0 and not sim.finished:
		sim.step(1.0 / 30.0); accumulator -= 1.0 / 30.0
	arena.sync(sim, dt, 1.0)
	frames += 1
	return frames >= limit
