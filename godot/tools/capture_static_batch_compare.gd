extends SceneTree
var records: Array[Dictionary]=[]
const FOLDER := "res://../docs/evidence/extended-polish/static-batches"
func _initialize() -> void:call_deferred("run")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))
    for enabled in [false,true]:
        var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
        scene.preferences_path=""
        scene.static_batches_enabled=enabled
        root.add_child(scene)
        scene.set_process(false)
        scene.set_physics_process(false)
        scene.audio.muted=true
        scene.start_match(true)
        scene.hud.hide()
        scene.backdrop.freeze_for_capture()
        for i in 120:scene._present(1.0/60)
        var label:="batched" if enabled else "source"
        for camera in ["fight","wide","left","right"]:
            scene.camera.fov=48 if camera=="fight" else 68
            scene.camera.position=Vector3(0,1.7,16.5) if camera=="fight" else Vector3(0,2.6,22)
            scene.camera.look_at(Vector3(0,2.45,3) if camera=="fight" else Vector3(0,7.8,-7))
            if camera=="left":
                scene.camera.position=Vector3(-15,3.4,12)
                scene.camera.look_at(Vector3(-11,10.5,2))
            elif camera=="right":
                scene.camera.position=Vector3(15,3.4,12)
                scene.camera.look_at(Vector3(12,10.5,2))
            for i in 8:await process_frame
            await RenderingServer.frame_post_draw
            var error:=root.get_texture().get_image().save_png(FOLDER+"/"+label+"_"+camera+".png")
            var data:={"variant":label,"camera":camera,"png_error":error,"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),"batch_stats":scene.backdrop.static_batch_stats,"adapter":RenderingServer.get_video_adapter_name()}
            records.append(data)
            print("STATIC_BATCH_CAPTURE ",JSON.stringify(data))
        scene.queue_free()
        await process_frame
        await process_frame
    var file:=FileAccess.open(FOLDER+"/captures.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(records,"  "))
    await create_timer(.15).timeout
    quit()
