extends Control
## Native game UI; the world stays visible and gameplay copy is localized centrally.
const Tokens = preload("res://scripts/combat/ui/ui_theme.gd")
const Copy = preload("res://scripts/combat/ui/ui_text.gd")
const INK := Tokens.INK
const PAPER := Tokens.PAPER
const YELLOW := Tokens.GOLD
var session: Node3D
var menu: PanelContainer
var menu_scroll: ScrollContainer
var menu_stack: VBoxContainer
var layout_root: Control
var service_art=preload("res://scripts/combat/last_service/presentation.gd").new()
var art=preload("res://scripts/combat/ui/reference_art.gd").new()
var title_motion:Node
var roster_preview:Node
var audio_restore:Button
var art_controls:Control
var art_buttons:Dictionary={}
var coach_continue:Button
var pause_button:Button
var menu_page := "main"
var previous_screen := ""
var built_page := ""
var focus_key := ""
var page_return_focus := ""
var skill_key := ""
var skill_time := 0.0
var notice := ""
var notice_time := 0.0
var font: Font=Tokens.BODY
var bold: Font=Tokens.DISPLAY
var copy := Copy.new()
var vfx_renderer := preload("res://scripts/combat/fight_vfx.gd").new()
var choice_buttons: Array[Button]=[]
var choice_skin := [-1,-1,-1]
var back_button: Button
var air_lesson: Button
var air_begin: Button
var air_parry: Button
var air_choices: Array[Button]=[]
var air_choice_skin:=[-1,-1]
var demo_buttons: Array[Button]=[]
var drill_start: Button
var health_lag := [100.0,100.0]
var last_health := [100.0,100.0]
var health_delay := [0.0,0.0]

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    theme=Tokens.build()
    layout_root=Control.new()
    layout_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
    layout_root.size=Vector2(1280,720)
    add_child(layout_root)
    art_controls=Control.new()
    art_controls.mouse_filter=Control.MOUSE_FILTER_IGNORE
    layout_root.add_child(art_controls)
    title_motion=preload("res://scripts/combat/ui/title_motion.gd").new()
    add_child(title_motion)
    art.title_stage=title_motion
    roster_preview=preload("res://scripts/combat/ui/roster_preview.gd").new()
    add_child(roster_preview)
    for i in 3:
        var button:=Button.new()
        button.position=Vector2(346+i*198,578)
        button.size=Vector2(190,44)
        button.add_theme_font_size_override("font_size",19)
        button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
        var choice: String=session.sim.exchange.CHOICES[i]
        button.pressed.connect(func():session.commit_clash_choice(choice))
        button.set_meta("ui_key","choice_"+choice)
        layout_root.add_child(button)
        choice_buttons.append(button)
    for i in 2:
        var button:=Button.new()
        button.position=Vector2(938+i*154,112)
        button.size=Vector2(146,34)
        var restart: bool=i==0
        button.pressed.connect(func():
            if restart:session.start_demo()
            else:session.return_to_title()
            button.release_focus())
        layout_root.add_child(button)
        demo_buttons.append(button)
    drill_start=Button.new()
    drill_start.position=Vector2(750,539)
    drill_start.size=Vector2(182,30)
    drill_start.add_theme_font_size_override("font_size",14)
    drill_start.pressed.connect(func():session.pending["attack"]="heavy")
    drill_start.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    layout_root.add_child(drill_start)
    air_lesson=Button.new()
    air_lesson.position=Vector2(1005,116)
    air_lesson.size=Vector2(241,36)
    air_lesson.set_meta("ui_key","air_lesson")
    air_lesson.pressed.connect(func():
        if session.sim.is_air_lesson():session.prime_air_drill()
        else:session.prime_air_defense())
    layout_root.add_child(air_lesson)
    air_begin=Button.new()
    air_begin.position=Vector2(494,611)
    air_begin.size=Vector2(292,36)
    air_begin.set_meta("ui_key","air_begin")
    air_begin.pressed.connect(func():session.pending["lesson_start"]=true)
    layout_root.add_child(air_begin)
    air_parry=Button.new()
    air_parry.position=Vector2(494,611)
    air_parry.size=Vector2(292,36)
    air_parry.set_meta("ui_key","air_parry")
    air_parry.pressed.connect(func():session.pending["guard_pressed"]=true)
    layout_root.add_child(air_parry)
    for index in 2:
        var button:=Button.new()
        button.position=Vector2(422+index*226,611)
        button.size=Vector2(210,36)
        button.set_meta("ui_key","air_"+["kick","escape"][index])
        var choice: String=["kick","escape"][index]
        button.pressed.connect(func():session.commit_air_choice(choice))
        layout_root.add_child(button)
        air_choices.append(button)
    for button in [air_lesson,air_begin,air_parry]+air_choices:
        button.add_theme_font_size_override("font_size",16)
        button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
        button.pressed.connect(button.release_focus)
    menu=PanelContainer.new()
    menu.add_theme_stylebox_override("panel",Tokens.plate(Color(INK,.94),Tokens.EDGE,2))
    layout_root.add_child(menu)
    menu_scroll=ScrollContainer.new()
    menu_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    menu_scroll.follow_focus=true
    menu.add_child(menu_scroll)
    menu_stack=VBoxContainer.new()
    menu_stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    menu_stack.add_theme_constant_override("separation",14)
    menu_scroll.add_child(menu_stack)
    back_button=Button.new()
    back_button.position=Vector2(360,28)
    back_button.size=Vector2(156,34)
    back_button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    for state in ["normal","hover","pressed"]:back_button.add_theme_stylebox_override(state,Tokens.plate(PAPER,INK,2))
    for state in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:back_button.add_theme_color_override(state,INK)
    back_button.add_theme_constant_override("outline_size",0)
    back_button.add_theme_font_override("font",Tokens.DISPLAY)
    back_button.add_theme_font_size_override("font_size",26)
    back_button.pressed.connect(close_page)
    layout_root.add_child(back_button)
    audio_restore=Button.new()
    audio_restore.text="SOUND OFF / RESTORE"
    audio_restore.position=Vector2(906,600);audio_restore.size=Vector2(334,54)
    audio_restore.add_theme_font_size_override("font_size",28)
    audio_restore.pressed.connect(_restore_sound)
    layout_root.add_child(audio_restore)
    pause_button=Button.new()
    pause_button.text="II  PAUSE"
    pause_button.position=Vector2(1094,94);pause_button.size=Vector2(150,42)
    pause_button.add_theme_font_override("font",Tokens.DISPLAY)
    pause_button.add_theme_font_size_override("font_size",Tokens.ACTION_SIZE)
    for state in ["normal","hover","pressed"]:pause_button.add_theme_stylebox_override(state,Tokens.plate(PAPER,INK,2))
    for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:pause_button.add_theme_color_override(state,INK)
    pause_button.add_theme_constant_override("outline_size",0)
    pause_button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    pause_button.pressed.connect(session.pause_game)
    pause_button.visible=false
    layout_root.add_child(pause_button)
    coach_continue=Button.new()
    coach_continue.position=Vector2(450,590);coach_continue.size=Vector2(380,42)
    coach_continue.add_theme_font_size_override("font_size",28)
    coach_continue.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    coach_continue.set_meta("ui_key","coach_continue")
    coach_continue.pressed.connect(func():session.continue_coach();coach_continue.release_focus())
    coach_continue.visible=false
    layout_root.add_child(coach_continue)
    resized.connect(_resize_layout)
    _resize_layout()
    rebuild_menu()

