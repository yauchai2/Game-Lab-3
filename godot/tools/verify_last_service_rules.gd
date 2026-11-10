extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Growth=preload("res://scripts/combat/last_service/progression.gd")
const OUT="res://../docs/evidence/last-service-runtime/rules.json"
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(name:String,passed:bool,detail:Variant=null) -> void:
    checks.append({"check":name,"pass":passed,"detail":detail});print("SERVICE ",name," ",passed," ",detail)
func fresh(a:=0,b:=1) -> RefCounted:
    var s:=Sim.new();s.last_service_enabled=true;s.arcade_enabled=true;s.character_choices=[a,b];s.reset_round();s.phase="fight";s.ai_enabled=false
    s.fighters[0].x=-.5;s.fighters[1].x=.5
    s.fighters[0].meter=100;s.fighters[1].meter=100
    return s
func step(s:RefCounted,count:int,a:Dictionary={},b:Dictionary={}) -> void:
    for i in count:s.tick(a,b)
func skill_energy(character:int,perk_id:String) -> float:
    var sim=fresh(character,1 if character!=1 else 0)
    sim.fighters[0].meter=70
    if perk_id!="":sim.fighters[0].perks=[perk_id]
    var attack:="special"
    if character==2:sim.fighters[0].service.sample=1;sim.fighters[0].service.sample_ttl=240
    if character==3:
        sim.fighters[0].meter=30;sim.fighters[0].service.nodes=[{"x":.5,"life":300,"id":1}];attack="node_pulse"
    sim.tick({"attack":attack});step(sim,120)
    return sim.fighters[0].meter
