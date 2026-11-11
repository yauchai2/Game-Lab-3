extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var scene := (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    scene.get_node("Street/Overlay").visible = false
    scene.get_node("Player/Visual").visible = false
    var no_shadow := OS.get_cmdline_user_args().has("--no-shadow")
    if no_shadow:
        scene.get_node("Street/Sun").shadow_enabled = false
    var fly = scene.get_node("AircraftFlyby")
    fly.freeze_for_capture()
    var plane: Node3D = fly.plane
    var camera := Camera3D.new()
    scene.add_child(camera)
    camera.fov = 52
    camera.make_current()
    var views := [
        {"name":"01_nose.png","from":Vector3(8,-7,-40),"target":Vector3(0,0,-26)},
        {"name":"02_underside.png","from":Vector3(25,-22,-8),"target":Vector3(0,-1,4)},
    ]
    for view in views:
        camera.global_position = plane.to_global(view.from)
        camera.look_at(plane.to_global(view.target),Vector3.UP)
        for frame in 12:
            await process_frame
        await RenderingServer.frame_post_draw
        if root.get_texture().get_image().save_png("res://../docs/evidence/character/"+("noshadow_" if no_shadow else "")+view.name) != OK:
            push_error("Aircraft capture failed")
            quit(1)
            return
    print("AIRCRAFT_DETAIL_CAPTURED ",RenderingServer.get_video_adapter_name())
    scene.queue_free()
    await process_frame
    quit()
