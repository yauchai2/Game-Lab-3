extends SceneTree
const Squad=preload("res://scripts/combat/enemies/squad_simulation.gd")
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(name:String,passed:bool,detail:Variant=null) -> void:
    checks.append({"name":name,"passed":passed,"detail":detail});print("SQUAD ",name," ",passed," ",detail)
func fresh(level:=1,character:=0) -> RefCounted:
    var s=Squad.new();s.last_service_enabled=true;s.arcade_enabled=true;s.character_choices=[character,4]
    s.difficulty=level;s.restart_match();s.begin_squad();s.phase="fight";s.ai_enabled=false
    return s
func run() -> void:
    for level in 3:
        var s=fresh(level)
        check("difficulty creates independent live enemies %d"%level,s.squad_members.size()==[3,4,5][level] and s.remaining_enemies()==[3,4,5][level])
        var original:int=s.squad_members[1].health;s.squad_members[0].health-=1
        check("enemy health is independent %d"%level,s.squad_members[1].health==original)
        check("group damage is below solo enemy damage %d"%level,s.move_for(s.squad_members[0],"jab").damage<7 and s.move_for(s.squad_members[0],"jab").startup>5)
        s=fresh(level);s.ai_enabled=true
        var attacks:=0;var hits:=0;var finite:=true
        for tick in 2400:
            var input:Dictionary=s.rush_agent.choose(s,0,s.ai_tick,1)
            s.tick(input)
            var active:int=s.squad_members.filter(func(f:Dictionary)->bool:return f.health>0 and f.state=="attack").size()
            attacks=maxi(attacks,active)
            for f in s.squad_members:finite=finite and is_finite(f.x) and is_finite(f.y) and f.health>=0 and f.health<=f.max_health
            for event in s.events:
                if event.kind=="hit":hits+=1
            if s.phase=="match_over":break
        check("coordinator allows at most one attacker %d"%level,attacks<=1 and hits>0,{"max_attackers":attacks,"hits":hits,"winner":s.winner})
        check("all live enemy states remain bounded %d"%level,finite)
        s=fresh(level);s.ai_enabled=true
        var incoming:=0;var minimum_gap:=999;var last_hit:=-999
        for tick in 1200:
            s.tick()
            for event in s.events:
                if event.kind=="hit" and event.target==0:
                    incoming+=1
                    if last_hit>=0:minimum_gap=mini(minimum_gap,s.squad_clock-last_hit)
                    last_hit=s.squad_clock
            if s.phase=="match_over":break
        check("idle player is threatened by real attacks %d"%level,incoming>0,incoming)
        check("damage leaves a fair breathing interval %d"%level,minimum_gap>=[60,45,30][level],minimum_gap)
    # Everyone is in the same real hit range: a normal sweep can strike all of them.
    var s=fresh(0,1);s.fighters[0].x=0.0
    for id in s.squad_members.size():s.squad_members[id].x=.9+id*.12
    s._start_attack(0,"heavy")
    var counts:Dictionary={}
    for tick in 90:
        s.tick()
        for event in s.events:
            if event.kind=="hit" and event.attacker==0:counts[event.squad_id]=counts.get(event.squad_id,0)+1
    check("one sweep contacts multiple live opponents",counts.size()==3,counts)
    check("one strike cannot damage one member repeatedly",counts.values().all(func(n:int)->bool:return n==1),counts)
    s=fresh(0);var reserve:Dictionary=s.squad_members[1]
    reserve.x=5.0;reserve.y=1.0;reserve.state="stun";reserve.stun=999;reserve.air.combo_left=1
    s.tick()
    check("waiting member retains bounded air-combo escape",reserve.air.combo_left==0 and reserve.state!="stun")
    check("waiting member events identify their actual model",s.events.any(func(e:Dictionary)->bool:return e.kind=="air_escape" and e.get("squad_id",-1)==1))
    s=fresh(0,3);s.fighters[0].x=0.0;s.fighters[0].meter=100
    for id in s.squad_members.size():s.squad_members[id].x=.5+id*.12
    s.fighters[0].service.nodes=[{"x":-.5,"life":300,"id":1},{"x":2.0,"life":300,"id":2}]
    s.tick({"attack":"node_pulse"})
    for tick in 24:s.tick()
    check("LOOP pulse damages every real member in range",s.squad_members.all(func(f:Dictionary)->bool:return f.health<35))
    s=fresh();s.squad_members[0].health=0;s._finish_round()
    check("defeating one member does not finish the encounter",s.phase=="fight" and s.remaining_enemies()==3)
    for member in s.squad_members:member.health=0
    s._finish_round()
    check("victory requires defeating the full squad",s.phase=="match_over" and s.winner==0)
    s=fresh();s.fighters[0].health=0;s._finish_round()
    check("player KO ends the group encounter",s.phase=="match_over" and s.winner==1)
    s=fresh();s.remaining=0;s._finish_round()
    check("timer ends encounter without silently despawning enemies",s.phase=="match_over" and s.winner==1 and s.remaining_enemies()==4)
    s=fresh();s.end_squad();s.restart_match()
    check("ordinary two-person fight restores after group mode",not s.squad_enabled and s.fighters.size()==2 and s.fighters[1].health==100)
    for character in 4:
        s=fresh(0,character);s.ai_enabled=true
        for tick in 360:
            s.tick({"rush":true,"axis":1.0})
            if s.phase=="match_over":break
        check("hero %d supports squad rules and own resources"%character,s.fighters[0].character==character and s.fighters[0].service.has("nodes"))
    FileAccess.open("res://../docs/evidence/black-suit-squad/rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"scope":"Deterministic group fixture/rule checks and legal-AI samples; not human difficulty validation."},"  "))
    quit(0 if checks.all(func(c:Dictionary)->bool:return c.passed) else 1)
