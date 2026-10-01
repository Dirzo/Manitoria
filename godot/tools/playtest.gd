extends SceneTree
## Team-fight playtest: real BattleSim AI + real ArenaView at the in-game camera.
## Logs motion/animation quality metrics and (optionally) captures frames.
## env: TEAMS="a,b,c,d,e|f,g,h,i,j" SEED=1 LEVEL=7 OUT=dir FRAMES=1 FPS_CAP=10 MAXT=60 TAG=name
var arena: ArenaView
var sim: BattleSim
var out := ""
var tag := ""
var frames := false
var cap_every := int(OS.get_environment("EVERY")) if OS.get_environment("EVERY") != "" else 4
var frame_i := 0
var maxt := 60.0
var acc := 0.0
var dt := 1.0 / 60.0
var t := 0.0
var prev := {}     # uid -> {p, v, yaw, state, state_t, last_state}
var stats := {}    # uid -> metrics
var log_lines: Array = []
var footprint := {}  # species -> horizontal radius (world)

func _init() -> void:
	HeroData.load_data()
	var teams = OS.get_environment("TEAMS").split("|")
	out = OS.get_environment("OUT"); tag = OS.get_environment("TAG")
	frames = OS.get_environment("FRAMES") == "1"
	maxt = float(OS.get_environment("MAXT")) if OS.get_environment("MAXT") != "" else 60.0
	var level = int(OS.get_environment("LEVEL")) if OS.get_environment("LEVEL") != "" else 7
	var lists = []
	for side in range(2):
		var l = []
		var names = teams[side].split(",")
		for i in range(names.size()):
			var h = HeroData.make_hero(names[i], "%s%d" % [names[i], side], names[i].capitalize(), level)
			h.slot = Campaign.FORMATION[i]
			if OS.get_environment("LURK") == "1" and HeroData.species[names[i]].role in HeroData.FLANK: h.tactics = BattleTactics.PRESETS.Assassin
			if OS.get_environment("LEGEND") != "" and i == 0: h.skill_rarity = {"signature": "Legendary"}
			# Give every hero a few learned abilities so casts happen in the fight.
			for k in [0, 1, 2]: h.learned[str((k * 4 + side + i) % 12)] = 2
			l.append(h)
		lists.append(l)
	arena = ArenaView.new(); get_root().add_child(arena)
	if OS.get_environment("FRAMES") == "1": RenderingServer.render_loop_enabled = false
	sim = BattleSim.new(); sim.action.connect(func(e): arena.handle_event(e); _ev(e))
	sim.setup(lists[0], lists[1], int(OS.get_environment("SEED")), 1.0)

func _ready_once() -> void:
	arena.camera.h_offset = 0; arena.target_distance = float(OS.get_environment("DIST")) if OS.get_environment("DIST") != "" else 37.0; arena.target_pitch = float(OS.get_environment("PITCH")) if OS.get_environment("PITCH") != "" else 0.95; arena.target_yaw = 0.0
	arena.update_camera(10.0)
	if OS.get_environment("TACTICAL") == "1": arena.clarity.tactical = true; play_speed = 0.75
	arena.sync(sim, 1.0)

var started := false
var play_speed := 1.0
func _process(_d: float) -> bool:
	if not started:
		started = true; _ready_once(); return false
	t += dt
	acc += dt * play_speed
	while acc >= 1.0 / 30.0 and not sim.finished:
		sim.step(1.0 / 30.0); acc -= 1.0 / 30.0
	arena.sync(sim, dt, play_speed)
	_measure()
	if OS.get_environment("COUNTS") == "1" and int(round(t * 60.0)) % 30 == 0: print("COUNT t=%.1f sim=%.1f vfx=%d effects=%d clarity=%d fighters=%d" % [t, sim.time, arena.vfx.get_child_count(), arena.effects.get_child_count(), arena.clarity.get_child_count(), arena.fighters.get_child_count()])
	if frames and int(round(t * 60.0)) % cap_every == 0:
		var _t0 = Time.get_ticks_msec()
		RenderingServer.force_draw(false)
		if OS.get_environment("FTIME") == "1": print("FTIME t=%.2f sim=%.2f ms=%d vfx=%d" % [t, sim.time, Time.get_ticks_msec() - _t0, arena.vfx.get_child_count()])
		get_root().get_texture().get_image().save_jpg("%s/f%04d.jpg" % [out, frame_i], 0.85); frame_i += 1
	if (sim.finished and t > 2.0 and _settled()) or t >= maxt:
		_report(); quit(); return true
	return false

var finish_t := -1.0
func _settled() -> bool:
	if finish_t < 0: finish_t = t
	return t - finish_t > 2.5

func _fp(sp: String, model: Node3D) -> float:
	if footprint.has(sp): return footprint[sp]
	var aabb := AABB(); var first = true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = mi.global_transform * mi.get_aabb()
		if first: aabb = a; first = false
		else: aabb = aabb.merge(a)
	var r = maxf(aabb.size.x, aabb.size.z) * 0.5
	footprint[sp] = r
	return r

