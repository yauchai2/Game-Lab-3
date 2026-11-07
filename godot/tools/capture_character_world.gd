extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var scene := (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    scene.get_node("Street/Overlay").visible = false
    scene.get_node("AircraftFlyby").freeze_for_capture()
    var player = scene.get_node("Player")
    scene.activate_walk(false)
    player.set_mouse_capture(true)
    for frame in 60:
        await physics_frame
    for frame in 6:
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://../docs/evidence/character/01_idle_behind.png")
    Input.action_press("walk_forward")
    for frame in 45:
        await physics_frame
    for frame in 3:
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://../docs/evidence/character/02_walking_behind.png")
    Input.action_release("walk_forward")
    var camera := Camera3D.new()
    scene.add_child(camera)
    camera.global_position = player.global_position + Vector3(3,1.4,3)
    camera.look_at(player.global_position+Vector3(0,.9,0),Vector3.UP)
    camera.fov = 45
    camera.make_current()
    for frame in 8:
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://../docs/evidence/character/03_character_side.png")
    print("CHARACTER_WORLD_CAPTURED ",JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"screen":[root.size.x,root.size.y],"actual_controller":true,"human_playtest":false}))
    scene.get_node("AircraftFlyby").sound.stop()
    scene.queue_free()
    await process_frame
    quit()
