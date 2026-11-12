extends SceneTree
const OUT="res://../docs/evidence/ink-ui/"
var s:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,passed:bool,detail:Variant=null) -> void:
    checks.append({"name":label,"passed":passed,"detail":detail});print("INK_UI ",label," ",passed)
func frames(count:=4) -> void:
    for i in count:await process_frame
func shot(label:String) -> void:
    s.hud.queue_redraw();await frames();await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(OUT+label+".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    root.gui_embed_subwindows=true
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    await frames()
    check("Shared960x540 framebuffer",root.get_texture().get_size()==Vector2(960,540))
    check("New logo has its own modular asset",s.hud.Tokens.LOGO.resource_path=="res://assets/ui/ink/logo.tres")
    await shot("title")
    s.hud.open_page("roster")
    for choice in 4:
        s.set_character(0,choice)
        s.hud.roster_preview.update_preview(true,choice,.12,false);await frames(8)
        var model:Node=s.hud.roster_preview.models[4]
        var flat:=true;var outline_off:=true
        for material in model.materials:
            flat=flat and material.get_shader_parameter("silhouette_preview")==false
            outline_off=outline_off and material.next_pass.get_shader_parameter("silhouette_preview")==false
        check("Real3D textured LAST SERVICE preview "+str(choice),flat and outline_off and model.skeleton!=null)
        await shot("roster"+str(choice))
    s.hud.open_page("settings");await shot("settings")
    var option:OptionButton
    for node in s.hud.menu_stack.get_children():
        if node is OptionButton:option=node;break
    option.show_popup();await frames()
    check("Native select popup opens",option.get_popup().visible)
    await shot("settings-select")
    option.get_popup().hide()
    s.hud.menu_scroll.scroll_vertical=2000;await shot("settings-bottom")
    s.hud.open_page("help");await shot("help")
    s.hud.menu_scroll.scroll_vertical=2000;await shot("help-bottom")
    s.hud.close_page();s.start_match(true)
    for i in 20:s._process(1.0/60)
    var normal:=true
    for fighter in s.fighters:
        for material in fighter.materials:normal=normal and not material.get_shader_parameter("silhouette_preview")
    check("Gameplay retains textured character materials",normal)
    await shot("hud")
    s.pause_game();await shot("pause")
    s.hud.open_page("settings");await shot("pause-settings")
    # Explicit result-state fixture; not a claimed KO playthrough.
    s.screen="result";s.sim.phase="match_over";s.sim.winner=0;s.sim.wins=[2,0]
    s.result_clock=s.FINISH_SECONDS+.5;s.hud.rebuild_menu();await shot("result")
    check("Shared readable body font",s.hud.theme.default_font_size>=28)
    check("Result has real rematch action",s.hud.menu_stack.get_children().any(func(n:Node)->bool:return n is Button and n.get_meta("ui_key","")=="rematch"))
    var file:=FileAccess.open(OUT+"page-checks.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"scope":"Native Compatibility page captures, four real3D preview silhouettes, native select popup, menu actions. Result page uses an explicit state fixture. Not a human playthrough or target Mac proof."},"  "));file.close()
    s.queue_free();await frames(8)
    root.gui_embed_subwindows=false
    await create_timer(.25).timeout
    var passed:=checks.all(func(c:Dictionary)->bool:return c.passed)
    quit(0 if passed else 1)
