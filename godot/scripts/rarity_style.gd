class_name RarityStyle
extends RefCounted

static func color(rarity: String) -> Color:
 return Color("ffd480") if rarity=="Legendary" else Color("bb9cff") if rarity=="Rare" else Color("87cbbd")

static func for_skill(hero: Dictionary, credit: String) -> String:
 var key=credit.trim_prefix("ability:")
 var saved=hero.get("skill_rarity",{}).get(key,"")
 if not saved.is_empty(): return saved
 return "Rare" if hero.get("ability_bonus_"+key,1.0)>1.0 else "Uncommon"

static func decorate(art: TextureRect, rarity: String) -> void:
 if rarity not in ["Rare","Legendary"]: return
 var shader=Shader.new()
 shader.code="""shader_type canvas_item;
uniform vec4 shine_color : source_color = vec4(1.0,0.8,0.4,1.0);
uniform float intensity = 0.3;
void fragment(){
 vec4 tex=texture(TEXTURE,UV);
 float sweep=fract(TIME*0.22)-0.25;
 float band=pow(max(0.0,1.0-abs(UV.x*0.6+UV.y*0.4-sweep*1.6)/0.085),3.0);
 float edge=pow(max(abs(UV.x-0.5),abs(UV.y-0.5))*2.0,12.0);
 COLOR=vec4(tex.rgb+shine_color.rgb*(band*intensity+edge*0.08),tex.a);
} """
 var mat=ShaderMaterial.new();mat.shader=shader;mat.set_shader_parameter("shine_color",color(rarity));mat.set_shader_parameter("intensity",0.55 if rarity=="Legendary" else 0.28);art.material=mat