func _resize_layout() -> void:
    if is_instance_valid(layout_root):layout_root.scale=size/Vector2(1280,720)

func tr_text(key: String) -> String:
    return copy.text(key)

func rebuild_menu(requested_focus := "") -> void:
    copy.language=session.language
    var preserve_scroll: bool = previous_screen==session.screen and built_page==menu_page
    var focused:=get_viewport().gui_get_focus_owner()
    if requested_focus!="":focus_key=requested_focus
    elif focused and focused.has_meta("ui_key"):focus_key=focused.get_meta("ui_key")
    if previous_screen!=session.screen:
        menu_page="main"
        focus_key=""
        previous_screen=session.screen
    built_page=menu_page
    var old_scroll:=menu_scroll.scroll_vertical
    for child in menu_stack.get_children():
        menu_stack.remove_child(child)
        child.queue_free()
    art_controls.visible=false
    menu.visible=session.screen!="play" and not (session.demo!=null and session.screen=="result") and not session.result_presentation_active()
    back_button.visible=menu.visible and menu_page!="main"
    back_button.text="ESC  BACK"
    if not menu.visible:
        _sync_choices()
        _sync_air_controls()
        return
    if session.screen=="title" and menu_page in ["main","roster"]:
        menu.visible=false
        back_button.visible=false
        _build_art_controls()
        _sync_choices();_sync_air_controls()
        call_deferred("_restore_focus")
        queue_redraw()
        return
    back_button.position=Vector2(1062,663)
    back_button.size=Vector2(174,39)
    if menu_page=="roster":
        menu.position=Vector2(52,230)
        menu.size=Vector2(450,434)
    elif menu_page!="main":
        menu.position=Vector2(250,133)
        menu.size=Vector2(780,510)
    elif session.screen=="title":
        menu.position=Vector2(52,230)
        menu.size=Vector2(450,434)
    else:
        menu.position=Vector2(340,141)
        menu.size=Vector2(600,500 if session.screen in ["pause","help"] else 440)
    menu.add_theme_stylebox_override("panel",Tokens.plate(Color.TRANSPARENT if session.screen=="title" and menu_page=="main" else Color(INK,.96),Tokens.EDGE if menu_page!="main" else Color.TRANSPARENT,2 if menu_page!="main" else 0))
    if menu_page=="skills":_skills_page()
    elif menu_page=="settings":_settings_page()
    elif menu_page=="roster":_roster_page()
    elif menu_page=="help":_help_page()
    elif session.screen=="title":_title_page()
    elif session.screen in ["pause","help"]:_pause_page()
    elif session.screen=="result":_result_page()
    menu_scroll.set_deferred("scroll_vertical",old_scroll if preserve_scroll else 0)
    call_deferred("_restore_focus")
    _sync_choices()
    _sync_air_controls()
    queue_redraw()

func _restore_focus() -> void:
    if art_controls.visible:
        var target:String=focus_key if art_buttons.has(focus_key) else ("card_"+str(session.character_choices[art.roster_side]) if menu_page=="roster" else "fight")
        art_buttons[target].grab_focus()
        return
    if not menu.visible:return
    if focus_key=="back" and back_button.visible:
        back_button.grab_focus()
        return
    var first: Control=null
    for control in menu_stack.find_children("*","Control",true,false):
        if not control is BaseButton and not control is Range:continue
        if not first:first=control
        if control.get_meta("ui_key","")==focus_key:
            control.grab_focus()
            return
    if first:first.grab_focus()

func _label(value: String, point_size: int, tint := PAPER, display := false) -> Label:
    var label:=Label.new()
    label.text=value
    label.add_theme_font_size_override("font_size",maxi(Tokens.CAPTION_SIZE,point_size))
    label.add_theme_constant_override("line_spacing",6)
    label.add_theme_color_override("font_color",tint)
    if display:label.add_theme_font_override("font",bold)
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    return label

func _caption(key: String) -> void:
    menu_stack.add_child(_label(tr_text(key),13,Tokens.MUTED))

func _heading(key: String) -> void:
    menu_stack.add_child(_label(tr_text(key),28))
    var separator:=HSeparator.new()
    separator.add_theme_color_override("color",Tokens.EDGE)
    menu_stack.add_child(separator)

func _action(parent: Node, key: String, shortcut: String, callback: Callable, primary := false) -> Button:
    var button:=Button.new()
    button.text=tr_text(key)
    button.alignment=HORIZONTAL_ALIGNMENT_LEFT
    button.custom_minimum_size=Vector2(0,60)
    button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    button.add_theme_font_size_override("font_size",Tokens.ACTION_SIZE)
    button.set_meta("ui_key",key)
    if primary:
        button.add_theme_stylebox_override("normal",Tokens.plate(Tokens.MAGENTA,INK,2))
        button.add_theme_color_override("font_color",INK)
        button.add_theme_color_override("font_focus_color",INK)
    if key in ["roster","controls","settings","demo","explore"]:
        button.add_theme_stylebox_override("normal",Tokens.plate(INK,Tokens.EDGE,1))
        button.add_theme_color_override("font_color",PAPER)
        button.add_theme_color_override("font_focus_color",PAPER)
    if key in ["roster","controls","settings","demo","explore"]:
        button.tooltip_text=button.text+(" · "+shortcut if shortcut!="" else "")
        shortcut=""
    if shortcut!="":
        var badge:=Label.new()
        badge.text=shortcut
        badge.add_theme_font_size_override("font_size",24)
        badge.add_theme_color_override("font_color",INK)
        badge.add_theme_color_override("font_outline_color",INK)
        badge.add_theme_constant_override("outline_size",0)
        badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
        badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        badge.offset_right=-16
        badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
        badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
        button.add_child(badge)
        var highlight:=func():badge.add_theme_color_override("font_color",INK)
        var restore:=func():badge.add_theme_color_override("font_color",INK)
        button.mouse_entered.connect(highlight)
        button.mouse_exited.connect(restore)
        button.button_down.connect(highlight)
        button.button_up.connect(restore)
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _title_page() -> void:
    _action(menu_stack,"fight","Enter",func():session.start_match(false),true)
    _caption("fight_hint")
    _action(menu_stack,"training","T",func():session.start_match(true))
    _caption("training_hint")
    var labs:=HBoxContainer.new()
    labs.add_theme_constant_override("separation",8)
    menu_stack.add_child(labs)
    var rally_button:=_action(labs,"rally_lab","F10",func():
        session.start_match(true)
        session.prime_rally_drill())
    rally_button.text=tr_text("rally_short")
    var air_button:=_action(labs,"air_lab","F11",func():
        session.start_match(true)
        session.prime_air_drill())
    for button in [rally_button,air_button]:
        button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size",17)
    _action(menu_stack,"drill","F8",func():
        session.start_match(true)
        session.prime_pressure_drill())
    _caption("drill_hint")
    var row:=HBoxContainer.new()
    row.add_theme_constant_override("separation",8)
    menu_stack.add_child(row)
    for key in ["roster","controls","settings"]:
        var page: String="help" if key=="controls" else key
        var shortcut:String={"controls":"H","settings":"F1"}.get(key,"")
        var button:=_action(row,key,shortcut,func():open_page(page))
        button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size",15)
        button.custom_minimum_size.y=38
    var bottom:=HBoxContainer.new()
    bottom.add_theme_constant_override("separation",8)
    menu_stack.add_child(bottom)
    var demo_button:=_action(bottom,"demo","F12",func():session.start_demo())
    demo_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    demo_button.add_theme_font_size_override("font_size",15)
    demo_button.custom_minimum_size.y=36
    var explore:=_action(bottom,"explore","F6",func():session.return_to_street())
    explore.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    explore.add_theme_font_size_override("font_size",15)
    explore.custom_minimum_size.y=36

