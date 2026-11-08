extends SceneTree
const Sim = preload("res://scripts/combat/fight_simulation.gd")
const Exchange = preload("res://scripts/combat/pressure_exchange.gd")
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("PRESSURE FAIL: "+label)
func fresh() -> RefCounted:
    var sim:=Sim.new()
    sim.phase="fight"
    sim.ai_enabled=false
    sim.fighters[0].x=-.6
    sim.fighters[1].x=.6
    return sim
func heavy(sim: RefCounted) -> void:
    sim.fighters[0].state="attack"
    sim.fighters[0].move="heavy"
    sim.fighters[0].frame=15
    sim.tick()
func ready_clash() -> RefCounted:
    var sim=fresh()
    sim.exchange.pressure=60
    heavy(sim)
    return sim
func resolve(sim: RefCounted, a: String, b: String) -> void:
    sim.tick({"clash_choice":a},{"clash_choice":b})
    for i in 23:sim.tick()
func key(scene: Node, code: Key) -> void:
    var event:=InputEventKey.new()
    event.keycode=code
    event.physical_keycode=code
    event.pressed=true
    scene._unhandled_key_input(event)
func run() -> void:
    for category in ["shadowed_variable_base_class","shadowed_global_identifier","integer_division"]:
        ProjectSettings.set_setting("debug/gdscript/warnings/"+category,2)
    for path in ["res://scripts/combat/pressure_exchange.gd","res://scripts/combat/fight_simulation.gd","res://scripts/combat/fight_session.gd","res://scripts/combat/fight_hud.gd"]:
        var compiled:=GDScript.new()
        compiled.source_code=FileAccess.get_file_as_string(path)
        check("strict compile "+path,compiled.reload()==OK)
    var exchange:=Exchange.new()
    check("pressure begins in calm tier",exchange.tier()==1 and exchange.pressure==0)
    exchange.contact(30)
    check("second tier begins at thirty",exchange.tier()==2)
    exchange.contact(30)
    check("third tier begins at sixty",exchange.tier()==3)
    exchange.contact(1000)
    check("pressure is capped",exchange.pressure==90 and exchange.tier()==3)
    for i in 90:exchange.advance_idle(false)
    check("nearby quiet grace period keeps pressure",exchange.pressure==90)
    exchange.advance_idle(false)
    check("quiet exchanges lose pressure",exchange.pressure<90)
    exchange.contact(0)
    for i in 31:exchange.advance_idle(true)
    check("separation starts faster pressure release",exchange.pressure<89.5)
    for i in 400:exchange.advance_idle(true)
    check("pressure decay never goes negative",exchange.pressure==0)
    var sim=fresh()
    heavy(sim)
    check("low pressure heavy remains a normal eighteen damage hit",not sim.exchange.active() and sim.fighters[1].health==82 and sim.hitstop==11 and sim.exchange.pressure==10)
    sim=fresh()
    sim.fighters[0].state="attack"
    sim.fighters[0].move="jab"
    sim.fighters[0].frame=4
    sim.tick({}, {"guard":true})
    check("perfect guard builds pressure without damage",sim.exchange.pressure==16 and sim.fighters[1].health==100)
    sim=fresh()
    sim.fighters[1].parry_cd=30
    sim.fighters[0].state="attack"
    sim.fighters[0].move="jab"
    sim.fighters[0].frame=4
    sim.tick({}, {"guard":true})
    check("ordinary block builds pressure",sim.exchange.pressure==8 and sim.fighters[1].health==100)
    for heavy_side in 2:
        sim=fresh()
        sim.exchange.pressure=60
        for side in 2:
            sim.fighters[side].state="attack"
            sim.fighters[side].move="heavy" if side==heavy_side else "jab"
            sim.fighters[side].frame=15 if side==heavy_side else 4
        sim.tick()
        check("simultaneous jab and high pressure heavy treats side %d fairly" % heavy_side,sim.exchange.active() and sim.exchange.clash.attacker==heavy_side and sim.fighters[0].health==100 and sim.fighters[1].health==100)
    sim=fresh()
    sim.exchange.pressure=50
    for side in 2:
        sim.fighters[side].state="attack"
        sim.fighters[side].move="jab" if side==0 else "heavy"
        sim.fighters[side].frame=4 if side==0 else 15
    sim.tick()
    check("a simultaneous normal trade cannot unlock a clash halfway through resolution",not sim.exchange.active() and sim.fighters[0].health==82 and sim.fighters[1].health==93)
    sim=ready_clash()
    check("grounded high pressure heavy opens a single decision window",sim.exchange.active() and sim.exchange.clash.remaining==24 and sim.events.filter(func(e:Dictionary)->bool:return e.kind=="clash_start").size()==1)
    check("opening clash defers damage",sim.fighters[1].health==100 and sim.hitstop==0)
    var snapshot: Array=sim.fighters.duplicate(true)
    var clock: float=sim.remaining
    sim.tick({"axis":1,"attack":"light","jump":true},{"axis":-1,"dash":true})
    check("clash freezes positions fighter states and round clock",sim.fighters==snapshot and sim.remaining==clock)
    check("normal movement attacks and jump do not leak through clash",sim.fighters[0].buffer=="" and sim.fighters[0].jump_buffer==0 and sim.exchange.clash.choices==["",""])
    sim=ready_clash()
    sim.tick({"clash_choice":"turn"},{"clash_choice":"press"})
    sim.tick({"clash_choice":"slip"},{"clash_choice":"turn"})
    check("first valid decision is locked for both players",sim.exchange.clash.choices==["turn","press"])
    check("choices do not resolve early",sim.exchange.active() and sim.fighters[0].health==100 and sim.fighters[1].health==100)
    var expected := [[-1,1,0],[0,-1,1],[1,0,-1]]
    for a in 3:
        for b in 3:
            sim=ready_clash()
            resolve(sim,Exchange.CHOICES[a],Exchange.CHOICES[b])
            var winner: int=expected[a][b]
            var damage:=0
            if winner>=0:damage=22 if [a,b][winner]==0 else (16 if [a,b][winner]==1 else 0)
            check("decision matrix %s vs %s" % [Exchange.CHOICES[a],Exchange.CHOICES[b]],sim.exchange.last_result.winner==winner and not sim.exchange.active() and sim.fighters[0].health==(100-damage if winner==1 else 100) and sim.fighters[1].health==(100-damage if winner==0 else 100))
    check("resolution releases shared pressure and enforces cooldown",sim.exchange.pressure==0 and sim.exchange.cooldown==90)
    sim=ready_clash()
    resolve(sim,"","")
    check("double timeout separates safely without damage",sim.exchange.last_result.winner==-1 and sim.fighters[0].health==100 and sim.fighters[1].health==100)
    sim=ready_clash()
    resolve(sim,"","press")
    check("single timeout concedes rather than granting free guard",sim.exchange.last_result.winner==1 and sim.fighters[0].health==78)
    sim=ready_clash()
    resolve(sim,"turn","press")
    var hp: int=sim.fighters[1].health
    for i in 5:sim.tick()
    check("clash damage is applied once and normal buffers stay clear",sim.fighters[1].health==hp and sim.fighters[0].buffer=="")
    sim=fresh()
    sim.exchange.pressure=60
    sim.exchange.cooldown=90
    heavy(sim)
    check("cooldown prevents immediate repeated clashes",not sim.exchange.active() and sim.fighters[1].health==82)
    sim=fresh()
    sim.exchange.pressure=60
    sim.fighters[1].y=1
    heavy(sim)
    check("airborne heavy does not open grounded clash",not sim.exchange.active())
    sim=fresh()
    sim.exchange.pressure=60
    sim.fighters[1].state="stun"
    sim.fighters[1].stun=30
    heavy(sim)
    check("stunned defenders are not forced into repeated decisions",not sim.exchange.active())
    sim=fresh()
    sim.exchange.pressure=60
    sim.fighters[1].x=6
    heavy(sim)
    check("whiffs neither open clash nor build pressure",not sim.exchange.active() and sim.exchange.pressure==60 and sim.fighters[1].health==100)
    sim=ready_clash()
    sim.ai_enabled=true
    var intent: String=sim.exchange.clash.intent
    sim.tick({"clash_choice":"press"})
    for i in 17:sim.tick()
    check("AI commits to preselected visible intent without reading player choice",sim.exchange.clash.choices[1]==intent)
    sim=ready_clash()
    resolve(sim,"slip","turn")
    var start_x: float=sim.fighters[0].x
    for i in 6:sim.tick()
    check("successful slip creates distance and deals no damage",sim.fighters[0].x<start_x and sim.fighters[1].health==100)
    sim.reset_round()
    check("round reset clears pressure choices cooldown and prior result",sim.exchange.pressure==0 and sim.exchange.cooldown==0 and not sim.exchange.active() and sim.exchange.last_result.is_empty())
    sim=ready_clash()
    sim.fighters[1].health=1
    resolve(sim,"press","slip")
    check("lethal clash resolves a normal round",sim.phase=="round_over" and sim.winner==0 and sim.wins[0]==1)
    sim=ready_clash()
    sim.training=true
    sim.fighters[1].health=1
    resolve(sim,"press","slip")
    check("lethal clash respects endless training",sim.phase=="fight" and sim.fighters[1].health==1)
    sim=ready_clash()
    sim.fighters[0].x=-8
    sim.fighters[1].x=-6.8
    resolve(sim,"slip","turn")
    for i in 12:sim.tick()
    check("slip cannot move fighters outside arena edges",sim.fighters[0].x>=-Sim.EDGE and sim.fighters[1].x<=Sim.EDGE)
    var replay_a=fresh()
    var replay_b=fresh()
    replay_a.ai_enabled=true
    replay_b.ai_enabled=true
    var rng:=RandomNumberGenerator.new()
    rng.seed=24680
    var stress_ok:=true
    var deterministic:=true
    var stress_clashes:=0
    for tick_index in 20000:
        var command := {"axis":signf(replay_a.fighters[1].x-replay_a.fighters[0].x) if absf(replay_a.fighters[1].x-replay_a.fighters[0].x)>1.3 else 0.0}
        if tick_index%18==0:command["attack"]=["light","heavy","launcher"][rng.randi_range(0,2)]
        if tick_index%11<3:command["guard"]=true
        if replay_a.exchange.active():command["clash_choice"]=Exchange.CHOICES[rng.randi_range(0,2)]
        var was_active: bool=replay_a.exchange.active()
        replay_a.tick(command)
        replay_b.tick(command)
        if replay_a.exchange.active() and not was_active:stress_clashes+=1
        deterministic=deterministic and replay_a.fighters==replay_b.fighters and replay_a.exchange.clash==replay_b.exchange.clash and is_equal_approx(replay_a.exchange.pressure,replay_b.exchange.pressure)
        stress_ok=stress_ok and replay_a.exchange.pressure>=0 and replay_a.exchange.pressure<=90
        for fighter in replay_a.fighters:
            stress_ok=stress_ok and is_finite(fighter.x) and is_finite(fighter.y) and absf(fighter.x)<=Sim.EDGE and fighter.y>=0 and fighter.health>=0 and fighter.health<=100
        if replay_a.phase in ["round_over","match_over"]:
            replay_a.restart_match()
            replay_b.restart_match()
            replay_a.phase="fight"
            replay_b.phase="fight"
    check("twenty thousand mixed AI ticks keep bounded fighters and pressure",stress_ok)
    check("replaying identical commands preserves clash and fighter states",deterministic)
    check("ordinary mixed combat reaches high pressure clashes",stress_clashes>0)
    print("PRESSURE_STRESS natural_clashes=",stress_clashes)
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    scene.start_match(true)
    scene.prime_pressure_drill()
    check("practice drill primes nearby third tier without autoattacking",scene.sim.exchange.pressure==60 and scene.sim.fighters[0].state=="idle" and scene.sim.fighters[1].x-scene.sim.fighters[0].x<2)
    for i in 300:scene._physics_process(1.0/60)
    check("drill waits without losing pressure while instructions are read",scene.sim.pressure_drill and scene.sim.exchange.pressure==60 and scene.sim.fighters[1].state=="idle")
    scene.sim.fighters[0].state="attack"
    scene.sim.fighters[0].move="heavy"
    scene.sim.fighters[0].frame=15
    scene._physics_process(1.0/60)
    check("session opens held clash effect and no contact release",scene.sim.exchange.active() and scene.effects.any(func(e:Dictionary)->bool:return e.kind=="clash") and scene.impact_queue.is_empty())
    key(scene,KEY_SHIFT)
    key(scene,KEY_E)
    check("rapid keys in one frame retain the first commitment",scene.pending.get("clash_choice","")=="turn" and not scene.pending.has("dash"))
    scene._physics_process(1.0/60)
    var remaining_ticks: int=scene.sim.exchange.clash.remaining
    scene.pause_game()
    scene._physics_process(1.0/60)
    scene._process(.1)
    check("pause freezes decision deadline and retains chosen action",scene.sim.exchange.clash.remaining==remaining_ticks and scene.sim.exchange.clash.choices[0]=="turn")
    scene.resume_game()
    for i in remaining_ticks:
        scene._physics_process(1.0/60)
        scene._process(1.0/60)
    check("training standing partner teaches turn against press",scene.sim.exchange.last_result.winner==0 and scene.sim.exchange.last_result.choice=="turn")
    check("resolved clash clears held clash effect",not scene.effects.any(func(e:Dictionary)->bool:return e.kind=="clash"))
    key(scene,KEY_F8)
    check("F8 drill can be repeated and clears pending VFX",scene.sim.exchange.pressure==60 and scene.effects.is_empty() and scene.pending.is_empty())
    scene.sim.exchange.begin(0,"press")
    scene.return_to_title()
    check("main menu clears active choice overlay",not scene.sim.exchange.active() and scene.sim.exchange.pressure==0)
    scene.queue_free()
    await process_frame
    await create_timer(.15).timeout
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/pressure-exchange/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed},"  "))
    print("PRESSURE_EXCHANGE_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
