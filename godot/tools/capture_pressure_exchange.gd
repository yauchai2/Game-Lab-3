extends SceneTree
var scene: Node
var records: Array[Dictionary]=[]
var folder := "res://../docs/evidence/pressure-exchange/captures"
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var compact:=OS.get_cmdline_user_args().has("--compact")
    if compact:folder="res://../docs/evidence/pressure-exchange/compact"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    scene.backdrop.freeze_for_capture()
    scene.start_match(true)
    scene.prime_pressure_drill()
    for i in 90:scene._present(1.0/60)
    if compact:
        begin()
        await shot("clash_960")
        scene.pause_game()
        await shot("pause_960")
        scene.queue_free()
        await process_frame
        await create_timer(.15).timeout
        quit()
        return
    await shot("01_drill_ready")
    begin()
    await shot("02_read_press")
    scene.pending["clash_choice"]="turn"
    for i in 12:step()
    await shot("03_turn_locked")
    for i in 12:step()
    await shot("04_turn_wins")
    begin()
    scene.sim.exchange.clash.intent="slip"
    scene.pending["clash_choice"]="press"
    for i in 12:step()
    await shot("05_rival_slip_cue")
    for i in 12:step()
    for i in 10:step()
    await shot("06_press_chases")
    begin()
    scene.sim.exchange.clash.intent="turn"
    scene.pending["clash_choice"]="slip"
    for i in 24:step()
    for i in 6:step()
    await shot("07_slip_distance")
    begin()
    scene.pending["clash_choice"]="press"
    for i in 24:step()
    await shot("08_tie")
    begin()
    scene.reduced_effects=true
    scene.pending["clash_choice"]="turn"
    for i in 10:step()
    await shot("09_reduced_clash")
    scene.pause_game()
    await shot("10_pause")
    scene.resume_game()
    scene.reduced_effects=false
    # Fixed-step demonstration, not realtime FPS or human playtest.
    begin()
    DirAccess.make_dir_recursive_absolute("/tmp/pressure-exchange-sequence")
    for tick in 80:
        if tick==5:scene.pending["clash_choice"]="turn"
        step()
        if tick%3==0:
            await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("/tmp/pressure-exchange-sequence/%03d.png"%tick)
    var file:=FileAccess.open(folder+"/captures.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(records,"  "))
    scene.queue_free()
    await process_frame
    await create_timer(.15).timeout
    quit()
func begin() -> void:
    scene.prime_pressure_drill()
    scene.sim._start_attack(0,"heavy")
    for event in scene.sim.events:scene._handle_event(event)
    for i in 16:step()
func step() -> void:
    scene._physics_process(1.0/60)
    scene._process(1.0/60)
func shot(label: String) -> void:
    scene.hud.queue_redraw()
    for i in 5:await process_frame
    await RenderingServer.frame_post_draw
    var error:=root.get_texture().get_image().save_png(folder+"/"+label+".png")
    records.append({"shot":label,"png_error":error,"clash":scene.sim.exchange.clash.duplicate(true),"pressure":scene.sim.exchange.pressure,"result":scene.sim.exchange.last_result.duplicate(true),"health":[scene.sim.fighters[0].health,scene.sim.fighters[1].health],"adapter":RenderingServer.get_video_adapter_name()})
    print("PRESSURE_CAPTURE ",label," error=",error)
