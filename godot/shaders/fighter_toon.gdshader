shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform sampler2D base_texture : source_color, filter_nearest_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool use_texture = false;
uniform float flash = 0.0;
void fragment() {
    vec3 c = tint.rgb * (use_texture ? texture(base_texture, UV).rgb : vec3(1.0));
    ALBEDO = mix(c, vec3(1.0), flash);
    EMISSION = c * 0.12 + vec3(flash * 0.8);
    ROUGHNESS = 1.0;
}
void light() {
    float shade = (step(0.18, dot(NORMAL, LIGHT)) + step(0.65, dot(NORMAL, LIGHT))) * 0.5;
    DIFFUSE_LIGHT += ALBEDO * mix(vec3(0.32,0.40,0.65),vec3(1.0),shade) * LIGHT_COLOR * ATTENUATION / PI;
}
