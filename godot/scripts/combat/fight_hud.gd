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
var menu_page := "main"
var previous_screen := ""
var built_page := ""
var focus_key := ""
var page_return_focus := ""
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
    air_lesson.pressed.connect(func():session.prime_air_drill() if session.sim.is_air_lesson() else session.prime_air_defense())
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
    menu.add_theme_stylebox_override("panel",Tokens.plate(Color(INK,.97),Tokens.EDGE,1))
    layout_root.add_child(menu)
    menu_scroll=ScrollContainer.new()
    menu_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    menu_scroll.follow_focus=true
    menu.add_child(menu_scroll)
    menu_stack=VBoxContainer.new()
    menu_stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    menu_stack.add_theme_constant_override("separation",9)
    menu_scroll.add_child(menu_stack)
    back_button=Button.new()
    back_button.position=Vector2(360,28)
    back_button.size=Vector2(156,34)
    back_button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    back_button.pressed.connect(close_page)
    layout_root.add_child(back_button)
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
    menu.visible=session.screen!="play" and not (session.screen=="result" and session.result_clock<.82 and not session.reduced_effects)
    back_button.visible=menu.visible and menu_page!="main"
    back_button.text="← "+tr_text("back")+"  Esc"
    if not menu.visible:
        _sync_choices()
        _sync_air_controls()
        return
    if menu_page!="main":
        menu.position=Vector2(360,74)
        menu.size=Vector2(560,572)
    elif session.screen=="title":
        menu.position=Vector2(52,230)
        menu.size=Vector2(450,434)
    else:
        menu.position=Vector2(420,126)
        menu.size=Vector2(440,480 if session.screen in ["pause","help"] else 398)
    if menu_page=="settings":_settings_page()
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
    if not menu.visible:return
    if focus_key=="back" and back_button.visible:
        back_button.grab_focus()
        return
    var first: Control
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
    label.add_theme_font_size_override("font_size",point_size)
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
    button.custom_minimum_size=Vector2(0,48)
    button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
    button.add_theme_font_size_override("font_size",20)
    button.set_meta("ui_key",key)
    if primary:
        button.add_theme_stylebox_override("normal",Tokens.plate(PAPER,PAPER,1))
        button.add_theme_color_override("font_color",INK)
        button.add_theme_color_override("font_focus_color",INK)
    if shortcut!="":
        var badge:=Label.new()
        badge.text=shortcut
        badge.add_theme_font_size_override("font_size",12)
        badge.add_theme_color_override("font_color",INK if primary else Tokens.MUTED)
        badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
        badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        badge.offset_right=-16
        badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
        badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
        button.add_child(badge)
        var highlight:=func():badge.add_theme_color_override("font_color",INK)
        var restore:=func():badge.add_theme_color_override("font_color",INK if primary or button.is_hovered() else Tokens.MUTED)
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
    for key in ["controls","settings"]:
        var page: String="help" if key=="controls" else "settings"
        var button:=_action(row,key,"H" if key=="controls" else "F1",func():open_page(page))
        button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size",15)
        button.custom_minimum_size.y=38
    var explore:=_action(menu_stack,"explore","F6",func():session.return_to_street())
    explore.add_theme_font_size_override("font_size",15)
    explore.custom_minimum_size.y=36

func _pause_page() -> void:
    _heading("paused")
    _action(menu_stack,"resume","Esc",func():session.resume_game(),true)
    _action(menu_stack,"reset_training" if session.practice else "restart","F5" if session.practice else "R",func():session.reset_training() if session.practice else session.start_match(false))
    if session.practice:_action(menu_stack,"drill","F8",func():session.prime_pressure_drill())
    _action(menu_stack,"settings","F1",func():open_page("settings"))
    _action(menu_stack,"controls","H",func():open_page("help"))
    _action(menu_stack,"main_menu","",func():session.return_to_title())

func _result_page() -> void:
    _heading("draw" if session.sim.winner<0 else ("win" if session.sim.winner==0 else "lose"))
    if session.sim.winner==1:_caption("runback")
    menu_stack.add_child(_label("%d  —  %d"%[session.sim.wins[0],session.sim.wins[1]],48,Tokens.GOLD,true))
    _caption("wins")
    var complete: bool=session.sim.phase=="match_over"
    _action(menu_stack,"rematch" if complete else "next_round","Enter",func():session.start_match(session.practice) if complete else session.advance_round(),true)
    _action(menu_stack,"main_menu","",func():session.return_to_title())

func open_page(page: String) -> void:
    if session.screen=="play":session.pause_game()
    page_return_focus="controls" if page=="help" else "settings"
    menu_page=page
    focus_key="back"
    rebuild_menu("back")

