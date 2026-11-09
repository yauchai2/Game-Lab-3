extends SceneTree
var scene: Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    DirAccess.make_dir_recursive_absolute("/tmp/rush-live-frames")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../docs/evidence/rush-rework/captures"))
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path="";root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    scene.backdrop.freeze_for_capture()
    scene.start_demo()
    var captured:={}
    for tick in 900:
        scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
        for e in scene.sim.events:
            var key: String=e.kind+('_'+str(e.get('move','')) if e.kind=='hit' else '')
            if key in ["homing_chase","hit_meteor","air_counter_start","hit_special","hit_air_kick","break_finish"] and not captured.has(key):
                await process_frame;await RenderingServer.frame_post_draw
                captured[key]=true
                root.get_texture().get_image().save_png("res://../docs/evidence/rush-rework/captures/"+key+".png")
        if tick%4==0:
            await process_frame;await RenderingServer.frame_post_draw
            var frame:=root.get_texture().get_image()
            frame.save_png("/tmp/rush-live-frames/%04d.png"%floori(tick/4.0))
            for e in scene.sim.events:
                var key: String=e.kind+('_'+str(e.get('move','')) if e.kind=='hit' else '')
                if key in ["homing_chase","hit_meteor","air_counter_start","hit_special","hit_air_kick","break_finish"] and not captured.has(key):
                    captured[key]=true;frame.save_png("res://../docs/evidence/rush-rework/captures/"+key+".png")
    root.get_texture().get_image().save_png("res://../docs/evidence/rush-rework/captures/live_fight.png")
    var stats:={"frames":225,"simulation_ticks":900,"output_fps":15,"one_continuous_take":true,"hits":scene.demo.hits,"events":scene.demo.seen}
    FileAccess.open("res://../docs/evidence/rush-rework/captures/take.json",FileAccess.WRITE).store_string(JSON.stringify(stats,"  "))
    scene.reduced_effects=true;scene._process(.01);scene.hud._process(0)
    await process_frame;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://../docs/evidence/rush-rework/captures/reduced_live.png")
    scene.queue_free();await process_frame;await process_frame
    print("LIVE_DEMO_CAPTURE ",JSON.stringify(stats));call_deferred("quit")
