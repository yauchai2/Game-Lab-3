shader_type spatial;
render_mode unshaded, cull_front;
uniform bool cabinet_cutout=false;
varying vec3 source_position;
void vertex(){source_position=VERTEX;VERTEX+=NORMAL*.0035;}
void fragment(){
    if(cabinet_cutout && source_position.x>-.26 && source_position.x<.27 && source_position.y>.475 && source_position.y<.84 && source_position.z>-.18) discard;
    ALBEDO=vec3(.035,.025,.075);
}
