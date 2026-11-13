extends SceneTree
## Fourteen-second legal air route or eight-second legal throw fixtures, all four heroes.
var scene:Node
var frame:=0
var throw_mode:=false
var segment_frames:=105
var counts:Dictionary={}
var air_moves:Dictionary={}
var segments:Array=[]
func _initialize() -> void:call_deferred("setup")
func key(code:int,pressed:bool) -> void:
    var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=pressed;Input.parse_input_event(event)
func setup() -> void:
    throw_mode=OS.get_cmdline_user_args().size()>1 and OS.get_cmdline_user_args()[1]=="throw"
    segment_frames=60 if throw_mode else 105
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path="";scene.progression_path="";root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false)
    scene.combat_event.connect(func(event:Dictionary):
        counts[event.kind]=int(counts.get(event.kind,0))+1
        if event.kind=="hit" and event.attacker==0:air_moves[event.move]=int(air_moves.get(event.move,0))+1
    )
    reset_segment()
func reset_segment() -> void:
    if frame>0:segments.append({"events":counts.duplicate(),"hit_moves":air_moves.duplicate()});counts.clear();air_moves.clear()
    key(KEY_J,false)
    scene.return_to_title();scene.set_character(0,floori(float(frame)/float(segment_frames)));scene.set_character(1,0)
    scene.start_match(true);scene.round_theatre.clear();scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=0;scene.sim.fighters[1].x=1.05;scene.sim.fighters[0].meter=100
func _process(_delta:float) -> bool:
    if scene==null:return false
    if scene.screen!="play":
        push_error("Capture lost focus / play state; run alone")
        key(KEY_J,false);quit(1);return false
    var local_frame:int=frame%segment_frames
    if frame>0 and local_frame==0:reset_segment()
    if local_frame==0:scene.pending={"attack":"grab" if throw_mode else "launcher"}
    if not throw_mode and local_frame==8:key(KEY_J,true)
    if not throw_mode and local_frame in [9,14]:scene.pending={"jump":true}
    if local_frame==72:key(KEY_J,false)
    for step in 2:scene._combat_step();scene._process(1.0/60)
    frame+=1
    if frame>=segment_frames*4:
        key(KEY_J,false);segments.append({"events":counts.duplicate(),"hit_moves":air_moves.duplicate()})
        var good:bool=segments.size()==4
        for segment in segments:
            if throw_mode:good=good and segment.hit_moves.get("grab",0)==1
            else:good=good and segment.events.get("homing_chase",0)>0 and segment.hit_moves.get("air_jab",0)==1 and segment.hit_moves.get("air_kick",0)==1 and segment.hit_moves.get("meteor",0)==1
        FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify({"frames":frame,"fps":30,"seconds":8 if throw_mode else 14,"mode":"throw" if throw_mode else "air","uninterrupted_play_frames":frame,"initial_meter_per_segment":100,"segments":segments,"expected_events":good,"scope":"Four reset training fixtures at close standing range, normal grab commands or launcher + held J + Space presses. Real throw or paid chase and air hits; no injected damage, air state, sample or nodes. Not human play or GPU performance."},"  "))
        scene.return_to_title();scene.queue_free();scene=null;call_deferred("quit",0 if good else 1)
    return false
