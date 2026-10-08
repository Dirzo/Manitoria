// A soft beam of light falling from the cave ceiling: brightest at the top, fading to nothing.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 tint : source_color = vec4(1.0, 0.9, 0.7, 1.0);
uniform float strength = 0.35;
void fragment(){
	float fall = pow(1.0 - UV.y, 1.6);
	float side = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.5);
	float flicker = 0.85 + 0.15 * sin(TIME * 0.7 + UV.x * 6.0);
	ALBEDO = tint.rgb * fall * (1.0 - side) * strength * flicker;
}
