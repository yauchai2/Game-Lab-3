shader_type spatial;
render_mode unshaded, cull_front;
uniform bool silhouette_preview = false;
uniform bool repaired_suit_neck = false;
void vertex() {
    // A thick inverted hull folds across the suit's concave jaw/collar junction.
    float width = (repaired_suit_neck && VERTEX.y > 0.80 && VERTEX.y < 0.915) ? 0.0008 : 0.012;
    VERTEX += NORMAL * width;
}
void fragment() {
    if (silhouette_preview) discard;
    ALBEDO = vec3(0.025, 0.025, 0.07);
}
