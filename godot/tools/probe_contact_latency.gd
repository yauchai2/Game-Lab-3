extends SceneTree
const OUT="res://../docs/evidence/live-combat/"
var s:Node
func _initialize() -> void:call_deferred("run")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    var results:Array=[]
    for pressure in [0,60]:
        for kind in ["launcher","parry","overdrive"]:
            s.start_match(true);s.sim.phase="fight";s.sim.partner_mode=0;s.sim.exchange.pressure=pressure
            s.sim.fighters[0].x=-.55;s.sim.fighters[1].x=.55
            if kind=="parry":
                s.sim.tick({"attack":"light"},{"guard":true})
                while not s.sim.events.any(func(e:Dictionary)->bool:return e.kind=="parry"):s.sim.tick({}, {"guard":true})
            else:
                s.sim.tick({"attack":kind})
                while not s.sim.events.any(func(e:Dictionary)->bool:return e.kind=="hit"):s.sim.tick()
            for e in s.sim.events:s._handle_event(e)
            var stop_ticks:int=s.sim.hitstop;var frames:=0
            var last:Array=s.sim.fighters.duplicate(true)
            var before_tick:int=s.sim.tick_count
            while frames<240:
                s._physics_process(1.0/60);frames+=1
                if s.sim.fighters[0].frame!=last[0].frame or s.sim.fighters[0].stun!=last[0].stun or s.sim.fighters[1].stun!=last[1].stun:break
            results.append({"contact":kind,"surge":pressure,"native_hitstop_ticks":stop_ticks,"first_live_action_wall_frames":frames,"nominal_seconds":frames/60.0,"simulation_steps":s.sim.tick_count-before_tick})
    var label:="before"
    for arg in OS.get_cmdline_user_args():label=arg
    FileAccess.open(OUT+label+"-latency.json",FileAccess.WRITE).store_string(JSON.stringify({"fixtures":results,"scope":"Real contact setup then virtual 60Hz wall stepping until actor state advances; no hardware latency or human response claim."},"  "))
    s.return_to_title();s.queue_free();s=null
    for i in 8:await process_frame
    await create_timer(.3).timeout;quit()
