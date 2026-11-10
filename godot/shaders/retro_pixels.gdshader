shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec2 grid = vec2(640.0,360.0);
void fragment(){
    vec2 uv=(floor(SCREEN_UV*grid)+vec2(0.5))/grid;
    COLOR=vec4(textureLod(screen_texture,uv,0.0).rgb,1.0);
}
