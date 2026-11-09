extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Counter=preload("res://scripts/combat/air_counter.gd")
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, value: bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("AIR COUNTER FAIL: "+label)
func fresh(attacker:=1, move:="air_finisher", frame_offset:=-2) -> RefCounted:
    var s:=Sim.new()
    s.training=true;s.practice_scenario="air";s.phase="fight";s.ai_enabled=false
    for i in 2:
        var f: Dictionary=s.fighters[i]
        f.x=-.65 if i==0 else .65;f.y=1.4;f.meter=100.0
        f.air.phase="apex"
    s.fighters[attacker].state="attack"
    s.fighters[attacker].move=move
    s.fighters[attacker].frame=Sim.MOVES[move].startup+frame_offset
    return s
func begin(s: RefCounted, defender:=0) -> void:
    var inputs:=[{},{}]
    inputs[defender]={"guard_pressed":true}
    s.tick(inputs[0],inputs[1])
    for i in 3:
        if s.air_counter.active():return
        s.tick()
func finish(s: RefCounted, choice: String, defender_command: Dictionary={}) -> void:
    var inputs:=[{},{}]
    inputs[s.air_counter.owner]={"air_choice":choice}
    s.tick(inputs[0],inputs[1])
    for i in 100:
        if not s.air_counter.active():return
        inputs=[{},{}]
        if s.air_counter.phase=="windup":inputs[1-s.air_counter.owner]=defender_command
        s.tick(inputs[0],inputs[1])
