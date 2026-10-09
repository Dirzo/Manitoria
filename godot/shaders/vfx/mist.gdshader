// Low, slowly drifting ground mist for dungeon chambers. Thin enough to keep fighters' feet readable.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.6, 0.7, 0.8, 1.0);
uniform float density = 0.22;
uniform float speed = 0.015;
float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p){ vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i), hash(i+vec2(1,0)), f.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), f.x), f.y); }
float fbm(vec2 p){ float v = 0.0; float a = 0.5; for (int i = 0; i < 4; i++){ v += a*noise(p); p *= 2.03; a *= 0.5; } return v; }
void fragment(){
	vec2 uv = UV * 5.0;
	float n = fbm(uv + vec2(TIME*speed*7.0, TIME*speed*3.0)) * fbm(uv*0.6 - vec2(TIME*speed*4.0, 0.0));
	// Thicker toward the cave walls, almost clear in the middle of the fight.
	float edge = smoothstep(0.18, 0.5, length(UV - vec2(0.5)));
	ALBEDO = tint.rgb;
	ALPHA = clamp(n * 1.8, 0.0, 1.0) * density * (0.25 + 0.75*edge);
}
