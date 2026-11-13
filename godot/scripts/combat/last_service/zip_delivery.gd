extends RefCounted
## Last Delivery: run-in, low kick, switch kick, held heel drive.
## Pose sampling follows confirmed simulation stages, never creates contacts.
const DELAYS := [24,16]
static func owns(f:Dictionary) -> bool:
    return f.get("character",-1)==0 and f.get("state","")=="attack" and f.get("move","")=="overdrive" and f.get("health",0)>0 and not f.get("showcase",false) and not f.has("cinematic_clip")
static func stage(f:Dictionary) -> int:return clampi(f.get("service",{}).get("delivery_stage",0),0,2)
static func contact(f:Dictionary,move:Dictionary) -> float:
    return float(f.get("service",{}).get("delivery_contact",move.startup))
static func segment(f:Dictionary,move:Dictionary) -> Dictionary:
    var current:int=stage(f)
    var hit:float=contact(f,move)
    var next:float=f.get("service",{}).get("followup",0)
    if next>0 and float(f.frame)>next-6.0:current=mini(2,current+1);hit=next
    return {"stage":current,"hit":hit,"mirrored":current==1,"frame":float(f.frame)-hit+float(move.startup)}
static func phase(f:Dictionary,move:Dictionary,marker:float) -> float:
    var beat:Dictionary=segment(f,move)
    var frame:float=f.frame;var hit:float=beat.hit
    if frame<hit:return lerpf(.05,marker,smoothstep(hit-9.0,hit,frame))
    if frame<hit+3.0:return lerpf(marker,.54,(frame-hit)/3.0)
    if beat.stage==0 and frame<hit+17.0 and f.get("service",{}).get("followup",0)>0:
        var flick:float=absf(sin((frame-hit-3.0)*PI/4.0))
        return lerpf(.27,.53,flick) # rapid ankle/knee flurry within the first confirmed beat
    var end:float=hit+8.0 if beat.stage<2 else float(move.startup+move.active+move.recovery*.55)
    return lerpf(.54,1.0,smoothstep(hit+3.0,end,frame))
static func finish(m:RefCounted,f:Dictionary,move:Dictionary) -> void:
    if f.frame<move.startup-10:return # full-body running source owns approach
    var beat:Dictionary=segment(f,move)
    var frame:float=f.frame;var hit:float=beat.hit
    var decay:float=hit+(17.0 if beat.stage==2 else 8.0)
    var weight:float=smoothstep(hit-7.0,hit,frame)*(1.0-smoothstep(hit+3.0,decay,frame))
    var leg:String="Left" if beat.mirrored else "Right"
    var up:Vector3=m.model_up;var front:Vector3=m.model_forward
    var height:float=-.40 if beat.stage==0 else (.15 if beat.stage==1 else .30)
    m.turn_hips((-.36 if beat.mirrored else .36)*weight)
    m._aim_limb(leg+"UpLeg",leg+"Leg",front+up*height,weight*.94)
    m._aim_limb(leg+"Leg",leg+"Foot",front-up*(.24 if beat.stage==0 else .04),weight*.98)
    m._aim_limb("Spine","Spine1",up-front*(.75 if beat.stage==2 else .30),weight*.85)
    m._aim_limb("LeftArm","LeftForeArm",-front*.65+up*.3,weight*.7)
    m._aim_limb("RightArm","RightForeArm",front*.3+up*.55,weight*.6)
