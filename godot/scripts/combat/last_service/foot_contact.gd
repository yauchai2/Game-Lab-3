extends RefCounted
## Bounded two-bone ground-plane IK. Presentation only; no simulation writes.
var anchors:Dictionary={}
var clearance:Dictionary={}
var previous_position:=Vector3.INF
var last_character:=-1
var last_state:=""
var corrections:=0
var max_error:=0.0
func clear() -> void:
    anchors.clear();previous_position=Vector3.INF;last_state="";max_error=0.0;corrections=0
func apply(actor:Node3D,f:Dictionary,stopped:bool) -> void:
    if not is_instance_valid(actor.skeleton):return
    var m:RefCounted=actor.motions
    var sk:Skeleton3D=actor.skeleton
    if last_character!=actor.character_index:
        clear();clearance.clear();last_character=actor.character_index
        for side in ["Left","Right"]:
            var foot:int=m.bone_index(side+"Foot")
            if foot>=0:
                var rest:Vector3=sk.global_transform*sk.get_bone_global_rest(foot).origin
                clearance[side]=clampf(rest.y-actor.global_position.y,.025,.22)
    var grounded:bool=f.health>0 and f.y<=.01 and f.state in ["idle","attack","blockstun","landing"] and f.get("ricochet",{}).get("ticks",0)<=0 and not f.has("ko_spin") and f.get("ko_theatre",-1.0)<0
    if not grounded:
        clear();return
    if previous_position.is_finite() and actor.global_position.distance_to(previous_position)>.45:anchors.clear()
    previous_position=actor.global_position
    if f.state!=last_state:anchors.clear();last_state=f.state
    sk.force_update_all_bone_transforms()
    var lowest:=INF
    for side in clearance:
        var foot:int=m.bone_index(side+"Foot")
        lowest=minf(lowest,(sk.global_transform*sk.get_bone_global_pose(foot).origin).y-clearance[side])
    # Imported standing bob can leave both feet above the ground. A bounded
    # pelvis offset makes the supporting ankle reachable before solving legs.
    var pelvis_drop:float=clampf(actor.global_position.y-lowest,-.14,.14)
    if absf(pelvis_drop)>.001:
        var hips:int=m.bone_index("Hips")
        var world_offset:=Vector3(0,pelvis_drop,0)
        var local_offset:Vector3=sk.global_basis.inverse()*world_offset
        var parent:int=sk.get_bone_parent(hips)
        if parent>=0:local_offset=sk.get_bone_global_pose(parent).basis.inverse()*local_offset
        sk.set_bone_pose_position(hips,sk.get_bone_pose_position(hips)+local_offset)
        sk.force_update_all_bone_transforms()
        lowest+=pelvis_drop
    var moving:bool=absf(f.vx)>.3
    var limb:String=preload("res://scripts/combat/last_service/street_motion.gd").striking_limb(f)
    for side in clearance:
        var foot:int=m.bone_index(side+"Foot")
        var at:Vector3=sk.global_transform*sk.get_bone_global_pose(foot).origin
        var support:bool=not (f.state=="attack" and limb==side+"Foot") and at.y-clearance[side]<=lowest+.055
        if not support:anchors.erase(side);continue
        var target:=Vector3(at.x,actor.global_position.y+clearance[side],at.z)
        if moving:anchors.erase(side)
        elif not anchors.has(side):anchors[side]=target
        elif not stopped and at.distance_to(anchors[side])>.24:anchors[side]=target
        if anchors.has(side):target=anchors[side]
        # A source pose outside this small reach must be fixed in animation,
        # rather than dragging the leg or changing the fighter's root/physics.
        var offset:Vector3=target-at
        if offset.length()>.22:target=at+offset.normalized()*.22
        _solve(m,sk,side,target)
        var error:float=(sk.global_transform*sk.get_bone_global_pose(foot).origin).distance_to(target)
        max_error=maxf(max_error,error);corrections+=1
func _solve(m:RefCounted,sk:Skeleton3D,side:String,world_target:Vector3) -> void:
    var hip:int=m.bone_index(side+"UpLeg");var knee:int=m.bone_index(side+"Leg");var ankle:int=m.bone_index(side+"Foot")
    if hip<0 or knee<0 or ankle<0:return
    var a:Vector3=sk.get_bone_global_pose(hip).origin
    var b:Vector3=sk.get_bone_global_pose(knee).origin
    var c:Vector3=sk.get_bone_global_pose(ankle).origin
    var target:Vector3=sk.global_transform.affine_inverse()*world_target
    var upper:float=a.distance_to(b);var lower:float=b.distance_to(c)
    if minf(upper,lower)<.001:return
    var reach:Vector3=target-a
    var distance:float=clampf(reach.length(),absf(upper-lower)+.001,upper+lower-.001)
    var axis:Vector3=reach.normalized()
    var bend:Vector3=(b-a)-axis*(b-a).dot(axis)
    if bend.length()<.001:bend=m.model_forward-axis*m.model_forward.dot(axis)
    if bend.length()<.001:return
    var along:float=(upper*upper-lower*lower+distance*distance)/(2.0*distance)
    var height:float=sqrt(maxf(0,upper*upper-along*along))
    var desired_knee:Vector3=a+axis*along+bend.normalized()*height
    m._aim_limb(side+"UpLeg",side+"Leg",desired_knee-a,1.0)
    var knee_at:Vector3=sk.get_bone_global_pose(knee).origin
    m._aim_limb(side+"Leg",side+"Foot",target-knee_at,1.0)
