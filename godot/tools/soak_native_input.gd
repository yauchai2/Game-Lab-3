extends SceneTree
## Native gameplay clock + viewport key injection. This complements the render
## soak which drives the pure simulation through a separate Timer callback.
var scene: Node
var started:=0
var duration:=1200.0
var output:="res://../docs/evidence/extended-polish/native-input-soak"
var held: Dictionary={}
var release_at: Dictionary={}
var next_attack:=0
var next_jump:=0
var next_heavy:=0
var last_sample:=-60.0
var rounds:=0
var matches:=0
var input_events:=0
var last_result_tick:=-1
var chosen_serial:=-1
var pause_at:=180000
var pause_stage:=0
var pause_deadline:=0
var samples: FileAccess
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var args:=OS.get_cmdline_user_args()
    if args.size()>0:duration=float(args[0])
    if args.size()>1:output=args[1]
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    samples=FileAccess.open(output+"/samples.jsonl",FileAccess.WRITE)
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    current_scene=scene
    scene.audio.muted=true
    started=Time.get_ticks_msec()
    process_frame.connect(drive)
func key(code: Key, pressed: bool) -> void:
    if held.get(code,false)==pressed:return
    held[code]=pressed
    var event:=InputEventKey.new()
    event.keycode=code
    event.physical_keycode=code
    event.pressed=pressed
    Input.parse_input_event(event)
    input_events+=1
func tap(code: Key, now: int) -> void:
    if held.get(code,false):return
    key(code,true)
    release_at[code]=now+140
func drive() -> void:
    var now:=Time.get_ticks_msec()
    var elapsed: float=(now-started)/1000.0
    for code in release_at.keys():
        if now>=release_at[code]:
            key(code,false)
            release_at.erase(code)
    if elapsed>=duration:
        process_frame.disconnect(drive)
        for code in held.keys():key(code,false)
        var file:=FileAccess.open(output+"/complete.json",FileAccess.WRITE)
        file.store_string(JSON.stringify({"completed":true,"elapsed_seconds":elapsed,"physics_ticks":scene.sim.tick_count,"rounds":rounds,"matches":matches,"input_events":input_events,"method":"actual native Godot physics clock with viewport Input.parse_input_event; muted Dummy audio; no human playtesting or target GPU performance claim"},"  "))
        scene.queue_free()
        call_deferred("quit")
        return
    if elapsed-last_sample>=60:
        last_sample=elapsed
        var data:={"elapsed_seconds":elapsed,"physics_ticks":scene.sim.tick_count,"rounds":rounds,"matches":matches,"input_events":input_events,"screen":scene.screen,"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)}
        samples.store_line(JSON.stringify(data))
        samples.flush()
        print("NATIVE_SOAK ",JSON.stringify(data))
        if int(elapsed/60.0) in [0,5,10,15,20]:RenderingServer.frame_post_draw.connect(capture.bind(int(elapsed)),CONNECT_ONE_SHOT)
    if scene.screen in ["title","result"]:
        if scene.screen=="result" and last_result_tick!=scene.sim.tick_count:
            last_result_tick=scene.sim.tick_count
            rounds+=1
            if scene.sim.phase=="match_over":matches+=1
        tap(KEY_ENTER,now)
        return
    if pause_stage>0:
        if now>=pause_deadline:
            tap(KEY_ESCAPE,now)
            pause_stage-=1
            pause_deadline=now+450
        return
    if scene.screen=="pause":
        tap(KEY_ESCAPE,now)
        return
    if scene.screen!="play" or scene.sim.phase!="fight":return
    if now-started>=pause_at and not scene.sim.exchange.active():
        tap(KEY_F1,now)
        pause_stage=2
        pause_deadline=now+600
        pause_at+=180000
        return
    var a: Dictionary=scene.sim.fighters[0]
    var b: Dictionary=scene.sim.fighters[1]
    var distance: float=absf(a.x-b.x)
    key(KEY_A,distance>1.25 and a.x>b.x)
    key(KEY_D,distance>1.25 and a.x<b.x)
    if scene.sim.exchange.active():
        if chosen_serial!=scene.sim.exchange.serial:
            var cue: String=scene.sim.exchange.clash.cue
            var choice: int=(scene.sim.exchange.CHOICES.find(cue)+1)%3
            tap([KEY_J,KEY_SHIFT,KEY_E][choice],now)
            chosen_serial=scene.sim.exchange.serial
        return
    if a.wall_tech_window>0:tap(KEY_E,now)
    if now>=next_attack:
        tap(KEY_G if b.guarding and distance<1.15 else KEY_J,now)
        next_attack=now+320
    if now>=next_heavy:
        tap(KEY_L if a.meter>=50 else KEY_K,now)
        next_heavy=now+1750
    if now>=next_jump:
        tap(KEY_SPACE,now)
        next_jump=now+3300
func capture(elapsed: int) -> void:
    root.get_texture().get_image().save_png(output+"/minute_%02d.png"%int(elapsed/60.0))
