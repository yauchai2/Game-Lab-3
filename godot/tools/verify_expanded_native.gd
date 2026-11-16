extends SceneTree
const OUT="res://../docs/evidence/tactics-expanded/"
var checks:Array=[]
var session:Node
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("EXPANDED_NATIVE ",label," ",ok)
    if not ok:push_error(label)
func frames(count:=3) -> void:
    for i in count:await process_frame
    await RenderingServer.frame_post_draw
func key(code:Key,down:bool) -> void:
    var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;Input.parse_input_event(event);await frames(2)
func button(parent:Node,act:String) -> Control:
    for child in parent.find_children("*","Control",true,false):
        if child.get_meta("act","")==act:return child
    return null
func click(control:Control) -> void:
    var parent:Node=control.get_parent()
    while parent:
        if parent is ScrollContainer:parent.ensure_control_visible(control);await frames();break
        parent=parent.get_parent()
    for down in [true,false]:
        var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=control.get_global_rect().get_center();event.global_position=event.position;root.push_input(event,true);await frames(2)
func shot(label:String) -> void:
    await frames();root.get_texture().get_image().save_png(OUT+label+".png")
func _initialize() -> void:call_deferred("run")
func run() -> void:
    session=preload("res://scenes/combat/street_fight.tscn").instantiate();session.preferences_path="";session.city_save_path="";root.add_child(session)
    session.set_process(false);session.set_physics_process(false);session.audio.muted=true;await frames(8)
    var campaign=session.city_campaign;var hub=campaign.hub;var p=campaign.profile
    p.data.best=18;p.data.points=25;p.allocate(1,"air_1");campaign.open_city();hub.open_station(0);await frames()
    check("native skill selectors expose six learned options",button(hub.stack,"tactic:0:ability").item_count==6)
    await click(button(hub.stack,"build:0:SAVE"))
    check("actual preset button stores a complete build",not p.data.build_presets[0][0].is_empty())
    var picker=button(hub.stack,"tactic:0:ability")
    hub.scroll.ensure_control_visible(picker);await frames();picker.grab_focus()
    await key(KEY_SPACE,true);await key(KEY_SPACE,false)
    for i in 3:await key(KEY_DOWN,true);await key(KEY_DOWN,false)
    await key(KEY_ENTER,true);await key(KEY_ENTER,false)
    check("actual native picker selects a later-chapter skill",p.data.tactics[0].skills[0]==3)
    session.set_language("zh");hub.open_station(0);await frames();hub.scroll.ensure_control_visible(button(hub.stack,"build:0:SAVE"));await shot("presets-zh")
    hub.scroll.ensure_control_visible(button(hub.stack,"tactic:0:ability"));await shot("skills-zh")
    session.set_language("en");hub.open_station(0);await frames();hub.scroll.ensure_control_visible(button(hub.stack,"tactic:0:ability"));await shot("skills-en")
    await click(button(hub.stack,"build:0:LOAD"))
    check("actual load button restores both skill slots",p.data.tactics[0].skills==[0,1])
    for hero in 4:
        for id in range(2,6):
            p.data.run={};campaign.show_city();session.set_character(0,hero);campaign.selected_hero=hero
            p.equip_tactic(hero,0,id);campaign.flow.force_live=false;campaign.depart();session.round_theatre.clear();await frames()
            var sim=session.sim;var f:Dictionary=sim.fighters[0]
            check("hero%d skill%d real story actor"%[hero,id],f.character==hero and sim.tactics.skill(0,0)==id)
            sim.arrival_left=9999;f.meter=100;f.x=0;f.face=1
            for target in sim.squad_members:target.x=2.2+int(target.squad_id)*1.2
            f.service.routes=2 if hero==0 and id==4 else 0;f.service.sample=1 if hero==2 and id==5 else 0
            f.service.nodes=[{"x":2.2,"life":300,"id":1},{"x":3.4,"life":300,"id":2}] if hero==3 else []
            if hero==0 and id==2:f.y=1.2;f.air.phase="fall"
            if hero==1 and id==4:
                await key(KEY_L,true)
                for i in 23:session._combat_step()
                check("real L input builds preload before native fan conversion",f.move=="special" and f.service.preload>0 and f.meter<100)
            await key(KEY_Q,true);session._combat_step();await key(KEY_Q,false)
            if hero==1 and id==4:await key(KEY_L,false)
            check("hero%d skill%d real key starts paid action"%[hero,id],f.state=="attack" and f.meter==100-sim.tactics.cost(f,id))
            if hero==1 and id==3:check("equipped economy path reaches real story costs and HUD",is_equal_approx(float(f.tactic_economy),.04) and sim.tactics.cost(f,id)==24 and f.meter==76)
            var count:int=45 if hero==3 and id==4 else (28 if hero==1 and id==5 else (6 if hero==0 and id==2 else 18))
            for i in count:session._combat_step();session._process(1.0/60)
            await frames()
            if id==5 or (hero==3 and id==4) or (hero==0 and id==2):await shot("hero%d-skill%d"%[hero,id])
            if hero==1 and id==5:
                var detonated:=false
                for i in 40:
                    session._combat_step();session._process(1.0/60)
                    if sim.events.any(func(e:Dictionary)->bool:return e.kind=="tactic_pulse"):detonated=true;break
                check("ground seal's real detonation reaches native effects",detonated)
                await shot("ground-seal-burst")
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var out:=FileAccess.open(OUT+"native.json",FileAccess.WRITE);out.store_string(JSON.stringify({"checks":checks,"failed":failed},"  "));out.close()
    session.return_to_title();session.queue_free();await frames(8);quit(1 if failed else 0)
