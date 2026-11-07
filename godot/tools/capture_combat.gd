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
    for i in 20: scene._present(1.0/60.0)
    await save(scene,"00_restored_overview")
    scene.sim.fighters[0].x = -1.0
    scene.sim.fighters[1].x = 1.0
    for i in 20: scene._present(1.0/60.0)
    await save(scene,"02_fight")
    scene.sim.fighters[0].meter = 85
    scene.sim.fighters[0].x = -0.75
    scene.sim.fighters[1].x = 0.75
    scene.sim.tick({"attack":"heavy","up":true})
    for i in 14:
        scene.sim.tick()
        scene._present(1.0/60.0)
        for event in scene.sim.events:
            scene._handle_event(event)
    for effect in scene.effects:
        effect.age = 0.035
    scene._present(0.05)
    await save(scene,"03_impact")
    for i in 19:
        scene.sim.tick()
        scene._present(1.0/60.0)
    scene.effects.clear()
    scene._present(0.05)
    await save(scene,"04_launcher")
    scene.screen = "pause"
    scene.hud.rebuild_menu()
    await save(scene,"05_pause")
    scene.screen = "play"
    scene.hud.rebuild_menu()
    scene.effects.clear()
    scene.sim.reset_round()
    scene.sim.phase = "fight"
    scene.sim.fighters[0].x = -7
    scene.sim.fighters[1].x = -3
    for i in 90: scene._present(1.0/60.0)
    await save(scene,"06_camera_left")
    scene.sim.fighters[0].x = 3
    scene.sim.fighters[1].x = 7
    for i in 150: scene._present(1.0/60.0)
    await save(scene,"07_camera_right")
    scene.sim.fighters[0].x = -1.1
    scene.sim.fighters[1].x = 1.1
    scene.sim.fighters[0].state = "attack"
    scene.sim.fighters[0].move = "heavy"
    scene.sim.fighters[0].frame = 18
    for i in 90: scene._present(1.0/60.0)
    await save(scene,"08_heavy_kick")
    scene.sim.fighters[0].state = "dash"
    scene.sim.fighters[0].frame = 7
    for i in 12: scene._present(1.0/60.0)
    await save(scene,"09_dodge_roll")
    scene.sim.fighters[0].state = "idle"
    scene.sim.fighters[0].y = 1.5
    scene.sim.fighters[0].vy = 3.0
    for i in 15: scene._present(1.0/60.0)
    await save(scene,"10_jump")
    scene.sim.fighters[0].y = 0.0
    scene.sim.fighters[0].vy = 0.0
    scene.sim.fighters[0].state = "idle"
    scene.sim.fighters[0].x = -1.1
    scene.sim.fighters[1].x = 1.1
    scene.effects.clear()
    for i in 90: scene._present(1.0/60.0)
    scene.ink_pass.visible = false
    await save(scene,"11_scene_edges_off")
    scene.ink_pass.visible = true
    await save(scene,"12_scene_edges_on")
    scene.ink_pass.visible = false
    scene._handle_event({"kind":"parry","target":0,"attacker":1})
    for effect in scene.effects: effect.age = 0.035
    await save(scene,"13_perfect_guard")
    scene.effects.clear()
    scene.hud.notice = ""
    scene._handle_event({"kind":"swing","target":0,"move":"special"})
    for effect in scene.effects: effect.age = 0.07
    scene.sim.fighters[0].state = "attack"
    scene.sim.fighters[0].move = "special"
    scene.sim.fighters[0].frame = 19
    for i in 8: scene._present(1.0/60.0)
    await save(scene,"14_energy_wave")
    scene.effects.clear()
    scene._handle_event({"kind":"guard_break","target":1,"attacker":0})
    for effect in scene.effects: effect.age = 0.08
    await save(scene,"15_guard_break")
    scene.queue_free()
    await process_frame
    await process_frame
    await create_timer(0.10).timeout
    quit()
func save(scene: Node, label: String) -> void:
    scene.hud.queue_redraw()
    for i in 5: await process_frame
    await RenderingServer.frame_post_draw
    var error := root.get_texture().get_image().save_png(output_dir+"/"+label+".png")
    print("COMBAT_CAPTURE ",label," ",error," adapter=",RenderingServer.get_video_adapter_name())
