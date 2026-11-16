extends SceneTree
const OUT="res://../docs/evidence/module-counterplay/"
var checks:Array=[]
var session:Node
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("RESPONSE_NATIVE ",label," ",ok)
    if not ok:push_error(label)
func frames(count:=3) -> void:
    for i in count:await process_frame
    await RenderingServer.frame_post_draw
func key(code:Key,down:bool) -> void:
    var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;Input.parse_input_event(event);await frames(2)
func step(count:int) -> void:
    for i in count:session._combat_step();session._process(1.0/60)
func shot(name:String) -> void:
    session._process(1.0/60);await frames();root.get_texture().get_image().save_png(OUT+name+".png")
func _initialize() -> void:call_deferred("run")
func run() -> void:
    session=preload("res://scenes/combat/street_fight.tscn").instantiate();session.preferences_path="";session.city_save_path="";root.add_child(session)
    session.set_process(false);session.set_physics_process(false);session.audio.muted=true;await frames(8)
    var campaign=session.city_campaign;var p=campaign.profile
    p.data.best=18;campaign.open_city();session.set_character(0,1);campaign.selected_hero=1;p.configure_tactic(1,1,"attachments",2);session.set_language("zh")
    campaign.flow.force_live=false;campaign.depart();session.round_theatre.clear();await frames()
    var s=session.sim;var hero:Dictionary=s.fighters[0];s.ai_enabled=false;hero.x=0;hero.face=1;hero.meter=100
    for enemy in s.squad_members:enemy.x=7
    await key(KEY_I,true);step(1);await key(KEY_I,false);step(23)
    check("actual I creates a paid warning before enemy response",hero.meter==75 and s.tactics.shots.size()==1 and s.tactics.shots[0].kind=="zone")
    var grunt:Dictionary=s.squad_members[0];var guard:Dictionary=s.squad_members[1];var heavy:Dictionary=s.squad_members[2]
    var fixtures:Array=[[grunt,"grunt",2.8],[guard,"guard",3.5],[heavy,"heavy",4.0]]
    for fixture in fixtures:
        var enemy:Dictionary=fixture[0];enemy.story_role=fixture[1];enemy.x=fixture[2];enemy.health=500;enemy.max_health=500;enemy.state="idle";enemy.arrival=0;enemy.buffer="";enemy.buffer_ttl=0
    s.ai_enabled=true;s.arrival_left=0;s.next_attack_at=99999;s.squad_clock=36
    var stepped:=false;var braced:=false;var captured:=false;var parries:=0
    for i in 23:
        step(1)
        if s.events.any(func(e:Dictionary)->bool:return e.kind=="tactic_step_out"):stepped=true
        if s.events.any(func(e:Dictionary)->bool:return e.kind=="tactic_brace"):braced=true
        parries+=s.events.filter(func(e:Dictionary)->bool:return e.kind=="parry" and e.get("tactic",false)).size()
        if not captured and grunt.get("tactic_response_left",0)>0 and guard.get("tactic_response_left",0)>0:
            captured=true;await shot("response-zh")
    check("live native grunt and guard publish distinct reaction events",stepped and braced and captured)
    check("guard reaction uses ordinary guarding without a perfect parry",not guard.parry_allowed and parries==0)
    check("heavy keeps its role without a new free response",heavy.get("tactic_response_left",0)==0 and heavy.invuln==0)
    check("stepping uses actual body movement with no invulnerability",absf(grunt.x-2.8)>.05 and grunt.invuln==0)
    check("responses cannot refund the player's paid area",hero.meter==75)
    var cooldown:int=grunt.get("tactic_response_cd",0)
    await key(KEY_ESCAPE,true);await key(KEY_ESCAPE,false);step(6)
    check("pause freezes the enemy reaction cooldown",session.screen=="pause" and grunt.get("tactic_response_cd",0)==cooldown)
    await key(KEY_ESCAPE,true);await key(KEY_ESCAPE,false)
    session.set_language("en");await shot("after-response-en")
    session.return_to_title();check("leaving story clears live tactical effects",session.sim.tactics.shots.is_empty())
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"native.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"  "));session.queue_free();await frames(8);quit(1 if failed else 0)
