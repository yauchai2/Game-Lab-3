extends SceneTree
const Story=preload("res://scripts/combat/story/story_simulation.gd")
const Base=preload("res://scripts/combat/enemies/squad_simulation.gd")
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":label,"passed":ok,"detail":detail});print("STORY ",label," ",ok)
    if not ok:push_error(label)
func fresh() -> RefCounted:
    var s=Story.new();s.last_service_enabled=true;s.character_choices=[0,4];s.begin_story();s.ai_enabled=false
    return s
func run() -> void:
    var s=fresh()
    check("three finite waves with role escalation",s.WAVES.size()==3 and s.squad_members.size()==3 and s.squad_members.all(func(f:Dictionary)->bool:return f.story_role=="grunt"))
    s.fighters[0].health=73;s.fighters[0].meter=42
    for f in s.squad_members:f.health=0
    s._finish_round()
    check("clear enters a safe break instead of ending match",s.story_state=="break" and s.phase=="fight")
    for i in 179:s.tick()
    check("break cannot spawn early",s.wave_index==0)
    s.tick()
    check("next wave carries HP and meter",s.wave_index==1 and s.squad_members.size()==4 and s.fighters[0].health==73 and s.fighters[0].meter==42)
    check("rushers have lower actual HP",s.squad_members[1].story_role=="rusher" and s.squad_members[1].health==28)
    var positions:Array=s.squad_members.map(func(f:Dictionary)->float:return f.x)
    s.fighters[0].health=0;s._finish_round()
    check("player death fails current wave",s.story_state=="failed" and s.winner==1)
    s.retry_story_wave()
    check("checkpoint repeats same wave and layout",s.wave_index==1 and positions==s.squad_members.map(func(f:Dictionary)->float:return f.x))
    check("retry supplies are explicit and bounded",s.fighters[0].health==73 and s.fighters[0].meter==60)
    s._load_wave(2,100,60)
    check("last wave has six real independent enemies and guards",s.squad_members.size()==6 and s.squad_members.filter(func(f:Dictionary)->bool:return f.story_role=="guard").size()==2)
    for f in s.squad_members:f.health=0
    s._finish_round()
    check("final clear is a real completed encounter",s.story_state=="complete" and s.phase=="match_over" and s.winner==0)
    # Actual guarded hit and legal throw use the inherited contact resolver.
    s=fresh();s._load_wave(2,100,60);s.arrival_left=0
    for id in range(1,6):s.squad_members[id].x=7
    s.squad_members[0].x=.8;s.squad_members[0].face=-1
    s.tick({"attack":"light"})
    for i in 12:s.tick()
    check("shield role actually blocks damage",s.squad_members[0].health==48 and s.squad_members[0].guard<100)
    s=fresh();s._load_wave(2,100,60);s.arrival_left=0
    for id in range(1,6):s.squad_members[id].x=7
    s.squad_members[0].x=.7;s.squad_members[0].face=-1
    var thrown:=false;s.tick({"attack":"grab"})
    for i in 30:
        s.tick()
        for e in s.events:
            if e.kind=="hit" and e.get("move","")=="grab":thrown=true
    check("shield can be countered by an ordinary throw",thrown and s.squad_members[0].health<48)
    s=fresh();s._load_wave(1,100,60);s.arrival_left=0;s.squad_clock=100;s.next_attack_at=0;s.squad_focus=1;s.fighters[1]=s.squad_members[1];s.ai_enabled=true
    
    for id in [0,2,3]:s.squad_members[id].x=-7
    s.fighters[1].x=3;s.tick()
    var rush:Dictionary=s.squad_members[1]
    check("rusher visibly commits before dashing",rush.rush_charge>0 and rush.state!="dash")
    s.fighters[0].x=5
    for i in 24:s.tick()
    check("rusher cannot retarget through its committed tell",rush.vx<0 and rush.rush_cd>0)
    # Real heavy contact launches a body into targets outside original reach.
    s=fresh();s.arrival_left=0
    for id in 3:s.squad_members[id].x=1.3+id*1.5;s.squad_members[id].face=-1
    s.tick({"attack":"heavy","down":true})
    var impacts:Array=[];var max_counts:Dictionary={};var hero_hp:int=s.fighters[0].health
    for i in 140:
        s.tick()
        for e in s.events:
            if e.kind=="story_chain_hit":impacts.append(e);max_counts[e.squad_id]=max_counts.get(e.squad_id,0)+1
    check("real heavy creates at least one swept body impact",not impacts.is_empty(),impacts)
    check("one chain cannot hit a target twice",max_counts.values().all(func(n:int)->bool:return n==1))
    check("player cannot be hurt by own body chain",s.fighters[0].health==hero_hp)
    check("body chains expire without permanent airborne locks",s.body_chain.bodies.is_empty())
    # Fast sweep: source crosses target in one tick, then cannot hit it again.
    s=fresh();s.squad_members[0].x=0;s.squad_members[1].x=2;s.squad_members[2].x=6
    var old:Array=[Vector2(0,0),Vector2(2,0),Vector2(6,0)]
    s.body_chain.arm(s.squad_members[0],99,20);s.squad_members[0].x=4;s.squad_members[0].vx=240
    s.body_chain.advance(s,old)
    check("fast swept collision cannot tunnel through target",s.squad_members[1].health==23)
    var hp:int=s.squad_members[1].health;s.body_chain.advance(s,old)
    check("repeated overlap cannot duplicate chain damage",s.squad_members[1].health==hp)
    s=fresh();s._load_wave(2,100,60)
    var sweep:Array=[]
    for id in 6:s.squad_members[id].x=float(id);sweep.append(Vector2(id,0))
    s.body_chain.arm(s.squad_members[0],100,20);s.squad_members[0].x=7;s.squad_members[0].vx=420
    s.body_chain.advance(s,sweep)
    var collisions:Array=s.events.filter(func(e:Dictionary)->bool:return e.kind=="story_chain_hit")
    check("root budget stops at four secondary targets",collisions.size()==4 and s.squad_members[5].health==s.squad_members[5].max_health)
    check("damage falls off across the shared root",collisions.map(func(e:Dictionary)->int:return e.damage)==[12,8,5,3])
    check("chain resource reward occurs once per source attack",s.fighters[0].meter==64)
    s=fresh();s._load_wave(2,100,60)
    for f in s.squad_members:f.x=7
    s.squad_members[0].x=2;s.squad_members[0].face=-1;s.squad_members[0].guarding=true
    s.squad_members[1].x=0
    var shield_old:Array=[]
    for f in s.squad_members:shield_old.append(Vector2(f.x,0))
    s.body_chain.arm(s.squad_members[1],102,20);s.squad_members[1].x=3;s.squad_members[1].vx=240
    s.body_chain.advance(s,shield_old)
    check("facing shield blocks a body without losing HP",s.squad_members[0].health==48 and s.squad_members[0].guard==70)
    s=fresh();s.squad_members[0].health=0;s.squad_members[0].x=0;s.squad_members[1].x=2;s.squad_members[2].x=6
    s.body_chain.arm(s.squad_members[0],101,20);s.squad_members[0].vx=240
    s.body_chain.advance(s,[Vector2(0,0),Vector2(2,0),Vector2(6,0)])
    check("settled corpse cannot become a damaging projectile",s.squad_members[1].health==35)
    s.squad_members[1].health=0;s.squad_members[1].flash=12
    for i in 20:s.tick()
    check("waiting story corpses do not stay white forever",s.squad_members[1].flash==0)
    s.end_squad()
    check("leaving story removes all encounter data",not s.story_enabled and not s.squad_enabled and s.body_chain.roots.is_empty())
    var a=Story.new();var b=Base.new();a.ai_enabled=false;b.ai_enabled=false;a.phase="fight";b.phase="fight"
    var rng=RandomNumberGenerator.new();rng.seed=1137;var same:=true
    for i in 1200:
        var command:Dictionary={"axis":rng.randi_range(-1,1)}
        if i%17==0:command["attack"]="light"
        if i%53==0:command["jump"]=true
        a.tick(command);b.tick(command)
        if a.fighters!=b.fighters or a.events!=b.events:same=false
    check("story-off simulation matches original squad class",same)
    a=fresh();b=fresh();same=true
    for i in 2400:
        var command:Dictionary={"rush":true,"axis":signf(a.fighters[1].x-a.fighters[0].x)}
        if i%67==0:command["attack"]="heavy";command["down"]=true
        a.tick(command);b.tick(command)
        if a.fighters!=b.fighters or a.events!=b.events or a.story_state!=b.story_state:same=false
        if a.story_state=="failed":a.retry_story_wave();b.retry_story_wave()
    check("mixed wave/chain replay remains deterministic",same)
    for character in 4:
        s=Story.new();s.last_service_enabled=true;s.character_choices=[character,4];s.difficulty=0;s.begin_story()
        var counts:Dictionary={"hits":0,"chains":0,"ticks":0,"attackers":0}
        for tick in 12000:
            var hero:Dictionary=s.fighters[0];var enemy:Dictionary=s.fighters[1]
            var command:Dictionary={"rush":true,"axis":signf(enemy.x-hero.x)}
            if enemy.guarding and absf(hero.x-enemy.x)<1.2:command["attack"]="grab"
            elif tick%63==0:command["attack"]="heavy";command["down"]=true
            s.tick(command);counts.ticks=tick+1
            counts.attackers=maxi(counts.attackers,s.squad_members.filter(func(f:Dictionary)->bool:return f.health>0 and f.state=="attack").size())
            for e in s.events:
                if e.kind=="hit":counts.hits+=1
                if e.kind=="story_chain_hit":counts.chains+=1
            if s.story_state in ["complete","failed"]:break
        check("hero %d clears Easy through ordinary inputs without reset"%character,s.story_state=="complete" and counts.hits>0,counts)
        check("hero %d encounter respects one attack slot"%character,counts.attackers<=1)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var out:="res://../docs/evidence/story-waves/"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
    FileAccess.open(out+"rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed},"  "))
    quit(1 if failed else 0)
