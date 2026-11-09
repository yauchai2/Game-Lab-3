extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Director=preload("res://scripts/combat/demo_director.gd")
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("LIVE DEMO FAIL: "+label)
func run() -> void:
    var s:=Sim.new();var replay:=Sim.new();var d:=Director.new();var other:=Director.new()
    d.prepare(s);other.prepare(replay)
    var bounded:=true;var identical:=true;var uninterrupted:=true
    var timeline: Array=[]
    for tick in 30000:
        var a:=d.commands(s);var b:=other.commands(replay)
        s.tick(a[0],a[1]);replay.tick(b[0],b[1]);d.observe(s);other.observe(replay)
        identical=identical and a==b and s.fighters==replay.fighters and s.events==replay.events
        uninterrupted=uninterrupted and s.phase=="fight" and not d.needs_setup and d.age==tick+1 and s.remaining==75
        for f in s.fighters:bounded=bounded and is_finite(f.x) and is_finite(f.y) and absf(f.x)<=Sim.EDGE and f.y>=0 and f.y<8 and f.health>=1 and f.health<=100 and f.meter>=0 and f.meter<=100 and f.impact_load<=100
        if tick%600==0:timeline.append({"tick":tick,"hits":d.hits.duplicate(),"gap":d.no_hit_ticks})
    check("one continuous fight remains active for thirty thousand ticks",uninterrupted)
    check("two independent runs reproduce commands actors and events",identical)
    check("both agents land hundreds of real hits",d.hits[0]>250 and d.hits[1]>250)
    check("first contact arrives within one second",d.first_hit<=60)
    check("no multi-second idle gaps",d.longest_gap<=180)
    check("positions health and resources stay bounded",bounded)
    for key in ["hit/jab","hit/cross","hit/launcher","hit/air_jab","hit/air_kick","hit/meteor","hit/special","hit/air_counter","homing_chase","ground_bounce","air_counter_start","air_escape","break_finish"]:
        check("natural live event "+key,d.seen.get(key,0)>2)
    check("demo is actually endless rather than a KO loop",s.endless and s.training and s.arcade_enabled and not d.seen.has("ko"))
    check("showy combos occur without scene presets",d.longest_combo>=6)
    FileAccess.open("res://../docs/evidence/rush-rework/live-rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"ticks":30000,"events":d.seen,"hits":d.hits,"longest_combo":d.longest_combo,"first_hit":d.first_hit,"max_no_hit_ticks":d.longest_gap,"timeline":timeline,"scope":"Live input policies only. No chapter changes, position resets or injected hits."},"  "))
    var passed:=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    print("LIVE_DEMO_CHECKS ",passed,"/",checks.size())
    quit(0 if passed==checks.size() else 1)
