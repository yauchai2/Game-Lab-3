extends RefCounted
## Stateless, rig-relative winner choreography. Never writes combat state.
const IDS := ["zip", "rivet", "hush", "loop"]
const LABELS := ["ZIP / GHOST STEP", "RIVET / HEAVY EXIT", "HUSH / LAST LOOK", "LOOP / SIGNAL OUT"]
const ACCENTS := [Color("00e9ef"),Color("ff9824"),Color("ff3d97"),Color("c4ff00")]

func apply(session: Node3D, side: int, seconds: float) -> Dictionary:
    var hero: Node3D=session.fighters[side]
    var id:int=hero.character_index
    var t:float=clampf(seconds,0,3.2)
    var leave:float=smoothstep(1.18,3.12,t)
    var direction:float=-1.0 if id in [0,2] else 1.0
    var stride:float=sin(maxf(0,t-1.18)*TAU/[.66,.86,.92,.72][id])
    var gesture:float=smoothstep(.04,.2,t)*(1.0-smoothstep(.85,1.35,t))
    var turn:float=smoothstep(.92,1.48,t)
    var bob:float=absf(stride)*.035*smoothstep(1.18,1.45,t)
    hero.visible=true
    hero.position=Vector3(direction*3.4*leave,bob,-.15*leave)
    hero.rotation=Vector3(0,direction*PI*.5*turn,0)
    if id==0:hero.rotation.y=-.38*turn # Sliding, still facing the lens.
    if id==2:hero.rotation.y=-PI*.5*turn-.12*gesture
    hero.model.position=Vector3.ZERO
    hero.model.rotation=Vector3(0,0,(-.08 if id==2 else .025)*gesture)
    hero.model.scale=Vector3.ONE*hero.model_scale
    hero.set_neon_silhouette(false)
    for material in hero.materials:
        if hero.neon_enabled:
            material.set_shader_parameter("ko_silhouette",false)
            material.set_shader_parameter("tint",Color.WHITE)
        material.set_shader_parameter("flash",0.0)
    var m=hero.motions
    if is_instance_valid(hero.skeleton):
        # Sample a reproducible neutral pose before applying the authored limbs.
        var idle:String=["Idle_Loop","Dance_Loop","Idle_Loop","Idle_Loop"][id]
        m.blend_from.clear();m.previous_state=idle+"/idle";m.clip_elapsed=t
        m.present({"character":id,"health":100,"state":"idle","move":"","frame":0,"y":0.0,"vy":0.0,"vx":0.0,"face":1,"guarding":false,"showcase":true},0.0,true)
        var up:Vector3=m.model_up
        var forward:Vector3=m.model_forward
        var right:Vector3=up.cross(forward).normalized()
        var walk:float=smoothstep(1.18,1.45,t)
        for label in ["Left","Right"]:
            var sign_side:float=-1.0 if label=="Left" else 1.0
            var swing:float=stride*sign_side*walk
            m._aim_limb(label+"Arm",label+"ForeArm",-up+forward*swing*.32,1.0)
            m._aim_limb(label+"ForeArm",label+"Hand",-up*.85+forward*(.22+swing*.16),1.0)
            m._aim_limb(label+"UpLeg",label+"Leg",-up+forward*swing*.42,1.0)
            m._aim_limb(label+"Leg",label+"Foot",-up+forward*maxf(0,-swing)*.68,1.0)
        match id:
            0:
                # Close finger-point/fist flick; then a sideways heel slide.
                m._aim_limb("RightArm","RightForeArm",-up*.35+forward,gesture)
                m._aim_limb("RightForeArm","RightHand",forward+up*(.25+.32*sin(t*TAU)),gesture)
                m._aim_limb("LeftArm","LeftForeArm",-up+right*.1,gesture)
                m._aim_limb("LeftForeArm","LeftHand",forward-up*.1-right*.5,gesture)
                if walk>.01:
                    m._aim_limb("RightUpLeg","RightLeg",-up+forward*.18*stride,walk)
                    m._aim_limb("LeftUpLeg","LeftLeg",-up-forward*.18*stride,walk)
            1:
                # Both knuckles toward camera, drop heavy shoulders, stomp away.
                for label in ["Left","Right"]:
                    m._aim_limb(label+"Arm",label+"ForeArm",-up*.6+forward*.55,gesture)
                    var side_push:float=-1.0 if label=="Left" else 1.0
                    m._aim_limb(label+"ForeArm",label+"Hand",up*(.4+.18*sin(t*TAU))+forward*.7+right*side_push*.55,gesture)
                hero.model.rotation.x=.10*gesture
                hero.position.y+=maxf(0,sin(t*PI/0.55))*.045*(1.0-turn)
            2:
                # Hand beside lips/cheek, head tilt, shoulder glance while leaving.
                m._aim_limb("RightArm","RightForeArm",-up*.1+forward*.25+right*.45,gesture)
                m._aim_limb("RightForeArm","RightHand",up-forward*.22-right*.18,gesture)
                var head:int=m.bone_index("Head")
                if head>=0:
                    hero.skeleton.set_bone_pose_rotation(head,m.target_local_rest[head]*Quaternion(up,.32*turn)*Quaternion(forward,-.14*gesture))
            3:
                # Existing hand-attached signal baton traces a circle near the lens.
                var flick:float=sin(t*TAU*1.35)*.35
                m._aim_limb("RightArm","RightForeArm",right*.55+forward*.3-up*.2,gesture)
                m._aim_limb("RightForeArm","RightHand",up*.45+forward*.35+right*(.85+flick),gesture)
                m._aim_limb("LeftArm","LeftForeArm",-up+right*.2,gesture)
                m._aim_limb("LeftForeArm","LeftHand",forward*.5-up*.7,gesture)
                hero.model.rotation.z+=sin(t*TAU)*.035*gesture
        hero.skeleton.force_update_all_bone_transforms()
    var close:float=1.0-smoothstep(.68,1.45,t)
    var camera:Camera3D=session.camera
    camera.near=.035
    # Match the actual rig's head height, then lock the lens while the actor exits.
    var head_index:int=m.bone_index("Head")
    var head_relative:=Vector3(0,1.8,0)
    if head_index>=0:
        head_relative=hero.skeleton.global_transform*hero.skeleton.get_bone_global_pose(head_index).origin-hero.position
    var focus:=Vector3(head_relative.x*close,lerpf(1.45,head_relative.y-.10,close),head_relative.z*close)
    camera.position=focus+Vector3(.04*direction,0,lerpf(1.10,.60,close))
    camera.look_at(focus)
    var accent:float=exp(-maxf(0,t-.10)*17) if t>=.10 else 0.0
    camera.position.x+=sin(t*125)*accent*.025
    camera.fov=lerpf(108,124,close)-accent*4
    camera.rotation.z=direction*(-.055*close+sin(t*2.3)*.012)
    return {"id":IDS[id],"label":LABELS[id],"character":id,"phase":"close" if t<.9 else ("turn" if t<1.45 else "exit"),"fish":lerpf(.28,1.0,close),"accent":ACCENTS[id],"impact":accent,"leave":leave}
