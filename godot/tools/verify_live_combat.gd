extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Agent=preload("res://scripts/combat/rush_agent.gd")
const Rhythm=preload("res://scripts/combat/combat_rhythm.gd")
const OUT="res://../docs/evidence/live-combat/"
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("LIVE_COMBAT ",label," ",ok)
    if not ok:push_error(label)
func fresh(character:=0,rival:=1) -> RefCounted:
    var s=Sim.new();s.last_service_enabled=true;s.arcade_enabled=true;s.character_choices=[character,rival];s.reset_round();s.phase="fight";s.ai_enabled=false
    s.fighters[0].x=-.6;s.fighters[1].x=.6
    return s
func run() -> void:
    var before:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"before-probe.json"))
    var after:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"after-probe.json"))
    for trial in after.combos:
        check("close held-J ground chain reaches launcher for %d at %.1f"%[trial.character,trial.gap],trial.first_three_tick>=0 and trial.first_three_tick<60)
    var old_loop:Array=before.combos.filter(func(t:Dictionary)->bool:return t.character==3)
    check("LOOP regression was reproduced before tuning",old_loop.all(func(t:Dictionary)->bool:return t.first_three_tick==-1 and t.max_chain==2))
    for trial in after.guard:
        check("normal AI punishes held guard with actual throw starts %d/%d"%[trial.character,trial.level],trial.moves.get("grab",0)>0)
    check("old guard policy had no throw attempts in all twelve scenarios",before.guard.all(func(t:Dictionary)->bool:return t.moves.get("grab",0)==0))
    for character in 4:
        var s=fresh(0,character);s.ai_enabled=true;s.difficulty=1
        s.fighters[1].meter=0;s.fighters[0].x=-1.125;s.fighters[1].x=1.125
        var hit:=false;var action:=false;var unpaid:=false
        for i in 100:
            s.tick()
            for e in s.events:
                if e.kind=="swing" and e.target==1:action=true
                if e.kind=="hit" and e.attacker==1:hit=true
                if e.kind=="no_meter" and e.target==1:unpaid=true
        check("unfunded character %d closes and fights instead of idling"%character,action and hit and not unpaid)
    var s=fresh();s.fighters[0].x=-.45;s.fighters[1].x=.45
    s.fighters[0].guarding=true;s.fighters[0].guard_frames=30
    var agent=Agent.new();var decision:Dictionary=agent.choose(s,1,20,1)
    check("held guard creates a committed legal throw",decision.get("attack","")=="grab" and agent.intent[1]=="throw_guard")
    var snapshot:Dictionary=agent.plans[1].duplicate(true)
    s.fighters[0].guarding=false;s.fighters[0].state="attack";s.fighters[0].move="jab";s.fighters[0].frame=0
    var next:Dictionary=agent.choose(s,1,21,1)
    check("opponent change cannot replace a committed plan",agent.plans[1]==snapshot and not next.has("attack"))
    s=fresh();var twin=fresh()
    s.fighters[0].buffer="light";twin.fighters[0].buffer="overdrive"
    var a=Agent.new();var b=Agent.new()
    check("hidden buffered player intent cannot change AI choice",a.choose(s,1,25,1)==b.choose(twin,1,25,1))
    s=fresh();agent=Agent.new();agent.plans[1]={"guard":true,"axis":0.0};agent.plan_until[1]=80
    s.hitstop=8
    check("AI holds guard continuously through contact freeze",agent.choose(s,1,20,1).get("guard",false))
    s.hitstop=0;s.fighters[1].state="blockstun";s.fighters[1].stun=6
    check("blockstun cannot silently release an existing guard plan",agent.choose(s,1,21,1).get("guard",false))
    s=fresh();s.ai_enabled=true;s.difficulty=1;s.fighters[0].x=-.45;s.fighters[1].x=.45
    var throw_hit:=false
    for i in 180:
        s.tick({"guard":true,"allow_parry":false})
        for e in s.events:
            if e.kind=="hit" and e.attacker==1 and e.move=="grab":throw_hit=true
    check("CPU throw damages a real guarding opponent",throw_hit and s.fighters[0].health<100)
    s=fresh();s.ai_enabled=true;s.difficulty=1;s.fighters[0].x=-.45;s.fighters[1].x=.45
    var dodged:=false;var caught:=false;var jumped:=false
    for i in 120:
        var rival:Dictionary=s.fighters[1]
        var command:Dictionary={"guard":true,"allow_parry":false}
        if rival.state=="attack" and rival.move=="grab":
            command={"jump":true,"allow_parry":false};jumped=true
        s.tick(command)
        for e in s.events:
            if e.kind=="hit" and e.attacker==1 and e.move=="grab":caught=true
        if jumped and rival.state=="idle" and not caught:dodged=true;break
    check("jump still avoids the committed throw by position",jumped and dodged and not caught)
    s=fresh();s.fighters[1].x=2.0;s.ai_enabled=true
    # A published recovery fixture: the AI must still start a normal attack to punish it.
    s.fighters[0].state="attack";s.fighters[0].move="heavy";s.fighters[0].frame=24;s.fighters[0].connected=false
    s.fighters[0].x=.5
    var punish:Dictionary=s.rush_agent.choose(s,1,20,1)
    check("whiff recovery is met with a normal punish input",s.rush_agent.intent[1]=="punish_recovery" and punish.get("attack","")=="light")
    s.rush_agent.plans[1]={"attack":"overdrive"};s.restart_match()
    check("new rounds clear AI commitments and burst history",s.rush_agent.plans==[{},{}] and s.rush_agent.last_cannon==[-600,-600])
    s=fresh();agent=Agent.new()
    var choices:Dictionary={}
    for serial in 4:
        s.air_counter.begin(1)
        s.air_counter.serial=serial+1
        var response:Dictionary=agent.choose(s,1,100,2)
        choices[response.air_choice]=choices.get(response.air_choice,0)+1
        s.air_counter.reset()
    check("air counter choices vary by exchange instead of locking to a global beat",choices.get("kick",0)==3 and choices.get("escape",0)==1)
    s=fresh();s.fighters[0].state="attack";s.fighters[0].move="jab";s.fighters[0].frame=1;s.fighters[1].guard=30
    agent=Agent.new();var retreat:Dictionary=agent.choose(s,1,20,1)
    check("low guard retreats with a legal dash rather than defending to break",retreat.get("dash",false) and retreat.get("axis",0.0)>0 and agent.intent[1]=="recover_guard")
    var rhythm=Rhythm.new();rhythm.trigger("parry",0)
    var bounded:=true;var drained:=0
    for i in 30:
        var steps:int=rhythm.take_steps(1.0/60,true,true)
        drained+=steps;bounded=bounded and steps>=1 and steps<=2 and rhythm.bank>=0 and rhythm.bank<1.001
    check("native freeze drains without slow-motion double stretching",bounded and drained>=30)
    var old_latency:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"before-latency.json"))
    var new_latency:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"after-latency.json"))
    for i in old_latency.fixtures.size():
        var old:Dictionary=old_latency.fixtures[i];var updated:Dictionary=new_latency.fixtures[i]
        check("contact resumes earlier for %s at SURGE %d"%[old.contact,old.surge],updated.first_live_action_wall_frames<old.first_live_action_wall_frames and updated.native_hitstop_ticks==old.native_hitstop_ticks)
    s=fresh();twin=fresh();s.ai_enabled=true;twin.ai_enabled=true
    a=Agent.new();b=Agent.new();var same:=true
    for i in 12000:
        if s.phase!="fight":s.restart_match();s.phase="fight";twin.restart_match();twin.phase="fight";a.reset();b.reset()
        var cmd_a:Dictionary=a.choose(s,0,s.ai_tick,1)
        var cmd_b:Dictionary=b.choose(twin,0,twin.ai_tick,1)
        s.tick(cmd_a);twin.tick(cmd_b)
        same=same and cmd_a==cmd_b and s.fighters==twin.fighters and s.events==twin.events and s.rush_agent.plans==twin.rush_agent.plans
    check("twelve thousand competitive-policy steps replay identically",same)
    var passed:int=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"total":checks.size(),"checks":checks,"engine":Engine.get_version_info().string,"scope":"Normal FIGHT policy and rules, deterministic controlled-input scenarios plus explicit unit fixtures. Not human fun validation."},"  "))
    quit(0 if passed==checks.size() else 1)
