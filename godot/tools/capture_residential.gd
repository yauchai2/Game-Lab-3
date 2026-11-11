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
    camera.global_position = Vector3(.5, 2.3, -16.5)
    camera.look_at(Vector3(-5.5, 7.8, -22.0),Vector3.UP)
    camera.fov = 65
    for i in 20:
        await process_frame
    await RenderingServer.frame_post_draw
    var result := root.get_texture().get_image().save_png("res://../docs/evidence/residential/03_left_facade.png")
    print("RESIDENTIAL_CAPTURE ",result," ",RenderingServer.get_video_adapter_name())
    scene.get_node("AircraftFlyby").sound.stop()
    scene.queue_free()
    await process_frame
    quit(0 if result == OK else 1)
