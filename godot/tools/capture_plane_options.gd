extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var scene := (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    scene.select_reference(0)
    scene.get_node("Player/Visual").visible = false
    scene.get_node("Street/Overlay").visible = false
    var fly = scene.get_node("AircraftFlyby")
    fly.freeze_for_capture()
    scene.get_node("StyleSample").set_image_sky(true)
    var candidates := [Vector3(-3,45,-60),Vector3(-3,41,-52),Vector3(-3,37,-44),Vector3(-3,34,-38),Vector3(-3,32,-34)]
    var images := []
    for i in candidates.size():
        fly.plane.global_position = candidates[i]
        for frame in 10:
            await process_frame
        await RenderingServer.frame_post_draw
        var filename := "option_"+str(i)+".png"
        if root.get_texture().get_image().save_png("res://../docs/evidence/aircraft-tuning/"+filename) != OK:
            push_error("Plane option capture failed")
            quit(1)
            return
        images.append({"file":filename,"position":[candidates[i].x,candidates[i].y,candidates[i].z]})
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"screen_size":[root.size.x,root.size.y],"static_candidates":true,"hardware_gpu_verified":false,"human_playtest":false,"candidates":images}
    var file := FileAccess.open("res://../docs/evidence/aircraft-tuning/candidates.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("PLANE_OPTIONS_CAPTURED ",JSON.stringify(report))
    scene.queue_free()
    await process_frame
    quit()