func _pause_page() -> void:
    _action(menu_stack,"resume","Esc",func():session.resume_game(),true)
    if session.demo!=null:_action(menu_stack,"demo_restart","R",func():session.start_demo())
    else:_action(menu_stack,"reset_training" if session.practice else "restart","F5" if session.practice else "R",func():
        if session.practice:session.reset_training()
        elif session.run_active:session.start_run()
        else:session.start_match(false))
    _action(menu_stack,"settings","F1",func():open_page("settings"))
    _action(menu_stack,"controls","H",func():open_page("help"))
    _action(menu_stack,"main_menu","",func():session.return_to_title())

func _result_page() -> void:
    _heading("draw" if session.sim.winner<0 else ("win" if session.sim.winner==0 else "lose"))
    if session.run_active:
        menu_stack.add_child(_label("STOP %d / +%d XP / %d SKILL POINTS"%[session.run_stage,session.run_reward,session.growth.points(session.run_character)],28))
        if session.sim.winner==0 and session.run_stage<3:
            _plain_action("NEXT STOP","next_stop",session.advance_run)
        else:_plain_action("RETURN TO FIGHTERS","end_run",func():session.return_to_title();open_page("roster"))
        _plain_action("SKILLS / FREE RESPEC","skills",func():open_page("skills"))
        return
    if session.sim.winner==1:_caption("runback")
    menu_stack.add_child(_label("%d  —  %d"%[session.sim.wins[0],session.sim.wins[1]],48,Tokens.GOLD,true))
    _caption("wins")
    var complete: bool=session.sim.phase=="match_over"
    _action(menu_stack,"rematch" if complete else "next_round","Enter",func():
        if complete:session.start_match(session.practice)
        else:session.advance_round(),true)
    _action(menu_stack,"main_menu","",func():session.return_to_title())

func open_page(page: String) -> void:
    if session.screen=="play":session.pause_game()
    page_return_focus="controls" if page=="help" else page
    menu_page=page
    focus_key="back"
    rebuild_menu("back")

func close_page() -> void:
    menu_page="main" if menu_page!="skills" else ("roster" if session.screen=="title" else "main")
    focus_key=page_return_focus
    rebuild_menu(page_return_focus)

func handle_shortcut(event: InputEvent) -> bool:
    if event.keycode==KEY_ESCAPE and menu_page!="main" and session.screen!="play":
        close_page()
        return true
    if event.keycode==KEY_F1:
        open_page("settings")
        return true
    if event.keycode==KEY_H:
        open_page("help")
        return true
    return false

func _choice(key: String, items: Array, selected: int, callback: Callable) -> void:
    var caption:=_label(tr_text(key),15,Tokens.MUTED)
    menu_stack.add_child(caption)
    var control:=OptionButton.new()
    control.custom_minimum_size.y=58
    control.set_meta("ui_key",key)
    control.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    for item in items:control.add_item(tr_text(item))
    control.select(selected)
    control.item_selected.connect(callback)
    menu_stack.add_child(control)

func _toggle(key: String, enabled: bool, callback: Callable) -> void:
    var button:=CheckButton.new()
    button.text=tr_text(key)
    button.button_pressed=enabled
    button.custom_minimum_size.y=56
    button.set_meta("ui_key",key)
    button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    button.toggled.connect(callback)
    menu_stack.add_child(button)

func _volume(key: String, value: float) -> void:
    var label:=_label(tr_text(key)+"  %d%%"%roundi(value*100),15,Tokens.MUTED)
    menu_stack.add_child(label)
    var slider:=HSlider.new()
    slider.min_value=0
    slider.max_value=1
    slider.step=.05
    slider.value=value
    slider.custom_minimum_size.y=42
    slider.set_meta("ui_key",key+"_volume")
    slider.value_changed.connect(func(level:float):
        label.text=tr_text(key)+"  %d%%"%roundi(level*100)
        session.set_volume(key,level))
    menu_stack.add_child(slider)

func _settings_page() -> void:
    _choice("difficulty",["relaxed","standard","challenging"],session.run_base_difficulty if session.run_active else session.sim.difficulty,session.set_difficulty)
    _caption("difficulty_hint")
    if session.sim.is_air_lesson():_caption("air_fixed_partner")
    elif session.demo==null and (session.practice or session.screen=="title"):_choice("partner",["standing","guarding","sparring"],session.sim.partner_mode,session.set_partner_mode)
    _toggle("muted",session.audio.muted,func(value:bool):
        session.audio.muted=value
        session.audio.stop_all()
        session.save_options())
    _toggle("music_enable",not session.audio.music_muted,func(value:bool):
        session.audio.music_muted=not value
        session.save_options())
    menu_stack.add_child(_label(session.audio.music_credit,14,Tokens.MUTED))
    _volume("music",session.audio.music_level)
    _volume("sound",session.audio.effects_level)
    menu_stack.add_child(_label(session.audio.status_text(),17,PAPER))
    _action(menu_stack,"test_audio","",func():session.audio.play_sound("parry",1.0,0.0))
    _action(menu_stack,"restore_audio","",_restore_sound)
    _toggle("reduced",session.reduced_effects,func(value:bool):
        session.reduced_effects=value
        session.save_options())
    _toggle("scene_edges",session.ink_pass.visible,func(value:bool):
        session.ink_pass.visible=value
        session.save_options())
    _toggle("training_details",session.training_details,func(value:bool):
        session.training_details=value
        session.save_options())
    _caption("settings_saved")

