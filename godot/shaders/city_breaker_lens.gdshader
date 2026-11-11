shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float blur = 0.0;
uniform float fisheye = 0.0;
uniform float impact = 0.0;
uniform float ring_phase = 1.0;
uniform vec2 center = vec2(0.5,0.48);
void fragment() {
    vec2 q = SCREEN_UV-vec2(.5);
    float r2=dot(q*vec2(1.777778,1.0),q*vec2(1.777778,1.0));
    vec2 uv = clamp(vec2(.5)+q*(1.0+fisheye*.72*r2)/(1.0+fisheye*.75),vec2(.002),vec2(.998));
    vec2 radial = uv-center;
    float distance_from_center = length(radial*vec2(1.0,0.5625));
    float rim = smoothstep(0.12,0.52,distance_from_center);
    float ring_radius = ring_phase*0.82;
    float shock = exp(-pow((distance_from_center-ring_radius)/0.032,2.0))*impact;
    vec2 lens_uv = clamp(uv+radial*shock*0.018,vec2(0.002),vec2(0.998));
    vec3 original = texture(screen_texture,lens_uv).rgb;
    vec3 color = original;
    // Short 7-tap radial exposure. Keep the centre sharp and the pixel palette crisp.
    for(int i=1;i<=6;i++) {
        float tap = float(i)/6.0;
        color += texture(screen_texture,clamp(lens_uv-radial*blur*rim*tap,vec2(0.002),vec2(0.998))).rgb;
    }
    color /= 7.0;
    float separation = impact*rim*0.0024;
    color.r = mix(color.r,texture(screen_texture,clamp(lens_uv+radial*separation,vec2(0.002),vec2(0.998))).r,impact*0.6);
    color.b = mix(color.b,texture(screen_texture,clamp(lens_uv-radial*separation,vec2(0.002),vec2(0.998))).b,impact*0.6);
    float luma = dot(original,vec3(.299,.587,.114));
    vec3 ink_frame = mix(vec3(.035,.02,.075),vec3(.98,.96,.78),step(.38,luma));
    color = mix(color,ink_frame,impact*.27);
    color *= 1.0-rim*(.12+blur*.8);
    color += vec3(.01,.15,.16)*shock*.2;
    COLOR=vec4(color,1.0);
}
