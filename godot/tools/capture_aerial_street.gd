extends SceneTree
var scene: Node
var folder:="res://../docs/evidence/aerial-street/captures"
var records: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    scene.backdrop.freeze_for_capture()
    await shot("title_labs")
    prepare()
    step({"jump":true})
    await shot("jump_load")
    for i in 3:step()
    await shot("jump_takeoff")
    for i in 23:step()
    await shot("jump_apex")
    step({"down_pressed":true})
    await shot("fast_fall")
    for i in 15:
        step()
        if scene.sim.fighters[0].air.phase=="land":break
    await shot("hard_landing")
    await begin_chase()
    for i in 4:step()
    await shot("homing_midpoint")
    for i in 6:step()
    await shot("homing_arrival")
    step({"attack":"light"})
    for move in ["air_jab","air_kick","air_finisher"]:
        var connected:=false
        for i in 60:
            step()
            if scene.sim.events.any(func(e:Dictionary)->bool:return e.kind=="hit" and e.move==move):connected=true;break
        await shot(move+"_contact" if connected else move+"_miss")
        if move!="air_finisher":step({"attack":"light"})
    await begin_chase()
    for i in 10:step()
    step({"attack":"heavy","down":true})
    for i in 50:
        step()
        if scene.sim.events.any(func(e:Dictionary)->bool:return e.kind=="hit" and e.move=="meteor"):break
    await shot("meteor_contact")
    for i in 70:
        step()
        if scene.sim.events.any(func(e:Dictionary)->bool:return e.kind=="ground_bounce"):break
    await shot("meteor_ground_bounce")
    prepare()
    scene.reduced_effects=true
    step({"jump":true})
    for i in 26:step()
    await shot("jump_reduced")
    scene.reduced_effects=false
    await sequence()
    var file:=FileAccess.open(folder+"/captures.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(records,"  "))
    scene.queue_free()
    await process_frame
    await create_timer(.15).timeout
    quit()
func prepare() -> void:
    scene.start_match(true)
    scene.prime_air_drill()
    scene.hud.notice_time=0
    for i in 90:scene._present(1.0/60)
func begin_chase() -> void:
    prepare()
    step({"attack":"heavy","up":true})
    for i in 30:
        step()
        if scene.sim.events.any(func(e:Dictionary)->bool:return e.kind=="hit"):break
    step({"dash":true})
    while scene.sim.hitstop>0:step()
    step()
func step(command: Dictionary={}) -> void:
    var before: int=scene.sim.hitstop
    scene.sim.tick(command)
    if before>0 and scene.sim.hitstop==0:scene._release_impacts()
    for event in scene.sim.events:scene._handle_event(event)
    scene._process(1.0/60)
func shot(label: String) -> void:
    scene.hud.queue_redraw()
    for i in 3:await process_frame
    await RenderingServer.frame_post_draw
    var error:=root.get_texture().get_image().save_png(folder+"/"+label+".png")
    records.append({"name":label,"png_error":error,"fighters":scene.sim.fighters.duplicate(true),"poses":[scene.fighters[0].motions.air_pose_name,scene.fighters[1].motions.air_pose_name],"camera":str(scene.camera.position),"adapter":RenderingServer.get_video_adapter_name(),"evidence":"native fixed-step simulation capture, not realtime performance or human play"})
    print("AIR_CAPTURE ",label," png=",error)
func sequence() -> void:
    var out:="/tmp/aerial-street-sequence"
    DirAccess.make_dir_recursive_absolute(out)
    prepare()
    var stage:=0
    var frame:=0
    for tick in 210:
        var command: Dictionary={}
        if tick==0:command={"jump":true,"axis":.25}
        if tick==29:command={"down_pressed":true}
        if tick==62:command={"attack":"heavy","up":true}
        if scene.sim.fighters[0].air.chase_window>0 and stage==0:
            command={"dash":true}
            stage=1
        if stage==1 and scene.sim.fighters[0].state=="idle" and scene.sim.fighters[0].air.chase_used:
            command={"attack":"light"}
            stage=2
        if stage==2 and scene.sim.fighters[0].hit_confirmed and scene.sim.fighters[0].move in ["air_jab","air_kick"]:
            command={"attack":"light"}
        step(command)
        if tick%2==0:
            scene.hud.queue_redraw()
            await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(out+"/%03d.png"%frame)
            frame+=1
    print("AIR_SEQUENCE frames=",frame," fixed_hz=60 output_fps=30")
