extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const Recipes=preload("res://scripts/combat/ink_fx/fx_recipes.gd")
var actor:Node3D
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"check":label,"pass":ok,"detail":detail});print("COUNTER_MOTION ",label," ",ok," ",detail)
func fresh(character:int,opponent_x:=1.1) -> RefCounted:
    var sim:=Sim.new();sim.last_service_enabled=true;sim.arcade_enabled=true;sim.ai_enabled=false
    sim.character_choices=[character,0];sim.reset_round();sim.phase="fight"
    sim.fighters[0].x=0;sim.fighters[1].x=opponent_x;sim.fighters[0].meter=100
    return sim
func present(f:Dictionary,stopped:=false,reduced:=false) -> void:
    var pose:Dictionary=f.duplicate(true);pose.air_enabled=true;pose.rush_visual=true
    actor.present(pose,1.0/60,stopped,reduced)
func stable(f:Dictionary) -> void:
    for tick in 8:present(f)
func step(sim:RefCounted,a:Dictionary={},b:Dictionary={}) -> void:
    sim.tick(a,b);present(sim.fighters[0],sim.hitstop>0)
func run() -> void:
    actor=Visual.new();root.add_child(actor);actor.neon_enabled=true
    for character in [2,3]:
        actor.setup(Color.WHITE,character)
        var sim:RefCounted=fresh(character);var f:Dictionary=sim.fighters[0]
        var actions:Array=["jab","cross","heavy","finisher","launcher","special","overdrive"]
        if character==3:actions.append("node_pulse")
        for action in actions:
            sim=fresh(character);f=sim.fighters[0]
            if action=="node_pulse":f.service.nodes=[{"x":1.2,"life":300,"id":1}]
            sim._start_attack(0,action)
            check("Pose fixture started a valid attack %d/%s"%[character,action],f.state=="attack" and f.move==action)
            f.move_data=sim.move_for(f,action)
            for face in [-1,1]:
                f.face=face;f.frame=f.move_data.startup
                var snapshot:String=JSON.stringify(sim.fighters)
                stable(f)
                var finite:=true
                for bone in actor.skeleton.get_bone_count():finite=finite and actor.skeleton.get_bone_global_pose(bone).is_finite()
                check("Full grounded pose %d/%s/%d"%[character,action,face],finite and actor.motions.pose_owner==("hush_intercept" if character==2 else "loop_baton") and actor.oversized_bones.is_empty())
                var label:String=Recipes.limb(action,character,f)
                var socket:Vector3=actor.fx_socket(label);present(f,true,true)
                check("Hitstop/F2 and simulation isolation %d/%s/%d"%[character,action,face],socket.distance_to(actor.fx_socket(label))<.001 and JSON.stringify(sim.fighters)==snapshot)
                if character==3:
                    check("Baton tip follows hand %s/%d"%[action,face],label=="BatonTip" and absf(actor.fx_socket("BatonTip").distance_to(actor.fx_socket("RightHand"))-actor.baton_tip.position.length()*actor.model_scale)<.002)
        sim=fresh(character);f=sim.fighters[0]
        for velocity in [-2.5,2.5,5.0]:
            f.vx=velocity;stable(f)
            var expected:String="KK_Backstep" if velocity<0 else ("KK_Run" if velocity>4 else "KK_Walk")
            check("Guarded locomotion %d/%s"%[character,expected],actor.motions.clip_name==expected)
        f.vx=0;f.guarding=true;stable(f)
        check("Distinct guard %d"%character,actor.motions.clip_name==("Punch_Enter" if character==2 else "KK_StickGuard"))
        f.state="blockstun";f.stun=8;stable(f)
        var at:Vector3=actor.fx_socket("RightHand")
        for tick in 8:present(f,true)
        check("Block recoil freezes with hitstop %d"%character,actor.motions.pose_owner!="legacy" and at.distance_to(actor.fx_socket("RightHand"))<.001)
        f.state="stun";present(f)
        check("Hit interruption releases pose %d"%character,actor.motions.pose_owner=="legacy")
        f.state="idle";f.y=1;present(f)
        check("Air retains its owner %d"%character,actor.motions.pose_owner=="legacy")
        f.y=0;f.air.phase="land";f.air.land=4;present(f)
        check("Landing retains its owner %d"%character,actor.motions.pose_owner=="legacy")
        f.air.phase="ground";f.health=0;present(f)
        check("Death retains its owner %d"%character,actor.motions.clip_name=="Death01" and actor.motions.air_pose_name=="")
        f.health=100;f.showcase=true;present(f)
        check("Showcase retains its owner %d"%character,actor.motions.pose_owner=="legacy")
    actor.setup(Color.WHITE,2)
    var sim:RefCounted=fresh(2);var f:Dictionary=sim.fighters[0]
    step(sim,{"guard":true,"guard_pressed":true},{"attack":"jab"})
    var parries:=0
    for tick in 24:
        step(sim,{"guard":true})
        for event in sim.events:
            if event.kind=="parry":parries+=1
    check("Normal frontal parry earns a real sample",parries==1 and f.service.sample==1,{"parries":parries,"sample":f.service.sample})
    for tick in 12:step(sim)
    var minimum_x:float=f.x;var spent:=0;var hits:=0
    step(sim,{"attack":"special"})
    for event in sim.events:
        if event.kind=="sample_spent":spent+=1
    for tick in 100:
        step(sim);minimum_x=minf(minimum_x,f.x)
        for event in sim.events:
            if event.kind=="hit" and event.attacker==0:hits+=1
    check("Sample counter retreats and consumes once on real attack",minimum_x<-.05 and spent==1 and hits==1 and f.service.sample==0,{"minimum_x":minimum_x,"spent":spent,"hits":hits})
    check("Retreat has no opposing model lunge",actor.model.position.z==0)
    actor.setup(Color.WHITE,3)
    sim=fresh(3,1.8);f=sim.fighters[0]
    var placements:=0;var hands:Array=[]
    for far in [true,false]:
        step(sim,{"attack":"special","axis":1.0 if far else 0.0})
        for tick in 55:
            step(sim)
            for event in sim.events:
                if event.kind=="node_placed":placements+=1;hands.append(actor.fx_socket("RightHand")-actor.global_position)
    check("Two directional placements create nodes without a body hit",placements==2 and f.service.nodes.size()==2 and sim.fighters[1].health==100)
    check("Near/far placement gestures are different",hands.size()==2 and hands[0].distance_to(hands[1])>.05,hands.map(func(v:Vector3)->String:return str(v)))
    var pulses:=0
    step(sim,{"attack":"special","down":true})
    for tick in 65:
        step(sim)
        for event in sim.events:
            if event.kind=="node_pulse_fx":pulses+=1
    check("Manual pulse consumes real nodes and damages through rules",pulses==1 and f.service.nodes.is_empty() and sim.fighters[1].health<100,{"pulses":pulses,"hp":sim.fighters[1].health})
    for count in [0,1,2]:
        sim=fresh(3);f=sim.fighters[0]
        # Explicit initial node fixtures cover all encore presentation variants.
        for index in count:f.service.nodes.append({"x":1.0+float(index)*.2,"life":300,"id":index})
        step(sim,{"attack":"overdrive"});pulses=0
        for tick in 150:
            step(sim)
            for event in sim.events:
                if event.kind=="node_pulse_fx":pulses+=1
        check("Encore %d uses exactly the existing node count"%count,pulses==count and f.service.nodes.is_empty(),pulses)
    sim=fresh(3);f=sim.fighters[0];stable(f)
    await process_frame;await RenderingServer.frame_post_draw
    check("Rendered baton marker matches a real palm grip",actor.baton_tip.global_position.distance_to(actor.fx_socket("BatonTip"))<.002 and (actor.baton_tip.position-Vector3(0,.145,0)).length()>.001)
    actor.setup(Color.WHITE,2)
    check("Character replacement clears baton marker",actor.baton_tip==null)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.pass).size()
    FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"scope":"Two real rigs, explicit pose/encore fixtures and normal input parry/placement/pulse rules. Neither human art approval nor terrain foot IK validation."},"  "))
    actor.queue_free();await process_frame;await RenderingServer.frame_post_draw;quit(1 if failed else 0)
