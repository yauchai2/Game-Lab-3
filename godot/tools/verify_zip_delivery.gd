extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Motion=preload("res://scripts/combat/last_service/zip_delivery.gd")
var checks:Array=[]
var actor:Node3D
var scene:Node
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":label,"passed":ok,"detail":detail});print("ZIP_DELIVERY ",label," ",ok)
func fresh(face:=1,distance:=2.2) -> RefCounted:
    var s:=Sim.new();s.last_service_enabled=true;s.arcade_enabled=true;s.ai_enabled=false;s.character_choices=[0,1];s.reset_round();s.phase="fight"
    s.fighters[0].x=0;s.fighters[1].x=distance*face;s.fighters[0].face=face;s.fighters[1].face=-face;s.fighters[0].meter=100
    return s
func execute(s:RefCounted,guard:=false,interrupt:=false,escape:=false) -> Array:
    var hits:Array=[]
    s.tick({"attack":"overdrive"},{"guard":guard,"allow_parry":false})
    check("One normal 75-energy payment",s.fighters[0].meter==25)
    for tick in 230:
        if not hits.is_empty() and interrupt:s.fighters[0].state="stun";s.fighters[0].stun=120;interrupt=false
        if not hits.is_empty() and escape:s.fighters[1].x=7*s.fighters[0].face;escape=false
        s.tick({}, {"guard":guard,"allow_parry":false})
        for event in s.events:
            if event.kind=="hit" and event.attacker==0:
                hits.append({"frame":s.fighters[0].frame,"stage":s.fighters[0].service.delivery_stage,"ricochet":s.move_for(s.fighters[0],"overdrive").ricochet,"damage":event.damage})
    return hits
