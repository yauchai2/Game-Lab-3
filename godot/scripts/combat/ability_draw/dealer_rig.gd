extends Node3D
## Authored choreography on the supplied 65-bone Tripo rig. Stateless timeline,
## reused CC0 gait plus two-bone world-space contacts; no combat fighter changes.
const SOURCE=preload("res://assets/ability_draw/source/tripo_convert_36d4f0c3-b64c-4ea1-841e-104fd70e96ae.glb")
const Materials=preload("res://scripts/combat/ability_draw/asset_materials.gd")
var model:Node3D
var skeleton:Skeleton3D
var motions=preload("res://scripts/combat/combat_motions.gd").new()
var hand_frames:Dictionary={}
var contact_error:=0.0
var contact_target:=Vector3.ZERO
var pose_label:="idle"
var token_transform:=Transform3D.IDENTITY
var model_height:=3.05

func setup() -> void:
    name="UploadedDealerRig"
    model=SOURCE.instantiate();model.name="OriginalTripoDealer";add_child(model)
    model.scale=Vector3.ONE*model_height
    skeleton=model.find_children("*","Skeleton3D",true,false)[0]
    Materials.style(model);motions.setup(skeleton,model)
    for side in ["Left","Right"]:
        var hand:=bone(side+"Hand")
        var origin:=skeleton.get_bone_global_rest(hand).origin
        var f:Vector3=(skeleton.get_bone_global_rest(bone(side+"HandMiddle1")).origin-origin).normalized()
        var across:Vector3=(skeleton.get_bone_global_rest(bone(side+"HandIndex1")).origin-skeleton.get_bone_global_rest(bone(side+"HandPinky1")).origin).normalized()
        var normal:=across.cross(f).normalized()
        if normal.dot(Vector3.BACK)<0:normal=-normal
        var frame:=frame_from(f,normal)
        hand_frames[side]=skeleton.get_bone_global_rest(hand).basis.orthonormalized().inverse()*frame

func bone(id:String) -> int:return motions.bone_index(id)
func point(id:String) -> Vector3:
    return skeleton.to_global(skeleton.get_bone_global_pose(bone(id)).origin)

func frame_from(forward:Vector3,normal:Vector3) -> Basis:
    var z:=forward.normalized();var y:=normal.slide(z).normalized()
    return Basis(y.cross(z).normalized(),y,z).orthonormalized()

func rotate_global(index:int,desired:Basis) -> void:
    var parent:=skeleton.get_bone_parent(index)
    var parent_basis:=Basis.IDENTITY if parent<0 else skeleton.get_bone_global_pose(parent).basis.orthonormalized()
    skeleton.set_bone_pose_rotation(index,(parent_basis.inverse()*desired).orthonormalized().get_rotation_quaternion())
    skeleton.force_update_all_bone_transforms()

func aim(index:int,child:int,direction:Vector3) -> void:
    var pose:=skeleton.get_bone_global_pose(index)
    var current:Vector3=skeleton.get_bone_global_pose(child).origin-pose.origin
    if current.length()<.0001 or direction.length()<.0001:return
    var correction:=Quaternion(current.normalized(),direction.normalized())
    rotate_global(index,Basis(correction)*pose.basis.orthonormalized())

func solve_arm(side:String,target_world:Vector3,pole_world:Vector3) -> void:
    var a:=bone(side+"Arm");var b:=bone(side+"ForeArm");var c:=bone(side+"Hand")
    var upper:=skeleton.get_bone_global_pose(a).origin
    var elbow:=skeleton.get_bone_global_pose(b).origin
    var wrist:=skeleton.get_bone_global_pose(c).origin
    var target:=skeleton.to_local(target_world)
    var l1:=upper.distance_to(elbow);var l2:=elbow.distance_to(wrist)
    var raw:=target-upper
    var distance:=clampf(raw.length(),absf(l1-l2)+.001,l1+l2-.001)
    var axis:=raw.normalized()
    var pole:Vector3=(skeleton.to_local(pole_world)-upper).slide(axis).normalized()
    if pole.length()<.1:pole=Vector3.UP.cross(axis).normalized()
    var cosine:=clampf((l1*l1+distance*distance-l2*l2)/(2*l1*distance),-1,1)
    var desired_elbow:=upper+axis*l1*cosine+pole*l1*sqrt(maxf(0,1-cosine*cosine))
    aim(a,b,desired_elbow-upper)
    elbow=skeleton.get_bone_global_pose(b).origin
    aim(b,c,target-elbow)

