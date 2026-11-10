extends RefCounted
## Wall-time signature poses layered on the real attack. Never changes root or hitboxes.
static func apply(m:RefCounted,f:Dictionary) -> void:
    var phase:String=f.get("neon_signature_phase","")
    if phase=="" or f.state!="attack" or f.move!="overdrive":return
    var up:Vector3=m.model_up
    var forward:Vector3=m.model_forward
    var character:int=f.get("character",0)
    var left:Vector3
    var right:Vector3
    match phase:
        "gather":left=-forward*.7-up*.25;right=-forward*.8+up*.15
        "open":left=-forward*.7+up*.85;right=forward*.25+up*.9
        "aim":left=forward*.45+up*.1;right=-forward*.8+up*.25
        "drive":left=forward+up*.10;right=forward-up*.10
        _:left=forward*.55-up*.5;right=forward*.7-up*.3
    if character==1:
        m._aim_limb("RightUpLeg","RightLeg",forward*(1.1 if phase=="drive" else .4)-up*.5,.95)
        m._aim_limb("RightLeg","RightFoot",forward if phase=="drive" else -up,.95)
        left=-up*.3-forward*.8
    elif character==2:
        if phase in ["open","aim"]:left=up*.9-forward*.35;right=up-forward*.5
        elif phase=="drive":left=forward*.65-up;right=forward-up*.8
    elif character==3:
        left=-forward*.9 if phase in ["aim","drive"] else -up*.8
        right=forward+up*.12 if phase=="drive" else forward*.3+up*.6
    m._aim_limb("Spine","Spine1",up+forward*(-.35 if phase in ["gather","aim"] else .30),.75)
    m._aim_limb("LeftArm","LeftForeArm",left,.95)
    m._aim_limb("RightArm","RightForeArm",right,.95)
    m._aim_limb("LeftForeArm","LeftHand",forward if phase=="drive" else up*.8+forward*.2,.9)
    m._aim_limb("RightForeArm","RightHand",forward if phase=="drive" else up,.9)
