extends "res://scripts/combat/city/nightshift/workshop.gd"
## Fixed-camera 3D projection set. Original plate supplies exact facade art;
## walk surfaces, depth proxies, moving parts, lights, effects and heroes are 3D.
const REF_SIZE=Vector2(1672,941)
const LOFT_Y=1.6
const STATION_PIXELS=[Vector2(625,615),Vector2(970,661),Vector2(1155,550),Vector2(280,515),Vector2(1310,828),Vector2(925,514)]
const ACTOR_PIXELS=[Vector2(800,851),Vector2(620,571),Vector2(252,469),Vector2(975,593)]
const AIM_PIXELS=[Vector2(690,435),Vector2(970,500),Vector2(1175,375),Vector2(285,399),Vector2(1395,664),Vector2(925,307)]
var stations:Array[Vector3]=[]
var spawns:Array[Vector3]=[]
var aims:Array[Vector3]=[]
var floor_outline:=PackedVector2Array()
var loft_outline:=PackedVector2Array()
var stair_outline:=PackedVector2Array()
var stair_bottom:Vector3
var stair_top:Vector3
var projection_material:ShaderMaterial
var trace_root:Node3D
var beams:Array[MeshInstance3D]=[]
var pools:Array[MeshInstance3D]=[]
var smoke:Array[MeshInstance3D]=[]
var arcs:Array[MeshInstance3D]=[]
var robot:Array[MeshInstance3D]=[]
var actor_sizes:Dictionary={}
var demo_enabled:=true
var gate_mix:=0.0
var night_mix:=0.0
var bounds_rect:Rect2
var grey_avatar:Node3D
var aperture:MeshInstance3D
var dealer_rig:Node3D
var discs:Array[Node3D]=[]
var lift_shadow:Node3D

func build() -> void:
    name="NightshiftWorkshop"
    camera=Camera3D.new();camera.name="ReferenceCamera";camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.keep_aspect=Camera3D.KEEP_HEIGHT;camera.size=12.0
    add_child(camera);camera.position=Vector3(12,10,24);camera.look_at(Vector3(0,1,0));camera.current=true
    environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=PINK
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color.WHITE;environment.ambient_light_energy=.95
    var env:=WorldEnvironment.new();env.environment=environment;add_child(env)
    var key_light:=DirectionalLight3D.new();key_light.rotation_degrees=Vector3(-28,-20,0);key_light.light_energy=1.4;add_child(key_light)
    projection_material=ShaderMaterial.new();projection_material.shader=preload("res://scripts/combat/city/nightshift/reference.gdshader")
    projection_material.set_shader_parameter("plate",load("res://assets/city/reference/empty-workshop.png"))
    projection_material.set_shader_parameter("ref_right",camera.global_basis.x)
    projection_material.set_shader_parameter("ref_up",camera.global_basis.y)
    projection_material.set_shader_parameter("ref_center",Vector3(0,1,0))
    projection_material.set_shader_parameter("ref_span",Vector2(12.0*REF_SIZE.x/REF_SIZE.y,12.0))
    _backdrop();_depth_geometry();_navigation_data();_robot();_lights();_dealer_model()
    for i in STATION_PIXELS.size():
        var height:=LOFT_Y if i==3 else 0.0
        stations.append(ref_point(STATION_PIXELS[i],height))
        aims.append(ref_point(AIM_PIXELS[i],height+1.4))
    for i in 4:spawns.append(ref_point(ACTOR_PIXELS[i],LOFT_Y if i==2 else 0.0))
    _navigation()

func ref_point(pixel:Vector2,height:=0.0) -> Vector3:
    var screen:Vector2=pixel/REF_SIZE*get_viewport().get_visible_rect().size
    var result:Variant=Plane(Vector3.UP,height).intersects_ray(camera.project_ray_origin(screen),camera.project_ray_normal(screen))
    return result if result!=null else Vector3.ZERO

func _backdrop() -> void:
    var backdrop:=MeshInstance3D.new();backdrop.name="ReferenceMatteBehindDepthGeometry"
    var shape:=QuadMesh.new();shape.size=Vector2(12.0*REF_SIZE.x/REF_SIZE.y,12.0);backdrop.mesh=shape
    backdrop.material_override=projection_material;add_child(backdrop)
    backdrop.global_basis=camera.global_basis;backdrop.global_position=Vector3(0,1,0)-camera.global_basis.z*50

