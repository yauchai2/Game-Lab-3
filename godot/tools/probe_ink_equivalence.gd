extends SceneTree
var scene:Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path="";scene.progression_path="";root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    await process_frame;await RenderingServer.frame_post_draw
    var digest:=HashingContext.new();digest.start(HashingContext.HASH_SHA256)
    var events:Dictionary={}
    scene.combat_event.connect(func(e:Dictionary):events[e.kind]=events.get(e.kind,0)+1)
    for pair in [[0,1],[2,3]]:
        scene.return_to_title();scene.set_character(0,pair[0]);scene.set_character(1,pair[1]);scene.start_demo();scene.round_theatre.clear();scene.sim.phase="fight";seed(4242)
        await process_frame;await RenderingServer.frame_post_draw
        for tick in 900:
            scene._physics_process(1.0/60);scene._process(1.0/60)
            var row:Array=[scene.sim.tick_count,scene.sim.hitstop,scene.sim.phase]
            for f in scene.sim.fighters:row.append([f.x,f.y,f.vx,f.vy,f.state,f.move,f.frame,f.health,f.meter,f.guard])
            digest.update(JSON.stringify(row).to_utf8_buffer())
    var report:={"sha256":digest.finish().hex_encode(),"events":events,"steps":1800,"scope":"Per-step gameplay trajectory, resources and event counts. Presentation is driven, but excluded from the digest."}
    var args:=OS.get_cmdline_user_args();FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    scene.return_to_title();scene.queue_free();scene=null
    for i in 8:await process_frame
    quit()