func _st(uid) -> Dictionary:
	if not stats.has(uid):
		stats[uid] = {"teleports": 0, "max_step": 0.0, "snaps": 0, "max_turn": 0.0, "flicker": 0, "switches": 0, "idle_slide": 0.0, "walk_still": 0.0, "misface": 0.0, "overlap": 0.0, "jerk_spikes": 0, "frames": 0, "moving_t": 0.0, "pace_sum": 0.0}
	return stats[uid]

func _measure() -> void:
	var alive = []
	for u in sim.units:
		if not arena.models.has(u.uid): continue
		var v = arena.models[u.uid]
		var s = _st(u.uid)
		var p: Vector3 = v.root.position + v.motion.position
		var yaw: float = v.model.rotation.y
		if not prev.has(u.uid):
			prev[u.uid] = {"p": p, "v": Vector3.ZERO, "yaw": yaw, "state": v.state, "state_t": t, "last_state": ""}
			continue
		var pr = prev[u.uid]
		if u.alive:
			s.frames += 1
			var step = Vector3(p.x - pr.p.x, 0, p.z - pr.p.z).length()
			s.max_step = maxf(s.max_step, step)
			if step > 0.45: s.teleports += 1; log_lines.append("%.2f TELEPORT %s step %.2f" % [t, u.hero.sp, step])
			var vel = (p - pr.p) / dt
			var jerk = (vel - pr.v).length()
			if jerk > 60.0: s.jerk_spikes += 1
			var turn = absf(angle_difference(pr.yaw, yaw))
			s.max_turn = maxf(s.max_turn, turn)
			if turn > 0.3: s.snaps += 1
			if v.state != pr.state:
				s.switches += 1
				if t - pr.state_t < 0.25 and v.state == pr.last_state: s.flicker += 1
				pr.last_state = pr.state; pr.state = v.state; pr.state_t = t
			var ground = Vector2(vel.x, vel.z).length()
			if v.state == "idle" and ground > 0.8: s.idle_slide += dt
			if v.state == "walk" and ground < 0.15 and u.moving == false: s.walk_still += dt
			if u.moving:
				s.moving_t += dt; s.pace_sum += ground * dt
			# Facing during attacks / casts
			if (u.windup > 0 or u.has("pending_cast")) and u.target >= 0:
				var tg = sim.find_unit(u.target)
				if not tg.is_empty() and tg.uid != u.uid:
					var want = atan2(tg.pos.x - u.pos.x, tg.pos.y - u.pos.y)
					if absf(angle_difference(yaw, want)) > 0.9: s.misface += dt
			alive.append({"u": u, "p": p, "r": _fp(str(u.uid), v.model)})
		pr.v = (p - pr.p) / dt; pr.p = p; pr.yaw = yaw
	for i in range(alive.size()):
		for j in range(i + 1, alive.size()):
			var a = alive[i]; var b = alive[j]
			var d = Vector2(a.p.x - b.p.x, a.p.z - b.p.z).length()
			var lim = (a.r + b.r) * 0.55
			if d < lim:
				_st(a.u.uid).overlap += dt; _st(b.u.uid).overlap += dt

func _report() -> void:
	var f = FileAccess.open("%s/report_%s.txt" % [OS.get_environment("REPORT_DIR"), tag], FileAccess.WRITE)
	f.store_line("battle %s  t=%.1f finished=%s winner=%d  vfx_live=%d" % [tag, t, sim.finished, sim.winner, arena.vfx.count()])
	f.store_line("sp            team frames tele maxstep snaps maxturn flick switch idleSlide walkStill misface overlap jerk avgSpeed footR")
	for u in sim.units:
		if not stats.has(u.uid): continue
		var s = stats[u.uid]
		f.store_line("%-13s %d %5d %4d %6.2f %5d %6.2f %5d %6d %8.2f %8.2f %7.2f %7.2f %4d %6.2f %5.2f" % [u.hero.sp + ("*" if u.summon else ""), u.team, s.frames, s.teleports, s.max_step, s.snaps, s.max_turn, s.flicker, s.switches, s.idle_slide, s.walk_still, s.misface, s.overlap, s.jerk_spikes, s.pace_sum / maxf(0.01, s.moving_t), footprint.get(str(u.uid), 0.0)])
	for l in log_lines.slice(0, 40): f.store_line(l)
	if OS.get_environment("EVLOG") == "1":
		for l in ev_log: f.store_line("EV " + l)
	f.close()

var ev_log: Array = []
func _ev(e: Dictionary) -> void:
	if e.type in ["hit", "heal", "blocked", "attack", "release", "impact"]: return
	var u = sim.find_unit(int(e.get("uid", -1)))
	ev_log.append("%.2f %s %s %s" % [sim.time, e.type, e.get("effect", ""), u.hero.sp if not u.is_empty() else ""])
