extends Node3D
## Rebuildable low-poly set. The same surface/obstacle data owns walking AND route finding.
const INK=Color("101019")
const PAPER=Color("f4f1f1")
const GREY=Color("bdb9cb")
const PINK=Color("ff008c")
const CYAN=Color("00d8ee")
const LIME=Color("bbff00")
const ORANGE=Color("ff8d18")
const STATIONS=[Vector3(-3.1,0,-2.1),Vector3(.1,0,-2.6),Vector3(5.8,0,-.8),Vector3(-6.4,2.1,-.4),Vector3(6,0,3.7),Vector3(2.9,0,-2.6)]
const TITLES=["RIVET / CLASS SKILLS","LOOP / CIRCUIT","THE DEALER / CORE + GEAR","HUSH / RADIO + STORY","FREIGHT LIFT / DEPART","COUNTER / SHOP + WORKSHOP"]
const ACCENTS=[ORANGE,LIME,CYAN,PINK,CYAN,PINK]
const BOUNDS=Rect2(-9.4,-5.35,18.8,11.7)
const LOFT=Rect2(-9.1,-5.35,4.3,6.35)
const STAIRS=Rect2(-9.1,1.0,1.65,4.0)
var section:Node3D
var obstacles:Array[Dictionary]=[]
var materials:Dictionary={}
var camera:Camera3D
var station_marks:Array[Node3D]=[]
var turntables:Array[MeshInstance3D]=[]
var fans:Array[Node3D]=[]
var trophies:Array[MeshInstance3D]=[]
var sparks:Array[MeshInstance3D]=[]
var gate:Node3D
var pulse_time:=0.0
var action_age:=2.0
var action_station:=-1
var lift_slats:Array[MeshInstance3D]=[]
var graph:=AStar3D.new()
var cells:Dictionary={}
var environment:Environment
var mesh_count:=0
var material_shader=preload("res://scripts/combat/city/nightshift/facet.gdshader")

func material(tint:Color) -> ShaderMaterial:
    var key:=tint.to_html()
    if not materials.has(key):
        var mat:=ShaderMaterial.new();mat.shader=material_shader;mat.set_shader_parameter("base_color",tint);materials[key]=mat
    return materials[key]

func box(at:Vector3,size:Vector3,tint:Color,parent:Node3D=self) -> MeshInstance3D:
    var node:=MeshInstance3D.new();var shape:=BoxMesh.new();shape.size=size;node.mesh=shape
    node.material_override=material(tint);(section if parent==self and section!=null else parent).add_child(node);node.position=at;mesh_count+=1
    return node

func bar(a:Vector3,b:Vector3,width:float,tint:Color,parent:Node3D=self) -> MeshInstance3D:
    var node:=box((a+b)*.5,Vector3(width,a.distance_to(b),width),tint,parent)
    if a.distance_to(b)>.001:node.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
    return node

func cylinder(at:Vector3,radius:float,height:float,tint:Color,parent:Node3D=self,segments:=8) -> MeshInstance3D:
    var node:=MeshInstance3D.new();var shape:=CylinderMesh.new();shape.top_radius=radius;shape.bottom_radius=radius;shape.height=height;shape.radial_segments=segments;shape.rings=1
    node.mesh=shape;node.material_override=material(tint);(section if parent==self and section!=null else parent).add_child(node);node.position=at;mesh_count+=1
    return node

func polygon(points:PackedVector2Array,at:Vector3,tint:Color,parent:Node3D=self) -> MeshInstance3D:
    var vertices:=PackedVector3Array();var normals:=PackedVector3Array()
    var indices:=Geometry2D.triangulate_polygon(points)
    for i in indices:vertices.append(Vector3(points[i].x,0,points[i].y));normals.append(Vector3.UP)
    var arrays:Array=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals
    var shape:=ArrayMesh.new();shape.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    var node:=MeshInstance3D.new();node.mesh=shape;node.material_override=material(tint);(section if parent==self and section!=null else parent).add_child(node);node.position=at;mesh_count+=1
    return node

func blocker(rect:Rect2,low:=0.0,high:=2.0) -> void:
    obstacles.append({"rect":rect,"low":low,"high":high})

