extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Director=preload("res://scripts/combat/demo_director.gd")
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("DEMO LOOP FAIL: "+label)
func run() -> void:
    var s:=Sim.new();var twin:=Sim.new();var d:=Director.new();var replay:=Director.new()
    s.last_service_enabled=true;twin.last_service_enabled=true
    d.prepare(s);replay.prepare(twin)
    check("normal-health exhibition starts in ready",not s.training and not s.endless and s.phase=="ready")
    var same:=true;var bounded:=true;var zero_health_ko:=true;var health_loss:=false
    for tick in 30000:
        var a:=d.commands(s);var b:=replay.commands(twin)
        s.tick(a[0],a[1]);twin.tick(b[0],b[1]);d.observe(s);replay.observe(twin)
        same=same and a==b and s.fighters==twin.fighters and s.events==twin.events and s.phase==twin.phase
        for f in s.fighters:bounded=bounded and f.health>=0 and f.health<=100 and f.meter>=0 and f.meter<=100 and is_finite(f.x) and is_finite(f.y)
        health_loss=health_loss or s.fighters[0].health<100 or s.fighters[1].health<100
        if s.phase in ["round_over","match_over"]:
            if s.remaining>0:zero_health_ko=zero_health_ko and mini(s.fighters[0].health,s.fighters[1].health)==0
            d.advance_round(s);replay.advance_round(twin)
    check("thirty thousand steps replay deterministically",same)
    check("normal health and resources stay bounded",bounded)
    check("real damage and zero-health KO occur",health_loss and zero_health_ko and d.seen.get("ko",0)>5)
    check("both autonomous agents land real hits",d.hits[0]>50 and d.hits[1]>50)
    check("natural rounds and matches continue indefinitely",d.rounds_finished>5 and d.matches_finished>0 and not s.training and not s.endless)
    check("round resets do not erase cumulative demo statistics",d.age==30000 and d.seen.get("hit",0)==0 and d.hits[0]+d.hits[1]>100)
    var failed:int=checks.filter(func(v:Dictionary)->bool:return not v.passed).size()
    FileAccess.open("res://../docs/evidence/rush-rework/live-rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"ticks":30000,"events":d.seen,"hits":d.hits,"rounds":d.rounds_finished,"matches":d.matches_finished,"scope":"Normal-stat input policies and natural KO boundaries; actual scene presentations tested in verify_round_flow"},"  "))
    print("DEMO_LOOP_CHECKS ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
