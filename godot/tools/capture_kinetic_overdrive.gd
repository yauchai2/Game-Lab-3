extends SceneTree
var scene: Node
var records: Array[Dictionary]=[]
var folder:="res://../docs/evidence/kinetic-overdrive/captures"
func _initialize() -> void:call_deferred("run")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    current_scene=scene
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    scene.backdrop.freeze_for_capture()
    if "--titles-only" in OS.get_cmdline_user_args():
        await shot("01_title")
        scene.language="en"
        scene.hud.rebuild_menu()
        await shot("title_english")
        var title_file:=FileAccess.open(folder+"/title-final.json",FileAccess.WRITE)
        title_file.store_string(JSON.stringify(records,"  "))
        scene.queue_free()
        await process_frame
        quit()
        return
    await shot("01_title")
    scene.prime_rally_drill() # Title alone cannot prime: start through real entry.
    scene.start_match(true)
    scene.prime_rally_drill()
    scene.sim.rally_drill=false
    scene.sim.fighters[1].state="attack"
    scene.sim.fighters[1].move="jab"
    scene.sim.fighters[1].frame=4
    for i in 80:scene._present(1.0/60)
    step({"guard":true,"guard_pressed":true},{})
    for tier in range(1,5):
        var owner: int=scene.sim.rally.owner
        var commands:=[{},{}]
        commands[owner]={"attack":"light"}
        step(commands[0],commands[1])
        for i in 3:step()
        await shot("rally_tier_%d_compress"%tier)
        while scene.sim.rally.phase=="compress":step()
        for i in 10:
            commands=[{},{}]
            # Last tier intentionally lands for a release/cashout capture.
            if tier<4:commands[1-owner]={"guard":i>=8,"guard_pressed":i==8}
            step(commands[0],commands[1])
        if tier==4:
            await shot("rally_tier_4_contact")
            for i in 19:step()
            await shot("rally_tier_4_release")
    prepare("special")
    for i in 8:scene._physics_process(1.0/60);scene._process(1.0/60)
    await shot("special_anticipation")
    for i in 11:scene._physics_process(1.0/60);scene._process(1.0/60)
    await shot("special_contact")
    for i in 18:scene._physics_process(1.0/60);scene._process(1.0/60)
    await shot("special_release")
    prepare("heavy")
    scene.sim.fighters[1].x=4.5
    for i in 18:scene._physics_process(1.0/60);scene._process(1.0/60)
    await shot("heavy_smear_whiff")
    prepare("special")
    scene.reduced_effects=true
    for i in 19:scene._physics_process(1.0/60);scene._process(1.0/60)
    await shot("special_reduced")
    scene.reduced_effects=false
    scene.start_match(false)
    scene.sim.phase="fight"
    scene.sim.ai_enabled=false
    scene.sim.fighters[1].health=0
    scene.sim.fighters[0].x=-.6
    scene.sim.fighters[1].x=.8
    scene._physics_process(1.0/60)
    scene._process(.1)
    await shot("knockout_impact")
    scene._process(.85)
    await shot("knockout_result")
    scene.return_to_title()
    scene._process(.1)
    scene.language="en"
    scene.hud.rebuild_menu()
    await shot("title_english")
    await record_sequence()
    var file:=FileAccess.open(folder+"/captures.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(records,"  "))
    scene.queue_free()
    await process_frame
    await create_timer(.15).timeout
    quit()
func prepare(move: String) -> void:
    scene.reduced_effects=false
    scene.start_match(true)
    scene.sim.fighters[0].x=-.8
    scene.sim.fighters[1].x=.8
    scene.sim.fighters[0].meter=100
    for i in 80:scene._present(1.0/60)
    scene.sim._start_attack(0,move)
    for event in scene.sim.events:scene._handle_event(event)
func step(a: Dictionary={}, b: Dictionary={}) -> void:
    var before: int=scene.sim.hitstop
    scene.sim.tick(a,b)
    if before>0 and scene.sim.hitstop==0:scene._release_impacts()
    for event in scene.sim.events:scene._handle_event(event)
    scene._process(1.0/60)
func shot(label: String) -> void:
    scene._grade_world()
    scene.hud.queue_redraw()
    for i in 3:await process_frame
    await RenderingServer.frame_post_draw
    var error:=root.get_texture().get_image().save_png(folder+"/"+label+".png")
    records.append({"shot":label,"png_error":error,"rally_phase":scene.sim.rally.phase,"tier":scene.sim.rally.tier,"grade_visible":scene.grade.visible,"fov":scene.camera.fov,"effects":scene.effects.size(),"adapter":RenderingServer.get_video_adapter_name(),"evidence":"native Compatibility fixed-step scripted scene, not realtime performance or human play"})
    print("KINETIC_CAPTURE ",label," png=",error)

func record_sequence() -> void:
    var sequence:="/tmp/kinetic-overdrive-sequence"
    DirAccess.make_dir_recursive_absolute(sequence)
    scene.language="zh"
    scene.start_match(true)
    scene.prime_rally_drill()
    scene.sim.rally_drill=false
    scene.hud.notice_time=0
    scene.sim.fighters[1].state="attack"
    scene.sim.fighters[1].move="jab"
    scene.sim.fighters[1].frame=4
    for i in 100:scene._present(1.0/60)
    step({"guard":true,"guard_pressed":true},{})
    var frame:=0
    for level in range(1,5):
        var owner: int=scene.sim.rally.owner
        var hold: int=scene.sim.rally.HOLDS[level-1]
        for tick in hold+10:
            var commands:=[{},{}]
            if tick==0:commands[owner]={"attack":"light"}
            if tick>=hold and level<4:commands[1-owner]={"guard":tick>=hold+8,"guard_pressed":tick==hold+8}
            step(commands[0],commands[1])
            if tick%2==0:
                await sequence_frame(sequence,frame)
                frame+=1
    for tick in 52:
        step()
        if tick%2==0:
            await sequence_frame(sequence,frame)
            frame+=1
    print("KINETIC_SEQUENCE frames=",frame," fixed_simulation_hz=60 output_fps=30")
func sequence_frame(sequence: String, frame: int) -> void:
    scene.hud.queue_redraw()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(sequence+"/%03d.png"%frame)
