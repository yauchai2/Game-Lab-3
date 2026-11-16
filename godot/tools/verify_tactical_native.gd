extends SceneTree
const OUT="res://../docs/evidence/tactics-expanded/first-eight-native/"
var checks:Array=[]
var session:Node
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("TACTIC_NATIVE ",label," ",ok)
    if not ok:push_error(label)
func frames(count:=3) -> void:
    for i in count:await process_frame
    await RenderingServer.frame_post_draw
func key(code:Key,down:bool) -> void:
    var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;Input.parse_input_event(e);await frames(2)
func shot(name:String) -> void:
    await frames();root.get_texture().get_image().save_png(OUT+name+".png")
func _initialize() -> void:call_deferred("run")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    session=preload("res://scenes/combat/street_fight.tscn").instantiate();session.preferences_path="";session.city_save_path="";root.add_child(session)
    session.set_process(false);session.set_physics_process(false);session.audio.muted=true
    await frames(8)
    var campaign=session.city_campaign;var hub=campaign.hub
    campaign.profile.data.best=3;session.set_character(0,1);campaign.open_city();await frames(5)
    hub.close_panel();await key(KEY_H,true);await key(KEY_H,false)
    check("H cannot interrupt the hub",not hub.panel.visible)
    hub.open_station(0);await frames()
    check("tactics selectors are real native controls",hub.stack.find_children("*","OptionButton",true,false).size()==7)
    var first_selector=hub.stack.find_children("*","OptionButton",true,false).filter(func(control:Node)->bool:return control.get_meta("act","")=="tactic:0:variants")[0]
    hub.scroll.ensure_control_visible(first_selector);await frames()
    session.set_language("zh");await frames();await shot("build-zh")
    session.set_language("en");await frames();await shot("build-en")
    first_selector=hub.stack.find_children("*","OptionButton",true,false).filter(func(control:Node)->bool:return control.get_meta("act","")=="tactic:0:variants")[0]
    hub.scroll.ensure_control_visible(first_selector);await frames();first_selector.grab_focus()
    await key(KEY_SPACE,true);await key(KEY_SPACE,false);await key(KEY_DOWN,true);await key(KEY_DOWN,false);await key(KEY_ENTER,true);await key(KEY_ENTER,false)
    check("native dropdown selection updates the build",campaign.profile.data.tactics[1].variants[0]==1)
    campaign.profile.configure_tactic(1,0,"variants",0)

    hub.close_panel();campaign.flow.force_live=false;campaign.depart();await frames(5)
    session.round_theatre.clear();session.sim.arrival_left=9999;session.sim.fighters[0].meter=100
    session.sim.fighters[0].state="idle";session.sim.fighters[0].x=0;session.sim.fighters[0].face=1
    for f in session.sim.squad_members:f.x=3+int(f.squad_id)*1.4
    await key(KEY_H,true);await key(KEY_H,false)
    check("H cannot open combat help",session.screen=="play" and session.hud.menu_page=="main")
    await key(KEY_Q,true)
    for i in 40:session._combat_step();session._process(1.0/60)
    check("physical Q holds the actual story charge",session.sim.fighters[0].tactical.full and session.sim.fighters[0].meter==70)
    await shot("charge")
    await key(KEY_Q,false)
    var seen:=false
    for i in 60:
        session._combat_step();session._process(1.0/60)
        if not session.sim.tactics.shots.is_empty():seen=true;break
    check("physical release spawns a real travelling rivet",seen)
    await shot("rivet-flight")
    session.pause_game();await frames();await shot("pause")
    check("pause exposes controls without an H shortcut",session.screen=="pause")
    session.hud.open_page("help");await frames()
    check("guide remains reachable from pause",session.hud.menu_page=="help")
    session.hud.close_page();session.resume_game()
    session.set_tactic_key(0,2)
    check("rebind changes actual semantic key",session.controls.tactic_keys[0]==KEY_U)
    session.set_tactic_key(1,2)
    check("duplicate rebind swaps instead of colliding",session.controls.tactic_keys==[KEY_I,KEY_U])
    var intent:Dictionary={}
    session._offer_attack(intent,"tactic_b");session._offer_attack(intent,"light");session._offer_attack(intent,"tactic_a")
    check("simultaneous input has stable priority",intent.attack=="tactic_a")
    for hero in [0,2,3]:
        campaign.profile.data.run={};campaign.show_city();session.set_character(0,hero);campaign.selected_hero=hero;campaign.depart();session.round_theatre.clear();await frames()
        check("hero%d departure uses the saved expedition identity"%hero,session.sim.fighters[0].character==hero and campaign.profile.data.run.hero==hero)
        session.sim.arrival_left=9999;session.sim.fighters[0].meter=100
        for slot in 2:
            session.sim.fighters[0].state="idle";session.sim.fighters[0].tactical.cd=[0,0]
            if hero==3 and slot==1:session.sim.fighters[0].service.nodes=[{"x":3.0,"life":300,"id":17}]
            if hero==2 and slot==1:session.sim.fighters[0].service.sample=1
            var cast_key:Key=session.controls.tactic_keys[slot]
            await key(cast_key,true);session._combat_step();await key(cast_key,false)
            var started:bool=session.sim.fighters[0].state=="attack" and session.sim.fighters[0].move==session.sim.TacticalSkills.MOVE_NAMES[slot]
            for i in 8:
                if started:break
                session._combat_step();session._process(1.0/60)
                started=session.sim.fighters[0].state=="attack" and session.sim.fighters[0].move==session.sim.TacticalSkills.MOVE_NAMES[slot]
            check("hero%d slot%d native intent starts"%[hero,slot],started)
            for i in 20:session._combat_step();session._process(1.0/60)
            await frames()
        await shot("hero%d"%hero)
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open(OUT+"native.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failed":failed},"  "));file.close()
    session.return_to_title();session.queue_free();await frames(8);quit(1 if failed else 0)
