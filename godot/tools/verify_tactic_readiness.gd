extends SceneTree
const S=preload("res://scripts/combat/story/story_simulation.gd")
const View=preload("res://scripts/combat/tactics/presentation.gd")
const OUT="res://../docs/evidence/tactics-usability/"
var checks:Array=[]
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("READINESS ",label," ",ok)
    if not ok:push_error(label)
func setup(hero:int,id:int) -> RefCounted:
    var s=S.new();s.last_service_enabled=true;s.character_choices=[hero,4];s.campaign_enabled=true;s.campaign_stats={"tactic_unlocked":6};s.wave_recipes=[["grunt"]];s.begin_story();s.arrival_left=99999
    s.tactics.enabled=true;s.tactics.config=[s.TacticalSkills.defaults(),{}];s.tactics.config[0].skills=[id,0 if id!=0 else 1]
    s.fighters[0].meter=100;s.fighters[1].x=7
    return s
func ticks(s:RefCounted,count:int,command:Dictionary={}) -> void:
    for i in count:s.tick(command)
func _initialize() -> void:
    root.get_node("GameLocale").set_language("en")
    var s=setup(3,4);var f:Dictionary=s.fighters[0];var view:Dictionary=View.slot_view(s,0)
    check("missing nodes explain the prerequisite before a wasted key",not view.ready and view.text=="PLACE NODES 0/2")
    var reason:String=s.tactics.quote(s,0,0).reason;s.tick({"attack":"tactic_a"})
    check("HUD and rejected cast use the same condition",s.events.any(func(e:Dictionary)->bool:return e.kind=="tactic_unavailable" and e.reason==reason) and f.meter==100)
    s=setup(0,4);f=s.fighters[0]
    for routes in 2:
        f.service.routes=routes;view=View.slot_view(s,0)
        check("route%d readiness shows the actual bank"%routes,not view.ready and view.text=="DODGE / ROUTES %d/2"%routes)
    f.service.routes=2;check("two routes enable the paid cast",View.slot_view(s,0).ready)
    s=setup(0,2);f=s.fighters[0];check("dive tells grounded players to jump",View.slot_view(s,0).text=="JUMP TO DIVE")
    f.y=1;f.air.fast_used=true;check("spent air budget asks for a landing",View.slot_view(s,0).text=="DIVE USED / LAND FIRST")
    f.air.fast_used=false;check("legal air dive reports its fee",View.slot_view(s,0).ready and View.slot_view(s,0).text=="20 ENERGY")
    s=setup(1,0);f=s.fighters[0];f.meter=10;check("energy shortage displays actual required fee",not View.slot_view(s,0).ready and View.slot_view(s,0).text=="NEED 20 ENERGY")
    f.tactic_economy=.2;check("readiness fee respects equipped economy",View.slot_view(s,0).text=="NEED 16 ENERGY")
    f.meter=100;f.tactic_unlocked=0;check("locked slot gives its specific milestone",View.slot_view(s,0).text=="LEARN / CLEAR 1")
    s=setup(3,2);f=s.fighters[0];f.y=1;check("ground-only cast explains landing",View.slot_view(s,0).text=="LAND TO CAST")
    s=setup(1,4);f=s.fighters[0];check("vent prompts the real L preparation",View.slot_view(s,0).text=="HOLD L TO PRELOAD")
    s._start_attack(0,"special");ticks(s,20,{"skill_held":true});f.meter=0
    check("vent readiness includes exactly the paid L credit",View.slot_view(s,0).ready and View.slot_view(s,0).text=="CONVERT L / 20 ENERGY")
    s.tick({"attack":"tactic_a","skill_held":true});check("quoted L credit transfers into one fee",f.move=="tactic_a" and f.meter==30)
    s=setup(1,0);f=s.fighters[0];f.tactic_economy=.2;s.tick({"attack":"tactic_a","tactic_a_held":true})
    check("charge displays the discounted optional surcharge",View.slot_view(s,0).text=="HOLD / +8 ENERGY")
    f.meter=0;check("charge never promises an unaffordable full tier",View.slot_view(s,0).text=="RELEASE / QUICK SHOT")
    s=setup(2,1);f=s.fighters[0];f.tactical.return_ready=90;f.service.sample=1;f.service.sample_ttl=240;f.tactical.cd[0]=200;f.meter=0
    view=View.slot_view(s,0);check("sample return is bright and free despite cooldown and empty meter",view.ready and view.text=="RETURN / 0 ENERGY" and view.progress==1)
    s.tick({"attack":"tactic_a"});check("free sample quote matches actual zero-fee cast",f.move=="tactic_a" and f.meter==0)
    s=setup(3,4);f=s.fighters[0];f.service.nodes=[{"x":2.0,"life":100,"id":1,"emitter":true},{"x":2.0,"life":100,"id":2,"emitter":true,"hidden":true}];f.tactical.cd[0]=300;f.meter=0
    view=View.slot_view(s,0);check("emitter readiness bypasses original fee and cooldown",view.ready and view.text=="EMITTER READY / FIRE")
    f.state="stun";f.stun=5;check("interrupted emitter cannot advertise a free immediate action",not View.slot_view(s,0).ready)
    s=setup(2,3);f=s.fighters[0];s.fighters[1].x=1;s.tick({"attack":"tactic_a"});ticks(s,12)
    f.meter=0;view=View.slot_view(s,0);check("confirmed chain is shown as a free actionable followup",view.ready and view.text=="FOLLOW / 0 ENERGY" and view.progress>0)
    s.tick({"attack":"tactic_a"});check("highlighted followup actually advances without a second fee",f.tactical.chain_stage==1 and f.meter==0)
    f.state="stun";f.stun=20;check("interruption closes confirmed chain readiness immediately",not s.tactics.Expanded.follow_ready(f,3) and not View.slot_view(s,0).ready)
    s=setup(0,5);f=s.fighters[0];s.tick({"attack":"tactic_a"});ticks(s,6)
    check("running skill advertises manual braking despite cooldown",View.slot_view(s,0).ready and View.slot_view(s,0).text=="PRESS AGAIN TO STOP")
    s=setup(1,2);f=s.fighters[0];f.guarding=true;check("held guard does not falsely advertise a cast",not View.slot_view(s,0).ready and View.slot_view(s,0).text=="RELEASE GUARD TO CAST")
    f.guarding=false;f.state="stun";check("recovery gives a distinct non-resource hint",not View.slot_view(s,0).ready and View.slot_view(s,0).text=="RECOVERING")
    for hero in 4:
        for id in 6:
            s=setup(hero,id);f=s.fighters[0];f.service.routes=2;f.service.preload=2;f.service.nodes=[{"x":2.0,"life":300,"id":1},{"x":4.0,"life":300,"id":2}]
            if hero==0 and id==2:f.y=1
            s.tactics.config[0].supports[id]=1;f.tactic_anchor=true
            var predicted:int=s.TacticalSkills.cooldown_ticks(hero,id,1,true)
            s._start_attack(0,"tactic_a")
            check("hero%d skill%d page cooldown matches actual support and equipment"%[hero,id],f.tactical.cd[0]==predicted and f.tactical.cd_total[0]==predicted)
    s=setup(1,2);f=s.fighters[0];s.tick({"attack":"tactic_a"});ticks(s,35)
    view=View.slot_view(s,0);var progress:float=view.progress;s.tick({});check("cooldown progress advances without wall-clock guessing",View.slot_view(s,0).progress>progress and not view.ready)
    var snapshot:String=JSON.stringify(f);View.slot_view(s,0);check("HUD reads never mutate simulation",JSON.stringify(f)==snapshot)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"readiness.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"  "));quit(1 if failed else 0)
