// Ghostly Meshy prop: additive fresnel shell with flowing inner energy; fades and dissolves by age.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
#include "res://shaders/vfx/common.gdshaderinc"
uniform float age = 0.0;
uniform float life = 1.4;
uniform vec4 tint : source_color = vec4(0.6,0.4,1.0,1.0);
uniform vec4 hot : source_color = vec4(1.0,0.9,1.0,1.0);
uniform float intensity = 1.3;
uniform float seed = 0.0;
varying vec3 lp;
void vertex(){ lp = VERTEX; }
void fragment(){
	float t = clamp(age/max(life,0.001),0.0,1.0);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	float n = vfx_fbm(lp.xy*6.0 + vec2(0.0, -age*1.8) + seed);
	float appear = smoothstep(0.0, 0.18, t);
	float dissolve = smoothstep(n - 0.1, n + 0.1, 1.0 - smoothstep(0.55, 1.0, t)*1.2);
	vec3 col = mix(tint.rgb, hot.rgb, fres*0.6);
	ALBEDO = col*intensity;
	ALPHA = clamp((fres*0.85 + 0.18 + n*0.25)*appear*dissolve*tint.a, 0.0, 1.0);
}
