extends SceneTree
const OUT="res://../docs/evidence/live-combat/"
var s:Node
var reports:Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/live-before-growth.cfg";root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    if s.sim.rush_agent.has_method("reset"):
        push_error("Baseline capture requires the baa6950 runtime in a separate checkout.")
        s.queue_free();quit(1);return
    for pair in [[0,1],[2,3]]:
        s.return_to_title();s.set_character(0,pair[0]);s.set_character(1,pair[1]);s.start_demo();seed(4242)
        var events:Dictionary={};var listener:=func(e:Dictionary):events[e.kind]=events.get(e.kind,0)+1
        s.combat_event.connect(listener)
        var folder:="/tmp/live-before-%d%d"%[pair[0],pair[1]];DirAccess.make_dir_recursive_absolute(folder)
        for tick in 1800:
            s._physics_process(1.0/60.0);s._process(1.0/60.0);s.hud._process(1.0/60.0)
            if tick%6==0:
                await process_frame;await RenderingServer.frame_post_draw
                root.get_texture().get_image().save_png(folder+"/%04d.png"%floori(tick/6.0))
        reports.append({"pair":pair,"virtual_wall_seconds":30,"fps":10,"frames":300,"silent":true,"hits":s.demo.hits.duplicate(),"events":events.duplicate()})
        s.combat_event.disconnect(listener)
    FileAccess.open(OUT+"before-demo.json",FileAccess.WRITE).store_string(JSON.stringify({"segments":reports,"scope":"Two independent uncut genuine free-AI samples, fixed-step virtual wall time. Not a human match, scripted skill showcase or hardware FPS result."},"  "))
    s.return_to_title();s.queue_free();s=null
    for frame in 8:await process_frame
    await create_timer(.3).timeout;call_deferred("quit")
