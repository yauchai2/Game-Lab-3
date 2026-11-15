extends SceneTree
## 12-second native Movie Writer fixture: three legal charge/release inputs.
var scene:Node
var frame:=0
var hits:=0
var tiers:Array=[]
func _initialize() -> void:call_deferred("setup")
func setup() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path="";scene.progression_path="";root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false)
    scene.set_character(0,1);scene.set_character(1,0)
    scene.combat_event.connect(func(event:Dictionary):
        if event.kind=="hit":hits+=1
        if event.kind=="preload_tier":tiers.append(event.tier))
    reset_segment()
func reset_segment() -> void:
    scene.return_to_title();scene.start_match(true);scene.round_theatre.clear()
    scene.sim.phase="fight";scene.sim.ai_enabled=false
    var face:int=-1 if frame==120 else 1
    scene.sim.fighters[0].x=-.8*face;scene.sim.fighters[1].x=.8*face
    scene.sim.fighters[0].face=face;scene.sim.fighters[1].face=-face
    scene.sim.fighters[0].meter=100
    scene.backdrop.freeze_for_capture()
func key(pressed:bool) -> void:
    var event:=InputEventKey.new();event.physical_keycode=KEY_L;event.pressed=pressed
    Input.parse_input_event(event)
func _process(_delta:float) -> bool:
    if scene==null:return false
    var segment:int=floori(float(frame)/120.0)
    var local_frame:int=frame%120
    if frame>0 and local_frame==0:reset_segment()
    if local_frame==15:scene.pending={"attack":"special"};key(segment>0)
    if local_frame==[16,27,34][mini(segment,2)]:key(false)
    for step in 2:
        scene._physics_process(1.0/60);scene._process(1.0/60)
    if frame in [22,27,31,34,38,42,46,50,54,60,142,150,158,166,262,270,278,286]:call_deferred("shot",frame)
    frame+=1
    if frame>=360:
        key(false)
        var path:String=OS.get_cmdline_user_args()[0]
        FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"frames":frame,"fps":30,"seconds":12,"hits":hits,"preload_events":tiers,"scope":"Three reset training fixtures, normal L press/hold/release through session command path. Real hits, native rendered/mixed Movie Writer frames; not a natural human match or measured hardware FPS."},"  "))
        scene.return_to_title();scene.queue_free();scene=null;call_deferred("finish_capture")
    return false

func shot(index:int) -> void:
    await RenderingServer.frame_post_draw
    var path:String=OS.get_cmdline_user_args()[0].get_base_dir()
    root.get_texture().get_image().save_png(path+"/frame-%03d.png"%index)

func finish_capture() -> void:
    for step in 8:await process_frame
    await RenderingServer.frame_post_draw
    call_deferred("quit")
