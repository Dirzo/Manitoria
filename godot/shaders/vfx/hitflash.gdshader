// Overlay pass on every fighter mesh: a bright rim-weighted flash when struck or casting.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform vec4 tint : source_color = vec4(1.0);
uniform float flash = 0.0;
void fragment(){
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = tint.rgb * flash * (0.45 + 1.6 * rim);
}
