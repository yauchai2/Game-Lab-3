extends SceneTree
var out:="/tmp/ui/"
var s:Node
func _initialize() -> void:call_deferred("run")
func wait(sec:float) -> void:await create_timer(sec).timeout
func shot(label:String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out+label+".png")
    print("SHOT ",label)
func run() -> void:
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--out="):out=a.substr(6)
    DirAccess.make_dir_recursive_absolute(out)
    root.size=Vector2i(1280,720)
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/ui-audit2.cfg"
    root.add_child(s);s.audio.muted=false;s.audio.music_muted=true
    await wait(2.0);await shot("20-title-unmuted")
    s.start_match(false);s.round_theatre.clear();s.sim.ai_enabled=false;await wait(4.0)
    s.sim.fighters[0].meter=80;s.sim.fighters[1].health=42;s.sim.fighters[0].health=63
    await wait(.3);await shot("21-fight-hud")
    s.pause_game();await wait(.5);await shot("21-pause")
    s.resume_game()
    s.start_match(false);s.round_theatre.clear();s.sim.round_number=2;s.sim.wins=[1,1];s.sim.phase="round_over";s.sim.winner=0;s.screen="result";s.result_clock=2;s.draw_seed=42
    s.advance_round()
    var seen:={}
    for i in 200:
        await wait(.1)
        var d=s.ability_draw
        if not d.active():break
        if not seen.has(d.state):
            seen[d.state]=true
            await wait(.45);await shot("22-draw-"+d.state)
            if d.state=="offer":d.confirm()
        elif d.state=="result" and not seen.has("r2"):
            seen["r2"]=true;await wait(1.0);await shot("22-draw-result-late")
    await wait(4.0);await shot("22-after-draw")
    root.size=Vector2i(960,540)
    s.return_to_title();await wait(1.0);await shot("23-title-960")
    s.start_match(false);s.round_theatre.clear();s.sim.ai_enabled=false;await wait(4.0);await shot("23-fight-960")
    s.return_to_title();s.set_process(false);s.set_physics_process(false);s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await wait(.15);s.queue_free();s=null
    root.size=Vector2i(1280,720)
    var w=load("res://scenes/street_walk.tscn").instantiate();root.add_child(w)
    await wait(3.0);await shot("24-walk")
    w.queue_free()
    for i in 8:await process_frame
    quit()