func build() -> void:
    name="NightshiftWorkshop"
    environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=PINK
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color.WHITE;environment.ambient_light_energy=.9
    var env:=WorldEnvironment.new();env.environment=environment;add_child(env)
    var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,-35,0);light.light_energy=.8;add_child(light)
    var builders:Array[Callable]=[_architecture,_loft,_workbench,_circuit,_shop,_dealer,_lift,_details]
    var sections:Array=["Architecture","DJLoft","RivetWorkbench","LoopCircuit","ShopHatch","DealerAlcove","FreightLift","LocalDetails"]
    for i in builders.size():
        section=Node3D.new();section.name=sections[i];add_child(section);builders[i].call()
    section=null
    for i in STATIONS.size():
        var marker:=Node3D.new();marker.name="Approach_"+str(i);marker.position=STATIONS[i]+Vector3(0,.035,0);add_child(marker)
        for a in [-1,1]:
            for b in [-1,1]:
                box(Vector3(a*.56,0,b*.46),Vector3(.30,.025,.06),ACCENTS[i],marker)
                box(Vector3(a*.68,0,b*.34),Vector3(.06,.025,.26),ACCENTS[i],marker)
        station_marks.append(marker)
    camera=Camera3D.new();camera.name="IsometricCamera";camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=18.5
    add_child(camera);camera.position=Vector3(22,21,26);camera.look_at(Vector3(0,1.25,0));camera.current=true
    _navigation()

func _architecture() -> void:
    box(Vector3(0,-.3,.5),Vector3(20,.6,13),INK)
    box(Vector3(0,-.02,.5),Vector3(19.8,.08,12.8),PAPER)
    box(Vector3(0,2.3,-5.7),Vector3(20,.0+4.6,.25),INK)
    box(Vector3(-9.85,2.3,-2.5),Vector3(.25,4.6,6.6),PAPER)
    # Camera-facing wall is a cutaway; it must never hide the dealer or cabinet.
    box(Vector3(9.85,.25,-2.5),Vector3(.25,.5,6.6),PAPER)
    # Black/white rear wall; large panes reveal the pink night, not a realistic skyline.
    for x in [-8.0,-4.0,0.0,4.0,8.0]:
        box(Vector3(x,3.75,-5.53),Vector3(3.7,1.3,.05),PINK)
        for dx in [-1.8,-.9,0,.9,1.8]:box(Vector3(x+dx,3.75,-5.45),Vector3(.065,1.4,.08),PAPER)
        box(Vector3(x,3.75,-5.43),Vector3(3.7,.07,.08),PAPER)
    for x in [-9.75,-5.1,1.3,9.75]:box(Vector3(x,2.3,-5.35),Vector3(.16,4.7,.16),PAPER)
    for x in [-9.2,8.7]:
        box(Vector3(x,0,-8.8),Vector3(2.8,.2,3),INK)
        box(Vector3(x,3.8,-8.8),Vector3(2.8,7.6,1.6),PAPER)
        for row in 5:
            for col in 3:box(Vector3(x-1+col,.6+row*1.3,-7.97),Vector3(.6,.85,.025),INK)
    for x in [-7,3,9]:bar(Vector3(x,7,-8),Vector3(x-2,5.0,-6),.045,INK)
    # Sparse graphic floor shapes keep character feet readable.
    for x in [-6,-1.5,3.0]:
        polygon(PackedVector2Array([Vector2(0,0),Vector2(2.8,-.8),Vector2(1.6,.5),Vector2(3.0,.25),Vector2(.1,2),Vector2(.9,.6)]),Vector3(x,.04,2.2),INK)
    for x in range(-9,10,2):box(Vector3(x,.04,6.7),Vector3(.85,.03,.18),INK)
    _pipe([Vector3(-5.6,0,-5.05),Vector3(-5.6,4.6,-5.05),Vector3(-5.6,5.0,-4.3),Vector3(-4.3,5.0,-4.3)],.38,GREY)

