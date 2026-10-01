class_name CardParticles
extends Node3D
const MAX_PARTICLES=1600
const MAX_BATCHES=80
static var palettes: Dictionary={}
static var profiles: Dictionary={}
static var enabled=true
var batches: Array=[]
var materials: Dictionary={}
var clock=0.0
var trail_times: Dictionary={}
var shield_values: Dictionary={}
var support_profiles: Dictionary={}
var emitted=0
var dropped=0
var rng=RandomNumberGenerator.new()

static func profile(sp: String,credit: String,effect: String="basic") -> Dictionary:
 var key=sp+"/"+credit+"/"+effect
 if profiles.has(key):return profiles[key]
 if palettes.is_empty():palettes=JSON.parse_string(FileAccess.get_file_as_string("res://data/card-particle-palettes.json"))
 var art=effect
 if not sp.is_empty() and HeroData.species.has(sp):art=AbilityArt.metric_info(sp,credit).art
 if art.begins_with("discovery:") and not palettes.has(art):
  var pieces=art.split(":");art=HeroData.learned_ability(pieces[1],int(pieces[2])).effect
 var palette=palettes.get(art,palettes.get(effect,{"primary":"b2e5ff","highlight":"ffffff"}))
 var motif="spark"
 if effect in ["fire","flamewave","magma","meteor","rebirth","threefold"]:motif="ember"
 elif effect in ["frost","frostroar","gaze"]:motif="crystal"
 elif effect in ["roots","rootbloom","regrowth","toxic","venom","acid","brood","antlerrush"]:motif="leaf"
 elif effect in ["tailwind","gust","skystrike","shriek","sky","stonedive"]:motif="feather"
 elif effect in ["tidal","renew","radiance"]:motif="petal"
 elif effect in ["quake","fissure","smash","boulder","bulwark","ward","shellup"]:motif="shard"
 elif effect in ["chain","storm","stormcall","beam","rally","prideroar"]:motif="star"
 elif effect in ["drain","vanish","fear","silence","wisps","foxfire","hunger","riddle"]:motif="wisp"
 var result={"color":Color(palette.primary),"highlight":Color(palette.highlight),"motif":motif,"art":art,"effect":effect,"physical":not AttackVisuals.style(sp,effect).is_empty()}
 profiles[key]=result
 return result

func count() -> int:
 var total=0
 for batch in batches:total+=batch.particles.size()
 return total

func particle_material(motif: String) -> ShaderMaterial:
 if materials.has(motif):return materials[motif]
 var shader=Shader.new();shader.code='''shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
uniform int motif = 0;
uniform float age = 0.0;
uniform int motion_mode = 0;
void vertex(){
 float t=age/max(.01,INSTANCE_CUSTOM.w);
 float growth=.5+.5*sin(clamp(t,0.0,1.0)*3.14159);
 float sx=length(MODEL_MATRIX[0].xyz)*growth;float sy=length(MODEL_MATRIX[1].xyz)*growth;
 vec4 anchor=MODEL_MATRIX[3];
 anchor.xyz+=INSTANCE_CUSTOM.xyz*age*vec3(1.45,1.0,1.45);
 if(motion_mode!=1){
  anchor.y+=sin(age*4.0+INSTANCE_CUSTOM.w*8.0)*.07;
  if(motif==1||motif==3||motif==5||motif==8){anchor.y+=age*.35;}
  else if(motion_mode==0){anchor.y-=age*age*.8;}
 }
 COLOR.a*=max(0.0,1.0-t)*.8;
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(vec4(INV_VIEW_MATRIX[0].xyz*sx,0.0),vec4(INV_VIEW_MATRIX[1].xyz*sy,0.0),vec4(INV_VIEW_MATRIX[2].xyz,0.0),anchor);
}
void fragment(){
 vec2 p=UV*2.0-1.0;float d=length(p);float shape=0.0;
 if(motif==1){shape=1.0-smoothstep(0.15,0.95,length(vec2(p.x*(1.6+p.y*.7),p.y)));}
 else if(motif==2){shape=1.0-smoothstep(.6,1.0,abs(p.x)*1.8+abs(p.y));}
 else if(motif==3){shape=(1.0-smoothstep(.65,1.0,length(vec2(p.x*1.8,p.y))))*(.65+.35*cos(p.y*14.0+p.x*4.0));}
 else if(motif==4){shape=1.0-smoothstep(.4,1.0,length(vec2((p.x-.2*sin(p.y*3.0))*3.0,p.y)));}
 else if(motif==5){shape=1.0-smoothstep(.4,1.0,length(vec2(p.x*1.4,p.y)));}
 else if(motif==6){shape=1.0-smoothstep(.65,.85,max(abs(p.x)*1.3,abs(p.y))+.3*abs(p.x+p.y));}
 else if(motif==7){shape=pow(max(0.0,1.0-d),3.0)+.6*pow(max(0.0,1.0-abs(p.x)*12.0),3.0)*(1.0-abs(p.y))+.6*pow(max(0.0,1.0-abs(p.y)*12.0),3.0)*(1.0-abs(p.x));}
 else{shape=pow(max(0.0,1.0-d),2.0);}
 ALBEDO=COLOR.rgb;EMISSION=COLOR.rgb*1.7;ALPHA=clamp(shape*COLOR.a,0.0,1.0);
}'''
 var material=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("motif",["spark","ember","crystal","leaf","feather","petal","shard","star","wisp"].find(motif));materials[motif]=material;return material

