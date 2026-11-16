extends SceneTree
const S=preload("res://scripts/combat/story/story_simulation.gd")
const P=preload("res://scripts/combat/city/city_profile.gd")
const View=preload("res://scripts/combat/tactics/presentation.gd")
const OUT="res://../docs/evidence/airdrop-module/"
var checks:Array=[]
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("AIRDROP ",label," ",ok)
    if not ok:push_error(label)
func setup(hero:int,airborne:=true) -> RefCounted:
    var s=S.new();s.ai_enabled=false;s.last_service_enabled=true;s.character_choices=[hero,4];s.campaign_enabled=true;s.campaign_stats={"tactic_unlocked":6};s.wave_recipes=[["grunt"]];s.begin_story();s.arrival_left=99999
    s.tactics.enabled=true;s.tactics.config=[s.TacticalSkills.defaults(),{}];s.tactics.config[0].attachments[0]=3
    s.fighters[0].x=0;s.fighters[0].face=1;s.fighters[0].meter=100;s.fighters[1].x=7;s.fighters[1].health=500
    if airborne:s.fighters[0].y=1.4;s.fighters[0].vy=0;s.fighters[0].air.phase="fall"
    return s
func steps(s:RefCounted,n:int) -> Array:
    var events:Array=[]
    for i in n:s.tick({});events.append_array(s.events)
    return events
