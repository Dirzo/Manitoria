// Shared noise helpers for Manitoria VFX.
float vfx_hash(vec2 p){ p = fract(p*vec2(123.34, 456.21)); p += dot(p, p+45.32); return fract(p.x*p.y); }
float vfx_noise(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p);
	float a = vfx_hash(i), b = vfx_hash(i+vec2(1,0)), c = vfx_hash(i+vec2(0,1)), d = vfx_hash(i+vec2(1,1));
	vec2 u = f*f*(3.0-2.0*f);
	return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}
float vfx_fbm(vec2 p){
	float v = 0.0; float a = 0.5;
	for(int i=0;i<5;i++){ v += a*vfx_noise(p); p = p*2.03 + vec2(1.7, 9.2); a *= 0.5; }
	return v;
}
vec2 vfx_voronoi(vec2 p){
	vec2 n = floor(p); vec2 f = fract(p); float d1 = 8.0; float d2 = 8.0;
	for(int j=-1;j<=1;j++) for(int i=-1;i<=1;i++){
		vec2 g = vec2(float(i),float(j));
		vec2 o = vec2(vfx_hash(n+g), vfx_hash(n+g+19.19));
		float d = length(g+o-f);
		if(d<d1){ d2=d1; d1=d; } else if(d<d2){ d2=d; }
	}
	return vec2(d1, d2);
}
