extends SceneTree
var s:Node
var checks:Array=[]
const OUT="res://../docs/evidence/title-motion/"
func _initialize() -> void:call_deferred("run")
func verify(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error(label)
func frames(n:=2) -> void:
    for i in n:await process_frame
    await RenderingServer.frame_post_draw
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.hud.set_process(false);s.audio.muted=false;s.reduced_effects=false
    await frames(5)
    var stage:Node=s.hud.title_motion
    verify("One isolated bounded title viewport",stage.viewport.size==Vector2i(376,360) and stage.viewport.own_world_3d and stage.actors.size()==2 and stage.batches.size()==3)
    var flat:=true
    for actor in stage.actors:
        for mat in actor.materials:flat=flat and mat.get_shader_parameter("silhouette_preview") and mat.next_pass.get_shader_parameter("silhouette_preview")
    verify("Two real retargeted models use faceless colour silhouettes",flat)
    var shots:Array=[]
    for frame in 96:
        s.hud._process(1.0/12);await frames()
        if not stage.shot_index in shots:shots.append(stage.shot_index)
        var img:Image=root.get_texture().get_image()
        img.save_png("/tmp/title-motion-frames/%03d.png"%frame)
        if frame in [0,24,48,72]:img.save_png(OUT+"shot-"+str(frame/24)+".png")
    verify("All four camera sections appear in eight-second loop",shots.size()==4)
    verify("Bounded render sampling",stage.rendered_frames<=98)
    var at:float=stage.elapsed;var total:int=stage.rendered_frames
    stage.update_stage(false,.1,false);await frames()
    verify("Leaving title freezes clock and disables render",stage.elapsed==at and stage.rendered_frames==total and stage.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED)
    stage.update_stage(true,.1,true);s.hud.queue_redraw();await frames()
    root.get_texture().get_image().save_png(OUT+"reduced.png")
    verify("Reduced effects uses static poster and disables viewport",not stage.active and stage.elapsed==at and stage.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED)
    stage.elapsed=7.99;stage.accumulator=1.0;stage.update_stage(true,.1,false);await frames()
    verify("Loop wraps without accumulating scene nodes",stage.elapsed<.11 and stage.viewport.get_child_count()==7)
    verify("UI retains five original native actions",s.hud.art_buttons.size()==5)
    var file:=FileAccess.open(OUT+"motion-checks.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"engine":Engine.get_version_info().string,"scope":"Native render/state checks. Eight virtual seconds, no audio, not target hardware performance."},"  "));file.close()
    s.queue_free();s=null;await frames(6);await create_timer(.3).timeout
    quit(0 if checks.all(func(c:Dictionary)->bool:return c.passed) else 1)