func blocked_guard(perk_id:String) -> float:
    var sim=fresh(1,0)
    if perk_id!="":sim.fighters[0].perks=[perk_id]
    sim.tick({"attack":"jab"},{"guard":true,"allow_parry":false});step(sim,35,{}, {"guard":true,"allow_parry":false})
    return sim.fighters[1].guard
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
    var s=fresh(0,1);s.tick({"attack":"special"});var hit_count:=0
    for frame in 120:
        s.tick()
        for event in s.events:
            if event.kind=="hit" and event.move=="special":hit_count+=1
    check("ZIP confirmed two-kick skill deals bounded real damage",hit_count==2 and s.fighters[1].health>=78 and s.fighters[1].health<90,{"hits":hit_count,"health":s.fighters[1].health})
    s=fresh(0,1);s.tick({"attack":"overdrive"});hit_count=0
    for frame in 200:
        s.tick()
        for event in s.events:
            if event.kind=="hit" and event.move=="overdrive":hit_count+=1
    check("ZIP overdrive confirms at most three legal contacts",hit_count==3 and s.fighters[1].health>=59 and s.fighters[1].health<75,{"hits":hit_count,"health":s.fighters[1].health})
    s=fresh(0,1);s.fighters[1].x=7;s.tick({"attack":"overdrive"});step(s,180)
    check("ZIP whiff does not auto-track or damage",s.fighters[1].health==100 and s.fighters[0].meter==25)
    s=fresh(0,1);s.fighters[0].x=-1;s.fighters[1].x=.5
    s.fighters[1].face=-1;s._start_attack(1,"jab");s.fighters[1].frame=4;s.tick({"dash":true,"axis":-1})
    check("ZIP genuine dodge earns a route",s.fighters[0].service.routes==1,s.fighters[0].service)
    var before:int=s.fighters[0].service.routes;step(s,2)
    check("Same enemy swing cannot generate repeated routes",s.fighters[0].service.routes==before)
    s.fighters[0].state="idle";s.fighters[0].dash_cd=0;s.tick({"dash":true})
    check("Route is spent on a legal dash",s.fighters[0].service.routes==0 and s.fighters[0].dash_cd<=30)
    s=fresh(1,0);s.tick({"attack":"special","skill_held":true});step(s,50,{"skill_held":true})
    check("RIVET hold reaches visible tier two",s.fighters[0].service.preload==2,s.fighters[0].service.preload)
    step(s,100)
    check("RIVET tier-two strike hits with a long recovery budget",s.fighters[1].health<=67 and s.move_for(s.fighters[0],"special").recovery>=38,s.fighters[1].health)
    s=fresh(1,0);s.fighters[1].x=7;s.tick({"attack":"special"});step(s,30,{"skill_held":true});s.fighters[0].state="stun";s.fighters[0].stun=30;step(s,20,{"skill_held":true})
    check("Interrupted RIVET cannot damage during hold",s.fighters[1].health==100)
    s=fresh(0,2);s._start_attack(0,"jab");s.fighters[0].frame=4;s.tick({}, {"guard":true,"guard_pressed":true})
    check("HUSH real frontal parry stores one sample",s.fighters[1].service.sample==1,s.events)
    s.fighters[1].state="idle";s._start_attack(1,"special")
    check("HUSH sample is spent on a stronger normal counter",s.fighters[1].service.sample==0 and s.move_for(s.fighters[1],"special").damage==22)
    s=fresh(2,0);s.tick({"attack":"special"});step(s,100)
    check("HUSH is usable without first earning a sample",s.fighters[1].health<100,s.fighters[1].health)
    s=fresh(3,0);s.fighters[0].x=-3;s.fighters[1].x=3;s.tick({"attack":"special"});step(s,60)
    check("LOOP placement costs20 and creates one real node without a fake hit",s.fighters[0].meter==80 and s.fighters[0].service.nodes.size()==1 and s.fighters[1].health==100)
    s.tick({"attack":"special"});step(s,60);s.tick({"attack":"special"});step(s,60)
    check("Third LOOP placement replaces oldest, maximum two",s.fighters[0].service.nodes.size()==2)
    s.fighters[1].x=s.fighters[0].service.nodes[0].x;s.fighters[0].state="idle";s.tick({"attack":"special","down":true});step(s,65)
    check("Manual LOOP pulse spends10, clears nodes and deals real damage",s.fighters[0].service.nodes.is_empty() and s.fighters[1].health==88 and s.fighters[0].meter<50,s.fighters[1].health)
    s=fresh(3,0);s.fighters[0].service.nodes=[{"x":.5,"life":300,"id":1}]
    s.tick({"attack":"node_pulse"},{"guard":true,"allow_parry":false});step(s,40,{}, {"guard":true,"allow_parry":false})
    check("LOOP pulse is blockable",s.fighters[1].health==100 and s.fighters[1].guard<100,{"health":s.fighters[1].health,"guard":s.fighters[1].guard})
    s=fresh(3,0);s.fighters[0].service.nodes=[{"x":.3,"life":300,"id":1}];s.fighters[1].face=-1;s._start_attack(1,"jab");s.fighters[1].frame=4;s.tick()
    check("Opponent can destroy a LOOP node with an active strike",s.fighters[0].service.nodes.is_empty())
    s=fresh(3,0);s.fighters[0].service.nodes=[{"x":3,"life":1,"id":1}];s.tick()
    check("LOOP nodes expire on simulation time",s.fighters[0].service.nodes.is_empty())
    s=fresh(3,0);s.fighters[0].service.nodes=[{"x":1.1,"life":300,"id":1}]
    s._start_attack(0,"node_pulse");s.fighters[0].frame=7;s._start_attack(1,"jab");s.fighters[1].frame=4;s.tick()
    check("Simultaneous node pulse and ordinary jab can trade",s.fighters[0].health<100 and s.fighters[1].health<100,{"health":[s.fighters[0].health,s.fighters[1].health]})
    s=fresh(3,0);s.fighters[0].x=0;s.fighters[1].x=0;s.fighters[0].y=1.6;s._start_attack(0,"special");s.fighters[0].frame=13;s.tick()
    check("Airborne LOOP placement has no zero-damage body hit",s.fighters[1].health==100 and s.fighters[1].state=="idle")
    s=fresh(0,1);s._start_attack(0,"overdrive");s.fighters[0].frame=1;s._start_attack(1,"jab");s.fighters[1].frame=4;s.tick()
    check("ZIP does not inherit generic full-startup armor",s.fighters[0].state=="stun")
    s=fresh(1,0);s._start_attack(0,"overdrive");s.fighters[0].frame=32;s._start_attack(1,"jab");s.fighters[1].frame=4;s.tick()
    check("RIVET late startup armor still takes damage",s.fighters[0].state=="attack" and s.fighters[0].health<100)
    s=fresh(1,0);s._start_attack(0,"overdrive");s.fighters[0].frame=10;s._start_attack(1,"jab");s.fighters[1].frame=4;s.tick()
    check("RIVET early startup remains interruptible",s.fighters[0].state=="stun")
    s=fresh(1,0);s._start_attack(0,"overdrive");s.fighters[0].frame=32;s._start_attack(1,"grab");s.fighters[1].frame=10;s.tick()
    check("Throw beats RIVET late armor",s.fighters[0].state=="stun")
    s=fresh(3,2);s.fighters[0].service.nodes=[{"x":.5,"life":300,"id":1}];s.tick({"attack":"node_pulse"},{"guard":true,"guard_pressed":true});step(s,12,{}, {"guard":true})
    check("HUSH can parry a remote pulse but does not sample it",s.fighters[1].health==100 and s.fighters[1].service.sample==0)
    s=fresh(3,0);s.fighters[0].service.nodes=[{"x":.5,"life":300,"id":1},{"x":1.0,"life":300,"id":2}];s.tick({"attack":"overdrive"})
    check("Encore keeps pending nodes visible and destructible",s.fighters[0].service.nodes.size()==2 and s.fighters[0].service.encore.size()==2)
    var pulse_count:=0
    for frame in 200:
        s.tick()
        for event in s.events:
            if event.kind=="node_pulse_fx":pulse_count+=1
    check("Encore consumes at most two real nodes without unbounded damage",pulse_count==2 and s.fighters[0].service.nodes.is_empty() and s.fighters[1].health>=52,{"pulses":pulse_count,"health":s.fighters[1].health})
    var path:="/tmp/last-service-growth-test.cfg"
    for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(path+suffix)
    var g:=Growth.new();g.path=path
    check("New player has four characters and no locked base mechanics",g.records.size()==4 and g.points(0)==0)
    var first:int=g.reward(0,"real-result-1",true,0);var duplicate:int=g.reward(0,"real-result-1",true,0)
    check("First victory grants a point once",first==40 and duplicate==0 and g.level(0)==1 and g.points(0)==1)
    check("Skill unlock consumes a point and can equip",g.unlock(0,0) and g.toggle(0,0) and g.points(0)==0 and g.equipped(0).size()==1)
    g.reward(0,"real-result-2",true,0);g.unlock(0,1);g.toggle(0,1);g.reward(0,"real-result-3",true,0);g.unlock(0,2)
    check("At most two skills can be equipped",not g.toggle(0,2) and g.equipped(0).size()==2)
    g.toggle_palette(0)
    var loaded:=Growth.new();loaded.path=path;loaded.load_data()
    check("XP, purchases, slots and cosmetic choice survive reload",loaded.records==g.records and loaded.records.zip.palette)
    loaded.respec(0)
    check("Respec returns spent points without erasing XP",loaded.points(0)==3 and loaded.equipped(0).is_empty() and loaded.records.zip.xp==120)
    # Same match state, with and without a run-only skill.
    s=fresh(0,1);var base_damage:int=s.move_for(s.fighters[0],"jab").damage
    s.fighters[0].perks=["zip_confirm"]
    check("ZIP skill point does not alter raw jab damage",s.move_for(s.fighters[0],"jab").damage==base_damage)
    s=fresh(3,0);s.fighters[0].perks=["loop_life"];s.fighters[0].x=-3;s.fighters[1].x=3;s.tick({"attack":"special"});step(s,30)
    check("LOOP equipped life skill extends actual placed node",s.fighters[0].service.nodes[0].life>390)
    s=fresh(3,0);s.fighters[0].perks=["loop_cycle"];s.fighters[0].service.nodes=[{"x":.5,"life":300,"id":1}];s.tick({"attack":"node_pulse"});step(s,18)
    check("LOOP equipped cooldown skill changes actual pulse lockout",s.fighters[0].service.node_cd<=60 and s.fighters[0].service.node_cd>0)
    s=fresh(1,0);s.fighters[0].perks=["rivet_fast"];s.tick({"attack":"special"});step(s,33,{"skill_held":true})
    check("RIVET equipped charge skill reaches second tier sooner",s.fighters[0].service.preload==2 and s.fighters[0].service.preload_age<30)
    s.fighters[0].perks=["rivet_recover"];check("RIVET equipped recovery skill changes charged recovery",s.move_for(s.fighters[0],"special").recovery==38)
    s=fresh(0,2);s.fighters[1].perks=["hush_hold"];s._start_attack(0,"jab");s.fighters[0].frame=4;s.tick({}, {"guard":true,"guard_pressed":true})
    check("HUSH equipped memory skill extends actual parry sample",s.fighters[1].service.sample_ttl==360)
    s.fighters[1].perks=["hush_recover"];s.fighters[1].state="idle";s._start_attack(1,"special")
    check("HUSH equipped recovery skill changes sampled move",s.move_for(s.fighters[1],"special").recovery==26)
    s=fresh(0,1);s.fighters[0].perks=["zip_dash"];s.fighters[0].service.routes=1;s.fighters[0].service.route_ttl=60;s.tick({"dash":true})
    check("ZIP equipped dash skill changes the paid route dash",s.fighters[0].dash_cd==24 and s.fighters[0].service.routes==0)
    check("ZIP confirmed-kick refund is once per attack",is_equal_approx(skill_energy(0,"zip_confirm")-skill_energy(0,""),4.0))
    check("HUSH sampled-hit refund actually grants five energy",is_equal_approx(skill_energy(2,"hush_gain")-skill_energy(2,""),5.0))
    check("LOOP pulse refund actually grants four energy",is_equal_approx(skill_energy(3,"loop_gain")-skill_energy(3,""),4.0))
    check("RIVET pressure skill adds five real guard drain",is_equal_approx(blocked_guard("")-blocked_guard("rivet_guard"),5.0))
    s=fresh(0,1);s.fighters[0].perks=["zip_route"];s.fighters[0].x=-1;s.fighters[1].x=.5;s.fighters[1].face=-1;s._start_attack(1,"jab");s.fighters[1].frame=4;s.tick({"dash":true,"axis":-1})
    check("ZIP route skill extends a genuinely earned route",s.fighters[0].service.routes==1 and s.fighters[0].service.route_ttl==300)
    for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(path+suffix)
    FileAccess.open(OUT,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"scope":"Fixed-step new-character mechanics and versioned local progression, not visual/performance proof."},"  "))
    s=null;g=null;loaded=null
    await process_frame
    call_deferred("quit",0 if checks.all(func(row:Dictionary)->bool:return row.pass) else 1)
