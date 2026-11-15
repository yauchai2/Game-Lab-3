extends RefCounted
## Retained boxing timing and source-stance mask used by street_motion.gd.
const ATTACKS={
    "jab":{"clip":"Punch_Jab","contact":.30,"release":.40},
    "cross":{"clip":"Punch_Cross","contact":.30,"release":.40},
    "heavy":{"clip":"Punch_Cross","contact":.30,"release":.40},
    "finisher":{"clip":"Punch_Cross","contact":.30,"release":.40},
    "special":{"clip":"Punch_Cross","contact":.30,"release":.40}}
static func sample(f:Dictionary,duration:float,move:Dictionary={}) -> float:
    if f.state!="attack":return duration
    var entry:Dictionary=ATTACKS[f.move]
    var frame:float=f.frame
    if frame<float(move.startup):
        if f.move=="special":
            # The simulation repeats frames 7/8 while holding. Both map to one
            # load pose; release then advances toward the real contact tick.
            var load:float=.12+.015*float(f.get("service",{}).get("preload",0))
            if frame<=8:return duration*load*smoothstep(0.0,7.0,frame)
            return duration*lerpf(load,entry.contact,smoothstep(8.0,float(move.startup),frame))
        return duration*float(entry.contact)*smoothstep(0.0,float(move.startup),frame)
    if frame<float(move.startup+move.active):
        return duration*lerpf(entry.contact,entry.release,(frame-move.startup)/float(move.active))
    return duration*lerpf(entry.release,1.0,clampf((frame-move.startup-move.active)/float(move.recovery),0.0,1.0))
static func planted_source(name:String) -> bool:
    # Freeze source pelvis and legs in the authored boxing stance. This is a
    # bounded planted clip mask, not terrain-aware foot IK or a walking solver.
    return name=="DEF-hips" or name.begins_with("DEF-thigh") or name.begins_with("DEF-shin") or name.begins_with("DEF-foot") or name.begins_with("DEF-toe")

static func owns(f:Dictionary) -> bool:
    return f.get("character",-1)==1 and f.get("state","")=="attack" and f.get("move","")=="special" and f.get("health",0)>0 and not f.get("showcase",false) and not f.has("cinematic_clip")

static func finish(m:RefCounted,f:Dictionary,move:Dictionary) -> void:
    # Raised gauntlets -> overhead windup -> one downward ground drive.
    # Frames 7/8 share one pose; tier strength comes from real preload age.
    var frame:float=f.frame
    var load:float=smoothstep(0.0,7.0,frame)
    var lift:float=smoothstep(8.0,float(move.startup)-5.0,frame)
    var strike:float=smoothstep(float(move.startup)-5.0,float(move.startup),frame)
    var recover:float=smoothstep(float(move.startup)+8.0,float(move.startup+move.active+move.recovery),frame)
    var weight:float=load*(1.0-recover)
    var up:Vector3=m.model_up
    var forward:Vector3=m.model_forward
    m.turn_hips(lerpf(-.24,.32,strike)*weight)
    var crouch:float=strike*weight
    for side in ["Left","Right"]:
        m._aim_limb(side+"UpLeg",side+"Leg",forward*.65-up,crouch*.65)
        m._aim_limb(side+"Leg",side+"Foot",-forward*.45-up,crouch*.65)
    var sk:Skeleton3D=m.skeleton
    var hips:int=m.target_hips
    var offset:Vector3=sk.global_basis.inverse()*Vector3(0,-.32*crouch,0)
    var parent:int=sk.get_bone_parent(hips)
    if parent>=0:offset=sk.get_bone_global_pose(parent).basis.inverse()*offset
    sk.set_bone_pose_position(hips,sk.get_bone_pose_position(hips)+offset)
    sk.force_update_all_bone_transforms()
    m._aim_limb("Spine","Spine1",up+forward*lerpf(-.12,2.4,strike),weight*.88)
    m._aim_limb("Spine1","Spine2",up+forward*.35*strike,weight*.65)
    var upper:Vector3=forward*lerpf(.35,.70,strike)+up*lerpf(.48,1.2,lift)
    upper=upper.lerp(forward*.35-up,strike)
    var lower:Vector3=(up+forward*.12).lerp(forward*.30-up,strike)
    m._aim_limb("RightArm","RightForeArm",upper,weight*.98)
    m._aim_limb("RightForeArm","RightHand",lower,weight*.98)
    m._aim_limb("LeftArm","LeftForeArm",forward*.30+up*.45,weight*.80)
    m._aim_limb("LeftForeArm","LeftHand",up-forward*.15,weight*.90)
