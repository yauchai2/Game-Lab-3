extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Rally=preload("res://scripts/combat/kinetic_rally.gd")
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, value: bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("KINETIC FAIL: "+label)
func fresh(side:=0) -> RefCounted:
    var sim:=Sim.new()
    sim.training=true
    sim.rally_enabled=true
    sim.ai_enabled=false
    sim.partner_mode=0
    sim.phase="fight"
    sim.fighters[0].x=-.65
    sim.fighters[1].x=.65
    sim.fighters[side].state="attack"
    sim.fighters[side].move="jab"
    sim.fighters[side].frame=4
    var commands:=[{},{}]
    commands[1-side]={"guard":true,"guard_pressed":true}
    sim.tick(commands[0],commands[1])
    return sim
func choose(sim: RefCounted) -> void:
    var commands:=[{},{}]
    commands[sim.rally.owner]={"attack":"light"}
    sim.tick(commands[0],commands[1])
func step_to(sim: RefCounted, phase: String) -> void:
    for i in 100:
        if sim.rally.phase==phase or not sim.rally.active():return
        sim.tick()
func parry_return(sim: RefCounted) -> void:
    choose(sim)
    step_to(sim,"windup")
    for i in Rally.WINDUP:
        var commands:=[{},{}]
        # New press precisely two ticks before contact. All tiers accept it.
        commands[1-sim.rally.owner]={"guard":i>=8,"guard_pressed":i==8}
        sim.tick(commands[0],commands[1])
