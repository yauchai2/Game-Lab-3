extends RefCounted
## Single pose owner for imported Mixamo motions; simulation remains authoritative.
const Data=preload("res://scripts/combat/mixamo_motion_library.gd")
const Transit=preload("res://scripts/combat/last_service/transit_motion.gd")
const BACK_WALK_SPEED:=0.89
const RUN_SPEED:=2.73
static func describe(f:Dictionary,move:Dictionary) -> Dictionary:
    if not Data.available() or f.get("character",0) not in [0,1,2,3]:return {}
    if f.health<=0 or f.has("cinematic_clip") or f.get("showcase",false) or f.has("paired_throw"):return {}
    if f.has("ko_spin") or f.get("ko_theatre",-1.0)>=0 or f.get("rally_phase","")!="" or f.get("exchange_choice","")!="":return {}
    if f.get("ricochet",{}).get("ticks",0)>0 or f.get("air_counter_phase","")=="hold":return {}
    if f.y>.01:return _air(f,move)
    if f.get("air",{}).get("phase","ground")!="ground":return {}
    var clip:=""
    var loop:=false
    var phase:=0.0
    var speed:=1.0
    var reaction:=false
    if f.state=="attack":
        if move.is_empty():return {}
        if f.move=="launcher":
            if f.character!=1 or not Data.data.clips.has("MX_Uppercut"):return {}
        elif f.move not in ["jab","cross","heavy","finisher","special","overdrive","node_pulse"]:return {}
        if f.move=="node_pulse" and f.character!=3:return {}
        match int(f.character):
            0:
                # Each simulation segment has one source kick, including the existing flurry clock.
                var segment:Dictionary=Transit.zip_segment(f,move)
                clip="MX_Roundhouse" if f.move in ["jab","cross","special"] else "MX_Hurricane"
                if segment.mirrored:clip+="_Mirror"
                phase=Transit.attack_phase(float(segment.frame),move,float(Data.data.markers[clip].contact))
            1:clip={"jab":"MX_Jab","cross":"MX_Cross","heavy":"MX_BodyPunch","finisher":"MX_Hook","special":"MX_Cross","overdrive":"MX_Hook","launcher":"MX_Uppercut"}[f.move]
            2:clip={"jab":"MX_HushJab","cross":"MX_HushElbow","heavy":"MX_Elbow","finisher":"MX_Elbow","special":"MX_Elbow","overdrive":"MX_HushElbow"}[f.move]
            3:
                # The batch has swings, but no short-stick thrust or rising strike.
                if f.move in ["jab","special"]:return {}
                clip={"cross":"MX_StickBack","heavy":"MX_StickHorizontal","finisher":"MX_StickDown","overdrive":"MX_StickHorizontal","node_pulse":"MX_StickDown"}[f.move]
        if f.character!=0:
            var contact:float=Data.data.markers[clip].contact
            phase=Transit.attack_phase(float(f.frame),move,contact)
            if f.character==1 and f.move=="special" and f.frame<move.startup:
                # Held charge repeats simulation frames 7/8: both must sample one load pose.
                var load:float=contact*.35
                phase=load*smoothstep(0,7,float(f.frame)) if f.frame<=8 else lerpf(load,contact,smoothstep(8,float(move.startup),float(f.frame)))
    elif f.state=="stun":
        clip="MX_HeadHit" if f.character in [0,3] or f.vy>2.0 else "MX_BodyHit"
        reaction=true
    elif f.state=="blockstun":
        if f.character==3:return {}
        clip="MX_Block";reaction=true
    elif f.state=="dash":
        if f.vx*f.face>=0:return {}
        clip="MX_Dodge";phase=clampf(float(f.frame)/14.0,0,1)
    elif f.state=="idle":
        var ground_speed:=absf(f.vx)
        if ground_speed>=.3:
            var backwards:bool=f.vx*f.face<0
            if ground_speed>2.0:
                clip="MX_RunBack" if backwards else ("MX_Sprint" if ground_speed>4.6 else "MX_Run")
                var stride_speed:float=3.17 if backwards else (6.36 if clip=="MX_Sprint" else RUN_SPEED)
                speed=clampf(ground_speed/stride_speed,.7,2.8 if backwards else 1.7)
            else:
                clip="MX_WalkBack" if backwards else "MX_Walking"
                speed=clampf(ground_speed/(BACK_WALK_SPEED if backwards else 1.23),.25,2.25 if backwards else 1.65)
            loop=true
        elif f.character in [1,2] and not f.guarding:
            clip="MX_Idle";loop=true;speed=.85 if f.character==1 else 1.05
        else:return {}
    else:return {}
    if not Data.data.clips.has(clip):return {}
    var result:Dictionary={"owner":"mixamo_"+str(f.character),"clip":clip,"phase":phase,"loop":loop,"speed":speed,"plant":false,"guard_arms":false,"imported":true,"reaction":reaction,"transit":true,"transition":f.state}
    if f.state=="idle" and absf(f.vx)>=.3 and (f.guarding or f.character==3):
        result.guard_arms=true
        result["stance_clip"]="KK_StickStab" if f.character==3 else "Punch_Enter"
        result["stance_phase"]=0.0 if f.character==3 else 1.0
    if f.character==3:result["grip"]="right"
    return result
