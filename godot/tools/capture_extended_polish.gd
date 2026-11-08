extends SceneTree
var scene: Node
var folder:="res://../docs/evidence/extended-polish/candidate"
var records: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var args:=OS.get_cmdline_user_args()
    if args.size()>0:folder=args[0]
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    scene.backdrop.freeze_for_capture()
    for i in 100:scene._present(1.0/60)
    await shot("01_title_zh")
    scene.set_language("en")
    await shot("02_title_en")
    scene.set_language("zh")
    scene.hud.open_page("settings")
    await shot("03_settings_top")
    for node in scene.hud.menu_stack.get_children():
        if node is OptionButton and node.get_meta("ui_key","")=="language":
            node.show_popup()
            await shot("03a_language_popup")
            node.get_popup().hide()
            break
    scene.hud.menu_scroll.scroll_vertical=2000
    await shot("04_settings_bottom")
    scene.hud.close_page()
    scene.hud.open_page("help")
    await shot("05_help")
    scene.hud.close_page()
    scene.start_match(true)
    for i in 100:scene._present(1.0/60)
    await shot("06_training")
    scene.training_details=true
    await shot("07_training_details")
    scene.training_details=false
    scene.prime_pressure_drill()
    for i in 70:scene._present(1.0/60)
    await shot("08_drill_ready")
    scene.sim._start_attack(0,"heavy")
    for event in scene.sim.events:scene._handle_event(event)
    for i in 16:step()
    await shot("09_clash")
    scene.commit_clash_choice("turn")
    for i in 10:step()
    await shot("10_locked")
    for i in 14:step()
    await shot("11_counter")
    scene.pause_game()
    await shot("12_pause")
    scene.resume_game()
    scene.start_match(true)
    scene.sim.fighters[0].x=-.45
    scene.sim.fighters[1].x=.45
    scene.sim._start_attack(0,"grab")
    for event in scene.sim.events:scene._handle_event(event)
    for i in 8:step()
    await shot("12a_throw_startup")
    for i in 3:step()
    await shot("12b_throw_hit")
    for i in 13:step()
    await shot("12bb_throw_release")
    scene.start_match(true)
    scene.sim.fighters[0].x=5.5
    scene.sim.fighters[1].x=8.19
    scene.sim.fighters[1].state="stun"
    scene.sim.fighters[1].stun=30
    scene.sim.fighters[1].vx=10
    scene.sim.fighters[1].y=.4
    for i in 70:scene._present(1.0/60)
    step()
    await shot("12c_edge_bounce")
    # Demonstrate player recovery on the left edge, using the real input buffer.
    scene.start_match(true)
    scene.sim.fighters[0].x=-8.19
    scene.sim.fighters[1].x=-5.5
    scene.sim.fighters[0].state="stun"
    scene.sim.fighters[0].stun=30
    scene.sim.fighters[0].vx=-10
    scene.sim.fighters[0].y=.4
    for i in 70:scene._present(1.0/60)
    step()
    await shot("12d_recovery_prompt")
    scene.pending["dash"]=true
    for i in 5:step()
    await shot("12e_recovery")
    scene.start_match(false)
    scene.sim.phase="match_over"
    scene.sim.winner=0
    scene.sim.wins=[2,1]
    scene.sim.fighters[0].health=47
    scene.sim.fighters[1].health=0
    scene.sim.fighters[0].x=-.8
    scene.sim.fighters[1].x=.8
    scene.screen="result"
    for i in 90:scene._process(1.0/60)
    scene.hud.rebuild_menu()
    await shot("13_result")
    scene.start_match(true)
    for i in 30:scene._present(1.0/60)
    scene.hud.hide()
    scene.camera.position=Vector3(0,2.6,22)
    scene.camera.fov=68
    scene.camera.look_at(Vector3(0,7.8,-7))
    await shot("14_street_front")
    scene.camera.position=Vector3(-15,3.4,12)
    scene.camera.fov=62
    scene.camera.look_at(Vector3(-11,10.5,2))
    await shot("15_blue_facade")
    var file:=FileAccess.open(folder+"/captures.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(records,"  "))
    scene.queue_free()
    await process_frame
    await create_timer(.15).timeout
    quit()
func step() -> void:
    scene._physics_process(1.0/60)
    scene._process(1.0/60)
func shot(label: String) -> void:
    scene.hud.queue_redraw()
    for i in 8:await process_frame
    await RenderingServer.frame_post_draw
    var error:=root.get_texture().get_image().save_png(folder+"/"+label+".png")
    records.append({"shot":label,"png_error":error,"size":str(root.size),"screen":scene.screen,"page":scene.hud.menu_page,"language":scene.language,"adapter":RenderingServer.get_video_adapter_name()})
    print("EXTENDED_CAPTURE ",label," error=",error)
