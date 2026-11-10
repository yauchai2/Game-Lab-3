extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.start_match(true)
    scene.audio.muted=true
    scene.hud.hide()
    scene.backdrop.freeze_for_capture()
    scene.camera.position=Vector3(0,3,16)
    scene.camera.fov=68
    scene.camera.look_at(Vector3(0,17,-12))
    var folder:="res://../docs/evidence/scene-composition/sky-motion"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    var values: Array[Dictionary]=[]
    for second in [0,60]:
        if second>0:scene.backdrop.sky_motion.advance(scene.backdrop.environment,60.0,PI*.5)
        for i in 6:await process_frame
        await RenderingServer.frame_post_draw
        var error:=root.get_texture().get_image().save_png(folder+"/t%02d.png"%second)
        values.append({"simulation_seconds":second,"yaw_radians":scene.backdrop.environment.sky_rotation.y,"png_error":error,"camera":str(scene.camera.transform)})
    var file:=FileAccess.open(folder+"/captures.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(values,"  "))
    scene.queue_free()
    await process_frame
    await create_timer(.15).timeout
    quit()
