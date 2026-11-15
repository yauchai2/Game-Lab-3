extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"check":label,"passed":ok,"detail":detail});print("RIVET_DROP ",label," ",ok," ",detail)
func run() -> void:
    var actor:=Visual.new();root.add_child(actor);actor.setup(Color.WHITE,1)
    await process_frame;await RenderingServer.frame_post_draw
    for face in [-1,1]:
        var sim:=Sim.new();sim.last_service_enabled=true;sim.arcade_enabled=true;sim.ai_enabled=false
        sim.character_choices=[1,0];sim.reset_round();sim.phase="fight"
        var f:Dictionary=sim.fighters[0];f.x=0;f.face=face;f.meter=100;sim.fighters[1].x=7*face
        sim.tick({"attack":"special","skill_held":true})
        for tick in 44:sim.tick({"skill_held":true})
        check("Hold reaches second tier facing "+str(face),f.service.preload==2)
        f.move_data=sim.move_for(f,"special");f.frame=18;actor.present(f,1.0/60,false,false)
        var raised:Vector3=actor.fx_socket("RightHand")
        f.frame=25
        for settle in 8:actor.present(f,1.0/60,false,false)
        var strike:Vector3=actor.fx_socket("RightHand")
        check("Fist descends from overhead facing "+str(face),raised.y-strike.y>.5,{"raised":str(raised),"strike":str(strike)})
        check("Downstroke is forward facing "+str(face),(strike.x-f.x)*face>.15)
        actor.present(f,1.0/60,false,true)
        check("F2 preserves authored strike facing "+str(face),strike.distance_to(actor.fx_socket("RightHand"))<.002)
        var finite:=true
        for bone in actor.skeleton.get_bone_count():finite=finite and actor.skeleton.get_bone_global_pose(bone).is_finite()
        check("Finite full skeleton facing "+str(face),finite)
        f.frame=7;actor.present(f,1.0/60,false,false);var a:Vector3=actor.fx_socket("RightHand")
        f.frame=8;actor.present(f,1.0/60,false,false)
        check("Held 7/8 does not snap facing "+str(face),a.distance_to(actor.fx_socket("RightHand"))<.002)
        check("Original size and no limb inflation facing "+str(face),actor.oversized_bones.is_empty() and actor.model.scale.is_equal_approx(Vector3.ONE*actor.model_scale))
    actor.queue_free();await process_frame;await RenderingServer.frame_post_draw
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed},"  "))
    call_deferred("quit",0 if failed==0 else 1)
