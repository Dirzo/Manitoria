// Soft billowing puff (alpha blended). Used for dust, poison clouds, shadow smoke, steam, frost mist.
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled;
#include "res://shaders/vfx/common.gdshaderinc"
uniform float age = 0.0;
uniform float life = 1.5;
uniform vec4 tint : source_color = vec4(0.6,0.55,0.5,0.6);
uniform float seed = 0.0;
uniform float glow = 0.0;
void vertex(){
	vec3 c = MODEL_MATRIX[3].xyz; float s = length(MODEL_MATRIX[0].xyz);
	float t = clamp(age/max(life,0.001),0.0,1.0);
	s *= 0.6 + 0.8*sqrt(t);
	float rot = seed*6.28 + age*0.4;
	vec2 v = mat2(vec2(cos(rot),-sin(rot)), vec2(sin(rot),cos(rot))) * VERTEX.xy;
	vec3 p = c + (INV_VIEW_MATRIX[0].xyz*v.x + INV_VIEW_MATRIX[1].xyz*v.y)*s;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(p,1.0);
}
void fragment(){
	float t = clamp(age/max(life,0.001),0.0,1.0);
	vec2 p = UV*2.0-1.0;
	float n = vfx_fbm(p*1.8 + vec2(seed*5.0, age*0.35));
	float d = length(p) + (n-0.5)*0.7;
	float puff = 1.0 - smoothstep(0.35, 0.95, d);
	float alive = smoothstep(0.0, 0.18, t) * (1.0 - smoothstep(0.35, 1.0, t));
	vec3 col = tint.rgb*(0.75 + 0.5*n);
	ALBEDO = col; EMISSION = col*glow;
	ALPHA = clamp(puff*alive*tint.a*(0.6+0.6*n), 0.0, 1.0);
}
