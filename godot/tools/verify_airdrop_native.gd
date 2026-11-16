extends SceneTree
const OUT="res://../docs/evidence/airdrop-module/"
const View=preload("res://scripts/combat/tactics/presentation.gd")
const L10n=preload("res://scripts/combat/ui/locale_text.gd")
var checks:Array=[]
var session:Node
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("AIRDROP_NATIVE ",label," ",ok)
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
func click(hub:Node,act:String) -> void:
    var button:Control=control(hub,act);hub.scroll.ensure_control_visible(button);await frames()
    for down in [true,false]:
        var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=button.get_global_rect().get_center();event.global_position=event.position;root.push_input(event,true);await frames(2)
func shot(name:String) -> void:
    session._process(1.0/60);await frames();root.get_texture().get_image().save_png(OUT+name+".png")
func _initialize() -> void:call_deferred("run")
func run() -> void:
    session=preload("res://scenes/combat/street_fight.tscn").instantiate();session.preferences_path="";session.city_save_path="";root.add_child(session)
    session.set_process(false);session.set_physics_process(false);session.audio.muted=true;await frames(8)
    var campaign=session.city_campaign;var p=campaign.profile;var hub=campaign.hub;p.data.best=18;campaign.open_city();session.set_language("zh")
    for hero in [0,3]:
        p.data.run={};campaign.show_city();session.set_character(0,hero);campaign.selected_hero=hero;hub.open_station(0);await frames()
        var picker:OptionButton=control(hub,"tactic:0:attachments");hub.scroll.ensure_control_visible(picker);await frames();picker.grab_focus()
        check("hero%d second support exposes the compatible air drop"%hero,picker.item_count==4 and not picker.is_item_disabled(3))
        await key(KEY_SPACE,true);await key(KEY_SPACE,false)
        for i in (2 if hero==0 else 1):await key(KEY_DOWN,true);await key(KEY_DOWN,false)
        await key(KEY_ENTER,true);await key(KEY_ENTER,false)
        check("hero%d actual dropdown fits air drop"%hero,p.data.tactics[hero].attachments[0]==3)
        hub.scroll.ensure_control_visible(control(hub,"tactic:0:module_info"));await shot("hero%d-build-zh"%hero)
        await click(hub,"build:0:SAVE");p.configure_tactic(hero,0,"attachments",0);hub.open_station(0);await frames();await click(hub,"build:0:LOAD")
        check("hero%d actual preset buttons restore its aerial module"%hero,p.data.tactics[hero].attachments[0]==3)
        campaign.flow.force_live=false;campaign.depart();session.round_theatre.clear();await frames()
        var s=session.sim;var f:Dictionary=s.fighters[0];s.ai_enabled=false;f.x=0;f.face=1;f.meter=100
        for target in s.squad_members:target.x=7;target.health=500;target.max_health=500
        if hero==0:s.squad_members[0].x=4.2
        await press(KEY_SPACE);step(12)
        check("hero%d real Space opens a paid aerial option"%hero,f.y>.1 and View.slot_view(s,0).ready and View.slot_view(s,0).text==L10n.text("AIR DROP / %d ENERGY")%15)
        await shot("hero%d-air-ready-zh"%hero);await press(KEY_Q);step(17)
        check("hero%d real Q spends one fee and the shared air budget"%hero,f.meter==85 and f.air.fast_used and f.tactical.air_debt==8)
        check("hero%d native projectile actually descends"%hero,not s.tactics.shots.is_empty() and s.tactics.shots[0].get("airdrop",false) and s.tactics.shots[0].fall_speed>0)
        await shot("hero%d-air-throw"%hero)
        var landing:=false
        for i in 80:
            step(1)
            if s.events.any(func(e:Dictionary)->bool:return e.kind=="tactic_landing"):
                landing=true;await shot("hero%d-landing"%hero)
        check("hero%d native landing serves the extra recovery"%hero,landing and f.tactical.air_debt==0 and f.state=="idle")
        if hero==0:check("ZIP aerial tag makes a real hit and live mark",s.squad_members[0].health<500 and f.tactical.mark_ttl>0)
        else:check("LOOP aerial setup keeps one ground node and normal energy",f.service.nodes.size()==1 and f.meter==85)
    session.return_to_title();check("exiting story clears airborne effects",session.sim.tactics.shots.is_empty())
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"native.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed},"  "));session.queue_free();await frames(8);quit(1 if failed else 0)
