extends RefCounted
## Grounded intercept and short-stick choreography. Reads resources; never owns rules.
const ATTACKS=["jab","cross","heavy","finisher","launcher","special","overdrive"]
static func owns(f:Dictionary) -> bool:
    return f.state in ["idle","dash","blockstun"] or (f.state=="attack" and (f.move in ATTACKS or (f.character==3 and f.move=="node_pulse")))
static func describe(f:Dictionary,move:Dictionary,markers:Dictionary) -> Dictionary:
    var hush:bool=f.character==2
    var guarded:bool=f.guarding or f.state=="blockstun"
    var motion:Dictionary={"owner":"hush_intercept" if hush else "loop_baton","clip":"KK_Punch" if hush else "KK_StickStab","phase":0.0,"loop":false,"speed":1.0,"plant":false,"guard_arms":false,"uppercut":false,"launch_kick":false,"reaction":false,"grip":"both" if hush else "right"}
    if f.state=="dash":
        motion.clip="KK_DodgeBack" if f.vx*f.face<0 else "KK_DodgeForward"
        motion.phase=clampf(float(f.frame)/14.0,0,1)
        arm_guard(motion,hush)
    elif f.state=="blockstun":
        motion.clip="Hit_Chest" if hush else "KK_StickBlockHit"
        motion.reaction=true
        if hush:motion.guard_arms=true
    elif f.state=="idle":
        if guarded:
            motion.clip="Punch_Enter" if hush else "KK_StickGuard"
            motion.phase=1.0;motion.loop=not hush
        elif absf(f.vx)>=.3:
            motion.clip="KK_Backstep" if f.vx*f.face<0 else ("KK_Run" if absf(f.vx)>4.0 else "KK_Walk")
            motion.loop=true
            motion.speed=clampf(absf(f.vx)/(5.2 if motion.clip=="KK_Run" else 1.8),.25,2.4)
            arm_guard(motion,hush)
    elif hush:
        motion.clip="KK_Punch_Mirror" if f.move=="jab" else "KK_Punch"
        var contact:float=markers[motion.clip].contact
        motion.phase=phase(float(f.frame),move,contact,minf(.85,contact+.15))
        motion.uppercut=f.move=="launcher"
    else:
        match f.move:
            "jab","special":motion.clip="KK_StickStab"
            "cross","overdrive":motion.clip="KK_StickSweep"
            "heavy","finisher","node_pulse":motion.clip="KK_StickChop"
            "launcher":motion.clip="KK_StickDiagonal"
        var contact:float=markers[motion.clip].contact
        # Placement is a directing gesture, not a zero-damage punch. Reach is
        # controlled only by the simulation's node_far / node placement rules.
        motion.phase=phase(float(f.frame),move,.14,.20) if f.move=="special" else phase(float(f.frame),move,contact,minf(.90,contact+.16))
        motion.uppercut=f.move=="launcher"
    return motion
static func arm_guard(motion:Dictionary,hush:bool) -> void:
    motion.guard_arms=true
    motion.stance_clip="KK_Punch" if hush else "KK_StickStab"
    motion.stance_phase=0.0
static func phase(frame:float,move:Dictionary,contact:float,release:float) -> float:
    if frame<move.startup:return contact*smoothstep(0.0,float(move.startup),maxf(0.0,frame))
    if frame<move.startup+move.active:return lerpf(contact,release,(frame-move.startup)/float(move.active))
    return lerpf(release,1.0,clampf((frame-move.startup-move.active)/float(move.recovery),0,1))
static func finish(m:RefCounted,f:Dictionary,motion:Dictionary,move:Dictionary) -> void:
    var front:Vector3=m.model_forward;var up:Vector3=m.model_up
    if f.state=="idle" and f.character==2 and f.guarding:
        var parry:float=1.0-clampf(float(f.get("guard_frames",12))/12.0,0,1)
        m._aim_limb("LeftForeArm","LeftHand",up+front*.35,parry*.28)
    if f.state=="idle" and f.character==2 and not f.guarding and f.get("service",{}).get("sample",0)>0:
        m._aim_limb("LeftForeArm","LeftHand",up+front*.2,.35)
    if f.state!="attack":return
    var weight:float=smoothstep(0.0,float(move.startup),float(f.frame))
    if f.frame>move.startup+move.active:weight*=1.0-smoothstep(float(move.startup+move.active),float(move.startup+move.active+move.recovery),float(f.frame))
    if motion.uppercut:
        m._aim_limb("RightArm","RightForeArm",up+front*.45,weight*.85)
        m._aim_limb("RightForeArm","RightHand",up+front*.20,weight*.85)
    elif f.character==2 and f.get("service",{}).get("sample_boost",false):
        # A small free-hand brace acknowledges the consumed sample. It does not
        # extend the attacking hand or fabricate a parry / hit reward.
        m._aim_limb("LeftArm","LeftForeArm",-up*.4-front*.3,weight*.35)
    elif f.character==3 and f.move=="special":
        var far:bool=f.get("node_far",false)
        m._aim_limb("RightArm","RightForeArm",front*(1.0 if far else .4)-up*(.05 if far else .65),weight*.7)
        m._aim_limb("RightForeArm","RightHand",front+up*.10 if far else front*.3-up,weight*.7)
    elif f.character==3 and f.move in ["node_pulse","overdrive"]:
        var pending:int=f.get("service",{}).get("encore",[]).size()
        var cue_weight:float=.6 if f.move=="node_pulse" else minf(.7,float(pending)*.3)
        m._aim_limb("LeftArm","LeftForeArm",-front*.3+up*.5,weight*cue_weight)
