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
    scene.get_node("StyleSample").set_image_sky(true)
    var outline: MeshInstance3D = scene.get_node("OutlinePass")
    for i in 2:
        outline.visible = i == 1
        for frame in 15:
            await process_frame
        await RenderingServer.frame_post_draw
        var filename := "01_off.png" if i == 0 else "02_on.png"
        if root.get_texture().get_image().save_png("res://../docs/evidence/outline/"+filename) != OK:
            push_error("Outline capture failed")
            quit(1)
            return
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"screen_size":[root.size.x,root.size.y],"hardware_gpu_verified":false,"human_playtest":false,"plane_frozen":true,"same_camera":true}
    var file := FileAccess.open("res://../docs/evidence/outline/captures.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("OUTLINE_CAPTURED ",JSON.stringify(report))
    scene.queue_free()
    await process_frame
    quit()