func burst(point: Vector3,p: Dictionary,amount: int=24,mode: String="burst",rarity: String="Uncommon",duration: float=1.0,destination: Vector3=Vector3.ZERO) -> void:
 amount=mini(amount,MAX_PARTICLES-count())
 if amount<=0 or batches.size()>=MAX_BATCHES:dropped+=1;return
 var node=MultiMeshInstance3D.new();add_child(node)
 var material=particle_material(p.motif).duplicate();material.set_shader_parameter("motion_mode",1 if mode=="windup" else 0 if mode=="burst" else 2)
 var mesh=QuadMesh.new();mesh.size=Vector2.ONE;mesh.material=material
 var multi=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_colors=true;multi.use_custom_data=true;multi.mesh=mesh;multi.instance_count=amount;node.multimesh=multi
 multi.custom_aabb=AABB(point-Vector3.ONE*12,Vector3.ONE*24)
 var particles=[]
 for i in range(amount):
  var direction=Vector3(rng.randf_range(-1,1),rng.randf_range(-.2,1.3),rng.randf_range(-1,1)).normalized()
  var origin=point+direction*rng.randf_range(0,.25)
  var velocity=direction*rng.randf_range(.7,2.8)
  if mode=="windup":origin=point+direction*rng.randf_range(.6,1.4);velocity=(point-origin)/duration
  elif mode=="line":origin=point.lerp(destination,float(i)/maxi(1,amount-1));velocity*=.4
  elif mode=="rise":origin+=Vector3(rng.randf_range(-.6,.6),rng.randf_range(-.3,.3),rng.randf_range(-.6,.6));velocity=Vector3(direction.x*.3,rng.randf_range(.6,1.8),direction.z*.3)
  elif mode=="trail":velocity*=.18
  var forward=(destination-point).normalized()
  if forward.length_squared()<.1:forward=Vector3.RIGHT
  var side=forward.cross(Vector3.UP).normalized()
  if mode=="cone":origin=point+forward*.45;velocity=forward*rng.randf_range(3,6)+side*rng.randf_range(-1.1,1.1)+Vector3.UP*rng.randf_range(-.1,.7)
  elif mode=="jet":origin=point+side*rng.randf_range(-.12,.12);velocity=forward*rng.randf_range(4,7)
  elif mode=="ground":origin=point+Vector3(rng.randf_range(-1.5,1.5),-point.y+.12,rng.randf_range(-1.2,1.2));velocity=Vector3(0,rng.randf_range(1.1,2.8),0)
  elif mode=="fall":origin=point+Vector3(rng.randf_range(-.35,.35),rng.randf_range(1.8,3),rng.randf_range(-.35,.35));velocity=Vector3(0,-rng.randf_range(4,6),0)
  elif mode=="contact":origin=point+direction*.08;velocity=forward*rng.randf_range(.4,1.2)+Vector3.UP*rng.randf_range(.2,.7)
  var color=p.highlight if i%5==0 else p.color
  if rarity=="Legendary" and i%9==0:color=color.lerp(Color("fff3bd"),.35)
  particles.append({"origin":origin,"velocity":velocity,"size":rng.randf_range(.14,.35)*(1.25 if rarity=="Legendary" else 1.0),"life":duration*rng.randf_range(.75,1.2),"color":color,"phase":rng.randf()*TAU})
  var size=particles[-1].size
  multi.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3(size,size*(1.8 if p.motif in ["ember","feather","crystal"] else 1.0),size)),origin));multi.set_instance_color(i,color)
  multi.set_instance_custom_data(i,Color(velocity.x,velocity.y,velocity.z,particles[-1].life))
 batches.append({"node":node,"particles":particles,"age":0.0,"mode":mode,"motif":p.motif,"material":material,"duration":duration*1.2});emitted+=amount

