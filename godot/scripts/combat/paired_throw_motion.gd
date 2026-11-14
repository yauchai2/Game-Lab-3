extends RefCounted
## Retarget absolute source poses, then solve the actual two-character wrist contact.
const Data=preload("res://scripts/combat/paired_throw_library.gd")
var calibration:Array[Quaternion]=[]
var calibration_role:=""
var source_indices:Array[int]=[]
var active_last:=false
var entry_rotations:Array[Quaternion]=[]
var entry_hip:=Vector3.ZERO
var last_pose:Dictionary={}
static func owns(f:Dictionary) -> bool:
    return f.has("paired_throw") and Data.available() and not f.has("ko_spin") and f.get("ko_theatre",-1.0)<0 and not f.has("cinematic_clip")
func present(visual:Node3D,f:Dictionary,delta:float,stopped:bool) -> void:
    var s:Skeleton3D=visual.skeleton
    var m:RefCounted=visual.motions
    var p:Dictionary=f.paired_throw
    var role:String=p.role
    var bones:Array=Data.data.actors[role].bones
    if calibration.is_empty() or calibration_role!=role:
        calibration.clear();source_indices.clear();calibration_role=role
        _calibrate(visual,bones)
    if not active_last or p.get("serial",0)!=last_pose.get("serial",-1):
        entry_rotations.clear()
        for i in s.get_bone_count():entry_rotations.append(s.get_bone_pose_rotation(i))
        entry_hip=s.get_bone_pose_position(m.target_hips)
    active_last=true;last_pose=p
    var recover:float=0.0 if f.health<=0 else float(p.recover)
    var recovery_rotations:Array[Quaternion]=[]
    var recovery_hip:=Vector3.ZERO
    if recover>0:
        var normal:Dictionary=f.duplicate(true)
        normal.erase("paired_throw");normal.state="idle";normal.move="";normal.vx=0.0;normal.vy=0.0
        normal["air_enabled"]=false;normal["motion_no_blend"]=true
        if role=="victim":
            normal["cinematic_clip"]="Roll";normal.state="dash";normal.frame=9.0+5.0*recover
        m.present(normal,delta,stopped)
        for i in s.get_bone_count():recovery_rotations.append(s.get_bone_pose_rotation(i))
        recovery_hip=s.get_bone_pose_position(m.target_hips)
        if role=="victim" and recover>.6:
            normal.erase("cinematic_clip");normal.state="idle";normal.frame=0
            m.present(normal,delta,stopped)
            var stand:float=smoothstep(.6,1,recover)
            for i in s.get_bone_count():recovery_rotations[i]=recovery_rotations[i].slerp(s.get_bone_pose_rotation(i),stand)
            recovery_hip=recovery_hip.lerp(s.get_bone_pose_position(m.target_hips),stand)
    var sample:Dictionary=Data.sample(role,p.source_frame)
    var convert:=Basis(Vector3(-float(p.face),0,0),Vector3(0,0,float(p.face)),Vector3.UP)
    var to_skeleton:Quaternion=(s.global_basis.inverse()*convert).get_rotation_quaternion()
    var desired:Array[Quaternion]=[]
    var entering:float=smoothstep(0,6,float(p.age))
    var recovering:float=smoothstep(0,.6 if role=="victim" else 1.0,recover)
    for i in s.get_bone_count():
        var parent:int=s.get_bone_parent(i)
        var parent_rotation:Quaternion=Quaternion.IDENTITY if parent<0 else desired[parent]
        var global_rotation:Quaternion
        var source:int=source_indices[i]
        if source>=0:
            var posed:Quaternion=Data.quat(sample.a.rotations[source]).slerp(Data.quat(sample.b.rotations[source]),sample.weight)
            global_rotation=to_skeleton*posed*Data.quat(bones[source].rotation).inverse()*calibration[i]
        else:global_rotation=parent_rotation*s.get_bone_rest(i).basis.get_rotation_quaternion()
        var local:Quaternion=(parent_rotation.inverse()*global_rotation).normalized()
        local=entry_rotations[i].slerp(local,entering)
        if recover>0:local=local.slerp(recovery_rotations[i],recovering)
        s.set_bone_pose_rotation(i,local)
        s.set_bone_pose_position(i,s.get_bone_rest(i).origin)
        desired.append(parent_rotation*local)
    var position:Vector3=s.get_bone_rest(m.target_hips).origin
    position.y=Data.hip(role,p.source_frame).z*1.15/visual.model_scale
    position=entry_hip.lerp(position,entering)
    if recover>0:position=position.lerp(recovery_hip,recovering)
    s.set_bone_pose_position(m.target_hips,position)
    s.force_update_all_bone_transforms()
    m.pose_owner="paired_throw_"+role;m.air_pose_name=m.pose_owner;m.clip_name="Mixamo_Shoulder_Throw"
    m.previous_state="paired_throw" # normal owner blends from the outgoing pose
