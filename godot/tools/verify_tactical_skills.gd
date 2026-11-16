extends SceneTree
const S=preload("res://scripts/combat/story/story_simulation.gd")
const P=preload("res://scripts/combat/city/city_profile.gd")
const C=preload("res://scripts/combat/fight_controls.gd")
var checks:Array=[]
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("TACTICS ",label," ",ok)
    if not ok:push_error(label)
func sim(hero:int) -> RefCounted:
    var s=S.new();s.character_choices=[hero,4];s.last_service_enabled=true;s.ai_enabled=false
    s.campaign_enabled=true;s.campaign_stats={"tactic_unlocked":2};s.wave_recipes=[["grunt","guard","rusher"]];s.begin_story();s.arrival_left=99999
    s.tactics.enabled=true;s.tactics.config=[s.TacticalSkills.defaults(),{}]
    s.fighters[0].meter=100;s.fighters[0].x=0;s.fighters[0].face=1
    for f in s.squad_members:f.x=3+int(f.squad_id)*1.4;f.health=100;f.max_health=100
    return s
func ticks(s:RefCounted,count:int,held:=false) -> Array:
    var events:Array=[]
    for i in count:s.tick({"tactic_a_held":held});events.append_array(s.events.duplicate(true))
    return events
func _initialize() -> void:
    for hero in 4:
        for slot in 2:
            var s=sim(hero)
            if hero==3 and slot==1:s.fighters[0].service.nodes=[{"x":3.0,"life":300,"id":1}]
            s.tick({"attack":"tactic_a" if slot==0 else "tactic_b"})
            check("hero%d slot%d starts and pays once"%[hero,slot],s.fighters[0].state=="attack" and s.fighters[0].meter==100-s.TacticalSkills.COSTS[hero][slot])
            var events:=ticks(s,100)
            if hero==3 and slot==0:check("connector shares real node budget",s.fighters[0].service.nodes.size()==1)
            elif hero==2 and slot==1:check("receive without a bullet does not invent sample",s.fighters[0].service.sample==0)
            else:check("hero%d slot%d has real travel contact or bounded melee"%[hero,slot],events.any(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("tactic",false)))
            check("cooldown remains after action",s.fighters[0].tactical.cd[slot]>0)
            s.fighters[0].state="idle";var meter:float=s.fighters[0].meter
            s._start_attack(0,"tactic_a" if slot==0 else "tactic_b")
            check("cooldown rejects without double spend",s.fighters[0].meter==meter and s.fighters[0].state=="idle")
    var s=sim(1);s.squad_members.resize(1);s.tick({"attack":"tactic_a","tactic_a_held":true});ticks(s,38,true)
    check("held rivet reaches paid full charge",s.fighters[0].tactical.full and s.fighters[0].meter==70 and s.tactics.shots.is_empty())
    s.tick({});var events:=ticks(s,65)
    check("release resolves a real full-charge contact",events.any(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("tactic",false)))
    s=sim(1);s.tick({"attack":"tactic_a"});ticks(s,15,true);s.tick({"guard":true})
    check("guard cancels charge without refund or shot",s.fighters[0].tactical.charge==-1 and s.tactics.shots.is_empty() and s.fighters[0].meter==80)
    s=sim(1);s.tick({"attack":"tactic_a"});ticks(s,8,true);s.tactics.suspend(s);ticks(s,70)
    check("pause/focus suspension cannot ghost release",s.tactics.shots.is_empty() and s.fighters[0].tactical.charge==-1)
    s=sim(1);s.fighters[0].meter=19;s.tick({"attack":"tactic_a"})
    check("insufficient energy gives reason without starting",s.fighters[0].meter==19 and s.fighters[0].state=="idle" and s.events.any(func(e:Dictionary)->bool:return e.kind=="tactic_unavailable"))
    s=sim(1);s.fighters[0].tactic_unlocked=0;s.tick({"attack":"tactic_a"})
    check("story unlock gate is real",s.fighters[0].meter==100 and s.fighters[0].state=="idle")
    s=sim(1);s.tactics.enabled=false;s.tick({"attack":"tactic_a"})
    check("standard modes do not consume story tactics",s.fighters[0].meter==100 and s.tactics.shots.is_empty())
    var p=P.new();p.path="";p.data.best=3;p.data.credits=77;p.data.parts=5
    check("profile and free configuration valid",p.valid(p.data) and p.configure_tactic(1,0,"variants",1) and p.data.credits==77 and p.data.parts==5)
    check("slot swap preserves variants",p.configure_tactic(1,0,"skills",0) and p.data.tactics[1].skills==[1,0] and p.data.tactics[1].variants==[1,0])
    var c=C.new();c.tactics_enabled=true
    var key:=InputEventKey.new();key.physical_keycode=KEY_Q;key.keycode=KEY_Q;key.pressed=true
    check("Q emits one semantic edge",c.feed(key).size()==1 and c.tactic_held(0))
    key.echo=true;check("key repeat cannot recast",c.feed(key).is_empty())
    c.clear_tactic_keys();check("suspension clears held keys",not c.tactic_held(0))
    extended()
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var out:=FileAccess.open("res://../docs/evidence/tactical-skills/checks.json",FileAccess.WRITE)
    if out:out.store_string(JSON.stringify({"checks":checks,"failed":failed},"  "))
    quit(1 if failed else 0)

