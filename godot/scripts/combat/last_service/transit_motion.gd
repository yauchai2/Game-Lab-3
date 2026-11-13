extends RefCounted
## Source-backed air / contact transitions. Presentation only, never a physics owner.
const Counter=preload("res://scripts/combat/last_service/counter_motion.gd")
const Rivet=preload("res://scripts/combat/last_service/rivet_motion.gd")
const GROUND_ATTACKS=["jab","cross","heavy","finisher","launcher","special","overdrive","node_pulse"]
const AIR_ATTACKS=["air_jab","air_kick","air_finisher","meteor","air_counter"]
const KEYS=["zip","rivet","hush","loop"]
static func owns(f:Dictionary) -> bool:
    if f.get("character",0) not in [0,1,2,3] or f.health<=0:return false
    if f.get("showcase",false) or f.has("cinematic_clip") or f.get("rally_phase","")!="":return false
    if f.get("ko_theatre",-1.0)>=0 or f.has("ko_spin") or f.get("exchange_choice","")!="":return false
    if f.get("air_counter_phase","")=="hold" or f.get("ricochet",{}).get("ticks",0)>0:return false
    if f.state=="stun":return true
    if f.state=="attack" and f.move=="grab" and f.y<=.01:return true
    if not f.has("air"):return false
    if f.state=="attack":return f.move in AIR_ATTACKS or (f.y>.01 and f.move in GROUND_ATTACKS)
    return f.state in ["idle","jump_squat","landing","chase","dash","blockstun"] and (f.y>.01 or f.get("air",{}).get("phase","ground") in ["squat","land"])
static func describe(f:Dictionary,move:Dictionary,markers:Dictionary) -> Dictionary:
    if not owns(f):return {}
    var hero:int=f.character
    var motion:Dictionary={"owner":KEYS[hero]+"_air","clip":"Jump_Loop","phase":.35+float(hero)*.10,"speed":1.0,"loop":false,"plant":false,"guard_arms":false,"grip":"both" if hero!=3 else "right","uppercut":false,"launch_kick":false,"transit":true,"air_legs":"","arm_stance":""}
    var air:Dictionary=f.get("air",{})
    motion.phase=clampf(.12+float(hero)*.035+float(air.get("air_ticks",0))/75.0,.12,.95)
    motion.transition=air.get("phase","ground")
    if f.state=="stun":
        motion.owner=KEYS[hero]+"_reaction"
        motion.transition="air" if f.y>.01 else "ground"
        motion.clip="Hit_Head" if hero in [0,3] or f.vy>2.0 else "Hit_Chest"
        motion.reaction=true
        if f.y>.01:motion.air_legs="both"
        return motion
    if f.state=="attack":
        if hero in [2,3] and f.move in GROUND_ATTACKS:
            var counter:Dictionary=Counter.describe(f,move,markers)
            counter.merge({"owner":KEYS[hero]+"_air","transit":true,"air_legs":"both","arm_stance":"","counter_transition":true},true)
            return counter
        var clip:String=""
        var contact:=.30
        if f.move=="grab":
            motion.owner=KEYS[hero]+"_throw"
            clip=["KK_Punch_Mirror","UAL2_Hook","Punch_Cross","KK_StickSweep"][hero]
            motion.plant=true
        elif hero==0:
            var mirrored:bool=f.move in ["air_jab","air_finisher"]
            if f.move in GROUND_ATTACKS:mirrored=zip_segment(f,move).mirrored
            clip="KK_Kick_Mirror" if mirrored else "KK_Kick"
            motion.air_legs="right" if clip=="KK_Kick_Mirror" else "left"
        elif hero==1:
            clip="Punch_Jab" if f.move in ["jab","air_jab"] else ("UAL2_Hook" if f.move in ["heavy","finisher","overdrive","air_finisher"] else "Punch_Cross")
            motion.air_legs="both"
        elif hero==2:
            clip="KK_Punch_Mirror" if f.move=="air_jab" else ("KK_Kick" if f.move=="air_kick" else "KK_Punch")
            motion.air_legs="left" if f.move=="air_kick" else "both"
            if f.move=="air_kick":motion.arm_stance="KK_Guard"
        else:
            clip={"air_jab":"KK_StickStab","air_kick":"KK_StickSweep","air_finisher":"KK_StickDiagonal","meteor":"KK_StickChop","air_counter":"KK_StickParry"}[f.move]
            motion.air_legs="both"
        motion.clip=clip
        if markers.has(clip):contact=float(markers[clip].contact)
        var frame:float=f.frame
        if hero==0 and f.move in GROUND_ATTACKS:frame=zip_segment(f,move).frame
        motion.phase=attack_phase(frame,move,contact)
        if hero==1 and f.move=="special":motion.phase=Rivet.sample(f,1.0,move)
        return motion
    var phase:String=air.get("phase","ground")
    if phase=="squat":
        motion.clip="Jump_Start";motion.phase=.32*(1.0-float(air.get("squat",0))/3.0)
    elif phase=="land":
        motion.clip="Jump_Land";motion.phase=lerpf(.05,.42,1.0-float(air.get("land",0))/(8.0 if air.get("hard_land",false) else 4.0))
    motion.arm_stance=["KK_Guard","Punch_Enter","KK_Guard","KK_StickGuard"][hero]
    return motion
