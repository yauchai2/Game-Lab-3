extends SceneTree
const Motion=preload("res://scripts/combat/last_service/rivet_shutdown.gd")
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"check":label,"passed":ok,"detail":detail});print("SHUTDOWN ",label," ",ok," ",detail)
func run() -> void:
    var s=preload("res://scenes/combat/street_fight.tscn").instantiate()
    s.preferences_path="";s.progression_path="";root.add_child(s)
    s.set_process(false);s.set_physics_process(false)
    await process_frame;await RenderingServer.frame_post_draw
    for face in [-1,1]:
        s.return_to_title();s.set_character(0,1);s.set_character(1,0);s.start_match(true);s.round_theatre.clear()
        s.sim.phase="fight";s.sim.ai_enabled=false
        var f:Dictionary=s.sim.fighters[0];f.x=0;f.face=face;f.meter=100;s.sim.fighters[1].x=7*face
        s.sim.tick({"attack":"overdrive"});f.move_data=s.sim.move_for(f,"overdrive")
        var actor:Node3D=s.fighters[0]
        f.frame=24
        for tick in 8:actor.present(f,1.0/60,false,false)
        var chamber:Vector3=actor.fx_socket("RightHand")
        f.frame=f.move_data.startup
        for tick in 8:actor.present(f,1.0/60,false,false)
        var fist:Vector3=actor.fx_socket("RightHand")
        var elbow:Vector3=actor.fx_socket("RightForeArm")
        check("Straight source facing "+str(face),actor.motions.clip_name=="Punch_Cross" and Motion.owns(f))
        check("Fist drives forward from chamber facing "+str(face),(fist.x-chamber.x)*face>.35,{"chamber":str(chamber),"fist":str(fist)})
        check("Forearm travels horizontally facing "+str(face),(fist.x-elbow.x)*face>.15 and absf(fist.y-elbow.y)<.15)
        actor.present(f,1.0/60,false,true)
        check("F2 keeps identical punch facing "+str(face),fist.distance_to(actor.fx_socket("RightHand"))<.002)
        var finite:=true
        for bone in actor.skeleton.get_bone_count():finite=finite and actor.skeleton.get_bone_global_pose(bone).is_finite()
        check("Finite skeleton facing "+str(face),finite)
        check("No geometry inflation facing "+str(face),actor.oversized_bones.is_empty())
    for scenario in ["hit","whiff","block"]:
        s.return_to_title();s.start_match(true);s.round_theatre.clear();s.sim.phase="fight";s.sim.ai_enabled=false
        s.sim.fighters[0].x=-1.0;s.sim.fighters[1].x=1.0 if scenario!="whiff" else 7.0
        s.sim.fighters[0].meter=100
        s.pending={"attack":"overdrive"}
        var links:=0;var walls:=0;var max_stop:=0;var initial_health:int=s.sim.fighters[1].health
        var seen_links:Dictionary={};var seen_walls:Dictionary={}
        # Contact proof uses health/effects below; no manually injected hit event.
        for tick in 180:
            if scenario=="block":s.versus=true;s.controls.set_mode("versus");s.controls.keys[KEY_KP_5]=true;s.sim.fighters[1].parry_allowed=false
            s._physics_process(1.0/60);s._process(1.0/60)
            max_stop=maxi(max_stop,s.sim.hitstop)
            for e:Dictionary in s.effects:
                if e.kind=="rivet_link":seen_links[e.serial]=true
                if e.kind=="rivet_wall":seen_walls[str(e.at)]=true
        links=seen_links.size();walls=seen_walls.size()
        if scenario=="hit":
            check("True hit emits one link",links==1)
            check("Actual first wall emits custom blast",walls==1,walls)
            check("Real hit damages opponent",s.sim.fighters[1].health<initial_health)
            check("No native skill freeze",max_stop==0,max_stop)
        elif scenario=="whiff":
            check("Whiff creates no link or wall blast",links==0 and walls==0)
            check("Whiff has no damage",s.sim.fighters[1].health==initial_health)
        else:
            check("Block creates no link or wall blast",links==0 and walls==0,{"links":links,"walls":walls})
        s.screen="pause";var saved:Array=s.effects.duplicate(true);s._process(.2)
        check(scenario+" pause preserves effects",s.effects==saved)
        s.return_to_title()
        check(scenario+" restart clears effects",s.effects.is_empty())
    s.queue_free();s=null
    for settle in 8:await process_frame
    await RenderingServer.frame_post_draw
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed},"  "))
    call_deferred("quit",1 if failed else 0)
