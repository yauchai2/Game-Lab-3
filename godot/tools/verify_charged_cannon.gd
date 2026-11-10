extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("CANNON FAIL: "+label)
func fresh(meter:=100.0) -> RefCounted:
    var s:=Sim.new();s.arcade_enabled=true;s.training=true;s.reset_training();s.ai_enabled=false
    s.fighters[0].x=-.5;s.fighters[1].x=.5;s.fighters[0].meter=meter
    return s
func run() -> void:
    var s=fresh(74);s.tick({"attack":"overdrive"})
    check("insufficient energy rejects the cannon with the correct price",s.fighters[0].meter==74 and s.fighters[0].state!="attack" and s.events.any(func(e:Dictionary)->bool:return e.kind=="no_meter" and e.cost==75))
    s=fresh(75);s.tick({"attack":"overdrive"})
    check("cannon spends exactly 75 once and has a long real startup",s.fighters[0].meter==0 and s.fighters[0].move=="overdrive" and Sim.MOVES.overdrive.startup>Sim.MOVES.special.startup)
    var hits:=0
    for i in 120:
        s.tick()
        for e in s.events:
            if e.kind=="hit" and e.move=="overdrive":hits+=1
    check("cannon hits once through its active frames",hits==1 and s.fighters[1].health==62)
    s=fresh();s.fighters[0].x=-4;s.fighters[1].x=4;s.tick({"attack":"overdrive"})
    for i in 120:s.tick()
    check("a missed cannon never damages or refunds energy",s.fighters[1].health==100 and s.fighters[0].meter==25)
    s=fresh();s.tick({"attack":"overdrive"});s.fighters[1].state="attack";s.fighters[1].move="jab";s.fighters[1].frame=4;s.tick()
    check("charge armor still takes real damage",s.fighters[0].health<100 and s.fighters[0].move=="overdrive" and s.fighters[0].state=="attack")
    s=fresh();s.tick({"attack":"overdrive"});s.fighters[1].state="attack";s.fighters[1].move="grab";s.fighters[1].frame=10;s.tick()
    check("throw really interrupts the paid charge",s.fighters[0].state=="stun" and s.fighters[0].health==88 and s.fighters[0].meter==31)
    s=fresh();s.tick({"rush":true})
    while not s.fighters[0].hit_confirmed:s.tick({"rush":true})
    s.tick({"attack":"overdrive","rush":true})
    var fired:=false
    for i in 90:
        s.tick({"rush":true})
        for e in s.events:
            if e.kind=="swing" and e.move=="overdrive":fired=true
    check("manual cannon is not swallowed by held J",fired)
    s=fresh();s.tick({"attack":"special"})
    check("ordinary L keeps its 50-energy immediate command",s.fighters[0].meter==50 and s.fighters[0].move=="special")
    var d=preload("res://scripts/combat/demo_director.gd").new();s=Sim.new();d.prepare(s)
    var contacts:=[0,0]
    for i in 7200:
        var commands:Array=d.commands(s);s.tick(commands[0],commands[1]);d.observe(s)
        for event in s.events:
            if event.kind=="hit":contacts[event.attacker]+=1
            elif event.kind=="parry":contacts[event.target]+=1
            elif event.kind=="air_counter_start":contacts[event.owner]+=1
    check("live agents naturally use the cannon",d.seen.get("hit/overdrive",0)>0 and d.seen.get("hit/special",0)>0)
    check("new cannon does not end or reset the live duel",s.phase=="fight" and d.age==7200 and d.hits[0]>50 and d.hits[1]>50 and contacts[0]>50 and contacts[1]>50)
    var passed:=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open("res://../docs/evidence/charged-cannon/rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"events":d.seen,"real_offense_or_defense_contacts":contacts,"scope":"Actual legal command and simulation contacts; no fake hits."},"  "))
    print("CANNON_RULES ",passed,"/",checks.size());quit(0 if passed==checks.size() else 1)
