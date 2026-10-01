// Solid Meshy prop (banner, root claw): lit, grows up out of the ground, glowing rim, sinks/dissolves out.
shader_type spatial;
render_mode cull_disabled;
#include "res://shaders/vfx/common.gdshaderinc"
uniform float age = 0.0;
uniform float life = 1.6;
uniform vec4 base : source_color = vec4(0.35,0.25,0.18,1.0);
uniform vec4 tint : source_color = vec4(0.6,1.0,0.4,1.0);
uniform float rise = 0.25;   // fraction of life spent rising
uniform float height = 1.0;  // mesh height in local units
uniform float seed = 0.0;
varying vec3 lp;
void vertex(){
	lp = VERTEX;
	float t = clamp(age/max(life,0.001),0.0,1.0);
	float up = smoothstep(0.0, rise, t);
	float down = smoothstep(0.82, 1.0, t);
	VERTEX.y -= height*(1.0-up)*1.05 + height*down*0.6;
}
void fragment(){
	float t = clamp(age/max(life,0.001),0.0,1.0);
	float n = vfx_fbm(lp.xz*5.0 + lp.y*3.0 + seed);
	float burn = smoothstep(0.7, 1.0, t);
	if(n < burn) discard;
	float edge = 1.0 - smoothstep(0.0, 0.08, n - burn);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = base.rgb*(0.75 + 0.5*n);
	ROUGHNESS = 0.85;
	EMISSION = tint.rgb*(fres*0.9 + edge*3.0 + 0.08);
}
