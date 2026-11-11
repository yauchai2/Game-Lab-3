extends SceneTree
var scene: Node
var folder:="res://../docs/evidence/impact-staging/captures"
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
    for move in ["jab","cross","finisher","heavy","launcher","special"]:
        prepare(move)
        for i in scene.Simulation.MOVES[move].startup:
            scene._physics_process(1.0/60)
            scene._process(1.0/60)
        await shot(move+"_contact")
        for i in scene.sim.hitstop:
            scene._physics_process(1.0/60)
            scene._process(1.0/60)
        scene._process(.04)
        await shot(move+"_release")
    prepare("heavy")
    scene.sim.fighters[1].x=4.5
    for i in 18:
        scene._physics_process(1.0/60)
        scene._process(1.0/60)
    await shot("heavy_whiff")
    prepare("launcher")
    scene.sim.fighters[1].x=-4.5
    scene.sim.fighters[0].face=-1
    # Regenerate start event with the mirrored facing before the arc becomes visible.
    scene.effects.clear()
    scene._handle_event({"kind":"swing","target":0,"move":"launcher"})
    for i in 15:
        scene._physics_process(1.0/60)
        scene._process(1.0/60)
    await shot("launcher_mirrored_whiff")
    prepare("special")
    scene.reduced_effects=true
    for i in 18:
        scene._physics_process(1.0/60)
        scene._process(1.0/60)
    await shot("special_reduced_contact")
    for i in scene.sim.hitstop:
        scene._physics_process(1.0/60)
        scene._process(1.0/60)
    scene._process(.04)
    await shot("special_reduced_release")
    # Deterministic 60 Hz replay, sampled every other tick; not realtime FPS telemetry.
    prepare("heavy")
    DirAccess.make_dir_recursive_absolute("/tmp/impact-staging-sequence")
    for tick in 64:
        scene._physics_process(1.0/60)
        scene._process(1.0/60)
        if tick%2==0:
            scene.hud.queue_redraw()
            await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("/tmp/impact-staging-sequence/%03d.png"%tick)
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
    for i in 70:scene._present(1.0/60)
    scene.sim._start_attack(0,move)
    for event in scene.sim.events:scene._handle_event(event)
func shot(label: String) -> void:
    scene.hud.queue_redraw()
    for i in 5:await process_frame
    await RenderingServer.frame_post_draw
    var error:=root.get_texture().get_image().save_png(folder+"/"+label+".png")
    records.append({"shot":label,"png_error":error,"hitstop":scene.sim.hitstop,"queue_size":scene.impact_queue.size(),"effects":scene.effects.duplicate(true),"adapter":RenderingServer.get_video_adapter_name()})
    print("IMPACT_CAPTURE ",label," error=",error)