func _calibrate(visual:Node3D,bones:Array) -> void:
    var s:Skeleton3D=visual.skeleton
    var names:Dictionary={}
    for i in bones.size():names[bones[i].name]=i
    var source_frame:Basis=_frame(Data.vector(bones[names.RightArm].position)-Data.vector(bones[names.LeftArm].position),Data.vector(bones[names.Head].position)-Data.vector(bones[names.Hips].position))
    var m:RefCounted=visual.motions
    var target_frame:Basis=_frame(s.get_bone_global_rest(m.bone_index("RightArm")).origin-s.get_bone_global_rest(m.bone_index("LeftArm")).origin,s.get_bone_global_rest(m.bone_index("Head")).origin-s.get_bone_global_rest(m.target_hips).origin)
    var target_to_source:Basis=source_frame*target_frame.inverse()
    for i in s.get_bone_count():
        var short_name:String=s.get_bone_name(i).trim_prefix("mixamorig_").trim_prefix("mixamorig:")
        source_indices.append(names.get(short_name,-1))
    for i in s.get_bone_count():
        var basis:Basis=target_to_source*s.get_bone_global_rest(i).basis
        var index:int=source_indices[i]
        if index>=0:
            for child in s.get_bone_children(i):
                var child_index:int=source_indices[child]
                if child_index<0:continue
                var target_direction:Vector3=target_to_source*(s.get_bone_global_rest(child).origin-s.get_bone_global_rest(i).origin)
                var source_direction:Vector3=Data.vector(bones[child_index].position)-Data.vector(bones[index].position)
                if minf(target_direction.length(),source_direction.length())>.0001:
                    basis=Basis(Quaternion(target_direction.normalized(),source_direction.normalized()))*basis
                break
        calibration.append(basis.get_rotation_quaternion())
static func _frame(right:Vector3,up:Vector3) -> Basis:
    var x:Vector3=right.normalized()
    var y:Vector3=(up-x*up.dot(x)).normalized()
    return Basis(x,y,x.cross(y).normalized())
static func correct_contacts(a:Node3D,b:Node3D) -> float:
    if not a.paired_motion.active_last or not b.paired_motion.active_last:return 0.0
    var p:Dictionary=a.paired_motion.last_pose
    if p.role!="aggressor":return correct_contacts(b,a)
    if p.source_frame>100 or p.age<6 or p.recover>0:return 0.0
    # Both actual arms participate; neither body is teleported to fake a grip.
    for iteration in 2:
        var left:Vector3=_world_bone(a,"LeftHand")
        var right:Vector3=_world_bone(b,"RightHand")
        var goal:Vector3=(left+right)*.5
        _arm_ik(a,"Left",goal)
        _arm_ik(b,"Right",goal)
    return _world_bone(a,"LeftHand").distance_to(_world_bone(b,"RightHand"))
static func _world_bone(v:Node3D,name:String) -> Vector3:
    return v.skeleton.global_transform*v.skeleton.get_bone_global_pose(v.motions.bone_index(name)).origin
