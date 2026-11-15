extends RefCounted
## Express Receipt choreography, sampled from the user's 4.017s reference.
## Simulation owns contacts; this module only samples the two planted kicks.
const FOLLOWUP_DELAY := 16
static func owns(f:Dictionary) -> bool:
    return f.get("character",-1)==0 and f.get("state","")=="attack" and f.get("move","")=="special" and f.get("health",0)>0 and not f.get("showcase",false) and not f.has("cinematic_clip")
static func second_contact(f:Dictionary,move:Dictionary) -> float:
    var pending:float=f.get("service",{}).get("followup",0)
    var stored:float=f.get("service",{}).get("zip_second_at",0)
    return pending if pending>0 else (stored if stored>0 else float(move.startup+FOLLOWUP_DELAY))
static func second(f:Dictionary,move:Dictionary) -> bool:
    var r:Dictionary=f.get("service",{})
    return (r.get("zip_second",false) or r.get("followup",0)>0) and float(f.frame)>second_contact(f,move)-8.0
static func phase(f:Dictionary,move:Dictionary,contact:float) -> float:
    var frame:float=f.frame
    if second(f,move):
        var hit:float=second_contact(f,move)
        if frame<hit:return lerpf(.10,contact,smoothstep(hit-8.0,hit,frame))
        if frame<hit+4.0:return lerpf(contact,.56,(frame-hit)/4.0)
        return lerpf(.56,1.0,smoothstep(hit+4.0,float(move.startup+move.active+move.recovery),frame))
    if frame<float(move.startup):return lerpf(.03,contact,smoothstep(0,float(move.startup),frame))
    return lerpf(contact,1.0,smoothstep(float(move.startup),float(move.startup)+8.0,frame))
static func finish(m:RefCounted,f:Dictionary,move:Dictionary) -> void:
    var frame:float=f.frame
    var hit:float=second_contact(f,move) if second(f,move) else float(move.startup)
    var weight:float=smoothstep(hit-7.0,hit,frame)*(1.0-smoothstep(hit+4.0,hit+20.0,frame))
    var forward:Vector3=m.model_forward
    var up:Vector3=m.model_up
    var leg:String="Left" if second(f,move) else "Right"
    # Short first kick; the return plants the shoe, then the opposite heel drives.
    m.turn_hips((-.30 if second(f,move) else .22)*weight)
    m._aim_limb(leg+"UpLeg",leg+"Leg",forward+up*.12,weight*.90)
    m._aim_limb(leg+"Leg",leg+"Foot",forward-up*.08,weight*.96)
    m._aim_limb("Spine","Spine1",up-forward*(.55 if second(f,move) else .25),weight*.8)
    m._aim_limb("LeftArm","LeftForeArm",-forward*.4+up*.25,weight*.6)
    m._aim_limb("RightArm","RightForeArm",forward*.25+up*.5,weight*.6)