func _pipe(points:Array,width:float,tint:Color) -> void:
    for i in range(1,points.size()):bar(points[i-1],points[i],width,tint)
    for point in points:box(point,Vector3.ONE*width*1.25,tint)

func _loft() -> void:
    box(Vector3(-7.0,1.94,-2.25),Vector3(4.6,.32,6.5),PAPER)
    for x in [-9.3,-4.7]:
        for z in [-5.3,.9]:box(Vector3(x,1,z),Vector3(.18,2,.18),INK)
    # Stairs are sampled as a continuous ramp for walking, with visible individual treads.
    for i in 10:
        box(Vector3(-8.275,.105+float(i)*.21,4.8-float(i)*.4),Vector3(1.65,.21,.40),PAPER)
        box(Vector3(-8.275,.22+float(i)*.21,4.78-float(i)*.4),Vector3(1.65,.025,.08),INK)
    for x in [-9.2,-7.35]:
        bar(Vector3(x,.8,5),Vector3(x,2.9,1),.10,INK)
        for z in [1.0,3.0,5.0]:bar(Vector3(x,(5-z)*.525,z),Vector3(x,(5-z)*.525+.8,z),.08,INK)
    for z in [-4.8,1.0]:
        bar(Vector3(-9.3,3,z),Vector3(-4.7,3,z),.10,INK)
        for x in [-9.3,-7,-4.7]:bar(Vector3(x,2.1,z),Vector3(x,3,z),.08,INK)
    bar(Vector3(-4.7,3,-4.8),Vector3(-4.7,3,1),.10,INK)
    for z in [-4,-2,0]:bar(Vector3(-4.7,2.1,z),Vector3(-4.7,3,z),.08,INK)
    box(Vector3(-7.1,2.8,-2.7),Vector3(3.0,.20,1.05),PAPER)
    for x in [-8.4,-5.8]:box(Vector3(x,2.45,-2.7),Vector3(.14,.7,.7),INK)
    for x in [-7.9,-6.5]:
        cylinder(Vector3(x,2.93,-2.7),.42,.07,INK)
        turntables.append(cylinder(Vector3(x,2.98,-2.7),.20,.025,CYAN))
    box(Vector3(-7.2,2.94,-2.7),Vector3(.35,.06,.55),PINK)
    for x in [-8.9,-5.1]:
        box(Vector3(x,2.9,-3.4),Vector3(.6,1.6,.65),INK)
        for y in [2.5,3.1]:
            var cone:=cylinder(Vector3(x,y,-3.03),.22,.04,CYAN);cone.rotation_degrees.x=90
            var core:=cylinder(Vector3(x,y,-2.995),.12,.04,INK);core.rotation_degrees.x=90
    box(Vector3(-7.2,2.4,-4.7),Vector3(2.2,.6,.65),INK)
    box(Vector3(-7.2,2.9,-5),Vector3(2.2,.6,.15),GREY)
    box(Vector3(-6,3.8,-5.2),Vector3(1.5,.1,.1),PINK)
    for x in [-8.5,-7.4,-6.3]:box(Vector3(x,.5,-3.7),Vector3(.9,1,.9),GREY)
    blocker(Rect2(-9.2,-3.5,4.5,1.45),2.05,4)
    blocker(Rect2(-8.5,-5.3,2.8,.9),2.05,4)
    blocker(Rect2(-9.3,-4.6,4.6,3),0,1.95)

