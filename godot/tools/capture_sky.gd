extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var output_dir := "res://../docs/evidence/sky/"
    var metadata_name := "captures.json"
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--output-dir="):
            output_dir = arg.trim_prefix("--output-dir=").path_join("")
            metadata_name = "street-captures.json"
    var scene := (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    scene.select_reference(0)
    scene.get_node("Player/Visual").visible = false
    scene.get_node("Street/Overlay").visible = false
    scene.get_node("AircraftFlyby").freeze_for_capture()
    var sample = scene.get_node("StyleSample")
    var shots := ["01_clouds_entry.png","02_flat_entry.png","03_clouds_midstreet.png","04_clouds_reverse.png"]
    for i in shots.size():
        sample.set_clouds(i != 1)
        if i == 2:
            scene.select_reference(1)
        elif i == 3:
            var camera: Camera3D = scene.get_node("Street/ReferenceCameras").get_child(1)
            camera.look_at(camera.global_position + Vector3(0, .5, 1), Vector3.UP)
        for frame in 12:
            await process_frame
        await RenderingServer.frame_post_draw
        if root.get_texture().get_image().save_png(output_dir.path_join(shots[i])) != OK:
            push_error("Failed to save "+shots[i])
            quit(1)
            return
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"display_driver":DisplayServer.get_name(),"hardware_gpu_verified":false,"human_playtest":false,"plane_frozen":true,"entry_comparison_same_camera":true,"shots":shots}
    var out := FileAccess.open(output_dir.path_join(metadata_name),FileAccess.WRITE)
    out.store_string(JSON.stringify(report,"  "))
    print("SKY_CAPTURED ",JSON.stringify(report))
    scene.queue_free()
    await process_frame
    quit()
