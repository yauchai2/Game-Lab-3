extends SceneTree
const OUT="res://../docs/evidence/tactical-modules/"
var checks:Array=[]
var session:Node
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("MODULES_NATIVE ",label," ",ok)
    if not ok:push_error(label)
func frames(count:=3) -> void:
    for i in count:await process_frame
    await RenderingServer.frame_post_draw
func key(code:Key,down:bool) -> void:
    var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;Input.parse_input_event(event);await frames(2)
func step(count:int) -> void:
    for i in count:session._combat_step();session._process(1.0/60)
func press(code:Key) -> void:
    await key(code,true);step(1);await key(code,false)
func control(hub:Node,act:String) -> Control:
    for child in hub.stack.find_children("*","Control",true,false):
        if child.get_meta("act","")==act:return child
    return null
func pick(hub:Node,act:String,index:int) -> void:
    var picker:OptionButton=control(hub,act);hub.scroll.ensure_control_visible(picker);await frames();picker.grab_focus()
    await key(KEY_SPACE,true);await key(KEY_SPACE,false)
    # Each call starts from NONE, and the desired module's earlier choices are enabled.
    for i in index:await key(KEY_DOWN,true);await key(KEY_DOWN,false)
    await key(KEY_ENTER,true);await key(KEY_ENTER,false)
func shot(name:String) -> void:
    session._process(1.0/60);await frames();root.get_texture().get_image().save_png(OUT+name+".png")
func _initialize() -> void:call_deferred("run")
func run() -> void:
    session=preload("res://scenes/combat/street_fight.tscn").instantiate();session.preferences_path="";session.city_save_path="";root.add_child(session)
    session.set_process(false);session.set_physics_process(false);session.audio.muted=true;await frames(8)
    var campaign=session.city_campaign;var p=campaign.profile;var hub=campaign.hub
    p.data.best=18;campaign.open_city();session.set_character(0,1);campaign.selected_hero=1;session.set_language("zh");hub.open_station(0);await frames()
    check("second support is a real selector on both equipped skills",control(hub,"tactic:0:attachments")!=null and control(hub,"tactic:1:attachments")!=null)
    check("RIVET shot enables return and disables area conversion",not control(hub,"tactic:0:attachments").is_item_disabled(1) and control(hub,"tactic:0:attachments").is_item_disabled(2))
    await pick(hub,"tactic:0:attachments",1)
    check("actual dropdown fits return module",p.data.tactics[1].attachments[0]==1)
    check("pierce is disabled with a readable incompatibility tooltip",control(hub,"tactic:0:supports").is_item_disabled(1) and control(hub,"tactic:0:supports").get_popup().get_item_tooltip(1)!="")
    hub.scroll.ensure_control_visible(control(hub,"tactic:0:module_info"));await shot("return-build-zh")
    session.set_language("en");hub.open_station(0);await frames();hub.scroll.ensure_control_visible(control(hub,"tactic:0:module_info"));await shot("return-build-en")
    campaign.flow.force_live=false;campaign.depart();session.round_theatre.clear();await frames()
    var sim=session.sim;var f:Dictionary=sim.fighters[0];sim.ai_enabled=false;f.x=0;f.face=1;f.meter=100
    for target in sim.squad_members:target.x=7;target.health=500;target.max_health=500
    sim.squad_members[0].x=1.4
    await press(KEY_Q);var turned:=false;var hits:=0
    for i in 75:
        step(1)
        hits+=sim.events.filter(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("tactic",false)).size()
        if not turned and not sim.tactics.shots.is_empty() and sim.tactics.shots[0].get("leg",0)==1:
            turned=true;await shot("return-flight")
    check("real Q return reverses and cannot hit its first body twice",turned and hits==1 and f.meter==80 and sim.tactics.shots.is_empty())
    p.data.run={};campaign.show_city();campaign.selected_hero=1;hub.open_station(0);await frames()
    # The return choice is disabled for the ground line; Down skips it to DELAY.
    await pick(hub,"tactic:1:attachments",1)
    check("actual compatible picker skips the disabled return choice",p.data.tactics[1].attachments[1]==2)
    session.set_language("zh");hub.open_station(0);await frames();hub.scroll.ensure_control_visible(control(hub,"tactic:1:module_info"));await shot("delay-build-zh")
    campaign.depart();session.round_theatre.clear();await frames();sim=session.sim;f=sim.fighters[0];sim.ai_enabled=false;f.x=0;f.face=1;f.meter=100
    for target in sim.squad_members:target.x=7;target.health=500;target.max_health=500
    sim.squad_members[0].x=2.8
    await press(KEY_I);step(25)
    check("real I leaves a visible fixed warning with no early damage",sim.tactics.shots.size()==1 and sim.tactics.shots[0].kind=="zone" and sim.tactics.shots[0].age<24 and sim.squad_members[0].health==500)
    await shot("delay-warning-zh");var bursts:=0;hits=0
    for i in 40:
        step(1);bursts+=sim.events.filter(func(e:Dictionary)->bool:return e.kind=="tactic_pulse").size();hits+=sim.events.filter(func(e:Dictionary)->bool:return e.kind=="hit" and e.get("tactic",false)).size()
        if bursts>0 and hits==1:await shot("delay-burst-zh");break
    check("warning becomes one actual paid damage event",bursts==1 and hits==1 and sim.squad_members[0].health<500 and f.meter==75)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"native.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"  "))
    session.return_to_title();session.queue_free();await frames(8);quit(1 if failed else 0)
