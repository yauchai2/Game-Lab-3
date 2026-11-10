extends SceneTree
## Real native physics + viewport inputs. No direct simulation tick/position edits.
var scene: Node
var started:=0
var duration:=120.0
var output:="res://../docs/evidence/air-reversal/native-soak"
var held: Dictionary={}
var release_at: Dictionary={}
var deadline:=0
var stage:=0
var loops:=0
var resets:=0
var counts: Dictionary={}
var input_events:=0
var max_effects:=0
var max_nodes:=0
var max_orphans:=0
var last_sample:=-10.0
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
    root.add_child(scene);current_scene=scene
    scene.audio.muted=true
    scene.combat_event.connect(func(event:Dictionary):
        counts[event.kind]=counts.get(event.kind,0)+1
        if event.kind=="hit":counts[event.move]=counts.get(event.move,0)+1)
    started=Time.get_ticks_msec()
    deadline=started
    process_frame.connect(drive)
func key(code: Key, down: bool) -> void:
    if held.get(code,false)==down:return
    held[code]=down
    var event:=InputEventKey.new()
    event.keycode=code;event.physical_keycode=code;event.pressed=down
    Input.parse_input_event(event)
    input_events+=1
func tap(code: Key, now: int) -> void:
    if held.get(code,false):return
    key(code,true);release_at[code]=now+90
func drive() -> void:
    var now:=Time.get_ticks_msec()
    var elapsed: float=(now-started)/1000.0
    for code in release_at.keys():
        if now>=release_at[code]:key(code,false);release_at.erase(code)
    max_effects=maxi(max_effects,scene.effects.size())
    max_nodes=maxi(max_nodes,int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
    max_orphans=maxi(max_orphans,int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
    if elapsed-last_sample>=10:
        last_sample=elapsed
        samples.store_line(JSON.stringify({"seconds":elapsed,"tick":scene.sim.tick_count,"effects":scene.effects.size(),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),"loops":loops,"counts":counts}))
        samples.flush()
    if elapsed>=duration:
        process_frame.disconnect(drive)
        for code in held.keys():key(code,false)
        var report:={"completed":true,"elapsed_seconds":elapsed,"input_events":input_events,"loops":loops,"resets":resets,"event_counts":counts,"max_effects":max_effects,"max_nodes":max_nodes,"max_orphans":max_orphans,"method":"real native Godot physics and viewport key events, combat_event signal observes every dispatched event; Dummy audio, software GL; no human/target GPU claim"}
        var file:=FileAccess.open(output+"/complete.json",FileAccess.WRITE)
        file.store_string(JSON.stringify(report,"  "))
        scene.queue_free()
        print("AIR_COUNTER_NATIVE_SOAK ",JSON.stringify(report))
        call_deferred("quit")
        return
    if scene.screen=="title":tap(KEY_F11,now);stage=0;deadline=now+400;return
    if scene.screen=="pause":tap(KEY_ESCAPE,now);return
    if scene.screen!="play" or now<deadline:return
    var sim=scene.sim
    match stage:
        0:
            tap(KEY_F11,now);resets+=1
            stage=1;deadline=now+220
        1:
            tap(KEY_F8,now);stage=2;deadline=now+250
        2:
            tap(KEY_K,now);stage=3;deadline=now+20
        3:
            var enemy: Dictionary=sim.fighters[1]
            if enemy.state=="attack" and enemy.frame>=7:
                tap(KEY_SHIFT,now);stage=4;deadline=now+20
            elif sim.air_lesson_stage=="review":stage=6;deadline=now+200
        4:
            if sim.air_counter.phase=="hold":
                if loops%3!=2:tap(KEY_J if loops%3==0 else KEY_E,now)
                stage=5
            elif sim.air_lesson_stage=="review":stage=6;deadline=now+200
        5:
            if not sim.air_counter.active():stage=6;deadline=now+250
        6:
            loops+=1
            stage=2;deadline=now+200
