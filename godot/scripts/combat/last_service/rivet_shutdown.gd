extends RefCounted
## Reference 04: compressed load, chambered gauntlet, one straight power stroke.
static func owns(f:Dictionary) -> bool:
    return f.get("character",-1)==1 and f.get("state","")=="attack" and f.get("move","")=="overdrive" and f.get("health",0)>0 and not f.get("showcase",false) and not f.has("cinematic_clip")
static func phase(f:Dictionary,move:Dictionary) -> float:
    var frame:float=f.frame
    if frame<move.startup-8:return lerpf(.02,.12,smoothstep(0.0,12.0,frame))
    if frame<move.startup:return lerpf(.12,.30,smoothstep(float(move.startup)-8.0,float(move.startup),frame))
    return lerpf(.30,1.0,smoothstep(float(move.startup)+12.0,float(move.startup+move.active+move.recovery),frame))
static func finish(m:RefCounted,f:Dictionary,move:Dictionary) -> void:
    var frame:float=f.frame
    var load:float=smoothstep(0.0,10.0,frame)
    var strike:float=smoothstep(float(move.startup)-7.0,float(move.startup),frame)
    var return_pose:float=smoothstep(float(move.startup)+12.0,float(move.startup+move.active+move.recovery),frame)
    var weight:float=load*(1.0-return_pose)
    var up:Vector3=m.model_up
    var forward:Vector3=m.model_forward
    m.turn_hips(lerpf(-.40,.48,strike)*weight)
    m._aim_limb("Spine","Spine1",up+forward*lerpf(.25,.85,strike),weight*.85)
    m._aim_limb("RightArm","RightForeArm",(-forward*.65+up*.15).lerp(forward+up*.05,strike),weight*.98)
    m._aim_limb("RightForeArm","RightHand",(up+forward*.30).lerp(forward,strike),weight*.99)
    m._aim_limb("LeftArm","LeftForeArm",forward*.35-up*.25,weight*.85)
    m._aim_limb("LeftForeArm","LeftHand",up*.65-forward*.15,weight*.80)
