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
    var shots := [{"ratio":.43,"name":"01_arrival.png"},{"ratio":.5,"name":"02_overhead.png"},{"ratio":.57,"name":"03_departure.png"}]
    for shot in shots:
        fly.freeze_for_capture(shot.ratio)
        for frame in 8:
            await process_frame
        await RenderingServer.frame_post_draw
        var path: String = "res://../docs/evidence/flyby/"+shot.name
        if root.get_texture().get_image().save_png(path) != OK:
            push_error("Failed to save "+path)
            quit(1)
            return
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"display_driver":DisplayServer.get_name(),"hardware_gpu_verified":false,"human_playtest":false,"captures_are_frozen_poses_not_runtime_video":true,"camera":"01_entry","shots":shots}
    var out := FileAccess.open("res://../docs/evidence/flyby/captures.json",FileAccess.WRITE)
    out.store_string(JSON.stringify(report,"  "))
    print("FLYBY_CAPTURED ",JSON.stringify(report))
    scene.queue_free()
    await process_frame
    quit()
