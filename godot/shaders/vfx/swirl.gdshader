// Tornado / vortex / water spiral surface on an open cone. Vertex twist + scrolling streak noise.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
#include "res://shaders/vfx/common.gdshaderinc"
uniform float age = 0.0;
uniform float life = 1.5;
uniform vec4 tint : source_color = vec4(0.8,0.9,1.0,1.0);
uniform vec4 tint2 : source_color = vec4(1.0,1.0,1.0,1.0);
uniform float intensity = 0.95;
uniform float spin = 6.0;
uniform float twist = 2.5;
uniform float density = 1.0;
uniform float seed = 0.0;
void vertex(){
	float h = UV.y; // 0 bottom 1 top
	float ang = twist*h + age*spin*0.35;
	float wob = sin(age*3.0 + h*4.0 + seed)*0.08*h;
	float c = cos(ang), s = sin(ang);
	VERTEX.xz = mat2(vec2(c,-s), vec2(s,c)) * VERTEX.xz;
	VERTEX.x += wob;
}
void fragment(){
	float t = clamp(age/max(life,0.001),0.0,1.0);
	vec2 uv = vec2(UV.x*3.0 - age*spin*0.18, UV.y*1.5 - age*0.6);
	float n = vfx_fbm(uv*vec2(4.0, 2.0) + seed);
	float streak = smoothstep(0.45, 0.85, vfx_fbm(vec2(UV.x*9.0 - age*spin*0.3 + UV.y*2.0, UV.y*1.2 + seed)));
	float band = smoothstep(0.0, 0.18, UV.y) * (1.0 - smoothstep(0.75, 1.0, UV.y));
	float alive = smoothstep(0.0, 0.15, t) * (1.0 - smoothstep(0.7, 1.0, t));
	float wisps = smoothstep(0.35,0.9,n);
	float a = (streak*0.75 + wisps*0.25) * band * alive * density * 0.8;
	vec3 col = mix(tint.rgb, tint2.rgb, streak);
	ALBEDO = col*intensity;
	ALPHA = clamp(a, 0.0, 1.0);
}
