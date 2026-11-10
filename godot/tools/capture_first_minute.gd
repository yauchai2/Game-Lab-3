extends SceneTree
## Explicit automated student fixture. Ordinary inputs and real contact rules throughout.
const Student=preload("res://tools/first_minute_student.gd")
var s:Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    s.start_first_minute()
    var folder:="/tmp/first-minute-frames";DirAccess.make_dir_recursive_absolute(folder)
    var wait:=0;var frames:=0;var total:=0;var winding:=false
    var events:Dictionary={};var listener:=func(e:Dictionary):events[e.kind]=events.get(e.kind,0)+1
    s.combat_event.connect(listener)
    for tick in 1400:
        if s.coach.status=="ready":
            wait+=1
            if wait>=60:s.continue_coach();wait=0
        elif s.coach.status=="passed":
            wait+=1
            if wait>=75:s.continue_coach();wait=0
        elif s.coach.status=="complete":
            wait+=1
            if wait>=90:break
        else:s.pending=Student.command(s.sim,s.coach)
        s._physics_process(1.0/60);s._process(1.0/60);s.hud._process(1.0/60);total+=1
        if tick%4==0:
            await process_frame;await RenderingServer.frame_post_draw
            var img=root.get_texture().get_image();img.resize(640,360,Image.INTERPOLATE_NEAREST)
            img.save_png(folder+"/%04d.png"%frames);frames+=1
        if not winding and s.coach.cue(s.sim).contains("SHIFT NOW"):
            s.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
            var img=root.get_texture().get_image();img.resize(640,360,Image.INTERPOLATE_NEAREST)
            img.save_png("res://../docs/evidence/first-minute/windup-cue.png");winding=true
    FileAccess.open("res://../docs/evidence/first-minute/demo.json",FileAccess.WRITE).store_string(JSON.stringify({"completed":s.coach.completed,"virtual_wall_seconds":total/60.0,"frames":frames,"fps":15,"events":events,"scope":"Automated student in explicitly configured training fixtures, not free AI or human learning/first-minute timing validation."},"  "))
    s.return_to_title();s.queue_free();s=null
    for i in 8:await process_frame
    await create_timer(.3).timeout;quit()