func _roster_page() -> void:
    _heading("roster")
    var labels:Array=[]
    for entry in preload("res://scripts/combat/fighter_roster.gd").ENTRIES:labels.append(entry.label)
    _choice("player_character",labels,session.character_choices[0],func(index:int):session.set_character(0,index))
    _choice("rival_character",labels,session.character_choices[1],func(index:int):session.set_character(1,index))
    for side in 2:
        var entry:Dictionary=session.FighterVisual.Roster.entry(session.character_choices[side])
        menu_stack.add_child(_label(tr_text("you" if side==0 else "rival")+" · "+tr_text(entry.trait),14,Tokens.LIME))
        var profile:Dictionary=session.Simulation.Profiles.profile(session.character_choices[side])
        menu_stack.add_child(_label("L · "+tr_text(profile.special_name)+" / W+L · "+tr_text(profile.overdrive_name),12,PAPER))
    _action(menu_stack,"fight","Enter",func():session.start_match(false),true)

func _help_page() -> void:
    _plain_action("FIRST MINUTE / C - START LESSONS","first_minute",session.start_first_minute)
    _plain_action("SURGE LAB / B - COMPARE DECISION WINDOW","surge_lab",session.start_surge_lab)
    for line in ["ZIP: evade a nearby strike for ROUTE. Spend it on E dash. L confirms a second kick.","RIVET: hold L to PRELOAD I / II, then release. Slow windup, strong guard pressure.","HUSH: frontal perfect guard stores SAMPLE. Cross / K / L / W+L spends it.","LOOP: L places a node (20). Move+L places farther. S+L pulses nodes (10). W+L: ENCORE.","FIGHTERS > STREET RUN: win stops for XP and skill points. Equip 2 in SKILLS. Standard FIGHT uses fixed stats."]:
        menu_stack.add_child(_label(line,28,Tokens.TEAL))
    for key in ["move_help","combo_help","air_help","defense_help","throw_help","wall_help","special_help","pressure_help","clash_help","air_lab_help"]:
        var label:=_label(tr_text(key),17,PAPER)
        menu_stack.add_child(label)
        var spacer:=Control.new()
        spacer.custom_minimum_size.y=8
        menu_stack.add_child(spacer)
    _action(menu_stack,"drill","F8",func():
        session.start_match(true)
        session.prime_pressure_drill())

func _process(delta: float) -> void:
    title_motion.update_stage(session.screen=="title" and menu_page=="main",delta,session.reduced_effects)
    art.advance(delta,session.reduced_effects)
    copy.language="en"
    pause_button.visible=session.screen=="play"
    coach_continue.visible=session.screen=="play" and session.coach!=null and session.coach.status in ["ready","passed","complete"]
    if coach_continue.visible:
        coach_continue.text="ENTER / "+{"ready":"BEGIN","passed":"NEXT LESSON","complete":"MAIN MENU"}[session.coach.status]
    audio_restore.visible=session.screen=="title" and menu_page=="main" and session.audio.silent_settings()
    roster_preview.update_preview(session.screen=="title" and menu_page=="roster",session.character_choices[art.roster_side],delta,session.reduced_effects)
    if session.screen not in ["pause","help"]:notice_time=maxf(0,notice_time-delta)
    if session.screen=="play":skill_time=maxf(0,skill_time-delta)
    for i in 2:
        var hp: float=session.sim.fighters[i].health
        if hp<last_health[i]:health_delay[i]=.18
        if hp>last_health[i]:health_lag[i]=hp
        last_health[i]=hp
        health_delay[i]=maxf(0,health_delay[i]-delta)
        if health_delay[i]<=0:health_lag[i]=move_toward(health_lag[i],hp,delta*65)
    _sync_choices()
    _sync_air_controls()
    queue_redraw()

func _sync_choices() -> void:
    if not is_instance_valid(drill_start):return
    var exchange=session.sim.exchange
    var active: bool=exchange.active() and session.screen=="play" and session.demo==null
    var drill: bool=session.sim.pressure_drill and session.screen=="play"
    drill_start.visible=drill
    drill_start.text=tr_text("begin_drill")
    var keys := ["J","Shift","E"]
    for i in 3:
        var button:=choice_buttons[i]
        button.visible=active or drill
        button.text=keys[i]+"  "+tr_text(exchange.CHOICES[i])
        var selected: bool=active and exchange.clash.choices[0]==exchange.CHOICES[i]
        var locked: bool=active and exchange.clash.choices[0]!=""
        button.disabled=not active or locked
        button.mouse_default_cursor_shape=Control.CURSOR_ARROW if button.disabled else Control.CURSOR_POINTING_HAND
        var skin:=1 if selected else (2 if button.disabled else 0)
        if choice_skin[i]==skin:continue
        choice_skin[i]=skin
        if selected:
            button.add_theme_stylebox_override("disabled",Tokens.plate(Tokens.TEAL,Tokens.TEAL,1))
            button.add_theme_color_override("font_disabled_color",INK)
        else:
            button.remove_theme_stylebox_override("disabled")
            button.remove_theme_color_override("font_disabled_color")

func _text(at: Vector2, value: String, point_size: int, color := PAPER, display := false) -> void:
    draw_string(bold if display else font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(Tokens.CAPTION_SIZE,point_size),color)

func _center(at: Vector2, value: String, point_size: int, color := PAPER, display := false) -> void:
    var face: Font=bold if display else font
    _text(at-Vector2(face.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(Tokens.CAPTION_SIZE,point_size)).x*.5,0),value,point_size,color,display)

func _plate(at: Vector2, extent: Vector2, color: Color) -> void:
    draw_colored_polygon(PackedVector2Array([at,at+Vector2(extent.x,0),at+extent,at+Vector2(0,extent.y)]),color)

func _cut_bar(at: Vector2, extent: Vector2, color: Color, reverse := false) -> void:
    if extent.x<=0:return
    var cut:=minf(10,extent.x*.2)
    var points:=PackedVector2Array([Vector2.ZERO,Vector2(extent.x-cut,0),extent,Vector2(0,extent.y)])
    for i in points.size():
        if reverse:points[i].x=extent.x-points[i].x
        points[i]+=at
    draw_colored_polygon(points,color)

