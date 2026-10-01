// Ice / arcane crystal: glossy tinted body with strong fresnel and an inner sparkle. Grows from the ground.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;
#include "res://shaders/vfx/common.gdshaderinc"
uniform float age = 0.0;
uniform float life = 1.6;
uniform vec4 tint : source_color = vec4(0.6,0.85,1.0,1.0);
uniform float grow_time = 0.18;
void vertex(){
	float t = clamp(age/max(life,0.001),0.0,1.0);
	float g = smoothstep(0.0, grow_time, t) * (1.0 - smoothstep(0.82, 1.0, t)*0.9);
	VERTEX *= vec3(mix(0.4,1.0,g), g, mix(0.4,1.0,g));
}
void fragment(){
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW),0.0,1.0), 3.0);
	float spark = step(0.97, vfx_noise(UV*60.0 + age*2.0));
	ALBEDO = tint.rgb*0.55;
	ROUGHNESS = 0.08; METALLIC = 0.1; SPECULAR = 0.9;
	EMISSION = tint.rgb*(0.25 + fres*1.6) + vec3(spark*2.0);
	ALPHA = 0.82 + fres*0.18;
}