func advance(dt: float) -> void:
 if dt<=0:return
 clock+=dt
 for batch in batches.duplicate():
  batch.age+=dt
  batch.material.set_shader_parameter("age",batch.age)
  if batch.age>=batch.duration:batch.node.queue_free();batches.erase(batch)

func event(e: Dictionary) -> void:
 if not enabled or not e.has("pos"):return
 var effect=str(e.get("effect","basic"));var credit=str(e.get("credit","basic"));var p=profile(str(e.get("species","")),credit,effect)
 var rarity=str(e.get("rarity","Uncommon"));var factor=2 if rarity=="Legendary" else 1.45 if rarity=="Rare" else 1.0
 var origin=Vector3(e.pos.x,1.05,e.pos.y);var end=e.get("target",e.pos);var target=Vector3(end.x,1.0,end.y)
 var physical=p.physical
 match e.type:
  "telegraph":
   if not physical:burst(origin,p,roundi(7*factor),"rise",rarity,SkillCombat.windup(effect))
  "cast":
   if physical:return # Actual victim hit events draw anatomy-specific contact trails.
   if effect in ["ward","rally","bulwark","shellup","radiance","renew","tidal","rootbloom"]:support_profiles[e.get("uid",-1)]={"profile":p,"time":clock}
   if effect in ["beam","fissure","drain","gaze","riddle"]:
    burst(target if effect=="drain" else origin,p,roundi(22*factor),"jet",rarity,.45,origin if effect=="drain" else target)
   elif effect in ["fire","flamewave","toxic","acid","gust","threefold"]:burst(origin,p,roundi(24*factor),"cone",rarity,.6,target)
   elif effect in ["roots","rootbloom","frost","magma"]:burst(target,p,roundi(22*factor),"ground",rarity,.8)
   elif effect in ["storm","stormcall","chain","meteor","boulder","barrage","wisps"]:pass # Trails and actual impacts identify each target.
   else:burst(origin,p,roundi(12*factor),"rise",rarity,.8)
  "impact":burst(origin,p,roundi((6 if e.get("small",false) else 15)*factor),"ground" if effect in ["meteor","boulder"] else "contact",rarity,.5,target)
  "bolt":burst(target,p,roundi(10*factor),"fall" if effect in ["storm","stormcall"] else "contact",rarity,.4,origin)
  "heal":
   if e.get("amount",0)>=3:burst(origin,p,9,"rise",rarity,1.0)
  "death":burst(origin,p,12,"rise",rarity,.8)

func sync(sim: BattleSim,dt: float) -> void:
 if not enabled or dt<=0:return
 advance(dt)
 var live={}
 for shot in sim.projectiles:
  var key="p%d"%shot.id;live[key]=true
  if clock<trail_times.get(key,0):continue
  trail_times[key]=clock+.07
  var source=sim.find_unit(shot.source)
  if source.is_empty():continue
  var p=profile(source.hero.sp,shot.get("credit","basic"),shot.effect)
  var t=clampf(1-shot.remaining/shot.duration,0,1);var destination=sim.find_unit(shot.target)
  var end=destination.pos if not destination.is_empty() else shot.last_pos
  var pos=shot.origin.lerp(end,t)
  burst(Vector3(pos.x,1.2+sin(t*PI)*(4 if shot.effect=="meteor" else .35),pos.y),p,4,"trail",RarityStyle.for_skill(source.hero,shot.get("credit","basic")),.4)
 for u in sim.units:
  var key="u%d"%u.uid;live[key]=true
  if u.alive and u.shield>shield_values.get(u.uid,0)+2:
   var p=profile(u.hero.sp,"signature",HeroData.species[u.hero.sp].ab)
   var latest=-1.0
   for ally in sim.living(u.team):
    var source=support_profiles.get(ally.uid,{})
    if not source.is_empty() and clock-source.time<1.5 and source.time>latest:
     p=source.profile;latest=source.time
   burst(Vector3(u.pos.x,.7,u.pos.y),p,14,"rise","Uncommon",1.0)
  shield_values[u.uid]=u.shield
  if u.alive and u.moving and clock>=trail_times.get(key,0):
   trail_times[key]=clock+.2
   burst(Vector3(u.pos.x,.1,u.pos.y),{"color":Color("baa990"),"highlight":Color("e3d3b3"),"motif":"spark"},2,"trail","Uncommon",.3)
 for key in trail_times.keys():
  if not live.has(key):trail_times.erase(key)

func clear() -> void:
 for batch in batches:batch.node.queue_free()
 batches.clear();trail_times.clear();shield_values.clear();support_profiles.clear();clock=0
