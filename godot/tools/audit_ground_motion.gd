extends SceneTree
## Explicit setup positions, then ordinary fixed-step commands through the real sim and renderer.
const RUN_CLIPS=["MX_Walking","MX_WalkBack","MX_Run","MX_RunBack","MX_Sprint","KK_Walk","KK_Run","KK_Backstep","Walk_Loop","Jog_Fwd_Loop","Sprint_Loop"]
var session:Node
var rows:Array=[]
var checks:Array=[]
var out:String
var reduced:=false
func frames() -> void:
    await process_frame;await RenderingServer.frame_post_draw
func _initialize() -> void:call_deferred("run")
func run() -> void:
    reduced=OS.get_cmdline_user_args().size()>1
    out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
    session=preload("res://scenes/combat/street_fight.tscn").instantiate();session.preferences_path="";session.city_save_path="";root.add_child(session);session.set_process(false);session.set_physics_process(false);session.audio.muted=true;await frames()
    for hero in 4:
        for scenario in ["forward","stop","reverse","right_wall","body_block","dash_forward","dash_back"]:
            session.return_to_title();session.set_character(0,hero);session.set_character(1,(hero+1)%4);session.start_match(false);session.round_theatre.clear();session.sim.phase="fight";session.sim.ai_enabled=false;session.hud.visible=false;session.reduced_effects=reduced
            var sim=session.sim;var f:Dictionary=sim.fighters[0];var actor:Node3D=session.fighters[0]
            f.x=8 if scenario=="right_wall" else (7.3 if scenario=="body_block" else -3.0)
            sim.fighters[1].x=-7 if scenario=="right_wall" else (8.2 if scenario=="body_block" else 7.0)
            f.face=-1 if scenario=="right_wall" else 1;session.render_motion.clear()
            var total:int=75 if scenario=="body_block" else 48
            var first_hitstop_snapshot:Array=[];var freeze_stable:=true
            for tick in total:
                var command:Dictionary={}
                if scenario in ["forward","right_wall","body_block"]:command={"axis":1.0}
                elif scenario=="stop":command={"axis":1.0} if tick<18 else {}
                elif scenario=="reverse":command={"axis":1.0 if tick<24 else -1.0}
                elif scenario.begins_with("dash") and tick==0:command={"dash":true,"axis":1.0 if scenario=="dash_forward" else -1.0}
                var previous_x:float=f.x;session.render_motion.remember(sim);sim.tick(command);session.render_motion.alpha=1.0
                var frozen:bool=tick in [30,31,32] and scenario=="forward"
                if frozen:sim.hitstop=1
                var before:String=JSON.stringify(sim.fighters);session._present(1.0/60);var pure:bool=before==JSON.stringify(sim.fighters)
                var pose:Dictionary=session.presentation_pose(0)
                var row:={"hero":hero,"scenario":scenario,"tick":tick,"x":f.x,"actual_dx":f.x-previous_x,"requested_vx":f.vx,"pose_vx":pose.vx,"state":f.state,"clip":actor.motions.clip_name,"owner":actor.motions.pose_owner,"phase":actor.motions.profile_loop_elapsed,"pure":pure,"frozen":frozen}
                if tick==30 and scenario=="forward":
                    for bone in actor.skeleton.get_bone_count():first_hitstop_snapshot.append(actor.skeleton.get_bone_pose_rotation(bone))
                if tick in [31,32] and scenario=="forward":
                    for bone in actor.skeleton.get_bone_count():freeze_stable=freeze_stable and first_hitstop_snapshot[bone].is_equal_approx(actor.skeleton.get_bone_pose_rotation(bone))
                rows.append(row)
                var capture_tick:int=7 if scenario.begins_with("dash") else (21 if scenario=="stop" else (27 if scenario=="reverse" else total-1))
                if tick==total-1:
                    var finite:=true
                    for bone in actor.skeleton.get_bone_count():finite=finite and actor.skeleton.get_bone_global_pose(bone).is_finite()
                    checks.append({"name":"finite rig %d %s"%[hero,scenario],"passed":finite})
                if tick==capture_tick:
                    session.camera.global_position=actor.global_position+Vector3(3.8,1.7,5.0);session.camera.look_at(actor.global_position+Vector3(0,.95,0));await frames()
                    root.get_texture().get_image().save_png(out+"hero%d-%s.png"%[hero,scenario])
                if tick%12==0:await process_frame
            if scenario=="forward":checks.append({"name":"hitstop freeze %d"%hero,"passed":freeze_stable})
    checks.append({"name":"all renderer samples preserve simulation","passed":rows.all(func(r:Dictionary)->bool:return r.pure)})
    var blocked:Array=rows.filter(func(r:Dictionary)->bool:return r.scenario in ["right_wall","body_block"] and r.tick>20 and absf(r.actual_dx)<.001 and absf(r.requested_vx)>.3)
    var moving_while_blocked:int=blocked.filter(func(r:Dictionary)->bool:return r.clip in RUN_CLIPS).size()
    FileAccess.open(out+"audit.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"rows":rows,"reduced":reduced,"blocked_samples":blocked.size(),"locomotion_while_blocked":moving_while_blocked,"scope":"4 real hero rigs,7 controlled scenarios, fixed-step semantic input, native render; setup positions explicit, no damage injections. Not human art certification or hardware FPS."},"  "))
    print("GROUND_AUDIT blocked=",blocked.size()," moving=",moving_while_blocked)
    session.return_to_title();session.queue_free()
    for i in 8:await frames()
    quit(0)