func run() -> void:
    for warning in ["shadowed_variable_base_class","shadowed_global_identifier","integer_division"]:ProjectSettings.set_setting("debug/gdscript/warnings/"+warning,2)
    for name in ["air_counter","aerial_motion","aerial_poses","fight_simulation","fight_session","fight_hud","fight_vfx"]:
        var script:=GDScript.new();script.source_code=FileAccess.get_file_as_string("res://scripts/combat/"+name+".gd")
        check("strict compile "+name,script.reload()==OK)
    for attacker in 2:
        for move in ["air_finisher","meteor"]:
            var defender:=1-attacker
            var s=fresh(attacker,move)
            s.fighters[defender].state="stun";s.fighters[defender].stun=30;s.fighters[defender].air.combo_left=100
            begin(s,defender)
            var label: String=str(attacker)+"/"+move
            check("air parry hijacks the real contact "+label,s.air_counter.active() and s.air_counter.owner==defender)
            check("one attempt costs twenty five "+label,s.fighters[defender].meter==75 and s.fighters[defender].air.parry_used)
            check("success does not award automatic damage "+label,s.fighters[0].health==100 and s.fighters[1].health==100 and s.hitstop==0)
            var positions:=[Vector2(s.fighters[0].x,s.fighters[0].y),Vector2(s.fighters[1].x,s.fighters[1].y)]
            s.tick()
            check("contact hold freezes both logical bodies "+label,positions==[Vector2(s.fighters[0].x,s.fighters[0].y),Vector2(s.fighters[1].x,s.fighters[1].y)])
            finish(s,"kick")
            check("committed kick deals the configured hold duration once "+label,s.air_counter.reason=="hit" and s.fighters[attacker].health==82 and s.fighters[defender].health==100)
            var health: int=s.fighters[attacker].health
            for i in 15:s.tick()
            check("kick cannot double hit after exit "+label,s.fighters[attacker].health==health)
    var s=fresh()
    begin(s)
    s.tick({"air_choice":"kick"})
    s.tick({"air_choice":"escape"})
    check("first valid commitment locks",s.air_counter.choice=="kick")
    var hold_left: int=Counter.HOLD-s.air_counter.age
    for i in hold_left-1:s.tick()
    check("hold remains active until the configured hold duration",s.air_counter.phase=="hold")
    s.tick()
    check("hold ends at the configured duration without another hitstop",s.air_counter.phase=="windup" and s.air_counter.age==0 and s.hitstop==0)
    for i in Counter.WINDUP-1:s.tick()
    check("kick has configured visible startup ticks",s.fighters[1].health==100 and s.air_counter.phase=="windup")
    s.tick()
    check("final live windup tick resolves contact",s.fighters[1].health==82 and not s.air_counter.active())
    s=fresh();begin(s);finish(s,"escape")
    check("escape transfers into a real safe dash",s.air_counter.reason=="escape" and s.fighters[0].state=="dash" and s.fighters[0].invuln>0 and s.fighters[1].health==100)
    s=fresh();begin(s)
    for i in Counter.HOLD:s.tick()
    check("no choice safely disperses instead of auto attacking",s.air_counter.reason=="escape" and s.fighters[1].health==100)
    s=fresh();begin(s);finish(s,"kick",{"dash":true})
    check("loser can dodge the new counter instead of guaranteed damage",s.air_counter.reason=="whiff" and s.fighters[1].health==100)
    s=fresh(1,"meteor",-14)
    for i in 18:s.tick({"guard_pressed":true})
    check("early repeated parries cannot refresh the window",not s.air_counter.active() and s.fighters[0].air.parry_used and s.fighters[0].health==86 and s.fighters[0].meter<100)
    s=fresh();s.fighters[0].meter=24
    begin(s)
    check("insufficient energy gives no negative meter or free counter",not s.air_counter.active() and not s.fighters[0].air.parry_used and s.fighters[0].meter>=24)
    s=fresh()
    for i in 4:s.tick({"guard":true,"guard_pressed":false})
    check("holding guard is not an automatic aerial parry",not s.air_counter.active() and not s.fighters[0].air.parry_used and s.fighters[0].health<100)
    s=fresh();s.fighters[0].x=-6
    begin(s)
    check("distant attempt is not consumed",not s.air_counter.active() and not s.fighters[0].air.parry_used and s.fighters[0].meter==100)
    s=fresh();s.fighters[0].air.parry_used=true
    begin(s)
    check("one parry attempt per flight",not s.air_counter.active() and s.fighters[0].meter>=100)
    s=fresh();s.training=false
    begin(s)
    check("formal fight cannot start the experimental counter",not s.air_counter.active())
    s=fresh();begin(s);s.air_counter.elapsed=89;s.tick()
    check("ninety tick failsafe ends the hold",not s.air_counter.active() and s.air_counter.reason=="timeout")
    s=fresh();begin(s);s.reset_training()
    check("training reset clears counter choice and windows",not s.air_counter.active() and s.air_counter.choice=="" and s.fighters[0].air.parry_window==0)
    s=fresh();s.configure_air_lesson()
    var positions: Array=s.fighters.duplicate(true)
    for i in 240:s.tick()
    check("lesson read phase is indefinite and physically stable",s.air_lesson_stage=="read" and s.fighters==positions)
    s.tick({"lesson_start":true})
    check("lesson begins only on explicit start",s.air_lesson_stage=="attack" and s.fighters[1].move=="air_finisher")
    for i in 8:s.tick()
    begin(s)
    check("scripted lesson can be genuinely parried",s.air_counter.active())
    finish(s,"escape")
    check("lesson resolves to review",s.air_lesson_stage=="review")
    s.tick({"lesson_start":true})
    check("review retry restores resources then starts a fresh attack",s.air_lesson_stage=="attack" and s.fighters[0].health==100 and s.fighters[0].meter==100 and not s.fighters[0].air.parry_used)
    s=fresh(0,"air_finisher",-5)
    s.partner_mode=2;s.difficulty=2
    s.fighters[1].state="stun";s.fighters[1].stun=30
    for i in 7:
        s.tick()
        if s.air_counter.active():break
    check("sparring AI can parry a public finisher tell",s.air_counter.active() and s.air_counter.owner==1)
    for i in 4:s.tick({"air_choice":"escape"})
    check("AI choice commits on its own schedule",s.air_counter.choice=="kick")
    while s.air_counter.active():s.tick({"dash":true})
    check("player can evade an AI reversal",s.fighters[0].health==100 and s.air_counter.reason=="whiff")
    var a=fresh();var b=fresh()
    var rng:=RandomNumberGenerator.new();rng.seed=117911
    var deterministic:=true
    var starts:=0
    for tick in 25000:
        var commands:=[{},{}]
        for side in 2:
            commands[side]={"guard_pressed":rng.randf()<.15,"axis":rng.randi_range(-1,1),"attack":"light" if rng.randf()<.65 else "heavy","down":rng.randf()<.2,"air_choice":"kick" if rng.randf()<.6 else "escape","dash":rng.randf()<.08}
        if tick%1000==0:commands[0]={"guard_pressed":true}
        elif tick%1000==1:commands[0]={}
        a.tick(commands[0],commands[1]);b.tick(commands[0],commands[1])
        for e in a.events:
            if e.kind=="air_counter_start":starts+=1
        if a.fighters!=b.fighters or a.events!=b.events or a.air_counter.phase!=b.air_counter.phase or a.air_counter.choice!=b.air_counter.choice:deterministic=false
        if tick%1000==999:a=fresh();b=fresh()
    check("twenty five thousand counter ticks remain deterministic",deterministic)
    check("deterministic replay exercises real reversals",starts>=25)
    var folder:="res://../docs/evidence/air-reversal"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open(folder+"/rules.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"replay_ticks":25000,"replay_counter_starts":starts},"  "))
    print("AIR_COUNTER_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(1 if failed else 0)
