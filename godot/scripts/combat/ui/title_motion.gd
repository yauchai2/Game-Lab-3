extends Node
## Title-only isolated stage: bounded 12 Hz pose/camera animation, no simulation/audio.
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const STEP:=1.0/12.0
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
    viewport=SubViewport.new();viewport.name="TitleStage";viewport.size=Vector2i(376,360)
    viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
    viewport.msaa_3d=Viewport.MSAA_DISABLED;viewport.screen_space_aa=Viewport.SCREEN_SPACE_AA_DISABLED
    add_child(viewport)
    var world:=WorldEnvironment.new();world.environment=Environment.new()
    world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color("950058")
    viewport.add_child(world)
    _city()
    for i in 2:
        var actor:=Visual.new();actor.neon_enabled=true;viewport.add_child(actor);actor.setup(Color.WHITE,0 if i==0 else 2)
        for mat in actor.materials:
            mat.set_shader_parameter("silhouette_preview",true)
            mat.set_shader_parameter("tint",Color("00d6e7") if i==0 else Color("ff008c"))
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
    shot_index=int(time/2.0)%4
    var beat:float=fposmod(time,.5)/.5
    var pulse:float=maxf(0.0,1.0-beat*5.0)
    var sway:float=sin(time*PI)*.045
    for i in 2:
        var actor:Node3D=actors[i]
        var m=actor.motions
        # Retargeted real animation, sampled in held cels rather than smooth interpolation.
        m.present({"character":0 if i==0 else 2,"health":100,"state":"idle","move":"","frame":0,"y":0.0,"vy":0.0,"vx":0.0,"face":1,"guarding":false,"showcase":true},STEP,false)
        var up:Vector3=m.model_up;var forward:Vector3=m.model_forward
        var gesture:bool=(int(time*2.0)+i*2)%8 in [4,5]
        for side in ["Left","Right"]:
            m._aim_limb(side+"Arm",side+"ForeArm",-up+forward*.18,1.0)
            m._aim_limb(side+"ForeArm",side+"Hand",-up*.6+forward*.4,1.0)
        if gesture:
            m._aim_limb("RightArm","RightForeArm",forward*.65+up*.3,1.0)
            m._aim_limb("RightForeArm","RightHand",up-forward*.2,1.0)
        actor.position=Vector3(-.56 if i==0 else .62,-.03+pulse*.025,0.0 if i==0 else -.25)
        actor.rotation=Vector3(0,-.35 if i==0 else -.65,0)
        actor.model.rotation=Vector3(.025*sin(time*PI),0,(-.06 if i==0 else .06)+sway)
    var phase:float=fposmod(time,2.0)/2.0
    var offset:float=[-.10,.22,-.18,.08][shot_index]
    camera.position=Vector3(offset+sin(time*.8)*.06,1.64,3.3)
    camera.look_at(Vector3(offset*.25,1.65,-.10))
    camera.fov=[36.0,32.0,40.0,34.0][shot_index]-pulse*.7+phase*.6
    camera.rotation.z=deg_to_rad([-3.0,5.0,-6.0,2.0][shot_index]+sin(time*1.5)*1.2)
func _city() -> void:
    var colours:Array[Color]=[Color("f4f4f7"),Color("111119"),Color("5c5a69")]
    var transforms:Array=[[],[],[]]
    # Each facade is deliberately uneven, with real depth and lean; three draw batches.
    for side in [-1,1]:
        for block in 6:
            var depth:float=-3.2-block*3.8
            var height:float=7.0+float((block*3+side+8)%5)*1.65
            var x:float=side*(2.1+float(block%2)*.3)
            _box(transforms,0,Vector3(x+side*1.15,height*.5,depth),Vector3(2.3,height,3.35),side*.025)
            for floor_index in int(height/1.0):
                var y:float=.55+floor_index
                for window in 3:
                    _box(transforms,1,Vector3(x-side*.035,y,depth-1.06+window*1.04),Vector3(.07,.58,.62),0)
                if floor_index%3==1:
                    _box(transforms,2,Vector3(x-side*.16,y-.35,depth),Vector3(.35,.12,3.1),0)
            _box(transforms,1,Vector3(x-side*.04,.65,depth),Vector3(.09,1.1,2.6),0)
    _box(transforms,1,Vector3(0,-.08,-9),Vector3(4.5,.12,30),0)
    for stripe in 8:
        _box(transforms,0,Vector3(-1.8+stripe*.5,-.01,-1.45),Vector3(.24,.025,1.0),0)
    for side in [-1,1]:
        _box(transforms,0,Vector3(side*1.95,.045,-10),Vector3(.35,.12,25),0)
    # Overhead wires are thin geometry, with segment sag rather than a flat overlay.
    for wire in 3:
        for segment in 8:
            var x:float=-2.1+segment*.6
            var y:float=4.3+wire*.45-.34*sin(float(segment)/7.0*PI)
            _box(transforms,1,Vector3(x,y,-4.0-wire*3.8),Vector3(.65,.025,.025),0)
    for i in 3:
        var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.albedo_color=colours[i]
        var mesh:=BoxMesh.new();mesh.material=mat
        var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh;mm.instance_count=transforms[i].size()
        for j in mm.instance_count:mm.set_instance_transform(j,transforms[i][j])
        var batch:=MultiMeshInstance3D.new();batch.multimesh=mm;batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        viewport.add_child(batch);batches.append(batch)
func _box(groups:Array,colour:int,at:Vector3,size:Vector3,lean:float) -> void:
    groups[colour].append(Transform3D(Basis(Vector3.FORWARD,lean).scaled(size),at))
