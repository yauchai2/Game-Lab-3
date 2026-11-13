extends SceneTree
## Four real rigs, deterministic presentation fixtures; not a human playtest.
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const ACTIONS=["idle","walk","backward","dash","guard","jab","cross","finisher","heavy","launcher","special","overdrive","grab","air_jab","air_kick","air_finisher","meteor","air_counter","node_pulse","stun","jump","death"]
var actors:Array=[]
var poses:Array=[]
var report:Array=[]
var output:String
func _initialize() -> void:call_deferred("run")
func run() -> void:
    output=OS.get_cmdline_user_args()[0]
    DirAccess.make_dir_recursive_absolute(output)
    var world:=Node3D.new();root.add_child(world)
    var environment:=WorldEnvironment.new();environment.environment=Environment.new()
    environment.environment.background_mode=Environment.BG_COLOR
    environment.environment.background_color=Color("c5c7cc")
    environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color=Color.WHITE
    environment.environment.ambient_light_energy=.8;world.add_child(environment)
    var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-25,0);world.add_child(light)
    var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=12.8;camera.position=Vector3(0,3.4,15);world.add_child(camera)
    camera.look_at(Vector3(0,1.0,3));camera.current=true
    var sim:=Sim.new();sim.last_service_enabled=true
    for character in 4:
        var actor:=Visual.new();world.add_child(actor);actor.setup(Color.WHITE,character)
        actor.neon_enabled=true
        actors.append(actor)
        var pose:Dictionary=sim.fighters[0].duplicate(true);pose.character=character
        pose.x=-4.5+float(character)*3.0;pose.air_enabled=true
        poses.append(pose)
    var actions:Array=ACTIONS
    if OS.get_cmdline_user_args().size()>1:
        var selection:String=OS.get_cmdline_user_args()[1]
        actions=["KK_Guard","KK_Kick","KK_Kick_Mirror","UAL2_Hook","KK_Walk","KK_Backstep","KK_DodgeBack","KK_DodgeForward"] if selection=="sources" else Array(selection.split(","))
    for action in actions:
        var samples:Array=[]
        for character in 4:
            var f:Dictionary=poses[character]
            f.erase("cinematic_clip")
            f.state="idle";f.move="";f.frame=0;f.vx=0.0;f.y=0.0;f.vy=0.0;f.health=100;f.guarding=false
            f.service.preload=0;f.service.preload_age=0;f.air.phase="ground"
            if actors[character].motions.library.clips.has(action):f.cinematic_clip=action
            elif Sim.MOVES.has(action):
                f.state="attack";f.move=action;f.move_data=sim.move_for(f,action)
            elif action=="walk":f.vx=2.5
            elif action=="backward":f.vx=-2.5
            elif action=="dash":f.state="dash"
            elif action=="guard":f.guarding=true
            elif action=="stun":f.state="stun"
            elif action=="jump":f.y=1.0;f.vy=2.0;f.air.phase="rise"
            elif action=="death":f.health=0
            if action.begins_with("air_") or action=="meteor":f.y=1.0;f.air.phase="apex"
            for settle in 8:actors[character].present(f,1.0/60,false,true)
        for tick in 90:
            for character in 4:
                var f:Dictionary=poses[character];f.frame=tick
                var actor:Node3D=actors[character]
                actor.present(f,1.0/60,false,false)
                # Exercise the actual post-sampler signature layer too.
                samples.append({"character":character,"tick":tick,"clip":actor.motions.clip_name,
                    "left_foot":vec(actor.fx_socket("LeftFoot")),"right_foot":vec(actor.fx_socket("RightFoot")),
                    "right_hand":vec(actor.fx_socket("RightHand"))})
            if tick in [0,24,55] or (action in ["air_jab","air_kick","air_finisher","meteor","air_counter","grab"] and tick in [8,14]) or (action in ["special","overdrive","launcher","heavy","jab"] and tick in [5,14,38]):
                await process_frame;await RenderingServer.frame_post_draw
                root.get_texture().get_image().save_png(output+"/"+action+"-%02d.png"%tick)
        report.append({"action":action,"samples":samples})
    FileAccess.open(output+"/samples.json",FileAccess.WRITE).store_string(JSON.stringify({"scope":"State-driven four-rig presentation sweep; fixed roots; neither actual walking input nor hit validation. Feet are bone sockets, not skinned shoe contacts. No hardware FPS claim.","actions":report},"  "))
    world.queue_free();await process_frame;await RenderingServer.frame_post_draw
    quit()
func vec(v:Vector3) -> Array:return [v.x,v.y,v.z]
