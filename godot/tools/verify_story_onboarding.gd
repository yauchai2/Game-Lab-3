extends SceneTree
const P=preload("res://scripts/combat/city/city_profile.gd")
const S=preload("res://scripts/combat/story/story_simulation.gd")
const Guide=preload("res://scripts/combat/city/story_guide.gd")
const OUT="res://../docs/evidence/story-onboarding/"
var checks:Array=[]
var session:Node
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("ONBOARDING ",label," ",ok)
    if not ok:push_error(label)
func frames(count:=3) -> void:
    for i in count:await process_frame
    await RenderingServer.frame_post_draw
func tap(code:Key) -> void:
    for down in [true,false]:
        var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;Input.parse_input_event(event);await frames(2)
func button(parent:Node,act:String) -> Button:
    for child in parent.find_children("*","Button",true,false):
        if child.get_meta("act","")==act:return child
    return null
func click(control:Control) -> void:
    check("requested guide control exists",control!=null)
    if control==null:return
    var ancestor:=control.get_parent()
    while ancestor:
        if ancestor is ScrollContainer:ancestor.ensure_control_visible(control);await frames();break
        ancestor=ancestor.get_parent()
    for down in [true,false]:
        var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=control.get_global_rect().get_center();event.global_position=event.position;root.push_input(event,true);await frames(2)