static func _air(f:Dictionary,move:Dictionary) -> Dictionary:
    if f.state!="attack" or move.is_empty():return {}
    if f.move not in ["air_jab","air_kick","air_finisher","meteor","air_counter"]:return {}
    var keys:Array=[
        {"air_jab":"MX_Roundhouse","air_kick":"MX_AirKick","air_finisher":"MX_Hurricane","meteor":"MX_AirKick","air_counter":"MX_AirKick"},
        {"air_jab":"MX_Jab","air_kick":"MX_Cross","air_finisher":"MX_Hook","meteor":"MX_BodyPunch","air_counter":"MX_Hook"},
        {"air_jab":"MX_HushJab","air_kick":"MX_AirKick","air_finisher":"MX_Elbow","meteor":"MX_Elbow","air_counter":"MX_HushElbow"},
        {"air_jab":"KK_StickStab","air_kick":"MX_StickHorizontal","air_finisher":"MX_StickBack","meteor":"MX_StickDown","air_counter":"MX_StickDown"}]
    var clip:String=keys[int(f.character)][f.move]
    if f.character==0 and f.move=="air_finisher" and Data.data.clips.has("MX_CrescentKick"):
        clip="MX_CrescentKick"
    if not Data.data.clips.has(clip):return {} # Original CC0 stick thrust keeps its own complete profile.
    var marker:Dictionary=Data.data.markers[clip]
    var legs:String="right" if marker.limb=="LeftFoot" else ("left" if marker.limb=="RightFoot" else "both")
    if clip=="MX_CrescentKick":legs=""
    var result:Dictionary={"owner":"mixamo_"+str(f.character),"clip":clip,"phase":Transit.attack_phase(float(f.frame),move,float(marker.contact)),"loop":false,"speed":1.0,"plant":false,"guard_arms":false,"imported":true,"reaction":false,"transit":true,"transition":"air","air_legs":legs}
    if f.character==3:result["grip"]="right"
    return result
static func finish(m:RefCounted,f:Dictionary,move:Dictionary) -> void:
    if f.y<=.01 or f.state!="attack" or f.move not in ["meteor","air_counter"]:return
    # Redirect a bounded part of the source strike toward the opponent below.
    # Full-body source rotation and simulation root remain authoritative.
    var weight:float=smoothstep(0,float(move.startup),float(f.frame))
    if f.frame>move.startup+move.active:weight*=1.0-smoothstep(float(move.startup+move.active),float(move.startup+move.active+move.recovery),float(f.frame))
    var limb_name:String=limb(f)
    if limb_name.ends_with("Foot"):
        var side:String=limb_name.trim_suffix("Foot")
        m._aim_limb(side+"UpLeg",side+"Leg",m.model_forward-m.model_up*.4,weight*.3)
        m._aim_limb(side+"Leg",side+"Foot",m.model_forward-m.model_up*.75,weight*.3)
    else:
        var side:String="Left" if limb_name.begins_with("Left") else "Right"
        m._aim_limb(side+"Arm",side+"ForeArm",m.model_forward-m.model_up*.55,weight*.3)
        m._aim_limb(side+"ForeArm",side+"Hand",m.model_forward-m.model_up*.85,weight*.3)
static func owns(f:Dictionary) -> bool:
    return not describe(f,f.get("move_data",{})).is_empty()
static func limb(f:Dictionary) -> String:
    if f.state!="attack":return ""
    var motion:Dictionary=describe(f,f.get("move_data",{}))
    return "" if motion.is_empty() else str(Data.data.markers[motion.clip].limb)