func _draw() -> void:
    if not is_instance_valid(session):return
    draw_set_transform(Vector2.ZERO,0,size/Vector2(1280,720))
    if session.screen=="title":
        if menu_page=="main":art.title(self)
        elif menu_page=="roster":art.roster(self,session)
        else:art.secondary(self,"LOADOUT" if menu_page=="skills" else ("SETTINGS" if menu_page=="settings" else "HOW TO PLAY"))
        return
    if session.round_theatre.intro and session.screen=="play":
        session.round_theatre.draw(self)
        return
    if session.city_breaker.active() and session.screen=="result":
        session.city_breaker.draw(self)
        return
    if session.neon_enabled:
        session.neon.draw(self,session)
    else:
        session.theatre.draw(self,session)
        session.rhythm.draw(self,session)
        if not (session.theatre.active() and session.theatre.mode in ["ko","skill","overdrive"] and not session.reduced_effects):session.spectacle.draw(self,session)
    for effect in session.effects:
        if effect.age>=0:vfx_renderer.draw_effect(self,session,effect)
    if not session.neon_enabled and session.theatre.active() and session.theatre.mode=="ko" and not session.reduced_effects:return
    art.hud(self,session,health_lag)
    service_art.draw(self,session)
    if session.sim.arcade_enabled:_surge_hud()
    if session.sim.exchange.decision_active():_surge_decision_hud()
    if session.neon_enabled:draw_string(font,Vector2(16,160),"NEON FACETS LAB",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("bdff00"))
    if skill_time>0 and skill_key!="" and session.screen=="play":
        _plate(Vector2(460,154),Vector2(360,34),INK)
        _center(Vector2(640,179),tr_text(skill_key),21,Tokens.LIME)
    if session.sim.phase=="ready" and session.screen=="play":
        _center(Vector2(640,280),tr_text("round")+" %d"%session.sim.round_number,40)
        _center(Vector2(640,316),"準備" if session.language=="zh" else "GET READY",22,Tokens.GOLD)
    if notice_time>0 and session.demo==null and not session.sim.exchange.decision_active() and not session.sim.exchange.active() and not session.sim.pressure_drill and not session.sim.rally.active():
        var notice_y:float=596 if notice.begins_with("RICOCHET") else 196
        _plate(Vector2(426,notice_y),Vector2(428,40),INK)
        _center(Vector2(640,notice_y+29),copy.notice(notice),19,Tokens.GOLD)
    var player: Dictionary=session.sim.fighters[0]
    if session.demo==null and player.wall_tech_window>0 and player.state=="stun" and player.meter>=20:
        var at: Vector2=session.project(Vector2(player.x,player.y+2.3))
        at.x=clampf(at.x,120,1160)
        _plate(at+Vector2(-100,-26),Vector2(200,32),INK)
        _center(at+Vector2(0,-3),"E "+tr_text("recover"),13,Tokens.TEAL)
    if session.demo==null and player.counter_window>0 and session.screen=="play":
        var cue: Vector2=session.project(Vector2(player.x,player.y+2.7))
        cue.x=clampf(cue.x,145,1135);cue.y=clampf(cue.y,180,480)
        _plate(cue+Vector2(-140,-28),Vector2(280,34),INK)
        _center(cue+Vector2(0,-5),tr_text("counter_ready"),16,Tokens.TEAL)
    if session.demo!=null:_demo_hud()
    elif session.sim.arcade_enabled:_arcade_hud()
    elif session.sim.is_aerial():_air_hud()
    elif session.sim.rally_enabled:_rally_hud()
    else:_pressure_hud()
    if session.coach!=null:_coach_hud()
    if session.practice and session.demo==null:_practice_hud()
    if session.demo==null and not session.sim.arcade_enabled and not session.sim.exchange.active() and not session.sim.pressure_drill and not session.sim.rally.active():
        _text(Vector2(34,690),"J "+tr_text("light")+"   K "+tr_text("heavy")+"   G "+tr_text("throw")+"   Shift "+tr_text("guard")+"   E "+tr_text("dodge"),13,PAPER)

    if session.hitboxes_visible:_draw_hitboxes()
    if session.screen!="play" and not (session.demo!=null and session.screen=="result") and not session.result_presentation_active():
        art.secondary(self,"SETTINGS" if menu_page=="settings" else ("HOW TO PLAY" if menu_page=="help" else ("PAUSED" if session.screen in ["pause","help"] else "RESULT")))

func _health(x: float, fighter: Dictionary, tint: Color, reverse: bool, index: int) -> void:
    var fighter_tag: String=("AI 1" if index==0 else "AI 2") if session.demo!=null else tr_text("you" if index==0 else ("practice" if session.practice else "rival"))
    _text(Vector2(x+8,28),fighter_tag+" / "+tr_text(session.FighterVisual.Roster.entry(session.character_choices[index]).label),13,PAPER)
    draw_rect(Rect2(x-5,27,480,42),PAPER,false,2)
    _cut_bar(Vector2(x+6,36),Vector2(458,24),INK,reverse)
    var hp: float=458*clampf(fighter.health/100.0,0,1)
    var lag: float=458*clampf(health_lag[index]/100.0,0,1)
    _cut_bar(Vector2(x+6+458-lag if reverse else x+6,40),Vector2(lag,16),PAPER,reverse)
    _cut_bar(Vector2(x+6+458-hp if reverse else x+6,40),Vector2(hp,16),tint,reverse)
    # Generated empty frame is a decoration; live bars and values remain native.
    _text(Vector2(x+14,55),str(fighter.health),14,INK,true)
    _plate(Vector2(x+6,72),Vector2(458,6),INK)
    _plate(Vector2(x+6,72),Vector2(458*clampf(fighter.meter/100.0,0,1),6),Tokens.LIME)
    for threshold in [50,75]:
        var tx: float=x+6+458*threshold/100.0
        draw_line(Vector2(tx,69),Vector2(tx,81),PAPER,2)
    _text(Vector2(x+6,96),"L 50 / W+L 75   ·   %d"%fighter.meter,11,Tokens.LIME)
    _text(Vector2(x+345,96),tr_text("guard")+" %d"%fighter.guard,11,PAPER)

