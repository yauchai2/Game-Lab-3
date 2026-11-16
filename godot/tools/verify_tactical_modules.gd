extends SceneTree
const S=preload("res://scripts/combat/story/story_simulation.gd")
const P=preload("res://scripts/combat/city/city_profile.gd")
const OUT="res://../docs/evidence/tactical-modules/"
var checks:Array=[]
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("MODULES ",label," ",ok)
    if not ok:push_error(label)
func setup(hero:int,id:int,module:int) -> RefCounted:
    var s=S.new();s.ai_enabled=false;s.last_service_enabled=true;s.character_choices=[hero,4];s.campaign_enabled=true;s.campaign_stats={"tactic_unlocked":6};s.wave_recipes=[["grunt","grunt"]];s.begin_story();s.arrival_left=99999
    s.tactics.enabled=true;s.tactics.config=[s.TacticalSkills.defaults(),{}];s.tactics.config[0].skills=[id,0 if id!=0 else 1];s.tactics.config[0].attachments[id]=module
    s.fighters[0].meter=100;s.fighters[0].x=0;s.fighters[0].face=1
    for target in s.squad_members:target.x=7;target.health=500;target.max_health=500
    return s
func step(s:RefCounted,count:int) -> Array:
    var events:Array=[]
    for i in count:s.tick({});events.append_array(s.events.duplicate(true))
    return events
func _initialize() -> void:
    for hero in 4:
        for id in 6:
            var p=P.new();p.path="";p.data.best=18
            for module in [1,2]:
                var allowed:bool=p.Tactics.Modules.compatible(hero,id,module,0)
                var before:String=JSON.stringify(p.data);var fitted:bool=p.configure_tactic(hero,id,"attachments",module)
                check("hero%d skill%d module%d compatibility is transactional"%[hero,id,module],fitted==allowed and (p.valid(p.data) if fitted else JSON.stringify(p.data)==before))
                p.configure_tactic(hero,id,"attachments",0)
    var p=P.new();p.path="";p.data.best=18;p.configure_tactic(1,0,"attachments",1)
    check("return rejects piercing without silently ejecting it",not p.configure_tactic(1,0,"supports",1) and p.data.tactics[1].supports[0]==0 and p.data.tactics[1].attachments[0]==1)
    p.configure_tactic(1,0,"attachments",0);p.configure_tactic(1,0,"supports",1)
    check("piercing rejects return in either fitting order",not p.configure_tactic(1,0,"attachments",1))
    var s=setup(1,0,1);s.tactics.config[0].supports[0]=1;s.tick({"attack":"tactic_a"})
    check("combat boundary also rejects incompatible injected config",s.fighters[0].meter==100 and s.events.any(func(e:Dictionary)->bool:return e.kind=="tactic_unavailable"))
    for hero in [0,1,2]:
        s=setup(hero,0,1);var f:Dictionary=s.fighters[0];s.squad_members[0].x=1.4
        s.tick({"attack":"tactic_a"});var hit_events:Array=[]
        for tick in 80:
            s.tick({});hit_events.append_array(s.events.filter(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("tactic",false)))
        check("hero%d return cannot hit the same body twice"%hero,hit_events.size()==1 and s.squad_members[0].health<500 and s.tactics.shots.is_empty())
        check("hero%d return never refunds its ranged fee"%hero,f.meter==100-s.TacticalSkills.COSTS[hero][0])
    s=setup(1,0,1);s.squad_members[0].x=1.4;s._start_attack(0,"tactic_a");var events:Array=[];var turned:=false;var snapshot:Dictionary={}
    for tick in 65:
        if not s.tactics.shots.is_empty() and int(s.tactics.shots[0].leg)==1 and not turned:
            turned=true;s.squad_members[1].x=2.1;snapshot=s.tactics.shots[0]
            s.fighters[0].tactical.relay_budget=0;s.fighters[0].tactical.relay=0
        s.tick({});events.append_array(s.events)
    check("return actually contacts a different target on its returning leg",turned and events.filter(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("tactic",false)).size()==2 and s.squad_members[1].health<500)
    check("return cannot rearm an already consumed next-melee refund",s.fighters[0].tactical.relay_budget==0 and s.fighters[0].meter==80 and snapshot.get("relay_armed",false))
    check("return damage and guard tradeoffs are real",not snapshot.is_empty() and snapshot.data.damage==8 and is_equal_approx(snapshot.data.guard_multiplier,.8))
    s=setup(0,0,1);s.fighters[0].x=7.5;s.fighters[0].face=1;s._start_attack(0,"tactic_a");var bounced:=false
    for tick in 45:
        s.tick({})
        if not s.tactics.shots.is_empty() and s.tactics.shots[0].leg==1:bounced=true
    check("return reverses once at the arena boundary instead of escaping",bounced and s.tactics.shots.is_empty())
    for hero in [1,3]:
        s=setup(hero,1,2);var f:Dictionary=s.fighters[0];s.squad_members[0].x=2.8
        if hero==3:f.service.nodes=[{"x":2.8,"life":300,"id":1}]
        s._start_attack(0,"tactic_a");var warned:=false;var early:=false;events=[]
        for tick in 80:
            if not s.tactics.shots.is_empty():
                warned=true
                if s.tactics.shots[0].age<23 and s.squad_members[0].health<500:early=true
            s.tick({});events.append_array(s.events)
        check("hero%d delayed area warns before its single real contact"%hero,warned and not early and events.filter(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("tactic",false)).size()==1)
        check("hero%d delayed explosion produces one cue at detonation"%hero,events.filter(func(e:Dictionary)->bool:return e.kind=="tactic_pulse").size()==1 and s.tactics.shots.is_empty())
        if hero==3:check("delayed pulse consumes its original node once",f.service.nodes.is_empty() and f.meter==80)
    s=setup(1,1,2);s.squad_members[0].x=2.8;s._start_attack(0,"tactic_a");step(s,24);s.squad_members[0].x=-5;step(s,35)
    check("walking out of a warning avoids actual damage",s.squad_members[0].health==500)
    s=setup(1,1,2);s._start_attack(0,"tactic_a");step(s,24);var age:int=s.tactics.shots[0].age;s.hitstop=4;step(s,4)
    check("delayed warning freezes with simulation hitstop",s.tactics.shots[0].age==age)
    s=setup(1,1,2);s.tactics.config[0].variants[1]=1;s.fighters[0].tactic_anchor=true;s._start_attack(0,"tactic_a");step(s,24)
    check("wide variant and anchor retain real coverage on delayed ground line",is_equal_approx(s.tactics.shots[0].radius,2.15) and s.tactics.shots[0].data.damage<10)
    s=setup(1,1,2);s._start_attack(0,"tactic_a");step(s,24);s.squad_members[0].x=2.8;s.squad_members[0].y=8;step(s,25)
    check("jumping above a delayed ground zone avoids contact",s.squad_members[0].health==500)
    var corrupt:Dictionary=p.data.duplicate(true);corrupt.tactics[3].attachments[5]=1
    check("save validator rejects a module on an incompatible skill",not p.valid(corrupt))
    corrupt=p.data.duplicate(true);corrupt.tactics[0].erase("attachments")
    check("current schema requires its support-slot record",not p.valid(corrupt))
    for version in [4,5,6,7]:migration(version)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"  "));quit(1 if failed else 0)
