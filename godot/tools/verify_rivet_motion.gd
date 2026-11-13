extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
var checks:Array=[]
var actor:Node3D
func _initialize() -> void:call_deferred("run")
func check(label:String,passed:bool,detail:Variant=null) -> void:
    checks.append({"check":label,"pass":passed,"detail":detail})
    print("RIVET_MOTION ",label," ",passed," ",detail)
func present(f:Dictionary,reduced:=false,stopped:=false) -> void:
    f.air_enabled=true;f.rush_visual=true
    actor.present(f,1.0/60,stopped,reduced)
func feet() -> Array:return [actor.fx_socket("LeftFoot")-actor.global_position,actor.fx_socket("RightFoot")-actor.global_position]
func distance(a:Array,b:Array) -> float:return maxf(a[0].distance_to(b[0]),a[1].distance_to(b[1]))
func fresh() -> RefCounted:
    var sim:=Sim.new();sim.last_service_enabled=true;sim.arcade_enabled=true;sim.ai_enabled=false
    sim.character_choices=[1,0];sim.reset_round();sim.phase="fight"
    sim.fighters[0].x=0;sim.fighters[1].x=7;sim.fighters[0].meter=100
    for tick in 8:present(sim.fighters[0])
    return sim
func run() -> void:
    actor=Visual.new();root.add_child(actor);actor.neon_enabled=true;actor.setup(Color.WHITE,1)
    var sim:RefCounted=fresh()
    check("Idle uses the library boxing guard",actor.motions.clip_name=="Punch_Enter" and actor.motions.pose_owner=="rivet_boxing")
    for action in ["jab","cross","heavy","finisher","special"]:
        sim=fresh();sim._start_attack(0,action)
        var f:Dictionary=sim.fighters[0];var move:Dictionary=sim.move_for(f,action)
        var anchor:Array=[];var excursion:=0.0;var finite:=true
        for tick in int(move.startup+move.active+move.recovery):
            f.frame=tick;f.move_data=move;present(f)
            if tick==5:anchor=feet()
            if tick>5:excursion=maxf(excursion,distance(anchor,feet()))
            for bone in actor.skeleton.get_bone_count():finite=finite and actor.skeleton.get_bone_global_pose(bone).is_finite()
        check(action+" retains a planted stance and finite bones",excursion<.002 and finite,excursion)
        check(action+" has no legacy sword/kick or active limb inflation",actor.motions.clip_name in ["Punch_Jab","Punch_Cross"] and actor.oversized_bones.is_empty() and actor.model.scale.is_equal_approx(Vector3.ONE*actor.model_scale))
    sim=fresh();sim.tick({"attack":"special","skill_held":true})
    var f:Dictionary=sim.fighters[0];var held:Array=[];var charge_reach:=0.0;var release_reach:=-INF
    for tick in 36:
        sim.tick({"skill_held":true});present(f)
        if f.frame in [7,8] and f.service.preload==0:held.append(actor.fx_socket("RightHand"))
        charge_reach=actor.fx_socket("RightHand").x
    for tick in 70:
        sim.tick();present(f)
        if f.state=="attack" and f.frame>=sim.move_for(f,"special").startup and f.frame<sim.move_for(f,"special").startup+sim.move_for(f,"special").active:
            release_reach=maxf(release_reach,actor.fx_socket("RightHand").x)
    check("Held attack charges tier two and releases the fist forward",f.service.preload==2 and release_reach>charge_reach+.1,{"charge_x":charge_reach,"release_x":release_reach})
    check("Charge frame 7/8 does not alternate poses",held.size()>=2 and held[0].distance_to(held[1])<.002)
    for face in [-1,1]:
        sim=fresh();f=sim.fighters[0];f.face=face;sim._start_attack(0,"special");f.frame=24;f.move_data=sim.move_for(f,"special")
        for tick in 8:present(f)
        var normal:Vector3=actor.fx_socket("RightHand")
        present(f,true);var reduced:Vector3=actor.fx_socket("RightHand")
        for tick in 12:present(f,false,true)
        check("F2 and hitstop preserve the fist on facing "+str(face),normal.distance_to(reduced)<.001 and normal.distance_to(actor.fx_socket("RightHand"))<.001)
    f.state="stun";present(f)
    check("Interruption relinquishes the boxing owner",actor.motions.pose_owner=="legacy")
    f.health=0;present(f)
    check("Death retains its original exclusive pose",actor.motions.clip_name=="Death01" and actor.motions.air_pose_name=="")
    sim=fresh();f=sim.fighters[0];f.y=1;f.state="attack";f.move="meteor";f.move_data=sim.move_for(f,"meteor");present(f)
    check("Air attacks keep the existing aerial route",actor.motions.pose_owner=="legacy")
    f.y=0;f.state="idle";f.showcase=true;present(f)
    check("Showcase keeps its independent director",actor.motions.pose_owner=="legacy")
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.pass).size()
    var args:=OS.get_cmdline_user_args();var output:String=args[0]
    FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"passed":checks.size()-failed,"scope":"Real rigs, valid simulation charge/release plus explicit pose fixtures; bone feet only, not terrain IK or human quality proof."},"  "))
    actor.queue_free();await process_frame;await RenderingServer.frame_post_draw
    quit(1 if failed else 0)
