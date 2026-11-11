extends SceneTree
## Actual desktop C / Enter / held J, with normal physics and hit detection.
var s:Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";root.add_child(s);s.audio.muted=true
    var budget:=0
    while (s.coach==null or s.coach.index!=0 or s.coach.status!="passed") and budget<14400:
        await process_frame;budget+=1
    var ok:bool=s.coach!=null and s.coach.status=="passed"
    var report:Dictionary={"passed":ok,"scope":"Actual desktop C/Enter/held J, live normal physics in explicit 100-energy fixture. Real two-hit combo required; not human learning validation."}
    if ok:
        report["combo"]=s.coach.combo_max;report["completed"]=s.coach.completed.duplicate()
        s.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://../docs/evidence/first-minute/real-key-combo.png")
    FileAccess.open("res://../docs/evidence/first-minute/real-keys.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    # Leave the success card visible for desktop inspection, until the user presses Esc.
    if ok:
        while s.screen=="play" and budget<18000:
            await process_frame;budget+=1
    s.return_to_title();s.queue_free();s=null
    for i in 8:await process_frame
    await create_timer(.3).timeout;quit(0 if ok else 1)
