extends SceneTree
const S=preload("res://scripts/combat/story/story_simulation.gd")
const P=preload("res://scripts/combat/city/city_profile.gd")
const OUT="res://../docs/evidence/tactics-expanded/"
var checks:Array=[]
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("EXPANDED ",label," ",ok)
    if not ok:push_error(label)
func setup(hero:int,id:int) -> RefCounted:
    var s=S.new();s.character_choices=[hero,4];s.last_service_enabled=true;s.ai_enabled=false;s.campaign_enabled=true;s.campaign_stats={"tactic_unlocked":6};s.wave_recipes=[["grunt"]];s.begin_story();s.arrival_left=99999
    s.tactics.enabled=true;s.tactics.config=[s.TacticalSkills.defaults(),{}];s.tactics.config[0].skills=[id,0 if id!=0 else 1]
    var f:Dictionary=s.fighters[0];f.meter=100;f.x=0;f.face=1
    s.fighters[1].x=1.8;s.fighters[1].health=500;s.fighters[1].max_health=500
    f.service.routes=2;f.service.preload=2;f.service.sample=1
    f.service.nodes=[{"x":1.8,"life":300,"id":1},{"x":3.4,"life":300,"id":2}]
    if id==3 or (hero==2 and id==2):s.fighters[1].x=1.0
    if hero==1 and id==5:s.fighters[1].x=3.0
    if hero==0 and id==2:f.y=1.2;f.air.phase="fall"
    return s
func step(s:RefCounted,count:int) -> Array:
    var events:Array=[]
    for i in count:s.tick({});events.append_array(s.events.duplicate(true))
    return events
