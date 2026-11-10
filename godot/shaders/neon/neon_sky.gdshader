shader_type sky;
uniform vec4 top_color : source_color = vec4(0.43,0.07,0.36,1.0);
uniform vec4 horizon_color : source_color = vec4(1.0,0.08,0.52,1.0);
void sky() {
    float band = floor(clamp(EYEDIR.y, 0.0, 1.0) * 5.0) / 5.0;
    COLOR = mix(horizon_color.rgb, top_color.rgb, band);
}