func orient_hand(side:String,fingers:Vector3,palm:Vector3,curl:float) -> void:
    var world_frame:=frame_from(fingers,palm)
    var desired:Basis=skeleton.global_basis.orthonormalized().inverse()*world_frame*hand_frames[side].inverse()
    rotate_global(bone(side+"Hand"),desired)
    var axis:Vector3=(skeleton.global_basis.inverse()*fingers.cross(palm)).normalized()
    for finger in ["Index","Middle","Ring","Pinky","Thumb"]:
        for digit in range(1,4):
            var index:=bone(side+"Hand"+finger+str(digit))
            var global_basis:=skeleton.get_bone_global_pose(index).basis.orthonormalized()
            rotate_global(index,Basis(Quaternion(axis,curl*(.32 if finger=="Thumb" else .63)))*global_basis)

func sample(t:float,travel:float,rolling:float,reveal:float,chassis:Node3D,travel_direction:=1.0) -> void:
    var turn:=1-smoothstep(.91,1.24,t)
    model.rotation.y=travel_direction*PI*.5*turn
    var walking:=rolling>.03 and t<1.10
    var selected:="Walk_Loop" if walking else "Idle_Loop"
    motions.blend_from.clear();motions.previous_state=selected+"/idle"
    motions.clip_elapsed=absf(travel)*.42 if walking else 0.0
    motions.present({"character":2,"health":100,"state":"idle","move":"","frame":0,"y":0.0,"vy":0.0,"vx":2.8 if walking else 0.0,"face":1,"guarding":false,"showcase":not walking},0.0,true)
    motions._aim_limb("Spine","Spine1",Vector3.UP+Vector3.BACK*(rolling*.18-reveal*.12),1.0)
    var left_target:=chassis.to_global(Vector3(-1.06,1.80,-.56))
    var right_target:=chassis.to_global(Vector3(-1.06,1.60,-.56))
    var up:=chassis.global_basis.y.normalized()
    var front:=chassis.global_basis.z.normalized()
    var fingers:Vector3=-up
    var palm:Vector3=chassis.global_basis.x.normalized()
    var curl:=.8
    contact_error=0;contact_target=left_target;pose_label="drag" if walking else "settle"
    if t>=1.16 and t<1.95:
        pose_label="slap"
        var lift:=maxf(0,1-absf(t-1.28)/.13)*.38
        left_target=chassis.to_global(Vector3(-.43,2.43+lift,-.18))
        fingers=chassis.global_basis.z;palm=-chassis.global_basis.y;curl=0
        right_target=to_global(Vector3(-.50,1.25,.10))
        contact_target=left_target
    elif t>=1.95:
        pose_label="offer" if t<2.55 else "spin"
        left_target=to_global(Vector3(.35,2.12,.76))
        right_target=to_global(Vector3(-.40,1.35,.12))
        fingers=up;palm=front;curl=.72 if t<2.55 else .35
        if reveal>0:
            pose_label="recoil"
            left_target=to_global(Vector3(.65,2.00,.50))
            right_target=to_global(Vector3(-.55,1.75,.50));curl=.2
    solve_arm("Left",left_target,to_global(Vector3(.7,1.7,-.1)))
    solve_arm("Right",right_target,to_global(Vector3(-.7,1.6,-.1)))
    orient_hand("Left",fingers,palm,curl)
    orient_hand("Right",-up,front,.45)
    if pose_label in ["drag","slap"]:contact_error=point("LeftHand").distance_to(contact_target)
    # The actual skinned wrist, rather than a detached surrogate hand, carries the token.
    var token_at:=point("LeftHand")+up*.15+front*.13
    token_transform=Transform3D(chassis.global_basis.orthonormalized(),token_at)
    var head:=bone("Head")
    var head_pose:=skeleton.get_bone_global_pose(head)
    rotate_global(head,head_pose.basis.orthonormalized()*Basis(Quaternion(Vector3.FORWARD,-.06)))
