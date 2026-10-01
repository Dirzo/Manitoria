class_name ClubBackdrop
extends Control
# Full-screen painting of the arena the club is currently competing in, with a slow
# camera drift and a weather layer that matches the region (embers, snow, dust, stars...).
var shade=0.22
var theme_name="Forest"
var picture:TextureRect
var t=0.0

const WEATHER={"Forest":0,"Volcanic":1,"Coastal":2,"Glacial":3,"Desert":4,"Astral":5}

static func theme_for(game: Node) -> String:
 var c=game.campaign
 if game.phase=="menu":
  # The title screen shows wherever your most recent club is competing.
  var latest=0;var modified=0
  for slot in range(1,4):
   if FileAccess.file_exists(Campaign.save_path(slot)) and FileAccess.get_modified_time(Campaign.save_path(slot))>modified:latest=slot;modified=FileAccess.get_modified_time(Campaign.save_path(slot))
  if latest==0:return "Forest"
  var saved=Campaign.new()
  if not saved.load_slot(latest) or not saved.state.has("tour"):return "Forest"
  c=saved
 if c==null or not c.state.has("tour") or game.exhibition:return "Forest"
 return str(WorldTour.region(c).theme)

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var path="res://assets/ui/regions/%s.jpg"%theme_name.to_lower()
 picture=TextureRect.new();picture.texture=load(path if ResourceLoader.exists(path) else "res://assets/ui/arena-valley-v1.png")
 picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(picture)
 picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);picture.pivot_offset=Vector2(800,450)
 var veil=ColorRect.new();veil.color=Color(.025,.05,.06,shade+(0.12 if theme_name in ["Glacial","Desert"] and shade>.2 else 0.0));veil.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(veil);veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var atmosphere=ColorRect.new();atmosphere.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(atmosphere);atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shader=Shader.new();shader.code="""shader_type canvas_item;
uniform int weather=0;
float h(float n){return fract(sin(n*127.1)*43758.5453);}
void fragment(){
 vec2 uv=UV;float aspect=1.7778;
 float edge=smoothstep(0.15,0.8,length((uv-vec2(.5,.48))*vec2(1.,.85)));
 vec3 c=vec3(0.);float a=0.;
 for(int i=0;i<44;i++){
  float f=float(i);float r=h(f);float r2=h(f+17.3);float r3=h(f+41.7);
  vec2 p;float sz;vec3 col;float k=1.;
  if(weather==1){ // embers rise and flicker
   p=vec2(fract(r+sin(TIME*.4+f)*.03),1.-fract(r2+TIME*(.04+.05*r3)));sz=5200.;col=vec3(1.,.48,.12);k=.6+.4*sin(TIME*6.+f*3.);
  } else if(weather==3){ // snow drifts down
   p=vec2(fract(r+TIME*.012+sin(TIME*.7+f)*.02),fract(r2+TIME*(.03+.03*r3)));sz=3800.+r3*4200.;col=vec3(.92,.96,1.);
  } else if(weather==4){ // sand blows sideways
   p=vec2(fract(r+TIME*(.05+.06*r3)),fract(r2+sin(TIME*.5+f)*.02));sz=6500.;col=vec3(1.,.82,.5);k=.7;
  } else if(weather==5){ // stars twinkle, a few motes drift
   p=vec2(r,r2*.55);sz=5500.;col=vec3(.85,.8,1.);k=pow(.5+.5*sin(TIME*(1.+r3*2.)+f*5.),4.)*1.4;
  } else if(weather==2){ // sea spray and gull-white glints
   p=vec2(fract(r-TIME*.015),.45+.5*fract(r2+TIME*.01));sz=5500.;col=vec3(.85,1.,1.);k=.4+.6*pow(.5+.5*sin(TIME*2.+f),6.);
  } else { // forest pollen and petals
   p=vec2(fract(r+TIME*.01+sin(TIME*.3+f)*.04),fract(r2+TIME*(.012+.02*r3)));sz=4800.;col=mix(vec3(1.,.9,.55),vec3(.9,.6,1.),r3);
  }
  float d=length((uv-p)*vec2(aspect,1.));
  float s=exp(-d*d*sz*sz*.0004)*k;
  c+=col*s;a+=s;
 }
 vec3 vig=vec3(.02,.03,.04);
 COLOR=vec4(mix(vig,c/max(a,.001),clamp(a,0.,1.)),clamp(edge*.55+a*.8,0.,1.));
}"""
 var mat=ShaderMaterial.new();mat.shader=shader;mat.set_shader_parameter("weather",WEATHER.get(theme_name,0));atmosphere.material=mat

func _process(delta: float) -> void:
 # Slow "establishing shot" drift so the arena feels alive behind the menus.
 t+=delta
 if picture:
  picture.scale=Vector2.ONE*(1.06+0.015*sin(t*.05))
  picture.position=Vector2(sin(t*.035)*22.0,cos(t*.027)*10.0)