func _pressure_hud() -> void:
    var exchange=session.sim.exchange
    var active: bool=exchange.active()
    var drill: bool=session.sim.pressure_drill
    var tint: Color=[Tokens.TEAL,Tokens.GOLD,Tokens.CORAL][exchange.tier()-1]
    if not active and not drill:
        _plate(Vector2(520,614),Vector2(240,36),Color(INK,.93))
        _center(Vector2(640,609),tr_text("pressure")+"  "+str(exchange.tier())+" / 3",12,tint)
        for i in 3:
            _cut_bar(Vector2(535+i*72,627),Vector2(66,8),Tokens.EDGE)
            var amount: float=clampf((exchange.pressure-i*30)/30.0,0,1)
            _cut_bar(Vector2(535+i*72,627),Vector2(66*amount,8),tint)
        if exchange.pressure>=60 and exchange.cooldown==0:_center(Vector2(640,669),"K  "+tr_text("ready"),12,Tokens.GOLD)
        return
    _plate(Vector2(330,530),Vector2(620,128),INK)
    _text(Vector2(346,556),tr_text("clash") if active else tr_text("drill"),20,Tokens.GOLD)
    if active:
        _text(Vector2(600,555),tr_text("cue_"+exchange.clash.cue),14,PAPER)
        _plate(Vector2(346,565),Vector2(588,3),Tokens.EDGE)
        _plate(Vector2(346,565),Vector2(588*float(exchange.clash.remaining)/exchange.WINDOW,3),Tokens.GOLD)
    else:_text(Vector2(548,556),tr_text("read_first"),13,Tokens.MUTED)
    for i in 3:_center(Vector2(441+i*198,642),tr_text(exchange.CHOICES[i]+"_rule"),13,Tokens.MUTED)
    if active and not session.practice and session.sim.difficulty>0:
        _text(Vector2(34,690),tr_text("feint_warning"),12,Tokens.MUTED)
    if active and exchange.clash.choices[0]!="":_center(Vector2(640,682),tr_text("locked")+" · "+tr_text(exchange.clash.choices[0]),14,Tokens.TEAL)
    elif drill:_text(Vector2(34,690),tr_text("drill_exit"),12,Tokens.MUTED)

func _demo_hud() -> void:
    _plate(Vector2(28,78),Vector2(270,38),INK)
    _text(Vector2(37,105),"AI DEMO / ROUND %02d"%session.presentation_round(),14,PAPER)

func _surge_hud() -> void:
    var exchange=session.sim.exchange
    var tier:int=exchange.tier()
    var tint:Color=[Tokens.TEAL,Tokens.LIME,Tokens.MAGENTA][tier-1]
    var jump:float=0.0 if session.reduced_effects else sin(session.surge_pulse/.45*PI)*4.0
    _plate(Vector2(548,86-jump),Vector2(184,64),INK)
    _center(Vector2(640,110-jump),"SURGE %02d"%roundi(exchange.pressure),24,tint)
    _center(Vector2(640,137-jump),["FLOW","HEAT","SURGE"][tier-1],24,tint)
    for i in 3:
        draw_rect(Rect2(556+i*56,143-jump,52,4),Color(tint,.2))
        draw_rect(Rect2(556+i*56,143-jump,52*clampf((exchange.pressure-i*30)/30.0,0,1),4),tint)
    for side in 2:
        var slot:Dictionary=session.sim.continuation.slots[side]
        if not slot.is_empty() and slot.choice!="" and not slot.spent:
            var label:String={"light":"J","heavy":"K","dash":"E"}[slot.choice]
            _plate(Vector2(330 if side==0 else 755,119),Vector2(210,30),INK)
            _text(Vector2(334 if side==0 else 759,143),"P%d %s LOCK"%[side+1,label],24,session.COLORS[side])

func _coach_hud() -> void:
    var c:RefCounted=session.coach
    var tint:Color=Tokens.LIME if c.status in ["passed","complete"] else Tokens.TEAL
    _plate(Vector2(200,494),Vector2(880,144),INK)
    _center(Vector2(640,521),"P1 GOAL %d/4 / "%int(c.index+1)+c.TITLES[c.index],28,tint)
    _center(Vector2(640,552),c.KEYS[c.index],28,PAPER)
    if c.status=="running":
        _center(Vector2(640,582),c.cue(session.sim),24,Tokens.LIME if c.cue(session.sim).contains("SHIFT NOW") else PAPER)
        var detail:String="REAL COMBO %d / 2"%c.combo_max if c.index==0 else ("PARRY / "+("YES" if c.parried else "--") if c.index==1 else ("LAUNCH %s / CHASE %s"%["YES" if c.launched else "--","YES" if c.chased else "--"] if c.index==2 else "PAID START / "+("YES" if c.paid else "--")))
        _center(Vector2(640,614),detail+" / F5 RETRY",24,Tokens.MUTED)
    else:
        _center(Vector2(640,580),"4/4 COMPLETE / %ds / NO TIME LIMIT"%ceili(c.elapsed) if c.status=="complete" else ("REAL CONTACT CONFIRMED" if c.status=="passed" else c.HINTS[c.index]),24,tint)

func _surge_decision_hud() -> void:
    var d:Dictionary=session.sim.exchange.decision
    _plate(Vector2(256,498),Vector2(768,134),INK)
    _center(Vector2(640,526),"SURGE LAB / CHOOSE / %02d"%d.remaining,28,Tokens.LIME)
    _center(Vector2(640,560),"J STRIKE   SHIFT GUARD   E BACKSTEP",28,PAPER)
    var own:String=d.choices[0]
    if session.pending.has("surge_choice"):own=session.pending.surge_choice
    _center(Vector2(640,591),"P1 "+("READY" if own=="" else own.to_upper()+" LOCK")+" / P2 "+("READY" if d.choices[1]=="" else "LOCKED"),24,Tokens.TEAL)
    draw_rect(Rect2(280,614,720*float(d.remaining)/session.sim.exchange.DECISION_TICKS,6),Tokens.MAGENTA)

func _arcade_hud() -> void:
    if session.sim.air_counter.active():
        _air_hud()
        return
    # Shared HUD draws the larger native English shortcut row.

func _air_hud() -> void:
    if session.sim.air_counter.active():
        var counter=session.sim.air_counter
        var tint: Color=session.COLORS[counter.owner]
        _plate(Vector2(330,548),Vector2(620,108),Color(INK,.96))
        _text(Vector2(348,575),tr_text("air_reversal"),18,tint)
        _text(Vector2(765,575),tr_text("you" if counter.owner==0 else "rival"),14,tint)
        if counter.phase=="hold":
            var caption: String=tr_text("air_choose" if counter.owner==0 else "air_rival_holds")
            if counter.owner==0 and counter.choice!="":caption=tr_text("air_locked")+" · "+tr_text("air_choice_"+counter.choice)
            _center(Vector2(640,600),caption,14,PAPER)
            _plate(Vector2(348,580),Vector2(584,3),Tokens.EDGE)
            _plate(Vector2(348,580),Vector2(584*(1.0-float(counter.age)/counter.HOLD),3),tint)
        else:_center(Vector2(640,620),tr_text("air_counter_release_hint"),16,PAPER)
        return
    if session.sim.is_air_lesson():
        _plate(Vector2(330,548),Vector2(620,108),Color(INK,.96))
        _text(Vector2(348,575),tr_text("air_defense_title"),18,Tokens.TEAL)
        var phase: String=session.sim.air_lesson_stage
        var caption: String=tr_text("air_defense_"+phase)
        if phase=="attack":
            var a: Dictionary=session.sim.fighters[1]
            var parry_ready: bool=a.state=="attack" and a.frame>=session.Simulation.MOVES.air_finisher.startup-session.sim.air_counter.PARRY_WINDOW and a.frame<session.Simulation.MOVES.air_finisher.startup
            caption=tr_text("air_parry_now" if parry_ready else "air_wait_windup")
        _center(Vector2(640,600),caption,14,PAPER)
        return
    var f: Dictionary=session.sim.fighters[0]
    _plate(Vector2(330,548),Vector2(620,108),Color(INK,.96))
    _text(Vector2(348,575),tr_text("air_lab"),18,Tokens.TEAL)
    _text(Vector2(744,575),tr_text("air_phase_"+f.air.phase),14,Tokens.GOLD)
    _center(Vector2(640,600),tr_text("air_jump_help"),14,PAPER)
    _center(Vector2(640,623),tr_text("air_combo_help"),14,PAPER)
    if session.sim.can_air_parry(0) and session.sim.fighters[1].frame>=session.Simulation.MOVES[session.sim.fighters[1].move].startup-session.sim.air_counter.PARRY_WINDOW:
        _center(Vector2(640,646),tr_text("air_parry_now"),13,Tokens.GOLD)
    elif f.air.chase_window>0 and not f.air.chase_used:
        _center(Vector2(640,646),tr_text("air_chase_ready"),13,Tokens.GOLD)
    else:_center(Vector2(640,646),tr_text("air_stall")+" %d / 12"%f.air.stall_left,12,Tokens.MUTED)