func patch(label:String,pixels:Array,heights:Array) -> MeshInstance3D:
    var verts:=PackedVector3Array();var coords:=PackedVector2Array()
    for i in pixels.size():verts.append(ref_point(pixels[i],heights[i]));coords.append(pixels[i])
    var ids:=Geometry2D.triangulate_polygon(coords);var list:=PackedVector3Array()
    for i in ids:list.append(verts[i])
    var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=list
    var normals:=PackedVector3Array();normals.resize(list.size());normals.fill(Vector3.UP);arrays[Mesh.ARRAY_NORMAL]=normals
    var shape:=ArrayMesh.new();shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    var node:=MeshInstance3D.new();node.name=label;node.mesh=shape;node.material_override=projection_material;trace_root.add_child(node)
    if label in ["BackWall","GateAndACWall"]:node.position-=camera.global_basis.z*8.0
    if label=="DJDeckFront":node.position+=camera.global_basis.z*2.0
    return node

func _depth_geometry() -> void:
    trace_root=Node3D.new();trace_root.name="ReferenceAlignedDepthSurfaces";add_child(trace_root)
    patch("Ground",[Vector2(10,773),Vector2(310,931),Vector2(803,941),Vector2(1178,874),Vector2(1384,929),Vector2(1653,754),Vector2(1653,464),Vector2(1315,402),Vector2(1152,460),Vector2(875,442),Vector2(535,536),Vector2(314,609),Vector2(130,604)],[0,0,0,0,0,0,0,0,0,0,0,0,0])
    patch("BackWall",[Vector2(52,172),Vector2(1053,32),Vector2(1235,53),Vector2(1248,389),Vector2(872,495),Vector2(505,566),Vector2(52,512)],[5.8,5.8,5.8,0,0,0,0])
    patch("GateAndACWall",[Vector2(1250,109),Vector2(1625,191),Vector2(1625,488),Vector2(1250,545)],[5.6,5.6,0,0])
    patch("LoftFloor",[Vector2(16,513),Vector2(313,616),Vector2(537,448),Vector2(222,383)],[LOFT_Y,LOFT_Y,LOFT_Y,LOFT_Y])
    patch("DJDeckFront",[Vector2(192,451),Vector2(458,393),Vector2(458,492),Vector2(201,577)],[3.0,3.0,LOFT_Y,LOFT_Y])
    patch("WorkbenchFace",[Vector2(532,432),Vector2(871,393),Vector2(864,494),Vector2(537,543)],[1.75,1.75,0,0])
    patch("SlotMachineFront",[Vector2(1111,277),Vector2(1280,309),Vector2(1242,488),Vector2(1065,458)],[3.2,3.2,0,0])
    patch("LiftFront",[Vector2(1238,511),Vector2(1497,542),Vector2(1500,805),Vector2(1238,749)],[4.5,4.5,0,0])
    patch("LiftSide",[Vector2(1497,542),Vector2(1649,493),Vector2(1649,751),Vector2(1500,805)],[4.5,4.5,0,0])
    # The only animated physical lamp is rebuilt rather than left printed in the plate.

func _world_poly(pixels:Array,height:float) -> PackedVector2Array:
    var poly:=PackedVector2Array()
    for p in pixels:
        var point:=ref_point(p,height);poly.append(Vector2(point.x,point.z))
    return poly

