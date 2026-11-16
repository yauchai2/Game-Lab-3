extends SceneTree
const S=preload("res://scripts/combat/story/story_simulation.gd")
const R=preload("res://scripts/combat/tactics/enemy_response.gd")
const OUT="res://../docs/evidence/module-counterplay/"
var checks:Array=[]
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("RESPONSE ",label," ",ok)
    if not ok:push_error(label)
func setup(role:="grunt") -> RefCounted:
    var s=S.new();s.character_choices=[1,4];s.last_service_enabled=true;s.campaign_enabled=true;s.campaign_stats={"tactic_unlocked":6};s.wave_recipes=[[role]];s.begin_story();s.arrival_left=0;s.squad_clock=12;s.next_attack_at=9999
    s.tactics.enabled=true;s.tactics.config=[s.TacticalSkills.defaults(),{}];s.tactics.config[0].attachments[1]=2
    s.fighters[0].x=0;s.fighters[1].arrival=0;s.fighters[1].x=2.8;s.fighters[1].state="idle"
    s.tactics.shots.append({"owner":0,"kind":"zone","age":8,"delay":24,"x":2.8,"radius":1.35})
    return s
func _initialize() -> void:
    for role in ["grunt","rusher","jammer","guard","captain","heavy"]:
        var s=setup(role);var f:Dictionary=s.fighters[1];var command:Dictionary=R.command(s,f)
        var step_role:bool=role in R.STEP_ROLES;var guard_role:bool=role in R.GUARD_ROLES
        check(role+" follows its published reaction role",(command.get("axis",0)!=0 if step_role else (command.get("guard",false) if guard_role else command.is_empty())))
        check(role+" reaction never grants dodge, jump or invulnerability",not command.get("dash",false) and not command.get("jump",false) and f.invuln==0)
        if not command.is_empty():check(role+" reaction cue preserves actual identity",s.events.any(func(e:Dictionary)->bool:return e.kind in ["tactic_step_out","tactic_brace"] and e.squad_id==f.squad_id))
        if guard_role:check(role+" reaction cannot auto-parry",command.get("allow_parry",true)==false)
    for excluded in ["unseen","late","airborne","stun","attack","rush","cooldown","off_cadence","other_owner","distant","no_ai","standard","arrival","boss"]:
        var s=setup();var f:Dictionary=s.fighters[1]
        match excluded:
            "unseen":s.tactics.shots[0].age=7
            "late":s.tactics.shots[0].age=24
            "airborne":f.y=1
            "stun":f.state="stun"
            "attack":f.state="attack"
            "rush":f.rush_charge=15
            "cooldown":f.tactic_response_cd=30
            "off_cadence":s.squad_clock=13
            "other_owner":s.tactics.shots[0].owner=1
            "distant":f.x=-5
            "no_ai":s.ai_enabled=false
            "standard":s.campaign_enabled=false
            "arrival":f.arrival=2
            "boss":s.CampaignRules.boss(f,"gantry")
        check(excluded+" never starts a new zone response",R.command(s,f).is_empty())
    var s=setup();var f:Dictionary=s.fighters[1];var command:Dictionary=R.command(s,f);var direction:float=command.axis
    s.tactics.shots[0].x=7.0;s.squad_clock=13;command=R.command(s,f)
    check("a committed step does not steer toward the live warning every frame",command.axis==direction)
    check("one response starts a three-second cooldown",f.tactic_response_cd==179 and s.events.filter(func(e:Dictionary)->bool:return e.kind=="tactic_step_out").size()==1)
    f.state="stun";R.command(s,f);check("taking a hit interrupts the response without refunding cooldown",f.tactic_response_left==0 and f.tactic_response_cd==178)
    s=setup();f=s.fighters[1];R.command(s,f);var ticks:int=f.tactic_response_left;var cooldown:int=f.tactic_response_cd;s.hitstop=3
    check("hitstop freezes reaction duration and cooldown",R.command(s,f).is_empty() and f.tactic_response_left==ticks and f.tactic_response_cd==cooldown)
    s=setup();f=s.fighters[1];f.x=8;s.tactics.shots[0].x=7.6;command=R.command(s,f)
    check("an edge-trapped step chooses the only inward route",command.axis<0)
    s=setup("guard");s.fighters[1].guard=20;check("exhausted guards cannot magically brace",R.command(s,s.fighters[1]).is_empty())
    s=setup();f=s.fighters[1];var active_ticks:=0
    for tick in 24:
        var response:Dictionary=R.command(s,f)
        if not response.is_empty():active_ticks+=1
    check("a step has at most twenty command ticks and no immediate repeat",active_ticks<=20 and f.tactic_response_left==0)
    s=setup();f=s.fighters[1];var health:int=f.health;var meter:float=f.meter;var x:float=f.x
    R.command(s,f);check("deciding a response cannot move a body or decide damage",f.x==x and f.health==health and f.meter==meter)
    # Real simulation integration: a warning is created by a paid I cast, and then live AI can react.
    s=setup();s.tactics.shots.clear();s.fighters[0].meter=100;s.arrival_left=99999;s._start_attack(0,"tactic_b")
    for i in 25:s.tick({})
    f=s.fighters[1];f.x=2.8;f.state="idle";f.buffer="";f.buffer_ttl=0;f.arrival=0;s.arrival_left=0;s.squad_clock=36
    var start:float=f.x;var reacted:=false
    for i in 18:
        s.tick({})
        if s.events.any(func(e:Dictionary)->bool:return e.kind=="tactic_step_out"):reacted=true
    check("real delayed cast reaches a real walking response",reacted and absf(f.x-start)>.1 and s.fighters[0].meter==75)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"  "));quit(1 if failed else 0)