func _sync_air_controls() -> void:
    if not is_instance_valid(air_lesson):return
    for i in demo_buttons.size():
        demo_buttons[i].visible=false
        demo_buttons[i].text=tr_text(["demo_restart","demo_exit"][i])
    var active: bool=session.screen=="play" and session.sim.is_aerial() and session.demo==null
    var lesson: bool=session.sim.is_air_lesson()
    var counter=session.sim.air_counter
    air_lesson.visible=active and session.practice and not session.sim.arcade_enabled
    air_lesson.text=tr_text("air_to_free" if lesson else "air_to_defense")
    air_begin.visible=active and lesson and not counter.active() and session.sim.air_lesson_stage in ["read","review"]
    air_begin.text=tr_text("air_begin" if session.sim.air_lesson_stage=="read" else "air_retry")
    air_parry.visible=active and lesson and not counter.active() and session.sim.air_lesson_stage=="attack"
    air_parry.text=tr_text("air_parry_button")
    air_parry.disabled=not session.sim.can_air_parry(0) or session.sim.fighters[0].meter<25
    for i in 2:
        var button:=air_choices[i]
        button.visible=active and counter.phase=="hold" and counter.owner==0
        button.text=tr_text("air_choice_"+["kick","escape"][i])
        button.disabled=counter.choice!=""
        var skin:=1 if counter.choice==["kick","escape"][i] else 0
        if air_choice_skin[i]!=skin:
            air_choice_skin[i]=skin
            if skin==1:
                button.add_theme_stylebox_override("disabled",Tokens.plate(Tokens.TEAL,Tokens.TEAL,1))
                button.add_theme_color_override("font_disabled_color",INK)
            else:
                button.remove_theme_stylebox_override("disabled")
                button.remove_theme_color_override("font_disabled_color")

func _rally_hud() -> void:
    var rally=session.sim.rally
    var tint: Color=session.COLORS[rally.owner] if rally.active() else Tokens.GOLD
    _plate(Vector2(340,546),Vector2(600,111),Color(INK,.96))
    _text(Vector2(358,573),tr_text("rally_lab"),18,tint)
    if not rally.active():
        _center(Vector2(640,603),tr_text("rally_wait"),16,PAPER)
        _center(Vector2(640,639),tr_text("rally_exit"),12,Tokens.MUTED)
        return
    var status: String=tr_text("you" if rally.owner==0 else "rival")+"  /  "+str(rally.tier)+" / 4"
    _text(Vector2(730,573),status,16,tint)
    var caption: String=tr_text("rally_commit" if rally.owner==0 else "rally_defend")
    if rally.phase=="compress" and rally.owner==0 and rally.chosen:caption=tr_text("rally_locked")
    _center(Vector2(640,606),caption,18,PAPER)
    var ratio: float=1.0-float(rally.age)/rally.HOLDS[rally.tier-1] if rally.phase=="compress" else float(rally.age)/rally.WINDUP
    _plate(Vector2(358,619),Vector2(564,5),Tokens.EDGE)
    _plate(Vector2(358,619),Vector2(564*clampf(ratio,0,1),5),tint)
    _center(Vector2(640,645),tr_text("rally_hold" if rally.phase=="compress" else "rally_live"),12,Tokens.MUTED)

func _practice_hud() -> void:
    if session.coach!=null:
        _plate(Vector2(28,95),Vector2(282,82),INK)
        _text(Vector2(40,122),"FIRST MINUTE / %d OF 4"%(session.coach.index+1),24,Tokens.LIME)
        _text(Vector2(40,148),"FIXTURE / 100 ENERGY",24,PAPER)
        _text(Vector2(40,172),"F5 RETRY / NO XP",24,Tokens.MUTED)
        return
    if session.sim.arcade_enabled and session.sim.surge_lab_fixture:
        _plate(Vector2(28,95),Vector2(282,82),INK)
        _text(Vector2(40,122),"SURGE LAB / "+("WINDOW" if session.sim.surge_lab_enabled else "BASELINE"),24,Tokens.LIME)
        _text(Vector2(40,148),"FIXTURE / B COMPARE",24,PAPER)
        _text(Vector2(40,172),"F5 RETRY / K TO START",24,Tokens.MUTED)
        return
    if session.sim.arcade_enabled:
        _plate(Vector2(28,95),Vector2(244,38),INK)
        _text(Vector2(40,122),tr_text("training_title"),13,Tokens.TEAL)
        return
    if session.sim.is_aerial():
        _text(Vector2(40,122),tr_text("air_lab"),12,Tokens.TEAL)
        _text(Vector2(40,143),tr_text("air_exit"),11,Tokens.MUTED)
        return
    var lab: bool=session.sim.rally_enabled
    _text(Vector2(40,122),tr_text("rally_lab") if lab else tr_text("training_title")+" · "+tr_text(["standing","guarding","sparring"][session.sim.partner_mode]),12,Tokens.MUTED)
    _text(Vector2(40,143),tr_text("rally_exit") if lab else "F5 "+tr_text("reset_training")+"   F8 "+tr_text("drill")+"   F9 "+tr_text("training_details"),11,Tokens.MUTED)
    if not session.training_details:return
    _plate(Vector2(30,488),Vector2(240,152),Color(INK,.94))
    _text(Vector2(44,511),tr_text("last_combo"),14,Tokens.GOLD)
    _text(Vector2(44,550),str(session.sim.last_combo_hits),32,PAPER,true)
    _text(Vector2(90,548),tr_text("hits"),15,Tokens.MUTED)
    _text(Vector2(44,580),"%d "%session.sim.last_combo_damage+tr_text("damage"),17,PAPER)
    _plate(Vector2(1010,488),Vector2(240,152),Color(INK,.94))
    _text(Vector2(1024,511),tr_text("inputs"),14,Tokens.GOLD)
    if session.input_history.is_empty():_text(Vector2(1024,542),tr_text("none"),13,Tokens.MUTED)
    for i in session.input_history.size():_text(Vector2(1024,534+i*16),session.input_history[i],11,PAPER)

