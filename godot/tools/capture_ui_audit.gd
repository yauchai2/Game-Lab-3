extends SceneTree
## UI audit capture: real scene, live process, forced fixtures for result pages. Not a natural-match recording.
var out:="/tmp/ui/"
var s:Node
func _initialize() -> void:call_deferred("run")
func wait(sec:float) -> void:await create_timer(sec).timeout
func shot(label:String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out+label+".png")
    print("SHOT ",label," screen=",s.screen," page=",s.hud.menu_page)
func ko(side:int) -> void:
    s.sim.fighters[side].health=0.0
func run() -> void:
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--out="):out=a.substr(6)
    DirAccess.make_dir_recursive_absolute(out)
    root.size=Vector2i(1280,720)
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/ui-audit.cfg"
    root.add_child(s);s.audio.muted=true
    await wait(2.0);await shot("01-title")
    for page in ["roster","skills","settings","help"]:
        if page=="skills":s.hud.open_page("roster")
        s.hud.open_page(page);await wait(1.2);await shot("02-"+page)
        if page in ["settings","help","skills"]:
            s.hud.menu_scroll.scroll_vertical=600;await wait(.3);await shot("02-"+page+"-b")
            s.hud.menu_scroll.scroll_vertical=4000;await wait(.3);await shot("02-"+page+"-c")
        s.hud.close_page()
        if page=="skills":s.hud.close_page()
    s.start_match(false);await wait(1.0);await shot("03-intro-a");await wait(1.2);await shot("03-intro-b")
    await wait(2.5);await shot("04-fight-start");await wait(6.0);await shot("04-fight-mid");await wait(4.0);await shot("04-fight-mid2")
    s.pause_game();await wait(.5);await shot("05-pause")
    s.hud.open_page("settings");await wait(.5);await shot("05-pause-settings");s.hud.close_page()
    s.hud.open_page("help");await wait(.5);await shot("05-pause-help");s.hud.close_page()
    s.resume_game();await wait(.3)
    ko(1);await wait(.4);await shot("06-roundko-early");await wait(3.0);await shot("06-round-result")
    print("STATE phase=",s.sim.phase," wins=",s.sim.wins," screen=",s.screen)
    if s.screen=="result":s.advance_round()
    await wait(1.0);await shot("07-after-advance");await wait(5.0)
    for i in 40:
        if s.ability_draw.active():
            if s.ability_draw.state=="offer":await shot("07-draw-offer");s.ability_draw.confirm();break
        await wait(.25)
    for i in 60:
        if s.ability_draw.active() and s.ability_draw.state=="result":await wait(.6);await shot("07-draw-result");break
        await wait(.2)
    print("STATE2 phase=",s.sim.phase," wins=",s.sim.wins," screen=",s.screen," draw=",s.ability_draw.active())
    s.start_match(false);s.round_theatre.clear();s.sim.phase="fight";s.sim.wins=[1,0];await wait(1.0)
    s.reduced_effects=true;ko(1);await wait(4.0);await shot("08-match-result")
    s.reduced_effects=false
    s.start_match(false);s.round_theatre.clear();s.sim.phase="fight";s.sim.wins=[0,1];await wait(1.0)
    ko(0);await wait(1.5);await shot("08-cb-a");await wait(3.0);await shot("08-cb-b");await wait(2.2);await shot("08-cb-winner");await wait(3.5);await shot("08-match-lose")
    s.return_to_title();await wait(.5)
    s.start_match(true);await wait(2.0);await shot("09-training")
    s.training_details=true;await wait(3.0);await shot("09-training-details");s.training_details=false
    s.pause_game();await wait(.4);await shot("09-training-pause");s.resume_game()
    s.start_match(true);s.prime_pressure_drill();await wait(1.5);await shot("10-drill-pressure")
    s.start_match(true);s.prime_rally_drill();await wait(1.5);await shot("10-drill-rally")
    s.start_match(true);s.prime_air_drill();await wait(1.5);await shot("10-drill-air")
    s.start_first_minute();await wait(1.5);await shot("11-coach");
    s.continue_coach();await wait(1.5);await shot("11-coach-b")
    s.start_surge_lab();await wait(1.5);await shot("11-surge-lab")
    s.start_demo();await wait(4.5);await shot("12-demo");await wait(5.0);await shot("12-demo-b")
    s.return_to_title();await wait(.4)
    s.start_run();await wait(1.2);await shot("13-run-intro");await wait(3.5);await shot("13-run-fight")
    s.sim.wins=[1,0];s.reduced_effects=true;ko(1);await wait(4.0);await shot("13-run-result")
    s.hud.open_page("skills");await wait(.5);await shot("13-run-skills");s.hud.close_page()
    s.reduced_effects=false
    s.return_to_title();s.set_process(false);s.set_physics_process(false);s.audio.set_process(false)
    await wait(.15);s.queue_free();s=null
    for i in 8:await process_frame
    quit()
