class_name SkillVFX
extends RefCounted
## Icon-directed engine animations. Shared geometry, explicit identity for every action.
const WEB=preload("res://shaders/vfx/silk.gdshader")
const LAVA=preload("res://shaders/vfx/lava.gdshader")
const PALETTES={
 "minotaur":["cc4931","ffe2a1"],"golem":["459cff","eefaff"],"troll":["93b83e","eeffc5"],"wendigo":["74bcff","edf8ff"],
 "direwolf":["94bbff","f5faff"],"manticore":["b85aff","efd4ff"],"griffin":["eac56b","fff8df"],"kitsune":["a653ff","f1d4ff"],
 "wyvern":["9fdb34","eaffb7"],"harpy":["40c2c9","d7ffff"],"phoenix":["ff9b22","fff3b4"],"kirin":["e0c770","e5fff5"],
 "basilisk":["43d79b","d4ffb0"],"treant":["b39a40","fff1a3"],"naga":["36ccda","eaffff"],"unicorn":["c4c1ff","fffaf1"],
 "cerberus":["fa5d19","ffc985"],"nemean":["efbb49","fff4c6"],"yeti":["75bdff","effaff"],"zaratan":["49c1dd","ffe6aa"],
 "owlbear":["cba355","ffefbd"],"hydra":["65cd39","d4ffb2"],"chimera":["f59029","ffe6a1"],"gargoyle":["9f6ce5","edd6ff"],
 "nekomata":["a25aff","ead5ff"],"jackalope":["99c463","fff0ad"],"cyclops":["e88a35","ffdb94"],"thunderbird":["4d9eff","e4f5ff"],
 "sphinx":["e4bd50","fff2b5"],"pegasus":["a4d8ee","fff8e8"],"arachne":["9a52eb","d6ffc0"],"salamander":["ff5719","ffd387"]}
static func decorate(c: Dictionary,credit: String,effect: String) -> Dictionary:
 var sp=str(c.sp)
 if not PALETTES.has(sp):return c
 var key=credit.trim_prefix("ability:") if credit.begins_with("ability:") else "signature"
 var entry=SkillScaling.audited(sp,key)
 c.skill_key=key;c.skill_id=sp+":"+key;c.effect=effect;c.rider=entry.get("rider","none")
 c.build_path=entry.get("build_path","ap");c.variant=abs(hash(c.skill_id))%8
 c.color=Color(PALETTES[sp][0]);c.hot=Color(PALETTES[sp][1]);c.alt=c.color.lerp(c.hot,.35)
 c.smoke=Color(c.color.r*.3,c.color.g*.3,c.color.b*.3,.4)
 if sp=="arachne":
  c.el="shadow" if effect in ["roots","ward","brood"] else "poison"
  c.color=Color("a06aff") if c.el=="shadow" else Color("80d94b");c.alt=Color("a06aff");c.motif="droplet" if c.el=="poison" else "glow"
 if sp=="chimera":
  if effect in ["toxic","roots","frost"]:c.color=Color("67ce45");c.el="poison";c.motif="droplet"
  elif effect in ["ambush","execute","whirl"]:c.color=Color("e3b84e");c.motif="shard"
 if sp in ["griffin","harpy","thunderbird","pegasus"] and effect in ["barrage","wisps","whirl"]:c.motif="feather"
 return c

static func decal(vfx: VFX,shader: Shader,at: Vector3,radius: float,life: float,tint: Color) -> void:
 var node=MeshInstance3D.new();node.mesh=VFX.ground_quad();node.position=at+Vector3.UP*.07;node.scale=Vector3(radius,1,radius)
 var mat=ShaderMaterial.new();mat.shader=shader;mat.set_shader_parameter("tint",tint)
 node.material_override=mat;vfx._track(node,life,[mat])

static func web(vfx: VFX,at: Vector3,radius: float,life: float) -> void:
 decal(vfx,WEB,at,radius,life,Color("aa78ff"))
 # Silk coils rise into a cocoon, rather than growing wooden vines.
 for i in range(3):
  var points=PackedVector3Array()
  for j in range(24):
   var t=j/23.0;var a=t*TAU*1.7+i*TAU/3
   points.append(at+Vector3(cos(a)*(.9-t*.35),.15+t*1.8,sin(a)*(.9-t*.35)))
  vfx.vine(points,.025,Color("cab1ff"),Color("a979ff"),life,i*.06,false)

