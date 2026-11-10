extends SceneTree
var scene:Node
var events:Dictionary={}
func _initialize() -> void:call_deferred("run")
func run() -> void:
    DirAccess.make_dir_recursive_absolute("/tmp/cannon-move-frames")
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path=""
    root.add_child(scene);current_scene=scene;scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    await process_frame;await process_frame
    scene.set_character(0,3);scene.set_character(1,2);scene.start_match(true);scene.backdrop.freeze_for_capture()
    scene.combat_event.connect(func(e:Dictionary):
        var label:String=e.kind+("/"+str(e.get("move","")) if e.kind=="hit" else "")
        events[label]=events.get(label,0)+1)
    for code in [KEY_W,KEY_L]:
        var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;Input.parse_input_event(e)
        await process_frame;await process_frame
    for code in [KEY_W,KEY_L]:
        var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=false;Input.parse_input_event(e)
        await process_frame;await process_frame
    var beam:=false
    for tick in 240:
        scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
        var firing:bool=scene.effects.any(func(e:Dictionary)->bool:return e.kind=="cannon_blast")
        if tick%2==0 or (firing and not beam):
            await process_frame;await RenderingServer.frame_post_draw
            var frame:=root.get_texture().get_image()
            if tick%2==0:frame.save_png("/tmp/cannon-move-frames/%03d.png"%floori(tick/2.0))
            if firing and not beam:frame.save_png("res://../docs/evidence/charged-cannon/captures/cannon_blast.png");beam=true
    FileAccess.open("res://../docs/evidence/charged-cannon/move-capture.json",FileAccess.WRITE).store_string(JSON.stringify({"events":events,"beam_seen":beam,"wall_seconds":4,"frames":120,"fps":30,"scope":"Native physical W/L command against standing training partner; actual cost/contact and release, fixed wall steps, silent."},"  "))
    scene.queue_free();await process_frame;await process_frame
    print("CANNON_MOVE_CAPTURE ",beam," ",JSON.stringify(events));call_deferred("quit",0 if beam else 1)
