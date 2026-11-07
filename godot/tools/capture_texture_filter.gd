extends SceneTree
## Identical fixed pose, comparing only the toon world-texture sampler.
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
    camera.global_position = Vector3(4.7, 1.7, -12)
    camera.look_at(Vector3(3.8, 2, -30), Vector3.UP)
    camera.fov = 65
    var sample = scene.get_node("StyleSample")
    var original: Array[Shader] = []
    for material in sample.replacements:
        original.append(material.shader)
        var linear := Shader.new()
        linear.code = material.shader.code.replace("world_texture : source_color, filter_nearest_mipmap", "world_texture : source_color, filter_linear_mipmap")
        material.shader = linear
    for frame in 20:
        await process_frame
    await RenderingServer.frame_post_draw
    var prefix := "res://../docs/evidence/style-reference/"
    if root.get_texture().get_image().save_png(prefix+"01_linear.png") != OK:
        quit(1)
        return
    for i in sample.replacements.size():
        sample.replacements[i].shader = original[i]
    for frame in 20:
        await process_frame
    await RenderingServer.frame_post_draw
    if root.get_texture().get_image().save_png(prefix+"02_nearest.png") != OK:
        quit(1)
        return
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"display_driver":DisplayServer.get_name(),"screen_size":[root.size.x,root.size.y],"hardware_gpu_verified":false,"human_playtest":false,"plane_frozen":true,"comparison":"Only toon world-texture filter changes; same camera and scene."}
    var file := FileAccess.open(prefix+"capture.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("FILTER_CAPTURED ",JSON.stringify(report))
    scene.get_node("AircraftFlyby").sound.stop()
    scene.queue_free()
    await process_frame
    quit()
