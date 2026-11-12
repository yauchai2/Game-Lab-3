shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
uniform vec4 color : source_color=vec4(1.0);
uniform bool spot=false;
void fragment(){
 float falloff=spot?pow(max(0.0,1.0-length(UV*2.0-1.0)),1.6):pow(max(0.0,1.0-UV.y),.6);
 ALBEDO=color.rgb;ALPHA=color.a*falloff;
}