func run() -> void:
    for category in ["shadowed_variable_base_class","shadowed_global_identifier","integer_division"]:
        ProjectSettings.set_setting("debug/gdscript/warnings/"+category,2)
    for path in ["kinetic_rally","fight_spectacle","fight_simulation","fight_session","fighter_visual","fight_vfx","combat_motions","fight_hud","fight_audio","ui/ui_text"]:
        var script:=GDScript.new()
        script.source_code=FileAccess.get_file_as_string("res://scripts/combat/"+path+".gd")
        check("strict compile "+path,script.reload()==OK)
    for side in 2:
        var sim=fresh(side)
        check("initial parry opens for defender "+str(side),sim.rally.active() and sim.rally.owner==1-side and sim.rally.tier==1 and sim.hitstop==0)
        check("initial parry does not damage "+str(side),sim.fighters[0].health==100 and sim.fighters[1].health==100 and sim.exchange.pressure==16)
        check("new mode never opens legacy menu "+str(side),not sim.exchange.active())
        var before: float=sim.remaining
        for level in range(1,5):
            check("tier progression "+str(side)+"/"+str(level),sim.rally.tier==level)
            var owner: int=sim.rally.owner
            parry_return(sim)
            if level<4:check("transfer "+str(side)+"/"+str(level),sim.rally.active() and sim.rally.owner==1-owner)
        check("fifth successful parry vents safely "+str(side),not sim.rally.active() and sim.rally.reason=="limit" and sim.fighters[0].health==100 and sim.fighters[1].health==100)
        check("rally pauses timer "+str(side),sim.remaining==before)
        check("end flushes attack and pressure "+str(side),sim.exchange.pressure==0 and sim.fighters[0].buffer=="" and sim.fighters[1].buffer=="")
    var sim=fresh()
    for i in 12:sim.tick()
    check("no commitment dissipates",not sim.rally.active() and sim.rally.reason=="no_input")
    sim=fresh()
    var owner: int=sim.rally.owner
    choose(sim)
    step_to(sim,"active")
    check("counter cashes out once",not sim.rally.active() and sim.rally.reason=="hit" and sim.fighters[1-owner].health==88)
    var hp: int=sim.fighters[1-owner].health
    for i in 12:sim.tick()
    check("no second ordinary damage after cashout",sim.fighters[1-owner].health==hp)
    sim=fresh()
    owner=sim.rally.owner
    choose(sim)
    step_to(sim,"windup")
    for i in 10:
        var commands:=[{},{}]
        commands[1-owner]={"guard":true,"guard_pressed":false}
        sim.tick(commands[0],commands[1])
    check("held guard is block not auto parry",not sim.rally.active() and sim.rally.reason=="blocked" and sim.fighters[1-owner].health==100)
    sim=fresh()
    choose(sim)
    step_to(sim,"windup")
    var defender: int=1-sim.rally.owner
    for i in 10:
        var commands:=[{},{}]
        commands[defender]={"guard":true,"guard_pressed":true}
        sim.tick(commands[0],commands[1])
    check("spamming early fresh presses cannot extend window",not sim.rally.active() and sim.rally.reason=="blocked")
    for escape in ["dash","jump","distance"]:
        sim=fresh()
        choose(sim)
        step_to(sim,"windup")
        defender=1-sim.rally.owner
        if escape=="distance":sim.fighters[defender].x=-6 if defender==0 else 6
        for i in 16:
            var commands:=[{},{}]
            if i==0:
                if escape=="dash":commands[defender]={"dash":true,"axis":-sim.fighters[defender].face}
                elif escape=="jump":commands[defender]={"jump":true}
            sim.tick(commands[0],commands[1])
        if escape=="jump":check("fast counter can catch a jump startup",not sim.rally.active() and sim.fighters[defender].health==88 and sim.fighters[defender].y>0)
        else:check("escape has real geometry "+escape,not sim.rally.active() and sim.fighters[defender].health==100)
    for level in range(1,5):
        var r:=Rally.new()
        r.begin(0)
        r.tier=level
        for i in r.HOLDS[level-1]-1:r.tick([{"attack":"light"},{}])
        check("hold exact before "+str(level),r.phase=="compress")
        r.tick([{},{}])
        check("hold exact after "+str(level),r.phase=="windup")
        r.elapsed=299
        r.tick([{},{}])
        check("absolute five second cap "+str(level),not r.active() and r.reason=="timeout")
    sim=Sim.new()
    sim.phase="fight"
    sim.training=true
    sim.rally_enabled=true
    sim.ai_enabled=false
    sim.fighters[0].x=-.65
    sim.fighters[1].x=.65
    sim.fighters[1].state="attack"
    sim.fighters[1].move="jab"
    sim.fighters[1].frame=4
    sim.tick({"guard":true,"guard_pressed":false},{})
    check("held guard without a fresh native edge cannot open rally",not sim.rally.active())
    sim=fresh()
    sim.reset_training()
    check("reset exits rally experiment",not sim.rally_enabled and not sim.rally.active() and not sim.rally_drill)
    sim=fresh()
    sim.training=false
    sim.rally.reset()
    sim.exchange.cooldown=0
    sim.fighters[1].parry_cd=0
    sim.fighters[0].state="attack"
    sim.fighters[0].move="jab"
    sim.fighters[0].frame=4
    sim.fighters[1].state="idle"
    sim.tick({}, {"guard":true})
    check("formal fight cannot start experimental rally",not sim.rally.active())
    # Determinism covers ordinary play, fresh inputs, resets and both parrying slots.
    var a:=Sim.new()
    var b:=Sim.new()
    for item in [a,b]:
        item.ai_enabled=false
        item.training=true
        item.phase="fight"
        item.rally_enabled=true
        item.fighters[0].x=-.65
        item.fighters[1].x=.65
    var rng:=RandomNumberGenerator.new()
    rng.seed=6109
    var deterministic:=true
    var rally_contacts:=0
    for item in [a,b]:
        item.fighters[1].state="attack"
        item.fighters[1].move="jab"
        item.fighters[1].frame=4
    for tick in 25000:
        var commands:=[{},{}]
        for side in 2:
            commands[side]={"axis":rng.randi_range(-1,1),"guard":rng.randf()<.18,"attack":"light" if rng.randf()<.7 else "heavy"} if tick%7==0 else {}
        if tick==0:commands=[{"guard":true,"guard_pressed":true},{}]
        a.tick(commands[0],commands[1]);b.tick(commands[0],commands[1])
        for event in a.events:
            if event.kind=="rally_contact":rally_contacts+=1
        if a.fighters!=b.fighters or a.events!=b.events or a.rally.phase!=b.rally.phase or a.rally.elapsed!=b.rally.elapsed:deterministic=false
        if tick%1000==999:
            for item in [a,b]:
                item.reset_training()
                item.rally_enabled=true
    check("25000 tick deterministic mixed replay",deterministic and rally_contacts>0)
    var folder:="res://../docs/evidence/kinetic-overdrive"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    var output:=FileAccess.open(folder+"/rules.json",FileAccess.WRITE)
    output.store_string(JSON.stringify({"checks":checks,"passed":checks.filter(func(c:Dictionary)->bool:return c.passed).size(),"total":checks.size(),"replay_ticks":25000,"replay_rally_contacts":rally_contacts},"  "))
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    print("KINETIC_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(1 if failed else 0)
