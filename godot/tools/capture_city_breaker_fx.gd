extends SceneTree
## Run with --write-movie; records actual Godot video AND mixer audio, no dubbed track.
var s:Node
var character:=0
var outro_only:=false
var out:="res://../docs/evidence/city-breaker-fx/"
func _initialize() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
        if arg.begins_with("--character="):character=int(arg.trim_prefix("--character="))
        if arg=="--outro-only":outro_only=true
    call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/ko-fx-capture-growth.cfg"
    root.add_child(s);s.set_process(false);s.set_physics_process(false)
    s.reduced_effects=false;s.audio.muted=false;s.audio.music_muted=true;s.audio.music_level=0
    await process_frame;await process_frame
    s.set_character(0,character);s.set_character(1,(character+1)%4)
    s.start_match(false);s.sim.ai_enabled=false;s.sim.phase="fight";s.sim.fighters[1].health=0;s._combat_step()
    if outro_only:
        s.audio.stop_all() # Isolated previews omit the earlier KO transient.
        s.city_breaker.playback_elapsed=s.city_breaker.BASE_DURATION
        s.city_breaker.advance(0.0,false)
    print("KO_MOVIE_START_FRAME ",Engine.get_process_frames())
    s.set_process(true)
    var shot_saved:Dictionary={}
    while s.city_breaker.active():
        await process_frame
        var c=s.city_breaker
        if c.playback_elapsed>=c.BASE_DURATION:
            var time:float=c.playback_elapsed-c.BASE_DURATION
            for mark in [.25,.75,1.8,2.95]:
                var label:String="exit_%d_%.2f"%[character,mark]
                if time>=mark and not shot_saved.has(label):
                    await RenderingServer.frame_post_draw
                    root.get_texture().get_image().save_png(out+label+".png")
                    shot_saved[label]=true
        elif not shot_saved.has(c.shot) and c.age-c.CUTS[c.shot]>.14:
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(out+"shot-%02d.png"%c.shot)
            shot_saved[c.shot]=true
    s.set_process(false);s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    for i in 8:await process_frame
    s.queue_free();s=null
    for i in 8:await process_frame
    quit()