static func attack_phase(frame:float,move:Dictionary,contact:float) -> float:
    if frame<move.startup:return contact*smoothstep(0.0,float(move.startup),maxf(0.0,frame))
    if frame<move.startup+move.active:return lerpf(contact,minf(.95,contact+.12),(frame-move.startup)/float(move.active))
    return lerpf(minf(.95,contact+.12),1.0,clampf((frame-move.startup-move.active)/float(move.recovery),0,1))
static func mask_leg(label:String,selection:String) -> bool:
    if selection=="":return false
    if not (label.begins_with("DEF-thigh") or label.begins_with("DEF-shin") or label.begins_with("DEF-foot") or label.begins_with("DEF-toe")):return false
    return selection=="both" or label.ends_with(".L" if selection=="left" else ".R")
static func limb(f:Dictionary) -> String:
    if not owns(f) or f.state!="attack":return ""
    if f.move=="grab":return "LeftHand" if f.character==0 else ("RightHand" if f.character!=3 else "BatonTip")
    if f.character==0:
        if f.move in GROUND_ATTACKS:
            var move:Dictionary=f.get("move_data",{})
            if move.is_empty():return ""
            return "LeftFoot" if zip_segment(f,move).mirrored else "RightFoot"
        return "LeftFoot" if f.move in ["air_jab","air_finisher"] else "RightFoot"
    if f.character==2 and f.move=="air_kick":return "RightFoot"
    if f.character==3:return "BatonTip"
    return "LeftHand" if f.move in ["jab","air_jab"] else "RightHand"
static func finish(m:RefCounted,f:Dictionary,motion:Dictionary,move:Dictionary) -> void:
    if motion.get("counter_transition",false):
        Counter.finish(m,f,motion,move)
        return
    var front:Vector3=m.model_forward
    var up:Vector3=m.model_up
    if f.state=="attack":
        var weight:float=smoothstep(0.0,float(move.startup),float(f.frame))
        if f.frame>move.startup+move.active:weight*=1.0-smoothstep(float(move.startup+move.active),float(move.startup+move.active+move.recovery),float(f.frame))
        if f.move=="grab":
            # Grip/release gesture only: the simulation resolves the throw, no fake attachment.
            var side:String="Left" if f.character==2 else "Right"
            m._aim_limb(side+"Arm",side+"ForeArm",front+up*.15,weight*.65)
            m._aim_limb(side+"ForeArm",side+"Hand",front+up*.1,weight*.65)
        elif f.character==2 and f.move=="air_kick":
            m._aim_limb("RightUpLeg","RightLeg",front*.6-up*.8,weight*.35)
            m._aim_limb("RightLeg","RightFoot",front*.75-up*.25,weight*.3)
        elif f.move in ["meteor","air_counter"]:
            if f.character==0:
                m._aim_limb("RightUpLeg","RightLeg",front-up*.25,weight*.65)
                m._aim_limb("RightLeg","RightFoot",front-up*.65,weight*.65)
            else:
                m._aim_limb("RightArm","RightForeArm",front-up*.65,weight*.70)
                m._aim_limb("RightForeArm","RightHand",front-up*.85,weight*.70)
    elif f.state=="stun":
        if f.character==1:m._aim_limb("LeftArm","LeftForeArm",front*.4+up*.3,.35)
        elif f.character==2:m._aim_limb("LeftForeArm","LeftHand",up+front*.3,.45)
        elif f.character==3:m._aim_limb("RightForeArm","RightHand",front+up*.15,.35)
    elif f.character==2:
        m._aim_limb("LeftForeArm","LeftHand",up+front*.35,.35)
    elif f.character==3:
        m._aim_limb("LeftArm","LeftForeArm",-front*.3+up*.4,.35)

static func zip_segment(f:Dictionary,move:Dictionary) -> Dictionary:
    var frame:float=f.frame
    var r:Dictionary=f.get("service",{})
    if preload("res://scripts/combat/last_service/zip_express.gd").owns(f):
        return {"mirrored":preload("res://scripts/combat/last_service/zip_express.gd").second(f,move),"frame":frame}
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
