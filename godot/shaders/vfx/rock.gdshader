// Stone chunk with procedural strata, optional molten glow in cracks (meteors, lava, magma).
shader_type spatial;
render_mode cull_back;
#include "res://shaders/vfx/common.gdshaderinc"
uniform vec4 stone : source_color = vec4(0.42,0.38,0.34,1.0);
uniform vec4 glow_color : source_color = vec4(1.0,0.45,0.1,1.0);
uniform float molten = 0.0;
uniform float seed = 0.0;
varying vec3 lp;
void vertex(){ lp = VERTEX; }
void fragment(){
	float n = vfx_fbm(lp.xz*3.0 + lp.y*2.0 + seed);
	float strata = vfx_noise(vec2(lp.y*9.0 + n*2.0, seed));
	vec2 v = vfx_voronoi(lp.xy*3.5 + lp.z*2.0 + seed);
	float crack = 1.0 - smoothstep(0.0, 0.06, v.y - v.x);
	ALBEDO = stone.rgb*(0.65 + 0.5*n)*(0.85+0.3*strata)*(1.0 - crack*0.5*(1.0-molten));
	ROUGHNESS = 0.9;
	EMISSION = glow_color.rgb*crack*molten*3.0;
}
