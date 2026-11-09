extends SceneTree
const Theatre=preload("res://scripts/combat/impact_theatre.gd")
var scene:Node
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("RED THEATRE FAIL: "+label)
func step(n:=1) -> void:
    for i in n:scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
func setup() -> void:
    scene.start_match(false);scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=-.5;scene.sim.fighters[1].x=.5
func run() -> void:
    var t:=Theatre.new();t.begin("skill",0);t.advance(.10,false)
    check("skill cut has a short finite lifespan",t.active())
    var age:float=t.age;t.advance(.5,true)
    check("pause freezes the visual clock",t.age==age)
    t.advance(.1,false);check("red stage naturally expires",not t.active())
    t.begin("break",1);t.begin("impact",0)
    check("ordinary hit cannot overwrite a finisher cut",t.mode=="break" and t.owner==1)
    t.begin("ko",0);t.begin("skill",1)
    check("KO has highest presentation priority",t.mode=="ko" and t.owner==0)
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path=""
    root.add_child(scene);current_scene=scene;scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    await process_frame;await process_frame
    setup();scene.pending.attack="special";step()
    check("accepted burst startup enters a real red scene",scene.theatre.mode=="skill" and scene.camera.environment==scene.red_environment and not scene.backdrop.visible)
    check("actors remain visible while scenery is hidden",scene.fighters.all(func(f:Node)->bool:return f.model.is_visible_in_tree()))
    var snapshot:Array=scene.sim.fighters.duplicate(true)
    scene._process(.05)
    check("red staging never edits positions health or combat state",scene.sim.fighters==snapshot)
    scene.pause_game();age=scene.theatre.age;scene._process(.5)
    check("native pause preserves the red clock",scene.theatre.age==age)
    scene.resume_game();scene.reduced_effects=true;scene._process(.01)
    check("F2 restores the city immediately",scene.backdrop.visible and scene.camera.environment==null and not scene.grade.visible)
    scene.reduced_effects=false
    setup();scene.sim.fighters[1].health=20;scene.pending.attack="special"
    for i in 25:
        step()
        if scene.screen=="result":break
    check("lethal real contact launches red KO animation",scene.screen=="result" and scene.theatre.mode=="ko" and scene.camera.environment==scene.red_environment)
    snapshot=scene.sim.fighters.duplicate(true);scene._process(.3)
    check("KO camera and pose leave the resolved simulation unchanged",scene.sim.fighters==snapshot)
    check("KO camera adds a bounded cinematic roll",absf(scene.camera.rotation.z)>0.01 and absf(scene.camera.rotation.z)<.2)
    scene._process(.55)
    check("KO returns to the city and operable result",not scene.theatre.active() and scene.backdrop.visible and scene.camera.environment==null and scene.hud.menu.visible)
    scene.return_to_title();scene._process(.01)
    check("title clears camera matte and shadows",scene.theatre.mode=="" and scene.backdrop.visible and scene.camera.environment==null and scene.silhouettes.all(func(s:Node)->bool:return s.visible))
    var honest_timeout:=true
    for health in [100,90]:
        setup();scene.sim.remaining=.001;scene.sim.fighters[1].health=health;step()
        honest_timeout=honest_timeout and scene.screen=="result" and scene.theatre.mode=="" and scene.backdrop.visible
    check("nonlethal timeout win and draw never pretend to be a red KO",honest_timeout)
    scene.start_demo()
    scene.sim.fighters[1].impact_load=54
    scene.sim.fighters[0].x=-.5;scene.sim.fighters[1].x=.5
    scene.sim.fighters[0].y=1.4;scene.sim.fighters[1].y=1.4
    scene.sim.fighters[0].state="attack";scene.sim.fighters[0].move="meteor";scene.sim.fighters[0].frame=13
    step()
    check("endless finisher red cut never ends the match",scene.screen=="play" and scene.sim.phase=="fight" and scene.theatre.mode=="break")
    check("finisher reward uses actual accumulated impact and a lockout",scene.sim.fighters[1].impact_load==0 and scene.sim.fighters[1].break_lock==180)
    scene.return_to_title()
    var passed:=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open("res://../docs/evidence/rush-rework/red-theatre.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"scope":"Real simulation contacts with controlled fixtures; native camera/matte state checks, not human visual acceptance."},"  "))
    scene.queue_free();await process_frame;await process_frame
    print("RED_THEATRE_CHECKS ",passed,"/",checks.size());call_deferred("quit",0 if passed==checks.size() else 1)
