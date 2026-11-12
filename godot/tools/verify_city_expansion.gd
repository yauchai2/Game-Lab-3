extends SceneTree
const P=preload("res://scripts/combat/city/city_profile.gd")
const B=preload("res://scripts/combat/city/city_builds.gd")
const S=preload("res://scripts/combat/story/story_simulation.gd")
class Fault:
    extends "res://scripts/combat/city/city_profile.gd"
    func save_data() -> bool:return false
var checks:Array=[]
const OUT="res://../docs/evidence/city-expansion/"
func _initialize() -> void:call_deferred("run")
func check(name:String,ok:bool) -> void:
    checks.append({"name":name,"passed":ok});print("EXPANSION ",name," ",ok)
    if not ok:push_error(name)
func flight(p:RefCounted) -> void:p.data.run["in_flight"]=true
func fresh() -> RefCounted:
    var p=P.new();p.path="";return p
func sim() -> RefCounted:
    var s=S.new();s.last_service_enabled=true;s.character_choices=[0,4];s.begin_story();s.ai_enabled=false;return s
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var nodes:Array=B.nodes()
    check("48 nodes split 28 minors 12 notables 4 keystones 4 gateways",nodes.size()==48 and nodes.filter(func(n:Dictionary)->bool:return n.kind=="minor").size()==28 and nodes.filter(func(n:Dictionary)->bool:return n.kind=="notable").size()==12 and nodes.filter(func(n:Dictionary)->bool:return n.kind=="keystone").size()==4 and nodes.filter(func(n:Dictionary)->bool:return n.kind=="hub").size()==4)
    var unique_ids:Dictionary={}
    for node in nodes:unique_ids[node.id]=true
    check("node IDs are unique",unique_ids.size()==48 and B.by_id("missing").is_empty())
    for hero in 4:
        var p=fresh();p.data.xp=1900;p.data.best=18;p._points()
        check("hero %d cannot allocate remote endpoint without a path"%hero,not p.allocate(hero,"break_11"))
        var progress:=true
        while progress:
            progress=false
            for node in nodes:
                if p.allocate(hero,node.id):progress=true
        check("hero %d connected paths spend exactly 25 points"%hero,p.data.talents[hero].size()==25 and p.valid(p.data))
        check("hero %d cannot allocate a 26th node"%hero,not p.allocate(hero,"flow_10"))
        p.respec(hero)
        check("hero %d free respec retains full budget"%hero,p.data.talents[hero].is_empty() and p.data.points==25)
    var p=fresh();p.data.points=25
    for id in ["break_1","break_2","break_3","break_4","break_5","break_6","break_10","break_11"]:p.allocate(0,id)
    check("keystone has actual bounded damage versus target tradeoff",is_equal_approx(p.stats(0).chain_damage,.35) and p.stats(0).chain_targets==-1)
    for id in ["air_2","air_3","air_4","air_5","air_6","air_10"]:p.allocate(0,id)
    check("a second keystone is explicitly refused",not p.allocate(0,"air_11"))
    p=fresh();p.start_run(0);flight(p)
    check("first clear banks enough for a pull and actual equipment",p.settle(true,80,42) and p.data.credits==100 and p.data.inventory.size()==1 and p.data.points==1 and p.level()==2)
    var loot_id:=int(p.data.inventory[0].id)
    check("repeat settlement cannot duplicate money loot or XP",not p.settle(true,80,42) and p.data.inventory.size()==1 and p.data.xp==100)
    check("first-clear double jump remains free and deterministic",p.learn("double_jump") and not p.learn("overdrive"))
    check("unlearned skill affixes cannot appear in generated gear",not p.Loot.make(10,0,3,5,[],42).affixes.any(func(a:Dictionary)->bool:return a.has("skill")))
    p.data.credits=1000;p.data.pity=9;p.data.unique_pity=39
    var item:Dictionary=p.pull(1,0)
    check("signature pity is exact and shares one atomic purchase",item.tier==3 and p.data.credits==900 and p.data.pity==0 and p.data.unique_pity==0 and item.affixes.size()==2)
    check("per-hero equipment can differ without deleting shared items",p.gear_for(1)[1].is_empty() and p.equip(int(item.id),1) and not p.gear_for(1)[1].is_empty())
    check("recycling protects equipment worn by any hero",not p.salvage(int(item.id)) and p.unequip(1,0) and not p.salvage(int(item.id)) and p.unequip(1,1) and p.salvage(int(item.id)))
    p.data.pity=9
    check("rare pity counts pulls rather than combat drops",p.pull(2).tier>=2 and p.data.pity==0)
    var fault=Fault.new();fault.data=p.data.duplicate(true);var before:Dictionary=fault.data.duplicate(true)
    check("failed write restores debit inventory and pity",fault.pull(0).is_empty() and fault.data==before and fault.error!="")
    p=fresh();p.start_run(0)
    for i in 60:p.data.inventory.append(p.Loot.make(i+1,0,1,1,[],i));p.data.item_serial=i+1
    flight(p);p.settle(true,80,40)
    check("full bag routes actual loot to stash",p.data.inventory.size()==60 and p.data.stash.size()==1)
    for i in 119:p.data.stash.append(p.Loot.make(1000+i,0,1,1,[],i))
    p.choose_boon("damage");flight(p);var parts:=int(p.data.parts);p.settle(true,80,40)
    check("full bag and stash recycle overflow with visible receipt",p.data.stash.size()==120 and p.data.parts>parts+1 and p.data.last_loot.has("FULL STORAGE: item recycled to parts"))
    p=fresh();p.data.best=18;p.data.xp=1900;p._points();p._contract(1,0,1147)
    var id:=int(p.data.contracts[0].id)
    check("contract consumes one entrance item and persists the run",p.start_contract(0,id) and p.data.contracts.is_empty() and p.data.run.tries==3 and not p.start_contract(0,id))
    flight(p);p.settle(true,72,40);p.choose_boon("damage")
    var money:=int(p.data.credits);var size:int=p.data.inventory.size()
    for attempt in 3:
        flight(p);p.settle(false,0,0)
        if attempt<2:check("contract failure %d retries the same wave without refunding entry"%attempt,p.data.run.wave==1 and p.data.run.tries==2-attempt and p.data.credits==money)
    check("third defeat ends challenge and preserves banked rewards",p.data.run.is_empty() and p.data.credits==money and p.data.inventory.size()==size and p.data.contracts.is_empty())
    for tier in range(1,6):
        var c:Dictionary=p.Contracts.make(tier,tier,0,1147+tier)
        for wave in int(c.waves):
            var recipe:Array=p.Contracts.recipe(c,wave)
            check("T%d wave%d finite seeded arrival recipes"%[tier,wave],recipe.size()<=9 and recipe.size()>=3 and recipe==p.Contracts.recipe(c,wave))
    p=fresh();p.data.best=18;p.data.xp=1900;p._points();p._contract(1,0,1147)
    for complete in 2:
        id=int(p.data.contracts[0].id);p.start_contract(0,id)
        for wave in 3:
            flight(p);p.settle(true,80,40)
            if not p.data.run.is_empty():p.choose_boon("damage")
    check("two map clears guarantee higher tier and return same-tier maps",p.data.contract_tier==2 and p.data.contracts.any(func(c:Dictionary)->bool:return int(c.tier)==2) and p.data.contracts.any(func(c:Dictionary)->bool:return int(c.tier)==1))
    p.data.contracts=[];p.start_run(0,0)
    for room in 3:
        flight(p);p.settle(true,80,40)
        if not p.data.run.is_empty():p.choose_boon("damage")
    check("free completed district replenishes T1 maps",p.data.contracts.size()==1 and p.data.contracts[0].tier==1)
    p=fresh();p.path="user://city-expansion/legacy.json"
    for suffix in ["",".bak",".tmp",".v1.bak"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(p.path+suffix))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p.path.get_base_dir()))
    var legacy:={"version":1,"credits":234,"parts":9,"best":8,"points":8,"skills":["double_jump","launcher"],"skill_levels":[1,0,0,0],"talents":[["break_1","break_2"],[],[],[]],"gear":[{},{},{}],"inventory":[],"pulls":4,"pity":4,"unique_pity":4,"serial":2,"attempts":2,"dialogue":1,"claims":[],"run":{}}
    var file:=FileAccess.open(p.path,FileAccess.WRITE);var original:=JSON.stringify(legacy);file.store_string(original);file.close();p.load_data()
    check("legacy migration retains abilities money and point budget",p.error=="" and p.data.version==3 and p.data.points==8 and p.data.credits==234 and p.data.skills==legacy.skills and p.data.skill_levels[0]==1)
    check("expanded tree refunds old allocations without overwriting original",p.data.talents[0].is_empty() and FileAccess.get_file_as_string(p.path)==original)
    p.learn("chase")
    check("first migrated transaction preserves immutable v1 backup",FileAccess.get_file_as_string(p.path+".v1.bak")==original)
    var reloaded=P.new();reloaded.path=p.path;reloaded.load_data()
    check("version2 profile reloads without further migration",reloaded.error=="" and reloaded.data.skills.has("chase") and reloaded.migration_notice=="")
    var s=sim();var baseline:Dictionary=s.move_for(s.fighters[0],"heavy")
    s.campaign_enabled=true;s.campaign_stats={"heavy_damage":.20,"guard_damage":.2,"launch_force":.15,"enemy_damage":.15,"defence":.1}
    var heavy:Dictionary=s.move_for(s.fighters[0],"heavy")
    check("build changes actual heavy damage launch and guard pressure",heavy.damage>baseline.damage and heavy.push>baseline.push and is_equal_approx(heavy.guard_multiplier,1.2))
    s.campaign_stats={"aerial_damage":.25,"ground_penalty":-.10};s.fighters[0].y=0;var ground:int=s.move_for(s.fighters[0],"jab").damage
    s.fighters[0].y=1
    check("sky keystone changes damage by actual aerial state",s.move_for(s.fighters[0],"jab").damage>ground)
    s=sim();s.campaign_enabled=true;s.campaign_stats={"parry_meter":4.0,"counter_damage":.3}
    var parry_bonus:=0.0
    for i in 4:
        s.fighters[0].x=0;s.fighters[0].face=1;s.fighters[0].guarding=true;s.fighters[0].guard_frames=1;s.fighters[0].parry_cd=0;s.fighters[0].guard=100;s.fighters[0].meter=0
        s.fighters[1].x=.8;s.fighters[1].face=-1;s.fighters[1].state="attack";s.fighters[1].move="jab";s.fighters[1].frame=0;s.fighters[1].connected=false
        s._resolve_hit(1,false);parry_bonus+=float(s.fighters[0].meter)-18.0
    check("real parries get bounded bonus and a timed counter",is_equal_approx(parry_bonus,12.0) and s.fighters[0].city_counter==180)
    s=sim();s.campaign_enabled=true;s.campaign_skills=["chase"];s.campaign_stats={"chase_refund":5.0}
    var meters:Array=[]
    for i in 3:
        var f:Dictionary=s.fighters[0];f.state="idle";f.x=0;f.y=0;f.meter=100;f.air.chase_used=false;f.air.chase_buffer=8;f.air.chase_window=30
        s.fighters[1].x=1;s.fighters[1].y=1;s.fighters[1].vy=2;s.fighters[1].state="stun";s.fighters[1].stun=100
        s._advance_fighter(0,{});meters.append(f.meter)
    check("real homing chase refunds cap at ten per encounter",meters==[85.0,85.0,80.0])
    s=sim();s.campaign_enabled=true;s.campaign_stats={"chain_targets":2.0,"splash":1.0,"chain_meter":4.0};s._load_wave(2,100,0)
    for i in s.squad_members.size():
        s.squad_members[i].x=1.0+i*.9;s.squad_members[i].y=0;s.squad_members[i].guarding=false
    s.squad_members[0].vx=120;s.body_chain.arm(s.squad_members[0],41,30)
    var positions:Array=s.squad_members.map(func(f:Dictionary)->Vector2:return Vector2(f.x,f.y))
    s.squad_members[0].x=2;s.body_chain.advance(s,positions)
    var hits:Array=s.events.filter(func(e:Dictionary)->bool:return e.kind=="story_chain_hit")
    var seen:Dictionary={};var duplicate:=false
    for event in hits:
        if seen.has(event.squad_id):duplicate=true
        seen[event.squad_id]=true
    check("first collision produces genuine splash sharing one hit set",hits.any(func(e:Dictionary)->bool:return e.get("splash",false)) and not duplicate)
    check("splash and chain share target and resource hard caps",hits.size()<=6 and s.fighters[0].meter==8)
    var hp:Array=s.squad_members.map(func(f:Dictionary)->int:return f.health)
    s.body_chain.advance(s,positions)
    check("same-source splash never repeats against struck targets",s.squad_members.map(func(f:Dictionary)->int:return f.health)==hp)
    s.end_squad();s.begin_story()
    check("standard preview restores full permissions and modifiers",not s.campaign_enabled and s.campaign_stats.is_empty() and s.wave_recipes==s.WAVES)
    var route=fresh();route.start_run(0)
    for room in 18:
        flight(route);route.settle(true,80,40)
        if not route.data.run.is_empty():route.choose_boon(["damage","defence","economy"][room%3])
    check("full story banks 18 drops, guaranteed first signature and an initial T1",route.data.best==18 and route.data.run.is_empty() and route.data.inventory.size()==18 and route.data.inventory[-1].tier==3 and route.data.contracts.size()==1)
    route.start_run(0,5)
    for i in 3:
        flight(route);route.settle(true,80,40)
        if not route.data.run.is_empty():route.choose_boon("damage")
    check("tower replay gives rare floor without repeating forced signature",route.data.inventory[-1].tier>=2 and route.data.contracts.size()==2)
    for character in 4:
        var account=fresh();account.rng.seed=1001+character;account.start_run(character)
        var playable:=true;var attack_slots:=true
        for room in 3:
            var encounter=sim();encounter.character_choices=[character,4];encounter.campaign_enabled=true;encounter.campaign_room=room;encounter.campaign_skills=account.data.skills.duplicate();encounter.campaign_stats=account.stats(character);encounter.wave_recipes=[account.recipe(room)];encounter.difficulty=0
            encounter._load_wave(0,int(account.data.run.hp),float(account.data.run.meter));encounter.ai_enabled=true
            for tick in 12000:
                var hero:Dictionary=encounter.fighters[0];var enemy:Dictionary=encounter.fighters[1]
                var command:Dictionary={"rush":true,"axis":signf(enemy.x-hero.x)}
                if enemy.guarding and absf(hero.x-enemy.x)<1.2:command["attack"]="grab"
                elif tick%63==0:command["attack"]="heavy";command["down"]=true
                encounter.tick(command)
                if encounter.squad_members.filter(func(f:Dictionary)->bool:return f.health>0 and f.state=="attack").size()>1:attack_slots=false
                if encounter.story_state in ["complete","failed"]:break
            if encounter.story_state!="complete":playable=false;break
            flight(account);account.settle(true,int(encounter.fighters[0].health),float(encounter.fighters[0].meter));account.choose_boon("damage")
            for skill in P.SKILLS:account.learn(skill.id)
        check("hero %d clears district one Easy using ordinary inputs and real earned loot, no healing"%character,playable)
        check("hero %d retains single attack slot"%character,attack_slots)
    var persistence=fresh();persistence.path="user://city-expansion/current.json"
    for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(persistence.path+suffix))
    persistence.start_run(2);flight(persistence);persistence.settle(true,73,42);persistence.choose_boon("damage");persistence.learn("double_jump")
    var loaded=P.new();loaded.path=persistence.path;loaded.load_data()
    check("v2 reload retains exact HP meter loot hero and temporary boon",loaded.error=="" and loaded.data.run.hero==2 and loaded.data.run.hp==73 and loaded.data.run.meter==42 and loaded.data.inventory.size()==1 and is_equal_approx(float(loaded.data.run.boons.damage),.05))
    file=FileAccess.open(persistence.path,FileAccess.WRITE);file.store_string("broken");file.close();loaded.load_data()
    check("corrupt primary recovers validated backup",loaded.error=="" and loaded.loaded_backup and not loaded.data.run.is_empty())
    loaded.save_data()
    check("recovery can safely save without replacing good backup with corrupt bytes",P.new().valid(JSON.parse_string(FileAccess.get_file_as_string(persistence.path+".bak"))))
    for suffix in ["",".bak"]:
        file=FileAccess.open(persistence.path+suffix,FileAccess.WRITE);file.store_string("broken");file.close()
    var corrupt=P.new();corrupt.path=persistence.path;corrupt.load_data()
    check("two bad saves retain original bytes and disable transactions",corrupt.error!="" and not corrupt.start_run(0) and FileAccess.get_file_as_string(corrupt.path)=="broken")
    var gates=sim();gates.campaign_enabled=true;gates.campaign_skills=[];gates.campaign_stats={}
    gates.fighters[0].chain=2;gates._start_attack(0,"light")
    check("held-J cannot bypass the locked launcher",gates.fighters[0].move=="finisher")
    gates.fighters[0].state="idle";gates.fighters[0].meter=100;gates._start_attack(0,"overdrive")
    check("locked overdrive resolves to the legal basic class skill",gates.fighters[0].move=="special")
    gates.fighters[0].y=2;gates.fighters[0].chain=2;gates._start_attack(0,"light")
    check("held air combo cannot bypass the locked finisher",gates.fighters[0].move=="air_kick")
    gates.fighters[0].state="idle";gates.fighters[0].jump_buffer=8;gates.fighters[0].air.chase_window=30;gates.fighters[0].air.chase_buffer=8
    gates._advance_fighter(0,{"jump":true})
    check("second jump and auto-chase buffers respect permissions",gates.fighters[0].jump_buffer==0 and gates.fighters[0].air.chase_buffer==0 and gates.fighters[0].air.chase_window==0)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    file=FileAccess.open(OUT+"rules.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks},"  "));file.close()
    print("EXPANSION RESULT ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
