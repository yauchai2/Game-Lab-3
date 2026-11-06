shader_type sky;

// Original procedural interpretation of the shared cloud reference.
// Clouds are evaluated in spherical directions, with angular wrap at +/- PI.
uniform vec4 blue : source_color = vec4(0.025, 0.29, 0.72, 1.0);
uniform vec4 cloud_light : source_color = vec4(0.98, 0.99, 1.0, 1.0);
uniform vec4 cloud_shadow : source_color = vec4(0.45, 0.76, 0.96, 1.0);

float oval(vec2 p, vec2 pos, vec2 size) {
    return 1.0 - step(1.0, length((p - pos) / size));
}
float cloud(vec2 p) {
    float shape = oval(p, vec2(-0.27, -0.030), vec2(0.085, 0.050));
    shape = max(shape, oval(p, vec2(-0.19, 0.015), vec2(0.09, 0.073)));
    shape = max(shape, oval(p, vec2(-0.12, 0.070), vec2(0.10, 0.095)));
    shape = max(shape, oval(p, vec2(-0.045, 0.030), vec2(0.10, 0.115)));
    shape = max(shape, oval(p, vec2(0.035, 0.105), vec2(0.105, 0.125)));
    shape = max(shape, oval(p, vec2(0.105, 0.055), vec2(0.10, 0.11)));
    shape = max(shape, oval(p, vec2(0.19, 0.015), vec2(0.10, 0.082)));
    shape = max(shape, oval(p, vec2(0.27, -0.020), vec2(0.08, 0.05)));
    shape = max(shape, oval(p, vec2(-0.11, -0.050), vec2(0.12, 0.045)));
    shape = max(shape, oval(p, vec2(0.02, -0.055), vec2(0.12, 0.045)));
    shape = max(shape, oval(p, vec2(0.15, -0.050), vec2(0.11, 0.043)));
    return shape;
}
vec2 local_cloud(float azimuth, float altitude, float center, float height, float scale) {
    float delta = atan(sin(azimuth-center), cos(azimuth-center));
    return vec2(delta, altitude-height) / scale;
}
void sky() {
    float azimuth = atan(EYEDIR.x, -EYEDIR.z);
    float altitude = atan(EYEDIR.y, length(EYEDIR.xz));
    vec2 a = local_cloud(azimuth, altitude, 0.02, 0.36, 0.50);
    vec2 b = local_cloud(azimuth, altitude, 1.6, 0.19, 0.58);
    vec2 c = local_cloud(azimuth, altitude, -1.35, 0.26, 0.55);
    vec2 d = local_cloud(azimuth, altitude, 2.9, 0.28, 0.65);
    float silhouette = max(max(cloud(a), cloud(b)), max(cloud(c), cloud(d)));
    // A vertically offset copy yields a separate, crisp lower color layer.
    float white_part = max(max(cloud(a - vec2(0.0, 0.075)), cloud(b - vec2(0.0, 0.075))),
                           max(cloud(c - vec2(0.0, 0.075)), cloud(d - vec2(0.0, 0.075))));
    vec3 color = mix(blue.rgb, cloud_shadow.rgb, silhouette);
    color = mix(color, cloud_light.rgb, silhouette * white_part);
    COLOR = color;
}