static func _arm_ik(v:Node3D,side:String,world_goal:Vector3) -> void:
    var s:Skeleton3D=v.skeleton
    var upper:int=v.motions.bone_index(side+"Arm")
    var lower:int=v.motions.bone_index(side+"ForeArm")
    var hand:int=v.motions.bone_index(side+"Hand")
    var saved_hand:Quaternion=s.get_bone_global_pose(hand).basis.get_rotation_quaternion()
    var shoulder:int=v.motions.bone_index(side+"Shoulder")
    var desired_local:Vector3=s.global_transform.affine_inverse()*world_goal
    var reach:float=s.get_bone_global_pose(upper).origin.distance_to(s.get_bone_global_pose(lower).origin)+s.get_bone_global_pose(lower).origin.distance_to(s.get_bone_global_pose(hand).origin)
    if s.get_bone_global_pose(upper).origin.distance_to(desired_local)>reach-.01:
        _aim(s,shoulder,upper,desired_local-s.get_bone_global_pose(shoulder).origin)
    var gap:float=s.get_bone_global_pose(upper).origin.distance_to(desired_local)-reach+.002
    var shifted:Vector3=s.get_bone_pose_position(upper)-s.get_bone_rest(upper).origin
    var allowance:float=maxf(0,.035/v.model_scale-shifted.length())
    if gap>0 and allowance>0:
        # Bounded scapular protraction, not limb scaling or body teleportation.
        var shift:Vector3=(desired_local-s.get_bone_global_pose(upper).origin).normalized()*minf(gap,allowance)
        var parent_basis:Basis=s.get_bone_global_pose(shoulder).basis
        s.set_bone_pose_position(upper,s.get_bone_pose_position(upper)+parent_basis.inverse()*shift)
        s.force_update_all_bone_transforms()
    var a:Vector3=s.get_bone_global_pose(upper).origin
    var b:Vector3=s.get_bone_global_pose(lower).origin
    var c:Vector3=s.get_bone_global_pose(hand).origin
    var goal:Vector3=s.global_transform.affine_inverse()*world_goal
    var l1:float=a.distance_to(b)
    var l2:float=b.distance_to(c)
    var distance:float=clampf(a.distance_to(goal),absf(l1-l2)+.001,l1+l2-.001)
    var axis:Vector3=(goal-a).normalized()
    var bend:Vector3=(b-a)-axis*(b-a).dot(axis)
    if bend.length()<.001:bend=axis.cross(Vector3.FORWARD)
    if bend.length()<.001:bend=axis.cross(Vector3.UP)
    var along:float=(l1*l1-l2*l2+distance*distance)/(2*distance)
    var elbow:Vector3=a+axis*along+bend.normalized()*sqrt(maxf(0,l1*l1-along*along))
    _aim(s,upper,lower,elbow-a)
    _aim(s,lower,hand,goal-s.get_bone_global_pose(lower).origin)
    s.set_bone_pose_rotation(hand,(s.get_bone_global_pose(lower).basis.get_rotation_quaternion().inverse()*saved_hand).normalized())
    s.force_update_all_bone_transforms()
static func _aim(s:Skeleton3D,bone:int,child:int,direction:Vector3) -> void:
    var transform:Transform3D=s.get_bone_global_pose(bone)
    var current:Vector3=s.get_bone_global_pose(child).origin-transform.origin
    if minf(current.length(),direction.length())<.0001:return
    var global_rotation:Quaternion=Quaternion(current.normalized(),direction.normalized())*transform.basis.get_rotation_quaternion()
    var parent:int=s.get_bone_parent(bone)
    var parent_rotation:Quaternion=Quaternion.IDENTITY if parent<0 else s.get_bone_global_pose(parent).basis.get_rotation_quaternion()
    s.set_bone_pose_rotation(bone,(parent_rotation.inverse()*global_rotation).normalized())
    s.force_update_all_bone_transforms()
