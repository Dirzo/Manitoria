shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform float age=0.0;
uniform float life=1.8;
uniform vec4 tint : source_color=vec4(.7,.4,1.,1.);
void fragment(){
 vec2 p=UV*2.-1.;float r=length(p);float a=atan(p.y,p.x);
 float reveal=smoothstep(0.,.22,age);float fade=1.-smoothstep(life*.65,life,age);
 float spokes=1.-smoothstep(.015,.045,abs(sin(a*8.))*r);
 float rings=1.-smoothstep(.018,.05,abs(fract(r*5.)-.5));
 float edge=1.-smoothstep(.86,1.,r);
 ALBEDO=tint.rgb;EMISSION=tint.rgb*.8;
 ALPHA=clamp((spokes+rings*.8)*edge*reveal*fade*.65,0.,.8);
}
