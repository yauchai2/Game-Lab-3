shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 tint : source_color = vec4(.48,.39,.55,1.0);
uniform float opacity = .3;
uniform float age = 0.0;
uniform float seed = 0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7))+seed*17.0)*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){
    mat4 facing=mat4(vec4(INV_VIEW_MATRIX[0].xyz*length(MODEL_MATRIX[0].xyz),0.0),vec4(INV_VIEW_MATRIX[1].xyz*length(MODEL_MATRIX[1].xyz),0.0),vec4(INV_VIEW_MATRIX[2].xyz*length(MODEL_MATRIX[2].xyz),0.0),MODEL_MATRIX[3]);
    MODELVIEW_MATRIX=VIEW_MATRIX*facing;
}
void fragment(){
    vec2 uv=floor(UV*96.0)/96.0;
    vec2 p=(uv-.5)*2.0;
    float n=noise(uv*5.0+vec2(age*.055,-age*.09));
    float small=noise(uv*12.0-vec2(age*.07,age*.04));
    float edge=length(p)+n*.30+small*.08;
    float density=1.0-smoothstep(.36,1.08,edge);
    density=floor(density*5.0)/5.0;
    ALBEDO=tint.rgb*(.76+.24*n);
    ALPHA=density*opacity;
}