static func play(vfx: VFX,family: String,c: Dictionary,from: Vector3,to: Vector3,targets: Array=[]) -> bool:
 if c.sp=="arachne" and family in ["roots","frost","brood","ward"]:
  if family=="brood":
   decal(vfx,WEB,from,2.0,1.2,Color("aa78ff"))
   for i in range(2):
    var at=from+Vector3((i*2-1)*.65,.35,0)
    vfx.shield(at,.45,Color("8fdc54"),.75,.05)
    vfx.spray(at,14,"glow",Color("a978ff"),Vector2(1.5,3),Vector2(.35,.65),.07,Vector3.UP,1,3,1,0,.5)
  elif family=="ward":
   web(vfx,from,1.3,1.5);vfx.shield(from+Vector3.UP*.9,1.15,Color("b487ff"),1.5,.5)
   return false # Keep the normal ward composition for all allied recipients.
  else:
   web(vfx,to,c.get("area_radius",2.1),1.8)
   for at in targets:
    if at.distance_to(to)>.2:web(vfx,at,.65,1.8)
   vfx.glow(to+Vector3.UP,2.0,Color("b68aff"),.35,0,0,2.0)
  return true
 if family=="roots" and c.sp!="treant":
  for i in range(4):
   var points=PackedVector3Array()
   for j in range(20):
    var t=j/19.0;var a=t*TAU+i*TAU/4+c.variant*.1
    points.append(to+Vector3(cos(a)*.9,.1+t*1.7,sin(a)*.9))
   vfx.vine(points,.06,c.color,c.hot,1.8,i*.04,false)
  vfx.rune(to,2.0,c.color,0,1.8)
  return true
 if family=="frost" and c.el not in ["ice","water"]:
  for i in range(8):
   var a=i*TAU/8
   vfx.crystal(to+Vector3(cos(a),0,sin(a))*1.1,.9,.13,c.color,1.3,i*.025)
  vfx.rune(to,2.2,c.color,1,.6)
  return true
 if family=="magma":
  decal(vfx,LAVA,to,c.get("area_radius",2.6),4.0,c.color)
  for i in range(8):
   var a=i*TAU/8;var at=to+Vector3(cos(a),0,sin(a))*1.7
   vfx.rock(at,.18,Color("30241e"),1,1.1,0,func(node,t):node.position=at+Vector3.UP*sin(minf(t,1)*PI)*1.5)
  vfx.spray(to,36,"ember",c.hot,Vector2(2,5),Vector2(.4,.9),.09,Vector3.UP,.9,5)
  return true
 if family in ["execute","ambush","maul","gore","triplebite","skystrike","antlerrush"]:
  # Three curved anatomical slash trails establish anticipation-to-contact direction.
  var d=(to-from).normalized();var side=d.cross(Vector3.UP).normalized()
  for i in range(3):
   var pts=PackedVector3Array()
   for j in range(10):
    var t=j/9.0;pts.append(to+Vector3.UP*(.6+sin(t*PI)*.7)+side*((t-.5)*2)+d*((i-1)*.22))
   vfx.vine(pts,.045,c.hot,c.color,.4,i*.04,false)
 if c.get("rider","none") in ["root","venom","burn"]:
  vfx.spray(to+Vector3.UP*.4,10,c.motif,c.alt,Vector2(.8,1.8),Vector2(.45,.8),.08,Vector3.UP,.6,1,1,0,.15)
 return false

static func projectile_mesh(root: Node3D,c: Dictionary,effect: String) -> void:
 if effect not in ["barrage","wisps"]:return
 var mesh=MeshInstance3D.new();var prism=PrismMesh.new();prism.size=Vector3(.12,.65,.2);mesh.mesh=prism
 var mat=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=c.color;mat.emission_enabled=true;mat.emission=c.hot;mat.emission_energy_multiplier=1.4
 mesh.material_override=mat;mesh.rotation.x=-PI*.5;root.add_child(mesh)
 root.set_meta("skill_id",c.get("skill_id",""))
