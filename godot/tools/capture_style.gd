extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var scene := (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    scene.select_reference(0)
    scene.get_node("Player/Visual").visible = false
    scene.get_node("Street/Overlay").visible = false
    var sample = scene.get_node("StyleSample")
    var results := []
    for i in 3:
        sample.set_mode(i)
        for frame in 8:
            await process_frame
        await RenderingServer.frame_post_draw
        var img := root.get_texture().get_image()
        var path := ProjectSettings.globalize_path("res://../docs/evidence/style/").path_join(["01_original.png","02_two_bands.png","03_three_bands.png"][i])
        var err := img.save_png(path)
        if err != OK:
            push_error("Failed to save "+path)
            quit(1)
            return
        results.append({"mode":i,"image":path.get_file(),"width":img.get_width(),"height":img.get_height()})
    # A shadow-off control checks whether cast shadows reach the sampled surfaces.
    sample.set_mode(1)
    scene.get_node("Street/Sun").shadow_enabled = false
    for frame in 8:
        await process_frame
    await RenderingServer.frame_post_draw
    var shadow_path := ProjectSettings.globalize_path("res://../docs/evidence/style/").path_join("04_shadow_off.png")
    if root.get_texture().get_image().save_png(shadow_path) != OK:
        push_error("Shadow control capture failed")
        quit(1)
        return
    scene.get_node("Street/Sun").shadow_enabled = true
    # Closer identical angle makes the curved hydrant and its banding visible.
    var camera: Camera3D = scene.get_node("Street/ReferenceCameras").get_child(0)
    camera.position = Vector3(3.3,1.55,2.5)
    camera.look_at(Vector3(5.1,.95,-1.5),Vector3.UP)
    camera.fov = 55
    for i in [1,2]:
        sample.set_mode(i)
        for frame in 8:
            await process_frame
        await RenderingServer.frame_post_draw
        var detail_name: String = "05_two_detail.png" if i == 1 else "06_three_detail.png"
        var detail_path := ProjectSettings.globalize_path("res://../docs/evidence/style/").path_join(detail_name)
        if root.get_texture().get_image().save_png(detail_path) != OK:
            push_error("Detail capture failed")
            quit(1)
            return
        results.append({"mode":i,"image":detail_name,"view":"hydrant detail"})
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"display_driver":DisplayServer.get_name(),"compatibility_renderer":true,"hardware_gpu_verified":false,"entry_comparison_same_camera":true,"detail_comparison_same_camera":true,"shadow_control_image":"04_shadow_off.png","captures":results}
    var out := FileAccess.open("res://../docs/evidence/style/captures.json",FileAccess.WRITE)
    out.store_string(JSON.stringify(report,"  "))
    print("STYLE_CAPTURED ",JSON.stringify(report))
    quit()
