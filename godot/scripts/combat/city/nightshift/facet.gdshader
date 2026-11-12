shader_type spatial;
render_mode unshaded;
uniform vec4 base_color : source_color = vec4(1.0);
varying vec3 face_normal;
void vertex() { face_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL); }
void fragment() {
    float band = face_normal.y > 0.5 ? 1.0 : (face_normal.x > 0.5 ? 0.62 : 0.83);
    ALBEDO = base_color.rgb * band;
}
