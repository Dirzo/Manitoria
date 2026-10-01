// Instanced particle spray (MultiMesh). INSTANCE_CUSTOM = (velocity.xyz, lifetime). COLOR per instance.
// Motion is analytic in age, so pausing/slow-motion only need the age uniform.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
#include "res://shaders/vfx/common.gdshaderinc"
uniform float age = 0.0;
uniform float gravity = 0.0;
uniform float drag = 0.8;
uniform float size_curve = 0.0; // 0 shrink, 1 grow-then-shrink, 2 constant
uniform int motif = 0; // 0 glow dot, 1 ember/streak, 2 feather, 3 leaf, 4 snow, 5 droplet, 6 shard, 7 star, 8 petal
uniform float stretch = 0.0;
uniform float intensity = 2.0;
uniform float spin = 3.0;
varying float v_t;
varying float v_seed;
void vertex(){
	vec3 vel = INSTANCE_CUSTOM.xyz; float lifetime = max(INSTANCE_CUSTOM.w, 0.01);
	float a = min(age, lifetime*1.5);
	v_t = clamp(age/lifetime, 0.0, 1.0);
	v_seed = fract(dot(vel, vec3(12.9898,78.233,45.164)));
	float k = drag;
	float travel = (k > 0.001) ? (1.0 - exp(-k*a))/k : a;
	vec3 anchor = MODEL_MATRIX[3].xyz + vel*travel + vec3(0.0, -0.5*gravity*a*a, 0.0);
	if(motif==2||motif==3||motif==8){ anchor.x += sin(a*3.0 + v_seed*20.0)*0.25*a; anchor.z += cos(a*2.3 + v_seed*13.0)*0.25*a; }
	float s = length(MODEL_MATRIX[0].xyz);
	if(size_curve < 0.5) s *= 1.0 - v_t*0.85;
	else if(size_curve < 1.5) s *= sin(min(v_t,1.0)*3.14159)*1.2 + 0.05;
	vec3 right = INV_VIEW_MATRIX[0].xyz; vec3 up = INV_VIEW_MATRIX[1].xyz;
	vec2 v = VERTEX.xy;
	if(stretch > 0.0){
		vec3 cur_vel = vel*exp(-k*a) + vec3(0.0,-gravity*a,0.0);
		vec3 dirv = normalize(cur_vel + vec3(0.0001));
		vec3 cam_dir = normalize(anchor - CAMERA_POSITION_WORLD);
		vec3 side = normalize(cross(dirv, cam_dir));
		right = side; up = dirv; v.y *= 1.0 + stretch*length(cur_vel);
	} else {
		float r = v_seed*6.28 + a*spin*(v_seed-0.5);
		v = mat2(vec2(cos(r),-sin(r)), vec2(sin(r),cos(r))) * v;
	}
	vec3 p = anchor + (right*v.x + up*v.y)*s;
	if(age > lifetime) p = vec3(0.0, -1000.0, 0.0);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(p, 1.0);
}
void fragment(){
	vec2 p = UV*2.0-1.0; float d = length(p); float shape;
	if(motif==1){ shape = pow(max(0.0,1.0-length(vec2(p.x*2.2, p.y))),1.6); }
	else if(motif==2){ float spine = 1.0-smoothstep(0.0,0.08,abs(p.x)); float vane = 1.0-smoothstep(0.35,0.95,length(vec2(p.x*1.9,p.y))); shape = max(vane*(0.55+0.45*sin(p.y*30.0+abs(p.x)*18.0)), spine*step(abs(p.y),0.95)); }
	else if(motif==3){ shape = (1.0-smoothstep(0.6,1.0,length(vec2(p.x*1.9,p.y*0.95))))*(0.7+0.3*cos(abs(p.x)*18.0-p.y*6.0)); }
	else if(motif==4){ float a6 = abs(cos(atan(p.y,p.x)*3.0)); shape = (1.0-smoothstep(0.0,0.12,abs(d*(0.6+0.4*a6)-0.0) - 0.0))*0.0 + pow(max(0.0,1.0-d),2.0) + 0.7*(1.0-smoothstep(0.03,0.09,abs(sin(atan(p.y,p.x)*3.0))*d))*(1.0-smoothstep(0.7,1.0,d)); }
	else if(motif==5){ shape = 1.0-smoothstep(0.5,0.95,length(vec2(p.x*1.5,(p.y+0.2)*(p.y>0.0?0.7:1.2)))); }
	else if(motif==6){ shape = 1.0-smoothstep(0.55,0.75,abs(p.x)*1.4+abs(p.y)*0.8+0.25*abs(p.x+p.y)); }
	else if(motif==7){ shape = pow(max(0.0,1.0-d),3.0) + 0.9*pow(max(0.0,1.0-abs(p.x)*9.0),2.0)*(1.0-abs(p.y)) + 0.9*pow(max(0.0,1.0-abs(p.y)*9.0),2.0)*(1.0-abs(p.x)); }
	else if(motif==8){ shape = 1.0-smoothstep(0.5,1.0,length(vec2(p.x*1.4,p.y*1.0 - 0.3*p.x*p.x))); }
	else { shape = pow(max(0.0,1.0-d),2.2); }
	float fade = 1.0 - smoothstep(0.6, 1.0, v_t);
	ALBEDO = COLOR.rgb*intensity;
	ALPHA = clamp(shape*fade*COLOR.a, 0.0, 1.0);
}
