extends SceneTree
## Story unlock, split-keyboard versus, two gamepads, mixed devices and hot-plug.
## Injected InputEvents on Linux; not a human, real-controller or keyboard-ghosting test.
var scene:Node
var checks:Array=[]
const OUT="res://../docs/evidence/local-versus/"
const SAVE="user://verify_local_versus/progression.cfg"
const OPTIONS="user://verify_local_versus/options.cfg"
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("LOCAL_VERSUS ",label," ",ok)
    if not ok:push_error("LOCAL_VERSUS FAIL: "+label)
func key(code:int,down:bool,location:=KEY_LOCATION_UNSPECIFIED) -> void:
    var event:=InputEventKey.new()
    event.keycode=code;event.physical_keycode=code;event.pressed=down;event.location=location
    Input.parse_input_event(event)
    await process_frame;await process_frame
func button(device:int,index:int,down:bool) -> void:
    var event:=InputEventJoypadButton.new()
    event.device=device;event.button_index=index;event.pressed=down;event.pressure=1.0 if down else 0.0
    Input.parse_input_event(event)
    await process_frame;await process_frame
func axis(device:int,index:int,value:float) -> void:
    var event:=InputEventJoypadMotion.new()
    event.device=device;event.axis=index;event.axis_value=value
    Input.parse_input_event(event)
    await process_frame;await process_frame
func step(count:=1) -> void:
    for i in count:
        scene._physics_process(1.0/60);scene._process(1.0/60)
func snapshot(name:String) -> void:
    scene.hud.queue_redraw()
    await process_frame;await RenderingServer.frame_post_draw
    var img:=root.get_texture().get_image()
    img.resize(1280,720,Image.INTERPOLATE_NEAREST)
    img.save_png(OUT+name+".png")
func open_scene() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=OPTIONS;scene.progression_path=SAVE
    root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    scene.controls.pads_override=[]
    scene.controls.assign()
    await process_frame;await process_frame
func close_scene() -> void:
    scene.return_to_title();scene.queue_free();scene=null
    for i in 6:await process_frame
func settle() -> void:
    # Stand both fighters apart in neutral so one input maps to one visible result.
    scene.sim.phase="fight"
    scene.sim.fighters[0].x=-3.0;scene.sim.fighters[1].x=3.0
    step(2)
func finish_stop(player_wins:bool) -> void:
    scene.sim.phase="fight"
    scene.sim.fighters[1 if player_wins else 0].health=0
    step(2)
func next_stop() -> void:
    scene.advance_run()
    # The between-stop ability draw is answered the way a player would, with confirm.
    for i in 12:
        if not scene.ability_draw.active():break
        scene.ability_draw.confirm()
        await process_frame
func show_result_menu() -> void:
    # Skip the KO cinematic the way Enter does, then let the result menu build.
    if scene.city_breaker.active():scene.skip_city_breaker()
    scene.finish_menu_open=true;scene.result_clock=2.0;scene.hud.rebuild_menu()
    await process_frame
func attacking(side:int) -> bool:
    return scene.sim.fighters[side].state=="attack"
