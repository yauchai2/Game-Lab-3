extends SceneTree
var scene:Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path="";root.add_child(scene);scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true;scene.backdrop.freeze_for_capture();root.size=Vector2i(960,540)
    scene.set_character(0,3);scene.set_character(1,1);scene.start_demo()
    DirAccess.make_dir_recursive_absolute("/tmp/reference-demo-frames")
    for frame in 120:
        for tick in 4:scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
        await process_frame;await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("/tmp/reference-demo-frames/%04d.png"%frame)
    FileAccess.open("res://../docs/evidence/ui-replica/demo-capture.json",FileAccess.WRITE).store_string(JSON.stringify({"frames":120,"fps":15,"fixed_wall_steps":480,"hits":scene.demo.hits,"events":scene.demo.seen,"scope":"Continuous native fixed-step capture. No soundtrack, no human input, not measured real-time FPS."},"  "))
    scene.queue_free();for i in 8:await process_frame
    await create_timer(.2).timeout;quit()
