extends Node
## Lightweight provisional gait for the supplied skinned character; no authored clips are present.
## All rotations are layered onto the imported bone pose; the GLB remains untouched.
var skeleton: Skeleton3D
var base_rotations: Dictionary = {}
var bone_indices: Dictionary = {}
var local_axes: Dictionary = {}
var phase := 0.0
var motion_blend := 0.0
var elapsed := 0.0
@onready var character: CharacterBody3D = get_parent().get_parent()

func _ready() -> void:
    var model: Node = get_parent().get_node("CharacterModel")
    var skeletons := model.find_children("*","Skeleton3D",true,false)
    if skeletons.is_empty():
        push_warning("Character model has no Skeleton3D; rest pose will be used.")
        set_physics_process(false)
        return
    skeleton = skeletons[0]
    for part in ["LeftUpLeg","RightUpLeg","LeftLeg","RightLeg","LeftArm","RightArm","LeftForeArm","RightForeArm","Spine"]:
        var index := skeleton.find_bone("mixamorig_"+part)
        if index<0:index=skeleton.find_bone("mixamorig:"+part)
        if index < 0:
            continue
        bone_indices[part] = index
        base_rotations[part] = skeleton.get_bone_pose_rotation(index)
        # Convert a lateral axis in model space into each bone's own rest space.
        local_axes[part] = (skeleton.get_bone_global_rest(index).basis.inverse()*Vector3.RIGHT).normalized()

func _physics_process(delta: float) -> void:
    if not is_instance_valid(skeleton):
        return
    elapsed += delta
    var horizontal_speed := Vector2(character.velocity.x,character.velocity.z).length()
    var target_blend := clampf(horizontal_speed/4.0,0.0,1.0) if character.is_on_floor() else 0.0
    motion_blend = move_toward(motion_blend,target_blend,delta*5.0)
    phase += delta * (3.0 + minf(horizontal_speed,7.0)*1.35)
    var stride := sin(phase)*motion_blend
    var airborne := not character.is_on_floor()
    _pose("LeftUpLeg",-.36*stride + (.12 if airborne else 0.0))
    _pose("RightUpLeg",.36*stride + (.12 if airborne else 0.0))
    _pose("LeftLeg",.32*maxf(0.0,stride) + (.30 if airborne else 0.0))
    _pose("RightLeg",.32*maxf(0.0,-stride) + (.30 if airborne else 0.0))
    _pose("LeftArm",.25*stride + (-.18 if airborne else 0.0))
    _pose("RightArm",-.25*stride + (-.18 if airborne else 0.0))
    _pose("LeftForeArm",.08*motion_blend)
    _pose("RightForeArm",.08*motion_blend)
    _pose("Spine",.025*sin(elapsed*2.2) + .06*motion_blend)

func _pose(name: String, angle: float) -> void:
    if not base_rotations.has(name):
        return
    var index: int = bone_indices[name]
    skeleton.set_bone_pose_rotation(index,base_rotations[name]*Quaternion(local_axes[name],angle))
