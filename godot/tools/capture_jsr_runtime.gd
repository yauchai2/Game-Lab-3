extends SceneTree
var scene:Node
const DIR="res://../docs/evidence/jsr-runtime"
func _initialize() -> void:call_deferred("run")
func shot(label:String) -> void:
    scene.hud.queue_redraw()
    for i in 3:await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(DIR+"/"+label+".png")
    print("JSR_SHOT ",label)
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path="";root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true;scene.backdrop.freeze_for_capture()
    for i in 50:scene._present(1.0/60)
    await shot("title-zh")
    scene.hud.open_page("roster")
    scene.set_character(0,3);scene.set_character(1,0);scene.hud.rebuild_menu()
    for i in 50:scene._present(1.0/60)
    await shot("roster-zh")
    scene.hud.open_page("settings");await shot("settings-zh")
    scene.hud.menu_scroll.scroll_vertical=2000;await shot("settings-bottom-zh")
    scene.return_to_title();scene.hud.close_page();scene.set_language("en");root.size=Vector2i(960,540);await shot("title-en-960")
    scene.hud.open_page("roster");await shot("roster-en-960")
    scene.hud.close_page();scene.start_demo()
    for frame in 240:
        scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
    await shot("demo-en-960")
    scene.pause_game();await shot("pause-en-960")
    scene.queue_free()
    for i in 6:await process_frame
    quit()
