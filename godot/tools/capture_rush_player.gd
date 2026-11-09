extends SceneTree
var scene: Node
func _initialize() -> void:call_deferred("run")
func key(code:Key,down:bool) -> void:
    var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down
    Input.parse_input_event(e);await process_frame;await process_frame
func shot(name:String) -> void:
    await process_frame;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://../docs/evidence/rush-rework/captures/"+name+".png")
func step() -> void:scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path=""
    root.add_child(scene);current_scene=scene;scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    await process_frame;await process_frame
    scene.backdrop.freeze_for_capture()
    DirAccess.make_dir_recursive_absolute("/tmp/rush-ko-frames")
    scene.start_match(false);await key(KEY_J,true)
    var captured:={}
    for i in 650:
        step()
        for e in scene.sim.events:
            if e.kind=="hit" and e.attacker==0 and e.move in ["launcher","meteor"] and not captured.has(e.move):
                captured[e.move]=true;await shot("player_"+e.move)
        if scene.screen=="result":
            for j in 60:
                scene._process(1.0/60);scene.hud._process(1.0/60)
                if j%2==0:
                    await process_frame;await RenderingServer.frame_post_draw
                    root.get_texture().get_image().save_png("/tmp/rush-ko-frames/%03d.png"%floori(j/2.0))
                if j==12:await shot("player_first_ko")
            break
    await key(KEY_J,false)
    scene.start_match(false)
    while scene.sim.phase=="ready":step()
    await key(KEY_L,true);step();await key(KEY_L,false)
    await shot("player_burst_charge")
    for i in 30:
        step()
        if scene.sim.events.any(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("move","")=="special"):
            await shot("player_burst_hit");break
    print("RUSH_PLAYER_CAPTURE ",JSON.stringify(captured))
    scene.queue_free();await process_frame;await process_frame;call_deferred("quit")
