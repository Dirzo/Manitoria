class_name AttackVisuals
extends RefCounted
static var trail_shader: Shader
# Physical attack grammar. Skills override anatomy only when their action demands it.
static func style(species: String,effect: String="basic") -> String:
 if effect in ["gore","antlerrush"]:return "thrust"
 if effect=="triplebite":return "bite"
 if effect in ["smash","quake"]:return "slam"
 if effect=="whirl":return "sweep"
 if effect not in ["basic","maul","ambush","execute","venom","vanish","skystrike","stonedive"]:return ""
 if effect=="stonedive":return "slam"
 if species in ["minotaur"]:return "sweep"
 if species in ["golem","troll","cyclops","treant","zaratan","yeti"]:return "slam"
 if species in ["direwolf","cerberus","hydra","basilisk","salamander","wyvern","naga","arachne"]:return "bite"
 if species in ["unicorn","kirin","jackalope","pegasus"]:return "thrust"
 return "claw"

static func ribbon(arena: Node3D,points: PackedVector3Array,width: float,color: Color,duration: float) -> void:
 var mesh=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(points.size()-1):
  var tangent=(points[i+1]-points[i]).normalized()
  var side=tangent.cross(Vector3(0.25,1,0.3)).normalized()
  if side.length_squared()<0.1:side=Vector3.RIGHT
  var w0=width*sin(PI*float(i)/float(points.size()-1))+.004
  var w1=width*sin(PI*float(i+1)/float(points.size()-1))+.004
  var vertices=[points[i]-side*w0,points[i]+side*w0,points[i+1]+side*w1,points[i]-side*w0,points[i+1]+side*w1,points[i+1]-side*w1]
  for k in range(6):
   mesh.surface_set_uv(Vector2(float(i+(1 if k in [2,4,5] else 0))/float(points.size()-1),1.0 if k in [1,2,4] else 0.0))
   mesh.surface_add_vertex(vertices[k])
 mesh.surface_end()
 if trail_shader==null:
  trail_shader=Shader.new();trail_shader.code="shader_type spatial; render_mode unshaded,cull_disabled,depth_test_disabled; uniform vec4 tint:source_color; uniform float reveal=0.0; uniform float fade=1.0; void fragment(){ ALBEDO=tint.rgb; EMISSION=tint.rgb*.08; ALPHA=tint.a*fade*sin(UV.y*3.14159)*(1.0-smoothstep(reveal-.07,reveal,UV.x)); }"
 var mat=ShaderMaterial.new();mat.shader=trail_shader;mat.set_shader_parameter("tint",color)
 var node=arena.mesh(arena.effects,mesh,mat);node.set_meta("attack_ribbon",true)
 var tween=arena.effect_tween();tween.tween_method(func(v):mat.set_shader_parameter("reveal",v),0.0,1.08,duration*.4)
 tween.tween_method(func(v):mat.set_shader_parameter("fade",v),1.0,0.0,duration*.6);tween.tween_callback(node.queue_free)

static func strike(arena: Node3D,origin: Vector2,target: Vector2,species: String,effect: String="basic",rarity: String="Uncommon") -> void:
 var kind=style(species,effect)
 if kind.is_empty():return
 var forward=Vector3(target.x-origin.x,0,target.y-origin.y).normalized()
 if forward.length_squared()<.1:forward=Vector3.RIGHT
 var side=forward.cross(Vector3.UP)
 var center=Vector3(target.x,1.45,target.y)
 var tint=Color("f1e3cc") # Bone, steel and contact light, rather than magical species glow.
 var width=.055 if effect=="basic" else .10
 if rarity=="Legendary":width*=1.3;tint=Color("fff0c5")
 var paths=3 if kind=="claw" else 2 if kind in ["bite","thrust"] else 1
 for lane in range(paths):
  var points=PackedVector3Array()
  for j in range(17):
   var t=float(j)/16;var point=center
   match kind:
    "claw":point+=side*((t-.5)*1.3)+Vector3.UP*((.5-t)*.7+(lane-1)*.18)+forward*((t-.5)*.95+(lane-1)*.40+sin(t*PI)*.15)
    "bite":point+=side*((t-.5)*1.35)+forward*((1 if lane==0 else -1)*sin(t*PI)*(.36+.12*abs(sin(t*PI*4))))+Vector3.UP*.1
    "thrust":point+=forward*((t-.8)*1.9)+side*((lane-.5)*.34)+Vector3.UP*sin(t*PI)*.10
    "slam":point+=Vector3.UP*(1.8-t*2.1)+forward*(t-.5)*.45
    "sweep":point+=side*sin((t-.5)*2.4)*1.4+forward*cos((t-.5)*2.4)*.65+Vector3.UP*(.2-t*.4)
   points.append(point)
  ribbon(arena,points,width*(1.5 if kind in ["slam","sweep"] else .75 if kind=="claw" else 1.0),tint,.23 if effect=="basic" else .38)
