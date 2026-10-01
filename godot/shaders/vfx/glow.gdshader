// Soft additive glow sprite (flashes, motes, orbs). Always faces the camera.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform float age = 0.0;
uniform float life = 1.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float intensity = 2.0;
uniform float hardness = 2.0;
uniform int mode = 0; // 0 flash (swell+fade), 1 steady, 2 star
void vertex(){
	vec3 c = MODEL_MATRIX[3].xyz; float s = length(MODEL_MATRIX[0].xyz);
	vec3 p = c + (INV_VIEW_MATRIX[0].xyz*VERTEX.x + INV_VIEW_MATRIX[1].xyz*VERTEX.y)*s;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(p,1.0);
}
void fragment(){
	float t = clamp(age/max(life,0.001),0.0,1.0);
	vec2 p = UV*2.0-1.0; float d = length(p);
	float g = pow(max(0.0, 1.0-d), hardness);
	if(mode==2){ g += 0.8*pow(max(0.0,1.0-abs(p.x)*10.0),2.0)*(1.0-abs(p.y)) + 0.8*pow(max(0.0,1.0-abs(p.y)*10.0),2.0)*(1.0-abs(p.x)); }
	float a = (mode==1) ? 1.0 : (1.0 - t)*(1.0 - t);
	if(mode==0) a *= smoothstep(0.0, 0.08, t);
	ALBEDO = tint.rgb*intensity;
	ALPHA = clamp(g*a*tint.a, 0.0, 1.0);
}
