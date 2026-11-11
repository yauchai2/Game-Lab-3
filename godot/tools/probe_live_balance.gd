extends SceneTree
func _initialize() -> void:
    var Sim=load("res://scripts/combat/fight_simulation.gd")
    var Demo=load("res://scripts/combat/demo_director.gd")
    var d=Demo.new();var s=Sim.new();d.prepare(s)
    var choices:={};var stale:=0
    for i in 7200:
        var commands:Array=d.commands(s);s.tick(commands[0],commands[1]);d.observe(s)
        if s.air_counter.active() and s.hitstop>0:stale+=1
        for e in s.events:
            if e.kind=="air_counter_choice":choices[e.choice]=choices.get(e.choice,0)+1
    print("AIR_CHOICES ",choices," stale-hitstop steps ",stale)
    print("DEMO_BALANCE ",d.hits," / ",d.seen)
    for level in 3:
        s=Sim.new();s.arcade_enabled=true;s.difficulty=level;s.restart_match()
        var first:=-1;var moves:={}
        for i in 600:
            s.tick({"rush":true})
            for e in s.events:
                if e.kind=="hit" and e.attacker==0:
                    if first<0:first=i
                    moves[e.move]=moves.get(e.move,0)+1
            if s.phase in ["round_over","match_over"]:break
        print("BEGINNER ",level," ",first," ",s.winner," ",moves," health ",s.fighters[0].health," / ",s.fighters[1].health)
    quit()