func _initialize() -> void:
    for hero in 4:
        for id in range(2,6):
            var s=setup(hero,id);s.tick({"attack":"tactic_a"})
            check("hero%d skill%d starts for its exact cost"%[hero,id],s.fighters[0].state=="attack" and s.fighters[0].meter==100-s.TacticalSkills.COSTS[hero][id])
            var events:=step(s,90)
            check("hero%d skill%d emits within bounded life"%[hero,id],s.fighters[0].tactical.fired and s.tactics.shots.size()<=12 and s.fighters[0].meter>=0)
            if not (hero==2 and id==4) and not (hero==3 and id==4):
                check("hero%d skill%d has real blockable contact"%[hero,id],events.any(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("tactic",false)))
    var s=setup(0,2);s.fighters[0].y=0;s.tick({"attack":"tactic_a"})
    check("diving tactic requires a real jump",s.fighters[0].meter==100)
    s=setup(0,2);s.tick({"attack":"tactic_a"});step(s,45)
    check("dive never refills jumps or pursuit",not s.fighters[0].air.double_used and s.fighters[0].air.chase_window==0)
    s=setup(1,4);s.fighters[0].service.preload=0;s.tick({"attack":"tactic_a"})
    check("pressure vent rejects absent preload",s.fighters[0].meter==100)
    s=setup(1,4);s.tick({"attack":"tactic_a"})
    check("pressure vent consumes the original preload once",s.fighters[0].service.preload==0 and s.fighters[0].tactical.vent_tier==2)
    s=setup(2,3);s.tick({"attack":"tactic_a"});var events:=step(s,35)
    check("cut-three does not autoplay stages",events.filter(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("tactic",false)).size()==1)
    s=setup(2,3);s.tick({"attack":"tactic_a"})
    for i in 16:s.tick({})
    var meter:float=s.fighters[0].meter;s.tick({"attack":"tactic_a"});events=step(s,20)
    check("confirmed manual stage is funded by the original cast",s.fighters[0].tactical.chain_stage==1 and s.fighters[0].meter==meter and events.any(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("tactic",false)))
    s=setup(2,3);s.fighters[1].x=7;s.tick({"attack":"tactic_a"});step(s,16);s.tick({"attack":"tactic_a"})
    check("whiff cannot open a free follow-up",s.fighters[0].tactical.chain_stage==0 and s.fighters[0].meter==75)
    s=setup(3,4);s.tick({"attack":"tactic_a"});step(s,35)
    check("floating emitter reserves both destructible nodes",s.tactics.Expanded.emitter(s.fighters[0]) and s.fighters[0].service.nodes.size()==2)
    meter=s.fighters[0].meter;s.tick({"attack":"tactic_a"});step(s,25)
    check("emitter is fired once without a second fee",s.fighters[0].meter==meter and s.fighters[0].service.nodes.is_empty())
    s=setup(2,4);s.tick({"attack":"tactic_a"});step(s,20)
    check("silence delays ordinary preparation only",s.fighters[1].get("tactic_silence",0)>0 and s.fighters[1].health==500)
    s=setup(1,5);s.tick({"attack":"tactic_a"});step(s,26)
    check("ground seal warns before it can hit",s.fighters[1].health==500 and s.tactics.shots.size()==1 and s.tactics.shots[0].delay==30)
    var detonation_events:=step(s,35)
    check("ground seal detonation has one real area cue",detonation_events.filter(func(e:Dictionary)->bool:return e.kind=="tactic_pulse").size()==1)
    var p=P.new();p.path="";p.data.best=18;p.data.credits=90;p.data.parts=8
    check("six learned skills are individually equippable",p.tactics_unlocked()==6 and p.equip_tactic(0,0,4) and p.equip_tactic(0,1,5) and p.valid(p.data))
    check("duplicate skill selection swaps the other slot",p.equip_tactic(0,0,5) and p.data.tactics[0].skills==[5,4])
    p.craft_tactic_gear(0,"tactic_anchor");var item:Dictionary=p.data.inventory[0];p.equip(int(item.id),0)
    p.data.points=5;p.allocate(0,"break_1");p.advanced_skill(0,p.Advanced.SKILLS[0][0].id)
    p.configure_tactic(0,4,"variants",1)
    check("full build can be stored for free",p.store_build(0,0) and p.valid(p.data))
    p.unequip(0,0);p.equip_tactic(0,0,0);p.respec(0);p.advanced_skill(0,p.Advanced.SKILLS[0][0].id)
    check("saved gear cannot be accidentally scrapped",not p.salvage(int(item.id)))
    check("build restores gear and six-skill configuration",p.load_build(0,0) and p.data.tactics[0].skills==[5,4] and p.data.tactics[0].variants[4]==1 and p.data.loadouts[0][0].id==item.id)
    check("build restores its allocated talent path",p.data.talents[0]==["break_1"])
    check("build restores equipped advanced techniques",p.data.advanced[0]==[p.Advanced.SKILLS[0][0].id])
    check("clearing preset releases only its references",p.clear_build(0,0) and not p.preset_uses(int(item.id)) and p.data.inventory.size()==1)
    check("preset load never changes money",p.data.credits==60 and p.data.parts==5)
    additional()
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open(OUT+"rules.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failed":failed},"  "));file.close()
    quit(1 if failed else 0)

