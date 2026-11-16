extends Node3D
## Four-foot companion follows the handler visually, outside the combat simulation.
const MODEL=preload("res://assets/characters/deadshift/snap.glb")
const LEGS=[
    ["tripo__Spine_4","bone_12"], ["bone_17","bone_18"],
    ["bone_23","bone_24"], ["tripo__0_Left_Limb_1","tripo__0_Left_Limb_2"],
]
var skeleton:Skeleton3D
var bones:Dictionary={}
var phase:=0.0

func setup() -> void:
    top_level=true
    var mesh:Node3D=MODEL.instantiate()
    add_child(mesh)
    mesh.scale=Vector3.ONE*1.2
    skeleton=mesh.find_children("*","Skeleton3D",true,false)[0]
    for pair in LEGS:
        for label in pair:_bind(label)
    _bind("tripo__Head_0")

func _bind(label:String) -> void:
    var index:=skeleton.find_bone(label)
    if index<0:return
    var rest:=skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
    var axis:=skeleton.get_bone_global_rest(index).basis.inverse()*Vector3.RIGHT
    bones[label]={"index":index,"rest":rest,"axis":axis.normalized()}

func _turn(label:String,angle:float) -> void:
    if not bones.has(label):return
    var joint:Dictionary=bones[label]
    skeleton.set_bone_pose_rotation(joint.index,joint.rest*Quaternion(joint.axis,angle))

func present(f:Dictionary,delta:float,stopped:bool) -> void:
    visible=f.health>0
    global_position=Vector3(f.x-f.face*.72,0.0,3.65)
    global_rotation=Vector3(0,PI*.5*float(f.face),0)
    var pace:=clampf(absf(float(f.vx))/4.0,0,1)
    if not stopped:phase=fposmod(phase+delta*lerpf(2.6,16.0,pace),TAU)
    for i in LEGS.size():
        var stride:=sin(phase+(PI if i in [1,2] else 0.0))*pace
        _turn(LEGS[i][0],stride*.40)
        _turn(LEGS[i][1],maxf(0.0,stride)*.35)
    _turn("tripo__Head_0",sin(phase)*.055)
