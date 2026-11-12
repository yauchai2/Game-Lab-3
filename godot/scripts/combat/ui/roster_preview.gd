extends Node
## Isolated real-model preview. No combat simulation, damage, or combat audio.
const T=preload("res://scripts/combat/ui/ui_theme.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
var viewports:Array[SubViewport]=[]
var models:Array[Node3D]=[]
var elapsed:=0.0
var sample_clock:=0.0
var selected:=-1
var confirmation:=0.0
var pose_names:=["Route_Ready","Clamp_Check","Low_Guard","Patch_Cue"]
func _ready() -> void:
    for slot in 5:
        var vp:=SubViewport.new();vp.name="RosterViewport_"+str(slot)
        vp.size=Vector2i(448,512) if slot==4 else Vector2i(192,256)
        vp.transparent_bg=true;vp.own_world_3d=true;vp.render_target_update_mode=SubViewport.UPDATE_DISABLED
        vp.msaa_3d=Viewport.MSAA_DISABLED;vp.screen_space_aa=Viewport.SCREEN_SPACE_AA_DISABLED
        add_child(vp);viewports.append(vp)
        var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(0,0,0,0);env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.85;vp.add_child(env)
        var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-30,0);light.light_energy=1.1;light.shadow_enabled=false;vp.add_child(light)
        var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.3 if slot==4 else 2.8;camera.position=Vector3(0,1.05 if slot==4 else 1.25,5);vp.add_child(camera);camera.look_at(Vector3(0,1.05 if slot==4 else 1.2,0));camera.current=true
        var visual:=Visual.new();visual.neon_enabled=true;vp.add_child(visual)
        # The large preview is initialized with the actual choice on first use.
        # Replacing its eager default before the first Compatibility draw leaves
        # a stale renderer material dependency in Godot4.7.2.
        if slot<4:
            visual.setup(Color.WHITE,slot)
            _style(visual,slot)
        models.append(visual)
func update_preview(active:bool,choice:int,delta:float,reduced:bool) -> void:
    if not active:
        for vp in viewports:vp.render_target_update_mode=SubViewport.UPDATE_DISABLED
        return
    if choice!=selected:
        selected=choice
        if models[4].model==null or models[4].character_index!=choice:
            models[4].setup(Color.WHITE,choice)
            _style(models[4],choice)
        confirmation=.45;sample_clock=1.0
    elapsed+=delta;confirmation=maxf(0,confirmation-delta);sample_clock+=delta
    if sample_clock<1.0/15:return
    sample_clock=0.0
    for slot in 5:
        var character:int=choice if slot==4 else slot
        var visual:Node3D=models[slot]
        var pose:Dictionary={"character":character,"health":100,"state":"idle","move":"","frame":0,"x":0.0,"y":0.0,"vy":0.0,"vx":0.0,"guarding":false,"showcase":true}
        visual.motions.present(pose,1.0/15,false)
        _pose(visual,character,elapsed,confirmation if slot==4 else 0.0,reduced)
        visual.position=Vector3.ZERO;visual.rotation.y=.5
        viewports[slot].render_target_update_mode=SubViewport.UPDATE_ONCE
func _style(visual:Node3D,index:int) -> void:
    for material in visual.materials:
        material.set_shader_parameter("silhouette_preview",false)
        if material.get_shader_parameter("use_texture"):material.set_shader_parameter("tint",Color.WHITE)
        material.set_shader_parameter("neon_accent",preload("res://scripts/combat/neon/neon_style_profile.tres").accent(index))
        if material.next_pass is ShaderMaterial:material.next_pass.set_shader_parameter("silhouette_preview",false)
func _pose(visual:Node3D,index:int,time:float,confirm:float,reduced:bool) -> void:
    var m=visual.motions;var up:Vector3=m.model_up;var forward:Vector3=m.model_forward
    var breath:float=sin(time*2.4)*.035 if not reduced else 0.0
    visual.model.rotation=Vector3(0,0,breath)
    visual.model.position=Vector3.ZERO
    match index:
        2:
            m._aim_limb("LeftArm","LeftForeArm",-up+forward*.25,1)
            m._aim_limb("LeftForeArm","LeftHand",forward+up*.15,1)
            m._aim_limb("RightArm","RightForeArm",forward*.5-up*.6,.95)
            m._aim_limb("RightForeArm","RightHand",forward*.3+up*.15,.95)
            if confirm>0:m._aim_limb("RightArm","RightForeArm",forward,confirm*1.8)
        0:
            for side in ["Left","Right"]:
                m._aim_limb(side+"Arm",side+"ForeArm",forward*.4-up*.7,.92)
                m._aim_limb(side+"ForeArm",side+"Hand",-up+forward*.1,.85)
            m._aim_limb("RightUpLeg","RightLeg",forward*.45-up,.55+breath)
            visual.model.rotation.z=-.12+breath
        1:
            m._aim_limb("LeftArm","LeftForeArm",forward*.5-up*.8,1)
            m._aim_limb("RightArm","RightForeArm",forward*.7-up*.5,1)
            for side in ["Left","Right"]:m._aim_limb(side+"ForeArm",side+"Hand",forward*.75+up*.05,.95)
            visual.model.rotation.x=.04
        3:
            m._aim_limb("LeftArm","LeftForeArm",-forward*.3-up*.4,.9)
            m._aim_limb("LeftForeArm","LeftHand",up*.6-forward*.2,.9)
            m._aim_limb("RightArm","RightForeArm",forward*.7-up*.4,1.0)
            m._aim_limb("RightForeArm","RightHand",forward+up*sin(time)*.12,.9)
            visual.model.rotation.z=.04+breath
        4:
            # Reserved, upright posture for the suited enemy/cinematic actor.
            for side in ["Left","Right"]:
                m._aim_limb(side+"Arm",side+"ForeArm",-up+forward*.1,.95)
                m._aim_limb(side+"ForeArm",side+"Hand",-up+forward*.15,.95)
func hero_texture() -> Texture2D:return viewports[4].get_texture()
func card_texture(index:int) -> Texture2D:return viewports[index].get_texture()
