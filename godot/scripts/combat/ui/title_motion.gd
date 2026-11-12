extends Node
## Title-only isolated stage: bounded 12 Hz pose/camera animation, no simulation/audio.
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const STEP:=1.0/12.0
# Reference composition: pink/cyan foreground, yellow centre, green/red behind.
# Fifth person is a background extra, not a fifth selectable fighter.
const CAST=[2,0,1,3,0]
const COLOURS=["ff0078","00d9e8","ffe600","ff304c","9dff00"]
const POSITIONS=[Vector3(.7,0,3.45),Vector3(2.7,0,2.45),Vector3(1.45,0,-1.35),Vector3(3.6,0,-3.3),Vector3(-2.15,0,-3.3)]
const YAWS=[-.35,-.45,.25,-.25,.5]
var viewport:SubViewport
var camera:Camera3D
var actors:Array[Node3D]=[]
var elapsed:=0.0
var accumulator:=STEP
var rendered_frames:=0
var active:=false
var ready_texture:=false
var shot_index:=0
var batches:Array[MultiMeshInstance3D]=[]
func _ready() -> void:
    viewport=SubViewport.new();viewport.name="TitleStage";viewport.size=Vector2i(960,540)
    viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
    viewport.msaa_3d=Viewport.MSAA_DISABLED;viewport.screen_space_aa=Viewport.SCREEN_SPACE_AA_DISABLED
    add_child(viewport)
    var world:=WorldEnvironment.new();world.environment=Environment.new()
    world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color("ca0098")
    viewport.add_child(world)
    _city()
    for i in CAST.size():
        var actor:=Visual.new();actor.neon_enabled=true;viewport.add_child(actor);actor.setup(Color.WHITE,CAST[i])
        for mat in actor.materials:
            mat.set_shader_parameter("silhouette_preview",true)
            mat.set_shader_parameter("tint",Color(COLOURS[i]))
            if mat.next_pass:mat.next_pass.set_shader_parameter("silhouette_preview",true)
        actors.append(actor)
    camera=Camera3D.new();camera.near=.05;camera.far=100;viewport.add_child(camera);camera.current=true
    _sample(0.0)
func update_stage(visible_title:bool,delta:float,reduced:bool) -> void:
    active=visible_title and not reduced
    if not active:
        viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
        return
    # A resumed tab never jumps through an entire camera sequence in one frame.
    var dt:float=clampf(delta,0.0,.1)
    elapsed=fposmod(elapsed+dt,8.0);accumulator+=dt
    if accumulator<STEP:return
    accumulator=fposmod(accumulator,STEP)
    _sample(floorf(elapsed/STEP)*STEP)
    viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
    rendered_frames+=1;ready_texture=true
