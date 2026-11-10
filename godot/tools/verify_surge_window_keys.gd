extends SceneTree
## Live fixture: desktop B, K, E. Clock is the actual 60 Hz physics process.
var s:Node
var opened_tick:=-1
var result:Dictionary={}
func _initialize() -> void:call_deferred("run")
func observe(event:Dictionary) -> void:
    if event.kind=="surge_decision_start":opened_tick=s.sim.tick_count
    elif event.kind=="surge_decision_end":
        result={"choices":event.choices,"decision_steps":s.sim.tick_count-opened_tick,"passed":event.choices[0]=="evade" and s.sim.tick_count-opened_tick==21,"scope":"Actual desktop B/K/E in explicit 60 energy / 60 SURGE training fixture; ordinary live physics and input handlers. Not human fun validation."}
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";root.add_child(s);s.audio.muted=true
    s.combat_event.connect(observe)
    var budget:=0
    var captured:=false
    while result.is_empty() and budget<7200:
        await process_frame;budget+=1
        if s.sim.exchange.decision_active() and not captured:
            s.hud.queue_redraw();await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://../docs/evidence/surge-window/real-key-window.png");captured=true
    if result.is_empty():result={"passed":false,"reason":"timeout waiting for desktop keys"}
    FileAccess.open("res://../docs/evidence/surge-window/real-keys.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
    await create_timer(.5).timeout
    s.return_to_title();s.queue_free();s=null
    for i in 8:await process_frame
    await create_timer(.3).timeout;quit(0 if result.passed else 1)
