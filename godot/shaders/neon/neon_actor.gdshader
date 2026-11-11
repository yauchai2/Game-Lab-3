shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform sampler2D base_texture : source_color, filter_nearest_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool use_texture = false;
uniform float flash = 0.0;
uniform bool silhouette_preview = false;
uniform float neon_silhouette = 0.0;
uniform vec4 neon_accent : source_color = vec4(0.0,0.84,0.91,1.0);
void fragment() {
    vec3 c = tint.rgb * (use_texture ? texture(base_texture, UV).rgb : vec3(1.0));
    if (silhouette_preview) {
        ALBEDO = vec3(0.0);
        EMISSION = tint.rgb;
    } else {
        // Restrained tint preserves skin and the original atlas design.
        c = floor(c * 12.0 + 0.5) / 12.0;
        ALBEDO = mix(mix(c, vec3(1.0), flash), vec3(0.0), neon_silhouette);
        EMISSION = mix(c * 0.16 + vec3(flash * 0.5), neon_accent.rgb, neon_silhouette);
    }
    ROUGHNESS = 1.0;
}
void light() {
    float shade = (step(0.18, dot(NORMAL, LIGHT)) + step(0.65, dot(NORMAL, LIGHT))) * 0.5;
    DIFFUSE_LIGHT += ALBEDO * mix(vec3(0.38,0.25,0.51),vec3(1.0),shade) * LIGHT_COLOR * ATTENUATION / PI;
}
