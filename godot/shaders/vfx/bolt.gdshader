// Lightning ribbon: bright white core, tinted halo, flicker. UV.x across, UV.y along.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
#include "res://shaders/vfx/common.gdshaderinc"
uniform float age = 0.0;
uniform float life = 0.4;
uniform vec4 tint : source_color = vec4(0.5,0.75,1.0,1.0);
uniform float intensity = 3.0;
uniform float seed = 0.0;
void fragment(){
	float t = clamp(age/max(life,0.001),0.0,1.0);
	float x = abs(UV.x*2.0-1.0);
	float core = 1.0 - smoothstep(0.05, 0.22, x);
	float halo = pow(1.0 - x, 2.5);
	float flick = step(0.35, vfx_hash(vec2(floor(age*38.0), seed)));
	flick = mix(1.0, 0.35 + 0.65*flick, step(0.12, t));
	float reveal = smoothstep(UV.y - 0.05, UV.y, t*6.0);   // strike travels down fast
	float fade = 1.0 - smoothstep(0.45, 1.0, t);
	vec3 col = mix(tint.rgb, vec3(1.0), core);
	ALBEDO = col*intensity;
	ALPHA = clamp((core + halo*0.7) * flick * fade * reveal, 0.0, 1.0);
}
