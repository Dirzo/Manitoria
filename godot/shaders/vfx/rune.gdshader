// Ground rune circle / shockwave / crack decal on a horizontal quad. mode selects the pattern.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
#include "res://shaders/vfx/common.gdshaderinc"
uniform float age = 0.0;
uniform float life = 1.2;
uniform vec4 tint : source_color = vec4(1.0,0.8,0.4,1.0);
uniform float intensity = 1.8;
uniform int mode = 0; // 0 rune circle, 1 shockwave ring, 2 ground cracks, 3 soft pool, 4 scorch
uniform float seed = 0.0;
void fragment(){
	float t = clamp(age/max(life,0.001),0.0,1.0);
	vec2 p = UV*2.0-1.0; float r = length(p); float ang = atan(p.y, p.x);
	float a = 0.0;
	if(mode==0){
		float spinv = age*0.6;
		float ring1 = 1.0 - smoothstep(0.0, 0.025, abs(r-0.92));
		float ring2 = 1.0 - smoothstep(0.0, 0.018, abs(r-0.74));
		float ring3 = 1.0 - smoothstep(0.0, 0.012, abs(r-0.40));
		float ticks = (1.0 - smoothstep(0.0, 0.18, abs(fract((ang+spinv)*72.0/6.2831)-0.5)*2.0 - 0.0)) * step(0.80,r)*step(r,0.88);
		float glyph = step(0.62, vfx_noise(vec2(floor((ang-spinv)*18.0/6.2831)*3.1, floor(r*14.0)+seed)))*step(0.44,r)*step(r,0.72);
		float star = 1.0 - smoothstep(0.0, 0.02, abs(sin(3.0*(ang+spinv*-1.5))*r*0.9 - p.y*0.0 - r*0.0 + (r-0.66)));
		float draw = smoothstep(0.0, 0.3, t);
		a = (ring1 + ring2*0.75 + ring3*0.5 + ticks*0.45 + glyph*0.3) * draw * 0.75;
		a *= step(ang/6.2831+0.5, draw*1.2);
		a *= 1.0 - smoothstep(0.7, 1.0, t);
		a += (1.0 - smoothstep(0.0,1.0,r))*0.18*(1.0-t);
	} else if(mode==1){
		float front = t*1.0;
		float w = 0.06 + 0.1*t;
		a = (1.0 - smoothstep(0.0, w, abs(r - front))) * (1.0 - t);
		a += (1.0 - smoothstep(0.0, front, r))*0.25*(1.0-t)*step(r,front);
	} else if(mode==2){
		vec2 v = vfx_voronoi(p*4.0 + seed*3.0);
		float crack = 1.0 - smoothstep(0.0, 0.07, v.y - v.x);
		float reach = 1.0 - smoothstep(t*1.6, t*1.6+0.15, r);
		a = crack * reach * (1.0 - smoothstep(0.55, 1.0, t)) * (1.0 - smoothstep(0.7, 1.0, r));
		a += (1.0 - smoothstep(0.0, 0.5, r))*0.3*(1.0-t);
	} else if(mode==3){
		float n = vfx_fbm(p*3.0 + vec2(age*0.3, -age*0.2) + seed);
		a = (1.0 - smoothstep(0.55, 1.0, r + (n-0.5)*0.4)) * (0.45 + 0.55*n);
		a *= smoothstep(0.0, 0.15, t) * (1.0 - smoothstep(0.75, 1.0, t));
	} else {
		float n = vfx_fbm(p*4.0 + seed);
		a = (1.0 - smoothstep(0.3, 1.0, r + (n-0.5)*0.5)) * (1.0 - t) * 0.8;
	}
	ALBEDO = tint.rgb*min(intensity, 1.25);
	if(intensity > 1.25) a *= min(intensity/1.25, 1.3);
	ALPHA = clamp(a*tint.a, 0.0, 1.0);
}