func _navigation_data() -> void:
    floor_outline=_world_poly([Vector2(30,760),Vector2(320,910),Vector2(800,916),Vector2(1160,850),Vector2(1370,903),Vector2(1620,735),Vector2(1500,456),Vector2(1290,426),Vector2(1130,460),Vector2(880,420),Vector2(530,530),Vector2(300,605)],0)
    loft_outline=_world_poly([Vector2(20,510),Vector2(315,610),Vector2(534,448),Vector2(225,385)],LOFT_Y)
    stair_bottom=ref_point(Vector2(110,760),0);stair_top=ref_point(Vector2(280,579),LOFT_Y)
    var axis:Vector3=stair_top-stair_bottom;axis.y=0
    var side:=Vector3(-axis.z,0,axis.x).normalized()*.85
    stair_outline=PackedVector2Array([Vector2(stair_bottom.x+side.x,stair_bottom.z+side.z),Vector2(stair_top.x+side.x,stair_top.z+side.z),Vector2(stair_top.x-side.x,stair_top.z-side.z),Vector2(stair_bottom.x-side.x,stair_bottom.z-side.z)])
    bounds_rect=Rect2(floor_outline[0],Vector2.ZERO)
    for point in floor_outline:bounds_rect=bounds_rect.expand(point)
    for point in loft_outline:bounds_rect=bounds_rect.expand(point)
    obstacles.clear()
    # Actual world footprints, separate from the projected depth surfaces.
    for entry in [[Vector2(700,480),Vector2(3.7,1.1)],[Vector2(1170,450),Vector2(2.5,1.3)],[Vector2(1390,738),Vector2(3.3,1.7)],[Vector2(470,855),Vector2(.65,.65)],[Vector2(410,777),Vector2(1.7,.8)]]:
        var p:=ref_point(entry[0]);blocker(Rect2(Vector2(p.x,p.z)-entry[1]*.5,entry[1]),0,8)

func in_loft(point:Vector3) -> bool:return Geometry2D.is_point_in_polygon(Vector2(point.x,point.z),loft_outline)
func height_at(at:Vector3) -> float:
    var p:=Vector2(at.x,at.z)
    if Geometry2D.is_point_in_polygon(p,stair_outline):
        var line:=Vector2(stair_top.x-stair_bottom.x,stair_top.z-stair_bottom.z)
        return clampf((p-Vector2(stair_bottom.x,stair_bottom.z)).dot(line)/line.length_squared(),0,1)*LOFT_Y
    if in_loft(at):return LOFT_Y
    return 0
func walkable(at:Vector3) -> bool:
    var p:=Vector2(at.x,at.z)
    if not Geometry2D.is_point_in_polygon(p,floor_outline) and not in_loft(at) and not Geometry2D.is_point_in_polygon(p,stair_outline):return false
    for obstacle in obstacles:
        if (obstacle.rect as Rect2).grow(.2).has_point(p):return false
    return true
func _navigation() -> void:
    graph.clear();cells.clear()
    var index:=0
    for x in range(floori(bounds_rect.position.x*2)-1,ceili(bounds_rect.end.x*2)+2):
        for z in range(floori(bounds_rect.position.y*2)-1,ceili(bounds_rect.end.y*2)+2):
            var at:=Vector3(float(x)*.5,0,float(z)*.5);at.y=height_at(at)
            if not walkable(at):continue
            cells[Vector2i(x,z)]=index;graph.add_point(index,at);index+=1
    for cell:Vector2i in cells:
        for offset in [Vector2i(1,0),Vector2i(0,1)]:
            if not cells.has(cell+offset):continue
            var a:int=cells[cell];var b:int=cells[cell+offset]
            if absf(graph.get_point_position(a).y-graph.get_point_position(b).y)<.35:graph.connect_points(a,b)
func accent_station(_index:int) -> void:pass # Reference has no floor station frames.
func progress(_best:int) -> void:pass # No unrelated trophy wall.

func _robot() -> void:
    # Reference orange articulated lamp: tabletop base, two hinged links, faceted head.
    for i in 4:robot.append(box(Vector3.ZERO,Vector3(.18,1,.18),ORANGE))
    robot[0].mesh=BoxMesh.new();robot[0].mesh.size=Vector3(.5,.18,.5)
    robot[3].mesh=BoxMesh.new();robot[3].mesh.size=Vector3(.55,.35,.5)

