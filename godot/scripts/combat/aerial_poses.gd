extends RefCounted
## Original procedural key poses layered after the retained CC0 clip retarget.
## Every call starts from the sampled clip; no accumulated bone transforms.
func apply(motions: RefCounted, f: Dictionary) -> String:
    var phase: String=f.air.phase
    var up: Vector3=motions.model_up
    var front: Vector3=motions.model_forward
    var right:=front.cross(up).normalized()
    var name:=""
    var pose: Dictionary={}
    if f.get("air_counter_phase","")=="hold":
        if f.get("air_counter_role","")=="owner":
            name="Air_Parry_Stomp"
            pose={"RightUpLeg":["RightLeg",front+up*.6,.9],"RightLeg":["RightFoot",-up+front*.1,.9],"LeftUpLeg":["LeftLeg",-up-front*.2,.7],"LeftArm":["LeftForeArm",front+up*.2,.8],"LeftForeArm":["LeftHand",right-front*.1,.8],"RightArm":["RightForeArm",front+up*.2,.7]}
        else:
            name="Air_Parried_Recoil"
            pose={"Spine":["Spine1",up-front*.5,.6],"LeftArm":["LeftForeArm",up-front,.8],"RightArm":["RightForeArm",up-front,.8],"RightUpLeg":["RightLeg",front+up*.3,.6]}
    elif f.state=="stun" and f.y>.1:
        name="Hit_Fold_V"
        pose={"Spine":["Spine1",front*.6+up*.4,.55],"LeftUpLeg":["LeftLeg",up*.5+front,.75],"RightUpLeg":["RightLeg",up*.4+front,.65],"LeftArm":["LeftForeArm",-front+up*.25,.6],"RightArm":["RightForeArm",-front+up*.4,.6]}
    elif f.state=="attack" and f.move in ["air_jab","air_kick","air_finisher","meteor","air_counter"]:
        var move: Dictionary=preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move]
        var weight:=clampf(float(f.frame)/move.startup,0,1)
        if f.frame>move.startup+move.active:weight=1.0-clampf(float(f.frame-move.startup-move.active)/move.recovery,0,1)
        name=f.move
        if f.move=="air_jab":pose={"LeftArm":["LeftForeArm",front,weight],"LeftForeArm":["LeftHand",front,weight],"RightUpLeg":["RightLeg",front+up*.2,.6]}
        elif f.move=="air_counter":pose={"RightUpLeg":["RightLeg",front-up*.4,weight],"RightLeg":["RightFoot",front-up*.6,weight],"LeftArm":["LeftForeArm",up-front*.2,.8]}
        elif f.move=="air_kick":pose={"RightUpLeg":["RightLeg",front+up*.3,weight],"RightLeg":["RightFoot",front-up*.1,weight],"LeftArm":["LeftForeArm",up-front*.3,.75]}
        else:pose={"RightArm":["RightForeArm",-up+front*.35,weight],"RightForeArm":["RightHand",-up+front*.1,weight],"LeftArm":["LeftForeArm",-up+front*.35,weight],"LeftUpLeg":["LeftLeg",front+up*.4,.7]}
    elif f.state=="chase":
        name="Air_Chase"
        pose={"RightArm":["RightForeArm",front+up*.15,.8],"LeftArm":["LeftForeArm",-front+up*.2,.7],"RightUpLeg":["RightLeg",-front-up,.6]}
    elif phase=="squat" or (phase=="land" and f.air.land>0):
        name="Jump_Load" if phase=="squat" else "Land_Superhero_Slide"
        pose={"LeftUpLeg":["LeftLeg",front*.8-up,.7],"RightUpLeg":["RightLeg",front*.5-up,.7],"LeftLeg":["LeftFoot",-front-up,.65],"RightLeg":["RightFoot",-front-up,.6],"RightArm":["RightForeArm",-up+front*.4,.85],"LeftArm":["LeftForeArm",-front+up*.3,.7]}
    elif phase=="rise":
        name="Air_Rise_Corkscrew"
        pose={"RightUpLeg":["RightLeg",front+up*.5,.9],"RightLeg":["RightFoot",-up-front*.25,.8],"RightArm":["RightForeArm",up+front*.15,.8],"LeftArm":["LeftForeArm",-front-up*.1,.7]}
    elif phase=="apex" or phase=="stall":
        name="Air_Apex_Swagger"
        pose={"LeftUpLeg":["LeftLeg",front*.7+right*.65-up*.15,.8],"RightUpLeg":["RightLeg",front*.7-right*.65-up*.15,.8],"LeftLeg":["LeftFoot",-up,.7],"RightLeg":["RightFoot",-up,.7],"LeftArm":["LeftForeArm",up+front*.2,.8],"LeftForeArm":["LeftHand",-front+up*.2,.8]}
    elif phase in ["fall","fast"]:
        name="Air_Descent"
        pose={"LeftArm":["LeftForeArm",-front+up*.4,.6],"RightArm":["RightForeArm",-front+up*.4,.6],"RightUpLeg":["RightLeg",front-up*.4,.5]}
    for bone in pose:
        var data: Array=pose[bone]
        motions._aim_limb(bone,data[0],data[1],data[2])
    return name

func stretch(f: Dictionary, reduced: bool) -> Vector3:
    if reduced:return Vector3.ONE
    var vertical:=1.0
    match f.air.phase:
        "squat":vertical=.68
        "rise":vertical=1.40 if f.air.air_ticks<=4 else 1.10
        "apex","stall":vertical=.88
        "parry":vertical=.82
        "recoil":vertical=1.08
        "fast":vertical=1.28
        "land":vertical=lerpf(.65 if f.air.hard_land else .79,1.0,1.0-float(f.air.land)/(8 if f.air.hard_land else 4))
    var lateral:=1.0/sqrt(maxf(.55,vertical))
    return Vector3(lateral,vertical,lateral)
