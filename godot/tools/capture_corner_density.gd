extends SceneTree
var output_dir := "res://../docs/evidence/corner-density/candidate"
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var args:=OS.get_cmdline_user_args()
    if not args.is_empty(): output_dir=args[0]
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_physics_process(false)
    scene.set_process(false)
    scene.audio.muted=true
    scene.start_match(true)
    scene.hud.hide()
    scene.backdrop.freeze_for_capture()
    if args.has("--without-corners") and scene.backdrop.street.has_node("CornerStreetscape"):
        scene.backdrop.street.get_node("CornerStreetscape").hide()
    for i in 90:scene._present(1.0/60.0)
    await shot(scene,"01_fight_center")
    scene.sim.fighters[0].x=-7
    scene.sim.fighters[1].x=-3
    for i in 150:scene._present(1.0/60.0)
    await shot(scene,"02_fight_left")
    scene.sim.fighters[0].x=3
    scene.sim.fighters[1].x=7
    for i in 180:scene._present(1.0/60.0)
    await shot(scene,"03_fight_right")
    scene.sim.fighters[0].x=-3
    scene.sim.fighters[1].x=3
    scene._present(0.0)
    scene.camera.fov=68
    scene.camera.position=Vector3(0,2.6,22)
    scene.camera.look_at(Vector3(0,7.8,-7))
    await shot(scene,"04_wide_reference")
    var previous_aspect:=root.content_scale_aspect
    root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
    root.size=Vector2i(1280,544)
    await shot(scene,"07_panorama_reference")
    root.content_scale_aspect=previous_aspect
    root.size=Vector2i(1280,720)
    scene.camera.fov=62
    scene.camera.position=Vector3(-15,3.4,12)
    scene.camera.look_at(Vector3(-15.5,6.8,0))
    await shot(scene,"05_left_shops")
    scene.camera.position=Vector3(15,3.4,12)
    scene.camera.look_at(Vector3(15.5,7.3,0))
    await shot(scene,"06_right_shops")
    scene.queue_free()
    await process_frame
    await create_timer(0.1).timeout
    call_deferred("quit")
func shot(scene:Node,label:String) -> void:
    for i in 6:await process_frame
    await RenderingServer.frame_post_draw
    var error:=root.get_texture().get_image().save_png(output_dir+"/"+label+".png")
    var metrics={"shot":label,"image_error":error,"adapter":RenderingServer.get_video_adapter_name(),"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),"camera_transform":str(scene.camera.global_transform),"fov":scene.camera.fov,"image_size":str(root.get_texture().get_size())}
    var file:=FileAccess.open(output_dir+"/"+label+".json",FileAccess.WRITE)
    file.store_string(JSON.stringify(metrics,"  "))
    file.close()
    print("CORNER_CAPTURE ",JSON.stringify(metrics))