func extended() -> void:
    for hero in 4:
        for variant in 2:
            for support in 2:
                var s=sim(hero);s.tactics.config[0].variants=[variant,variant];s.tactics.config[0].supports=[support,support]
                s.tick({"attack":"tactic_a"});ticks(s,100)
                check("hero%d variant%d support%d stays bounded"%[hero,variant,support],s.fighters[0].meter>=0 and s.fighters[0].meter<=100 and s.tactics.shots.size()<=12)
    var s=sim(1);s.squad_members.resize(1);s.fighters[1].x=7
    s.tick({"attack":"tactic_a"});ticks(s,72,true)
    check("max hold automatically releases once",s.fighters[0].tactical.charge==-1 and s.fighters[0].meter==70 and s.fighters[0].tactical.fired)
    s=sim(1);s.fighters[0].meter=25;s.tick({"attack":"tactic_a"});ticks(s,40,true)
    check("unfunded full tier never borrows meter",not s.fighters[0].tactical.full and s.fighters[0].meter==5)
    s=sim(1);s.tick({"attack":"tactic_a"});var before:int=s.fighters[0].tactical.charge;s.hitstop=8;ticks(s,8,true)
    check("hitstop cannot advance charge",s.fighters[0].tactical.charge==before)
    s=sim(1);s.tick({"attack":"tactic_a"});s.fighters[0].state="stun";s.fighters[0].stun=100;ticks(s,60,true)
    check("interrupted charge cannot emit",s.tactics.shots.is_empty() and not s.fighters[0].tactical.fired and s.fighters[0].meter==80)
    s=sim(1);s.fighters[0].y=1;s.tick({"attack":"tactic_b"})
    check("airborne ground line fails without cost",s.fighters[0].meter==100)
    s=sim(1);s.squad_members.resize(1);s.fighters[1].y=2;s.fighters[1].vy=0;s.fighters[1].air.stall=90
    s.tick({"attack":"tactic_b"});ticks(s,30)
    check("ground line does not hit an elevated target",s.fighters[1].health==100)
    # Direct impact fixtures exercise the ordinary guard and boss paths, not injected damage.
    for guarded in [true,false]:
        s=sim(1);s.squad_members.resize(1);s.fighters[1].x=3
        var target:Dictionary=s.fighters[1];target.guarding=guarded;target.guard_frames=30;target.parry_allowed=false;target.face=-1
        s._start_attack(0,"tactic_a");s.fighters[0].tactical.full=true
        s.tactics.emit(s,0,0,s.tactics.move(s.fighters[0],"tactic_a"))
        var shot:Dictionary=s.tactics.shots[0];shot.previous=2.8
        s.tactics.impact(s,shot,target)
        check("guarded=%s uses normal health/guard authority"%guarded,target.health==100 and target.guard<100 if guarded else target.health<100)
        check("remote hit cannot refund its own cost",s.fighters[0].meter==80)
    s=sim(1);s.squad_members.resize(1);s._start_attack(0,"tactic_a");s.tactics.emit(s,0,0,s.tactics.move(s.fighters[0],"tactic_a"))
    var shot:Dictionary=s.tactics.shots[0];shot.previous=2.8;s.fighters[0].state="attack";s.fighters[0].move="jab";s.fighters[0].service.serial+=1;s.fighters[0].hit_confirmed=false
    s.tactics.impact(s,shot,s.fighters[1])
    check("old projectile cannot confirm a new unrelated jab",not s.fighters[0].hit_confirmed)
    s=sim(2);s.squad_members.resize(1);s.fighters[0].x=0;s.fighters[0].face=1;s._start_attack(0,"tactic_b")
    var bullet:={"owner":1,"shooter":s.fighters[1],"target":s.fighters[0],"x":.5,"y":1.0,"dir":-1.0,"age":0,"damage":10,"passed":false,"reflected":false}
    var kept:bool=s.GunShot._step(s,bullet)
    check("sample receives exactly one actual pistol round",not kept and s.fighters[0].service.sample==1 and s.fighters[0].health==100)
    s.fighters[0].state="idle";var paid:float=s.fighters[0].meter;s._start_attack(0,"tactic_b")
    check("received sample can be sent during cooldown without double fee",s.fighters[0].state=="attack" and s.fighters[0].service.sample==0 and s.fighters[0].meter==paid)
    s.fighters[0].state="idle";s._start_attack(0,"tactic_b")
    check("sample follow-up cannot be repeated",s.fighters[0].state=="idle" and s.fighters[0].meter==paid)
    s=sim(3);s._start_attack(0,"tactic_b")
    check("empty node cast does not spend",s.fighters[0].meter==100 and s.fighters[0].state=="idle")
    for version in [1,2,3,4]:
        var p=P.new();p.path="user://tactics-test/v%d.json"%version
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p.path.get_base_dir()))
        var old:Dictionary=p.fresh();old.version=version;old.credits=321;old.parts=17;old.best=7
        if version<4:old.erase("tactics")
        var bytes:=JSON.stringify(old);var file:=FileAccess.open(p.path,FileAccess.WRITE);file.store_string(bytes);file.close();p.load_data()
        check("schema%d migration preserves progress and original bytes"%version,p.error=="" and p.valid(p.data) and p.data.credits==321 and p.data.parts==17 and p.data.best==7 and FileAccess.get_file_as_string(p.path)==bytes)
        var saved:bool=p.save_data();var next=P.new();next.path=p.path;next.load_data()
        check("schema%d next save reloads tactical defaults"%version,next.valid(next.data) and next.data.tactics==p.data.tactics)
    var p=P.new();p.path="";p.data.best=3;p.data.credits=100;p.data.parts=12
    for kind in ["tactic_relay","tactic_anchor"]:
        check("deterministic recipe creates valid equipment "+kind,p.craft_tactic_gear(1,kind) and p.valid(p.data))
    var a:Dictionary=p.data.inventory[0];var b:Dictionary=p.data.inventory[1]
    p.data.loadouts[1]=[b,{},a]
    check("two recipe mechanics cannot silently stack",p.stats(1).tactic_relay==1 and p.stats(1).tactic_anchor==0)
    var bad:Dictionary=p.data.duplicate(true);bad.tactics[0].skills=[0,0]
    check("corrupt duplicate-slot config is rejected",not p.valid(bad))

    s=sim(1);s.squad_members.resize(1);s.CampaignRules.boss(s.fighters[1],"gantry");s.fighters[1].x=3
    s._start_attack(0,"tactic_a");s.tactics.emit(s,0,0,s.tactics.move(s.fighters[0],"tactic_a"))
    var boss_hp:int=s.fighters[1].health;s.tactics.shots[0].previous=2.8;s.tactics.impact(s,s.tactics.shots[0],s.fighters[1])
    check("closed boss armour caps tactical damage",boss_hp-s.fighters[1].health<=3)
    p=P.new();p.path="";p.data.best=3
    var snapshot:Dictionary=p.data.duplicate(true)
    check("unfunded recipe is atomic",not p.craft_tactic_gear(0,"tactic_relay") and p.data==snapshot)
    p.data.credits=100;p.data.parts=10;p.error="test save unavailable";snapshot=p.data.duplicate(true)
    check("save rejection rolls recipe back",not p.craft_tactic_gear(0,"tactic_relay") and p.data==snapshot)

    var controls=C.new();controls.pads_override=[];controls.set_mode("versus");controls.tactics_enabled=true
    var event:=InputEventKey.new();event.physical_keycode=KEY_I;event.keycode=KEY_I;event.pressed=true
    var presses:Array=controls.feed(event)
    check("split keyboard retains P2 I dodge",presses.size()==1 and presses[0].side==1 and presses[0].action=="dash")
    controls=C.new();controls.pads_override=[7];controls.tactics_enabled=true
    var pad:=InputEventJoypadButton.new();pad.device=7;pad.button_index=JOY_BUTTON_RIGHT_STICK;pad.pressed=true
    presses=controls.feed(pad)
    check("controller semantic tactic route preserves held state",presses.size()==1 and presses[0].action=="tactic_a" and controls.tactic_held(0))
    pad.pressed=false;controls.feed(pad)
    check("controller release clears tactical hold",not controls.tactic_held(0))
    p=P.new();p.path="user://tactics-test/corrupt-v3.json"
    var corrupt:Dictionary=p.fresh();corrupt.version=3;corrupt.erase("credits");corrupt.erase("tactics")
    var corrupt_file:=FileAccess.open(p.path,FileAccess.WRITE);corrupt_file.store_string(JSON.stringify(corrupt));corrupt_file.close();p.load_data()
    check("incomplete schema3 cannot silently reset missing progress",p.error!="")

    var focused=sim(1);var wide=sim(1);wide.tactics.config[0].variants=[1,0]
    focused._start_attack(0,"tactic_a");wide._start_attack(0,"tactic_a")
    focused.tactics.emit(focused,0,0,focused.tactics.move(focused.fighters[0],"tactic_a"));wide.tactics.emit(wide,0,0,wide.tactics.move(wide.fighters[0],"tactic_a"))
    check("wide variant trades travel and damage for coverage",wide.tactics.shots[0].life<focused.tactics.shots[0].life and wide.tactics.shots[0].radius>focused.tactics.shots[0].radius and wide.tactics.shots[0].data.damage<focused.tactics.shots[0].data.damage)
    var pierced=sim(1);pierced.tactics.config[0].supports=[1,0];pierced._start_attack(0,"tactic_a");pierced.tactics.emit(pierced,0,0,pierced.tactics.move(pierced.fighters[0],"tactic_a"))
    check("pierce support changes target budget with lower damage",pierced.tactics.shots[0].limit==2 and pierced.tactics.shots[0].data.damage<focused.tactics.shots[0].data.damage)
    focused.fighters[0].tactical.relay=120;focused.fighters[0].tactical.relay_budget=1;focused.fighters[0].meter=10
    var melee_event:={"kind":"hit","attacker":0,"move":"jab"}
    focused.tactics.observe(focused,melee_event);focused.tactics.observe(focused,melee_event)
    check("relay returns energy only once after the next real melee",focused.fighters[0].meter==14 and focused.fighters[0].tactical.relay_budget==0)
    var anchored=sim(1);anchored.fighters[0].tactic_anchor=true;anchored._start_attack(0,"tactic_a")
    check("anchor equipment pays a longer cooldown",anchored.fighters[0].tactical.cd[0]==300)
    p=P.new();p.path="";p.start_run(0);p.data.run.in_flight=true;p.settle(true,100,60)
    check("first actual encounter guarantees a learned tactic receipt",p.tactics_unlocked()==1 and p.data.last_loot.has("FIRST TACTIC LEARNED / SEE SKILLS"))
    p.data.run.room=2;p.data.run.in_flight=true;p.settle(true,100,60)
    check("district completion guarantees second tactic and recipes",p.tactics_unlocked()==2 and p.data.last_loot.has("SECOND TACTIC + GEAR RECIPES / SEE SKILLS"))
