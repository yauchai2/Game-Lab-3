extends SceneTree
const P=preload("res://scripts/combat/city/city_profile.gd")
const S=preload("res://scripts/combat/story/story_simulation.gd")
const Pilot=preload("res://tools/test_helpers/campaign_pilot.gd")
const OUT="res://../docs/evidence/campaign-complete/"
var checks:Array=[]
var runs:Array=[]
func _initialize() -> void:call_deferred("run")
func check(name:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":name,"passed":ok,"detail":detail});print("COMPLETE ",name," ",ok)
    if not ok:push_error(name)
func profile() -> RefCounted:
    var p=P.new();p.path="";p.rng.seed=8831;return p
func fight(character:int,kind:="",stats:Dictionary={},recipe:Array=[]) -> RefCounted:
    var s=S.new();s.last_service_enabled=true;s.character_choices=[character,4];s.difficulty=0;s.begin_story();s.campaign_enabled=true;s.campaign_boss=kind;s.campaign_stats=stats;s.campaign_skills=["double_jump","launcher","chase","finisher","overdrive"]
    s.wave_recipes=[["boss"]] if kind!="" else [recipe if not recipe.is_empty() else ["grunt","guard","jammer","heavy","captain","rusher"]]
    s._load_wave(0,100,60);return s
func battle(s:RefCounted,skilled:=true,max_ticks:=18000) -> Dictionary:
    var hits:=0;var parries:=0;var phases:Dictionary={};var active:=0
    for tick in max_ticks:
        s.tick(Pilot.command(s,tick,skilled))
        active=maxi(active,s.squad_members.filter(func(f:Dictionary)->bool:return f.health>0).size())
        for f in s.squad_members:
            if f.has("boss"):phases[f.boss.phase]=true
        for event in s.events:
            if event.kind=="hit" and event.target==0:hits+=1
            if event.kind=="parry" and event.target==0:parries+=1
        if s.story_state in ["complete","failed"]:return {"state":s.story_state,"hp":s.fighters[0].health,"ticks":tick,"hits":hits,"parries":parries,"phases":phases.size(),"active":active}
    return {"state":s.story_state,"hp":s.fighters[0].health,"ticks":max_ticks,"hits":hits,"parries":parries,"phases":phases.size(),"active":active}
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    for kind in ["gantry","signal"]:
        for character in 4:
            var s=fight(character,kind);var result:Dictionary=battle(s);result["hero"]=character;result["boss"]=kind;runs.append(result)
            check("bare hero %d defeats %s via ordinary timed commands"%[character,kind],result.state=="complete" and result.hp>0 and result.parries>0,result)
            check("%s shows its genuine phases for hero%d"%[kind,character],result.phases==(2 if kind=="gantry" else 3))
    var p=profile();p.data.best=18;p.data.xp=1900;p._points()
    for node in p.Builds.nodes():p.allocate(0,node.id)
    for slot in 3:
        var item:Dictionary=p.Loot.make(slot+1,slot,3,99,p.SKILLS.map(func(s:Dictionary)->String:return s.id),slot+1)
        item.amount=.1;item.affixes=[{"stat":"damage","amount":.1},{"stat":"defence","amount":.1},{"stat":"heavy_damage","amount":.2}]
        p.data.inventory.append(item);p.equip(int(item.id))
    var max_stats:Dictionary=p.stats(0)
    check("equipment direct damage and defence remain bounded under extreme items",max_stats.damage<=.2 and max_stats.defence<=.15 and max_stats.economy<=.2,max_stats)
    var losses:=0
    for core in p.Cores.ITEMS:
        var s=fight(0,"signal",max_stats);s.fighters[0]["draw_core"]=core.id
        var result:Dictionary=battle(s,false);result["core"]=core.id;runs.append(result)
        if result.state=="failed":losses+=1
    check("top-gear attack spam fails final Boss across nine core choices",losses==9,{"failed":losses,"tested":9})
    var s=fight(0,"signal",max_stats);var b:Dictionary=s.squad_members[0];b.boss.step="windup";b.boss.open=0
    s.fighters[0].state="attack";s.fighters[0].move="overdrive";s.fighters[0].meter=0;s.fighters[0].x=4.3;s.fighters[0].face=1;s.fighters[0].connected=false
    var before:=int(b.health);s._resolve_hit(0,false)
    check("equipment and overdrive cannot bypass sealed core armour",before-b.health<=3)
    check("armour chips do not award full raw damage energy",s.fighters[0].meter<=4.5)
    b.boss.open=150;s.fighters[0].state="attack";s.fighters[0].move="overdrive";s.fighters[0].connected=false;s.fighters[0].y=1.2;before=int(b.health);s._resolve_hit(0,false)
    check("exposed upper core rewards a real aerial punish with bounded damage",before-b.health>3 and before-b.health<=14)
    s=fight(0,"gantry",{},["boss"]);s.campaign_hazards=[{"kind":"sweep","x":0.0,"half":3.0,"warn":10,"active":4,"age":0,"source":0,"boss":true,"face":-1,"struck":false}]
    var hp:=int(s.fighters[0].health)
    for i in 9:s.CampaignRules.hazards(s)
    check("visible tell does not damage before its active tick",s.fighters[0].health==hp)
    s.fighters[0].y=1.1;s.CampaignRules.hazards(s)
    check("jumping actually avoids a low sweep",s.fighters[0].health==hp)
    s=fight(0,"",{},["grunt","guard","jammer","heavy","captain","rusher","grunt","rusher","heavy","jammer"])
    check("arrival queue preserves ten total enemies but only six rigs",s.squad_members.size()==6 and s.remaining_enemies()==10)
    for f in s.squad_members:f.health=0;f.y=0;f.dead_age=40
    s._reinforce()
    check("scheduled arrival prevents false clear and spawns with grace",s.story_state=="combat" and s.reinforcements.size()==3 and s.squad_members[0].health>0 and s.squad_members[0].invuln==45)
    var broad=fight(0);var roles:Array=broad.squad_members.map(func(f:Dictionary)->String:return f.story_role)
    check("new support heavy and captain roles have distinct simulation state",roles.has("jammer") and roles.has("heavy") and roles.has("captain"))
    var encounter_result:Dictionary=battle(broad)
    check("mixed new roles remain beatable by bare ordinary inputs",encounter_result.state=="complete",encounter_result)
    p=profile();p.data.parts=5
    var offer:Dictionary=p.roll_core();var repeat:Dictionary=p.roll_core()
    check("core token is debited once and cancelled offer remains stable",p.data.parts==4 and offer==repeat and not offer.is_empty())
    check("claim installs one prepared core without duplicate claim",p.claim_core() and not p.claim_core() and p.data.pending_core==offer.id)
    p.start_run(0)
    check("prepared core belongs to one expedition and is consumed once",p.data.run.core==offer.id and p.data.pending_core=="")
    p.data.run.in_flight=true;p.settle(true,80,40,7,{"parry":1,"chain":1})
    check("heal budget and first-skill rewards bank with the wave",p.data.run.core_healed==7 and p.data.quest_claims.has("parry") and p.data.quest_claims.has("chain"))
    var money:=int(p.data.credits);p.choose_boon("damage");p.choose_route("combat");p.data.run.in_flight=true;p.settle(true,80,40,9,{"parry":1})
    check("technique quest cannot be farmed on later encounters",p.data.credits-money==70 and p.data.run.core_healed==9)
    p.abandon();check("ending an expedition clears temporary core but retains skills and loot",p.data.run.is_empty() and p.data.pending_core=="" and p.data.inventory.size()==2)
    p=profile();p.data.credits=1000;p.data.parts=100;var item:Dictionary=p.pull(0);var item_id:=int(item.id)
    var old_tier:=int(item.tier)
    if old_tier==3:item.tier=1;item.special="";p._refresh_item(item)
    var allowed:bool=int(item.tier)<2
    var ok:bool=p.craft(item_id,"temper")
    check("tempering has a rare ceiling and charges a real transaction",ok==allowed and (not ok or p.data.credits==780))
    var receipt:=int(p.data.craft_serial);var previous_stat:String=p.data.inventory[0].affixes[0].stat if not p.data.inventory[0].affixes.is_empty() else ""
    if previous_stat!="":
        check("recalibration changes the requested affix and updates equipped copies",p.craft(item_id,"recalibrate",0) and p.data.craft_serial==receipt+1 and p.data.inventory[0].affixes[0].stat!=previous_stat and p.gear_for(0)[0]==p.data.inventory[0])
    p=profile();p.start_run(0);p.data.run.room=3;p.data.run.hp=40;p.data.run["route_due"]=true
    check("rest route heals once without a reusable free-heal button",p.choose_route("rest") and p.data.run.hp==60 and not p.choose_route("rest"))
    var saved:Dictionary=p.data.duplicate(true);saved.version=2
    for key in ["quest_claims","core_offer","pending_core","core_serial","craft_serial"]:saved.erase(key)
    var expanded:Dictionary=p.expand(saved)
    check("schema2 expansion preserves exact talent inventory and run state",expanded.version==3 and expanded.run==saved.run and expanded.talents==saved.talents and p.valid(expanded))
    var old_mode=S.new();old_mode.last_service_enabled=true;old_mode.character_choices=[0,4];old_mode.difficulty=0;old_mode.begin_story()
    var old_attacks:=0
    for tick in 600:
        old_mode.tick()
        old_attacks=maxi(old_attacks,old_mode.squad_members.filter(func(f:Dictionary)->bool:return f.state=="attack").size())
    check("original M1 enemies still leave arrival grace and attack",old_attacks>0)
    var capped=profile();capped.start_run(0);capped.data.run.boon_due=true;capped.data.run.boons={"damage":.3,"defence":.3,"economy":.3}
    var previous_credits:=int(capped.data.credits)
    check("useless capped boons are refused instead of claiming fake power",not capped.choose_boon("damage") and is_zero_approx(capped.boon_gain("damage")))
    check("a capped build can take currency once and continue",capped.skip_boon() and not capped.skip_boon() and capped.data.credits==previous_credits+10)
    var advanced=profile();advanced.data.best=8
    check("advanced class techniques cannot skip their story milestones",not advanced.advanced_skill(0,"zip_route"))
    advanced.data.best=18
    check("each hero has three advanced options but only two equipped",advanced.advanced_skill(0,"zip_route") and advanced.advanced_skill(0,"zip_confirm") and not advanced.advanced_skill(0,"zip_dash"))
    var prop_test=fight(0,"",{},["grunt","grunt"]);prop_test.campaign_props=[{"x":1.0,"hp":2,"hits":[]}]
    prop_test.squad_members[0].x=1.6;prop_test.squad_members[1].x=2.2
    var h:Dictionary=prop_test.fighters[0];h.x=0;h.y=0;h.face=1;h.state="attack";h.move="heavy";h.frame=prop_test.move_for(h,"heavy").startup
    var past:Array=prop_test.squad_members.map(func(f:Dictionary)->Vector2:return Vector2(f.x,f.y))
    h.service.serial=10;prop_test.CampaignRules.props(prop_test,past);prop_test.CampaignRules.props(prop_test,past)
    check("one attack cannot repeatedly damage the same prop",prop_test.campaign_props[0].hp==1)
    h.service.serial=11;prop_test.CampaignRules.props(prop_test,past)
    var prop_hp:Array=prop_test.squad_members.map(func(f:Dictionary)->int:return f.health)
    check("second real heavy breaks prop and produces bounded enemy damage",prop_test.campaign_props[0].hp==0 and prop_hp[0]<35 and prop_hp[1]<35)
    prop_test.CampaignRules.props(prop_test,past)
    check("destroyed prop cannot repeatedly explode",prop_test.squad_members.map(func(f:Dictionary)->int:return f.health)==prop_hp)
    var middle=profile();middle.data.parts=4;middle.start_run(0);middle.data.run["in_flight"]=false;middle.data.run["entered"]=true;middle.data.run.meter=40
    middle.data.core_offer={"id":"charge","seed":1,"boundary":"test-mid"}
    check("safe mid-expedition core install is allowed and charge applies once",middle.claim_core() and middle.data.run.core=="charge" and middle.data.run.meter==60 and not middle.can_prepare_core() and not middle.claim_core())
    var campaign_runs:Array=[]
    for character in 4:
        var complete_run:Dictionary=Pilot.full_story(character);campaign_runs.append(complete_run)
        check("hero %d legally clears all eighteen encounters with earned loot and paid healing"%character,complete_run.complete,complete_run)
    var full_file:=FileAccess.open(OUT+"campaign-runs.json",FileAccess.WRITE);full_file.store_string(JSON.stringify(campaign_runs,"  "));full_file.close()
    var file:=FileAccess.open(OUT+"balance-runs.json",FileAccess.WRITE);file.store_string(JSON.stringify(runs,"  "));file.close()
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    file=FileAccess.open(OUT+"rules.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks},"  "));file.close()
    print("COMPLETE RESULT ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
