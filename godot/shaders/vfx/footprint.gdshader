// Ability footprint telegraph on the ground. mode 0 = circle area, 1 = line/strip, 2 = target reticle, 3 = team ring.
// progress 0..1 fills the shape as the cast charges, so you can read *where* and *when* it lands.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform int mode = 0;
uniform float progress = 0.0;
uniform vec4 edge : source_color = vec4(1.0, 0.5, 0.4, 1.0);
uniform vec4 fill : source_color = vec4(1.0, 0.6, 0.3, 1.0);
uniform float strength = 1.0;
uniform float t = 0.0;
uniform float aspect = 1.0; // length / width for lines (dash spacing)
void fragment(){
	vec2 p = UV * 2.0 - 1.0;
	float a = 0.0; vec3 col = edge.rgb;
	if (mode == 0) {
		float r = length(p);
		if (r > 1.0) discard;
		float ang = atan(p.y, p.x);
		float rim = smoothstep(0.90, 0.955, r) * (1.0 - smoothstep(0.975, 1.0, r));
		float dash = step(0.5, fract(ang * 5.0 / 3.14159 + t * 0.35));
		float inner = smoothstep(0.80, 0.86, r) * (1.0 - smoothstep(0.86, 0.885, r)) * dash;
		float filled = 1.0 - smoothstep(progress - 0.02, progress, r);
		float front = smoothstep(progress - 0.07, progress - 0.01, r) * filled;
		a = rim * 0.95 + inner * 0.5 + filled * 0.20 + front * 0.55;
		col = mix(fill.rgb, edge.rgb, clamp(rim + front * 0.5, 0.0, 1.0));
	} else if (mode == 1) {
		float x = abs(p.x); float y = UV.y;
		float side = smoothstep(0.86, 0.93, x) * (1.0 - smoothstep(0.96, 1.0, x));
		float filled = 1.0 - smoothstep(progress - 0.015, progress, y);
		float chev = step(0.72, fract(y * aspect * 0.6 - x * 0.35 - t * 1.2)) * (1.0 - smoothstep(0.55, 0.8, x));
		float cap = smoothstep(0.96, 0.985, y);
		a = side * 0.95 + filled * 0.22 + chev * 0.28 + cap * 0.8;
		col = mix(fill.rgb, edge.rgb, clamp(side + cap, 0.0, 1.0));
	} else if (mode == 2) {
		float r = length(p);
		if (r > 1.0) discard;
		float ring = smoothstep(0.78, 0.85, r) * (1.0 - smoothstep(0.93, 1.0, r));
		float ang = atan(p.y, p.x) + t * 1.4;
		float ticks = step(0.82, abs(cos(ang * 2.0))) * smoothstep(0.35, 0.45, r) * (1.0 - smoothstep(0.62, 0.7, r));
		float dot_ = 1.0 - smoothstep(0.08, 0.13, r);
		a = (ring * 0.9 + ticks * 0.9 + dot_ * 0.7) * (0.55 + 0.45 * progress);
	} else {
		float r = length(p);
		if (r > 1.0) discard;
		float ring = smoothstep(0.80, 0.88, r) * (1.0 - smoothstep(0.94, 1.0, r));
		float glow = smoothstep(0.55, 0.9, r) * (1.0 - smoothstep(0.9, 1.0, r)) * 0.25;
		a = ring * 0.8 + glow;
	}
	ALBEDO = col;
	ALPHA = clamp(a * strength * edge.a, 0.0, 1.0);
}
