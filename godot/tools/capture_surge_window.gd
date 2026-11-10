extends SceneTree
## Explicit identical-input comparison fixture, not autonomous combat or human input.
var s:Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    var reports:Array=[]
    for enabled in [false,true]:
        s.start_surge_lab(enabled)
        var events:Dictionary={}
        var listener:=func(e:Dictionary):events[e.kind]=events.get(e.kind,0)+1
        s.combat_event.connect(listener)
        var folder:String="/tmp/surge-window-"+("on" if enabled else "off")
        DirAccess.make_dir_recursive_absolute(folder)
        for tick in 180:
            if tick==0:s.pending={"attack":"heavy","up":true}
            if tick==8:s.pending={"surge_choice":"evade"} if s.sim.exchange.decision_active() else {"dash":true}
            s._physics_process(1.0/60);s._process(1.0/60);s.hud._process(1.0/60)
            if tick%4==0:
                await process_frame;await RenderingServer.frame_post_draw
                var img=root.get_texture().get_image();img.resize(640,360,Image.INTERPOLATE_NEAREST)
                img.save_png(folder+"/%04d.png"%floori(tick/4.0))
        reports.append({"window":enabled,"events":events.duplicate(),"virtual_wall_seconds":3,"fps":15,"frames":45,"silent":true})
        s.combat_event.disconnect(listener)
    FileAccess.open("res://../docs/evidence/surge-window/comparison.json",FileAccess.WRITE).store_string(JSON.stringify({"segments":reports,"scope":"Two explicitly configured fixtures, identical K-at-step-0 / E-at-step-8 intended inputs, ordinary rules. No human or free-AI claim."},"  "))
    s.return_to_title();s.queue_free();s=null
    for i in 8:await process_frame
    await create_timer(.3).timeout;quit()
