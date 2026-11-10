extends SceneTree
## 30 virtual wall seconds, uncut true AI; silent images, not a hardware FPS benchmark.
const OUT="res://../docs/evidence/neon-facets/"
var scene:Node
var events:Dictionary={}
var timeline:Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
    DirAccess.make_dir_recursive_absolute("/tmp/neon-demo-frames")
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path=""
    root.add_child(scene);scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    scene.set_character(0,3);scene.set_character(1,2)
    scene.start_demo();seed(4242)
    scene.combat_event.connect(func(event:Dictionary):
        var key:String=event.kind+("/"+str(event.get("move","")) if event.kind in ["hit","swing"] else "")
        events[key]=events.get(key,0)+1)
    for tick in 1800:
        scene._physics_process(1.0/60.0);scene._process(1.0/60.0);scene.hud._process(1.0/60.0)
        if tick%4==0:
            scene.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("/tmp/neon-demo-frames/%04d.png"%floori(tick/4.0))
            timeline.append({"wall_seconds":tick/60.0,"sim_tick":scene.sim.tick_count,"rate":scene.rhythm.rate_now,"poster":scene.neon.stage(),"mode":scene.neon.mode,"effects":scene.effects.size()})
    FileAccess.open(OUT+"demo-capture.json",FileAccess.WRITE).store_string(JSON.stringify({"wall_steps":1800,"virtual_seconds":30,"fps":15,"frames":450,"silent":true,"one_continuous_take":true,"events":events,"hits":scene.demo.hits,"timeline":timeline,"scope":"Seeded normal AI and real hit rules; frames sampled every four wall steps. Not a human playthrough or realtime performance measurement."},"  "))
    scene.return_to_title();scene.queue_free();await process_frame;await process_frame;quit()
