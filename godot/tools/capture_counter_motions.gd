extends SceneTree
## Fifteen-second native fixture: actual sample counter, two-node pulse, encore.
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
    var character:int=2 if frame<150 else 3
    scene.set_character(0,character);scene.set_character(1,0)
    scene.start_match(true);scene.round_theatre.clear();scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=0;scene.sim.fighters[1].x=1.1 if character==2 or frame>=300 else 1.8
    scene.sim.fighters[0].meter=100
    if character==2:
        # Standing rival fixture starts one legal jab; P1 must actually parry.
        scene.sim._start_attack(1,"jab");key(KEY_SHIFT,true);scene.pending={"guard_pressed":true}
func _process(_delta:float) -> bool:
    if scene==null:return false
    if scene.screen!="play":
        push_error("Capture interrupted by focus pause; run this movie alone")
        key(KEY_SHIFT,false);key(KEY_D,false);quit(1);return false
    var segment:int=floori(float(frame)/150.0)
    var local_frame:int=frame%150
    if frame>0 and local_frame==0:reset_segment()
    if segment==0:
        if local_frame==12:key(KEY_SHIFT,false)
        if local_frame==35:scene.pending={"attack":"special"}
    else:
        if local_frame==12:scene.pending={"attack":"special"}
        if local_frame==45:
            if segment==1:key(KEY_D,true);scene.pending={"attack":"special"}
            else:scene.pending={"attack":"overdrive"}
        if local_frame==46:key(KEY_D,false)
        if segment==1 and local_frame==80:scene.pending={"attack":"special","down":true}
    for step in 2:scene._combat_step();scene._process(1.0/60)
    frame+=1
    if frame>=450:
        key(KEY_SHIFT,false);key(KEY_D,false);segments.append(counts.duplicate())
        var good:bool=segments[0].get("sample_gained",0)==1 and segments[0].get("sample_spent",0)==1 and segments[0].get("hit",0)>0 and segments[1].get("node_placed",0)==2 and segments[1].get("node_pulse_fx",0)==1 and segments[2].get("node_placed",0)==1 and segments[2].get("node_pulse_fx",0)==1
        FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify({"frames":frame,"fps":30,"seconds":15,"uninterrupted_play_frames":frame,"segments":segments,"expected_events":good,"scope":"Three reset training fixtures, real frontal parry then sample L; two normal placements then S+L; one placement then W+L. Rival starts one legal jab. No seeded nodes/samples or injected damage; session command path and actual rules. Not human play or hardware FPS."},"  "))
        scene.return_to_title();scene.queue_free();scene=null;call_deferred("quit",0 if good else 1)
    return false
