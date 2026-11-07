extends SceneTree
const Sim = preload("res://scripts/combat/fight_simulation.gd")
var checks: Array[Dictionary] = []
func _initialize() -> void:
    call_deferred("run")
func check(label: String, condition: bool) -> void:
    checks.append({"name":label,"passed":condition})
    if not condition:
        push_error("FAIL: "+label)
func setup() -> RefCounted:
    var sim := Sim.new()
    sim.phase = "fight"
    sim.ai_enabled = false
    sim.fighters[0].x = -0.65
    sim.fighters[1].x = 0.65
    return sim
func run() -> void:
    var sim := Sim.new()
    for i in 72: sim.tick()
    check("ready transitions into fight after 72 ticks",sim.phase=="fight")
    sim = setup()
    sim.tick({"attack":"light"})
    for i in 4: sim.tick()
    check("jab startup cannot deal early damage",sim.fighters[1].health==100)
    sim.tick()
    check("jab deals damage on its active frame",sim.fighters[1].health==93 and sim.hitstop==5)
    var x: float = sim.fighters[1].x
    var timer: float = sim.remaining
    var frame: int = sim.fighters[0].frame
    sim.tick({"attack":"light"})
    check("hitstop freezes displacement attack and round clocks",sim.fighters[1].x==x and sim.fighters[0].frame==frame and sim.remaining==timer)
    check("input can be buffered during hitstop",sim.fighters[0].buffer=="light")
    for i in 10: sim.tick()
    check("confirmed light cancels into second chain attack",sim.fighters[0].move=="cross")
    for i in 8: sim.tick()
    check("second chain hit connects and applies combo scaling",sim.combo_hits==2 and sim.combo_damage==15)
    sim = setup()
    var finisher_hit := false
    for i in 120:
        sim.tick({"attack":"light"} if i % 7 == 0 else {})
        for event in sim.events:
            if event.kind == "hit" and event.move == "finisher":
                finisher_hit = true
        if finisher_hit: break
    check("full confirmed three-hit chain reaches finisher",finisher_hit and sim.combo_hits==3)
    sim = setup()
    sim.fighters[0].state = "attack"
    sim.fighters[0].move = "jab"
    sim.fighters[0].frame = 4
    sim.tick({}, {"dash":true,"axis":1.0})
    check("dash invulnerability avoids an active strike",sim.fighters[1].health==100)
    sim = setup()
    for i in 2:
        sim.fighters[i].state = "attack"
        sim.fighters[i].move = "jab"
        sim.fighters[i].frame = 4
    sim.tick()
    check("simultaneous active hits trade fairly",sim.fighters[0].health==93 and sim.fighters[1].health==93)
    sim = setup()
    sim.tick({"attack":"light"})
    for i in 50: sim.tick()
    check("one swing cannot hit multiple times",sim.fighters[1].health==93)
    sim = setup()
    sim.fighters[1].x = 6
    sim.tick({"attack":"heavy"})
    for i in 60: sim.tick()
    check("out of range attacks whiff",sim.fighters[1].health==100)
    sim = setup()
    sim.fighters[1].x = -2
    sim.fighters[0].face = 1
    sim.fighters[0].state = "attack"
    sim.fighters[0].move = "jab"
    sim.fighters[0].frame = 5
    sim.tick()
    check("attack does not hit behind the fighter",sim.fighters[1].health==100)
    sim = setup()
    sim.tick({"attack":"heavy"},{"guard":true})
    for i in 17: sim.tick({},{"guard":true})
    check("guard prevents health damage and spends guard",sim.fighters[1].health==100 and sim.fighters[1].guard<60)
    sim = setup()
    sim.fighters[1].guard = 10
    sim.tick({"attack":"heavy"},{"guard":true})
    for i in 17: sim.tick({},{"guard":true})
    check("guard break causes a punishable stun",sim.fighters[1].state=="stun" and sim.fighters[1].stun>=60)
    sim = setup()
    sim.tick({"attack":"special"})
    check("special rejects insufficient energy",sim.fighters[0].state=="idle" and sim.fighters[0].meter==0)
    sim.fighters[0].meter = 70
    sim.tick({"attack":"special"})
    check("special spends exactly 50 energy",sim.fighters[0].meter==20 and sim.fighters[0].move=="special")
    sim = setup()
    sim.tick({"attack":"heavy","up":true})
    for i in 14: sim.tick()
    check("launcher creates airborne hitstun",sim.fighters[1].vy>8 and sim.fighters[1].state=="stun")
    check("heavy has a longer hitstop than jab",sim.hitstop>5)
    sim = setup()
    sim.tick({"jump":true})
    check("jump leaves ground",sim.fighters[0].y>0)
    for i in 80: sim.tick()
    check("gravity returns fighter to ground",sim.fighters[0].y==0 and sim.fighters[0].vy==0)
    sim = setup()
    sim.tick({"dash":true,"axis":-1.0})
    check("dash grants startup invulnerability and cooldown",sim.fighters[0].invuln>0 and sim.fighters[0].dash_cd>0 and sim.fighters[0].vx<0)
    for i in 80: sim.tick({"axis":-1.0})
    check("arena boundary contains fighter",sim.fighters[0].x>=-Sim.EDGE)
    sim = setup()
    sim.fighters[1].health = 7
    sim.tick({"attack":"light"})
    for i in 6: sim.tick()
    check("KO finishes round and awards point",sim.phase=="round_over" and sim.wins==[1,0] and sim.winner==0)
    sim.next_round()
    check("next round resets fighters and retains wins",sim.fighters[1].health==100 and sim.wins==[1,0] and sim.phase=="ready")
    sim.phase = "fight"
    sim.remaining = 0.001
    sim.fighters[1].health = 80
    sim.tick()
    check("second round victory completes best of three",sim.phase=="match_over" and sim.wins==[2,0])
    sim.restart_match()
    check("rematch clears scores and round",sim.wins==[0,0] and sim.round_number==1)
    sim = setup()
    sim.remaining = 0.001
    sim.tick()
    check("tied timeout awards no point",sim.phase=="round_over" and sim.winner==-1 and sim.wins==[0,0])
    sim = setup()
    sim.fighters[1].y = 4
    sim.tick({"attack":"light"})
    for i in 6: sim.tick()
    check("height separation prevents a ground hit",sim.fighters[1].health==100)
    sim = setup()
    sim.ai_enabled = true
    for i in 1800:
        sim.tick({"axis":1.0})
        if sim.phase=="round_over": break
    check("AI engages and damages player",sim.fighters[0].health<100)
    var scene := preload("res://scenes/combat/street_fight.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    scene.start_match(true)
    scene.pause_game()
    check("pause clears pending input and preserves phase",scene.screen=="pause" and scene.pending.is_empty())
    var before_pause: int = scene.sim.tick_count
    scene._physics_process(1.0/60.0)
    check("paused session cannot advance gameplay",scene.sim.tick_count==before_pause)
    scene.resume_game()
    check("resume returns to play",scene.screen=="play")
    scene.reduced_effects = true
    scene.audio.muted = true
    check("reduced effects and mute are configurable",scene.reduced_effects and scene.audio.muted)
    scene.queue_free()
    await process_frame
    await process_frame
    var failed := checks.filter(func(c: Dictionary)->bool: return not c.passed).size()
    var file := FileAccess.open("res://../docs/evidence/combat/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"passed":checks.size()-failed,"failed":failed,"evidence":"headless gameplay and scene checks; not human playtesting or hardware GPU validation"},"  "))
    file.close()
    print("COMBAT_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
