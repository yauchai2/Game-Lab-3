shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
uniform vec4 ink : source_color = vec4(0.055, 0.10, 0.14, 1.0);
uniform float edge_threshold : hint_range(0.005, 0.5) = 0.045;
uniform float ink_strength : hint_range(0.0, 1.0) = 0.58;
void vertex() {
    // Full-screen spatial quad; reverse-Z near plane in Godot 4.3+.
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}
float view_depth(vec2 uv, mat4 inverse_projection) {
    float raw_depth = texture(depth_texture, uv).r;
    // Compatibility uses OpenGL's -1..1 clip-space depth.
    vec4 view = inverse_projection * vec4(uv * 2.0 - 1.0, raw_depth * 2.0 - 1.0, 1.0);
    return abs(view.z / max(abs(view.w), 0.00001));
}
void fragment() {
    vec2 pixel = 1.0 / VIEWPORT_SIZE;
    float center = view_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
    float left = view_depth(SCREEN_UV + vec2(-pixel.x, 0.0), INV_PROJECTION_MATRIX);
    float right = view_depth(SCREEN_UV + vec2(pixel.x, 0.0), INV_PROJECTION_MATRIX);
    float up = view_depth(SCREEN_UV + vec2(0.0, -pixel.y), INV_PROJECTION_MATRIX);
    float down = view_depth(SCREEN_UV + vec2(0.0, pixel.y), INV_PROJECTION_MATRIX);
    float difference = max(max(abs(center-left),abs(center-right)),max(abs(center-up),abs(center-down)));
    float edge = step(edge_threshold, difference / max(center,1.0));
    vec3 color = texture(screen_texture, SCREEN_UV).rgb;
    ALBEDO = mix(color, ink.rgb, edge * ink_strength);
    ALPHA = 1.0;
}
