extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const OUT="res://../docs/evidence/live-combat/"
func _initialize() -> void:call_deferred("run")
func fresh(character:int,rival:int) -> RefCounted:
    var s=Sim.new();s.last_service_enabled=true;s.arcade_enabled=true;s.character_choices=[character,rival];s.reset_round();s.phase="fight";s.ai_enabled=false
    s.fighters[0].x=-.6;s.fighters[1].x=.6
    return s
func run() -> void:
    var combos:Array=[];var guard:Array=[];var neutral:Array=[]
    for character in 4:
        for gap in [1.2,1.5]:
            var s=fresh(character,(character+1)%4)
            s.fighters[0].x=-gap*.5;s.fighters[1].x=gap*.5
            var max_chain:=0;var first_three:=-1;var misses:=0;var swings:=0;var hits:=0
            for i in 180:
                s.tick({"rush":true})
                for e in s.events:
                    if e.kind=="swing" and e.target==0:swings+=1
                    if e.kind=="hit" and e.attacker==0:
                        hits+=1;max_chain=maxi(max_chain,s.combo_hits)
                        if first_three<0 and max_chain>=3:first_three=i
            combos.append({"character":character,"gap":gap,"max_chain":max_chain,"first_three_tick":first_three,"swings":swings,"hits":hits})
        for level in 3:
            var s=fresh(0,character);s.ai_enabled=true;s.difficulty=level
            var events:Dictionary={};var moves:Dictionary={};var rounds:=0
            for i in 1800:
                if s.phase!="fight":
                    rounds+=1;s.restart_match();s.phase="fight";s.fighters[0].x=-.6;s.fighters[1].x=.6
                s.tick({"guard":true,"allow_parry":false})
                for e in s.events:
                    events[e.kind]=events.get(e.kind,0)+1
                    if e.kind=="swing" and e.target==1:moves[e.move]=moves.get(e.move,0)+1
            guard.append({"character":character,"level":level,"events":events,"moves":moves,"rounds":rounds})
        var s=fresh(0,character);s.ai_enabled=true;s.difficulty=1
        var moves:Dictionary={};var idle_at_distance:=0;var frames:=0
        for i in 1200:
            if s.phase!="fight":s.restart_match();s.phase="fight"
            s.tick()
            for e in s.events:
                if e.kind=="swing" and e.target==1:moves[e.move]=moves.get(e.move,0)+1
            if s.fighters[1].state=="idle" and absf(s.fighters[0].x-s.fighters[1].x)>1.8:idle_at_distance+=1
            frames+=1
        neutral.append({"character":character,"moves":moves,"idle_at_distance":idle_at_distance,"ticks":frames})
    var label:String="before"
    for arg in OS.get_cmdline_user_args():label=arg
    FileAccess.open(OUT+label+"-probe.json",FileAccess.WRITE).store_string(JSON.stringify({"combos":combos,"guard":guard,"neutral":neutral,"scope":"Normal FIGHT Simulation rules and normal AI policy; deterministic input scenarios, rounds reset after real KO. Fixed game ticks, not wall-time FPS or fun measurement."},"  "))
    print("LIVE_PROBE ",label," completed");quit()
