extends SceneTree
## Identical legal inputs for baseline/updated captures. Four three-second fixtures.
var s:Node
var frame:=0
var hits:Array=[]
var samples:Array=[]
var out:String
func _initialize() -> void:call_deferred("setup")
func setup() -> void:
    out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path=""
    root.add_child(s);s.set_process(false);s.set_physics_process(false)
    s.combat_event.connect(func(e:Dictionary):
        if e.kind=="hit" and e.get("attacker",-1)==0:hits.append({"frame":frame,"hero":s.sim.fighters[0].character,"move":e.move,"damage":e.damage,"hitstop":s.sim.hitstop}))
    reset()
func reset() -> void:
    s.return_to_title();var hero:int=floori(float(frame)/90.0)
    s.set_character(0,hero);s.set_character(1,(hero+1)%4);s.start_match(true);s.round_theatre.clear();s.sim.phase="fight";s.sim.ai_enabled=false
    s.sim.fighters[0].x=-.7;s.sim.fighters[1].x=.7;s.sim.fighters[0].meter=100
    s.backdrop.freeze_for_capture()
func _process(_delta:float) -> bool:
    if s==null:return false
    if frame>0 and frame%90==0:reset()
    var hero:int=floori(float(frame)/90.0)
    var local_frame:int=frame%90
    if hero==3:
        if local_frame==4:s.pending={"attack":"special"}
        if local_frame==30:s.pending={"attack":"overdrive"}
    elif local_frame==8:s.pending={"attack":"overdrive"}
    for step in 2:s._physics_process(1.0/60);s._process(1.0/60)
    var a:Dictionary=s.presentation_pose(0) if s.has_method("presentation_pose") else s.sim.fighters[0]
    samples.append({"frame":frame,"hero":hero,"state":a.state,"move":a.move,"pose_frame":a.frame,"x":a.x,"y":a.y,"target_x":s.fighters[1].position.x,"target_y":s.fighters[1].position.y,"rate":s.rhythm.view_speed(),"hitstop":s.sim.hitstop})
    frame+=1
    if frame>=360:
        FileAccess.open(out+"/capture.json",FileAccess.WRITE).store_string(JSON.stringify({"frames":frame,"fps":30,"hits":hits,"samples":samples,"scope":"Four reset training fixtures, 100 initial meter, normal session commands and physics clock; no injected damage or node. Linux native Movie Writer, not hardware FPS or human play."},"  "))
        s.return_to_title();s.queue_free();s=null;call_deferred("quit")
    return false
