extends SceneTree
var scene: Node
var frames:=0
var selected:=["air_combo","air_counter_kick","kinetic","finale"]
var targets:={"combo":"hit","heavy":"hit","block":"block","guard_break":"guard_break","parry":"parry","grab":"hit","throw_tech":"throw_tech","dodge":"dash","special":"hit","pressure_press":"clash_start","pressure_turn":"clash_start","pressure_slip":"clash_start","jump":"fast_fall","air_combo":"hit","meteor":"ground_bounce","air_counter_kick":"air_counter_start","air_counter_escape":"air_counter_start","air_counter_evade":"air_counter_release","wall_bounce":"wall_bounce","wall_tech":"wall_tech","kinetic":"rally_contact","duel":"hit","finale":"ko"}
func _initialize() -> void:call_deferred("run")
func shot(path:String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(path)
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../docs/evidence/ai-demo/captures"))
    DirAccess.make_dir_recursive_absolute("/tmp/ai-demo-sequence")
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    scene.backdrop.freeze_for_capture()
    await shot("res://../docs/evidence/ai-demo/captures/00_title.png")
    scene.start_demo()
    for index in scene.demo.CHAPTERS.size():
        scene.demo.chapter=index;scene._prepare_demo_chapter()
        var name: String=scene.demo.key()
        var captured:=false
        for tick in 180:
            scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(0)
            if not captured and scene.sim.events.any(func(e:Dictionary)->bool:return e.kind==targets[name] and (name!="air_combo" or e.get("move","")=="air_finisher")):
                await shot("res://../docs/evidence/ai-demo/captures/%02d_%s.png"%[index+1,name]);captured=true
            if name in selected and tick%4==0:
                await shot("/tmp/ai-demo-sequence/%04d.png"%frames);frames+=1
        if not captured:await shot("res://../docs/evidence/ai-demo/captures/%02d_%s.png"%[index+1,name])
    scene.reduced_effects=true;scene.demo.chapter=16;scene._prepare_demo_chapter()
    for i in 14:scene._physics_process(1.0/60);scene._process(1.0/60)
    await shot("res://../docs/evidence/ai-demo/captures/24_reduced.png")
    print("DEMO_CAPTURE frames=",frames," fixed_hz=60 output_fps=15")
    scene.queue_free();await process_frame;await process_frame
    call_deferred("quit")
