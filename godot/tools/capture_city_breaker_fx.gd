extends SceneTree
## Run with --write-movie; records actual Godot video AND mixer audio, no dubbed track.
var s:Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/ko-fx-capture-growth.cfg"
    root.add_child(s);s.set_process(false);s.set_physics_process(false)
    s.reduced_effects=false;s.audio.muted=false;s.audio.music_muted=true;s.audio.music_level=0
    await process_frame;await process_frame
    s.start_match(false);s.sim.ai_enabled=false;s.sim.phase="fight";s.sim.fighters[1].health=0;s._combat_step()
    print("KO_MOVIE_START_FRAME ",Engine.get_process_frames())
    s.set_process(true)
    var shot_saved:Dictionary={}
    while s.city_breaker.active():
        await process_frame
        var c=s.city_breaker
        if not shot_saved.has(c.shot) and c.age-c.CUTS[c.shot]>.14:
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://../docs/evidence/city-breaker-fx/shot-%02d.png"%c.shot)
            shot_saved[c.shot]=true
    s.set_process(false);s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    for i in 8:await process_frame
    s.queue_free();s=null
    for i in 8:await process_frame
    quit()
