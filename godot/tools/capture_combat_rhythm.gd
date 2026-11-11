extends SceneTree
var scene:Node
var events:Dictionary={}
var timeline:Array=[]
var shots:Dictionary={}
var pending_events:Array=[]
func _initialize() -> void:call_deferred("run")
func render() -> void:await process_frame;await RenderingServer.frame_post_draw
func save(name:String) -> void:
    await render();root.get_texture().get_image().save_png("res://../docs/evidence/combat-rhythm/captures/"+name+".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute("/tmp/combat-rhythm-frames")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../docs/evidence/combat-rhythm/captures"))
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path=""
    root.add_child(scene);current_scene=scene;scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    await process_frame;await process_frame
    scene.set_character(0,3);scene.set_character(1,2);scene.backdrop.freeze_for_capture()
    scene.combat_event.connect(func(event:Dictionary):
        var label:String=event.kind+("/"+str(event.get("move","")) if event.kind=="hit" else "")
        events[label]=events.get(label,0)+1;pending_events.append(label))
    scene.start_demo()
    for tick in 1800:
        scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
        var label:String=scene.rhythm.phase()
        if scene.theatre.mode=="skill" and scene.rhythm.phase()=="slow":label="skill_slow"
        elif "break_finish" in pending_events:label="break"
        elif "hit/meteor" in pending_events:label="meteor"
        if label not in shots and (tick>30 or label=="skill_slow"):
            shots[label]=true;await save(label)
        pending_events.clear()
        if tick%4==0:
            await render();root.get_texture().get_image().save_png("/tmp/combat-rhythm-frames/%04d.png"%floori(tick/4.0))
            timeline.append({"seconds":tick/60.0,"simulation_tick":scene.demo.age,"phase":scene.rhythm.phase(),"rate":scene.rhythm.rate_now,"red":scene.theatre.mode,"roll_degrees":rad_to_deg(scene.camera.rotation.z)})
    var stats:={"wall_steps":1800,"wall_seconds":30,"simulation_ticks":scene.demo.age,"output_frames":450,"output_fps":15,"one_continuous_take":true,"silent":true,"hits":scene.demo.hits,"events":events,"timeline":timeline}
    FileAccess.open("res://../docs/evidence/combat-rhythm/capture.json",FileAccess.WRITE).store_string(JSON.stringify(stats,"  "))
    scene.return_to_title();scene.hud.open_page("roster")
    for i in 120:scene._process(1.0/60);scene.hud._process(1.0/60)
    await save("short_fighter_preview")
    scene.queue_free();await process_frame;await process_frame
    print("RHYTHM_CAPTURE ",JSON.stringify({"hits":stats.hits,"ticks":stats.simulation_ticks,"events":events}));call_deferred("quit")
