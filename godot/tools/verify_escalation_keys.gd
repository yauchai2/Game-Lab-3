extends SceneTree
## Explicit frozen-time input fixture: actual desktop keys, no gameplay success claim.
var s:Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    await process_frame;await process_frame
    s.start_match(true);s.sim.phase="fight";s.sim.continuation.open(0);s.rhythm.trigger("parry",0)
    var remaining:=1200
    while s.sim.continuation.slots[0].choice!="heavy" and remaining>0:
        await create_timer(.1).timeout;remaining-=1
    if remaining==0:quit(1);return
    s.hud.queue_redraw()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://../docs/evidence/combat-escalation/real-key-lock.png")
    while s.screen!="pause" and remaining>0:
        await create_timer(.1).timeout;remaining-=1
    var snapshot:Array=s.sim.continuation.slots.duplicate(true)
    while s.screen=="pause" and remaining>0:
        await create_timer(.1).timeout;remaining-=1
    var ok:bool=remaining>0 and s.sim.continuation.slots==snapshot and s.rhythm.age==0
    FileAccess.open("res://../docs/evidence/combat-escalation/real-keys.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":ok,"locked":"K","hold_age":s.rhythm.age,"scope":"Actual desktop K, Esc, Esc in explicitly frozen presentation fixture. Simulation not advanced; no human gameplay claim."},"  "))
    s.return_to_title();s.queue_free();s=null
    for i in 8:await process_frame
    await create_timer(.3).timeout;quit(0 if ok else 1)