func additional() -> void:
    for version in [3,4,5,6]:
        var p=P.new();p.path="user://expanded-tactics/v%d.json"%version
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p.path.get_base_dir()))
        var old:Dictionary=p.fresh();old.version=version;old.credits=432;old.parts=19;old.best=12
        if version<5:old.erase("build_presets")
        if version==3:old.erase("tactics")
        elif version==4:
            for cfg in old.tactics:cfg.variants=[1,0];cfg.supports=[0,1];cfg.skills=[1,0]
        var bytes:=JSON.stringify(old);var file:=FileAccess.open(p.path,FileAccess.WRITE);file.store_string(bytes);file.close();p.load_data()
        check("schema%d preserves old save bytes and progression"%version,p.error=="" and p.valid(p.data) and p.data.credits==432 and p.data.best==12 and FileAccess.get_file_as_string(p.path)==bytes)
        if version==4:check("schema4 pads new choices without losing the old build",p.data.tactics[0].variants==[1,0,0,0,0,0] and p.data.tactics[0].skills==[1,0])
        p.save_data();var next=P.new();next.path=p.path;next.load_data()
        check("schema%d new save reloads with six-choice records"%version,next.valid(next.data) and next.data.tactics==p.data.tactics)
    for best in [0,1,3,6,9,12,15,18]:
        var p=P.new();p.path="";p.data.best=best
        var expected:int=[0,1,2,3,4,5,6,6][[0,1,3,6,9,12,15,18].find(best)]
        check("progress%d unlocks exactly%d tools"%[best,expected],p.tactics_unlocked()==expected)
    var s=setup(0,1);s.fighters[1].y=5;s.fighters[1].air.stall=100;s._start_attack(0,"tactic_a");step(s,20)
    check("ground tactic cannot hit arbitrarily high flyers",s.fighters[1].health==500)
    s=setup(1,3);s.CampaignRules.boss(s.fighters[1],"gantry");s.fighters[1].x=2;s._start_attack(0,"tactic_a");step(s,45)
    check("cable never moves a giant boss",s.fighters[1].x==s.fighters[1].boss.anchor)
    s=setup(2,3);s._start_attack(0,"tactic_a");step(s,12);s.fighters[0].state="stun";s.fighters[0].stun=99;s.tick({"attack":"tactic_a"})
    check("interruption clears the manual chain window",s.fighters[0].tactical.follow_window==0)
    s=setup(3,4);s._start_attack(0,"tactic_a");step(s,35);s.fighters[0].service.nodes.pop_back();s.tick({})
    check("breaking half an emitter releases both reserved points",s.fighters[0].service.nodes.is_empty())
    s=setup(3,5);s._start_attack(0,"tactic_a");step(s,36)
    check("broadcast segments share one victim budget",s.fighters[1].health>=486)
    var p=P.new();p.path="";p.data.best=18;p.data.credits=100;p.data.parts=10;p.equip_tactic(2,0,5);p.store_build(2,1)
    p.equip_tactic(2,0,2);p.error="test save rejection";var before:Dictionary=p.data.duplicate(true)
    check("failed preset load is an atomic rollback",not p.load_build(2,1) and p.data==before)
    p.error="";p.data.build_presets[2][1].gear=[999,-1,-1];before=p.data.duplicate(true)
    check("missing preset equipment cannot invent gear or partially apply",not p.load_build(2,1) and p.data==before)
    p.data.build_presets[2][1].gear=[-1,-1,-1];p.data.points=0;p.data.build_presets[2][1].talents=["guard_1"]
    check("unaffordable saved allocation cannot apply",p._valid_preset(p.data.build_presets[2][1],2) and not p.load_build(2,1))

    s=setup(0,4)
    var second:Dictionary=s.fighters[1].duplicate(true);second.squad_id=1;second.x=3.2;s.squad_members.append(second)
    s.tick({"attack":"tactic_a"})
    for i in 25:
        if s.fighters[0].tactical.follow_window>0:break
        s.tick({})
    var first_hp:int=s.squad_members[0].health;var paid:float=s.fighters[0].meter
    s.tick({"attack":"tactic_a"});step(s,35)
    check("two-stop delivery selects and actually hits a different body",s.fighters[0].tactical.chain_stage==1 and second.health<500 and s.squad_members[0].health==first_hp and s.fighters[0].meter==paid)
    s=setup(2,3);s.fighters[1].story_role="guard";s.tick({"attack":"tactic_a"});step(s,16);s.tick({"attack":"tactic_a"})
    check("blocked chain cannot grant free manual continuation",s.fighters[0].tactical.follow_left==0 and s.fighters[0].meter==75)
    s=setup(2,4)
    s.projectiles.append({"owner":1,"shooter":s.fighters[1],"target":s.fighters[0],"x":2.5,"y":1.0,"dir":-1.0,"age":0,"damage":10,"passed":false,"reflected":false})
    s._start_attack(0,"tactic_a");s.tactics.emit(s,0,4,s.tactics.move(s.fighters[0],"tactic_a"));s.GunShot.advance(s)
    check("silence never deletes a pistol round already in flight",s.projectiles.size()==1 and s.projectiles[0].x<2.5)
    s=setup(2,4);s.CampaignRules.boss(s.fighters[1],"gantry");s.fighters[1].x=2.0;s._start_attack(0,"tactic_a");s.tactics.emit(s,0,4,s.tactics.move(s.fighters[0],"tactic_a"))
    check("silence does not suppress a nearby giant boss",s.fighters[1].get("tactic_silence",0)==0)

    p=P.new();p.path="user://expanded-tactics/nonempty-preset.json";p.data.best=18;p.data.points=5;p.data.credits=100;p.data.parts=10
    p.equip_tactic(1,0,4);p.allocate(1,"air_1");p.craft_tactic_gear(1,"tactic_anchor")
    var saved_item:int=p.data.inventory[0].id;p.equip(saved_item,1);p.store_build(1,2)
    var loaded=P.new();loaded.path=p.path;loaded.load_data();loaded.unequip(0,1);loaded.respec(1);loaded.equip_tactic(1,0,0)
    check("nonempty preset survives atomic save/reload with gear and talents",loaded.load_build(1,2) and loaded.data.tactics[1].skills==[4,1] and loaded.data.talents[1]==["air_1"] and int(loaded.data.loadouts[1][0].id)==saved_item)
    loaded.unequip(0,1)
    check("reloaded preset still protects its item identity",not loaded.salvage(saved_item) and loaded.preset_uses(saved_item))

    s=setup(1,0);s.fighters[0].tactic_economy=.2;s.tick({"attack":"tactic_a","tactic_a_held":true})
    for i in 40:s.tick({"tactic_a_held":true})
    check("economy build affects both fast fee and full-charge surcharge",s.fighters[0].meter==76 and s.tactics.cost(s.fighters[0],0)==16)
    s=setup(0,5);s.fighters[0].tactic_economy=9;s._start_attack(0,"tactic_a")
    check("tactical energy discounts retain the common twenty-percent cap",s.fighters[0].meter==76)

    s=setup(0,4);s.fighters[0].service.routes=0;s.fighters[0].service.route_ttl=0
    for dodge in 2:
        if dodge>0:step(s,50)
        s.fighters[0].x=-1;s.fighters[1].x=.5;s.fighters[1].face=-1
        s._start_attack(1,"jab");s.fighters[1].frame=int(s.move_for(s.fighters[1],"jab").startup)-1
        s.tick({"dash":true,"axis":-1})
        check("route-banking build earns route%d from a legal dodge"%(dodge+1),s.fighters[0].service.routes==dodge+1)

    s=setup(1,4);s.fighters[0].service.preload=0;s.fighters[1].x=7;s._start_attack(0,"special")
    for i in 20:s.tick({"skill_held":true})
    check("normal L charge genuinely builds a fan conversion opportunity",s.fighters[0].service.preload>0 and not s.fighters[0].service.preload_spent and s.fighters[0].meter==50)
    s.tick({"attack":"tactic_a","skill_held":true})
    check("L-to-vent conversion commits only the replacement fee",s.fighters[0].move=="tactic_a" and s.fighters[0].meter==80 and s.fighters[0].service.preload==0)
    s=setup(1,4);s.fighters[0].service.preload=0;s._start_attack(0,"special")
    for i in 40:s.tick({"skill_held":true})
    step(s,90);s.fighters[0].state="idle";var paid_meter:float=s.fighters[0].meter;s.tick({"attack":"tactic_a"})
    check("resolved charged punch cannot spend its visual tier again",s.fighters[0].service.preload_spent and s.fighters[0].move!="tactic_a" and s.fighters[0].meter==paid_meter)
    for blocked in ["cooldown","guard","jump","interrupted"]:
        s=setup(1,4);s.fighters[0].service.preload=0;s._start_attack(0,"special")
        for i in 20:s.tick({"skill_held":true})
        var command:={"attack":"tactic_a","skill_held":true}
        if blocked=="cooldown":s.fighters[0].tactical.cd[0]=30
        if blocked in ["guard","jump"]:command[blocked]=true
        if blocked=="interrupted":s.fighters[0].state="stun";s.fighters[0].stun=10
        s.tick(command)
        check("%s conversion cannot refund the L commitment"%blocked,s.fighters[0].meter==50 and s.fighters[0].move!="tactic_a")
