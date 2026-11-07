extends SceneTree
var output_dir := "res://../docs/evidence/combat"
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var args := OS.get_cmdline_user_args()
    if not args.is_empty(): output_dir = args[0]
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
    var scene := preload("res://scenes/combat/street_fight.tscn").instantiate()
    root.add_child(scene)
    scene.set_physics_process(false)
    scene.set_process(false)
    scene.audio.muted = true
    scene.backdrop.freeze_for_capture()
    await save(scene,"01_title")
    scene.start_match(true)
    scene.sim.phase = "fight"
    scene.sim.fighters[0].x = -1.0
    scene.sim.fighters[1].x = 1.0
    scene._present(0.016)
    await save(scene,"02_fight")
    scene.sim.fighters[0].meter = 85
    scene.sim.fighters[0].x = -0.75
    scene.sim.fighters[1].x = 0.75
    scene.sim.tick({"attack":"heavy","up":true})
    for i in 14:
        scene.sim.tick()
        for event in scene.sim.events:
            scene._handle_event(event)
    for effect in scene.effects:
        effect.age = 0.035
    scene._present(0.05)
    await save(scene,"03_impact")
    for i in 19: scene.sim.tick()
    scene.effects.clear()
    scene._present(0.05)
    await save(scene,"04_launcher")
    scene.screen = "pause"
    scene.hud.rebuild_menu()
    await save(scene,"05_pause")
    scene.queue_free()
    await process_frame
    await process_frame
    quit()
func save(scene: Node, label: String) -> void:
    scene.hud.queue_redraw()
    for i in 5: await process_frame
    await RenderingServer.frame_post_draw
    var error := root.get_texture().get_image().save_png(output_dir+"/"+label+".png")
    print("COMBAT_CAPTURE ",label," ",error," adapter=",RenderingServer.get_video_adapter_name())
