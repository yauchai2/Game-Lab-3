extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Motion=preload("res://scripts/combat/last_service/zip_express.gd")
var checks:Array=[]
var scene:Node
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":label,"passed":ok,"detail":detail});print("ZIP_REFERENCE ",label," ",ok)
func fresh(face:=1,distance:=1.3) -> RefCounted:
    var s:=Sim.new();s.last_service_enabled=true;s.arcade_enabled=true;s.ai_enabled=false;s.character_choices=[0,0];s.reset_round();s.phase="fight"
    s.fighters[0].x=0;s.fighters[1].x=distance*face;s.fighters[0].face=face;s.fighters[1].face=-face;s.fighters[0].meter=100
    return s
func contacts(s:RefCounted,guard:=false,interrupt:=false,escape:=false) -> Array:
    var hits:Array=[]
    s.tick({"attack":"special"},{"guard":guard,"allow_parry":false})
    for tick in 180:
        if not hits.is_empty() and interrupt:s.fighters[0].state="stun";s.fighters[0].stun=80;interrupt=false
        if not hits.is_empty() and escape:s.fighters[1].x=7;escape=false
        s.tick({}, {"guard":guard,"allow_parry":false})
        for event in s.events:
            if event.kind=="hit" and event.attacker==0:hits.append({"frame":s.fighters[0].frame,"second":s.fighters[0].service.zip_second,"damage":event.damage})
    return hits
func run() -> void:
    for face in [-1,1]:
        var sim:RefCounted=fresh(face);var hits:Array=contacts(sim)
        check("Two real contacts facing %d"%face,hits.size()==2,hits)
        check("Plant and pivot separate contacts facing %d"%face,hits.size()==2 and hits[1].frame-hits[0].frame==Motion.FOLLOWUP_DELAY)
        check("Normal cost and bounded damage facing %d"%face,sim.fighters[0].meter>=50 and sim.fighters[1].health>=78 and sim.fighters[1].health<90)
        sim=fresh(face,7);hits=contacts(sim)
        check("Whiff never invents contact or second kick %d"%face,hits.is_empty() and not sim.fighters[0].service.zip_second and sim.fighters[0].meter==50)
        sim=fresh(face);hits=contacts(sim,true)
        check("Block prevents hit-confirm followup %d"%face,hits.is_empty() and not sim.fighters[0].service.zip_second and sim.fighters[1].health==100)
        sim=fresh(face);hits=contacts(sim,false,true)
        check("Interruption stops confirmed followup %d"%face,hits.size()==1)
        sim=fresh(face);hits=contacts(sim,false,false,true)
        check("Second kick still checks distance %d"%face,hits.size()==1)
    for enter_frame in [15,22]:
        var late:RefCounted=fresh(1,7)
        late.tick({"attack":"special"})
        var late_hits:Array=[]
        for tick in 160:
            if late.fighters[0].state=="attack" and late.fighters[0].frame==enter_frame:late.fighters[1].x=1.3
            late.tick()
            for event in late.events:
                if event.kind=="hit" and event.attacker==0:late_hits.append(late.fighters[0].frame)
        if enter_frame==15:
            check("Late first contact keeps its actual second-contact frame",late_hits.size()==2 and late_hits[1]-late_hits[0]==Motion.FOLLOWUP_DELAY and int(late.fighters[0].service.zip_second_at)==late_hits[1],late_hits)
        else:check("Entering during the planted turn cannot hit invisibly",late_hits.is_empty(),late_hits)
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path="";scene.progression_path=""
    root.add_child(scene);scene.set_process(false);scene.set_physics_process(false)
    await process_frame
    await RenderingServer.frame_post_draw
    scene.set_character(0,0);scene.set_character(1,0);scene.start_match(true);scene.round_theatre.clear();scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=0;scene.sim.fighters[1].x=1.3;scene.sim.fighters[0].meter=100
    var actual:Array=[]
    scene.pending={"attack":"special"}
    for tick in 170:
        scene._combat_step();scene._process(1.0/60)
        for e in scene.sim.events:
            if e.kind=="hit" and e.attacker==0:actual.append(e.duplicate())
        if scene.effects.any(func(e:Dictionary)->bool:return e.get("zip_express",false) and e.kind=="hit"):
            check("True hit uses ZIP-specific burst",scene.effects.any(func(e:Dictionary)->bool:return e.get("zip_express",false) and e.kind=="hit"))
            break
    check("Reference skill avoids generic charge stage",not scene.theatre.active() and not scene.neon.active() and scene.spectacle.mode!="charge")
    var snapshot:String=JSON.stringify(scene.sim.fighters)
    for i in 4:scene._present(1.0/60)
    check("Pose rendering does not write simulation",snapshot==JSON.stringify(scene.sim.fighters))
    var ages:Array=scene.effects.map(func(e:Dictionary)->float:return e.age)
    scene.pause_game();scene._process(.1)
    check("Pause freezes effect phases",ages==scene.effects.map(func(e:Dictionary)->float:return e.age))
    scene.resume_game();scene.reduced_effects=true;scene._process(.016)
    check("F2 clears decorative dust and ribbons",scene.ink_fx.active_count()==0 and scene.ink_fx.traces.is_empty())
    scene.return_to_title()
    check("Exit clears attack effects and trails",scene.effects.is_empty() and scene.ink_fx.traces.is_empty())
    scene.set_character(1,2);scene.start_match(true);scene.round_theatre.clear();scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=0;scene.sim.fighters[1].x=1.3;scene.sim.fighters[0].meter=100;scene.reduced_effects=false
    scene.sim.tick({"attack":"special"})
    for e in scene.sim.events:scene._handle_event(e)
    var parried:=false
    for tick in 18:
        scene.sim.tick({}, {"guard":tick>=11,"allow_parry":true})
        for e in scene.sim.events:
            scene._handle_event(e)
            if e.kind=="parry":parried=true
    check("Parrying ZIP retains the defender's PARRY presentation",parried and scene.neon.mode=="PARRY")
    scene.return_to_title()

    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed},"  "))
    await process_frame
    await RenderingServer.frame_post_draw
    scene.queue_free()
    for i in 8:await process_frame
    await RenderingServer.frame_post_draw
    call_deferred("quit",1 if failed else 0)
