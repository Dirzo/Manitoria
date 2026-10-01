// Vines, roots and thorns: bark gradient with an emissive growth tip; grows along UV.y.
shader_type spatial;
render_mode cull_disabled;
#include "res://shaders/vfx/common.gdshaderinc"
uniform float age = 0.0;
uniform float life = 1.8;
uniform vec4 bark : source_color = vec4(0.25,0.35,0.15,1.0);
uniform vec4 glow_color : source_color = vec4(0.6,1.0,0.4,1.0);
uniform float grow_time = 0.35;
void fragment(){
	float t = clamp(age/max(life,0.001),0.0,1.0);
	float grown = smoothstep(0.0, grow_time, t);
	float wither = smoothstep(0.8, 1.0, t);
	if(UV.y > grown*(1.0 - wither)) discard;
	float n = vfx_fbm(vec2(UV.x*8.0, UV.y*20.0));
	ALBEDO = bark.rgb*(0.6+0.7*n);
	ROUGHNESS = 0.85;
	float tip = 1.0 - smoothstep(0.0, 0.15, grown - UV.y);
	EMISSION = glow_color.rgb*(tip*1.8 + 0.15*n);
}
