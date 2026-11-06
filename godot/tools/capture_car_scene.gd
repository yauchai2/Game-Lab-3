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
    var camera: Camera3D = scene.get_node("Street/ReferenceCameras").get_child(0)
    var shots := [
        {"name":"01_front_street.png","position":Vector3(0,1.7,-11),"target":Vector3(-2.9,.9,-17)},
        {"name":"02_back_street.png","position":Vector3(.0,1.7,-23),"target":Vector3(-2.9,.9,-17)}
    ]
    for shot in shots:
        camera.position = shot.position
        camera.look_at(shot.target,Vector3.UP)
        camera.fov = 55
        for frame in 10:
            await process_frame
        await RenderingServer.frame_post_draw
        if root.get_texture().get_image().save_png("res://../docs/evidence/car/"+shot.name) != OK:
            push_error("Scene capture failed")
            quit(1)
            return
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"display_driver":DisplayServer.get_name(),"shots":["01_front_street.png","02_back_street.png"],"hardware_gpu_verified":false,"human_playtest":false}
    var out := FileAccess.open("res://../docs/evidence/car/captures.json",FileAccess.WRITE)
    out.store_string(JSON.stringify(report,"  "))
    print("CAR_SCENE_CAPTURED ",JSON.stringify(report))
    scene.queue_free()
    await process_frame
    quit()
