extends SceneTree
## Twelve-second four-hero fixture: real skills and impacts, no seeded nodes/sample/damage.
var scene:Node
var frame:=0
var counts:Dictionary={}
var segments:Array=[]
func _initialize() -> void:call_deferred("setup")
func setup() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path="";scene.progression_path="";root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false)
    scene.combat_event.connect(func(event:Dictionary):counts[event.kind]=int(counts.get(event.kind,0))+1)
    reset_segment()
func key(code:int,pressed:bool) -> void:
    var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=pressed;Input.parse_input_event(event)
func reset_segment() -> void:
    if frame>0:segments.append(counts.duplicate());counts.clear()
    key(KEY_SHIFT,false);key(KEY_D,false)
    scene.return_to_title()
    var character:int=floori(float(frame)/90.0)
    scene.set_character(0,character);scene.set_character(1,0)
    scene.start_match(true);scene.round_theatre.clear();scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=0;scene.sim.fighters[1].x=1.1 if character!=3 else 1.8
    scene.sim.fighters[0].meter=100
    if character==2:
        # Standing rival fixture starts one legal jab; P1 must actually parry.
        scene.sim._start_attack(1,"jab");key(KEY_SHIFT,true);scene.pending={"guard_pressed":true}
func _process(_delta:float) -> bool:
    if scene==null:return false
    if scene.screen!="play":
        push_error("Capture interrupted by focus pause; run this movie alone")
        key(KEY_SHIFT,false);key(KEY_D,false);quit(1);return false
    var segment:int=floori(float(frame)/90.0)
    var local_frame:int=frame%90
    if frame>0 and local_frame==0:reset_segment()
    if segment==2:
        if local_frame==12:key(KEY_SHIFT,false)
        if local_frame==35:scene.pending={"attack":"special"}
    elif segment==3:
        if local_frame==8:scene.pending={"attack":"special"}
        if local_frame==38:scene.pending={"attack":"overdrive"}
    elif local_frame==8:scene.pending={"attack":"special" if segment==0 else "overdrive"}
    for step in 2:scene._combat_step();scene._process(1.0/60)
    frame+=1
    if frame>=360:
        key(KEY_SHIFT,false);key(KEY_D,false);segments.append(counts.duplicate())
        var good:bool=segments.size()==4
        for events in segments:good=good and events.get("hit",0)>0
        good=good and segments[2].get("sample_gained",0)==1 and segments[2].get("sample_spent",0)==1 and segments[3].get("node_placed",0)==1 and segments[3].get("node_pulse_fx",0)==1
        FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify({"initial_meter_per_segment":100,"frames":frame,"fps":30,"seconds":12,"uninterrupted_play_frames":frame,"segments":segments,"expected_events":good,"scope":"Four reset training fixtures, normal session commands. HUSH rival starts one legal jab; actual parry earns sample. LOOP places a real node before encore. No injected damage/nodes/sample. Linux native rendering, not human play or hardware FPS."},"  "))
        scene.return_to_title();scene.queue_free();scene=null;call_deferred("quit",0 if good else 1)
    return false