func idle_again() -> void:
    for i in 90:
        if scene.screen!="play":break
        if scene.sim.fighters[0].state=="idle" and scene.sim.fighters[1].state=="idle" and scene.sim.fighters[0].y<=.01 and scene.sim.fighters[1].y<=.01:break
        step()
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    for path in [SAVE,SAVE+".bak",SAVE+".tmp",OPTIONS]:
        if FileAccess.file_exists(path):DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    await open_scene()
    var hud:Control=scene.hud
    # --- Story-only start -------------------------------------------------
    check("fresh save starts with free battle locked",not scene.free_battle_unlocked() and not scene.growth.story_cleared)
    check("main menu lists story first then locked versus",hud.art_buttons.keys()==["story","fight","roster","training","settings","demo"] and hud.art.free_locked)
    check("story has the default focus",hud.art_buttons.story.has_focus())
    await snapshot("title-locked")
    hud.art_buttons.fight.pressed.emit();await process_frame
    check("locked versus button does not open a mode",scene.screen=="title" and hud.menu_page=="main" and hud.art.locked_flash>0)
    scene.start_free_battle(false);scene.start_free_battle(true)
    check("free battle entry points refuse while locked",scene.screen=="title" and not scene.versus)
    hud.art_buttons.story.release_focus()
    await key(KEY_ENTER,true);await key(KEY_ENTER,false)
    check("Enter on a locked title starts the story run",scene.screen=="play" and scene.run_active and scene.run_stage==1)
    scene.return_to_title()
    hud.open_page("roster");await process_frame
    check("fighters page offers story instead of fight while locked",hud.art_buttons.roster_fight.text=="STORY")
    hud.art_buttons.roster_fight.pressed.emit();await process_frame
    check("fighters page primary button starts the story",scene.run_active and scene.screen=="play")
    # --- Losing the last stop keeps the lock ------------------------------
    finish_stop(true);await next_stop();finish_stop(true);await next_stop()
    check("run reaches the third stop",scene.run_stage==3 and scene.screen=="play")
    finish_stop(false)
    check("losing the final stop does not unlock",scene.screen=="result" and not scene.growth.story_cleared)
    scene.return_to_title()
    # --- Clearing three stops unlocks and saves ---------------------------
    scene.start_run()
    for stop in 3:
        check("stop %d is live play"%(stop+1),scene.screen=="play" and scene.run_stage==stop+1 and not scene.free_battle_unlocked() or stop==2 and scene.screen=="play")
        finish_stop(true)
        if stop<2:
            check("winning stop %d alone keeps the lock"%(stop+1),not scene.growth.story_cleared)
            await next_stop()
    check("winning the third stop unlocks free battle",scene.growth.story_cleared and scene.free_battle_unlocked() and scene.story_unlock_fresh)
    await show_result_menu()
    var result_text:Array=[]
    for node in hud.menu_stack.find_children("*","Label",true,false):result_text.append(node.text)
    check("result screen announces the unlock",result_text.any(func(t:String)->bool:return t.contains("FREE BATTLE UNLOCKED")))
    await snapshot("story-clear")
    var stored:=ConfigFile.new()
    check("unlock is written to the save file",stored.load(SAVE)==OK and stored.get_value("save","story_cleared",false)==true and stored.get_value("save","version",0)==1)
    var reread:=preload("res://scripts/combat/last_service/progression.gd").new()
    reread.path=SAVE;reread.load_data()
    check("a new session reads the unlock and keeps XP",reread.story_cleared and reread.records[reread.Profiles.IDS[scene.run_character]].xp>0)
    await close_scene()
    # --- Restarted game stays unlocked ------------------------------------
    await open_scene();hud=scene.hud
    check("restarted game is unlocked",scene.free_battle_unlocked() and not hud.art.free_locked)
    await snapshot("title-unlocked")
    hud.art_buttons.fight.pressed.emit();await process_frame
    check("versus opens the free battle page",hud.menu_page=="versus" and hud.menu.visible)
    var actions:Array=[]
    for node in hud.menu_stack.find_children("*","Button",true,false):actions.append(node.get_meta("ui_key",""))
    check("free battle page offers CPU and local 2P",actions.has("vs_cpu") and actions.has("vs_local") and actions.has("P1 DEVICE") and actions.has("P2 DEVICE"))
    await snapshot("free-battle-page")
    # --- One keyboard, two players ----------------------------------------
    scene.start_free_battle(true)
    check("local versus is a normal match with no CPU",scene.screen=="play" and scene.versus and not scene.practice and not scene.sim.ai_enabled and not scene.sim.training and scene.sim.arcade_enabled)
    check("no gamepad splits the keyboard",scene.controls.devices[0].kind=="kb_left" and scene.controls.devices[1].kind=="kb_right")
    settle()
    await key(KEY_F,true);step(2)
    check("F attacks for P1 only",attacking(0) and not attacking(1))
    await key(KEY_F,false);idle_again()
    await key(KEY_K,true);step(2)
    check("K attacks for P2 only",attacking(1) and not attacking(0))
    await key(KEY_K,false);idle_again()
    await key(KEY_J,true);step(3)
    check("solo J is not a versus key",not attacking(0) and not attacking(1))
    await key(KEY_J,false)
    var start:Array=[scene.sim.fighters[0].x,scene.sim.fighters[1].x]
    await key(KEY_D,true);await key(KEY_LEFT,true);step(12)
    check("both players walk at the same time",scene.sim.fighters[0].x>start[0]+.2 and scene.sim.fighters[1].x<start[1]-.2)
    await key(KEY_D,false);await key(KEY_LEFT,false);step(2)
    await key(KEY_SHIFT,true,KEY_LOCATION_LEFT);step(3)
    check("left Shift guards P1 only",scene.sim.fighters[0].guarding and not scene.sim.fighters[1].guarding)
    await key(KEY_SHIFT,false,KEY_LOCATION_LEFT);step(20)
    await key(KEY_SHIFT,true,KEY_LOCATION_RIGHT);step(3)
    check("right Shift guards P2 only",scene.sim.fighters[1].guarding and not scene.sim.fighters[0].guarding)
    await key(KEY_SHIFT,false,KEY_LOCATION_RIGHT);step(20)
    await key(KEY_SPACE,true);await key(KEY_SEMICOLON,true);step(6)
    check("each player has an own jump key",scene.sim.fighters[0].y>0 and scene.sim.fighters[1].y>0)
    await key(KEY_SPACE,false);await key(KEY_SEMICOLON,false);idle_again()
    await key(KEY_KP_1,true);step(2)
    check("numpad is an alternate P2 attack",attacking(1) and not attacking(0))
    await key(KEY_KP_1,false);idle_again()
    await key(KEY_O,true);step(2)
    check("P2 skill key is not the scene-edge shortcut",not scene.ink_pass.visible and scene.screen=="play")
    await key(KEY_O,false);idle_again()
    await snapshot("versus-keyboard")
    # Two humans decide the round; P2 can win.
    scene.sim.phase="fight";scene.sim.fighters[0].health=0;step(2)
    await show_result_menu()
    var headings:Array=[]
    for node in hud.menu_stack.find_children("*","Label",true,false):headings.append(node.text)
    check("result names the winning player",scene.screen=="result" and scene.sim.winner==1 and headings.has("P2 WINS"))
    scene.sim.round_number=2
    check("two-human matches skip the one-sided ability draw",scene.ability_draw_boundary()=="")
    scene.sim.round_number=1
    await key(KEY_ENTER,true);await key(KEY_ENTER,false)
    check("next round keeps both humans",scene.screen=="play" and scene.versus and not scene.sim.ai_enabled)
    scene.pause_game();await key(KEY_R,true);await key(KEY_R,false)
    check("restart keeps local versus",scene.screen=="play" and scene.versus and not scene.sim.ai_enabled and scene.sim.wins==[0,0])
    # --- Two gamepads ------------------------------------------------------
    scene.return_to_title()
    scene.controls.pads_override=[0,1];scene._on_joy_connection(0,true);scene._on_joy_connection(1,true)
    scene.start_free_battle(true)
    var intro_shown:bool=scene.round_theatre.intro
    await button(1,JOY_BUTTON_A,true);await button(1,JOY_BUTTON_A,false)
    check("gamepad A skips the round intro",intro_shown and not scene.round_theatre.intro and scene.screen=="play")
    settle()
    check("two gamepads take both players",scene.controls.devices[0]=={"kind":"pad","id":0} and scene.controls.devices[1]=={"kind":"pad","id":1})
    await button(0,JOY_BUTTON_X,true);step(2)
    check("gamepad 1 X attacks for P1 only",attacking(0) and not attacking(1))
    await button(0,JOY_BUTTON_X,false);idle_again()
    await button(1,JOY_BUTTON_X,true);step(2)
    check("gamepad 2 X attacks for P2 only",attacking(1) and not attacking(0))
    await button(1,JOY_BUTTON_X,false);idle_again()
    start=[scene.sim.fighters[0].x,scene.sim.fighters[1].x]
    await axis(0,JOY_AXIS_LEFT_X,.9);await button(1,JOY_BUTTON_DPAD_LEFT,true);step(12)
    check("stick and d-pad both move",scene.sim.fighters[0].x>start[0]+.2 and scene.sim.fighters[1].x<start[1]-.2)
    await axis(0,JOY_AXIS_LEFT_X,.1);await button(1,JOY_BUTTON_DPAD_LEFT,false);step(2)
    start=[scene.sim.fighters[0].x,scene.sim.fighters[1].x];step(10)
    check("stick inside the dead zone stops",absf(scene.sim.fighters[0].x-start[0])<.05)
    await axis(1,JOY_AXIS_TRIGGER_RIGHT,1.0);step(3)
    check("trigger guards for its own player",scene.sim.fighters[1].guarding and not scene.sim.fighters[0].guarding)
    await axis(1,JOY_AXIS_TRIGGER_RIGHT,0.0);step(20)
    await button(0,JOY_BUTTON_A,true);step(6)
    check("A jumps",scene.sim.fighters[0].y>0 and scene.sim.fighters[1].y<=.01)
    await button(0,JOY_BUTTON_A,false);idle_again()
    await key(KEY_F,true);step(2)
    check("keyboard halves are off when both players hold gamepads",not attacking(0) and not attacking(1))
    await key(KEY_F,false)
    await snapshot("versus-gamepads")
    await button(1,JOY_BUTTON_START,true);await button(1,JOY_BUTTON_START,false)
    check("Start pauses",scene.screen=="pause")
    await button(0,JOY_BUTTON_START,true);await button(0,JOY_BUTTON_START,false)
    check("Start resumes",scene.screen=="play")
    # --- Hot-plug ----------------------------------------------------------
    scene.controls.pads_override=[0];scene._on_joy_connection(1,false)
    check("unplugging an active gamepad pauses",scene.screen=="pause")
    check("the unplugged player falls back to the keyboard",scene.controls.devices[0]=={"kind":"pad","id":0} and scene.controls.devices[1].kind=="kb_solo")
    await snapshot("gamepad-unplugged")
    scene.resume_game();settle()
    await key(KEY_J,true);step(2)
    check("fallback keyboard plays P2 at once",attacking(1) and not attacking(0))
    await key(KEY_J,false);idle_again()
    scene.controls.pads_override=[0,1];scene._on_joy_connection(1,true)
    check("replugging restores the gamepad without a restart",scene.screen=="play" and scene.controls.devices[1]=={"kind":"pad","id":1})
    await button(1,JOY_BUTTON_Y,true);step(2)
    check("replugged gamepad attacks again",attacking(1))
    await button(1,JOY_BUTTON_Y,false);idle_again()
    # --- Mixed keyboard and gamepad ---------------------------------------
    scene.return_to_title()
    scene.controls.pads_override=[4];scene._on_joy_connection(4,true)
    scene.start_free_battle(true);settle()
    check("one gamepad goes to P2 and P1 keeps the full keyboard",scene.controls.devices[0].kind=="kb_solo" and scene.controls.devices[1]=={"kind":"pad","id":4})
    await key(KEY_J,true);step(2)
    check("mixed: keyboard J is P1",attacking(0) and not attacking(1))
    await key(KEY_J,false);idle_again()
    await button(4,JOY_BUTTON_X,true);step(2)
    check("mixed: gamepad X is P2",attacking(1) and not attacking(0))
    await button(4,JOY_BUTTON_X,false);idle_again()
    scene.return_to_title()
    scene.set_device(0,scene.controls.GAMEPAD)
    scene.start_free_battle(true)
    check("P1 can claim the only gamepad",scene.controls.devices[0]=={"kind":"pad","id":4} and scene.controls.devices[1].kind=="kb_solo")
    scene.return_to_title()
    scene.set_device(1,scene.controls.GAMEPAD)
    scene.start_free_battle(true)
    check("a missing second gamepad falls back with a warning",scene.controls.devices[1].kind=="kb_solo" and scene.controls.fallback[1] and scene.controls.describe(1).contains("NO GAMEPAD"))
    scene.return_to_title()
    var saved:=ConfigFile.new()
    check("device choices are saved",saved.load(OPTIONS)==OK and saved.get_value("options","p1_device",0)==2 and saved.get_value("options","p2_device",0)==2)
    scene.set_device(0,0);scene.set_device(1,0)
    # --- Gamepad in single-player modes -----------------------------------
    scene.start_run();settle()
    check("story is single player against the CPU",scene.run_active and not scene.versus and scene.sim.ai_enabled)
    scene.sim.ai_enabled=false
    await button(4,JOY_BUTTON_X,true);step(2)
    check("a gamepad plays P1 in story",attacking(0))
    await button(4,JOY_BUTTON_X,false);idle_again()
    await key(KEY_J,true);step(2)
    check("the keyboard still plays P1 beside the gamepad",attacking(0))
    await key(KEY_J,false);idle_again()
    start=[scene.sim.fighters[0].x,scene.sim.fighters[1].x]
    await axis(4,JOY_AXIS_LEFT_X,-1.0);step(12)
    check("stick moves P1 and never P2 in story",scene.sim.fighters[0].x<start[0]-.2 and absf(scene.sim.fighters[1].x-start[1])<.01)
    await axis(4,JOY_AXIS_LEFT_X,0.0);step(2)
    scene.return_to_title();await process_frame;await process_frame
    # --- Gamepad drives the menus -----------------------------------------
    hud.art_buttons.story.grab_focus();await process_frame
    await button(4,JOY_BUTTON_DPAD_DOWN,true);await button(4,JOY_BUTTON_DPAD_DOWN,false)
    check("d-pad moves the menu focus",hud.art_buttons.fight.has_focus())
    await button(4,JOY_BUTTON_A,true);await button(4,JOY_BUTTON_A,false)
    check("A confirms a menu entry",hud.menu_page=="versus")
    await button(4,JOY_BUTTON_B,true);await button(4,JOY_BUTTON_B,false)
    check("B goes back",hud.menu_page=="main")
    hud.open_page("versus");await process_frame
    var picker:Control=hud.menu_stack.find_children("*","OptionButton",true,false)[0]
    picker.grab_focus();await process_frame
    await button(4,JOY_BUTTON_A,true);await button(4,JOY_BUTTON_A,false)
    check("A cycles a device choice",scene.controls.wanted[0]==scene.controls.KEYBOARD)
    scene.set_device(0,0);hud.close_page()
    # --- Relock for replaying the unlock ----------------------------------
    scene.relock_free_battle()
    reread.load_data()
    check("relock clears the saved flag only",not scene.free_battle_unlocked() and not reread.story_cleared and reread.records[reread.Profiles.IDS[0]].xp>0)
    await close_scene()
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"passed":checks.size()-failed,"failed":failed,"scope":"Linux Compatibility rendering under Xvfb; injected InputEvents and an injected gamepad list, Dummy audio. Not a real controller, keyboard-ghosting, human feel, Mac or GPU validation."},"  "))
    print("LOCAL_VERSUS_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(1 if failed else 0)
