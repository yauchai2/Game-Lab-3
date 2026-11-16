extends SceneTree
const OUT="res://../docs/evidence/tactics-usability/"
const View=preload("res://scripts/combat/tactics/presentation.gd")
const L10n=preload("res://scripts/combat/ui/locale_text.gd")
var checks:Array=[]
var session:Node
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("READINESS_NATIVE ",label," ",ok)
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
func shot(label:String) -> void:
    session._process(1.0/60);await frames();root.get_texture().get_image().save_png(OUT+label+".png")
func find_act(parent:Node,act:String) -> Control:
    for child in parent.find_children("*","Control",true,false):
        if child.get_meta("act","")==act:return child
    return null
func _initialize() -> void:call_deferred("run")
func run() -> void:
    session=preload("res://scenes/combat/street_fight.tscn").instantiate();session.preferences_path="";session.city_save_path="";root.add_child(session)
    session.set_process(false);session.set_physics_process(false);session.audio.muted=true;await frames(8)
    for language in ["en","zh"]:
        session.set_language(language)
        var overflow:Array=[]
        for hero in 4:
            for name in View.Skills.NAMES[hero]:
                if session.hud.font.get_string_size("Q  "+L10n.text(name),HORIZONTAL_ALIGNMENT_LEFT,-1,20).x>288:overflow.append(name)
        check(language+" enlarged tactical names fit both HUD cards",overflow.is_empty())
        for text in ["HOLD / +10 ENERGY","RELEASE / QUICK SHOT","LEARN / CLEAR 15","NEED 35 ENERGY","JUMP TO DIVE","DIVE USED / LAND FIRST","LAND TO CAST","DODGE / ROUTES 1/2","NEED ANOTHER TARGET","HOLD L TO PRELOAD","PLACE NODES 1/2","PLACE ONE NODE","WAIT FOR ACTIVE TACTICS","CONVERT L / 20 ENERGY","RECOVERING","FOLLOW / 0 ENERGY","RETURN / 0 ENERGY","RELEASE GUARD TO CAST","EMITTER READY / FIRE"]:
            if session.hud.font.get_string_size(L10n.text(text),HORIZONTAL_ALIGNMENT_LEFT,-1,18).x>288:overflow.append(text)
        check(language+" enlarged actionable hints fit both HUD cards",overflow.is_empty())
    var campaign=session.city_campaign;var p=campaign.profile;var hub=campaign.hub
    p.data.best=18;p.data.credits=90;p.data.parts=8
    campaign.open_city();session.set_character(0,3);campaign.selected_hero=3;p.equip_tactic(3,0,4);p.configure_tactic(3,4,"supports",1)
    p.craft_tactic_gear(3,"tactic_anchor");p.equip(int(p.data.inventory[0].id),3)
    session.set_language("zh");hub.open_station(0);await frames()
    var fee_text:String=L10n.text("%d ENERGY / %.1fs")%[25,394.0/60.0]
    check("skill page displays modified cooldown instead of base seven seconds",hub.stack.find_children("*","Label",true,false).any(func(n:Label)->bool:return n.text.contains(fee_text)))
    hub.scroll.ensure_control_visible(find_act(hub.stack,"tactic:0:variants"));await shot("modified-cooldown-zh")
    campaign.flow.force_live=false;campaign.depart();session.round_theatre.clear();await frames()
    var sim=session.sim;var f:Dictionary=sim.fighters[0]
    sim.arrival_left=9999;f.x=-4;f.meter=100
    for enemy in sim.squad_members:enemy.x=7
    check("actual expedition uses the expected role and equipped mechanism",f.character==3 and f.tactic_anchor and sim.tactics.skill(0,0)==4)
    var meter:float=f.meter;var status:Dictionary=View.slot_view(sim,0)
    check("empty network is visibly unavailable in Chinese",not status.ready and status.text==L10n.text("PLACE NODES %d/2")%0)
    await shot("nodes-needed-zh");await press(KEY_Q)
    check("unavailable real Q input cannot charge a fee",f.meter==meter and f.move!="tactic_a")
    await press(KEY_L);step(65)
    check("actual L placement updates the node requirement",f.service.nodes.size()==1 and View.slot_view(sim,0).text==L10n.text("PLACE NODES %d/2")%1)
    await press(KEY_L);step(65)
    check("two actual L placements make the emitter cast ready",f.service.nodes.size()==2 and View.slot_view(sim,0).ready)
    meter=f.meter;await press(KEY_Q);step(40)
    check("actual supported cast starts the quoted cooldown",f.tactical.cd_total[0]==394)
    check("actual paid setup becomes a bright free emitter followup",f.meter==meter-25 and View.slot_view(sim,0).ready and View.slot_view(sim,0).text==L10n.text("EMITTER READY / FIRE"))
    await shot("emitter-free-zh");meter=f.meter;await press(KEY_Q);step(20)
    check("real highlighted followup fires once for zero additional fee",f.meter==meter and f.service.nodes.is_empty())
    step(25);status=View.slot_view(sim,0)
    check("spent emitter returns to real remaining cooldown",not status.ready and status.progress>0 and status.progress<1)
    session.set_language("en");await shot("cooldown-en")
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"native.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"  "))
    session.return_to_title();session.queue_free();await frames(8);quit(1 if failed else 0)
