extends RefCounted
## Test stagings for the VFX gallery.

func _model(root: Node3D, sp: String, pos: Vector3, face: Vector3, scale: float = 0.72) -> void:
	var n = load("res://assets/beasts/%s.glb" % sp).instantiate()
	n.position = pos; n.scale = Vector3.ONE * scale; root.add_child(n)
	n.rotation.y=atan2(face.x-pos.x,face.z-pos.z)
	var ap = n.find_children("*", "AnimationPlayer", true, false)
	if ap.size() > 0 and ap[0].has_animation("idle"): ap[0].play("idle"); ap[0].seek(0.5, true); ap[0].pause()

func stage(name: String, vfx: VFX, root: Node3D) -> void:
	if name.begins_with("item-"):
		var id=name.trim_prefix("item-");var from=Vector3(-3,0,0);var to=Vector3(2,0,0)
		_model(root,"minotaur",from,to);_model(root,"golem",to,from,.55)
		ItemFeedback.play(vfx,{"item_id":id,"stage":"proc"},from,to);return
	if name.begins_with("skill-"):
		var parts=name.split("-");var sp=parts[1];var key=parts[2]
		var a=SkillScaling.audited(sp,key);var caster=Vector3(-3,0,0);var target=Vector3(2,0,0)
		_model(root,sp,caster,target);_model(root,"golem",target,caster,.55)
		var credit="signature" if key=="signature" else "ability:"+key
		var c=AbilityFX.ctx(sp,Color.TRANSPARENT,"Rare",credit,a.effect)
		AbilityFX.cast_flash(vfx,c,caster);AbilityFX.play(vfx,a.effect,c,caster,target,[target]);return
	if name.begins_with("fam-"):
		# fam-<family>-<caster species>
		var parts = name.split("-")
		var family = parts[1]; var sp = parts[2]
		var caster = Vector3(-4.2, 0, 0.6)
		var foes = [Vector3(3.0, 0, 0), Vector3(4.2, 0, 1.6), Vector3(4.0, 0, -1.5)]
		var friends = [Vector3(-5.6, 0, -1.8), Vector3(-5.8, 0, 2.4)]
		_model(root, sp, caster, foes[0])
		var support = family in ["ward", "renew", "rally", "tidal", "radiance", "regrowth", "bulwark", "shellup", "tailwind", "prideroar", "rootbloom"]
		for p in foes: _model(root, "golem", p, caster, 0.55)
		for p in friends: _model(root, "direwolf", p, foes[0], 0.55)
		var c = AbilityFX.ctx(sp, Color(0, 0, 0, 0), "Rare")
		var targets = ([caster] + friends) if support else foes
		var to = foes[0]
		AbilityFX.play(vfx, family, c, caster, to, targets)
		return
	match name:
		"prim_fire":
			for i in range(7):
				var a = i * TAU / 7.0
				vfx.flame(Vector3(cos(a) * 0.6, 0, sin(a) * 0.6), Vector2(0.9, 1.7), Color("ff5a14"), 1.8, i * 0.05)
			vfx.flame(Vector3.ZERO, Vector2(1.4, 2.6), Color("ff6a1a"), 1.8)
			vfx.spray(Vector3(0, 0.4, 0), 60, "ember", Color("ffae55"), Vector2(1.5, 3.5), Vector2(0.8, 1.6), 0.09, Vector3.UP, 0.6, -1.0, 0.6, 0.3)
			vfx.smoke(Vector3(0, 2.2, 0), 2.4, Color(0.2, 0.17, 0.15, 0.55), 2.0, 0.2)
			vfx.rune(Vector3.ZERO, 2.0, Color("ff7a2a"), 4, 2.0)
		"prim_bolt":
			vfx.bolt(Vector3(0.4, 9, 0.2), Vector3(0, 0.1, 0), Color("7fb5ff"), 0.3, 0.6, 3)
			vfx.bolt(Vector3(-2.4, 9, -1), Vector3(-2.2, 0.1, -0.8), Color("7fb5ff"), 0.25, 0.6, 2, 0.12)
			vfx.glow(Vector3(0, 0.3, 0), 3.2, Color("a8cbff"), 0.5, 0)
			vfx.rune(Vector3.ZERO, 1.6, Color("9cc4ff"), 1, 0.7)
			vfx.spray(Vector3(0, 0.2, 0), 40, "spark", Color("cfe3ff"), Vector2(3, 7), Vector2(0.3, 0.7), 0.06, Vector3.UP, 1.2, 9.0, 1.5, 0.08)
		"prim_tornado":
			vfx.swirl(Vector3.ZERO, 0.45, 2.2, 4.2, Color("b7d8e8"), Color("ffffff"), 2.2, 9.0, 1.0)
			vfx.swirl(Vector3.ZERO, 0.3, 1.6, 3.6, Color("8fb4c8"), Color("e6f4ff"), 2.2, 12.0, 0.8, 0.1)
			vfx.spray(Vector3(0, 0.5, 0), 50, "leaf", Color("9dc86a"), Vector2(1.5, 3.5), Vector2(1.0, 2.0), 0.16, Vector3.UP, 1.0, 0.5, 0.5, 0.0, 0.0, 2, 1.2)
			vfx.smoke(Vector3(0, 0.3, 0), 3.0, Color(0.55, 0.5, 0.42, 0.45), 2.0, 0.0, Vector3(0, 0.2, 0))
		"prim_shield":
			vfx.shield(Vector3(0, 1.1, 0), 1.3, Color("6fe6d6"), 2.0)
			vfx.rune(Vector3.ZERO, 1.8, Color("6fe6d6"), 0, 2.0)
			vfx.spray(Vector3(0, 0.2, 0), 30, "star", Color("b8fff4"), Vector2(0.6, 1.4), Vector2(1.0, 1.8), 0.12, Vector3.UP, 0.4, -0.4, 0.3, 0.0, 0.0, 1, 1.2)
		"prim_beam":
			vfx.beam(Vector3(-4, 1.3, 0), Vector3(4, 1.1, 0), 0.28, Color("ffcf6a"), 1.0)
			vfx.beam(Vector3(-4, 1.3, 0), Vector3(4, 1.1, 0), 0.08, Color("fff6d8"), 1.0)
			vfx.glow(Vector3(-4, 1.3, 0), 1.6, Color("ffd68a"), 1.0, 1)
			vfx.spray(Vector3(-4, 1.3, 0), 50, "spark", Color("ffe2a0"), Vector2(4, 9), Vector2(0.4, 0.9), 0.05, Vector3.RIGHT, 0.25, 0.0, 0.5, 0.06)
		"prim_ice":
			for i in range(9):
				var a = i * 2.4; var r = 0.4 + (i % 3) * 0.35
				vfx.crystal(Vector3(cos(a) * r, 0, sin(a) * r), 1.0 + (i % 4) * 0.35, 0.18 + (i % 2) * 0.06, Color("9fdcff"), 2.0, i * 0.03, Vector3(sin(a) * 0.35, 0, cos(a) * 0.35))
			vfx.smoke(Vector3(0, 0.4, 0), 3.0, Color(0.8, 0.92, 1.0, 0.35), 2.0, 0.0, Vector3(0, 0.15, 0))
			vfx.spray(Vector3(0, 1.0, 0), 40, "snow", Color("e6f7ff"), Vector2(0.5, 1.5), Vector2(1.0, 2.0), 0.1, Vector3.UP, 1.0, 0.5, 0.5)
		"prim_rock":
			for i in range(6):
				var a = i * TAU / 6
				vfx.rock(Vector3(cos(a) * 1.2, 0.2, sin(a) * 1.2), 0.25 + (i % 3) * 0.1, Color("7b6e62"), 0.0, 2.0)
			vfx.rock(Vector3(0, 0.5, 0), 0.6, Color("4a3a30"), 1.0, 2.0)
			vfx.rune(Vector3.ZERO, 2.4, Color("ff9a55"), 2, 2.0)
			vfx.smoke(Vector3(0, 0.4, 0), 2.6, Color(0.5, 0.44, 0.38, 0.6), 2.0)
		"prim_vine":
			for i in range(5):
				var a = i * TAU / 5; var pts := PackedVector3Array()
				for k in range(12):
					var t = k / 11.0
					pts.append(Vector3(cos(a + t * 3.0) * (1.1 - t * 0.6), t * 2.2, sin(a + t * 3.0) * (1.1 - t * 0.6)))
				vfx.vine(pts, 0.11, Color("3d2a1a"), Color("9cff6a"), 2.0, i * 0.06)
			vfx.spray(Vector3(0, 0.3, 0), 30, "leaf", Color("8fd35a"), Vector2(0.5, 1.5), Vector2(1.0, 2.0), 0.14, Vector3.UP, 1.0, 0.3)
		"prim_runes":
			vfx.rune(Vector3(-3, 0, 0), 1.4, Color("c69cff"), 0, 2.0)
			vfx.rune(Vector3(0, 0, 0), 1.6, Color("ffd27a"), 1, 1.0)
			vfx.rune(Vector3(3, 0, 0), 1.4, Color("ff8a3a"), 2, 2.0)
			vfx.rune(Vector3(0, 0, -3), 1.6, Color("8ae06a"), 3, 2.0)
		"prim_smoke":
			for i in range(8):
				vfx.smoke(Vector3((i % 4) * 0.5 - 0.75, 0.5 + (i / 4) * 0.5, 0), 1.6, Color(0.35, 0.8, 0.3, 0.5), 2.0, i * 0.05, Vector3(0, 0.4, 0), 0.3)
			vfx.spray(Vector3(0, 0.3, 0), 30, "droplet", Color("9cff6a"), Vector2(1, 2.5), Vector2(0.5, 1.2), 0.1, Vector3.UP, 0.8, 6.0)
