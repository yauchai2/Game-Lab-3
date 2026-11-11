shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D base_texture : source_color, filter_nearest_mipmap;
// World-projected environment tiles use crisp pixel sampling, while imported
// character and prop textures retain their existing filtering.
uniform sampler2D world_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform bool use_texture = false;
uniform bool use_instance_color = false;
uniform bool use_world_uv = false;
uniform vec3 texture_scale = vec3(1.0);
uniform vec3 texture_offset = vec3(0.0);
varying vec3 world_position;
void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
uniform int bands : hint_range(2, 3) = 2;
uniform vec3 shadow_tint : source_color = vec3(0.50, 0.65, 0.78);
uniform float palette_strength = 1.0;
uniform vec3 accent : source_color = vec3(0.0, 0.84, 0.91);
uniform bool landmark = false;
uniform int value_role = 0;
void fragment() {
    vec2 tex_uv = UV * texture_scale.xy + texture_offset.xy;
    if (use_world_uv) {
        vec3 world_normal = abs(normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz));
        vec3 point = world_position * texture_scale + texture_offset;
        tex_uv = world_normal.y > max(world_normal.x, world_normal.z) ? point.xz :
                 (world_normal.x > world_normal.z ? point.zy : point.xy);
    }
    vec3 tex_color = vec3(1.0);
    if (use_texture) {
        tex_color = use_world_uv ? texture(world_texture, tex_uv).rgb : texture(base_texture, tex_uv).rgb;
    }
    ALBEDO = base_color.rgb * tex_color * (use_instance_color ? COLOR.rgb : vec3(1.0));
    float value = dot(ALBEDO, vec3(0.299, 0.587, 0.114));
    // Value-role palette, with original texture contrast retained in each band.
    vec3 neutral = mix(vec3(0.045,0.052,0.075), vec3(0.85,0.87,0.90), value);
    if (landmark) neutral = mix(neutral, accent * (0.28 + value * 0.72), 0.16);
    if (value_role == 1) neutral = vec3(0.065,0.070,0.095) * (0.8 + value * 0.5);
    if (value_role == 2) neutral = vec3(0.035,0.045,0.065) * (0.8 + value * 0.6);
    ALBEDO = mix(ALBEDO, neutral, palette_strength);
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
