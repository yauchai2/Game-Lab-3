extends SceneTree
var scene:Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    DirAccess.make_dir_recursive_absolute("/tmp/combat-rhythm-ko")
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path=""
    root.add_child(scene);current_scene=scene;scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    await process_frame;await process_frame
    scene.set_character(0,3);scene.set_character(1,2);scene.start_match(false)
    var key:=InputEventKey.new();key.keycode=KEY_J;key.physical_keycode=KEY_J;key.pressed=true;Input.parse_input_event(key)
    await process_frame;await process_frame
    for i in 1800:
        scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
        if scene.screen=="result":break
    key=key.duplicate();key.pressed=false;Input.parse_input_event(key)
    if scene.screen!="result" or scene.sim.fighters[1].health>0:
        push_error("Expected a real held-J KO: "+str([scene.screen,scene.sim.winner,scene.sim.fighters[0].health,scene.sim.fighters[1].health]));scene.queue_free();await process_frame;quit(1);return
    for i in 96:
        scene._process(1.0/60);scene.hud._process(1.0/60)
        if i%2==0:
            await process_frame;await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("/tmp/combat-rhythm-ko/%03d.png"%floori(i/2.0))
            if i==24:root.get_texture().get_image().save_png("res://../docs/evidence/combat-rhythm/captures/extended_ko.png")
    print("RHYTHM_REAL_KO ",scene.sim.winner," / red duration ",scene.theatre.duration)
    scene.queue_free();await process_frame;await process_frame;call_deferred("quit")