func _workbench() -> void:
    box(Vector3(-2.8,1,-4.5),Vector3(4.1,.24,1.35),PAPER)
    for x in [-4.6,-1.0]:box(Vector3(x,.5,-4.5),Vector3(.18,1,1.3),INK)
    box(Vector3(-3.4,.5,-4.5),Vector3(1.65,.8,1.2),INK)
    for i in 4:box(Vector3(-4.03+float(i)*.42,.65,-3.88),Vector3(.36,.40,.06),[CYAN,ORANGE,PINK,LIME][i])
    box(Vector3(-2.8,2.5,-5.27),Vector3(4,2.3,.13),PAPER)
    for x in [-4.3,-3.8,-3.3,-2.8,-2.3,-1.8,-1.3]:
        for y in [1.6,2.0,2.4,2.8,3.2]:box(Vector3(x,y,-5.18),Vector3(.035,.035,.025),INK)
    for x in [-4.0,-3.25,-2.5,-1.75]:
        box(Vector3(x,2.6,-5.1),Vector3(.12,.95,.06),INK)
        box(Vector3(x,3.05,-5.1),Vector3(.45,.15,.06),INK)
    box(Vector3(-1.5,1.25,-4.3),Vector3(.9,.28,.6),ORANGE)
    box(Vector3(-1.5,1.6,-4.3),Vector3(.65,.5,.35),ORANGE)
    bar(Vector3(-2,1.65,-4.3),Vector3(-.9,1.65,-4.3),.08,INK)
    bar(Vector3(-2.3,1.15,-4.9),Vector3(-2.3,3.5,-4.9),.08,ORANGE)
    bar(Vector3(-2.3,3.5,-4.9),Vector3(-3.2,3.5,-4.3),.08,ORANGE)
    box(Vector3(-3.2,3.45,-4.3),Vector3(.55,.1,.45),ORANGE)
    for i in 7:
        var spark:=box(Vector3(-2,1.2,-4.3),Vector3(.025,.18,.025),ORANGE);spark.hide();sparks.append(spark)
    blocker(Rect2(-4.9,-5.2,4.4,1.8))

func _circuit() -> void:
    box(Vector3(.1,.7,-4.5),Vector3(1.0,1.4,.65),INK)
    box(Vector3(.1,1.75,-4.5),Vector3(1.1,.8,.7),LIME)
    box(Vector3(.1,1.75,-4.1),Vector3(.8,.52,.04),INK)
    for x in [-.15,.15]:
        for y in [1.65,1.85]:box(Vector3(x,y,-4.05),Vector3(.15,.12,.025),CYAN)
    _pipe([Vector3(.5,1.6,-4.0),Vector3(.95,1.6,-4.0),Vector3(.95,.6,-4.0),Vector3(.5,.6,-4.0)],.06,LIME)
    blocker(Rect2(-.6,-5.1,1.7,1.4))

func _shop() -> void:
    box(Vector3(2.9,1.25,-5.1),Vector3(2.7,2.5,.55),PAPER)
    box(Vector3(2.9,1.85,-4.78),Vector3(2.2,1.15,.05),INK)
    box(Vector3(2.9,1.05,-4.55),Vector3(2.8,.15,.7),PAPER)
    box(Vector3(2.9,2.65,-4.8),Vector3(2.9,.35,.8),PINK)
    for x in [2.1,2.7,3.3,3.8]:box(Vector3(x,1.4,-4.75),Vector3(.24,.35,.23),GREY)
    # A little faceless clerk silhouette is geometry, not another combat actor.
    box(Vector3(3.3,1.6,-4.72),Vector3(.45,.5,.25),INK)
    cylinder(Vector3(3.3,2.0,-4.72),.19,.35,INK)
    blocker(Rect2(1.45,-5.4,2.9,1.6))

func _dealer() -> void:
    var source:Node3D=load("res://assets/ability_draw/source/tripo_convert_275dc57f-e328-47e0-89e5-10195d3209c4.glb").instantiate()
    source.name="PreservedTripoCabinet";add_child(source);source.position=Vector3(7.4,.1,-3.7);source.scale=Vector3.ONE*2.0
    _style_asset(source,true)
    # Actual visible reels are separate geometry; source GLB stays byte-for-byte unchanged.
    for i in 3:
        var wheel:=cylinder(Vector3(6.88+float(i)*.5,1.38,-3.18),.20,.09,LIME);wheel.rotation_degrees.x=90
        var dot:=cylinder(Vector3(6.88+float(i)*.5,1.38,-3.11),.075,.03,INK);dot.rotation_degrees.x=90
    var model:Node3D=load("res://assets/ability_draw/source/tripo_convert_36d4f0c3-b64c-4ea1-841e-104fd70e96ae.glb").instantiate()
    model.name="PreservedTripoDealer";add_child(model);model.position=Vector3(5.4,0,-3.9);model.scale=Vector3.ONE*2.0
    _style_asset(model,false)
    for x in [6.5,8.3]:
        box(Vector3(x,3.6,-5.15),Vector3(1.3,.75,.6),PAPER)
        var fan:=Node3D.new();add_child(fan);fan.position=Vector3(x,3.6,-4.8);fans.append(fan)
        cylinder(Vector3.ZERO,.25,.06,INK,fan).rotation_degrees.x=90
        for a in 3:
            var blade:=box(Vector3.ZERO,Vector3(.08,.47,.03),GREY,fan);blade.rotation.z=float(a)*TAU/3
    for i in 7:
        var x:=4.6+float(i)*.75
        bar(Vector3(x,.1,-5.1),Vector3(x+.55,2.7,-5.1),.035,GREY)
        bar(Vector3(x,2.7,-5.1),Vector3(x+.55,.1,-5.1),.035,GREY)
    blocker(Rect2(4.8,-5.2,4.4,2.7))

