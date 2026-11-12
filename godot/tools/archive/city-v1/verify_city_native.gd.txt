extends SceneTree
const OUT="res://../docs/evidence/city-hub/"
var s:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("CITY_NATIVE ",label," ",ok)
    if not ok:push_error(label)
func frames(n:=3) -> void:
    for i in n:await process_frame
    await RenderingServer.frame_post_draw
func key(code:Key,down:bool) -> void:
    var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down
    Input.parse_input_event(e);await frames(2)
func tap(code:Key) -> void:await key(code,true);await key(code,false)
func click(control:Control) -> void:
    var parent:=control.get_parent()
    while parent!=null:
        if parent is ScrollContainer:parent.ensure_control_visible(control);await frames(3);break
        parent=parent.get_parent()
    for down in [true,false]:
        var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down
        e.position=root.get_screen_transform()*control.get_global_rect().get_center();e.global_position=e.position
        Input.parse_input_event(e);await frames(2)
func shot(name:String) -> void:
    await frames();root.get_texture().get_image().save_png(OUT+name+".png")
func clear_fixture() -> void:
    # Explicit completion fixture, separate from the real native damage check.
    for f in s.sim.squad_members:f.health=0
    s.sim._finish_round();s._combat_step();s._process(2);await frames()
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var path:="user://city-verification/native.json"
    for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.city_save_path=path
    root.add_child(s);s.audio.muted=true;s.set_process(false);s.set_physics_process(false)
    await frames(5);await shot("main-menu")
    await click(s.hud.art_buttons.fight)
    var city=s.city_campaign;var h=city.hub;var p=city.profile
    check("main Story pointer opens an actual independent 3D hub",s.screen=="city" and h.visible and not s.hud.visible and h.viewport.own_world_3d)
    check("city uses orthographic yaw45 pitch45 camera",h.view_camera.projection==Camera3D.PROJECTION_ORTHOGONAL and is_equal_approx(absf(h.view_camera.rotation_degrees.x),45.0))
    await shot("safe-block")
    var start:Vector3=h.hero.position
    await key(KEY_D,true)
    for i in 12:h._process(1.0/60)
    await key(KEY_D,false)
    check("native WASD moves the hub avatar on the city plane",h.hero.position.distance_to(start)>.4 and h.hero.position.y==0)
    h.hero.position=h.STATIONS[0];await frames();await tap(KEY_E)
    check("nearby E opens the physical skill station",h.panel.visible and h.page=="SKILLS")
    await shot("skills")
    await tap(KEY_ESCAPE);await tap(KEY_5);await shot("city-map")
    var board:Control=h.stack.get_children().filter(func(c:Node)->bool:return c.get_meta("city_board","")=="map")[0]
    await click(board.get_child(0))
    check("native map pointer starts a saved campaign fight",s.screen=="play" and s.sim.campaign_enabled and city.active and p.data.run.in_flight and not h.visible)
    var xp:Dictionary=s.growth.records.duplicate(true)
    s.sim.ai_enabled=false;s.sim.arrival_left=0;s.sim.squad_members[0].x=.9
    await key(KEY_J,true)
    for i in 15:s._combat_step();s._process(1.0/60)
    await key(KEY_J,false)
    check("native J causes actual damage in the expedition",s.sim.squad_members[0].health<35)
    await shot("expedition")
    await clear_fixture()
    check("clear presents a city return instead of silently respawning",s.screen=="result" and p.data.credits==0 and not s.city_breaker.active())
    await tap(KEY_ENTER)
    check("native Enter banks once and returns to the city",s.screen=="city" and p.data.credits==45 and p.data.run.room==1 and p.data.run.boon_due)
    await tap(KEY_1)
    var learned:=false
    for child in h.stack.get_children():
        if child is Button and child.text.begins_with("LEARN  DOUBLE"):await click(child);learned=true;break
    check("skill station learns guaranteed double jump for free",learned and "double_jump" in p.data.skills and p.data.credits==45)
    await tap(KEY_2);await shot("talent-circuit")
    var talent_board:Control=h.stack.get_children().filter(func(c:Node)->bool:return c.get_meta("city_board","")=="talents")[0]
    await click(talent_board.get_child(0))
    check("native connected node spends the available point",p.data.talents[0]==["break_1"])
    await tap(KEY_5)
    var boon_chosen:=false
    for child in h.stack.get_children():
        if child is Button and child.text=="TAKE DAMAGE":await click(child);boon_chosen=true;break
    check("city offers one temporary reward before continuing",boon_chosen and not p.data.run.boon_due)
    city.depart();s.sim.ai_enabled=false
    check("next fight carries HP, permissions and real combined damage",s.sim.campaign_room==1 and "double_jump" in s.sim.campaign_skills and s.sim.campaign_stats.damage>.08)
    s.sim.fighters[0].health=0;s.sim._finish_round();s._combat_step();s._process(2);await tap(KEY_ENTER)
    check("defeat returns home and clears only the expedition",s.screen=="city" and p.data.run.is_empty() and p.data.credits==45 and "double_jump" in p.data.skills)
    check("campaign never touches old character XP",s.growth.records==xp)
    # Shop fixture gives explicit test funds; not a gameplay reward.
    p.data.credits=500;p.data.parts=5;p.save_data();await tap(KEY_3)
    for child in h.stack.get_children():
        if child is Button and child.text.begins_with("DRAW SELECTED"):await click(child);break
    check("native dealer button debits and persists one permanent item",p.data.credits==400 and p.data.inventory.size()==1 and not p.data.gear[0].is_empty())
    await shot("dealer")
    await tap(KEY_4);await shot("radio-story")
    city.leave_city();s.start_match(false);s.round_theatre.clear()
    check("standard Fight restores full kit and disables city modifiers",not city.active and not s.sim.campaign_enabled and not h.visible and s.hud.visible and not is_instance_valid(city.dressing))
    s.sim.fighters[0].meter=100;s.sim._start_attack(0,"overdrive")
    check("normal Fight can still use overdrive without story unlock",s.sim.fighters[0].move=="overdrive")
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open(OUT+"native.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks},"  "));file.close()
    s.queue_free();await frames(8)
    await create_timer(.25).timeout
    print("CITY_NATIVE RESULT ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