func _draw_hitboxes() -> void:
    for i in 2:
        var f: Dictionary=session.sim.fighters[i]
        var foot: Vector2=session.project(Vector2(f.x,f.y))
        var top: Vector2=session.project(Vector2(f.x-.35,f.y+2))
        draw_rect(Rect2(top,Vector2((foot.x-top.x)*2,foot.y-top.y)),Color(0,1,0,.8),false,2)
        if f.state=="attack":
            var move: Dictionary=session.sim.move_for(f,f.move)
            if f.frame>=move.startup and f.frame<move.startup+move.active:
                draw_line(session.project(Vector2(f.x,f.y+1.2)),session.project(Vector2(f.x+f.face*move.reach,f.y+1.2)),Color.RED,5)

func _art_button(key:String,label:String,rect:Rect2,callback:Callable) -> Button:
    var button:=Button.new()
    button.name="Art_"+key
    button.text=label
    button.tooltip_text=label
    button.set_meta("ui_key",key)
    button.position=rect.position;button.size=rect.size
    for state in ["normal","hover","pressed","focus","disabled"]:button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
    for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color","font_outline_color"]:button.add_theme_color_override(state,Color.TRANSPARENT)
    button.add_theme_constant_override("outline_size",0)
    button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    button.focus_entered.connect(func():art.focused_key=key;queue_redraw())
    button.mouse_entered.connect(func():art.focused_key=key;queue_redraw())
    button.pressed.connect(func():
        get_viewport().set_input_as_handled()
        callback.call())
    art_controls.add_child(button);art_buttons[key]=button
    return button

func _build_art_controls() -> void:
    for child in art_controls.get_children():art_controls.remove_child(child);child.queue_free()
    art_buttons.clear();art_controls.visible=true
    if menu_page=="main":
        var keys:Array=["fight","roster","training","settings","demo"]
        var labels:Array=["FIGHT","FIGHTERS","TRAINING","SETTINGS","AI DEMO"]
        var calls:Array=[func():session.start_match(false),func():open_page("roster"),func():session.start_match(true),func():open_page("settings"),func():session.start_demo()]
        for i in 5:_art_button(keys[i],labels[i],art.MAIN_RECTS[i],calls[i])
        for i in 5:
            art_buttons[keys[i]].focus_neighbor_top=art_buttons[keys[(i+4)%5]].get_path()
            art_buttons[keys[i]].focus_neighbor_bottom=art_buttons[keys[(i+1)%5]].get_path()
    else:
        for i in 4:
            var index:int=i
            _art_button("card_"+str(i),["ZIP","RIVET","HUSH","LOOP"][i],art.fit(art.CARD_RECTS[i]),func():
                focus_key="card_"+str(index)
                session.set_character(art.roster_side,index)
                _build_art_controls();call_deferred("_restore_focus");queue_redraw())
        for side in 2:
            var selected_side:int=side
            _art_button("side_"+str(side),"SELECT P%d"%(side+1),art.fit(Rect2(18,241+side*100,160,84)),func():art.roster_side=selected_side;queue_redraw())
        _art_button("skills","SKILLS",Rect2(1094,300,140,60),func():open_page("skills"))
        _art_button("street_run","STREET RUN",Rect2(1094,380,140,86),session.start_run)
        _art_button("roster_fight","FIGHT",art.fit(Rect2(849,773,550,100)),func():session.start_match(false))
        _art_button("back","BACK",art.fit(Rect2(1507,875,145,50)),close_page)
        for i in 4:
            var button:Button=art_buttons["card_"+str(i)]
            button.focus_neighbor_left=art_buttons["card_"+str(i^1)].get_path()
            button.focus_neighbor_right=art_buttons["card_"+str(i^1)].get_path()
            button.focus_neighbor_top=art_buttons["card_"+str((i+2)%4)].get_path()
            button.focus_neighbor_bottom=art_buttons["card_"+str(i+2)].get_path() if i<2 else art_buttons.roster_fight.get_path()

func _restore_sound() -> void:
    session.audio.restore_output()
    session.save_options()
    if menu_page=="settings":rebuild_menu()

func _plain_action(label:String,key:String,callback:Callable) -> Button:
    var button:Button=_action(menu_stack,key,"",callback)
    button.text=label
    return button

func _skills_page() -> void:
    var character:int=session.character_choices[0]
    var growth:RefCounted=session.growth
    var record:Dictionary=growth.records[growth.Profiles.IDS[character]]
    menu_stack.add_child(_label("%s / LV %d / XP %d / POINTS %d"%[growth.Profiles.NAMES[character],growth.level(character),record.xp,growth.points(character)],32,PAPER,true))
    menu_stack.add_child(_label("Equip 2. Skills apply to STREET RUN only. Standard FIGHT keeps fixed stats. Changes apply at the next stop.",28,Tokens.MUTED))
    for i in 3:
        var index:int=i;var node:Dictionary=growth.SKILLS[character][i]
        var unlocked:bool=node.id in record.unlocked;var equipped:bool=node.id in record.equipped
        var status:String="EQUIPPED" if equipped else ("EQUIP" if unlocked else "UNLOCK / 1 POINT / LV %d"%(i+1))
        var button:Button=_plain_action(node.name+" / "+status,"skill_"+node.id,func():
            if node.id in growth.records[growth.Profiles.IDS[character]].unlocked:growth.toggle(character,index)
            else:growth.unlock(character,index)
            rebuild_menu("skill_"+node.id))
        button.disabled=not unlocked and (growth.points(character)<=0 or growth.level(character)<i+1)
        menu_stack.add_child(_label(node.desc,28,Tokens.MUTED))
    _plain_action("FREE RESPEC","respec",func():growth.respec(character);rebuild_menu("respec"))
    var palette:Button=_plain_action("PALE FX / "+("ON" if record.palette else "OFF")+" / UNLOCK AT 120 XP","palette",func():growth.toggle_palette(character);rebuild_menu("palette"))
    palette.disabled=record.xp<120
    if growth.last_error!=OK:menu_stack.add_child(_label("SAVE FAILED / PROGRESS IS IN MEMORY",28,Tokens.MAGENTA))
    if session.screen=="title":_plain_action("START 3-STOP STREET RUN","start_run",session.start_run)