func _lights() -> void:
    for i in 3:
        var beam:=MeshInstance3D.new();var beam_mesh:=CylinderMesh.new();beam_mesh.top_radius=.04;beam_mesh.bottom_radius=.9;beam_mesh.height=1;beam_mesh.radial_segments=12
        beam.mesh=beam_mesh;var mat:=ShaderMaterial.new();mat.shader=preload("res://scripts/combat/city/nightshift/light.gdshader");mat.set_shader_parameter("color",Color(1,.98,.9,.08));beam.material_override=mat;add_child(beam);beams.append(beam)
        var pool:=MeshInstance3D.new();var quad:=PlaneMesh.new();quad.size=Vector2(3,3);pool.mesh=quad
        var pool_mat:=ShaderMaterial.new();pool_mat.shader=mat.shader;pool_mat.set_shader_parameter("spot",true);pool_mat.set_shader_parameter("color",Color(1,.97,.88,.75));pool.material_override=pool_mat;add_child(pool);pools.append(pool)
    for i in 10:
        var puff:=MeshInstance3D.new();var puff_mesh:=SphereMesh.new();puff_mesh.radius=.15;puff_mesh.height=.25;puff_mesh.radial_segments=5;puff_mesh.rings=2;puff.mesh=puff_mesh
        var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_color=Color(1,1,1,.25);puff.material_override=mat;add_child(puff);smoke.append(puff)
    for i in 12:arcs.append(box(Vector3.ZERO,Vector3(.035,.25,.035),LIME))
    var portal:=QuadMesh.new();portal.size=Vector2(1.8,3.3);aperture=MeshInstance3D.new();aperture.mesh=portal;aperture.material_override=material(PINK);add_child(aperture)
    var center:=ref_point(Vector2(1390,664),1.8)
    var corners:Array=[ref_point(Vector2(1293,548),3.4),ref_point(Vector2(1466,576),3.4),ref_point(Vector2(1466,785),0),ref_point(Vector2(1293,746),0)]
    var vertices:=PackedVector3Array()
    for i in [0,1,2,0,2,3]:vertices.append(corners[i]-center)
    var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices
    var shape:=ArrayMesh.new();shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);aperture.mesh=shape
    aperture.position=center+camera.global_basis.z*4.0;aperture.hide()
    lift_shadow=Node3D.new();aperture.add_child(lift_shadow)
    box(Vector3(0,-.2,.08),Vector3(.55,.9,.025),INK,lift_shadow)
    cylinder(Vector3(0,.47,.08),.21,.40,INK,lift_shadow,5)
    for side in [-1,1]:
        bar(Vector3(side*.18,-.55,.08),Vector3(side*.32,-1.1,.08),.16,INK,lift_shadow)
        bar(Vector3(side*.23,.1,.08),Vector3(side*.48,-.3,.08),.13,INK,lift_shadow)

func advance(delta:float,reduced:bool) -> void:
    pulse_time+=maxf(delta,0);action_age+=delta
    sample(pulse_time,reduced)

