extends SceneTree
const Tokens=preload("res://scripts/combat/ui/ui_theme.gd")
const Copy=preload("res://scripts/combat/ui/ui_text.gd")
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("UI FAIL: "+label)
func control(hud: Node, key: String) -> Control:
    for node in hud.menu_stack.find_children("*","Control",true,false):
        if node.get_meta("ui_key","")==key:return node
    return null
func frames() -> void:
    await process_frame
    await process_frame
func run() -> void:
    var glyphs:=true
    var missing: Array[int]=[]
    for values in Copy.COPY.values():
        for value in values:
            for index in str(value).length():
                var code: int=str(value).unicode_at(index)
                if code>=32 and not Tokens.BODY.has_char(code):
                    glyphs=false
                    if code not in missing:missing.append(code)
    check("bundled font covers every localized copy string",glyphs)
    print("UI_FONT_MISSING ",missing)
    var theme:=Tokens.build()
    check("labels have no opaque style that can cover button text",not theme.has_stylebox("normal","Label"))
    check("native buttons share hover pressed focus and disabled styles",theme.has_stylebox("hover","Button") and theme.has_stylebox("pressed","Button") and theme.has_stylebox("focus","Button") and theme.has_stylebox("disabled","Button"))
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    var hud=scene.hud
    var old_billboard:=false
    var dressing=scene.backdrop.street.find_children("BatchedGeometry","Node3D",true,false)[0]
    for batch in dressing.get_children():
        if not batch is MultiMeshInstance3D:continue
        for i in batch.multimesh.instance_count:
            var pose: Transform3D=batch.multimesh.get_instance_transform(i)
            if absf(pose.origin.x+9.0)<.2 and pose.origin.z>2 and pose.basis.get_scale().y>7:old_billboard=true
    check("the misplaced eight metre residential billboard is removed",not old_billboard)
    check("replacement shop fascia has a stable artwork anchor",scene.backdrop.street.has_node("CornerStreetscape/BlueCornerShopSign") and scene.backdrop.street.get_node("CornerStreetscape/BlueCornerShopSign").position.y<4)
    check("arena has two visible edge barriers outside the running envelope",scene.backdrop.street.get_node("CornerStreetscape").find_children("ArenaBarrier_*","StaticBody3D",true,false).size()==2)
    await frames()
    check("Traditional Chinese is the default",scene.language=="zh" and control(hud,"fight").text=="街頭對戰")
    check("title has separate fight training and dojo actions",control(hud,"fight")!=null and control(hud,"training")!=null and control(hud,"drill")!=null)
    check("title main actions fit without mandatory scroll",hud.menu_scroll.get_v_scroll_bar().max_value<=hud.menu_scroll.size.y+2)
    control(hud,"settings").grab_focus()
    hud.open_page("settings")
    await frames()
    check("settings has a persistent Back outside scroll",hud.back_button.visible and hud.back_button.get_parent()!=hud.menu_stack and hud.back_button.has_focus())
    check("settings starts at top instead of scrolling to the last button",hud.menu_scroll.scroll_vertical==0)
    check("language difficulty and audio sliders use native controls",control(hud,"language") is OptionButton and control(hud,"difficulty") is OptionButton and control(hud,"music_volume") is HSlider and control(hud,"sound_volume") is HSlider)
    hud.close_page()
    await frames()
    check("Back restores the originating settings action",control(hud,"settings").has_focus())
    hud.open_page("help")
    await frames()
    check("help opens to its text before action buttons",hud.menu_page=="help" and hud.menu_scroll.scroll_vertical==0 and hud.back_button.has_focus())
    hud.close_page()
    scene.start_match(true)
    scene.pause_game()
    hud.open_page("settings")
    await frames()
    scene.set_partner_mode(1)
    await frames()
    check("changing practice partner in settings keeps the game paused",scene.screen=="pause" and hud.menu_page=="settings" and scene.sim.partner_mode==1)
    var slider: HSlider=control(hud,"music_volume")
    hud.menu_scroll.scroll_vertical=180
    slider.grab_focus()
    await frames()
    var old_scroll: int=hud.menu_scroll.scroll_vertical
    slider.value=.25
    check("slider changes volume immediately",is_equal_approx(scene.audio.music_level,.25))
    check("slider does not rebuild or lose focus on every change",is_instance_valid(slider) and slider.has_focus() and hud.menu_scroll.scroll_vertical==old_scroll)
    var language: OptionButton=control(hud,"language")
    language.grab_focus()
    scene.set_language("en")
    await frames()
    check("changing language preserves native control focus",control(hud,"language").has_focus() and hud.menu_page=="settings")
    check("English view changes labels without changing simulation",control(hud,"difficulty").get_item_text(0)=="Relaxed" and scene.sim.partner_mode==1)
    scene.audio.muted=false
    scene.set_volume("music",0)
    scene.audio._process(.1)
    check("zero music level pauses or prevents music playback",not scene.audio.music.playing or scene.audio.music.stream_paused)
    scene.audio.play_sound("hit")
    scene.set_volume("sound",0)
    check("zero effects level stops playing sound voices",scene.audio.voices.all(func(v:AudioStreamPlayer)->bool:return not v.playing))
    scene.audio.muted=true
    hud.close_page()
    scene.resume_game()
    scene.sim.partner_mode=0
    scene.prime_pressure_drill()
    hud._process(0)
    check("read-first drill exposes Start and disables uncommitted choices",hud.drill_start.visible and hud.choice_buttons.all(func(b:Button)->bool:return b.disabled))
    hud.drill_start.pressed.emit()
    for i in 17:scene._physics_process(1.0/60)
    hud._process(0)
    check("native Start enters the real simulation clash",scene.sim.exchange.active() and not hud.drill_start.visible)
    check("active choices are pointer-operable native buttons",hud.choice_buttons.all(func(b:Button)->bool:return b.visible and not b.disabled and b.mouse_default_cursor_shape==Control.CURSOR_POINTING_HAND))
    hud.choice_buttons[1].pressed.emit()
    hud.choice_buttons[2].pressed.emit()
    scene._physics_process(1.0/60)
    hud._process(0)
    check("pointer choices feed the same first commitment as keyboard",scene.sim.exchange.clash.choices[0]=="turn")
    check("commitment disables every choice and removes pointer cursor",hud.choice_buttons.all(func(b:Button)->bool:return b.disabled and b.mouse_default_cursor_shape==Control.CURSOR_ARROW))
    var time_left: int=scene.sim.exchange.clash.remaining
    hud.open_page("settings")
    await frames()
    check("opening settings pauses the decision window",scene.screen=="pause" and scene.sim.exchange.clash.remaining==time_left and hud.menu_page=="settings")
    hud.close_page()
    scene.resume_game()
    scene._physics_process(1.0/60)
    check("returning from settings resumes same committed choice",scene.sim.exchange.clash.choices[0]=="turn" and scene.sim.exchange.clash.remaining==time_left-1)
    scene.reset_training()
    scene.sim.fighters[0].health=60
    hud._process(.1)
    check("health damage retains a short readable trailing segment",hud.health_lag[0]>60)
    hud._process(1.0)
    check("health trailing segment converges to actual health",is_equal_approx(hud.health_lag[0],60))
    scene.return_to_title()
    check("returning to title clears gameplay and drill state",scene.sim.phase=="ready" and not scene.sim.exchange.active() and not scene.sim.pressure_drill)
    var prefs=preload("res://scripts/combat/fight_preferences.gd").new()
    var path:="user://ui_test_preferences.cfg"
    prefs.write_options(path,{"language":"en","music_level":.25,"effects_level":.5,"training_details":true})
    var options: Dictionary=prefs.read_options(path)
    check("language volumes and practice detail preference persist",options.language=="en" and options.music_level==.25 and options.effects_level==.5 and options.training_details)
    prefs.write_options(path,{"language":"bogus","music_level":2.0,"effects_level":-1.0})
    options=prefs.read_options(path)
    check("invalid preference values are bounded or fall back",options.language=="zh" and options.music_level==1.0 and options.effects_level==0.0)
    DirAccess.remove_absolute(path)
    scene.queue_free()
    await frames()
    await create_timer(.15).timeout
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/extended-polish/ui-verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"missing_glyphs":missing},"  "))
    print("GAME_UI_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
