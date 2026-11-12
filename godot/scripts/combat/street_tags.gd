extends RefCounted
## G1: text-free street tags earned in standard fights, saved locally, shown on the street asphalt.
## Presentation/save only. Demo, training, Street Run and fixtures never unlock tags.
const IDS:=["zip","rivet","hush","loop","mirror","streak","dusk","clean"]
const TITLES:={
    "zip":["ZIP 的路線標記","ZIP ROUTE MARK"],"rivet":["RIVET 的鉚釘標記","RIVET STUD MARK"],"hush":["HUSH 的留白標記","HUSH QUIET MARK"],"loop":["LOOP 的線圈標記","LOOP COIL MARK"],
    "mirror":["鏡像戰紀念","MIRROR MATCH"],"streak":["同一人連勝五場","FIVE IN A ROW"],"dusk":["黃昏以外的勝利","WIN AFTER DAYLIGHT"],"clean":["一回合未失","FLAWLESS MATCH"],
}
const COLORS:={"zip":Color("19d3c5"),"rivet":Color("ff8a2a"),"hush":Color("f5f5f5"),"loop":Color("a6ff3d"),"mirror":Color("ff2b8f"),"streak":Color("ffd23a"),"dusk":Color("8f7bff"),"clean":Color("ff4b4b")}
## Sprayed boards standing at the kerb beside the fight lane (board centre height). Slots are [x, y, z].
const SLOTS:=[[-4.6,0.95,-5.0],[4.6,0.95,-6.5],[-4.7,0.95,-9.0],[4.7,0.95,-10.5],[-4.7,0.95,-13.0],[4.7,0.95,-14.5],[-4.6,0.95,-17.0],[4.6,0.95,-18.5]]
var path:=""
var unlocked:Dictionary={}
func _init(p:="") -> void:
    path=p;load_data()
func load_data() -> void:
    unlocked={}
    if path.is_empty():return
    var f:=ConfigFile.new()
    if f.load(path)!=OK or int(f.get_value("tags","version",0))!=1:return
    var list:Variant=f.get_value("tags","unlocked",[])
    if typeof(list)!=TYPE_ARRAY:return
    for id in list:
        if typeof(id)==TYPE_STRING and id in IDS:unlocked[id]=true
func count() -> int:return unlocked.size()
func has(id:String) -> bool:return unlocked.has(id)
func unlock(id:String) -> bool:
    if id not in IDS or unlocked.has(id):return false
    unlocked[id]=true;save();return true
func save() -> void:
    if path.is_empty():return
    var f:=ConfigFile.new();f.set_value("tags","version",1);f.set_value("tags","unlocked",unlocked.keys())
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
    f.save(path)
## Standard-match result -> newly unlocked tag ids. Pure function of the facts.
func evaluate(player_char:int,rival_char:int,player_won:bool,streak:int,time_of_day:int,rounds_lost:int) -> Array:
    var earned:Array=[]
    if player_won:
        earned.append(IDS[clampi(player_char,0,3)])
        if streak>=5:earned.append("streak")
        if time_of_day!=0:earned.append("dusk")
        if rounds_lost==0:earned.append("clean")
    if player_char==rival_char:earned.append("mirror")
    var fresh:Array=[]
    for id in earned:
        if unlock(id):fresh.append(id)
    return fresh
static func title(id:String,english:bool) -> String:return TITLES[id][1 if english else 0]
## Builds one flat, text-free mark per id as a Node3D child; slot index follows IDS order.
static func build_marks(parent:Node3D) -> Dictionary:
    var nodes:Dictionary={}
    for i in IDS.size():
        var id:String=IDS[i];var slot:Array=SLOTS[i]
        var root:=Node3D.new();root.name="Tag_"+id;root.position=Vector3(slot[0],slot[1],slot[2])
        root.rotation.y=.35 if slot[0]<0 else -.35;root.scale=Vector3.ONE*(0.8+maxf(0.0,-slot[2])*.03)
        root.visible=false;parent.add_child(root)
        var mat:=StandardMaterial3D.new();mat.albedo_color=COLORS[id];mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
        var back:=StandardMaterial3D.new();back.albedo_color=Color("14141c");back.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
        var board:=BoxMesh.new();board.size=Vector3(1.5,1.1,.06)
        var bn:=MeshInstance3D.new();bn.mesh=board;bn.material_override=back;bn.position=Vector3(0,0,-.04);bn.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(bn)
        for px in [-.55,.55]:
            var post:=BoxMesh.new();post.size=Vector3(.06,.5,.06)
            var pn:=MeshInstance3D.new();pn.mesh=post;pn.material_override=back;pn.position=Vector3(px,-.8,-.04);pn.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(pn)
        match id:
            "zip":_add(root,_quad(.9,.12),Vector3(0,0,0),-.5,mat);_add(root,_quad(.5,.12),Vector3(.3,.22,0),.5,mat)  # zig-zag route
            "rivet":for k in 3:_add(root,_disc(.14),Vector3(-.4+k*.4,0,0),0.0,mat)
            "hush":_add(root,_quad(.8,.1),Vector3(0,0,0),0.0,mat);_add(root,_quad(.5,.1),Vector3(0,-.2,0),0.0,mat)
            "loop":_add(root,_ring(.32,.22),Vector3.ZERO,0.0,mat);_add(root,_ring(.2,.12),Vector3(.45,0,0),0.0,mat)
            "mirror":_add(root,_quad(.5,.7),Vector3(-.3,0,0),0.0,mat);_add(root,_quad(.5,.7),Vector3(.3,0,0),0.0,mat)
            "streak":for k in 5:_add(root,_quad(.12,.22+k*.08),Vector3(-.45+k*.22,0,0),0.0,mat)
            "dusk":_add(root,_disc(.38),Vector3.ZERO,0.0,mat);_add(root,_quad(1.0,.1),Vector3(0,-.5,0),0.0,mat)
            "clean":_add(root,_quad(.9,.12),Vector3(0,0,0),.8,mat);_add(root,_quad(.9,.12),Vector3(0,0,0),-.8,mat)
        nodes[id]=root
    return nodes
static func _quad(w:float,h:float) -> Mesh:
    var q:=QuadMesh.new();q.size=Vector2(w,h);return q
static func _disc(r:float) -> Mesh:
    var c:=CylinderMesh.new();c.top_radius=r;c.bottom_radius=r;c.height=.01;c.radial_segments=16;return c
static func _ring(outer:float,inner:float) -> Mesh:
    var t:=TorusMesh.new();t.outer_radius=outer;t.inner_radius=inner;return t
static func _add(root:Node3D,mesh:Mesh,at:Vector3,roll:float,mat:Material) -> void:
    var n:=MeshInstance3D.new();n.mesh=mesh;n.material_override=mat;n.position=at;n.rotation.z=roll;n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    if mesh is CylinderMesh:n.rotation.x=PI*.5
    if mesh is TorusMesh:n.rotation.x=PI*.5
    root.add_child(n)
