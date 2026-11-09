extends SceneTree
var scene:Node
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("CANNON INPUT FAIL: "+label)
func step() -> void:scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
func key(code:Key,down:bool) -> void:
    var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down;Input.parse_input_event(e)
    await process_frame;await process_frame
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path=""
    root.add_child(scene);current_scene=scene;scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    await process_frame;await process_frame
    scene.set_character(0,3);scene.set_character(1,2);scene.start_match(true)
    await key(KEY_W,true);await key(KEY_L,true);await key(KEY_L,false);await key(KEY_W,false);step()
    check("native W plus L commits the paid cannon after modifiers are released",scene.sim.fighters[0].move=="overdrive" and scene.sim.fighters[0].meter==25)
    scene.theatre.begin("skill",1);scene.rhythm.trigger("skill",1)
    check("weaker skill cannot erase the cannon red charge or pacing profile",scene.theatre.mode=="overdrive" and scene.theatre.duration==1.45 and scene.rhythm.kind=="overdrive")
    var load_seen:=false;var palm_seen:=false;var beam_seen:=false;var hit:=false
    var before:int=scene.sim.fighters[1].health
    for i in 180:
        step()
        load_seen=load_seen or scene.fighters[0].motions.air_pose_name=="Cannon_Load"
        palm_seen=palm_seen or scene.fighters[0].motions.air_pose_name=="Cannon_DoublePalm"
        beam_seen=beam_seen or scene.effects.any(func(e:Dictionary)->bool:return e.kind=="cannon_blast")
        hit=hit or scene.sim.fighters[1].health<before
    check("real charge and two-palm release poses both render",load_seen and palm_seen)
    check("beam appears after actual cannon contact",beam_seen and hit)
    scene.reset_training();scene.sim.fighters[0].meter=74
    await key(KEY_W,true);await key(KEY_L,true);await key(KEY_L,false);await key(KEY_W,false);step()
    check("underfunded cannon tells the player the 75 cost",scene.hud.notice=="OVERDRIVE NEEDS 75" and scene.sim.fighters[0].meter==74)
    scene.reduced_effects=true;scene.reset_training();scene.sim.fighters[0].meter=100
    scene.pending.attack="overdrive";step()
    for i in 100:step()
    check("F2 cannon retains real damage without red camera staging",scene.sim.fighters[1].health<100 and not scene.rhythm.active() and scene.camera.environment==null and scene.backdrop.visible)
    scene.return_to_title()
    check("leaving the match clears cannon effects and profile",scene.effects.is_empty() and not scene.rhythm.active() and not scene.theatre.active())
    scene.queue_free();await process_frame;await process_frame
    var passed:=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open("res://../docs/evidence/charged-cannon/input.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"scope":"Native W/L input, real cost and contacts, procedural pose and effect state; software renderer, no human claim."},"  "))
    print("CANNON_INPUT ",passed,"/",checks.size());call_deferred("quit",0 if passed==checks.size() else 1)
