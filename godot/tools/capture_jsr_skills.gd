extends SceneTree
var scene:Node
var captures:Array=[]
const DIR="res://../docs/evidence/jsr-runtime"
func _initialize() -> void:call_deferred("run")
func step() -> void:
    scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
func shot(name:String) -> void:
    scene.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(DIR+"/"+name+".png")
    captures.append(name);print("SKILL_SHOT ",name)
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path="";root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true;scene.backdrop.freeze_for_capture()
    root.size=Vector2i(1280,720)
    for index in 4:
        scene.return_to_title();scene.set_character(0,index);scene.set_character(1,(index+1)%4);scene.hud.open_page("roster")
        for i in 30:scene._present(1.0/60)
        await shot("fighter-%d"%index)
        for move in ["special","overdrive"]:
            scene.start_match(true);scene.sim.ai_enabled=false;scene.sim.fighters[0].x=-.7;scene.sim.fighters[1].x=.7;scene.sim.fighters[0].meter=100
            scene.pending["attack"]=move
            var saved:=false
            for frame in 300:
                step()
                if not saved and scene.effects.any(func(e:Dictionary)->bool:return e.kind=="release" and e.get("move","")==move):
                    await shot("fighter-%d-%s"%[index,move]);saved=true
            if not saved:push_error("No actual contact captured: "+str(index)+" "+move)
    scene.return_to_title();scene.set_character(0,1);scene.set_character(1,3);scene.start_demo()
    var before_hits:Array=scene.demo.hits.duplicate()
    DirAccess.make_dir_recursive_absolute("/tmp/jsr-demo-frames")
    for frame in 120:
        for tick in 4:step()
        await process_frame;await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("/tmp/jsr-demo-frames/%04d.png"%frame)
    FileAccess.open(DIR+"/capture.json",FileAccess.WRITE).store_string(JSON.stringify({"screens":captures,"demo_frames":120,"fps":15,"wall_steps":480,"hits_before":before_hits,"hits_after":scene.demo.hits,"actual_events":scene.demo.seen,"scope":"Native fixed wall-step capture; no sound, no human input, not measured frame rate."},"  "))
    scene.queue_free();for i in 6:await process_frame
    quit()
