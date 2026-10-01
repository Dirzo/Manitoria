// Protective bubble: fresnel rim, hex lattice, impact ripple sweep.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
#include "res://shaders/vfx/common.gdshaderinc"
uniform float age = 0.0;
uniform float life = 1.2;
uniform vec4 tint : source_color = vec4(0.5,0.95,0.9,1.0);
uniform float intensity = 1.6;
uniform float hold = 0.0; // 1 keeps it visible (persistent shields)
float hexgrid(vec2 p){
	p.x *= 1.1547; p.y += mod(floor(p.x),2.0)*0.5;
	vec2 f = abs(fract(p)-0.5);
	return abs(max(f.x*1.5+f.y, f.y*2.0)-1.0);
}
void fragment(){
	float t = clamp(age/max(life,0.001),0.0,1.0);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW),0.0,1.0), 2.2);
	float hex = 1.0 - smoothstep(0.0, 0.08, hexgrid(UV*vec2(18.0, 9.0)));
	float sweep = 1.0 - smoothstep(0.0, 0.12, abs(UV.y - fract(age*0.8)));
	float appear = smoothstep(0.0, 0.25, t);
	float fade = mix(1.0 - smoothstep(0.6,1.0,t), 1.0, hold);
	float a = (fres*0.9 + hex*0.35*(0.4+fres) + sweep*0.25) * appear * fade;
	ALBEDO = mix(tint.rgb, vec3(1.0), fres*0.5)*intensity;
	ALPHA = clamp(a, 0.0, 1.0);
}
