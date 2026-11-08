extends SceneTree
const Sim = preload("res://scripts/combat/fight_simulation.gd")
var checks: Array[Dictionary]=[]
func _initialize() -> void: call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed: push_error("POLISH FAIL: "+label)
func setup(training := false) -> RefCounted:
    var sim=Sim.new()
    sim.training=training
    sim.reset_round()
    sim.phase="fight"
    sim.ai_enabled=false
    sim.fighters[0].x=-0.65
    sim.fighters[1].x=0.65
    return sim
func run() -> void:
    var sim=setup(true)
    sim.remaining=0.01
    for i in 120: sim.tick()
    check("training has unlimited time",sim.remaining==0.01 and sim.phase=="fight")
    check("training starts with full energy",sim.fighters[0].meter==100 and sim.fighters[1].meter==100)
    sim.fighters[1].health=1
    sim.fighters[0].state="attack"
    sim.fighters[0].move="heavy"
    sim.fighters[0].frame=15
    sim.tick()
    check("lethal training hit does not finish a round",sim.fighters[1].health==1 and sim.phase=="fight" and sim.wins==[0,0])
    check("training remembers last combo damage",sim.last_combo_damage==18 and sim.last_combo_hits==1)
    for i in 160: sim.tick()
    check("settled training partner heals automatically",sim.fighters[1].health==100 and sim.fighters[1].guard==100)
    check("healing preserves last combo statistics",sim.last_combo_damage==18)
    sim.fighters[0].meter=0
    sim.tick()
    check("training restores special meter",sim.fighters[0].meter==100)
    sim.fighters[0].health=30
    sim.fighters[0].state="stun"
    sim.fighters[0].stun=200
    for i in 100: sim.tick()
    check("training does not heal in the middle of hitstun",sim.fighters[0].health==30)
    sim.reset_training()
    check("manual training reset restores positions and state",sim.phase=="fight" and sim.fighters[0].x==-3 and sim.fighters[1].x==3 and sim.fighters[0].health==100 and sim.fighters[0].meter==100)
    sim=setup(true)
    sim.partner_mode=1
    sim.fighters[1].guard=5
    sim.fighters[0].state="attack"
    sim.fighters[0].move="heavy"
    sim.fighters[0].frame=15
    sim.tick()
    check("guarding partner permits real guard-break practice",sim.events.any(func(e:Dictionary)->bool:return e.kind=="guard_break") and sim.fighters[1].health==100)
    check("guarding partner never auto-parries",not sim.events.any(func(e:Dictionary)->bool:return e.kind=="parry"))
    sim=setup(true)
    sim.partner_mode=2
    sim.tick()
    check("sparring partner attacks with AI while practice stays unlimited",sim.fighters[1].state=="attack" and sim.phase=="fight")
    var counts: Array[int]=[]
    for level in 3:
        sim=setup()
        sim.difficulty=level
        var count:=0
        for i in 200:
            sim.ai_tick=i
            if sim.ai_command().has("attack"): count+=1
        counts.append(count)
    check("difficulty changes deliberate attack frequency",counts[0]<counts[1] and counts[1]<counts[2])
    check("all AI levels avoid perfect parries",not sim.ai_command().get("allow_parry",true))
    sim=setup()
    sim.hitstop=2
    sim.tick({"jump":true})
    sim.tick()
    sim.tick()
    check("jump input buffered during hitstop survives until simulation resumes",sim.fighters[0].vy>0)
    sim=setup()
    var chased:=false
    var air_hit:=false
    for i in 55:
        var command: Dictionary={}
        if i==0: command={"attack":"heavy","up":true}
        if i==15: command={"jump":true}
        if i==25: command={"attack":"light"}
        sim.tick(command,{})
        for event in sim.events:
            if event.kind=="air_chase": chased=true
            if event.kind=="hit" and event.move=="jab" and sim.fighters[1].y>0.1: air_hit=true
    check("confirmed launcher can jump-cancel from a hitstop buffer",chased)
    check("launcher jump cancel produces a reachable air follow-up",air_hit and sim.last_combo_hits>=2)
    sim=setup()
    sim.fighters[1].x=7
    sim.tick({"attack":"heavy","up":true})
    for i in 25: sim.tick({"jump":true} if i==15 else {})
    check("whiffed launcher cannot jump-cancel its recovery",sim.fighters[0].y==0)
    sim=setup()
    sim.fighters[0].y=1.3
    sim.fighters[1].y=1.3
    sim.fighters[1].juggle=2
    sim.fighters[0].state="attack"
    sim.fighters[0].move="jab"
    sim.fighters[0].frame=4
    sim.tick()
    check("third airborne hit sends the target down",sim.fighters[1].juggle==3 and sim.fighters[1].vy<0)
    var hp: int=sim.fighters[1].health
    sim.hitstop=0
    sim.fighters[0].connected=false
    sim.fighters[0].frame=4
    sim.tick()
    check("airborne juggle cap prevents an endless relaunch",sim.fighters[1].health==hp)
    sim.fighters[1].y=0.001
    sim.fighters[1].vy=-1
    sim.tick()
    check("landing clears the air-hit budget",sim.fighters[1].juggle==0)
    var prefs=preload("res://scripts/combat/fight_preferences.gd").new()
    var path: String="user://qa_afterhours_options.cfg"
    DirAccess.remove_absolute(path)
    check("missing preferences use safe defaults",prefs.read_options(path).difficulty==1 and not prefs.read_options(path).muted)
    prefs.write_options(path,{"difficulty":8,"partner_mode":-2,"muted":true,"music_muted":true})
    var saved: Dictionary=prefs.read_options(path)
    check("preferences persist validated values and clamp ranges",saved.difficulty==2 and saved.partner_mode==0 and saved.muted and saved.music_muted)
    var file:=ConfigFile.new()
    file.set_value("options","muted","wrong type")
    file.set_value("options","difficulty","wrong type")
    file.save(path)
    check("malformed preference types fall back safely",not prefs.read_options(path).muted and prefs.read_options(path).difficulty==1)
    DirAccess.remove_absolute(path)
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=path
    root.add_child(scene)
    scene.set_physics_process(false)
    scene.start_match(true)
    check("practice menu enters an unlimited ready-to-train session",scene.practice and scene.sim.training and scene.sim.phase=="fight")
    check("expanded menu uses a bounded scroll container",scene.hud.menu_scroll.custom_minimum_size.y<=560)
    for i in 10: scene._record_training_input(KEY_J)
    check("training input history stays bounded",scene.input_history.size()==6)
    var key:=InputEventKey.new()
    key.pressed=true
    key.keycode=KEY_F5
    scene.sim.fighters[0].health=20
    scene._unhandled_key_input(key)
    check("F5 resets practice and clears input history",scene.sim.fighters[0].health==100 and scene.input_history.is_empty())
    key.keycode=KEY_F7
    scene._unhandled_key_input(key)
    check("F7 cycles practice opponent and restores spacing",scene.sim.partner_mode==1 and scene.sim.fighters[0].x==-3)
    scene.set_difficulty(2)
    scene.audio.music_muted=true
    scene.reduced_effects=true
    scene.save_options()
    scene.return_to_title()
    check("main menu returns without reloading the world",scene.screen=="title" and scene.audio.music_muted)
    scene.start_match(false)
    check("leaving training restores normal round rules",not scene.sim.training and scene.sim.ai_enabled and scene.sim.phase=="ready")
    scene.queue_free()
    await process_frame
    var restored=preload("res://scenes/combat/street_fight.tscn").instantiate()
    restored.preferences_path=path
    root.add_child(restored)
    restored.set_physics_process(false)
    check("new session restores difficulty, music and accessibility choices",restored.sim.difficulty==2 and restored.audio.music_muted and restored.reduced_effects and restored.sim.partner_mode==1)
    restored.queue_free()
    await process_frame
    await create_timer(0.1).timeout
    DirAccess.remove_absolute(path)
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var output:=FileAccess.open("res://../docs/evidence/combat-polish/verification.json",FileAccess.WRITE)
    output.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"method":"Godot 4.6.3 headless deterministic gameplay, preferences and scene integration"},"  "))
    output.close()
    print("COMBAT_POLISH_CHECKS ",checks.size()-failed,"/",checks.size())
    call_deferred("quit",0 if failed==0 else 1)
