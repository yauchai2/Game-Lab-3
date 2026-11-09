extends SceneTree
const Rhythm=preload("res://scripts/combat/combat_rhythm.gd")
var checks:Array[Dictionary]=[]
var scene:Node
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("RHYTHM FAIL: "+label)
func step() -> void:scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
func run() -> void:
    var t:=Rhythm.new()
    for kind in Rhythm.PROFILES:
        t.clear();t.trigger(kind,1)
        var phases:={};var rates:={};var max_steps:=0
        for i in 120:
            var count:=t.take_steps(1.0/60,true);max_steps=maxi(max_steps,count)
            phases[t.phase()]=true;rates[t.rate_now]=true
        check(kind+" has hold slow release and normal flow",phases.has("hold") and phases.has("slow") and phases.has("release") and phases.has("flow"))
        check(kind+" uses a bounded shared clock",max_steps<=2 and rates.has(0.0) and rates.has(.22) and not t.active())
    t.trigger("break",0);t.trigger("skill",1)
    check("weaker events cannot restart a dramatic hold",t.kind=="break" and t.owner==0)
    check("reduced effects immediately returns to one normal step",t.take_steps(1.0/60,false)==1 and not t.active() and t.bank==0 and t.rate_now==1)
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path=""
    root.add_child(scene);current_scene=scene;scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    await process_frame;await process_frame
    scene.set_character(0,3);scene.set_character(1,0)
    scene._process(.01)
    check("goggle fighter is exactly one third shorter",is_equal_approx(scene.fighters[0].model_scale/scene.fighters[1].model_scale,2.0/3.0))
    scene.start_match(false);scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=-.5;scene.sim.fighters[1].x=.5;scene.pending.attack="special";step()
    check("paid skill opens a full second red cut and hold",scene.theatre.mode=="skill" and scene.theatre.duration==1 and scene.rhythm.phase()=="hold" and scene.sim.fighters[0].meter==10)
    var tick:int=scene.sim.tick_count
    var snapshot:Array=scene.sim.fighters.duplicate(true)
    scene.pending.attack="launcher";scene.pending.guard_pressed=true
    for i in 5:step()
    check("hold really stops both fighters and the simulation clock",scene.sim.tick_count==tick and scene.sim.fighters==snapshot)
    check("input received during the hold stays pending",scene.pending.get("attack","")=="launcher" and scene.pending.get("guard_pressed",false))
    var age:float=scene.rhythm.age
    var red_age:float=scene.theatre.age
    scene.pause_game()
    for i in 30:step()
    check("pause freezes both choreography clocks",scene.rhythm.age==age and scene.theatre.age==red_age)
    scene.resume_game()
    var observed:={};var roll:=0.0;var honest:=true
    var previous_tick:int=scene.sim.tick_count
    for i in 160:
        step();observed[scene.rhythm.rate_now]=true;roll=maxf(roll,absf(scene.camera.rotation.z))
        honest=honest and scene.sim.tick_count-previous_tick<=2
        previous_tick=scene.sim.tick_count
    check("live scene actually slows and accelerates",observed.has(.22) and observed.keys().any(func(rate:float)->bool:return rate>1.5))
    check("cinematic camera performs visible bounded rotation",roll>deg_to_rad(5) and roll<deg_to_rad(13))
    check("accelerated frames never skip more than two fixed steps",honest)
    scene.reduced_effects=true;step()
    check("F2 clears the tempo and red environment",not scene.rhythm.active() and scene.rhythm.rate_now==1 and scene.camera.environment==null and scene.backdrop.visible)
    scene.reduced_effects=false;scene.return_to_title()
    check("title clears the pacing accumulator",not scene.rhythm.active() and scene.rhythm.bank==0)
    scene.set_character(0,3);scene.set_character(1,2);scene.start_demo()
    var phases:={};var red_frames:=0;var field_frames:=0;var max_effects:=0
    for i in 1800:
        step();phases[scene.rhythm.phase()]=phases.get(scene.rhythm.phase(),0)+1
        if scene.theatre.active():red_frames+=1
        else:field_frames+=1
        max_effects=maxi(max_effects,scene.effects.size())
    check("live demo retains quiet and dramatic intervals",field_frames>180 and red_frames>180 and phases.has("flow") and phases.has("release"))
    check("slow-motion demo stays alive and both sides hit",scene.screen=="play" and scene.sim.phase=="fight" and scene.demo.hits[0]>10 and scene.demo.hits[1]>10)
    check("extra full-screen effects remain bounded",max_effects<=64)
    scene.return_to_title();scene.queue_free();await process_frame;await process_frame
    var passed:=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open("res://../docs/evidence/combat-rhythm/verification.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"phase_frames":phases,"red_frames":red_frames,"street_frames":field_frames,"max_effects":max_effects,"scope":"Fixed-step native engine input/state/camera checks; no human fun score or target GPU claim."},"  "))
    print("RHYTHM_CHECKS ",passed,"/",checks.size());call_deferred("quit",0 if passed==checks.size() else 1)