func close_page() -> void:
    menu_page="main"
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
    control.custom_minimum_size.y=42
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
    button.custom_minimum_size.y=40
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
    slider.custom_minimum_size.y=32
    slider.set_meta("ui_key",key+"_volume")
    slider.value_changed.connect(func(level:float):
        label.text=tr_text(key)+"  %d%%"%roundi(level*100)
        session.set_volume(key,level))
    menu_stack.add_child(slider)

func _settings_page() -> void:
    _heading("settings")
    _choice("language",["zh","en"],0 if session.language=="zh" else 1,func(index:int):session.set_language("zh" if index==0 else "en"))
    _choice("difficulty",["relaxed","standard","challenging"],session.sim.difficulty,session.set_difficulty)
    _caption("difficulty_hint")
    if session.sim.is_air_lesson():_caption("air_fixed_partner")
    elif session.practice or session.screen=="title":_choice("partner",["standing","guarding","sparring"],session.sim.partner_mode,session.set_partner_mode)
    _toggle("muted",session.audio.muted,func(value:bool):
        session.audio.muted=value
        session.audio.stop_all()
        session.save_options())
    _toggle("music_enable",not session.audio.music_muted,func(value:bool):
        session.audio.music_muted=not value
        session.save_options())
    _volume("music",session.audio.music_level)
    _volume("sound",session.audio.effects_level)
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

func _help_page() -> void:
    _heading("controls")
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
    copy.language=session.language
    if session.screen not in ["pause","help"]:notice_time=maxf(0,notice_time-delta)
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
    var active: bool=exchange.active() and session.screen=="play"
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
    draw_string(bold if display else font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size,color)

func _center(at: Vector2, value: String, point_size: int, color := PAPER, display := false) -> void:
    var face: Font=bold if display else font
    _text(at-Vector2(face.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x*.5,0),value,point_size,color,display)

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
        if menu_page!="main":
            _plate(Vector2.ZERO,Vector2(1280,720),Color(Tokens.NIGHT,.62))
            return
        draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(540,0),Vector2(592,720),Vector2(0,720)]),Color(Tokens.NIGHT,.94))
        _text(Vector2(66,100),"AFTERHOURS",57,Tokens.TEAL,true)
        _text(Vector2(66,145),tr_text("subtitle"),29)
        _text(Vector2(66,188),tr_text("intro"),15,Tokens.MUTED)
        _text(Vector2(66,694),tr_text("local")+"  /  ↑↓  Enter",12,Tokens.MUTED)
        _text(Vector2(940,686),tr_text("stage"),18,PAPER)
        return
    session.spectacle.draw(self,session)
    for effect in session.effects:
        if effect.age>=0:vfx_renderer.draw_effect(self,session,effect)
    _health(34,session.sim.fighters[0],Tokens.TEAL,false,0)
    _health(772,session.sim.fighters[1],Tokens.CORAL,true,1)
    _plate(Vector2(604,16),Vector2(72,62),INK)
    _center(Vector2(640,61),tr_text("free") if session.practice else "%02d"%ceili(session.sim.remaining),23 if session.practice else 43,Tokens.GOLD,not session.practice)
    _center(Vector2(640,94),tr_text("round")+" %02d"%session.sim.round_number,11,Tokens.MUTED)
    for side in 2:
        for pip in 2:
            var at:=Vector2(548+pip*22 if side==0 else 710+pip*22,42)
            var color: Color=(Tokens.TEAL if side==0 else Tokens.CORAL) if session.sim.wins[side]>pip else Tokens.EDGE
            draw_colored_polygon(PackedVector2Array([at+Vector2(0,-6),at+Vector2(6,0),at+Vector2(0,6),at+Vector2(-6,0)]),color)
    if session.sim.combo_hits>=2 and session.sim.fighters[1-session.sim.combo_owner].state=="stun":
        var x:=40 if session.sim.combo_owner==0 else 1090
        var baseline:=210.0 if session.sim.is_aerial() else 171.0
        _text(Vector2(x,baseline),"%02d"%session.sim.combo_hits,42,Tokens.GOLD,true)
        _text(Vector2(x+61,baseline-2),tr_text("hits"),16,PAPER)
        _text(Vector2(x,baseline+23),"%d "%session.sim.combo_damage+tr_text("damage"),13,Tokens.MUTED)
    if session.sim.phase=="ready" and session.screen=="play":
        _center(Vector2(640,280),tr_text("round")+" %d"%session.sim.round_number,40)
        _center(Vector2(640,316),"準備" if session.language=="zh" else "GET READY",22,Tokens.GOLD)
    if notice_time>0 and not session.sim.exchange.active() and not session.sim.pressure_drill and not session.sim.rally.active():
        _plate(Vector2(426,110),Vector2(428,40),INK)
        _center(Vector2(640,139),copy.notice(notice),19,Tokens.GOLD)
    var player: Dictionary=session.sim.fighters[0]
    if player.wall_tech_window>0 and player.state=="stun" and player.meter>=20:
        var at: Vector2=session.project(Vector2(player.x,player.y+2.3))
        at.x=clampf(at.x,120,1160)
        _plate(at+Vector2(-100,-26),Vector2(200,32),INK)
        _center(at+Vector2(0,-3),"E "+tr_text("recover"),13,Tokens.TEAL)
    if session.sim.is_aerial():_air_hud()
    elif session.sim.rally_enabled:_rally_hud()
    else:_pressure_hud()
    if session.practice:_practice_hud()
    if not session.sim.exchange.active() and not session.sim.pressure_drill and not session.sim.rally.active():
        _text(Vector2(34,690),"J "+tr_text("light")+"   K "+tr_text("heavy")+"   G "+tr_text("throw")+"   Shift "+tr_text("guard")+"   E "+tr_text("dodge"),13,PAPER)
    _text(Vector2(1010,690),"H "+tr_text("help")+"   Esc "+tr_text("pause"),13,PAPER)
    if session.hitboxes_visible:_draw_hitboxes()
    if session.screen!="play" and not (session.screen=="result" and session.result_clock<.82 and not session.reduced_effects):_plate(Vector2.ZERO,Vector2(1280,720),Color(Tokens.NIGHT,.6))