func migration(version:int) -> void:
    var p=P.new();p.path="user://modules-test/v%d.json"%version
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p.path.get_base_dir()));p.data.best=18;p.data.credits=777;p.data.parts=12;p.configure_tactic(1,0,"variants",1);p.store_build(1,0)
    var old:Dictionary=p.data.duplicate(true);old.version=version
    if version<6:
        for cfg in old.tactics:cfg.erase("attachments")
        for hero_presets in old.build_presets:
            for preset in hero_presets:
                if not preset.is_empty():preset.tactics.erase("attachments")
    if version==4:
        old.erase("build_presets")
        for cfg in old.tactics:cfg.variants=cfg.variants.slice(0,2);cfg.supports=cfg.supports.slice(0,2)
    var bytes:String=JSON.stringify(old);FileAccess.open(p.path,FileAccess.WRITE).store_string(bytes);p.load_data()
    check("schema%d preserves old save bytes and choices"%version,p.error=="" and p.valid(p.data) and p.data.version==P.SCHEMA and p.data.credits==777 and p.data.tactics[1].variants[0]==1 and FileAccess.get_file_as_string(p.path)==bytes)
    if version>=5:check("schema%d upgrades nested preset support slots"%version,p.load_build(1,0) and p.data.tactics[1].attachments==[0,0,0,0,0,0])
    p.configure_tactic(1,0,"attachments",1);p.store_build(1,1);p.save_data();var reloaded=P.new();reloaded.path=p.path;reloaded.load_data()
    check("schema%d migrated module preset survives integer normalization and reload"%version,reloaded.error=="" and reloaded.load_build(1,1) and reloaded.data.tactics[1].attachments[0]==1)