func texture() -> Texture2D:return viewport.get_texture()
func _sample(time:float) -> void:
    shot_index=0
    var beat:float=fposmod(time,.5)/.5
    var pulse:float=maxf(0.0,1.0-beat*4.0)
    for i in CAST.size():
        var actor:Node3D=actors[i]
        var m=actor.motions
        m.present({"character":CAST[i],"health":100,"state":"idle","move":"","frame":0,"y":0.0,"vy":0.0,"vx":0.0,"face":1,"guarding":false,"showcase":true},STEP,false)
        var up:Vector3=m.model_up;var forward:Vector3=m.model_forward
        var groove:float=sin(time*PI+i*1.4)
        for side in ["Left","Right"]:
            m._aim_limb(side+"Arm",side+"ForeArm",-up+forward*.22,1.0)
            m._aim_limb(side+"ForeArm",side+"Hand",-up*.7+forward*.35,1.0)
        match i:
            0:
                # Foreground MC: dropped shoulders and pocket-height hands.
                m._aim_limb("RightArm","RightForeArm",-up+forward*.35,1.0)
                m._aim_limb("RightForeArm","RightHand",-up*.6+forward*.5,1.0)
            1:
                m._aim_limb("LeftArm","LeftForeArm",-up+forward*.5,1.0)
                m._aim_limb("LeftForeArm","LeftHand",forward*.8-up*.2,1.0)
            2:
                # Centre figure's elbows project sideways, away from the face.
                for side in ["Left","Right"]:
                    m._aim_limb(side+"Arm",side+"ForeArm",-up*.4+forward*.7,1.0)
                    m._aim_limb(side+"ForeArm",side+"Hand",-up+forward*.25,1.0)
            3:
                m._aim_limb("RightArm","RightForeArm",forward*.8+up*.1,1.0)
                m._aim_limb("RightForeArm","RightHand",up*.6+forward*.5,1.0)
            4:
                m._aim_limb("LeftArm","LeftForeArm",up*.5+forward*.4,1.0)
                m._aim_limb("LeftForeArm","LeftHand",up,1.0)
        actor.position=POSITIONS[i]+Vector3(groove*.035,0,0)
        actor.rotation=Vector3(0,YAWS[i]+groove*.035,0)
        actor.model.rotation=Vector3(0,0,groove*.035)
    # Keep one reference-like street-corner axis. Small dolly/roll, no angle cuts.
    camera.position=Vector3(1.1+sin(time*TAU/8)*.045,0.95,6.5-pulse*.07)
    camera.look_at(Vector3(-1.8,1.65,-7.0))
    camera.fov=51.0-pulse*.5
    camera.rotation.z=deg_to_rad(6.0+sin(time*TAU/8)*.3)
func _city() -> void:
    var colours:Array[Color]=[Color("f4f4f7"),Color("111119"),Color("5c5a69")]
    var transforms:Array=[[],[],[]]
    # Each facade is deliberately uneven, with real depth and lean; three draw batches.
    for side in [-1,1]:
        for block in 7:
            var depth:float=-2.0-block*4.8
            var height:float=9.0+float((block*3+side+8)%5)*2.2
            var x:float=side*(5.0+float(block%2)*.35)
            _box(transforms,0,Vector3(x+side*1.7,height*.5,depth),Vector3(3.4,height,4.3),side*.025)
            for floor_index in int(height/1.0):
                var y:float=.55+floor_index
                for window in 3:
                    _box(transforms,1,Vector3(x-side*.035,y,depth-1.35+window*1.3),Vector3(.07,.64,.78),0)
                if floor_index%3==1:
                    _box(transforms,2,Vector3(x-side*.16,y-.35,depth),Vector3(.35,.12,4.1),0)
            _box(transforms,1,Vector3(x-side*.04,.65,depth),Vector3(.09,1.1,2.6),0)
    _box(transforms,1,Vector3(0,-.08,-14),Vector3(10.5,.12,44),0)
    for stripe in 15:
        _box(transforms,0,Vector3(-4.4+stripe*.64,-.01,-1.45),Vector3(.34,.025,2.0),0)
    for side in [-1,1]:
        _box(transforms,0,Vector3(side*4.85,.045,-10),Vector3(.35,.12,40),0)
    # Overhead wires are thin geometry, with segment sag rather than a flat overlay.
    for wire in 3:
        for segment in 8:
            var x:float=-5.0+segment*1.4
            var y:float=4.3+wire*.45-.34*sin(float(segment)/7.0*PI)
            _box(transforms,1,Vector3(x,y,-4.0-wire*3.8),Vector3(1.48,.025,.025),0)
    for i in 3:
        var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=colours[i]
        var mesh:=BoxMesh.new();mesh.material=mat
        var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh;mm.instance_count=transforms[i].size()
        for j in mm.instance_count:mm.set_instance_transform(j,transforms[i][j])
        var batch:=MultiMeshInstance3D.new();batch.multimesh=mm;batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        viewport.add_child(batch);batches.append(batch)
func _box(groups:Array,colour:int,at:Vector3,size:Vector3,lean:float) -> void:
    groups[colour].append(Transform3D(Basis(Vector3.FORWARD,lean).scaled(size),at))
