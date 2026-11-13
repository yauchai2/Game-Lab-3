extends SceneTree
## Two six-second reset training fixtures; actual session commands and contacts.
var scene:Node
var frame:=0
var hits:Array=[]
var events:Array=[]
var framing:Array=[]
var output:String
func _initialize() -> void:call_deferred("setup")
func setup() -> void:
    output=OS.get_cmdline_user_args()[0]
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path="";scene.progression_path="";root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false)
    scene.combat_event.connect(func(event:Dictionary):
        if event.kind=="hit":hits.append({"movie_frame":frame,"event":event.duplicate(true),"attack_frame":scene.sim.fighters[0].frame,"stage":scene.sim.fighters[0].service.delivery_stage})
        events.append(event.kind))
    reset_segment()
func reset_segment() -> void:
    scene.return_to_title();scene.set_character(0,0);scene.set_character(1,1)
    scene.start_match(true);scene.round_theatre.clear();scene.sim.phase="fight";scene.sim.ai_enabled=false
    var face:int=1 if frame==0 else -1
    scene.sim.fighters[0].x=-1.1*face;scene.sim.fighters[1].x=1.1*face
    scene.sim.fighters[0].face=face;scene.sim.fighters[1].face=-face
    scene.sim.fighters[0].meter=100
    scene.backdrop.freeze_for_capture()
func _process(_delta:float) -> bool:
    if scene==null:return false
    if frame==180:reset_segment()
    if frame%180==12:scene.pending={"attack":"overdrive"}
    for step in 2:scene._physics_process(1.0/60);scene._process(1.0/60)
    if frame in [15,24,36,48,60,72,84,96,110,132,195,216,228,240,252,264,276,290,312]:
        framing.append({"frame":frame,"camera":str(scene.camera.position),"fov":scene.camera.fov,"fighters":scene.sim.fighters.duplicate(true)})
        call_deferred("shot",frame)
    frame+=1
    if frame>=360:
        var good:bool=hits.size()==6
        FileAccess.open(output+"/capture.json",FileAccess.WRITE).store_string(JSON.stringify({"frames":frame,"fps":30,"framing":framing,"hits":hits,"expected_contacts":good,"scope":"Two six-second reset training fixtures, 100 initial meter, standing opponent, normal overdrive commands. Native Compatibility llvmpipe, not hardware FPS or human input."},"  "))
        scene.return_to_title();scene.queue_free();scene=null;call_deferred("quit",0 if good else 1)
    return false
func shot(index:int) -> void:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(output+"/frame-%03d.png"%index)