func _health(x: float, fighter: Dictionary, tint: Color, reverse: bool, index: int) -> void:
    _cut_bar(Vector2(x-10,10),Vector2(494,90),Color(INK,.94),reverse)
    _text(Vector2(x+4,31),tr_text("you" if index==0 else ("practice" if session.practice else "rival")),14,tint)
    _cut_bar(Vector2(x,39),Vector2(470,23),Tokens.EDGE,reverse)
    var hp: float=470*fighter.health/100.0
    var lag: float=470*health_lag[index]/100.0
    _cut_bar(Vector2(x+470-lag if reverse else x,39),Vector2(lag,23),PAPER,reverse)
    _cut_bar(Vector2(x+470-hp if reverse else x,39),Vector2(hp,23),tint,reverse)
    _text(Vector2(x+10,57),str(fighter.health),16,INK,true)
    for part in 2:
        var amount: float=clampf((fighter.meter-part*50)/50.0,0,1)
        var bx:=x+part*238
        _plate(Vector2(bx,70),Vector2(232,4),Tokens.EDGE)
        _plate(Vector2(bx,70),Vector2(232*amount,4),Tokens.GOLD)
    _text(Vector2(x,92),"L "+tr_text("special") if fighter.meter>=50 else tr_text("energy")+" %d"%fighter.meter,11,Tokens.GOLD if fighter.meter>=50 else Tokens.MUTED)
    _text(Vector2(x+340,92),tr_text("guard")+" %d"%fighter.guard,11,Tokens.MUTED)

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
            var ready: bool=a.state=="attack" and a.frame>=session.Simulation.MOVES.air_finisher.startup-6 and a.frame<session.Simulation.MOVES.air_finisher.startup
            caption=tr_text("air_parry_now" if ready else "air_wait_windup")
        _center(Vector2(640,600),caption,14,PAPER)
        return
    var f: Dictionary=session.sim.fighters[0]
    _plate(Vector2(330,548),Vector2(620,108),Color(INK,.96))
    _text(Vector2(348,575),tr_text("air_lab"),18,Tokens.TEAL)
    _text(Vector2(744,575),tr_text("air_phase_"+f.air.phase),14,Tokens.GOLD)
    _center(Vector2(640,600),tr_text("air_jump_help"),14,PAPER)
    _center(Vector2(640,623),tr_text("air_combo_help"),14,PAPER)
    if session.sim.can_air_parry(0) and session.sim.fighters[1].frame>=session.Simulation.MOVES[session.sim.fighters[1].move].startup-6:
        _center(Vector2(640,646),tr_text("air_parry_now"),13,Tokens.GOLD)
    elif f.air.chase_window>0 and not f.air.chase_used:
        _center(Vector2(640,646),tr_text("air_chase_ready"),13,Tokens.GOLD)
    else:_center(Vector2(640,646),tr_text("air_stall")+" %d / 12"%f.air.stall_left,12,Tokens.MUTED)

func _sync_air_controls() -> void:
    if not is_instance_valid(air_lesson):return
    var active: bool=session.screen=="play" and session.sim.is_aerial()
    var lesson: bool=session.sim.is_air_lesson()
    var counter=session.sim.air_counter
    air_lesson.visible=active
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
            var move: Dictionary=session.Simulation.MOVES[f.move]
            if f.frame>=move.startup and f.frame<move.startup+move.active:
                draw_line(session.project(Vector2(f.x,f.y+1.2)),session.project(Vector2(f.x+f.face*move.reach,f.y+1.2)),Color.RED,5)
