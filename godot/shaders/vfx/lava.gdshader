shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
#include "res://shaders/vfx/common.gdshaderinc"
uniform float age=0.0;
uniform float life=4.0;
uniform vec4 tint : source_color=vec4(1.,.3,.05,1.);
void fragment(){
 vec2 p=UV*2.-1.;float r=length(p);vec2 cells=vfx_voronoi(p*4.+vec2(age*.12,-age*.08));
 float cracks=1.-smoothstep(.02,.1,cells.y-cells.x);
 float heat=.7+.3*sin(age*5.+r*9.);
 vec3 molten=mix(tint.rgb,vec3(1.,.75,.15),cracks);
 ALBEDO=mix(vec3(.06,.025,.015),molten,cracks*.9);
 EMISSION=molten*cracks*heat*1.5;
 ALPHA=(1.-smoothstep(.82,1.,r))*smoothstep(0.,.16,age)*(1.-smoothstep(life-.6,life,age));
}