func shot(label:String) -> void:
    await frames();root.get_texture().get_image().save_png(OUT+label+".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var p=P.new();p.path=""
    check("fresh profile grants the full kit without money or story progress",p.data.skills==P.BASIC_SKILLS and p.data.credits==0 and p.data.best==0 and p.valid(p.data))
    for hero in 4:
        var sim=S.new();sim.last_service_enabled=true;sim.character_choices=[hero,4];sim.begin_story();sim.campaign_enabled=true;sim.campaign_skills=[];sim.ai_enabled=false
        var f:Dictionary=sim.fighters[0];f.chain=2;sim._start_attack(0,"light")
        check("hero %d opening ground chain reaches launcher"%hero,f.move=="launcher")
        f.state="idle";f.y=1.5;f.chain=2;sim._start_attack(0,"light")
        check("hero %d opening air chain reaches finisher"%hero,f.move=="meteor")
        f.state="idle";f.y=0;f.meter=100;sim._start_attack(0,"overdrive")
        check("hero %d opening overdrive pays the normal cost"%hero,f.move=="overdrive" and f.meter==25)
        f.state="idle";f.meter=0;sim._start_attack(0,"overdrive")
        check("hero %d still cannot use overdrive without energy"%hero,f.state=="idle" and f.meter==0)
        f.y=1;f.jump_buffer=8;sim._advance_fighter(0,{"jump":true})
        check("hero %d opening double jump is a real event"%hero,sim.events.any(func(e:Dictionary)->bool:return e.kind=="double_jump"))
        f.state="idle";f.y=0;f.meter=60;f.air.chase_window=30;f.air.chase_buffer=8
        sim.fighters[1].y=1;sim.fighters[1].vy=1;sim.fighters[1].state="stun";sim.fighters[1].x=f.x+1
        sim._advance_fighter(0,{})
        check("hero %d opening chase really spends energy"%hero,f.state=="chase" and f.meter==40)
    # Each supported save version keeps its original bytes on read and grants only basics.
    for version in [1,2,3]:
        p=P.new();p.path="user://story-onboarding/legacy%d.json"%version
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(p.path.get_base_dir()))
        var old:Dictionary=p.fresh();old.version=version;old.skills=["double_jump"];old.credits=234;old.parts=9;old.best=8;old.skill_levels=[1,0,0,0]
        old.points=2;old.xp=200
        var bytes:=JSON.stringify(old);var file:=FileAccess.open(p.path,FileAccess.WRITE);file.store_string(bytes);file.close()
        p.load_data()
        check("schema%d grants basics without erasing money rank or progress"%version,p.error=="" and p.data.skills==P.BASIC_SKILLS and p.data.credits==234 and p.data.parts==9 and p.data.best==8 and p.data.skill_levels[0]==1 and p.data.advanced==[[],[],[],[]])
        check("schema%d read preserves original save bytes"%version,FileAccess.get_file_as_string(p.path)==bytes)
        p.save_data();var reloaded=P.new();reloaded.path=p.path;reloaded.load_data()
        check("schema%d next save and reload retain every basic move"%version,reloaded.error=="" and reloaded.data.skills==P.BASIC_SKILLS)
    session=preload("res://scenes/combat/street_fight.tscn").instantiate();session.preferences_path="";session.city_save_path="";root.add_child(session)
    session.audio.muted=true;session.set_process(false);session.set_physics_process(false);session.set_language("zh");await frames(6)
    var campaign=session.city_campaign;var hub=campaign.hub;campaign.flow.force_live=true;campaign.open_city();await frames()
    var snapshot:Dictionary=campaign.profile.data.duplicate(true)
    check("first visit explains story without altering the profile",hub.page=="GUIDE" and hub.panel.visible and campaign.profile.data==snapshot)
    await shot("guide-zh")
    hub.scroll.ensure_control_visible(button(hub.stack,"guide_equipment"));await frames();await shot("guide-growth-zh")
    check("guide scroll reaches equipment navigation",button(hub.stack,"guide_equipment").get_global_rect().intersects(hub.scroll.get_global_rect()))
    session.set_language("en");hub.open_guide();await frames();await shot("guide-en")
    session.set_language("zh");hub.open_guide();await frames()
    await tap(KEY_H);await frames()
    check("H closes guide and leaves compact guidance visible",not hub.panel.visible and hub.next_hint.visible and hub.guide_button.visible)
    await shot("hub-zh")
    await click(hub.guide_button)
    check("visible guide button reopens the guide",hub.page=="GUIDE" and hub.panel.visible)
    await click(button(hub.stack,"guide_next"))
    check("next-step button walks to the physical station",hub.route_station==4 and not hub.panel.visible)
    for i in 1500:
        hub._process(1.0/60)
        if hub.route_station<0:break
    check("guided walk reaches DEPART without spending or starting a run",hub.page=="DEPART" and campaign.profile.data==snapshot)
    hub.open_station(0);await frames()
    for id in P.BASIC_SKILLS:
        var practice:=button(hub.stack,"practice:"+id)
        check("fresh native practice is enabled for "+id,practice!=null and not practice.disabled)
    await shot("skills-zh")
    session.set_language("en");await frames();await shot("skills-en")
    session.set_language("zh");await frames()
    await click(button(hub.stack,"practice:launcher"));await frames()
    check("practice starts with the real kit and leaves progression alone",campaign.lesson_active=="launcher" and session.screen=="play" and campaign.profile.data==snapshot)
    await tap(KEY_K)
    for i in 100:session._combat_step();session._process(1.0/60)
    check("actual K input completes launcher practice",session.sim.story_state=="complete")
    campaign.show_city();campaign.flow.force_live=false;campaign.depart();await frames()
    for i in 150:session._combat_step();session._process(1.0/60)
    check("first real encounter carries the full kit",session.sim.campaign_enabled and session.sim.campaign_skills==P.BASIC_SKILLS and campaign.profile.data.best==0)
    await shot("combat-zh")
    var fighter:Dictionary=session.sim.fighters[0];fighter.meter=65;fighter.air.chase_window=0;fighter.y=0
    check("combat advice uses discounted real skill costs",Guide.combat_tip(fighter,40,60).contains("(60)") and Guide.combat_tip(fighter,40,60).contains("(40)"))
    campaign.show_city();campaign.profile.data.points=1
    check("unspent talent point suggests the real circuit",Guide.next_step(campaign.profile,0).station==1)
    campaign.profile.data.run.boon_due=true
    check("pending current takes priority over spending",Guide.next_step(campaign.profile,0).station==4)
    var failures:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var report:=FileAccess.open(OUT+"checks.json",FileAccess.WRITE);report.store_string(JSON.stringify({"passed":checks.size()-failures,"failed":failures,"checks":checks},"  "));report.close()
    print("ONBOARDING RESULT ",checks.size()-failures,"/",checks.size())
    session.queue_free();await frames();quit(1 if failures else 0)