func sample(seconds:float,reduced:=false) -> void:
    var t:=fposmod(seconds,15.0)
    for disc in discs:disc.rotation.y=t*2.4
    if dealer_rig!=null:
        dealer_rig.motions.present({"character":0,"health":100,"state":"idle","move":"","frame":0,"y":0.0,"vy":0.0,"vx":0.0,"face":1,"guarding":false,"showcase":true},0.0,true)
        var m=dealer_rig.motions
        for side in ["Left","Right"]:
            m._aim_limb(side+"Arm",side+"ForeArm",-m.model_up*.6+m.model_forward*.3,1.0)
            m._aim_limb(side+"ForeArm",side+"Hand",m.model_forward*.35+m.model_up*.45,1.0)
    night_mix=0.0 if reduced else smoothstep(.35,1.15,seconds)
    gate_mix=0.0 if reduced else smoothstep(7.5,8.2,t)*(1-smoothstep(12.3,13.1,t))
    projection_material.set_shader_parameter("night",night_mix);projection_material.set_shader_parameter("clock",t);projection_material.set_shader_parameter("gate_open",gate_mix)
    for i in beams.size():
        var start:=ref_point([Vector2(493,90),Vector2(1344,215),Vector2(1460,235)][i],6.5)
        var end:=ref_point([Vector2(720+65*sin(t*.8),565),Vector2(1040+80*sin(t*.6),670),Vector2(800+110*sin(t*.45),850)][i])
        var beam:MeshInstance3D=beams[i];beam.visible=not reduced and t>.6
        beam.position=(start+end)*.5;beam.quaternion=Quaternion(Vector3.UP,(start-end).normalized());beam.scale.y=start.distance_to(end)
        pools[i].visible=beam.visible;pools[i].position=end+Vector3(0,.04,0)
    var pipe:=ref_point(Vector2(495,111),6.3)
    for i in smoke.size():
        var age:=fposmod(t*1.2+float(i)*.18,2.0)
        smoke[i].visible=not reduced and t>4.8
        smoke[i].position=pipe+Vector3(sin(float(i)*1.8+age)*.12,-age*.8,.10*age)
        smoke[i].scale=Vector3.ONE*(.5+age*.7)
        (smoke[i].material_override as StandardMaterial3D).albedo_color=Color(1,1,1,.22*(1-age*.5))
    var powered:=not reduced and t>=9.0 and t<12.6
    for i in arcs.size():
        arcs[i].visible=powered
        var angle:=float(i)*TAU/12+t*3
        var a:=ref_point(Vector2(1115+cos(angle)*100,390+sin(angle)*85),1.9)
        var b:=ref_point(Vector2(1115+cos(angle+.12)*125,390+sin(angle+.12)*105),1.9)
        arcs[i].position=(a+b)*.5;arcs[i].quaternion=Quaternion(Vector3.UP,(b-a).normalized());arcs[i].scale.y=a.distance_to(b)/.25
    var root_point:=ref_point(Vector2(794,381),1.5)
    var elbow:=ref_point(Vector2(827+8*sin(t*.9),245+9*sin(t*.9)),3.0)
    var head:=ref_point(Vector2(760+14*sin(t*.9),190+7*cos(t*.9)),3.8)
    robot[0].position=root_point
    for i in [1,2]:
        var a:Vector3=root_point if i==1 else elbow;var b:Vector3=elbow if i==1 else head
        robot[i].position=(a+b)*.5;robot[i].quaternion=Quaternion(Vector3.UP,(b-a).normalized());robot[i].scale.y=a.distance_to(b)
    robot[3].position=head;robot[3].rotation.z=-.25+.1*sin(t*.9)
    aperture.visible=not reduced and t>=7.9 and t<12.6
    lift_shadow.rotation.z=sin(t*3)*.08
    environment.background_color=Color("031225") if night_mix>.5 else PINK

func calibrate_actor(actor:Node3D,id:int) -> void:
    if actor_sizes.has(actor) and actor.get_meta("ref_character",-1)==id:return
    var bounds:=AABB();var first:=true
    for node:MeshInstance3D in actor.model.find_children("*","MeshInstance3D",true,false):
        var local:Transform3D=actor.global_transform.affine_inverse()*node.global_transform
        var rect:AABB=local*node.get_aabb()
        bounds=rect if first else bounds.merge(rect);first=false
    var height:float=maxf(.1,bounds.size.y)
    var pixels_per_metre:float=absf(camera.unproject_position(Vector3.UP).y-camera.unproject_position(Vector3.ZERO).y)
    var target:float=[305.0,255.0,215.0,265.0][id]/REF_SIZE.y*get_viewport().get_visible_rect().size.y
    actor.scale=Vector3.ONE*target/(height*pixels_per_metre)
    actor.set_meta("ref_character",id);actor.set_meta("ref_floor",-bounds.position.y);actor_sizes[actor]=actor.scale.x

