extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok})
    print("DOUBLE_JUMP ",label," ",ok)
    if not ok:push_error(label)
func fresh(character:=0) -> RefCounted:
    var s=Sim.new()
    s.arcade_enabled=true;s.last_service_enabled=true;s.character_choices=[character,(character+1)%4]
    s.reset_round();s.phase="fight";s.ai_enabled=false
    s.fighters[0].x=-5;s.fighters[1].x=5
    return s
func event_count(s:RefCounted,kind:String,side:int) -> int:
    return s.events.filter(func(e:Dictionary)->bool:return e.kind==kind and e.get("target",-1)==side).size()
func step(s:RefCounted,side:int,command:Dictionary={}) -> void:
    s.tick(command if side==0 else {},command if side==1 else {})
func takeoff(s:RefCounted,side:int) -> void:
    step(s,side,{"jump":true})
    for i in 8:step(s,side)
func run() -> void:
    for character in 4:
        for side in 2:
            var s=fresh(character);var f:Dictionary=s.fighters[side]
            takeoff(s,side)
            check("ground press cannot also spend air jump %d/%d"%[character,side],f.y>0 and not f.air.double_used)
            # Save the scarce budgets to detect accidental refreshes.
            f.air.stall_left=3;f.air.chase_used=true;f.air.parry_used=true;f.air.fast_used=true
            var meter:float=f.meter
            step(s,side,{"jump":true,"axis":-float(f.face)})
            check("second impulse with steering %d/%d"%[character,side],event_count(s,"double_jump",side)==1 and f.vy>9 and f.vx*f.face<0)
            check("no resource refill %d/%d"%[character,side],f.air.stall_left==3 and f.air.chase_used and f.air.parry_used and f.air.fast_used and f.meter>=meter)
            var doubles:=1;var peak:float=f.y
            for i in 6:
                step(s,side,{"jump":true});doubles+=event_count(s,"double_jump",side);peak=maxf(peak,f.y)
            check("third press rejected %d/%d"%[character,side],doubles==1)
            for i in 180:
                step(s,side);peak=maxf(peak,f.y)
            check("bounded flight returns to ground %d/%d"%[character,side],f.y==0 and f.state=="idle" and peak<5.0 and not f.air.double_used)
            takeoff(s,side);step(s,side,{"jump":true})
            check("landing restores exactly one air jump %d/%d"%[character,side],event_count(s,"double_jump",side)==1)
    var s=fresh();var f:Dictionary=s.fighters[0]
    takeoff(s,0)
    for i in 25:s.tick()
    check("fixture is falling",f.vy<0)
    s.tick({"jump":true})
    check("falling jump reverses vertical motion",f.vy>9 and event_count(s,"double_jump",0)==1)
    s=fresh();f=s.fighters[0];takeoff(s,0)
    s.hitstop=5
    s.tick({"jump":true})
    var at:float=f.y
    for i in 4:s.tick()
    check("hitstop preserves jump without moving",f.y==at and f.jump_buffer==8 and not f.air.double_used)
    s.tick()
    check("buffer fires once after hitstop",event_count(s,"double_jump",0)==1 and f.jump_buffer==0)
    for state in ["stun","blockstun","attack","chase"]:
        s=fresh();f=s.fighters[0];takeoff(s,0)
        f.state=state;f.stun=25;f.move="air_jab";f.frame=0
        if state=="chase":f.air.points=[Vector2(-5,1),Vector2(-5,2),Vector2(-4,2),Vector2(-4,1)]
        s.tick({"jump":true})
        check("Space cannot cancel "+state,event_count(s,"double_jump",0)==0 and not f.air.double_used)
    s=fresh();f=s.fighters[0];takeoff(s,0)
    s.tick({"down_pressed":true})
    check("fast fall begins",f.air.fast)
    s.tick({"jump":true})
    check("air jump brakes fast fall without rearming it",f.vy>0 and not f.air.fast and f.air.fast_used)
    s=fresh();f=s.fighters[0]
    f.y=.04;f.vy=-20;f.air.double_used=true
    s.tick({"jump":true})
    check("hard landing records the early input",f.state=="landing" and f.jump_buffer>0)
    var hops:=0
    for i in 16:
        s.tick();hops+=event_count(s,"jump",0)
    check("early Space survives hard landing recovery",hops==1 and f.y>0 and not f.air.double_used)
    s.reset_round()
    check("restart clears air jump state",s.fighters.all(func(p:Dictionary)->bool:return not p.air.double_used and p.jump_buffer==0))
    # Replays exercise both sides, attacks, dashes, fast falls and jumps.
    var twin=fresh();s=fresh();var rng=RandomNumberGenerator.new();rng.seed=9210
    var stable:=true
    for i in 6000:
        var commands:Array=[{},{}]
        for side in 2:
            commands[side]={"axis":rng.randi_range(-1,1)}
            if i%7==0:commands[side]["jump"]=true
            if i%11==0:commands[side]["attack"]="light"
            if i%23==0:commands[side]["down_pressed"]=true
        s.tick(commands[0],commands[1]);twin.tick(commands[0],commands[1])
        if s.fighters!=twin.fighters or s.events!=twin.events:stable=false
        if i%500==499:s=fresh();twin=fresh()
    check("6000 mixed ticks replay deterministically",stable)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var path:="res://../docs/evidence/double-jump/"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
    var file=FileAccess.open(path+"rules.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed},"  "))
    print("DOUBLE_JUMP_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(1 if failed else 0)
