extends SceneTree
## Deterministic real renderer capture, same KO entry as formal gameplay.
const OUT := "res://../docs/evidence/city-breaker/"
var s: Node
func _initialize() -> void: call_deferred("run")
func run() -> void:
    DirAccess.make_dir_recursive_absolute("/tmp/city-breaker-frames")
    s=preload("res://scenes/combat/street_fight.tscn").instantiate()
    s.preferences_path="";s.progression_path="/tmp/ko-capture-growth.cfg"
    root.add_child(s);s.set_process(false);s.set_physics_process(false);s.audio.muted=true;s.reduced_effects=false
    await process_frame;await process_frame
    s.set_character(0,0);s.set_character(1,1);s.start_match(false)
    s.sim.ai_enabled=false;s.sim.phase="fight";s.sim.fighters[1].health=0;s._combat_step()
    var c=s.city_breaker
    var fps:=15
    for frame in 150:
        var t:float=frame/float(fps)
        s.result_clock=t
        s._present(0.0);s._apply_red_stage();c.sample(t)
        s.hud.queue_redraw()
        await process_frame;await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("/tmp/city-breaker-frames/%04d.png"%frame)
        if frame in [4,16,35,62,84,98,111,132]:
            root.get_texture().get_image().save_png(OUT+"shot-%02d.png"%c.shot)
    s.skip_city_breaker()
    s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    for i in 8:await process_frame
    s.queue_free()
    for i in 8:await process_frame
    quit()
