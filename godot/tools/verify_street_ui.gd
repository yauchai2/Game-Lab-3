extends SceneTree
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("STREET UI FAIL: "+label)
func frames(count := 3) -> void:
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
func shot(label: String) -> void:
    await frames()
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://../docs/evidence/extended-polish/street-ui/"+label+".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../docs/evidence/extended-polish/street-ui"))
    var scene=preload("res://scenes/street_walk.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    current_scene=scene
    scene.select_reference(0)
    scene.get_node("AircraftFlyby").set_process(false)
    scene.street_hud.copy.language="zh"
    scene.street_hud.refresh()
    await frames()
    check("legacy development help is hidden",not scene.get_node("Street/Overlay/Help").is_visible_in_tree())
    check("street uses the shared CJK UI font",scene.street_hud.theme.default_font==preload("res://scripts/combat/ui/ui_theme.gd").BODY)
    check("exploration controls start compact",not scene.street_hud.expanded)
    await shot("01_compact_zh")
    await tap(KEY_H)
    check("H expands street controls through viewport input",scene.street_hud.expanded)
    await shot("02_help_zh")
    await tap(KEY_H)
    check("H collapses controls without changing reference camera",not scene.street_hud.expanded and not scene.walking)
    await tap(KEY_3)
    check("reference view keys still reach the street",not scene.walking and scene.street.active_view==2)
    await tap(KEY_0)
    var first_person: bool=scene.player.first_person
    await tap(KEY_V)
    check("walk and camera mode shortcuts still work",scene.walking and scene.player.first_person!=first_person)
    await tap(KEY_ESCAPE)
    check("Escape frees the pointer for native UI",not scene.player.mouse_look_enabled and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
    scene.get_node("AircraftFlyby").restart()
    await tap(KEY_M)
    check("street mute cancels active or pending flyby playback",scene.options.muted and not scene.get_node("AircraftFlyby").sound.playing)
    await tap(KEY_M)
    check("street unmute restarts engine audio during the same flyby",not scene.options.muted and scene.get_node("AircraftFlyby").sound.playing)
    scene.get_node("AircraftFlyby").freeze_for_capture()
    scene.select_reference(0)
    scene.street_hud.copy.language="en"
    scene.street_hud.refresh()
    check("English return action is localized",scene.street_hud.back_button.text=="BACK TO FIGHT / F6")
    await shot("03_compact_en")
    var at: Vector2=root.get_screen_transform()*scene.street_hud.back_button.get_global_rect().get_center()
    var click:=InputEventMouseButton.new()
    click.position=at
    click.global_position=at
    click.button_index=MOUSE_BUTTON_LEFT
    click.pressed=true
    Input.parse_input_event(click)
    await frames(1)
    click=click.duplicate()
    click.pressed=false
    Input.parse_input_event(click)
    await frames(8)
    check("mouse return action opens fight title",current_scene.name=="StreetFight" and current_scene.screen=="title")
    if current_scene.name=="StreetFight":current_scene.audio.muted=true
    current_scene.queue_free()
    await frames()
    await create_timer(.15).timeout
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/extended-polish/street-ui/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"method":"native Godot viewport key/mouse injection and rendered screenshots"},"  "))
    print("STREET_UI_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
