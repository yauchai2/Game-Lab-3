shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D plate : source_color, filter_linear;
uniform vec3 ref_right;
uniform vec3 ref_up;
uniform vec3 ref_center;
uniform vec2 ref_span;
uniform float night=0.0;
uniform float clock=0.0;
uniform float gate_open=0.0;
varying vec2 paint_uv;
float cross2(vec2 a, vec2 b){return a.x*b.y-a.y*b.x;}
float quad(vec2 p,vec2 a,vec2 b,vec2 c,vec2 d){return step(0.0,cross2(b-a,p-a))*step(0.0,cross2(c-b,p-b))*step(0.0,cross2(d-c,p-c))*step(0.0,cross2(a-d,p-d));}
void vertex(){
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz-ref_center;
 paint_uv=vec2(dot(world,ref_right)/ref_span.x+.5,.5-dot(world,ref_up)/ref_span.y);
}
void fragment(){
 vec2 uv=paint_uv;vec3 original=texture(plate,uv).rgb;
 vec3 c=original*mix(1.0,.37,night);
 float pink=step(.65,original.r)*step(original.g,.23)*step(.20,original.b);
 float indoor=quad(uv,vec2(.49,.05),vec2(.71,.05),vec2(.71,.25),vec2(.49,.25));
 indoor+=quad(uv,vec2(.78,.28),vec2(.96,.28),vec2(.96,.88),vec2(.73,.88));
 indoor+=quad(uv,vec2(.09,.20),vec2(.35,.20),vec2(.35,.65),vec2(.09,.65));
 indoor+=quad(uv,vec2(.24,.78),vec2(.33,.78),vec2(.33,.95),vec2(.24,.95));
 float outside=1.0-clamp(indoor,0.0,1.0);
 c=mix(c,mix(original,vec3(.015,.035,.09),night),clamp(outside,0.0,1.0)*pink);
 // Small panes swap pink/cyan exactly where the reference has windows.
 float panes=quad(uv,vec2(.49,.105),vec2(.64,.075),vec2(.702,.13),vec2(.702,.22));
 c=mix(c,vec3(.02,.72,.94)*(.75+.25*sin(clock*.8)),panes*pink*night);
 float neon=step(.65,original.g)*step(.45,original.b)*step(original.r,.4);
 c=mix(c,original,neon*.85*night);
 float gate=quad(uv,vec2(.800,.307),vec2(.939,.355),vec2(.939,.528),vec2(.798,.477));
 c=mix(c,vec3(.96,.0,.43),gate*gate_open);
 ALBEDO=c;
}
