// Channelled lance / light pillar: cylinder along local Y. Soft core, scrolling energy, optional top fade.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
#include "res://shaders/vfx/common.gdshaderinc"
uniform float age = 0.0;
uniform float life = 0.8;
uniform vec4 tint : source_color = vec4(1.0,0.85,0.4,1.0);
uniform float intensity = 1.1;
uniform float seed = 0.0;
uniform float span = 1.0;
uniform float pillar = 0.0; // 1 = fade towards +Y end (healing columns)
varying float along;
void vertex(){ along = VERTEX.y/max(span,0.001) + 0.5; }
void fragment(){
	float t = clamp(age/max(life,0.001),0.0,1.0);
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float core = pow(facing, 4.0);
	float soft = pow(facing, 1.2);
	float n = vfx_fbm(vec2(UV.x*6.0, along*8.0*span*0.25 - age*9.0) + seed);
	float grow = smoothstep(along-0.08, along, t*5.0);
	float alive = smoothstep(0.0, 0.06, t) * (1.0 - smoothstep(0.6, 1.0, t));
	float top = mix(1.0, (1.0 - smoothstep(0.15, 1.0, along)) * smoothstep(0.0, 0.08, along), pillar);
	vec3 col = mix(tint.rgb, vec3(1.0), core*0.35);
	float pulse = 0.6 + 0.4*sin(along*span*3.0 - age*22.0);
	ALBEDO = col*intensity*(0.55+0.8*n)*pulse;
	ALPHA = clamp((soft*0.35 + core*0.45)*(0.55+0.6*n)*grow*alive*top, 0.0, 1.0);
}
