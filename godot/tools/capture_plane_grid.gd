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
    for angle in [-160,-150,-140]:
        for x in [-9,-6,-3]:
            fly.plane.global_position = Vector3(x,41,-52)
            fly.plane.rotation_degrees.y = angle
            for frame in 8:
                await process_frame
            await RenderingServer.frame_post_draw
            var filename := "grid_"+str(abs(angle))+"_"+str(abs(x))+".png"
            if root.get_texture().get_image().save_png("res://../docs/evidence/aircraft-tuning/"+filename) != OK:
                push_error("Plane grid capture failed")
                quit(1)
                return
    print("PLANE_GRID_CAPTURED ",JSON.stringify({"angles":[-160,-150,-140],"x_positions":[-9,-6,-3],"position_yz":[41,-52],"renderer":RenderingServer.get_video_adapter_name(),"static_only":true}))
    scene.queue_free()
    await process_frame
    quit()
