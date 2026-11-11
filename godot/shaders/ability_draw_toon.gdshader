shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform vec4 base_color : source_color = vec4(1.0);
void fragment(){ ALBEDO=base_color.rgb; ROUGHNESS=1.0; SPECULAR=0.0; }
void light(){
    float band=step(0.32,dot(NORMAL,LIGHT));
    DIFFUSE_LIGHT+=ALBEDO*mix(vec3(.47,.35,.68),vec3(1.0),band)*LIGHT_COLOR*ATTENUATION/PI;
}
