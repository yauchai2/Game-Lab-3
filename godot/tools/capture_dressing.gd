extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var output := "res://../docs/evidence/dressing/after/"
    for arg in OS.get_cmdline_user_args():
        if arg == "--before":
            output = "res://../docs/evidence/dressing/before/"
    var scene := (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    if output.ends_with("/after/") and (not scene.has_node("StreetDressing") or not scene.get_node("StreetDressing").has_method("_flush_groups")):
        push_error("Street dressing did not load; capture is invalid")
        quit(1)
        return
    scene.select_reference(0)
    scene.get_node("Player/Visual").visible = false
    scene.get_node("Street/Overlay").visible = false
    scene.get_node("AircraftFlyby").freeze_for_capture()
    var sample = scene.get_node("StyleSample")
    var camera: Camera3D = scene.get_node("Street/ReferenceCameras").get_child(0)
    var poses := [
        {"file":"01_entry.png", "pos":Vector3(0,1.1,8), "target":Vector3(0,13,-24), "fov":75.0, "sky":false},
        {"file":"02_entry_image_sky.png", "pos":Vector3(0,1.1,8), "target":Vector3(0,13,-24), "fov":75.0, "sky":true},
        {"file":"03_street_level.png", "pos":Vector3(0,1.7,3), "target":Vector3(0,3.7,-35), "fov":65.0, "sky":true},
        {"file":"04_midstreet.png", "pos":Vector3(0,1.7,-23), "target":Vector3(0,6,-50), "fov":68.0, "sky":true},
        {"file":"05_alley_return.png", "pos":Vector3(-12,1.6,-32), "target":Vector3(3,6,-30), "fov":75.0, "sky":true}
    ]
    for spec in poses:
        camera.global_position = spec.pos
        camera.look_at(spec.target,Vector3.UP)
        camera.fov = spec.fov
        sample.set_image_sky(spec.sky)
        for frame in 12:
            await process_frame
        await RenderingServer.frame_post_draw
        var path: String = output.path_join(spec.file)
        if root.get_texture().get_image().save_png(path) != OK:
            push_error("Could not save "+path)
            quit(1)
            return
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"display_driver":DisplayServer.get_name(),"screen_size":[root.size.x,root.size.y],"hardware_gpu_verified":false,"human_playtest":false,"plane_frozen":true,"shots":["01_entry.png","02_entry_image_sky.png","03_street_level.png","04_midstreet.png","05_alley_return.png"]}
    var file := FileAccess.open(output.path_join("captures.json"),FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("DRESSING_CAPTURED ",JSON.stringify(report))
    scene.queue_free()
    await process_frame
    quit()
