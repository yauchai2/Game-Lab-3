extends SceneTree
var scene: Node
var folder:="res://../docs/evidence/air-reversal/captures"
var records: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    scene.backdrop.freeze_for_capture()
    prepare()
    await shot("01_read_first")
    step({"lesson_start":true});step_many(8)
    await shot("02_finisher_tell")
    parry_now()
    await shot("03_parry_hold")
    step({"air_choice":"kick"});step_many(4)
    await shot("04_kick_locked")
    while scene.sim.air_counter.phase=="hold":step()
    step_many(5)
    await shot("05_counter_windup")
    while scene.sim.air_counter.active():step()
    await shot("06_counter_contact")
    while scene.sim.hitstop>0:step()
    step_many(2)
    await shot("07_counter_release")
    prepare();step({"lesson_start":true});step_many(8);parry_now()
    step({"air_choice":"escape"})
    while scene.sim.air_counter.active():step()
    step_many(3)
    await shot("08_escape")
    prepare();step({"lesson_start":true});step({"guard_pressed":true});step_many(15)
    await shot("09_early_failure")
    prepare();scene.sim.fighters[0].meter=24
    step({"lesson_start":true});step_many(8);step({"guard_pressed":true})
    await shot("10_insufficient_energy")
    prepare();step({"lesson_start":true});step_many(8);parry_now()
    scene.reduced_effects=true
    scene._process(.01)
    await shot("11_reduced_hold")
    scene.reduced_effects=false;scene.language="en";scene.hud.rebuild_menu()
    await shot("12_english_hold")
    prepare();scene.sim.practice_scenario="air";scene.sim.air_lesson_stage="";scene.sim.partner_mode=2;scene.sim.difficulty=2
    scene.sim.fighters[0].state="attack";scene.sim.fighters[0].move="air_finisher";scene.sim.fighters[0].frame=7
    scene.sim.fighters[1].state="stun";scene.sim.fighters[1].stun=30
    for i in 7:
        step()
        if scene.sim.air_counter.active():break
    await shot("13_ai_reversal")
    while scene.sim.air_counter.phase=="hold":step()
    step({"dash":true})
    while scene.sim.air_counter.active():step()
    await shot("14_evade_ai")
    await sequence()
    var file:=FileAccess.open(folder+"/captures.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(records,"  "))
    scene.queue_free()
    await process_frame
    quit()
func prepare() -> void:
    scene.reduced_effects=false
    scene.start_match(true);scene.prime_air_defense()
    for i in 90:scene._present(1.0/60)
    scene.hud.notice_time=0
func parry_now() -> void:
    step({"guard_pressed":true})
    for i in 4:
        if scene.sim.air_counter.active():return
        step()
func step(a: Dictionary={},b: Dictionary={}) -> void:
    var before: int=scene.sim.hitstop
    scene.sim.tick(a,b)
    if before>0 and scene.sim.hitstop==0:scene._release_impacts()
    for event in scene.sim.events:scene._handle_event(event)
    scene._process(1.0/60)
    scene.hud._process(0)
func step_many(count: int) -> void:
    for i in count:step()
func shot(label: String) -> void:
    scene.hud.queue_redraw()
    for i in 3:await process_frame
    await RenderingServer.frame_post_draw
    var error:=root.get_texture().get_image().save_png(folder+"/"+label+".png")
    records.append({"name":label,"png_error":error,"phase":scene.sim.air_counter.phase,"choice":scene.sim.air_counter.choice,"owner":scene.sim.air_counter.owner,"health":[scene.sim.fighters[0].health,scene.sim.fighters[1].health],"meter":[scene.sim.fighters[0].meter,scene.sim.fighters[1].meter],"poses":[scene.fighters[0].motions.air_pose_name,scene.fighters[1].motions.air_pose_name],"adapter":RenderingServer.get_video_adapter_name(),"method":"native fixed-step scripted capture; no realtime/human claim"})
    print("AIR_REVERSAL_CAPTURE ",label," png=",error)
func sequence() -> void:
    var out:="/tmp/air-reversal-sequence"
    DirAccess.make_dir_recursive_absolute(out)
    scene.language="zh";prepare()
    var frame:=0
    for tick in 160:
        var command: Dictionary={}
        if tick in [12,92]:command={"lesson_start":true}
        if tick in [21,101]:command={"guard_pressed":true}
        if scene.sim.air_counter.phase=="hold" and scene.sim.air_counter.choice=="":command={"air_choice":"kick" if tick<90 else "escape"}
        step(command)
        if tick%2==0:
            scene.hud.queue_redraw()
            await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(out+"/%03d.png"%frame)
            frame+=1
    print("AIR_REVERSAL_SEQUENCE frames=",frame," fixed_hz=60 output_fps=30")
