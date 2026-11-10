extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var scene := (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    scene.select_reference(0)
    scene.get_node("Player/Visual").visible = false
    scene.get_node("Street/Overlay").visible = false
    scene.get_node("AircraftFlyby").freeze_for_capture()
    var sample = scene.get_node("StyleSample")
    sample.set_image_sky(true)
    var camera: Camera3D = scene.get_node("Street/ReferenceCameras").get_child(0)
    var poses := [
        {"file":"01_entry.png", "pos":Vector3(0,1.1,8), "target":Vector3(0,13,-24), "fov":75.0},
        {"file":"02_street_level.png", "pos":Vector3(0,1.7,3), "target":Vector3(0,3.7,-35), "fov":65.0},
        {"file":"03_midstreet.png", "pos":Vector3(0,1.7,-23), "target":Vector3(0,6,-50), "fov":68.0},
        {"file":"04_sidewalk.png", "pos":Vector3(4.7,1.7,-12), "target":Vector3(3.8,2,-30), "fov":65.0},
        {"file":"05_alley_mural.png", "pos":Vector3(-10.5,1.7,-29.7), "target":Vector3(-10.5,3.2,-33.9), "fov":65.0},
    ]
    for spec in poses:
        camera.global_position = spec.pos
        camera.look_at(spec.target,Vector3.UP)
        camera.fov = spec.fov
        for frame in 10:
            await process_frame
        await RenderingServer.frame_post_draw
        var path: String = "res://../docs/evidence/textured/"+spec.file
        if root.get_texture().get_image().save_png(path) != OK:
            push_error("Capture failed "+path)
            quit(1)
            return
    scene.get_node("OutlinePass").visible = true
    for frame in 10:
        await process_frame
    await RenderingServer.frame_post_draw
    if root.get_texture().get_image().save_png("res://../docs/evidence/textured/06_alley_outline.png") != OK:
        push_error("Outline alley capture failed")
        quit(1)
        return
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"display_driver":DisplayServer.get_name(),"screen_size":[root.size.x,root.size.y],"hardware_gpu_verified":false,"human_playtest":false,"plane_frozen":true,"shots":["01_entry.png","02_street_level.png","03_midstreet.png","04_sidewalk.png","05_alley_mural.png","06_alley_outline.png"]}
    var file := FileAccess.open("res://../docs/evidence/textured/captures.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("TEXTURED_CAPTURED ",JSON.stringify(report))
    scene.queue_free()
    await process_frame
    quit()
