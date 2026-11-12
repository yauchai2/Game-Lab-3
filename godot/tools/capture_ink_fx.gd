extends SceneTree
## Movie writer captures real rendered/audio frames; fixed-step AI is not hardware FPS.
var s:Node
var frame:=0
var rows:Array=[]
var hits:=0
var last_hits:=0
var frame_draw_calls:=0
var cpu_samples:Array=[]
func _initialize() -> void:call_deferred("setup")
func setup() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path=""
    root.add_child(s);s.set_process(false);s.set_physics_process(false)
    seed(4242);s.set_character(0,0);s.set_character(1,1);s.start_demo()
    s.round_theatre.clear();s.sim.phase="fight"
    s.combat_event.connect(func(e:Dictionary):
        if e.kind=="hit":hits+=1)
func _process(_delta:float) -> bool:
    if s==null:return false
    if frame==180:
        rows.append({"pair":[0,1],"hits":hits-last_hits});last_hits=hits
        s.return_to_title();s.set_character(0,2);s.set_character(1,3);s.start_demo();s.round_theatre.clear();s.sim.phase="fight";seed(4343)
    var start:=Time.get_ticks_usec()
    for i in 2:s._physics_process(1.0/60);s._process(1.0/60)
    cpu_samples.append(float(Time.get_ticks_usec()-start)/1000)
    frame_draw_calls=maxi(frame_draw_calls,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
    frame+=1
    if frame>=360:
        rows.append({"pair":[2,3],"hits":hits-last_hits})
        cpu_samples.sort()
        var args:=OS.get_cmdline_user_args()
        if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify({"segments":rows,"frames":frame,"capture_fps":30,"virtual_seconds":12,"draw_calls_peak":frame_draw_calls,"presentation_cpu_ms_p95":cpu_samples[floori(cpu_samples.size()*.95)],"scope":"Movie Writer native Compatibility llvmpipe with real mixer, fixed virtual wall steps; CPU includes two simulation and presentation steps, not target hardware FPS."},"  "))
        s.return_to_title();s.queue_free();s=null;call_deferred("quit")
    return false
