shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float strength : hint_range(0.0,1.0) = 0.0;
uniform vec4 accent : source_color = vec4(.4,.9,.8,1.0);
void fragment() {
    vec3 source = textureLod(screen_texture,SCREEN_UV,0.0).rgb;
    float luma = dot(source,vec3(.2126,.7152,.0722));
    vec3 paper = vec3(1.0,.96,.83);
    vec3 ink = vec3(.045,.065,.14);
    vec3 band = mix(ink,accent.rgb*.78,step(.28,luma));
    band = mix(band,paper,step(.69,luma));
    float border = smoothstep(.12,.65,length((SCREEN_UV-vec2(.5,.52))*vec2(1.0,.8)));
    COLOR = vec4(mix(source,band,strength*(.50+.50*border)),1.0);
}
