extends SceneTree
## Normal FIGHT, normal AI: actual desktop Shift held, no demo/controller/fixture positions.
var s:Node
var guarded_throw:=false
var moves:Dictionary={}
var inputs_held:=false
func _initialize() -> void:call_deferred("run")
func observe(e:Dictionary) -> void:
    if e.kind=="swing" and e.target==1:moves[e.move]=moves.get(e.move,0)+1
    if e.kind=="hit" and e.attacker==1 and e.move=="grab" and Input.is_physical_key_pressed(KEY_SHIFT):guarded_throw=true
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";root.add_child(s);s.audio.muted=true
    s.start_match(false);s.sim.difficulty=1
    s.combat_event.connect(observe)
    var budget:=0
    while not guarded_throw and budget<14400:
        await process_frame;budget+=1
        inputs_held=inputs_held or Input.is_physical_key_pressed(KEY_SHIFT)
    var report:Dictionary={"passed":guarded_throw,"mode":"normal FIGHT","difficulty":1,"demo":s.demo!=null,"training":s.sim.training,"held_shift_observed":inputs_held,"cpu_moves":moves,"player_health":s.sim.fighters[0].health,"scope":"Actual desktop held Shift in normal FIGHT through the real input handler. Default spawns, stats, countdown and opponent policy. Not a human fun/balance score."}
    FileAccess.open("res://../docs/evidence/live-combat/real-fight-keys.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    if guarded_throw:
        s.hud.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
        var img=root.get_texture().get_image();img.resize(640,360,Image.INTERPOLATE_NEAREST);img.save_png("res://../docs/evidence/live-combat/real-fight-throw.png")
        while s.screen=="play" and budget<18000:await process_frame;budget+=1
    s.return_to_title();s.queue_free();s=null
    for i in 8:await process_frame
    await create_timer(.3).timeout;quit(0 if guarded_throw else 1)
