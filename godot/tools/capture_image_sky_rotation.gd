extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var scene := (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    scene.get_node("Street/Overlay").visible = false
    scene.get_node("AircraftFlyby").freeze_for_capture()
    scene.get_node("AircraftFlyby").plane.visible = false
    scene.get_node("StyleSample").set_image_sky(true)
    var camera := Camera3D.new()
    camera.name = "SkyTestCamera"
    camera.position = Vector3(0,1000,0)
    camera.far = 500
    camera.fov = 60
    scene.add_child(camera)
    camera.make_current()
    var headings := [0.0,45.0,90.0,135.0,180.0,225.0,270.0,315.0,360.0,-180.0,179.75,-179.75]
    var names := ["yaw_000.png","yaw_045.png","yaw_090.png","yaw_135.png","yaw_180.png","yaw_225.png","yaw_270.png","yaw_315.png","yaw_360.png","yaw_minus180.png","yaw_179_75.png","yaw_minus179_75.png"]
    for i in headings.size():
        var radians := deg_to_rad(headings[i])
        camera.look_at(camera.global_position + Vector3(sin(radians),0.3,-cos(radians)),Vector3.UP)
        for frame in 8:
            await process_frame
        await RenderingServer.frame_post_draw
        var path: String = "res://../docs/evidence/truck-sky/image-rotation/"+names[i]
        if root.get_texture().get_image().save_png(path) != OK:
            push_error("Could not capture "+path)
            quit(1)
            return
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"display_driver":DisplayServer.get_name(),"hardware_gpu_verified":false,"human_playtest":false,"sky_only_camera_height_m":1000,"fov":60,"headings_degrees":headings,"images":names}
    var out := FileAccess.open("res://../docs/evidence/truck-sky/image-rotation/captures.json",FileAccess.WRITE)
    out.store_string(JSON.stringify(report,"  "))
    print("IMAGE_SKY_ROTATION_CAPTURED ",JSON.stringify(report))
    scene.queue_free()
    await process_frame
    quit()
