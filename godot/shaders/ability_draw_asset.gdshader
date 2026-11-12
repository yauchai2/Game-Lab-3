shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;
uniform sampler2D base_texture : source_color, filter_nearest;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool cabinet_cutout=false;
varying vec3 source_position;
void fragment(){
    if(cabinet_cutout && source_position.x>-.26 && source_position.x<.27 && source_position.y>.475 && source_position.y<.84 && source_position.z>-.18) discard;
    vec3 paint=texture(base_texture,UV).rgb*tint.rgb;
    ALBEDO=paint;ROUGHNESS=1.0;SPECULAR=0.0;
    float cyan=step(paint.r*1.7,paint.g)*step(.48,paint.g)*step(.45,paint.b);
    EMISSION=paint*cyan*.16;
}
void vertex(){source_position=VERTEX;}
void light(){
    float band=step(.32,dot(NORMAL,LIGHT));
    DIFFUSE_LIGHT+=ALBEDO*mix(vec3(.47,.35,.68),vec3(1.0),band)*LIGHT_COLOR*ATTENUATION/PI;
}
