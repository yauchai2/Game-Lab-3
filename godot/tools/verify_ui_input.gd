extends SceneTree
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("UI INPUT FAIL: "+label)
func control(hud: Node, key: String) -> Control:
    for node in hud.menu_stack.find_children("*","Control",true,false):
        if node.get_meta("ui_key","")==key:return node
    return null
func frames(count := 2) -> void:
    for i in count:await process_frame
func tap(code: Key) -> void:
    var event:=InputEventKey.new()
    event.keycode=code
    event.physical_keycode=code
    event.pressed=true
    Input.parse_input_event(event)
    await frames(1)
    event=event.duplicate()
    event.pressed=false
    Input.parse_input_event(event)
    await frames()
func click(node: Control) -> void:
    # Input.parse_input_event consumes window pixels, not logical canvas points.
    var at:=root.get_screen_transform()*node.get_global_rect().get_center()
    var motion:=InputEventMouseMotion.new()
    motion.position=at
    motion.global_position=at
    Input.parse_input_event(motion)
    await frames(1)
    var event:=InputEventMouseButton.new()
    event.position=at
    event.global_position=at
    event.button_index=MOUSE_BUTTON_LEFT
    event.pressed=true
    Input.parse_input_event(event)
    await frames(1)
    event=event.duplicate()
    event.pressed=false
    Input.parse_input_event(event)
    await frames()
func run() -> void:
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    current_scene=scene
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    await frames(4)
    var training: Button=control(scene.hud,"training")
    var motion:=InputEventMouseMotion.new()
    motion.position=root.get_screen_transform()*training.get_global_rect().get_center()
    motion.global_position=motion.position
    Input.parse_input_event(motion)
    await frames(3)
    var badge: Label=training.get_child(0)
    var foreground: Color=badge.get_theme_color("font_color").srgb_to_linear()
    var background: Color=badge.get_theme_color("font_outline_color").srgb_to_linear()
    var fg: float=foreground.r*.2126+foreground.g*.7152+foreground.b*.0722
    var bg: float=background.r*.2126+background.g*.7152+background.b*.0722
    check("real pointer hover keeps outlined shortcut contrast above 4.5",training.is_hovered() and (maxf(fg,bg)+.05)/(minf(fg,bg)+.05)>=4.5)
    await click(control(scene.hud,"settings"))
    check("pointer opens settings from title",scene.hud.menu_page=="settings")
    var language: OptionButton=control(scene.hud,"language")
    language.grab_focus()
    await tap(KEY_SPACE)
    check("keyboard opens native language popup",language.get_popup().visible)
    await tap(KEY_ESCAPE)
    check("popup Escape does not leave settings",scene.hud.menu_page=="settings" and not language.get_popup().visible)
    language.grab_focus()
    await tap(KEY_SPACE)
    await tap(KEY_DOWN)
    await tap(KEY_ENTER)
    check("native popup selection changes to English",scene.language=="en" and scene.hud.menu_page=="settings")
    var slider: HSlider=control(scene.hud,"music_volume")
    scene.hud.menu_scroll.ensure_control_visible(slider)
    await frames()
    slider.grab_focus()
    var old_value:=slider.value
    await tap(KEY_LEFT)
    check("keyboard changes native audio slider",scene.audio.music_level<old_value and slider.has_focus())
    await tap(KEY_ESCAPE)
    check("page Escape returns focus to title settings action",scene.hud.menu_page=="main" and control(scene.hud,"settings").has_focus())
    await click(control(scene.hud,"drill"))
    check("pointer opens read-first dojo",scene.screen=="play" and scene.sim.pressure_drill)
    await click(scene.hud.drill_start)
    for i in 17:
        scene._physics_process(1.0/60)
        scene._process(1.0/60)
    await frames()
    check("pointer Start creates the actual clash",scene.sim.exchange.active())
    await click(scene.hud.choice_buttons[1])
    scene._physics_process(1.0/60)
    check("pointer chooses and locks TURN",scene.sim.exchange.clash.choices[0]=="turn")
    await click(scene.hud.choice_buttons[2])
    scene._physics_process(1.0/60)
    check("disabled choice click cannot change commitment",scene.sim.exchange.clash.choices[0]=="turn")
    await tap(KEY_F1)
    check("settings shortcut pauses a live clash",scene.screen=="pause" and scene.hud.menu_page=="settings")
    var time_left: int=scene.sim.exchange.clash.remaining
    scene._physics_process(1.0/60)
    check("settings does not consume decision time",scene.sim.exchange.clash.remaining==time_left)
    await tap(KEY_ESCAPE)
    await tap(KEY_ESCAPE)
    check("Escape returns through pause and resumes same fight",scene.screen=="play" and scene.sim.exchange.clash.choices[0]=="turn")
    root.size=Vector2i(960,540)
    scene.return_to_title()
    await frames(4)
    await click(control(scene.hud,"settings"))
    check("pointer coordinates still match settings at 960x540",scene.hud.menu_page=="settings")
    var back_was_visible: bool=scene.hud.back_button.visible
    await click(scene.hud.back_button)
    check("persistent Back remains clickable in small viewport",back_was_visible and scene.hud.menu_page=="main")
    root.size=Vector2i(1024,768)
    await frames(4)
    await click(control(scene.hud,"settings"))
    check("letterboxed 4:3 viewport preserves native pointer hit targets",scene.hud.menu_page=="settings")
    scene.queue_free()
    await frames()
    await create_timer(.15).timeout
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/extended-polish/ui-input.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"method":"Actual X11 Godot viewport Input.parse_input_event mouse and keyboard; not physical human input"},"  "))
    print("UI_INPUT_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
