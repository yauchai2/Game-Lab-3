extends Node3D
## A transparent wire cage keeps the actual street visible. Four reusable impact grids.
const BOX=preload("res://scripts/combat/arena_box.gd")
var impacts:Array=[]
func _ready() -> void:
    name="RicochetArena"
    var edge:=8.65;var roof:=BOX.CEILING+2.4
    for z in [2.0,4.0]:
        line(Vector3(-edge,0,z),Vector3(edge,0,z),.015,Color("73b4c7"),.22)
        line(Vector3(-edge,roof,z),Vector3(edge,roof,z),.015,Color("d794bf"),.22)
        for x in [-edge,edge]:line(Vector3(x,0,z),Vector3(x,roof,z),.015,Color("b29ac5"),.25)
    for x in [-edge,edge]:
        for y in [0.0,roof]:line(Vector3(x,y,2),Vector3(x,y,4),.015,Color("b29ac5"),.22)
    for i in 4:
        var node:=MeshInstance3D.new();var mesh:=ImmediateMesh.new();node.mesh=mesh
        var mat:=material(Color("e8f6ff"),0);node.material_override=mat
        mesh.surface_begin(Mesh.PRIMITIVE_LINES)
        for axis in 2:
            for n in range(-3,4):
                var a:=Vector3(n*.24,-.72,0) if axis==0 else Vector3(-.72,n*.24,0)
                var b:=Vector3(n*.24,.72,0) if axis==0 else Vector3(.72,n*.24,0)
                mesh.surface_add_vertex(a);mesh.surface_add_vertex(b)
        mesh.surface_end();add_child(node);node.hide()
        impacts.append({"node":node,"mat":mat,"age":1.0})
func material(color:Color,alpha:float) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.albedo_color=Color(color,alpha)
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mat
func line(a:Vector3,b:Vector3,radius:float,color:Color,alpha:float) -> void:
    var node:=MeshInstance3D.new();var mesh:=CylinderMesh.new()
    mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=a.distance_to(b);mesh.radial_segments=4
    node.mesh=mesh;node.material_override=material(color,alpha);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(node);node.position=(a+b)*.5
    node.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
func react(event:Dictionary) -> void:
    var index:int=["left","right","ceiling","floor"].find(event.surface)
    var item:Dictionary=impacts[index];item.age=0.0
    item.node.position=Vector3(event.x,event.y,4.1)
    item.mat.albedo_color=Color("00e9ef") if index<2 else Color("ff87d0")
func advance(delta:float,paused:bool,reduced:bool) -> void:
    if paused:return
    for item in impacts:
        item.age+=delta;item.node.visible=item.age<.32 and not reduced
        item.node.scale=Vector3.ONE*(.75+item.age*3.2)
        var color:Color=item.mat.albedo_color;color.a=maxf(0,1-item.age/.32)*.75;item.mat.albedo_color=color
func clear() -> void:
    for item in impacts:item.age=1.0;item.node.hide()
