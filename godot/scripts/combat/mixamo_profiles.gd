extends RefCounted
## Single pose owner for imported Mixamo motions; simulation remains authoritative.
const Data=preload("res://scripts/combat/mixamo_motion_library.gd")
const Transit=preload("res://scripts/combat/last_service/transit_motion.gd")
const BACK_WALK_SPEED:=0.89
static func describe(f:Dictionary,move:Dictionary) -> Dictionary:
    if not Data.available() or f.get("character",0) not in [0,1,2,3]:return {}
    if f.health<=0 or f.has("cinematic_clip") or f.get("showcase",false) or f.has("paired_throw"):return {}
    if f.has("ko_spin") or f.get("ko_theatre",-1.0)>=0 or f.get("rally_phase","")!="" or f.get("exchange_choice","")!="":return {}
    if f.get("ricochet",{}).get("ticks",0)>0 or f.get("air_counter_phase","")=="hold":return {}
    if f.y>.01 or f.get("air",{}).get("phase","ground")!="ground":return {}
    var clip:=""
    var loop:=false
    var phase:=0.0
    var speed:=1.0
    var reaction:=false
    if f.state=="attack":
        if move.is_empty():return {}
        if f.move not in ["jab","cross","heavy","finisher"]:return {}
        match int(f.character):
            0:
                # Each simulation segment has one source kick, including the existing flurry clock.
                var segment:Dictionary=Transit.zip_segment(f,move)
                clip="MX_Roundhouse" if f.move in ["jab","cross"] else "MX_Hurricane"
                if segment.mirrored:clip+="_Mirror"
                phase=Transit.attack_phase(float(segment.frame),move,float(Data.data.markers[clip].contact))
            1:clip={"jab":"MX_Jab","cross":"MX_Cross","heavy":"MX_BodyPunch","finisher":"MX_Hook"}[f.move]
            2:clip={"jab":"MX_HushJab","cross":"MX_HushElbow","heavy":"MX_Elbow","finisher":"MX_Elbow"}[f.move]
            3:
                # The batch has swings, but no short-stick thrust or rising strike.
                if f.move=="jab":return {}
                clip={"cross":"MX_StickBack","heavy":"MX_StickHorizontal","finisher":"MX_StickDown"}[f.move]
        if f.character!=0:
            var contact:float=Data.data.markers[clip].contact
            phase=Transit.attack_phase(float(f.frame),move,contact)
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
            if ground_speed>2.0:return {}
            var backwards:bool=f.vx*f.face<0
            clip="MX_WalkBack" if backwards else "MX_Walking"
            loop=true
            speed=clampf(ground_speed/(BACK_WALK_SPEED if backwards else 1.23),.25,2.25 if backwards else 1.65)
        elif f.character in [1,2] and not f.guarding:
            clip="MX_Idle";loop=true;speed=.85 if f.character==1 else 1.05
        else:return {}
    else:return {}
    if not Data.data.clips.has(clip):return {}
    var result:Dictionary={"owner":"mixamo_"+str(f.character),"clip":clip,"phase":phase,"loop":loop,"speed":speed,"plant":false,"guard_arms":false,"imported":true,"reaction":reaction,"transit":true,"transition":f.state}
    if clip in ["MX_Walking","MX_WalkBack"] and (f.guarding or f.character==3):
        result.guard_arms=true
        result["stance_clip"]="KK_StickStab" if f.character==3 else "Punch_Enter"
        result["stance_phase"]=0.0 if f.character==3 else 1.0
    if f.character==3:result["grip"]="right"
    return result
static func owns(f:Dictionary) -> bool:
    return not describe(f,f.get("move_data",{})).is_empty()
static func limb(f:Dictionary) -> String:
    if f.state!="attack":return ""
    var motion:Dictionary=describe(f,f.get("move_data",{}))
    return "" if motion.is_empty() else str(Data.data.markers[motion.clip].limb)
