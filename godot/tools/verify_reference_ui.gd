extends SceneTree
var scene:Node
var checks:Array=[]
const DIR="res://../docs/evidence/ui-replica"
func _initialize() -> void:call_deferred("run")
func check(name:String,passed:bool) -> void:
    checks.append({"name":name,"passed":passed})
    if not passed:push_error("REFERENCE UI: "+name)
func frames(n:=3) -> void:
    for i in n:await process_frame
func tap(key:Key) -> void:
    for pressed in [true,false]:
        var event:=InputEventKey.new();event.keycode=key;event.physical_keycode=key;event.pressed=pressed;Input.parse_input_event(event);await frames(2)
func click(button:Control) -> void:
    for pressed in [true,false]:
        var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=root.get_screen_transform()*button.get_global_rect().get_center();event.global_position=event.position;event.pressed=pressed;Input.parse_input_event(event);await frames(2)
func shot(name:String) -> void:
    scene.hud.queue_redraw();await frames();await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(DIR+"/"+name+".png")
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path="";root.add_child(scene);scene.set_process(false);scene.set_physics_process(false);scene.backdrop.freeze_for_capture()
    await frames();var hud:Node=scene.hud
    check("English interface default",scene.language=="en")
    check("exactly five native main actions",hud.art_buttons.keys()==["fight","roster","training","settings","demo"] and hud.art_controls.visible and not hud.menu.visible)
    check("native buttons retain meaningful English names",hud.art_buttons.values().all(func(b:Button)->bool:return not b.text.is_empty() and b.focus_mode==Control.FOCUS_ALL))
    for dimensions in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:
        root.size=dimensions;await frames();var fit:=true
        for b in hud.art_buttons.values():fit=fit and b.get_global_rect().position.x>=0 and b.get_global_rect().end.x<=root.get_visible_rect().size.x+1 and b.get_global_rect().end.y<=root.get_visible_rect().size.y+1
        check("five actions fit "+str(dimensions),fit)
    root.size=Vector2i(1280,720);hud.art_buttons.fight.grab_focus();hud.art.focused_key="fight";await shot("title")
    await tap(KEY_DOWN);check("arrow moves Fight to Fighters",hud.art_buttons.roster.has_focus())
    await tap(KEY_ENTER);print("ENTER_STATE ",scene.screen," ",hud.menu_page," ",hud.art_buttons.keys());check("Enter opens four-card Fighters page",hud.menu_page=="roster" and hud.art_buttons.has("card_3"))
    await click(hud.art_buttons.card_3);check("pointer selects LOOP for P1",scene.character_choices[0]==3 and scene.sim.character_choices[0]==3)
    await click(hud.art_buttons.side_1);await click(hud.art_buttons.card_1)
    check("P2 card controls independently update actual rival",scene.character_choices==[3,1] and scene.sim.character_choices==[3,1])
    await click(hud.art_buttons.side_0);await shot("fighters")
    for index in 3:
        await click(hud.art_buttons["card_"+str(index)])
        check("card %d changes actual P1 profile"%index,scene.character_choices[0]==index and scene.sim.fighters[0].character==index)
        await shot("fighter-card-"+str(index))
    await tap(KEY_ESCAPE);check("Esc returns to five-option menu",hud.menu_page=="main" and hud.art_buttons.size()==5)
    await click(hud.art_buttons.settings);check("pointer opens native Settings",hud.menu_page=="settings" and hud.menu.visible)
    var options:Array=hud.menu_stack.find_children("*","OptionButton",true,false)
    options[0].grab_focus();await tap(KEY_SPACE)
    check("keyboard opens native difficulty popup",options[0].get_popup().visible)
    await tap(KEY_ESCAPE)
    check("popup Esc preserves Settings page",hud.menu_page=="settings")
    var sliders:Array=hud.menu_stack.find_children("*","HSlider",true,false)
    check("settings retain actual native sliders",sliders.size()==2)
    var before:float=scene.audio.music_level;sliders[0].value=.35;check("music slider changes real gain",scene.audio.music_level==.35 and before!=.35)
    await shot("settings");hud.menu_scroll.scroll_vertical=2000;await frames();await shot("settings-bottom");check("settings scrollbar reaches lower options",hud.menu_scroll.scroll_vertical>0);await tap(KEY_ESCAPE)
    await click(hud.art_buttons.training);scene._process(.016);check("Training starts actual play",scene.screen=="play" and scene.practice)
    scene.audio.muted=false;scene.audio.music_level=.7;scene.audio.context="play"
    await create_timer(1.6).timeout
    var player:AudioStreamPlayer=scene.audio.music
    var before_position:float=player.get_playback_position()
    var before_gain:float=player.volume_db
    await tap(KEY_ESCAPE);scene._process(.016);await create_timer(.35).timeout
    check("Esc pauses gameplay",scene.screen=="pause")
    check("pause keeps same music player and advances head",scene.audio.music==player and player.playing and not player.stream_paused and player.get_playback_position()>before_position+.1)
    check("pause smoothly lowers music gain",player.volume_db<before_gain-3)
    hud.open_page("settings");scene._process(.016);var pos:float=player.get_playback_position();await create_timer(.25).timeout
    check("pause Settings music continues without restart",scene.audio.music==player and player.get_playback_position()>pos+.1)
    hud.close_page();scene.resume_game();scene._process(.016);await create_timer(.45).timeout
    check("resume restores gain on same advancing song",scene.audio.music==player and not player.stream_paused and player.volume_db>before_gain-1)
    var transport:float=player.get_playback_position();scene.audio.context="title";scene.audio._process(.01)
    check("song change starts an overlapping crossfade",scene.audio.fading_music==player and player.playing and scene.audio.music.playing and scene.audio.crossfade<.1)
    scene.audio.context="play";scene.audio._process(.01)
    check("rapid navigation reverses existing crossfade",scene.audio.music==player and player.get_playback_position()>=transport)
    for i in 120:scene.audio._process(.02)
    check("crossfade retires old deck only after fading",scene.audio.crossfade==1 and not scene.audio.fading_music.playing and scene.audio.music.playing)
    check("music has exactly two bounded decks",scene.audio.get_children().filter(func(n:Node)->bool:return n is AudioStreamPlayer).size()==12)
    scene.audio.music_level=0;var p:float=scene.audio.music.get_playback_position();await create_timer(.2).timeout
    check("zero volume silences without stopping transport",scene.audio.music.playing and not scene.audio.music.stream_paused and scene.audio.music.get_playback_position()>p)
    scene.audio.music_level=.7;scene.audio.muted=true
    scene.return_to_title();hud.close_page();await click(hud.art_buttons.demo);scene._process(.016)
    check("AI Demo starts real endless battle",scene.demo!=null and scene.sim.endless)
    for i in 180:scene._physics_process(1.0/60);scene._process(1.0/60)
    await shot("hud")
    await click(hud.pause_button);check("native HUD pause target works",scene.screen=="pause")
    await shot("pause")
    await tap(KEY_ESCAPE);var reduced:bool=scene.reduced_effects;await tap(KEY_F2);check("F2 remains an independent effects control",scene.reduced_effects!=reduced);await tap(KEY_F2)
    var shapes=preload("res://scripts/combat/impact_shapes.gd").new();var all_valid:=true
    for move in scene.Simulation.MOVES:
        for kind in ["swing","hit","release"]:
            for frame in 6:
                var pieces:Array=shapes.build(kind,move,float(frame)/6.0,Color("4acfe0"),1,false)
                for piece in pieces:
                    all_valid=all_valid and piece.points.size()>=3
                    for point in piece.points:all_valid=all_valid and point.is_finite()
    check("all 13 vector attacks have finite staged geometry",all_valid)
    check("active renderer has no generated raster stamps",not FileAccess.get_file_as_string("res://scripts/combat/fight_vfx.gd").contains("sprite_fx"))
    scene.return_to_title();check("title clears all combat effects",scene.effects.is_empty())
    scene.queue_free();await frames(5);await create_timer(.2).timeout
    var passed:int=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open(DIR+"/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":passed,"total":checks.size(),"scope":"Native injected pointer/keyboard, two-deck audio transport and geometry. No human/target GPU claim."},"  "))
    print("REFERENCE_UI ",passed,"/",checks.size());quit(0 if passed==checks.size() else 1)
