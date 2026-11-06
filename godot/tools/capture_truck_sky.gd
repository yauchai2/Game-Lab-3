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
    var camera: Camera3D = scene.get_node("Street/ReferenceCameras").get_child(0)
    var shots := ["01_procedural.png","02_image_sky.png","03_truck_front.png","04_truck_back.png"]
    for i in shots.size():
        if i == 0:
            sample.set_clouds(true)
        elif i == 1:
            sample.set_image_sky(true)
        elif i == 2:
            camera.position = Vector3(-.3,1.7,-29)
            camera.look_at(Vector3(2.6,1.4,-36),Vector3.UP)
            camera.fov = 55
        elif i == 3:
            camera.position = Vector3(-.3,1.7,-43)
            camera.look_at(Vector3(2.6,1.4,-36),Vector3.UP)
        for frame in 10:
            await process_frame
        await RenderingServer.frame_post_draw
        if root.get_texture().get_image().save_png("res://../docs/evidence/truck-sky/"+shots[i]) != OK:
            push_error("Scene capture failed")
            quit(1)
            return
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"display_driver":DisplayServer.get_name(),"shots":shots,"same_camera_sky_comparison":true,"plane_frozen":true,"hardware_gpu_verified":false,"human_playtest":false}
    var out := FileAccess.open("res://../docs/evidence/truck-sky/captures.json",FileAccess.WRITE)
    out.store_string(JSON.stringify(report,"  "))
    print("TRUCK_SKY_CAPTURED ",JSON.stringify(report))
    scene.queue_free()
    await process_frame
    quit()
