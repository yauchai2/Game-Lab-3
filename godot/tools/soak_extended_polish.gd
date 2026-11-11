extends SceneTree
var scene: Node
var start_ms := 0
var duration := 10800.0
var output := "/tmp/baseline-soak"
var frame_count := 0
var matches := 0
var clashes := 0
var throws := 0
var recoveries := 0
var menu_cycles := 0
var menu_release_ms := 0
var last_sample := -60.0
var last_scene_cycle := 0
var sample_file: FileAccess
var timer: Timer
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var args:=OS.get_cmdline_user_args()
    if args.size()>0:duration=float(args[0])
    if args.size()>1:output=args[1]
    DirAccess.make_dir_recursive_absolute(output)
    sample_file=FileAccess.open(output+"/samples.jsonl",FileAccess.WRITE)
    start_ms=Time.get_ticks_msec()
    await load_fight()
    timer=Timer.new()
    timer.wait_time=1.0/60.0
    timer.timeout.connect(drive)
    root.add_child(timer)
    timer.start()
    process_frame.connect(sample)
func load_fight() -> void:
    scene=load("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_physics_process(false)
    scene.audio.muted=true
    scene.start_match(false)
    scene.sim.phase="fight"
    scene.sim.difficulty=matches%3
    await process_frame
func drive() -> void:
    if not is_instance_valid(scene):return
    if menu_release_ms>0:
        if Time.get_ticks_msec()<menu_release_ms:return
        scene.hud.close_page()
        scene.resume_game()
        menu_release_ms=0
    if matches>last_scene_cycle and matches%3==0 and scene.hud.has_method("open_page"):
        last_scene_cycle=matches
        scene.hud.open_page("settings")
        scene.set_language("en" if menu_cycles%2==0 else "zh")
        menu_cycles+=1
        menu_release_ms=Time.get_ticks_msec()+1500
        return
    if scene.screen=="result":
        matches+=1
        scene.start_match(false)
        scene.sim.phase="fight"
        scene.sim.difficulty=matches%3
    if scene.screen!="play":return
    var sim=scene.sim
    var a:Dictionary=sim.fighters[0]
    var b:Dictionary=sim.fighters[1]
    var command={"axis":signf(b.x-a.x) if absf(b.x-a.x)>1.35 else 0.0}
    if sim.tick_count%22==0:command["attack"]="heavy" if sim.tick_count%66==0 else "light"
    if sim.tick_count%47<6:command["guard"]=true
    if sim.tick_count%190==0:command["jump"]=true
    if a.has("wall_tech_window") and a.wall_tech_window>0:command["dash"]=true
    if b.guarding and absf(a.x-b.x)<1.1 and sim.tick_count%19==0:command["attack"]="grab"
    if sim.exchange.active():command["clash_choice"]=sim.exchange.CHOICES[(sim.exchange.serial+matches)%3]
    var previous_stop:int=sim.hitstop
    var previous_clash:bool=sim.exchange.active()
    sim.tick(command)
    if not previous_clash and sim.exchange.active():clashes+=1
    if previous_stop>0 and sim.hitstop==0:scene._release_impacts()
    for event in sim.events:
        if event.kind=="hit" and event.get("move","")=="grab":throws+=1
        if event.kind=="wall_tech":recoveries+=1
        scene._handle_event(event)
    if sim.phase in ["round_over","match_over"]:
        scene._release_impacts(false)
        scene.screen="result"
        scene.hud.rebuild_menu()
func sample() -> void:
    frame_count+=1
    var elapsed:float=(Time.get_ticks_msec()-start_ms)/1000.0
    if elapsed-last_sample>=60.0:
        last_sample=elapsed
        var sample_data={"elapsed_seconds":elapsed,"frames":frame_count,"matches":matches,"clashes":clashes,"throws":throws,"recoveries":recoveries,"menu_cycles":menu_cycles,"fps":Engine.get_frames_per_second(),"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC),"object_count":Performance.get_monitor(Performance.OBJECT_COUNT),"node_count":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"orphan_nodes":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),"adapter":RenderingServer.get_video_adapter_name()}
        sample_file.store_line(JSON.stringify(sample_data))
        sample_file.flush()
        print("SOAK ",JSON.stringify(sample_data))
    if elapsed>=duration:
        timer.stop()
        process_frame.disconnect(sample)
        var file:=FileAccess.open(output+"/complete.json",FileAccess.WRITE)
        file.store_string(JSON.stringify({"elapsed_seconds":elapsed,"frames":frame_count,"matches":matches,"clashes":clashes,"throws":throws,"recoveries":recoveries,"menu_cycles":menu_cycles,"completed":true,"method":"native software GL bot observation driven by Timer callbacks; audio muted, not human playtesting or target hardware FPS"},"  "))
        file.close()
        scene.queue_free()
        call_deferred("quit")
