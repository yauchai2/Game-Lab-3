extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Director=preload("res://scripts/combat/demo_director.gd")
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,passed:bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("DEMO FAIL: "+label)
func run() -> void:
    var sim:=Sim.new()
    var replay:=Sim.new()
    var director:=Director.new()
    var other:=Director.new()
    var coverage: Dictionary={}
    var actors: Dictionary={}
    var chapters: Dictionary={}
    var bounded:=true
    var deterministic:=true
    var ticks:=0
    for i in 18000:
        if director.needs_setup:
            director.prepare(sim);other.prepare(replay)
            chapters[director.key()]=chapters.get(director.key(),0)+1
        var input:=director.commands(sim)
        var second:=other.commands(replay)
        sim.tick(input[0],input[1]);replay.tick(second[0],second[1])
        deterministic=deterministic and input==second and sim.fighters==replay.fighters and sim.events==replay.events
        for event in sim.events:
            var key: String=event.kind
            if key=="hit":key+="/"+event.get("move","")
            coverage[key]=coverage.get(key,0)+1
            if event.kind=="hit":actors[str(event.attacker)]=actors.get(str(event.attacker),0)+1
        director.observe(sim);other.observe(replay)
        for f in sim.fighters:bounded=bounded and absf(f.x)<=Sim.EDGE and f.y>=0 and f.y<8 and is_finite(f.x) and is_finite(f.y)
        ticks=i+1
        if director.cycle>=2:break
    check("two complete showcase cycles finish",director.cycle==2)
    check("all chapters run in both role orientations",chapters.size()==Director.CHAPTERS.size() and chapters.values().all(func(n:int)->bool:return n==2))
    check("both AI agents land actual hits",actors.get("0",0)>10 and actors.get("1",0)>10)
    check("identical state produces identical commands outcomes and events",deterministic)
    check("all simulated positions remain finite and in arena",bounded)
    for key in ["hit/jab","hit/cross","hit/finisher","hit/heavy","hit/launcher","hit/air_jab","hit/air_kick","hit/air_finisher","hit/meteor","hit/air_counter","hit/grab","hit/special","block","guard_break","parry","throw_tech","dash","wall_bounce","wall_tech","jump","fast_fall","homing_chase","chase_arrive","ground_bounce","air_counter_start","air_counter_end","clash_start","clash_end","rally_contact","rally_release","rally_end","ko"]:
        check("real event coverage "+key,coverage.get(key,0)>=2)
    var path:="res://../docs/evidence/ai-demo/rules.json"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../docs/evidence/ai-demo"))
    FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"ticks":ticks,"coverage":coverage,"chapters":chapters,"scope":"Deterministic scripted showcase agents, real simulation commands and contacts; not competitive AI or human test."},"  "))
    var passed:=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    print("DEMO_CHECKS ",passed,"/",checks.size()," ticks=",ticks)
    quit(0 if passed==checks.size() else 1)
