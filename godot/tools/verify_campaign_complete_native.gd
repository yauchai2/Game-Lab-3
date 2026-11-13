extends SceneTree
const OUT="res://../docs/evidence/campaign-complete/"
var s:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(name:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":name,"passed":ok,"detail":detail});print("COMPLETE_NATIVE ",name," ",ok)
    if not ok:push_error(name)
func frames(n:=3) -> void:
    for i in n:await process_frame
    await RenderingServer.frame_post_draw
func step(n:=1) -> void:
    for i in n:s._combat_step();s._process(1.0/60)
func view_step(n:int) -> void:
    for i in n:s._process(1.0/60)
func key(code:Key,down:bool) -> void:
    var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=down;Input.parse_input_event(e);await frames(2)
func tap(code:Key) -> void:
    await key(code,true);await key(code,false)
    await station_travel()
func click(control:Control) -> void:
    await frames(3) # Rebuilt station panels need a layout pass before scrolling/clicking.
    if control==null:check("requested native control exists",false);return
    var parent:=control.get_parent()
    while parent!=null:
        if parent is ScrollContainer:parent.ensure_control_visible(control);await frames(3);break
        parent=parent.get_parent()
    for down in [true,false]:
        var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=control.get_global_rect().get_center();e.global_position=e.position;root.push_input(e,true);await frames(2)
const ACT_ALIAS={"REVIEW 06":"chapter:6","PRACTICE SIGNAL":"practice:boss_signal","EQUIP LONG ROUTE":"tech:zip_route","EQUIP SIGNED RECEIPT":"tech:zip_confirm","EQUIP EXIT PLAN":"tech:zip_dash","PRACTICE DOUBLE JUMP":"practice:double_jump","LEARN  DOUBLE":"learn:double_jump"}
func button(parent:Node,prefix:String) -> Button:
    var act:String=ACT_ALIAS.get(prefix,"contract:"+prefix.substr(prefix.find("#")+1) if prefix.begins_with("START CONTRACT #") else "")
    for child in parent.find_children("*","Button",true,false):
        if act!="" and child.get_meta("act","")==act:return child
        if act=="" and child.text.begins_with(prefix):return child
    return null
func shot(name:String) -> void:
    await frames();root.get_texture().get_image().save_png(OUT+name+".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var path:="user://campaign-complete/native.json"
    for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.city_save_path=path;root.add_child(s);s.audio.muted=true;s.set_process(false);s.set_physics_process(false);await frames(6)
    await click(s.hud.art_buttons.story)
    var c=s.city_campaign;var p=c.profile;var h=c.hub;await frames(6)
    check("city now uses original hero skeleton and authored NPC models",h.hero_visual.skeleton!=null and h.town_npcs.size()==3 and h.hero_visual.character_index==0)
    await shot("city")
    # Explicit progression/funding fixtures for feature verification, not earned rewards.
    p.data.best=18;p.data.xp=1900;p._points();p.data.skills=p.SKILLS.map(func(skill:Dictionary)->String:return skill.id);p.data.parts=100;p.data.credits=3000;p.save_data()
    await tap(KEY_4);await shot("story-ending")
    check("six authored chapters have objectives and a persistent technique journal",p.Story.CHAPTERS.size()==6 and button(h.stack,"REVIEW 06")!=null and button(h.stack,"PRACTICE SIGNAL")!=null)
    await tap(KEY_1)
    await click(button(h.stack,"EQUIP LONG ROUTE"));await click(button(h.stack,"EQUIP SIGNED RECEIPT"))
    check("native city class-technique choices persist exactly two",p.data.advanced[0]==["zip_route","zip_confirm"] and button(h.stack,"EQUIP EXIT PLAN").disabled)
    p.start_run(0);p.data.run.hp=63;p.save_data();var snapshot:Dictionary=p.data.duplicate(true)
    await click(button(h.stack,"PRACTICE DOUBLE JUMP"))
    check("native lesson starts an isolated full-energy fixture",c.lesson_active=="double_jump" and s.screen=="play" and s.sim.fighters[0].meter==100 and p.data==snapshot)
    await tap(KEY_SPACE);step(12);await tap(KEY_SPACE);step(2);s._process(2)
    check("real Space double-jump event completes the lesson",s.screen=="result" and s.sim.story_state=="complete")
    await tap(KEY_ENTER)
    check("lesson exit preserves expedition HP money loot and core state",s.screen=="city" and p.data==snapshot)
    p.abandon();await tap(KEY_3)
    await click(button(h.stack,"DEALER / CORE DRAW"))
    check("city dealer enters shared 3D draw with one saved token",s.ability_draw.active() and s.screen=="result" and p.data.parts==99 and not p.data.core_offer.is_empty())
    var core:String=p.data.core_offer.id
    view_step(150);await frames();await click(s.ability_draw.action)
    check("native DRAW reveals the already-saved core rather than rerolling",s.ability_draw.state=="spin" and s.ability_draw.result.id==core)
    view_step(165);await frames();await shot("core-result");await click(s.ability_draw.action);view_step(95);await shot("core-equip")
    check("actual selected-character equip presentation is active",s.ability_draw.state=="equip" and s.ability_draw.equip_view.hero.character_index==0)
    view_step(190);await frames(6)
    check("equip completion atomically prepares exactly one core",s.screen=="city" and p.data.pending_core==core and p.data.core_offer.is_empty() and p.data.parts==99 and not p.claim_core())
    p.start_run(0,3);p.data.run.room=11;p.save_data();c.depart();view_step(150);await frames(6)
    check("story freight finale owns a real Boss, core and class perks",s.sim.campaign_boss=="gantry" and s.sim.fighters[0].get("draw_core","")==core and s.sim.fighters[0].perks==["zip_route","zip_confirm"])
    var boss:Node3D=s.squad_visuals[0].get_node("CampaignBoss")
    check("generated giant is an articulated mesh model, not the old suit",not s.squad_visuals[0].model.visible and boss.find_child("Arm_L",true,false)!=null and boss.find_children("*","MeshInstance3D",true,false).size()>25)
    var hero_at:Vector2=s.camera.unproject_position(Vector3(s.sim.fighters[0].x,0,3));var head_at:Vector2=s.camera.unproject_position(Vector3(s.sim.fighters[0].x,2.1,3))
    check("giant camera keeps a readable player projection",hero_at.distance_to(head_at)>=45,{"player_px":hero_at.distance_to(head_at)})
    check("authored arena replaces the shared street and owns environment",not s.backdrop.visible and s.camera.environment==c.dressing.environment)
    await shot("gantry")
    step(175);await shot("gantry-warning")
    check("boss windup is visible in model cue and ground mark",not s.sim.campaign_hazards.is_empty() and c.dressing.marks.any(func(mark:MeshInstance3D)->bool:return mark.visible))
    await tap(KEY_ESCAPE);var left:int=s.sim.squad_members[0].boss.left;step(50)
    check("native pause freezes Boss attack countdown",s.screen=="pause" and s.sim.squad_members[0].boss.left==left)
    await tap(KEY_ESCAPE)
    # Explicit phase boundary fixture, separate from headless ordinary-input Boss clears.
    s.sim.squad_members[0].health=70;step();await shot("gantry-phase2")
    check("real phase director changes phase and clears pending attacks",s.sim.squad_members[0].boss.phase==2 and s.sim.campaign_hazards.is_empty())
    for foe in s.sim.squad_members:foe.health=0
    s.sim._finish_round();s._combat_step();view_step(100);await frames(5)
    var grounded:=INF
    for mesh in boss.find_children("*","MeshInstance3D",true,false):
        var bounds:AABB=mesh.get_aabb()
        for corner in 8:grounded=minf(grounded,(mesh.global_transform*bounds.get_endpoint(corner)).y)
    check("defeated giant is grounded instead of floating",absf(grounded-.02)<.03,{"lowest_y":grounded})
    await shot("gantry-defeated")
    c.show_city();p.abandon();p.start_run(0,5);p.data.run.room=17;p.save_data();c.depart();view_step(150);step(175);await shot("leviathan-warning")
    check("tower finale has its own distinct giant model and three-phase data",s.sim.campaign_boss=="signal" and s.sim.squad_members[0].boss.kind=="signal")
    c.show_city();p.abandon()
    var item:Dictionary=p.Loot.make(500,0,1,5,p.data.skills,91);p.data.item_serial=500;p.data.inventory.append(item);p.equip(500);p.save_data()
    await tap(KEY_3);await click(button(h.stack,"INSPECT #500"));var parts:=int(p.data.parts);var money:=int(p.data.credits)
    await click(button(h.stack,"RECALIBRATE FIRST"))
    check("native workshop recalibrates and debits only the stated cost",p.data.parts==parts-5 and p.data.credits==money-80 and p.data.craft_serial==1)
    await shot("workshop")
    c.leave_city();s.start_match(false);s.round_theatre.clear();s._process(1.0/60);await frames(6)
    check("standard mode exit restores the original street and removes Boss visuals",not s.sim.campaign_enabled and s.backdrop.visible and s.fighters[1].get_node_or_null("CampaignBoss")==null and s.fighters[1].model.visible)
    check("city equipment bonuses and visual sockets do not leak into standard Fight",s.sim.fighters[0].perks.is_empty() and not s.fighters[0].skeleton.get_children().any(func(node:Node)->bool:return str(node.name).begins_with("CityGear")))
    c.open_city();p.start_run(0);c.depart();s.sim.ai_enabled=false;s.sim.fighters[0].x=2.4
    for attempt in 2:
        await key(KEY_S,true);await tap(KEY_K);step(3);await key(KEY_S,false)
        for tick in 90:
            step()
            if s.sim.campaign_props.any(func(prop:Dictionary)->bool:return prop.hp<=0):break
        if s.sim.campaign_props.any(func(prop:Dictionary)->bool:return prop.hp<=0):break
    await frames(4)
    check("native heavy/body impact visibly destroys a real arena prop",s.sim.campaign_props.any(func(prop:Dictionary)->bool:return prop.hp<=0) and c.dressing.crates.any(func(crate:MeshInstance3D)->bool:return not crate.visible))
    await shot("prop-break")
    var failed:int=checks.filter(func(test:Dictionary)->bool:return not test.passed).size()
    var file:=FileAccess.open(OUT+"native.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks},"  "));file.close()
    s.queue_free();await frames(10);await create_timer(.35).timeout
    print("COMPLETE_NATIVE RESULT ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)

func station_travel() -> void:
    if s.screen!="city":return
    var h=s.city_campaign.hub
    for tick in 1500:
        if h.route_station<0:return
        h._process(1.0/60)
        if tick%120==0:await frames(1)
    check("station travel completes before UI assertions",false)
