extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("FRIENDLY DEFENSE FAIL: "+label)
func fresh(frame:=5,attacker:=1) -> RefCounted:
    var s:=Sim.new();s.phase="fight";s.ai_enabled=false
    for i in 2:s.fighters[i].x=-.6 if i==0 else .6
    s.fighters[attacker].state="attack";s.fighters[attacker].move="heavy";s.fighters[attacker].frame=frame
    return s
func run() -> void:
    for side in 2:
        var s=fresh(5,1-side)
        var inputs:=[{},{}];inputs[side]={"guard_pressed":true}
        s.tick(inputs[0],inputs[1])
        for i in 10:s.tick()
        check("early tap catches a real attack on side "+str(side),s.fighters[side].health==100 and s.fighters[1-side].state=="stun")
        check("parry grants tangible energy and punish time "+str(side),s.fighters[side].meter==18 and s.fighters[1-side].stun==30 and s.fighters[side].counter_window==36)
        check("parry cooldown is bounded "+str(side),s.fighters[side].parry_cd==60)
    var s=fresh()
    s.tick({"guard_pressed":true,"guard":true})
    for i in 9:s.tick({"guard":true})
    s.tick({"guard":true,"attack":"light"})
    check("counter input can be queued before parry contact",s.fighters[0].counter_window>0 and s.fighters[0].buffer=="light")
    var counter_events:=0
    for i in 30:
        s.tick({"guard":true})
        counter_events+=s.events.filter(func(e:Dictionary)->bool:return e.kind=="counter_success").size()
    check("queued counter starts even while Shift stays held",s.fighters[1].health<100 and counter_events==1)
    check("counter adds no automatic damage bonus",s.last_combo_damage==7)
    s=fresh(0)
    s.tick({"guard_pressed":true})
    for i in 17:s.tick()
    check("a tap that is too early still expires",s.fighters[0].health==82)
    s=fresh();s.fighters[1].state="idle"
    s.tick({"guard_pressed":true});s.tick({"jump":true})
    check("released tap guard does not swallow a jump",s.fighters[0].vy>0)
    s=fresh(10);s.fighters[1].move="grab"
    s.fighters[0].x=-.5;s.fighters[1].x=.5
    s.tick({"guard_pressed":true,"guard":true})
    check("throw still beats assisted guard",s.fighters[0].health==88)
    s=fresh();s.fighters[1].state="idle";s.fighters[1].x=6
    s.fighters[0].counter_window=36
    s.tick({"attack":"light"})
    counter_events=0
    for i in 25:
        s.tick();counter_events+=s.events.filter(func(e:Dictionary)->bool:return e.kind=="counter_success").size()
    check("counter praise requires actual contact",counter_events==0 and s.fighters[1].health==100)
    s=fresh();s.fighters[1].state="idle";s.fighters[0].counter_window=36
    for i in 37:s.tick()
    check("counter opportunity cannot last forever",s.fighters[0].counter_window==0)
    s=fresh();s.training=true;s.practice_scenario="air"
    for f in s.fighters:f.y=1.4;f.meter=100
    s.fighters[1].move="air_finisher";s.fighters[1].frame=0
    s.tick({"guard_pressed":true})
    for i in 11:s.tick()
    check("air parry accepts the entire finisher tell",s.air_counter.active() and s.fighters[0].health==100 and s.fighters[0].meter==75)
    check("air hold and punish windup allow more decision time",s.air_counter.HOLD==30 and s.air_counter.WINDUP==14)
    s=fresh();s.training=true;s.rally_enabled=true;s.fighters[1].state="idle"
    s.rally.begin(1)
    s.tick({}, {"attack":"light"})
    while s.rally.phase=="compress" and s.rally.age<s.rally.HOLDS[0]-4:s.tick()
    s.tick({"guard_pressed":true})
    check("late compression guard is buffered",s.rally.guard_buffer[0])
    for i in 20:
        if s.rally.owner==0:break
        s.tick()
    check("buffered tap becomes an actual rally parry",s.rally.owner==0 and s.rally.tier==2)
    check("high tier retains a generous but finite window",s.rally.WINDOWS==[12,10,9,8])
    s=fresh();s.fighters[0].counter_window=36;s.training=true;s.reset_training()
    check("reset removes counter opportunity and queued strike",s.fighters[0].counter_window==0 and not s.fighters[0].counter_attack)
    check("pressure decision lasts six tenths of a second",s.exchange.WINDOW==36)
    s=fresh(15);s.exchange.pressure=60;s.fighters[0].counter_window=36
    s.tick()
    check("pressure clash clears the ordinary counter cue",s.exchange.active() and s.fighters[0].counter_window==0)
    s=fresh(4);s.training=true;s.rally_enabled=true;s.fighters[1].move="jab";s.fighters[0].counter_window=36
    s.tick({"guard":true,"guard_pressed":true})
    check("rally transfer clears ordinary counter state",s.rally.active() and s.fighters[0].counter_window==0)
    var copy=preload("res://scripts/combat/ui/ui_text.gd").new()
    for locale in ["zh","en"]:
        copy.language=locale
        check("positive feedback is localized "+locale,copy.notice("COUNTER SUCCESS")!="COUNTER SUCCESS" and copy.notice("NICE BLOCK")!="NICE BLOCK" and copy.text("counter_ready")!="counter_ready")
    var passed:=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open("res://../docs/evidence/friendly-defense/rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks},"  "))
    print("FRIENDLY_DEFENSE_CHECKS ",passed,"/",checks.size())
    quit(0 if passed==checks.size() else 1)
