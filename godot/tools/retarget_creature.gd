extends SceneTree
## Builds a creature's combat clips by retargeting Mesh2Motion's CC0 animation libraries (art/mesh2motion)
## onto the creature's existing rig, as listed in data/retarget_jobs.json. Writes an AnimationLibrary to
## assets/beasts/clips/<species>.res, which CombatAnimator layers over the model's own clips at runtime.
## The creature's .glb is never modified.
##   godot --headless --path godot -s tools/retarget_creature.gd -- --species direwolf
##   ... -- --species direwolf --chains          (print the detected chains and bone pairing, write nothing)
##   ... -- --species minotaur --only attack_1,hit_heavy
const Retargeter = preload("res://tools/retargeter.gd")
const SETS := {
	"human": ["human-base-animations.glb", "human-addon-animations.glb", "human-mocap-animations.glb"],
	"fox": ["fox-animations.glb"], "horse": ["horse-animations.glb"], "snake": ["snake-animations.glb"],
	"spider": ["spider-animations.glb"], "kaiju": ["kaiju-animations.glb"], "dragon": ["dragon-animations.glb"], "bird": ["bird-animations.glb"],
}
var args := {}
var cache := {}

func _initialize() -> void:
	var raw = OS.get_cmdline_user_args()
	var i = 0
	while i < raw.size():
		var k = raw[i].trim_prefix("--")
		if i + 1 < raw.size() and not raw[i + 1].begins_with("--"): args[k] = raw[i + 1]; i += 2
		else: args[k] = "1"; i += 1
	run.call_deferred()

func source_dir() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../art/mesh2motion").simplify_path()

## The loaded source scene that holds `clip` in one of the set's files.
func source_for(set_name: String, clip: String) -> Node3D:
	for f in SETS.get(set_name, []):
		if not cache.has(f):
			var doc = GLTFDocument.new(); var state = GLTFState.new()
			var path = source_dir().path_join(f)
			if doc.append_from_file(path, state) != OK: push_error("cannot read " + path); cache[f] = null; continue
			var scene: Node3D = doc.generate_scene(state)
			get_root().add_child(scene)
			cache[f] = scene
		var s: Node3D = cache[f]
		if s == null: continue
		var ap: AnimationPlayer = s.find_children("*", "AnimationPlayer", true, false)[0]
		if ap.has_animation(clip): return s
	return null

func run() -> void:
	var sp = str(args.get("species", ""))
	var jobs = JSON.parse_string(FileAccess.get_file_as_string("res://data/retarget_jobs.json"))
	if not jobs is Dictionary or not jobs.has(sp): print("no job for '%s' in data/retarget_jobs.json" % sp); quit(1); return
	var job: Dictionary = jobs[sp]
	var target: Node3D = load("res://assets/beasts/%s.glb" % str(job.get("model", sp))).instantiate()
	get_root().add_child(target)
	await process_frame
	var rt = Retargeter.new()
	var tsk: Skeleton3D = target.find_children("*", "Skeleton3D", true, false)[0]
	if args.has("chains"):
		var tch = Retargeter.chains_from_names(tsk, job.chains) if job.has("chains") else Retargeter.chains(tsk)
		print("target %s chains:" % sp)
		for role in tch: print("  %-6s %s" % [role, tch[role].map(func(b): return tsk.get_bone_name(b))])
		print("  facing ", Retargeter.facing(tsk, tch))
		var set_name = str(job.get("set", "human"))
		var first_clip = str(job.clips.values()[0].from)
		var src = source_for(set_name, first_clip)
		if src:
			var ssk: Skeleton3D = src.find_children("*", "Skeleton3D", true, false)[0]
			var sch = Retargeter.chains(ssk)
			print("source %s chains:" % set_name)
			for role in sch: print("  %-6s %s" % [role, sch[role].map(func(b): return ssk.get_bone_name(b))])
			print("  facing ", Retargeter.facing(ssk, sch))
			var pairs = Retargeter.pair(tsk, tch, ssk, sch)
			var lines = []
			for b in pairs: lines.append("%s->%s" % [tsk.get_bone_name(b), ssk.get_bone_name(pairs[b].source)])
			print("pairs (%d): %s" % [pairs.size(), ", ".join(lines)])
		quit(); return
	var only = Array(str(args.get("only", "")).split(",", false))
	var out_path = "res://assets/beasts/clips/%s.res" % sp
	var library: AnimationLibrary = load(out_path) if ResourceLoader.exists(out_path) and not only.is_empty() else AnimationLibrary.new()
	for clip in job.clips:
		if not only.is_empty() and clip not in only: continue
		var c: Dictionary = job.clips[clip]
		var set_name = str(c.get("set", job.get("set", "human")))
		var src = source_for(set_name, str(c.from))
		if src == null: print("  %s: source clip '%s' not found in %s" % [clip, c.from, set_name]); continue
		var trim = c.get("trim", [0.0, 1.0])
		var anim = rt.retarget(target, src, str(c.from), Array(c.get("roles", job.get("roles", []))),
			bool(c.get("loop", false)), float(c.get("speed", 1.0)), Vector2(trim[0], trim[1]), float(c.get("travel", 0.25)),
			job.get("chains", {}), float(c.get("ground", 0.0 if clip in ["death", "spawn"] else 0.6 if clip == "run" else 1.0)), float(c.get("twist", 1.0)), float(c.get("amplify", 1.0)), float(c.get("body", job.get("body", 1.0))))
		if anim == null: continue
		anim.resource_name = clip
		if library.has_animation(clip): library.remove_animation(clip)
		library.add_animation(clip, anim)
		print("  %-13s <- %s/%s  %.2fs%s" % [clip, set_name, c.from, anim.length, " (loop)" if anim.loop_mode != Animation.LOOP_NONE else ""])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/beasts/clips"))
	var err = ResourceSaver.save(library, out_path, ResourceSaver.FLAG_COMPRESS)
	print("wrote %s (%d clips) err=%d" % [out_path, library.get_animation_list().size(), err])
	for line in rt.report: if line.begins_with("missing"): print("  ", line)
	quit()
