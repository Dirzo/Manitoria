extends SceneTree
## Decimate a static Meshy GLB into a light prop mesh (.res) using Godot's LOD generator.
## env: IN=abs path glb, OUT=res://... .res, TRIS=target triangle count
func _init() -> void:
	var doc := GLTFDocument.new(); var st := GLTFState.new()
	if doc.append_from_file(OS.get_environment("IN"), st) != OK: print("load fail"); quit(); return
	var root = doc.generate_scene(st)
	var target = int(OS.get_environment("TRIS")) if OS.get_environment("TRIS") != "" else 6000
	var verts := PackedVector3Array(); var norms := PackedVector3Array(); var uvs := PackedVector2Array(); var idx := PackedInt32Array()
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var xf: Transform3D = mi.global_transform if mi.is_inside_tree() else _xf(mi)
		for s in range(mi.mesh.get_surface_count()):
			var a = mi.mesh.surface_get_arrays(s); var base = verts.size()
			for v in a[Mesh.ARRAY_VERTEX]: verts.append(xf * v)
			var n = a[Mesh.ARRAY_NORMAL]
			for k in range(a[Mesh.ARRAY_VERTEX].size()): norms.append((xf.basis * n[k]).normalized() if n.size() > k else Vector3.UP)
			var uv = a[Mesh.ARRAY_TEX_UV]
			for k in range(a[Mesh.ARRAY_VERTEX].size()): uvs.append(uv[k] if uv != null and uv.size() > k else Vector2.ZERO)
			var ii = a[Mesh.ARRAY_INDEX]
			if ii == null: ii = range(a[Mesh.ARRAY_VERTEX].size())
			for k in ii: idx.append(base + k)
	print("in tris ", idx.size() / 3, " verts ", verts.size())
	var im := ImporterMesh.new(); var arr = []; arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts; arr[Mesh.ARRAY_NORMAL] = norms; arr[Mesh.ARRAY_TEX_UV] = uvs; arr[Mesh.ARRAY_INDEX] = idx
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, arr)
	im.generate_lods(60, 60, [])
	var best: PackedInt32Array = idx
	for l in range(im.get_surface_lod_count(0)):
		var li = im.get_surface_lod_indices(0, l)
		print(" lod ", l, " tris ", li.size() / 3)
		best = li
		if li.size() / 3 <= target: break
	# Compact to used vertices, normalise size: fit height to 1.0, base at y=0, centred.
	var remap = {}; var nv := PackedVector3Array(); var nn := PackedVector3Array(); var nu := PackedVector2Array(); var ni := PackedInt32Array()
	for k in best:
		if not remap.has(k): remap[k] = nv.size(); nv.append(verts[k]); nn.append(norms[k]); nu.append(uvs[k])
		ni.append(remap[k])
	var aabb := AABB(nv[0], Vector3.ZERO)
	for v in nv: aabb = aabb.expand(v)
	var sc = 1.0 / maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var c = aabb.get_center(); c.y = aabb.position.y
	for k in range(nv.size()): nv[k] = (nv[k] - c) * sc
	var out := ArrayMesh.new(); var oa = []; oa.resize(Mesh.ARRAY_MAX)
	oa[Mesh.ARRAY_VERTEX] = nv; oa[Mesh.ARRAY_NORMAL] = nn; oa[Mesh.ARRAY_TEX_UV] = nu; oa[Mesh.ARRAY_INDEX] = ni
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, oa)
	print("out tris ", ni.size() / 3, " verts ", nv.size(), " size ", aabb.size * sc)
	ResourceSaver.save(out, OS.get_environment("OUT"))
	quit()

func _xf(n: Node) -> Transform3D:
	var t := Transform3D.IDENTITY; var p = n
	while p is Node3D: t = p.transform * t; p = p.get_parent()
	return t
