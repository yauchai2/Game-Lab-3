extends SceneTree
const Profile=preload("res://scripts/combat/city/city_profile.gd")
const Story=preload("res://scripts/combat/story/story_simulation.gd")
class FailingProfile:
    extends "res://scripts/combat/city/city_profile.gd"
    func save_data() -> bool:return false
var checks:Array=[]
const OUT="res://../docs/evidence/city-hub/"
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("CITY ",label," ",ok)
    if not ok:push_error(label)
func flight(p:RefCounted) -> void:p.data.run["in_flight"]=true
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var p=Profile.new();p.path="user://city-verification/profile.json"
    for suffix in ["",".tmp",".bak"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(p.path+suffix))
    p.load_data()
    check("fresh city does not grant free currency or advanced abilities",p.data.credits==0 and p.data.skills.is_empty())
    check("locked districts cannot be entered",not p.start_run(0,1))
    check("new expedition saves hero and first room",p.start_run(2) and int(p.data.run.hero)==2 and int(p.data.run.room)==0)
    check("cannot overwrite live expedition",not p.start_run(1))
    check("cannot settle before an encounter starts",not p.settle(true,80,42))
    flight(p)
    check("clear banks currency, permanent point, parts and exact HP",p.settle(true,73,42) and p.data.credits==45 and p.data.points==1 and p.data.run.hp==73 and p.data.run.room==1)
    check("settlement cannot pay twice",not p.settle(true,73,42) and p.data.credits==45)
    check("advanced skill milestone cannot be skipped",not p.learn("overdrive") and not p.learn("launcher"))
    check("first clear guarantees free double jump permission",p.learn("double_jump") and not p.learn("double_jump"))
    check("boon applies once and remains run-only",p.choose_boon("damage") and not p.choose_boon("damage") and is_equal_approx(p.stats(2).damage,.05))
    check("tree connectivity prevents skipping first node",not p.allocate(2,"break_2"))
    check("one available point changes the selected hero only",p.allocate(2,"break_1") and not p.allocate(2,"air_1") and is_equal_approx(p.stats(2).damage,.09) and is_equal_approx(p.stats(1).damage,.05))
    check("free respec returns full budget",p.respec(2) and p.data.talents[2].is_empty() and p.allocate(2,"air_1"))
    var reloaded=Profile.new();reloaded.path=p.path;reloaded.load_data()
    check("disk reload preserves run, unlocks, coins and allocated tree",reloaded.error=="" and int(reloaded.data.run.room)==1 and "double_jump" in reloaded.data.skills and reloaded.data.talents[2]==["air_1"] and int(reloaded.data.credits)==45)
    check("paid healing applies exact capped amount",p.heal() and p.data.run.hp==100 and p.data.credits==20 and not p.heal())
    check("insufficient money cannot roll items",p.pull(0).is_empty() and p.data.pulls==0)
    p.data.credits=1000;p.data.pity=9;p.data.unique_pity=39;p.rng.seed=41
    var gear:Dictionary=p.pull(0)
    check("40th pull guarantees signature with one debit and auto-equip",gear.tier==3 and p.data.credits==900 and p.data.inventory.size()==1 and p.data.gear[0].id==gear.id)
    check("signature resets both pity counters",p.data.pity==0 and p.data.unique_pity==0)
    check("equipped item cannot be recycled",not p.salvage(int(gear.id)))
    p.data.pity=9
    var next:Dictionary=p.pull(0)
    check("10th pull guarantees rare or better",next.tier>=2 and p.data.pity==0)
    check("changing equipment retains old item and permits recycling",p.equip(int(next.id)) and p.salvage(int(gear.id)) and p.data.inventory.size()==1)
    flight(p)
    check("defeat ends run but preserves coins, gear, skill and tree",p.settle(false,0,0) and p.data.run.is_empty() and p.data.credits==800 and p.data.skills==["double_jump"] and p.data.talents[2]==["air_1"])
    check("defeat clears temporary damage boon",is_equal_approx(p.stats(2).damage,float(next.amount)))
    var file:=FileAccess.open(p.path,FileAccess.WRITE);file.store_string("broken");file.close()
    reloaded.load_data()
    check("corrupt primary recovers a validated backup",reloaded.error=="" and not reloaded.data.skills.is_empty())
    file=FileAccess.open(p.path+".bak",FileAccess.WRITE);file.store_string("broken");file.close()
    var broken=Profile.new();broken.path=p.path;broken.load_data()
    check("two invalid saves disable transactions without overwrite",broken.error!="" and not broken.start_run(0) and FileAccess.get_file_as_string(p.path)=="broken")
    var fault=FailingProfile.new();fault.data=p.data.duplicate(true)
    var old:Dictionary=fault.data.duplicate(true)
    check("save failure rolls back debits and generated gear",fault.pull(1).is_empty() and fault.data==old and fault.error!="")
    p.path="";p.data.parts=20;p.data.credits=800
    check("permanent class skill upgrade pays exact cost",p.upgrade_skill(2) and p.data.skill_levels[2]==1 and p.data.parts==18 and p.data.credits==770 and is_equal_approx(p.stats(2).skill_damage,.05))
    var sim=Story.new();sim.last_service_enabled=true;sim.character_choices=[0,4];sim.begin_story();sim.ai_enabled=false
    var original:Dictionary=sim.move_for(sim.fighters[0],"jab")
    sim.campaign_enabled=true;sim.campaign_skills=[];sim.campaign_stats={"damage":.2,"defence":.2,"economy":.2}
    sim.fighters[0].chain=2;sim._start_attack(0,"light")
    check("held light third hit cannot bypass locked launcher",sim.fighters[0].move=="finisher")
    sim.fighters[0].state="idle";sim._start_attack(0,"overdrive")
    check("locked overdrive falls back to legal basic class skill",sim.fighters[0].move=="special")
    sim.fighters[0].y=2;sim.fighters[0].chain=2;sim._start_attack(0,"light")
    check("held aerial chain cannot bypass locked finisher",sim.fighters[0].move=="air_kick")
    sim.fighters[0].state="idle";sim.fighters[0].air.jumps=1;sim.fighters[0].jump_buffer=8;sim.fighters[0].air.chase_window=30;sim.fighters[0].air.chase_buffer=8
    sim._advance_fighter(0,{"jump":true})
    check("locked second jump and buffered auto-chase are blocked",sim.fighters[0].jump_buffer==0 and sim.fighters[0].air.chase_buffer==0 and sim.fighters[0].air.chase_window==0)
    check("permanent and temporary stats change real move damage and cost",sim.move_for(sim.fighters[0],"jab").damage>original.damage and sim.skill_cost(sim.fighters[0],"special")==40)
    sim.campaign_skills=["launcher","overdrive"];sim.fighters[0].y=0;sim.fighters[0].state="idle";sim.fighters[0].meter=100
    sim._start_attack(0,"launcher")
    check("earned permissions enable the original launcher",sim.fighters[0].move=="launcher")
    sim.end_squad();sim.begin_story()
    check("leaving campaign fully restores M1 recipes and full permissions",not sim.campaign_enabled and sim.wave_recipes==sim.WAVES and sim.campaign_stats.is_empty())
    for room in 18:
        var recipe:Array=p.recipe(room)
        check("encounter %d respects six actor budget"%room,recipe.size()>=3 and recipe.size()<=6)
    var route=Profile.new();route.path="";route.start_run(0)
    for room in 18:
        flight(route);route.settle(true,80,50)
        if not route.data.run.is_empty():route.choose_boon(["damage","defence","economy"][room%3])
    check("all eighteen settlements unlock six districts and end the run",route.data.best==18 and route.data.run.is_empty() and route.data.points==8)
    check("cleared tower can be replayed without an entrance fee",route.start_run(0,5) and route.data.run.room==15)
    for character in 4:
        var playable:=true;var attack_cap:=true
        var hp:=100;var meter:=60.0
        for room in 3:
            var encounter=Story.new();encounter.last_service_enabled=true;encounter.character_choices=[character,4];encounter.difficulty=0;encounter.begin_story()
            encounter.campaign_enabled=true;encounter.campaign_room=room;encounter.campaign_skills=["double_jump"] if room>0 else []
            encounter.campaign_stats={"damage":.05*room};encounter.wave_recipes=[p.recipe(room)];encounter._load_wave(0,hp,meter)
            for tick in 12000:
                var hero:Dictionary=encounter.fighters[0];var enemy:Dictionary=encounter.fighters[1]
                var command:Dictionary={"rush":true,"axis":signf(enemy.x-hero.x)}
                if enemy.guarding and absf(hero.x-enemy.x)<1.2:command["attack"]="grab"
                elif tick%63==0:command["attack"]="heavy";command["down"]=true
                encounter.tick(command)
                if encounter.squad_members.filter(func(f:Dictionary)->bool:return f.health>0 and f.state=="attack").size()>1:attack_cap=false
                if encounter.story_state in ["complete","failed"]:break
            if encounter.story_state!="complete":playable=false;break
            hp=int(encounter.fighters[0].health);meter=float(encounter.fighters[0].meter)
        check("hero %d clears first district Easy using ordinary inputs, no gear or healing"%character,playable)
        check("hero %d campaign keeps one active attack slot"%character,attack_cap)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    file=FileAccess.open(OUT+"rules.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks},"  "));file.close()
    print("CITY RESULT ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
