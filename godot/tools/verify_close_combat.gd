extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("CLOSE COMBAT FAIL: "+label)
func fresh() -> RefCounted:
    var sim:=Sim.new()
    sim.ai_enabled=false
    sim.phase="fight"
    sim.fighters[0].x=-.45
    sim.fighters[1].x=.45
    return sim
func wall(meter: float) -> RefCounted:
    var sim=fresh()
    sim.fighters[0].x=5
    var f: Dictionary=sim.fighters[1]
    f.x=8.19
    f.y=.4
    f.state="stun"
    f.stun=30
    f.vx=10
    f.vy=0
    f.meter=meter
    return sim
func run() -> void:
    var sim=fresh()
    sim.tick({"attack":"grab"},{"guard":true})
    check("throw has clear startup and cooldown",sim.fighters[0].move=="grab" and sim.fighters[0].frame==0 and sim.fighters[0].throw_cd==60)
    for i in 11:sim.tick({}, {"guard":true})
    check("throw defeats even a fresh guard without guard damage",sim.fighters[1].health==88 and sim.fighters[1].guard==100 and sim.fighters[1].state=="stun")
    check("throw creates lift and a held impact",sim.fighters[1].vy>4.5 and sim.hitstop==9 and sim.events.any(func(e:Dictionary)->bool:return e.kind=="hit" and e.move=="grab"))
    check("throw builds shared pressure once",sim.exchange.pressure==10)
    for i in 50:sim.tick()
    check("one throw cannot damage repeatedly",sim.fighters[1].health==88)
    sim=fresh()
    sim.tick({"attack":"grab","guard":true})
    check("throwing from guard drops protection during startup",sim.fighters[0].state=="attack" and not sim.fighters[0].guarding)
    sim=fresh()
    sim.fighters[0].y=1
    sim.tick({"attack":"grab"})
    check("airborne attackers cannot start a throw",sim.fighters[0].move=="" and sim.fighters[0].throw_cd==0)
    sim=fresh()
    sim.fighters[1].y=1.2
    sim.tick({"attack":"grab"})
    for i in 14:sim.tick()
    check("airborne target cannot be thrown",sim.fighters[1].health==100)
    sim=fresh()
    sim.fighters[1].x=3
    sim.tick({"attack":"grab"})
    for i in 40:sim.tick()
    check("out of range throw whiffs with a punishable cooldown",sim.fighters[1].health==100 and sim.fighters[0].throw_cd>0)
    sim.tick({"attack":"grab"})
    check("throw cooldown rejects immediate retry",sim.fighters[0].state=="idle" and sim.fighters[0].buffer=="")
    sim=fresh()
    sim.tick({"attack":"grab"})
    for i in 10:sim.tick()
    sim.tick({}, {"attack":"grab"})
    check("defender can break a throw with a late G",sim.fighters[0].health==100 and sim.fighters[1].health==100 and sim.events.filter(func(e:Dictionary)->bool:return e.kind=="throw_tech").size()==1)
    check("throw break separates and releases a small pressure gain",sim.fighters[0].vx<0 and sim.fighters[1].vx>0 and sim.exchange.pressure==12 and sim.hitstop==6)
    sim=fresh()
    for side in 2:
        sim.fighters[side].state="attack"
        sim.fighters[side].move="grab"
        sim.fighters[side].frame=10
    sim.tick()
    check("simultaneous throws break exactly once",sim.events.filter(func(e:Dictionary)->bool:return e.kind=="throw_tech").size()==1 and sim.exchange.pressure==12 and sim.fighters[0].health==100 and sim.fighters[1].health==100)
    for throw_side in 2:
        sim=fresh()
        for side in 2:
            sim.fighters[side].state="attack"
            sim.fighters[side].move="grab" if side==throw_side else "jab"
            sim.fighters[side].frame=10 if side==throw_side else 4
        sim.tick()
        check("active jab interrupts throw fairly on side %d"%throw_side,sim.fighters[throw_side].health==93 and sim.fighters[1-throw_side].health==100)
    sim=fresh()
    sim.tick({"attack":"grab"},{"jump":true})
    for i in 14:sim.tick()
    check("jumping escapes a throw",sim.fighters[1].health==100 and sim.fighters[1].y>.1)
    sim=fresh()
    sim.tick({"attack":"grab"},{"dash":true,"axis":1})
    for i in 14:sim.tick()
    check("dodge escapes throw range",sim.fighters[1].health==100 and sim.fighters[1].x>2)
    sim=fresh()
    sim.fighters[1].state="stun"
    sim.fighters[1].stun=40
    sim.tick({"attack":"grab"})
    for i in 14:sim.tick()
    check("throws cannot extend a helpless stun combo",sim.fighters[1].health==100)
    sim=wall(30)
    sim.tick()
    check("heavy edge impact bounces once without free damage",sim.events.any(func(e:Dictionary)->bool:return e.kind=="wall_bounce") and sim.fighters[1].vx<0 and sim.fighters[1].health==100 and sim.fighters[1].wall_bounces==1)
    check("edge impact opens a twelve tick recovery opportunity",sim.fighters[1].wall_tech_window==12)
    sim.fighters[1].vx=10
    sim.tick()
    check("same launch cannot bounce repeatedly",not sim.events.any(func(e:Dictionary)->bool:return e.kind=="wall_bounce"))
    sim=wall(30)
    sim.tick({}, {"dash":true})
    check("prebuffered recovery spends exactly twenty energy",sim.events.any(func(e:Dictionary)->bool:return e.kind=="wall_tech") and sim.fighters[1].meter==10 and sim.fighters[1].state=="dash")
    check("recovery grants a bounded jump away and invulnerability",sim.fighters[1].vx<0 and sim.fighters[1].vy>6 and sim.fighters[1].invuln==10 and sim.fighters[1].wall_tech_window==0)
    sim=wall(45)
    sim.fighters[1].juggle=3
    sim.tick()
    for i in 5:sim.tick()
    sim.tick({}, {"dash":true})
    check("late recovery remains available inside the window",sim.events.any(func(e:Dictionary)->bool:return e.kind=="wall_tech") and sim.fighters[1].meter==25)
    check("recovery clears old juggle and buffered commands",sim.fighters[1].juggle==0 and sim.fighters[1].buffer=="" and sim.fighters[1].jump_buffer==0)
    var old_meter: float=sim.fighters[1].meter
    sim.tick({}, {"dash":true})
    check("recovery cannot charge energy twice",sim.fighters[1].meter==old_meter)
    sim=wall(19)
    sim.tick({}, {"dash":true})
    check("insufficient energy keeps the bounce without negative resource",sim.fighters[1].meter==19 and sim.fighters[1].state=="stun" and sim.events.any(func(e:Dictionary)->bool:return e.kind=="wall_bounce"))
    sim=wall(40)
    sim.tick()
    for i in 13:sim.tick()
    sim.tick({}, {"dash":true})
    check("recovery after the deadline is rejected",not sim.events.any(func(e:Dictionary)->bool:return e.kind=="wall_tech") and sim.fighters[1].meter==40)
    sim=wall(30)
    sim.fighters[1].vx=4
    sim.tick()
    check("light push does not trigger dramatic edge bounce",not sim.events.any(func(e:Dictionary)->bool:return e.kind=="wall_bounce"))
    sim.reset_round()
    check("round reset clears all throw and recovery state",sim.fighters.all(func(f:Dictionary)->bool:return f.throw_cd==0 and f.tech_window==0 and f.wall_bounces==0 and f.wall_tech_window==0 and f.wall_tech_buffer==0))
    sim=fresh()
    sim.fighters[0].x=0
    sim.fighters[0].guarding=true
    sim.fighters[1].x=1.35
    check("AI closes distance to challenge a passive guard with throws",sim.ai_command().axis<0)
    sim.fighters[1].x=1.0
    sim.ai_tick=25
    check("AI chooses an in-range throw against a passive guard",sim.ai_command().get("attack","")=="grab")
    for level in 3:
        var feints:=0
        var intentions_fixed:=true
        for serial in 12:
            sim=fresh()
            sim.ai_enabled=true
            sim.difficulty=level
            sim.exchange.pressure=60
            sim.exchange.serial=serial
            sim.fighters[0].state="attack"
            sim.fighters[0].move="heavy"
            sim.fighters[0].frame=15
            sim.tick()
            if sim.exchange.clash.cue!=sim.exchange.clash.intent:feints+=1
            var actual: String=sim.exchange.clash.intent
            sim.tick({"clash_choice":"press"})
            for tick in 18:sim.tick()
            intentions_fixed=intentions_fixed and sim.exchange.clash.intent==actual
        check("all twelve preselected intentions remain fixed at difficulty %d"%level,intentions_fixed)
        check("difficulty %d has bounded preselected feint frequency"%level,feints==[0,3,6][level])
    sim=fresh()
    sim.training=true
    sim.partner_mode=2
    sim.difficulty=2
    sim.exchange.pressure=60
    sim.exchange.serial=1
    sim.fighters[0].state="attack"
    sim.fighters[0].move="heavy"
    sim.fighters[0].frame=15
    sim.tick()
    check("dojo always shows the true stance even on challenging difficulty",sim.exchange.clash.cue==sim.exchange.clash.intent)
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    scene.start_match(true)
    var event:=InputEventKey.new()
    event.pressed=true
    event.keycode=KEY_G
    event.physical_keycode=KEY_G
    scene._unhandled_key_input(event)
    check("G routes to the throw command",scene.pending.get("attack","")=="grab")
    scene.pending.clear()
    scene.sim.fighters[0].state="attack"
    scene.sim.fighters[0].move="grab"
    scene.sim.fighters[0].frame=11
    for i in 10:scene._present(1.0/60)
    var skeleton: Skeleton3D=scene.fighters[0].skeleton
    var hands_forward:=true
    for side in ["Left","Right"]:
        var arm:=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_"+side+"Arm")).origin)
        var hand:=skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_"+side+"Hand")).origin)
        hands_forward=hands_forward and hand.x>arm.x+.1
    check("throw pose extends both hands toward the opponent",hands_forward)
    scene.queue_free()
    await process_frame
    await create_timer(.15).timeout
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/extended-polish/close-combat.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed},"  "))
    print("CLOSE_COMBAT_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
