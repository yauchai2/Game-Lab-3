extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Box=preload("res://scripts/combat/arena_box.gd")
const OUT="res://../docs/evidence/arena-box/"
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("ARENA ",label," ",ok)
    if not ok:push_error(label)
func fixture() -> RefCounted:
    var s=Sim.new();s.arcade_enabled=true;s.last_service_enabled=true;s.ai_enabled=false;s.phase="fight"
    return s
func run() -> void:
    var s=fixture();s.character_choices=[1,0];s.restart_match();s.phase="fight";s.fighters[0].meter=100;s.fighters[0].x=0;s.fighters[1].x=1
    var landed:=false
    for tick in 70:
        s.tick({"attack":"overdrive"} if tick==0 else {},{})
        for e in s.events:
            if e.kind=="hit":landed=Box.active(s.fighters[1])
    check("a legal paid overdrive hit arms the box trajectory",landed)
    var health:int=s.fighters[1].health;var surfaces:Dictionary={};var bounded:=true;var released:=false
    for tick in 500:
        s.tick({},{})
        for f in s.fighters:bounded=bounded and absf(f.x)<=s.EDGE and f.y>=0 and f.y<=Box.CEILING and Vector2(f.x,f.y).is_finite()
        for e in s.events:
            if e.kind=="arena_bounce":surfaces[e.surface]=true
        if not Box.active(s.fighters[1]):released=true
    check("one overdrive makes multiple genuine boundary contacts",surfaces.size()>=3)
    check("flight remains inside all four limits",bounded)
    check("ricochets never create additional health damage",s.fighters[1].health==health)
    check("finite flight restores control without a permanent stun",released and s.fighters[1].state=="idle")
    for surface in ["left","right","ceiling","floor"]:
        s=fixture();var f:Dictionary=s.fighters[0]
        f.state="stun";f.stun=40;f.y=2;Box.arm(f,"heavy",1,18)
        match surface:
            "left":f.x=-s.EDGE+.01;f.vx=-30
            "right":f.x=s.EDGE-.01;f.vx=30
            "ceiling":f.y=Box.CEILING-.01;f.vy=24
            "floor":f.y=.01;f.vy=-24
        var incoming:float=absf(f.vx) if surface in ["left","right"] else absf(f.vy)
        s.tick({},{})
        var found:bool=s.events.any(func(e:Dictionary)->bool:return e.kind=="arena_bounce" and e.surface==surface)
        var normal:Vector2=f.ricochet.normal
        check(surface+" reverses the normal velocity and loses energy",found and Vector2(f.vx,f.vy).dot(normal)>0 and (absf(f.vx) if normal.x!=0 else absf(f.vy))<incoming)
        s.hitstop=0;f.meter=50;s.tick({"dash":true},{})
        check(surface+" E tech spends 20 and releases the flight",not Box.active(f) and f.meter==30 and f.state=="dash" and f.invuln>0)
    s=fixture();var f:Dictionary=s.fighters[0];f.state="stun";f.stun=20;f.y=2;Box.arm(f,"heavy",1,14)
    var original:Dictionary=f.duplicate(true);s.hitstop=4;s.tick({},{})
    check("native hitstop freezes trajectory and lifetime",f.x==original.x and f.y==original.y and f.ricochet==original.ricochet)
    s.hitstop=0;f.ricochet.ticks=1;s.tick({},{})
    check("time limit releases with protection",not Box.active(f) and f.state=="idle" and f.invuln>=18)
    Box.arm(f,"heavy",1,14)
    check("spent contact budget cannot be refreshed before landing",not Box.active(f))
    for character in 4:
        for name in ["jab","cross","heavy","finisher","launcher","meteor","air_finisher","air_counter","grab","special"]:
            s=fixture();s.character_choices=[character,0];s.restart_match();s.phase="fight"
            var attacker:Dictionary=s.fighters[0];var target:Dictionary=s.fighters[1]
            attacker.x=0;target.x=1;attacker.state="attack";attacker.move=name;attacker.frame=s.move_for(attacker,name).startup
            if name in ["meteor","air_finisher","air_counter"]:attacker.y=2;target.y=2
            s._resolve_hit(0,false)
            check("ordinary %d/%s never arms multi-bounce"%[character,name],not Box.active(target))
    for character in 4:
        s=fixture();s.character_choices=[character,0];s.restart_match();s.phase="fight"
        var a:Dictionary=s.fighters[0];a.service.flurry_left=0
        check("character %d overdrive final impact opts in"%character,s.move_for(a,"overdrive").ricochet)
    s=fixture();s.character_choices=[1,0];s.restart_match();s.fighters[0].service.preload=1
    check("partial RIVET charge remains ordinary",not s.move_for(s.fighters[0],"special").ricochet)
    s.fighters[0].service.preload=2
    check("full RIVET charge opts in",s.move_for(s.fighters[0],"special").ricochet)
    s=fixture();s.character_choices=[2,0];s.restart_match();s.fighters[0].service.sample_boost=true
    check("boosted HUSH special opts in",s.move_for(s.fighters[0],"special").ricochet)
    s=fixture();s.fighters[0].y=Box.CEILING-.01;s.fighters[0].vy=20;s.tick({},{})
    check("ordinary movement has no temporary box ceiling",s.fighters[0].y>Box.CEILING and not Box.active(s.fighters[0]))
    s=fixture();var twin=fixture();var deterministic:=true
    for tick in 10000:
        var a:Dictionary=s.rush_agent.choose(s,0,tick,2,true);var b:Dictionary=s.rush_agent.choose(s,1,tick,2,true)
        s.tick(a,b);twin.tick(a,b)
        deterministic=deterministic and s.fighters==twin.fighters and s.phase==twin.phase
        if s.phase in ["round_over","match_over"]:s.restart_match();twin.restart_match()
    check("10000 normal AI ticks are deterministic",deterministic)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"surfaces_from_one_overdrive":surfaces.keys(),"scope":"Pure simulation, legal overdrive plus explicit boundary and input fixtures; not a human balance test"},"  "))
    print("ARENA_CHECKS ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
