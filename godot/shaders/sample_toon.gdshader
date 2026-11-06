shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D base_texture : source_color, filter_linear_mipmap;
uniform bool use_texture = false;
uniform int bands : hint_range(2, 3) = 2;
uniform vec3 shadow_tint : source_color = vec3(0.50, 0.65, 0.78);
void fragment() {
    ALBEDO = base_color.rgb * (use_texture ? texture(base_texture, UV).rgb : vec3(1.0));
    ROUGHNESS = 1.0;
    SPECULAR = 0.0;
}
void light() {
    float n_dot_l = max(dot(NORMAL, LIGHT), 0.0);
    float tone = bands == 2 ? step(0.38, n_dot_l) : (step(0.22, n_dot_l) + step(0.66, n_dot_l)) * 0.5;
    vec3 ramp = mix(shadow_tint, vec3(1.0), tone);
    // Preserve cast-shadow attenuation from the engine separately from the normal ramp.
    DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ramp * ATTENUATION / PI;
}
