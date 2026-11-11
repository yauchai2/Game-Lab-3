extends SceneTree
## Captures actual event updates at fixed simulated 30 fps; no audio is captured.
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var scene := (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    scene.select_reference(0)
    scene.get_node("Player/Visual").visible = false
    scene.get_node("Street/Overlay").visible = false
    scene.get_node("StyleSample").set_image_sky(true)
    var fly = scene.get_node("AircraftFlyby")
    fly.restart()
    var emitted := 0
    for i in 361:
        await process_frame
        if i % 3 == 0:
            await RenderingServer.frame_post_draw
            var path := "/tmp/game-lab-flyby-frames/frame_%03d.png" % emitted
            if root.get_texture().get_image().save_png(path) != OK:
                push_error("Frame save failed")
                quit(1)
                return
            emitted += 1
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"screen_size":[root.size.x,root.size.y],"simulation_fixed_fps":30,"captured_fps":10,"frame_count":emitted,"capture_contains_audio":false,"plane_frozen":false,"hardware_gpu_verified":false,"human_playtest":false,"event_active_at_finish":fly.active}
    var file := FileAccess.open("res://../docs/evidence/motion/capture.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("LIVE_FLYBY_CAPTURED ",JSON.stringify(report))
    fly.sound.stop()
    scene.queue_free()
    await process_frame
    quit()
