// Billboard flame tongue: scrolling fbm shaped into a teardrop, hot core to tinted rim.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
#include "res://shaders/vfx/common.gdshaderinc"
uniform float age = 0.0;
uniform float life = 1.0;
uniform float seed = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform vec4 core : source_color = vec4(1.0, 0.95, 0.7, 1.0);
uniform float intensity = 1.05;
uniform float fade_in = 0.12;
void vertex(){
	// Camera-facing around the Y axis so tongues stay upright.
	vec3 world_pos = MODEL_MATRIX[3].xyz;
	vec3 to_cam = normalize(CAMERA_POSITION_WORLD - world_pos);
	vec3 right = normalize(cross(vec3(0,1,0), to_cam));
	float sx = length(MODEL_MATRIX[0].xyz); float sy = length(MODEL_MATRIX[1].xyz);
	vec3 p = world_pos + right*VERTEX.x*sx + vec3(0,1,0)*VERTEX.y*sy;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(p, 1.0);
}
void fragment(){
	float t = clamp(age/max(life,0.001), 0.0, 1.0);
	vec2 uv = UV; uv.y = 1.0 - uv.y;        // 0 bottom, 1 top
	float time = age*1.7 + seed*13.0;
	float n = vfx_fbm(vec2(uv.x*3.0 + seed*7.0, uv.y*2.2 - time*2.6));
	float n2 = vfx_fbm(vec2(uv.x*6.0 - seed*3.0, uv.y*4.0 - time*4.1));
	float x = (uv.x - 0.5) * 2.0;
	float width = mix(0.95, 0.12, pow(uv.y, 0.8));
	float body = 1.0 - smoothstep(width*0.55, width, abs(x + (n-0.5)*0.55*uv.y));
	float h = uv.y + (n2 - 0.5)*0.35;
	float shape = body * (1.0 - smoothstep(0.55, 1.0, h)) * smoothstep(0.0, 0.12, uv.y);
	float heat = shape * (0.3 + 0.8*n) * (1.0 - 0.35*uv.y);
	float alive = smoothstep(0.0, fade_in, t) * (1.0 - smoothstep(0.55, 1.0, t));
	vec3 deep = tint.rgb*vec3(0.9,0.35,0.25);
	vec3 col = mix(deep, tint.rgb, smoothstep(0.1, 0.45, heat));
	col = mix(col, core.rgb, smoothstep(0.62, 0.95, heat)*smoothstep(0.55,0.2,uv.y));
	ALBEDO = col * intensity;
	ALPHA = clamp(smoothstep(0.08,0.5,heat) * alive, 0.0, 1.0);
}