func run() -> void:
    for face in [-1,1]:
        var sim:RefCounted=fresh(face);var hits:Array=execute(sim)
        check("Three real ordered hits facing %d"%face,hits.size()==3 and hits.map(func(h:Dictionary)->int:return h.stage)==[0,1,2],hits)
        check("Two independent confirmation delays facing %d"%face,hits.size()==3 and hits[1].frame-hits[0].frame==Motion.DELAYS[0] and hits[2].frame-hits[1].frame==Motion.DELAYS[1])
        check("Only final heel drive opens ricochet %d"%face,hits.size()==3 and not hits[0].ricochet and not hits[1].ricochet and hits[2].ricochet)
        check("Original bounded three-hit damage %d"%face,sim.fighters[1].health>=59 and sim.fighters[1].health<75,sim.fighters[1].health)
        check("Approach is bounded and has no free invulnerability %d"%face,absf(sim.fighters[0].x)<1.5 and sim.fighters[0].invuln==0,sim.fighters[0].x)
        sim=fresh(face,7);hits=execute(sim)
        check("Out-of-range run never homes or invents hits %d"%face,hits.is_empty() and sim.fighters[1].health==100 and sim.fighters[0].service.delivery_stage==0)
        sim=fresh(face);hits=execute(sim,true)
        check("Blocking prevents confirmed followups %d"%face,hits.is_empty() and sim.fighters[1].health==100 and sim.fighters[0].service.delivery_stage==0)
        sim=fresh(face);hits=execute(sim,false,true)
        check("Interruption cancels remaining kicks %d"%face,hits.size()==1)
        sim=fresh(face);hits=execute(sim,false,false,true)
        check("Second whiff never arms the final kick %d"%face,hits.size()==1 and sim.fighters[0].service.delivery_stage==1)
    var delayed:RefCounted=fresh(1,7);delayed.tick({"attack":"overdrive"})
    for tick in 60:
        if delayed.fighters[0].frame==30:delayed.fighters[1].x=delayed.fighters[0].x+1.3
        delayed.tick()
    check("Run and recovery do not contain invisible hitboxes",delayed.fighters[1].health==100)
    actor=preload("res://scripts/combat/fighter_visual.gd").new();root.add_child(actor);actor.neon_enabled=true;actor.setup(Color.WHITE,0)
    await process_frame;await RenderingServer.frame_post_draw
    var sim:RefCounted=fresh();var f:Dictionary=sim.fighters[0]
    sim._start_attack(0,"overdrive");f.air_enabled=true;f.rush_visual=true
    for tick in 8:sim.tick()
    for i in 3:actor.present(f,1.0/60,false,false)
    check("Startup uses full-body running source",actor.motions.clip_name=="KK_Run")
    for stage in 3:
        f.service.delivery_stage=stage;f.service.delivery_contact=24+stage*12;f.service.followup=0;f.frame=f.service.delivery_contact
        for i in 3:actor.present(f,1.0/60,false,false)
        check("Contact limb matches stage %d"%stage,preload("res://scripts/combat/ink_fx/fx_recipes.gd").limb("overdrive",0,f)==("LeftFoot" if stage==1 else "RightFoot"))
        var valid:=true
        for bone in actor.skeleton.get_bone_count():valid=valid and actor.skeleton.get_bone_global_pose(bone).is_finite()
        var foot:Vector3=actor.fx_socket("LeftFoot" if stage==1 else "RightFoot")
        actor.present(f,1.0/60,true,true)
        check("Finite stable F2/hitstop pose %d"%stage,valid and foot.distance_to(actor.fx_socket("LeftFoot" if stage==1 else "RightFoot"))<.001)
    var pose_snapshot:String=JSON.stringify(sim.fighters);actor.present(f,1.0/60,false,false)
    check("Rendering does not modify simulation",pose_snapshot==JSON.stringify(sim.fighters))
    actor.queue_free();actor=null
    for i in 6:await process_frame
    await RenderingServer.frame_post_draw
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path="";scene.progression_path=""
    root.add_child(scene);scene.set_process(false);scene.set_physics_process(false)
    await process_frame;await RenderingServer.frame_post_draw
    scene.set_character(0,0);scene.set_character(1,1);scene.start_match(true);scene.round_theatre.clear();scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=-1.1;scene.sim.fighters[1].x=1.1;scene.sim.fighters[0].meter=100
    scene.pending={"attack":"overdrive"};scene._physics_process(1.0/60);scene._process(1.0/60)
    check("Normal session routes the overdrive to dedicated VFX",scene.effects.any(func(e:Dictionary)->bool:return e.kind=="swing" and e.get("zip_delivery",false)))
    check("Reference choreography avoids generic red stage and cannon",not scene.theatre.active() and not scene.neon.active() and scene.effects.filter(func(e:Dictionary)->bool:return e.kind=="cannon_charge").all(func(e:Dictionary)->bool:return e.get("zip_delivery",false)))
    var frozen:Array=scene.effects.map(func(e:Dictionary)->float:return e.age)
    scene.pause_game();scene._process(.15)
    check("Pause freezes the run and attack effects",frozen==scene.effects.map(func(e:Dictionary)->float:return e.age))
    scene.resume_game()
    for tick in 260:
        scene._physics_process(1.0/60);scene._process(1.0/60)
        if scene.effects.any(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("zip_delivery",false) and e.get("delivery_stage",-1)==2):break
    check("Final fan comes from a genuine stage-two contact",scene.effects.any(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("zip_delivery",false) and e.get("delivery_stage",-1)==2))
    scene.sim.fighters[0].state="stun";scene.sim.fighters[0].stun=30;scene._process(1.0/60)
    check("Interruption removes active shoe smears and windups",not scene.effects.any(func(e:Dictionary)->bool:return e.get("zip_delivery",false) and e.kind in ["swing","charge","cannon_charge"]))
    scene.reduced_effects=true;scene._process(.016)
    check("F2 clears decorative smoke and trails",scene.ink_fx.active_count()==0 and scene.ink_fx.traces.is_empty())
    scene.return_to_title()
    check("Exit clears delivery effects",scene.effects.is_empty() and scene.ink_fx.traces.is_empty())
    await process_frame;await RenderingServer.frame_post_draw
    scene.queue_free();scene=null
    for i in 8:await process_frame
    await RenderingServer.frame_post_draw
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed},"  "))
    call_deferred("quit",0 if failed==0 else 1)
