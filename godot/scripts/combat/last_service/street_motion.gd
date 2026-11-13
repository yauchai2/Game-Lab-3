extends RefCounted
## Data-only grounded motion selection for the four heroes. Never writes simulation.
const Counter=preload("res://scripts/combat/last_service/counter_motion.gd")
const Rivet=preload("res://scripts/combat/last_service/rivet_motion.gd")
const ZIP_ATTACKS=["jab","cross","heavy","finisher","launcher","special","overdrive"]
const RIVET_ATTACKS=["jab","cross","heavy","finisher","launcher","special","overdrive"]
static func owns(f:Dictionary) -> bool:
    if f.get("character",0) not in [0,1,2,3] or f.health<=0 or f.y>.01:return false
    if f.get("showcase",false) or f.has("cinematic_clip") or f.get("rally_phase","")!="":return false
    if f.get("ko_theatre",-1.0)>=0 or f.has("ko_spin"):return false
    if f.get("air_enabled",false) and f.get("air",{}).get("phase","ground") in ["squat","rise","apex","stall","fall","fast","land"]:return false
    if f.character in [2,3]:return Counter.owns(f)
    return f.state in ["idle","dash"] or (f.state=="attack" and f.move in (ZIP_ATTACKS if f.character==0 else RIVET_ATTACKS))
static func describe(f:Dictionary,move:Dictionary,markers:Dictionary) -> Dictionary:
    if not owns(f):return {}
    if f.character in [2,3]:return Counter.describe(f,move,markers)
    var zip:bool=f.character==0
    var motion:Dictionary={"owner":"zip_kicks" if zip else "rivet_boxing","clip":"KK_Guard" if zip else "Punch_Enter","loop":zip,"phase":1.0,"speed":1.0,"plant":not zip,"guard_arms":false,"uppercut":false,"launch_kick":false}
    if f.state=="dash":
        motion.clip="KK_DodgeBack" if f.vx*f.face<0 else "KK_DodgeForward"
        motion.phase=clampf(float(f.frame)/14.0,0,1);motion.loop=false;motion.plant=false;motion.guard_arms=not zip
        return motion
    if f.state=="idle":
        if absf(f.vx)>=.3:
            motion.clip="KK_Backstep" if f.vx*f.face<0 else ("KK_Run" if absf(f.vx)>4.0 else "KK_Walk")
            var stride_speed:float=5.2 if motion.clip=="KK_Run" else 1.8
            motion.speed=clampf(absf(f.vx)/stride_speed,.25,2.4)
            motion.loop=true;motion.plant=false;motion.guard_arms=not zip
        return motion
    var frame:float=f.frame
    if zip:
        var segment:Dictionary=zip_segment(f,move)
        var mirrored:bool=segment.mirrored
        frame=segment.frame
        motion.clip="KK_Kick_Mirror" if mirrored else "KK_Kick"
        motion.launch_kick=f.move=="launcher"
        motion.phase=attack_phase(frame,move,float(markers[motion.clip].contact),.75)
    elif f.move in ["heavy","finisher","overdrive"]:
        motion.clip="UAL2_Hook"
        if f.frame>=move.startup+move.active:
            motion.clip="UAL2_Hook_Rec"
            motion.phase=clampf(float(f.frame-move.startup-move.active)/float(move.recovery),0,1)
        else:motion.phase=attack_phase(frame,move,float(markers.UAL2_Hook.contact),1.0)
    else:
        motion.clip="Punch_Jab" if f.move=="jab" else "Punch_Cross"
        motion.phase=Rivet.sample(f,1.0,move) if f.move in Rivet.ATTACKS else attack_phase(frame,move,.30,.40)
        motion.uppercut=f.move=="launcher"
    motion.loop=false
    return motion
static func zip_segment(f:Dictionary,move:Dictionary) -> Dictionary:
    var frame:float=f.frame
    var r:Dictionary=f.get("service",{})
    var mirrored:bool=f.move in ["cross","finisher"]
    if f.move=="special" and (r.get("zip_second",false) or (r.get("followup",0)>0 and frame>float(r.followup)-4.0)):
        mirrored=true
        var next_contact:float=float(r.get("followup",0)) if r.get("followup",0)>0 else float(move.startup+4)
        frame+=float(move.startup)-next_contact
    elif f.move=="overdrive":
        var stage:int=2-int(r.get("flurry_left",2))
        # Preserve the contact pose on the exact tick that confirms a hit.
        if r.get("followup",0)>0 and frame<=float(r.followup)-5.0:stage=maxi(0,stage-1)
        mirrored=stage==1;frame-=float(stage*5)
    return {"mirrored":mirrored,"frame":frame}
static func striking_limb(f:Dictionary) -> String:
    if not owns(f) or f.state!="attack":return ""
    if f.character==3:return "BatonTip"
    if f.character in [1,2]:return "LeftHand" if f.move=="jab" else "RightHand"
    var move:Dictionary=f.get("move_data",{})
    if move.is_empty():return ""
    return "LeftFoot" if zip_segment(f,move).mirrored else "RightFoot"
static func attack_phase(frame:float,move:Dictionary,contact:float,release:float) -> float:
    if frame<move.startup:return contact*smoothstep(0.0,float(move.startup),maxf(0.0,frame))
    if frame<move.startup+move.active:return lerpf(contact,release,(frame-move.startup)/float(move.active))
    return lerpf(release,1.0,clampf((frame-move.startup-move.active)/float(move.recovery),0,1))
static func guard_bone(label:String) -> bool:
    return label.begins_with("DEF-shoulder") or label.begins_with("DEF-upper_arm") or label.begins_with("DEF-forearm") or label.begins_with("DEF-hand") or label.begins_with("DEF-f_") or label.begins_with("DEF-thumb")
static func finish(m:RefCounted,f:Dictionary,motion:Dictionary,move:Dictionary) -> void:
    if f.character in [2,3]:
        Counter.finish(m,f,motion,move)
        return
    # One bounded trajectory correction belongs to this same pose owner. The
    # imported full-body kick remains the base; no legacy aerial/cannon layers.
    var weight:=0.0
    if f.state=="attack":
        weight=smoothstep(0.0,float(move.startup),float(f.frame))
        if f.frame>move.startup+move.active:weight*=1.0-smoothstep(float(move.startup+move.active),float(move.startup+move.active+move.recovery),float(f.frame))
    if motion.uppercut:
        m._aim_limb("RightArm","RightForeArm",m.model_up+m.model_forward*.35,weight*.9)
        m._aim_limb("RightForeArm","RightHand",m.model_up+m.model_forward*.15,weight*.9)
    elif motion.launch_kick:
        m._aim_limb("RightUpLeg","RightLeg",m.model_up*.75+m.model_forward,weight*.55)
        m._aim_limb("RightLeg","RightFoot",m.model_forward+m.model_up*.55,weight*.55)