func _lift() -> void:
    gate=Node3D.new();gate.name="DepartureLift";gate.position=Vector3(8.25,0,3.25);add_child(gate)
    for x in [-1.35,1.35]:box(Vector3(x,1.65,0),Vector3(.3,3.3,1.6),PAPER,gate)
    box(Vector3(0,3.25,0),Vector3(3,.35,1.6),PAPER,gate)
    box(Vector3(0,1.5,-.1),Vector3(2.4,3,.18),INK,gate)
    for x in [-.62,.62]:lift_slats.append(box(Vector3(x,1.5,.36),Vector3(1.18,2.85,.08),PINK,gate))
    box(Vector3(1.57,1.5,.68),Vector3(.28,.9,.12),INK,gate)
    for y in [1.3,1.6,1.9]:cylinder(Vector3(1.57,y,.76),.07,.035,LIME,gate).rotation_degrees.x=90
    var arrow:=polygon(PackedVector2Array([Vector2(-.35,.7),Vector2(.35,.7),Vector2(.35,-.2),Vector2(.7,-.2),Vector2(0,-.85),Vector2(-.7,-.2),Vector2(-.35,-.2)]),Vector3(6,.07,3.6),CYAN)
    arrow.rotation.y=-PI*.5
    blocker(Rect2(6.85,2.3,2.7,2.1))

func _details() -> void:
    var sign:=Label3D.new();sign.name="NightshiftDoorPlate";sign.text="夜班";sign.font=load("res://assets/fonts/RadioChinese.tres");sign.font_size=72;sign.pixel_size=.009;sign.modulate=PAPER;sign.outline_size=0
    add_child(sign);sign.position=Vector3(8.8,2.7,-5.1)
    for z in [-.6,.0,.6]:box(Vector3(9.4,.045,z),Vector3(.15,.025,.38),INK)
    # A lone plastic stool and takeaway cup: Hong Kong is a small material detail.
    box(Vector3(-5,.45,4.5),Vector3(.7,.1,.7),PINK)
    for x in [-5.25,-4.75]:
        for z in [4.25,4.75]:box(Vector3(x,.22,z),Vector3(.10,.45,.10),PINK)
    blocker(Rect2(-5.7,3.85,1.4,1.3))
    box(Vector3(-3.8,.7,5.1),Vector3(1.5,.12,.8),PAPER)
    for x in [-4.4,-3.2]:box(Vector3(x,.35,5.1),Vector3(.08,.7,.55),INK)
    cylinder(Vector3(-3.8,.87,5.1),.12,.25,PAPER)
    bar(Vector3(-3.8,1.0,5.1),Vector3(-3.75,1.3,5.1),.025,INK)
    blocker(Rect2(-4.7,4.5,1.9,1.3))
    # Six physical chapter trophies; only actual saved district clears illuminate them.
    for i in 6:
        box(Vector3(1.35+float(i)*.52,3.14,-5.24),Vector3(.44,.42,.05),GREY)
        trophies.append(box(Vector3(1.35+float(i)*.52,3.14,-5.18),Vector3(.30,.28,.035),INK))
    # Sparse wall graphics, authored polygons instead of baked text.
    var bolt:=polygon(PackedVector2Array([Vector2(-.8,-.6),Vector2(.0,-.3),Vector2(-.1,-.9),Vector2(1,.0),Vector2(.2,-.1),Vector2(.3,.6)]),Vector3(-8.2,3.7,-5.3),CYAN)
    bolt.rotation_degrees.x=90

