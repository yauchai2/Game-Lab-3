extends SceneTree
## Four close-range training fixtures, normal command inputs, real scene and events.
var scene:Node
var frame:=0
var segments:Array=[]
var counts:Dictionary={}
var clips:Dictionary={}
var guard_walk:=false
func _initialize() -> void:call_deferred("setup")
func key(code:int,pressed:bool) -> void:
    var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=pressed;Input.parse_input_event(event)
func setup() -> void:
    if not preload("res://scripts/combat/mixamo_motion_library.gd").available():push_error("Private motion data required");quit(2);return
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path="";scene.progression_path="";root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false)
    scene.combat_event.connect(func(event:Dictionary):counts[event.kind]=int(counts.get(event.kind,0))+1)
    reset_segment()
func reset_segment() -> void:
    if frame>0:save_segment()
    key(KEY_D,false);key(KEY_SHIFT,false)
    var hero:int=floori(float(frame)/90.0)
    scene.return_to_title();scene.set_character(0,hero);scene.set_character(1,(hero+1)%4)
    scene.start_match(true);scene.round_theatre.clear();scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=0;scene.sim.fighters[1].x=1.65
    counts.clear();clips.clear();guard_walk=false
func save_segment() -> void:
    segments.append({"hero":floori(float(frame)/90.0)-1,"events":counts.duplicate(),"clips":clips.keys(),"guard_walk_input":guard_walk})
func _process(_delta:float) -> bool:
    if scene==null:return false
    if scene.screen!="play":push_error("Capture lost play state / focus");quit(1);return false
    var local_frame:int=frame%90
    if frame>0 and local_frame==0:reset_segment()
    if local_frame==0:key(KEY_D,true);key(KEY_SHIFT,true);guard_walk=true
    if local_frame==18:key(KEY_D,false);key(KEY_SHIFT,false)
    for step in 2:
        if local_frame==21 and step==0:scene.pending={"attack":"heavy","down":true}
        elif local_frame==65 and step==0:scene.pending={"attack":"light"}
        scene._combat_step();scene._process(1.0/60)
        for actor in scene.fighters:
            if actor.motions.clip_name.begins_with("MX_"):clips[actor.motions.clip_name]=true
    frame+=1
    if frame>=360:
        key(KEY_D,false);key(KEY_SHIFT,false)
        save_segment()
        var good:bool=segments.size()==4
        for segment in segments:good=good and segment.guard_walk_input and segment.clips.has("MX_Walking") and segment.events.get("swing",0)>=1
        var args:PackedStringArray=OS.get_cmdline_user_args()
        if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify({"frames":frame,"fps":30,"seconds":12,"segments":segments,"expected_events":good,"scope":"Four reset training fixtures. Forward guard walking, heavy then light commands; actual simulation and presentation. No injected damage, air state or motion pose. Linux software rendering, not human play or performance."},"  "))
        scene.return_to_title();scene.queue_free();scene=null;call_deferred("quit",0 if good else 1)
    return false
