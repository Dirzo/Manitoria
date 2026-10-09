// Dungeon monster skin: recolours the creature towards its tint and adds a soft rim glow.
// Drawn as a pass after the creature's own material, so its textures and animation stay intact.
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, cull_back;
uniform vec4 tint : source_color = vec4(1.0);
uniform float strength = 0.5;
uniform vec4 rim : source_color = vec4(1.0);
uniform float rim_amount = 0.3;
void fragment(){
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	// Multiply by a colour above 1 at the rim so the edge brightens towards the glow colour.
	vec3 body = mix(vec3(1.0), tint.rgb * 1.35, strength);
	ALBEDO = body + rim.rgb * edge * rim_amount;
}
