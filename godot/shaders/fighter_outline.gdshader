shader_type spatial;
render_mode unshaded, cull_front;
uniform bool silhouette_preview = false;
void vertex() { VERTEX += NORMAL * 0.012; }
void fragment() {
    if (silhouette_preview) discard;
    ALBEDO = vec3(0.025, 0.025, 0.07);
}
