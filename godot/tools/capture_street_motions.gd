extends SceneTree
## Twelve-second native fixture: ZIP two/three kicks, then RIVET hook drive.
var scene:Node
var frame:=0
var hits:=0
var tiers:Array=[]
var segment_hits:Array=[]
var last_hits:=0
func _initialize() -> void:call_deferred("setup")
func setup() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path="";scene.progression_path="";root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false)
    scene.combat_event.connect(func(event:Dictionary):
        if event.kind=="hit":hits+=1
        if event.kind=="preload_tier":tiers.append(event.tier))
    reset_segment()
func reset_segment() -> void:
    if frame>0:segment_hits.append(hits-last_hits);last_hits=hits
    scene.return_to_title()
    var character:int=1 if frame>=240 else 0
    scene.set_character(0,character);scene.set_character(1,1-character)
    scene.start_match(true);scene.round_theatre.clear()
    scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=-.6;scene.sim.fighters[1].x=.6
    scene.sim.fighters[0].meter=100
func key(pressed:bool) -> void:
    var event:=InputEventKey.new();event.physical_keycode=KEY_L;event.pressed=pressed
    Input.parse_input_event(event)
func _process(_delta:float) -> bool:
    if scene==null:return false
    if scene.screen!="play":
        push_error("Capture interrupted by a focus pause; run this movie alone")
        key(false);quit(1);return false
    var segment:int=floori(float(frame)/120.0)
    var local_frame:int=frame%120
    if frame>0 and local_frame==0:reset_segment()
    if local_frame==15:scene.pending={"attack":"special" if segment==0 else "overdrive"}
    for step in 2:
        scene._combat_step();scene._process(1.0/60)
    frame+=1
    if frame>=360:
        key(false)
        segment_hits.append(hits-last_hits)
        var path:String=OS.get_cmdline_user_args()[0]
        FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"frames":frame,"fps":30,"seconds":12,"hits":hits,"segment_hits":segment_hits,"uninterrupted_play_frames":frame,"preload_events":tiers,"scope":"Three reset training fixtures: ZIP L, ZIP W+L, RIVET W+L through session command path, normal paid contacts. Native rendered/mixed frames; not a human match or hardware FPS."},"  "))
        scene.return_to_title();scene.queue_free();scene=null;call_deferred("quit")
    return false