func _initialize() -> void:
    root.get_node("GameLocale").set_language("en")
    for hero in 4:
        for id in 6:
            var p=P.new();p.path="";p.data.best=18;var before:String=JSON.stringify(p.data);var ok:bool=p.configure_tactic(hero,id,"attachments",3)
            check("hero%d skill%d airdrop compatibility is transactional"%[hero,id],ok==(hero in [0,3] and id==0) and (p.valid(p.data) if ok else JSON.stringify(p.data)==before))
    for hero in [0,3]:
        var s=setup(hero);var f:Dictionary=s.fighters[0];f.air.double_used=true;f.air.chase_used=true;f.air.stall_left=5
        check("hero%d airborne HUD advertises a genuinely legal paid cast"%hero,View.slot_view(s,0).ready and s.tactics.quote(s,0,0).price==15)
        s.tick({"attack":"tactic_a"})
        check("hero%d air cast spends normal fee and shared fast-fall budget"%hero,f.state=="attack" and f.meter==85 and f.air.fast_used and f.tactical.air_debt==8)
        check("hero%d air cast preserves spent jump and chase resources"%hero,f.air.double_used and f.air.chase_used and f.air.stall_left<5)
        steps(s,16)
        check("hero%d projectile follows a real downward path"%hero,not s.tactics.shots.is_empty() and s.tactics.shots[0].get("airdrop",false) and s.tactics.shots[0].fall_speed>0)
        var events:Array=steps(s,70)
        check("hero%d landing pays its recovery commitment once"%hero,events.filter(func(e:Dictionary)->bool:return e.kind=="tactic_landing").size()==1 and f.tactical.air_debt==0)
        check("hero%d air effect has a finite life"%hero,s.tactics.shots.is_empty())
        if hero==3:check("air connector creates exactly one real ground node",f.service.nodes.size()==1 and f.service.nodes[0].x>0 and f.meter==85)
        s=setup(hero);f=s.fighters[0];f.air.fast_used=true;var meter:float=f.meter;s.tick({"attack":"tactic_a"})
        check("hero%d spent fast fall rejects without borrowing energy"%hero,f.meter==meter and not f.tactical.air_cast)
        s=setup(hero,false);f=s.fighters[0];s.tick({"attack":"tactic_a"});steps(s,18)
        check("hero%d ground casts retain ordinary behavior"%hero,not f.tactical.air_cast and f.tactical.air_debt==0 and not s.tactics.shots.is_empty() and not s.tactics.shots[0].get("airdrop",false))
    var s=setup(0);s.fighters[1].x=3;s.tick({"attack":"tactic_a"});var events:Array=steps(s,70)
    check("aerial tag can make one real grounded contact and mark",events.filter(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("tactic",false)).size()==1 and s.fighters[0].tactical.mark_ttl>0)
    s=setup(0);s._start_attack(0,"tactic_a");steps(s,12)
    check("airborne tag actually pays its damage tradeoff",not s.tactics.shots.is_empty() and s.tactics.shots[0].data.damage==6)
    s=setup(0);s.tactics.config[0].skills=[0,2];s.tick({"attack":"tactic_a"});s.fighters[0].state="idle";s.fighters[0].buffer="";s.fighters[0].buffer_ttl=0;s.tick({"attack":"tactic_b"})
    check("air drop cannot also buy ZIP's diving tactic in the same jump",s.fighters[0].move!="tactic_b" and s.fighters[0].meter==85)
    s=setup(3);s.tick({"attack":"tactic_a"});var control=setup(3);control.tick({"attack":"tactic_a"});control.fighters[0].tactical.air_debt=0
    var free_at:=-1;var debt_at:=-1
    for tick in 100:
        s.tick({});control.tick({})
        if free_at<0 and control.fighters[0].state=="idle" and control.fighters[0].y<=.01:free_at=tick
        if debt_at<0 and s.fighters[0].state=="idle" and s.fighters[0].y<=.01:debt_at=tick
    check("landing commitment adds eight real ticks after attack recovery",free_at>=0 and debt_at-free_at==8)
    s=setup(0,false);var f:Dictionary=s.fighters[0];f.tactical.air_debt=8
    s.tick({"jump":true});check("queued jump cannot cancel landing commitment",f.state=="landing" and f.y==0)
    events=steps(s,12);check("queued jump survives the extra recovery instead of being eaten",events.any(func(e:Dictionary)->bool:return e.kind=="jump"))
    s=setup(0,false);f=s.fighters[0];f.tactical.air_debt=8;s.tick({"attack":"heavy"});check("queued attack waits through the landing commitment",f.state=="landing")
    events=steps(s,12);check("queued attack starts after recovery",f.move=="heavy" and f.state=="attack")
    s=setup(0,false);f=s.fighters[0];f.tactical.air_debt=8;s.tactics.enabled=false;s.tick({"jump":true})
    check("disabled story tactics never impose their debt on standard modes",f.state!="landing")
    s=setup(3);s.tick({"attack":"tactic_a"});s.hitstop=3;var debt:int=s.fighters[0].tactical.air_debt;steps(s,3)
    check("hitstop cannot advance or discard landing debt",s.fighters[0].tactical.air_debt==debt)
    s=setup(0,false);f=s.fighters[0];f.tactical.air_debt=8;f.state="stun";f.stun=12;s.tick({})
    check("a hurt landing serves actual hitstun instead of adding hidden debt",f.state=="stun" and f.stun==11 and f.tactical.air_debt==0)
    events=steps(s,15);check("recovering from a hurt landing cannot trigger a late second lockout",f.state=="idle" and not events.any(func(e:Dictionary)->bool:return e.kind=="tactic_landing"))
    s=setup(0);f=s.fighters[0];f.tactical.air_debt=8;f.state="stun";f.stun=12;s.tick({})
    check("an airborne interruption clears the future debt without erasing hitstun",f.y>.01 and f.state=="stun" and f.tactical.air_debt==0)
    for version in [6,7]:migration(version)
    var malformed=P.new();malformed.path="user://airdrop-test/malformed6.json"
    for source in [malformed.path,malformed.path+".bak"]:
        if FileAccess.file_exists(source):DirAccess.remove_absolute(ProjectSettings.globalize_path(source))
    var broken:Dictionary=malformed.fresh();broken.version=6;broken.tactics[0].erase("attachments")
    FileAccess.open(malformed.path,FileAccess.WRITE).store_string(JSON.stringify(broken));malformed.load_data()
    check("migration rejects a schema6 save missing its mandatory module record",malformed.error!="")
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"rules.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"  "));quit(1 if failed else 0)
func migration(version:int) -> void:
    var p=P.new();p.path="user://airdrop-test/v%d.json"%version;DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p.path.get_base_dir()))
    p.data.best=18;p.data.credits=135;p.configure_tactic(0,0,"attachments",1);p.store_build(0,0)
    var old:Dictionary=p.data.duplicate(true);old.version=version;var bytes:String=JSON.stringify(old);FileAccess.open(p.path,FileAccess.WRITE).store_string(bytes);p.load_data()
    check("schema%d preserves original bytes, money and old module preset"%version,p.error=="" and p.data.version==P.SCHEMA and p.data.credits==135 and FileAccess.get_file_as_string(p.path)==bytes and p.data.build_presets[0][0].tactics.attachments[0]==1)
    p.configure_tactic(0,0,"attachments",3);p.store_build(0,1);p.save_data();var reloaded=P.new();reloaded.path=p.path;reloaded.load_data()
    check("schema%d air-drop preset survives reload with integer module ID"%version,reloaded.error=="" and reloaded.load_build(0,1) and reloaded.data.tactics[0].attachments[0]==3)
