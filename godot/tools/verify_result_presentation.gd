extends SceneTree
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("RESULT PRESENTATION FAIL: "+label)
func run() -> void:
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    for outcome in [0,1,-1]:
        scene.start_match(false)
        scene.sim.ai_enabled=false
        scene.sim.phase="fight"
        scene.result_clock=9.0 # A previous round must not accelerate this result.
        for f in scene.sim.fighters:
            f.health=1 if outcome<0 else (70 if scene.sim.fighters.find(f)==outcome else 0)
            f.y=.7
            f.flash=15
            f.state="stun"
            f.stun=30
            f.vx=0
        if outcome<0:scene.sim.remaining=0
        scene._physics_process(1.0/60)
        check("result %d resets its own presentation clock"%outcome,scene.screen=="result" and scene.sim.winner==outcome and scene.result_clock==0)
        var frozen: Array=scene.sim.fighters.duplicate(true)
        scene._process(.1)
        check("result %d has the expected flash owner"%outcome,scene.fighters.filter(func(f:Node)->bool:return f.visible).all(func(f:Node)->bool:return f.materials.all(func(m:ShaderMaterial)->bool:return m.get_shader_parameter("flash")== (0.0 if scene.city_breaker.active() else 1.0))))
        scene._process(.7)
        check("result %d clears the frozen simulation flash in the visual pose"%outcome,scene.fighters.all(func(f:Node)->bool:return f.materials.all(func(m:ShaderMaterial)->bool:return m.get_shader_parameter("flash")==0.0)))
        check("result %d visual cleanup leaves the simulation snapshot intact"%outcome,scene.sim.fighters==frozen)
        if scene.city_breaker.active():
            check("result %d launches the loser before settling"%outcome,scene.fighters[1-outcome].position.y>5 and not scene.finish_menu_open)
            scene.skip_city_breaker()
        scene._process(.7) # KO tumble (1.31s) finishes inside the 1.4s finish window.
        check("result %d actors settle onto the crossing"%outcome,scene.fighters.all(func(f:Node3D)->bool:return is_zero_approx(f.position.y)))
        scene.hud.rebuild_menu()
        if DisplayServer.get_name()!="headless":
            for i in 4:await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://../docs/evidence/extended-polish/result_%d.png"%outcome)
    scene.audio.set_process(false);scene.audio.music.stop();scene.audio.fading_music.stop()
    scene.city_breaker.clear()
    await create_timer(.12).timeout
    scene.queue_free()
    for i in 4:await process_frame
    if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
    await create_timer(.12).timeout
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/extended-polish/result-presentation.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"display":DisplayServer.get_name(),"method":"real KO/timeout transitions with a stale prior-round result clock and active hit flash; frozen simulation compared with settled visual poses"},"  "))
    print("RESULT_PRESENTATION_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