func pose_actor(actor:Node3D,id:int,walking:bool,reduced:bool,ambient:=false) -> void:
    calibrate_actor(actor,id)
    actor.model.position.y=float(actor.get_meta("ref_floor",0.0))
    if walking:return
    var t:=fposmod(pulse_time,15.0);var m=actor.motions
    var up:Vector3=m.model_up;var forward:Vector3=m.model_forward;var right:Vector3=up.cross(forward).normalized()
    actor.rotation.y=.45
    if not reduced:actor.model.rotation.z=sin(t*TAU*1.6)*.025
    match id:
        0:
            if ambient and m.library.clips.has("MX_Wave"):
                var greeting:float=clampf((t-.2)/1.47,0,1) if t<5.0 else clampf((t-10.25)/1.47,0,1)
                m.present({"character":id,"health":100,"state":"idle","move":"","frame":0,"y":0.0,"vy":0.0,"vx":0.0,"face":1,"guarding":false,"cinematic_clip":"MX_Wave","cinematic_phase":greeting,"motion_no_blend":true},0.0,true)
                actor.skeleton.force_update_all_bone_transforms()
                actor.model.position.y+=maxf(0.0,actor.global_position.y+.01-actor.lowest_skin_y())/maxf(.01,actor.global_basis.y.length())
                return
            var wave:float=1-smoothstep(2.4,3.4,t)+smoothstep(10,10.5,t)*(1-smoothstep(12,13,t))
            m._aim_limb("LeftArm","LeftForeArm",(-up*.65+right*.25).lerp(right*.8+up*.2,wave),1.0)
            m._aim_limb("LeftForeArm","LeftHand",(-up*.3+forward*.25).lerp(up+right*sin(t*4)*.12,wave),1.0)
            m._aim_limb("RightArm","RightForeArm",-up+forward*.15,.8)
            m._aim_limb("RightForeArm","RightHand",-up*.5+forward*.3,.8)
        1:
            var press:float=.6+.2*sin(t*1.4)
            m._aim_limb("RightArm","RightForeArm",-up*.7+forward*.6,press)
            m._aim_limb("RightForeArm","RightHand",forward*.8-up*.4,press)
            actor.model.rotation.x=.12
        2:
            var wave:float=1-smoothstep(.4,1.6,fposmod(t,4.0))
            m._aim_limb("RightArm","RightForeArm",(forward*.8-up*.4).lerp(up,wave),1.0)
            m._aim_limb("RightForeArm","RightHand",(forward-up*.2).lerp(up,wave),1.0)
            m._aim_limb("LeftArm","LeftForeArm",-up*.4+forward*.65,.9)
            m._aim_limb("LeftForeArm","LeftHand",forward-up*.5,.9)
        3:
            var travel:float=smoothstep(5.0,7.0,t)*(1-smoothstep(12.4,14.4,t))
            if actor.get_parent()==get_parent():actor.position=spawns[3]+(ref_point(Vector2(1095,560))-spawns[3])*travel
            var crouch:float=1.0-smoothstep(4.6,6.0,t)+smoothstep(12.6,14.2,t)
            actor.model.position.y-=.32*crouch
            actor.model.rotation.x=.13*crouch
            for label in ["Left","Right"]:
                m._aim_limb(label+"UpLeg",label+"Leg",-up*.55+forward*.55,crouch*.8)
                m._aim_limb(label+"Leg",label+"Foot",-up-forward*.5,crouch*.8)
            m._aim_limb("LeftArm","LeftForeArm",-up*.6+forward*.3,.8)
            m._aim_limb("LeftForeArm","LeftHand",-up*.7+right*.2,.8)
    for label in ["LeftHand","RightHand"]:
        var index:int=m.bone_index(label)
        if index>=0:actor.skeleton.set_bone_pose_scale(index,Vector3.ONE*(1.45 if id==1 else 1.15))
    actor.skeleton.force_update_all_bone_transforms()

func _dealer_model() -> void:
    dealer_rig=preload("res://scripts/combat/ability_draw/dealer_rig.gd").new();add_child(dealer_rig);dealer_rig.setup()
    dealer_rig.position=ref_point(Vector2(1071,428));dealer_rig.rotation.y=.45;dealer_rig.scale=Vector3.ONE*.92
    _style_asset(dealer_rig.model,false)
    for p in [Vector2(269,439),Vector2(383,396)]:
        var holder:=Node3D.new();add_child(holder);holder.position=ref_point(p,LOFT_Y+1.35)
        cylinder(Vector3.ZERO,.28,.025,INK,holder)
        box(Vector3(.17,.02,0),Vector3(.17,.015,.025),CYAN,holder);discs.append(holder)

func _style_asset(model:Node3D,cabinet:bool) -> void:
    for node:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
        for surface in node.mesh.get_surface_count():
            var original:Material=node.get_active_material(surface)
            var texture:Texture2D=null
            if original is BaseMaterial3D:texture=original.albedo_texture
            elif original is ShaderMaterial:texture=original.get_shader_parameter("base_texture")
            if texture!=null:
                var mat:=ShaderMaterial.new();mat.shader=preload("res://scripts/combat/city/nightshift/asset.gdshader")
                mat.set_shader_parameter("base_texture",texture);mat.set_shader_parameter("cabinet_cutout",cabinet);node.set_surface_override_material(surface,mat)
