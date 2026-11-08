extends SceneTree
var scene: Node
var records: Array[Dictionary]=[]
const FOLDER:="res://../docs/evidence/extended-polish/ui-review"
const FRAMES:="/tmp/afterhours-polish-frames"
func _initialize() -> void:call_deferred("run")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    scene.backdrop.freeze_for_capture()
    scene.set_language("en")
    for window in [Vector2i(1280,720),Vector2i(960,540),Vector2i(1024,768)]:
        root.size=window
        scene.return_to_title()
        for i in 90:scene._present(1.0/60)
        var prefix:="%dx%d_"%[window.x,window.y]
        scene.hud.open_page("settings")
        await shot(prefix+"settings_top")
        scene.hud.menu_scroll.scroll_vertical=2000
        await shot(prefix+"settings_bottom")
        scene.hud.close_page()
        scene.hud.open_page("help")
        await shot(prefix+"help_top")
        scene.hud.menu_scroll.scroll_vertical=2000
        await shot(prefix+"help_bottom")
        scene.hud.close_page()
        scene.start_match(true)
        scene.training_details=true
        for i in 90:scene._present(1.0/60)
        await shot(prefix+"practice_details")
        scene.prime_pressure_drill()
        scene.pending["attack"]="heavy"
        for i in 17:step()
        await shot(prefix+"clash")
    root.size=Vector2i(960,540)
    scene.set_language("zh")
    scene.training_details=false
    for clip in ["throw","edge_recovery"]:
        DirAccess.make_dir_recursive_absolute(FRAMES+"/"+clip)
        scene.sim.partner_mode=1 if clip=="throw" else 0
        scene.start_match(true)
        if clip=="throw":
            scene.sim.fighters[0].x=-.45
            scene.sim.fighters[1].x=.45
        else:
            scene.sim.training=false
            scene.sim.fighters[1].x=-5.5
            var f: Dictionary=scene.sim.fighters[0]
            f.x=-8.19
            f.y=.4
            f.state="stun"
            f.stun=30
            f.vx=-10
            f.meter=40
        for i in 90:scene._present(1.0/60)
        for frame in 90:
            if clip=="throw" and frame==10:scene.pending["attack"]="grab"
            if clip=="edge_recovery" and frame==3:scene.pending["dash"]=true
            step()
            step()
            await process_frame
            await RenderingServer.frame_post_draw
            var error:=root.get_texture().get_image().save_png(FRAMES+"/"+clip+"/%03d.png"%frame)
            if error!=OK:push_error("Animation capture failed: "+str(error))
        print("REVIEW_CLIP ",clip," 90 frames / two 60 Hz steps per frame")
    var file:=FileAccess.open(FOLDER+"/captures.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"screens":records,"animation":{"clips":["throw","edge_recovery"],"frames_each":90,"simulation_ticks_per_frame":2,"encoded_fps":30,"method":"native fixed simulation-step render; not measured real-time FPS or human input"}},"  "))
    scene.queue_free()
    for i in 4:await process_frame
    await RenderingServer.frame_post_draw
    quit()
func step() -> void:
    scene._physics_process(1.0/60)
    scene._process(1.0/60)
func shot(label: String) -> void:
    scene.hud.queue_redraw()
    for i in 4:await process_frame
    await RenderingServer.frame_post_draw
    var capture:=root.get_texture().get_image()
    var error:=capture.save_png(FOLDER+"/"+label+".png")
    records.append({"file":label+".png","png_error":error,"image_size":str(capture.get_size()),"window_size":str(root.size),"canvas_to_window":str(root.get_screen_transform()),"language":scene.language})
    print("REVIEW_SCREEN ",label," error=",error)
