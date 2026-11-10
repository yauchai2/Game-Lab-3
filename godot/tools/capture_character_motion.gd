extends SceneTree
## Fixed-step capture of real CharacterBody input; silent, not a human playtest.
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var scene := (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    scene.get_node("Street/Overlay").visible = false
    scene.get_node("AircraftFlyby").freeze_for_capture()
    scene.activate_walk(false)
    var player = scene.get_node("Player")
    player.set_mouse_capture(true)
    var camera := Camera3D.new()
    scene.add_child(camera)
    camera.fov = 45
    camera.make_current()
    Input.action_press("walk_forward")
    var frame_count := 0
    for i in 151:
        await physics_frame
        camera.global_position = player.global_position + Vector3(3.3,1.4,1.0)
        camera.look_at(player.global_position + Vector3(0,.9,0),Vector3.UP)
        if i % 3 == 0:
            await RenderingServer.frame_post_draw
            var path := "/tmp/game-lab-character-frames/frame_%03d.png" % frame_count
            if root.get_texture().get_image().save_png(path) != OK:
                push_error("Character frame capture failed")
                quit(1)
                return
            frame_count += 1
    Input.action_release("walk_forward")
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"fixed_simulation_fps":60,"capture_fps":20,"frames":frame_count,"audio":false,"real_controller_input":true,"human_playtest":false}
    var file := FileAccess.open("res://../docs/evidence/character/motion-capture.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("CHARACTER_MOTION_CAPTURED ",JSON.stringify(report))
    scene.get_node("AircraftFlyby").sound.stop()
    scene.queue_free()
    await process_frame
    quit()
