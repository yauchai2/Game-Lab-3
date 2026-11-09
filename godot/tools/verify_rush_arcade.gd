extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("RUSH ARCADE FAIL: "+label)
func run() -> void:
    var s:=Sim.new();s.arcade_enabled=true;s.restart_match()
    check("burst is ready on the first round",s.fighters[0].meter==60 and s.fighters[1].meter==60)
    check("opening begins close and quickly",s.countdown==36 and s.fighters[1].x-s.fighters[0].x<3.3)
    var seen:={};var first:=-1;var max_combo:=0
    for t in 600:
        s.tick({"rush":true})
        for e in s.events:
            if e.kind=="hit" and e.attacker==0:
                seen[e.move]=seen.get(e.move,0)+1
                if first<0:first=t
        max_combo=maxi(max_combo,s.combo_hits)
        if s.phase in ["round_over","match_over"]:break
    check("holding one button earns contact within two seconds",first>=0 and first<120)
    for move in ["jab","cross","launcher","air_jab","air_kick","meteor"]:check("one-button chain actually hits with "+move,seen.has(move))
    check("beginner can finish a real round",s.phase=="round_over" and s.winner==0)
    check("opponent still deals real damage",s.fighters[0].health<100)
    check("chain produces a readable six-hit reward",max_combo>=6)
    s=Sim.new();s.arcade_enabled=true;s.training=true;s.phase="fight";s.ai_enabled=false
    s.fighters[0].x=-.6;s.fighters[1].x=.6;s.fighters[0].meter=100
    s.tick({"rush":true})
    while not s.fighters[0].hit_confirmed:s.tick({"rush":true})
    s.tick({"attack":"special","rush":true})
    var burst_started:=false
    for i in 35:
        s.tick({"rush":true})
        for e in s.events:
            if e.kind=="swing" and e.move=="special":burst_started=true
    check("held light does not erase a requested burst",burst_started and s.fighters[0].meter<100)
    check("confirmed attack can cancel into a burst",s.last_combo_damage>0)
    s=Sim.new();s.arcade_enabled=true;s.training=true;s.phase="fight";s.ai_enabled=false
    s.fighters[0].x=-6;s.fighters[1].x=6
    for i in 90:s.tick({"rush":true})
    check("assist never hits outside real reach",s.fighters[1].health==100)
    check("misses do not award free chase",not s.fighters[0].air.chase_used)
    s=Sim.new();s.arcade_enabled=true;s.phase="fight";s.ai_enabled=false
    var f: Dictionary=s.fighters[1];f.y=.01;f.vy=-3;f.state="stun";f.stun=30;f.juggle=3
    s.tick()
    check("air combo landing grants a real escape",f.state=="idle" and f.invuln>0)
    s.phase="round_over";s.next_round()
    check("arcade rules survive subsequent rounds",s.arcade_enabled and s.phase=="ready" and s.fighters[0].meter==60)
    s.training=true;s.reset_training()
    check("free practice resets at a playable distance",absf(s.fighters[0].x-s.fighters[1].x)<1.5)
    s=Sim.new();s.arcade_enabled=true;s.ai_enabled=false;s.phase="fight"
    s.fighters[0].x=-.5;s.fighters[1].x=.5;s.fighters[0].meter=100
    s.tick({"attack":"special"})
    s.fighters[1].state="attack";s.fighters[1].move="jab";s.fighters[1].frame=4
    s.tick()
    check("burst startup takes damage without losing the move to a jab",s.fighters[0].health<100 and s.fighters[0].state=="attack" and s.fighters[0].move=="special")
    s=Sim.new();s.arcade_enabled=true;s.ai_enabled=false;s.phase="fight"
    s.fighters[0].x=-.5;s.fighters[1].x=.5;s.fighters[0].meter=100
    s.tick({"attack":"special"})
    s.fighters[1].state="attack";s.fighters[1].move="grab";s.fighters[1].frame=10
    s.tick()
    check("throw remains a real answer to burst startup",s.fighters[0].health==88 and s.fighters[0].state=="stun")
    FileAccess.open("res://../docs/evidence/rush-rework/arcade-rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"opening_first_hit":first,"opening_combo":max_combo},"  "))
    var passed:=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    print("RUSH_ARCADE_CHECKS ",passed,"/",checks.size());quit(0 if passed==checks.size() else 1)
