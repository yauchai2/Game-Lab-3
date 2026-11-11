extends SceneTree
## Real native physics + viewport inputs. No direct simulation tick/position edits.
var scene: Node
var started:=0
var duration:=120.0
var output:="res://../docs/evidence/aerial-street/native-soak"
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
        print("AIR_NATIVE_SOAK ",JSON.stringify(report))
        call_deferred("quit")
        return
    if scene.screen=="title":tap(KEY_F11,now);stage=0;deadline=now+400;return
    if scene.screen=="pause":tap(KEY_ESCAPE,now);return
    if scene.screen!="play" or now<deadline:return
    var f: Dictionary=scene.sim.fighters[0]
    match stage:
        0:
            tap(KEY_F11,now);resets+=1
            stage=1;deadline=now+250
        1:
            key(KEY_W,true);tap(KEY_K,now)
            stage=2;deadline=now+120
        2:
            key(KEY_W,false)
            if f.air.chase_window>0:
                tap(KEY_E,now);stage=3;deadline=now+60
            elif f.state=="idle":stage=0;deadline=now+250
        3:
            if f.state=="idle" and f.air.chase_used:
                tap(KEY_J,now);stage=4;deadline=now+60
        4:
            if f.state=="attack" and f.hit_confirmed and f.move in ["air_jab","air_kick"]:tap(KEY_J,now)
            if f.y==0 and f.state=="idle":stage=5;deadline=now+250
        5:
            tap(KEY_SPACE,now);stage=6;deadline=now+550
        6:
            tap(KEY_S,now);stage=7;deadline=now+550
        7:
            loops+=1
            stage=0;deadline=now+350
