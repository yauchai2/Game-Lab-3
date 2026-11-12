shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D base_texture : source_color, filter_nearest;
uniform bool cabinet_cutout=false;
varying vec3 source_position;
varying vec3 face_normal;
void vertex(){source_position=VERTEX;face_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
    if(cabinet_cutout && source_position.x>-.26 && source_position.x<.27 && source_position.y>.475 && source_position.y<.84 && source_position.z>-.18) discard;
    vec3 src=texture(base_texture,UV).rgb;
    float value=dot(src,vec3(.299,.587,.114));
    vec3 paint=mix(vec3(.04,.04,.06),vec3(.92,.92,.95),step(.31,value));
    float accent=step(src.r*1.7,src.g)*step(.48,src.g)*step(.45,src.b);
    paint=mix(paint,vec3(0,.82,.94),accent);
    ALBEDO=paint*(face_normal.y>.5?1.0:.83);
}