func height_at(at:Vector3) -> float:
    var point:=Vector2(at.x,at.z)
    if STAIRS.has_point(point):return clampf((5-at.z)*.525,0,2.1)
    if LOFT.has_point(point):return 2.1
    return 0.0

func walkable(at:Vector3) -> bool:
    if not BOUNDS.has_point(Vector2(at.x,at.z)):return false
    var y:=height_at(at)
    if STAIRS.has_point(Vector2(at.x,at.z)) and (at.x< -8.85 or at.x> -7.7):return false
    for obstacle in obstacles:
        if y>=float(obstacle.low)-.01 and y<float(obstacle.high)-.01 and (obstacle.rect as Rect2).grow(.22).has_point(Vector2(at.x,at.z)):return false
    # Loft railing has one physical access: the stair mouth. No walking off the edge.
    return true

func move_actor(from:Vector3,direction:Vector3,delta:float) -> Vector3:
    var at:=from
    for axis in [0,2]:
        var next:=at;next[axis]+=direction[axis]*delta
        if walkable(next) and absf(height_at(next)-at.y)<.35:
            next.y=height_at(next);at=next
    return at

func _navigation() -> void:
    var index:=0
    for x in range(-18,19):
        for z in range(-10,13):
            var at:=Vector3(float(x)*.5,0,float(z)*.5);at.y=height_at(at)
            if not walkable(at):continue
            cells[Vector2i(x,z)]=index;graph.add_point(index,at);index+=1
    for cell:Vector2i in cells:
        for offset in [Vector2i(1,0),Vector2i(0,1)]:
            if not cells.has(cell+offset):continue
            var a:int=cells[cell];var b:int=cells[cell+offset]
            if absf(graph.get_point_position(a).y-graph.get_point_position(b).y)<.35:graph.connect_points(a,b)

func route(from:Vector3,to:Vector3) -> PackedVector3Array:
    return graph.get_point_path(graph.get_closest_point(from),graph.get_closest_point(to))

func accent_station(index:int) -> void:
    for i in station_marks.size():station_marks[i].scale=Vector3.ONE*(1.08 if i==index else .88)

func trigger(index:int) -> void:
    action_station=index;action_age=0.0

func advance(delta:float,reduced:bool) -> void:
    pulse_time+=delta;action_age+=delta
    if not reduced:
        for disc in turntables:disc.rotation.y+=delta*1.6
        for fan in fans:fan.rotation.z+=delta*1.8
    for i in sparks.size():
        sparks[i].visible=not reduced and action_station==0 and action_age<.7
        sparks[i].position=Vector3(-2.4+sin(float(i)*2.1+action_age*9)*action_age,1.1+fmod(action_age*4+float(i)*.13,.65),-4.2+cos(float(i)*1.7)*action_age)
    for i in lift_slats.size():
        var open:=maxf(0,1-action_age) if action_station==4 else 0.0
        lift_slats[i].position.x=(-1 if i==0 else 1)*(.62+open*.42)

func _style_asset(model:Node3D,cabinet:bool) -> void:
    # Instance-only duotone wrapper: original GLB and embedded albedo remain untouched.
    for node:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
        for surface in node.mesh.get_surface_count():
            var original:Material=node.get_active_material(surface)
            if original is BaseMaterial3D and original.albedo_texture!=null:
                var mat:=ShaderMaterial.new();mat.shader=preload("res://scripts/combat/city/nightshift/asset.gdshader")
                mat.set_shader_parameter("base_texture",original.albedo_texture);mat.set_shader_parameter("cabinet_cutout",cabinet)
                node.set_surface_override_material(surface,mat)

func progress(best:int) -> void:
    for i in trophies.size():trophies[i].material_override=material([CYAN,ORANGE,LIME,PINK,CYAN,PAPER][i] if best>=(i+1)*3 else INK)
