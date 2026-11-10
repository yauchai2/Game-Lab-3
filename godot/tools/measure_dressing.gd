extends SceneTree
func _initialize() -> void:
    call_deferred("measure")
func measure() -> void:
    var scene := (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    scene.select_reference(0)
    scene.get_node("Player/Visual").visible = false
    scene.get_node("Street/Overlay").visible = false
    scene.get_node("AircraftFlyby").freeze_for_capture()
    var results := []
    for option in [{"name":"with_dressing","show":true,"outline":false},{"name":"without_dressing","show":false,"outline":false},{"name":"with_outline","show":true,"outline":true}]:
        scene.get_node("StreetDressing").visible = option.show
        scene.get_node("OutlinePass").visible = option.outline
        var calls := []
        var objects := []
        var primitives := []
        for i in 40:
            await process_frame
            await RenderingServer.frame_post_draw
            if i>=20:
                calls.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
                objects.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME))
                primitives.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
        results.append({"mode":option.name,"draw_calls_min":calls.min(),"draw_calls_max":calls.max(),"objects_min":objects.min(),"objects_max":objects.max(),"primitives_min":primitives.min(),"primitives_max":primitives.max()})
    var report := {"renderer":RenderingServer.get_video_adapter_name(),"screen_size":[root.size.x,root.size.y],"hardware_gpu_verified":false,"fps_benchmark":false,"same_camera":true,"results":results}
    var path := "res://../docs/evidence/dressing/render_metrics.json"
    for arg in OS.get_cmdline_user_args():
        if arg == "--before-batching":
            path = "res://../docs/evidence/dressing/render_metrics_before_batching.json"
    var file := FileAccess.open(path,FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("DRESSING_METRICS ",JSON.stringify(report))
    scene.queue_free()
    await process_frame
    quit()
