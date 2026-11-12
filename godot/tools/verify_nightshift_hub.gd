extends SceneTree
const OUT="res://../docs/evidence/nightshift-reference/"
var s:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":label,"passed":ok,"detail":detail});print("NIGHTSHIFT ",label," ",ok)
    if not ok:push_error(label)
func frames(n:=3) -> void:
    for i in n:await process_frame
    await RenderingServer.frame_post_draw
func shot(label:String) -> void:
    await frames();root.get_texture().get_image().save_png(OUT+label+".png")
func run() -> void:
    for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path("user://nightshift-test/reference-profile.json"+suffix))
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.city_save_path="user://nightshift-test/reference-profile.json"
    root.add_child(s);s.audio.muted=true;s.set_process(false);s.set_physics_process(false);await frames(6)
    s.city_campaign.open_city();var h=s.city_campaign.hub;await frames(5)
    check("formal Story uses the new workshop in its isolated 960 viewport",s.screen=="city" and h.workshop.name=="NightshiftWorkshop" and h.viewport.size==Vector2i(960,540))
    await shot("01-in-game")
    h.viewport.get_texture().get_image().save_png(OUT+"02-map.png")
    if "--preview" not in OS.get_cmdline_user_args():await verify(h)
    s.city_campaign.leave_city();await frames()
    check("leaving hub disables its renderer and restores title",not h.visible and h.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED and not root.disable_3d and s.hud.visible)
    s.queue_free();s=null;await frames(10)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"verification.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"engine":Engine.get_version_info().string,"display":DisplayServer.get_name()},"  "))
    await create_timer(.3).timeout;quit(1 if failed else 0)
func verify(h:Node) -> void:
    check("orthographic camera uses cutaway map framing",h.view_camera.projection==Camera3D.PROJECTION_ORTHOGONAL)
    check("all heroes retain real production skeletons",h.hero_visual.skeleton!=null and h.town_npcs.all(func(n:Node3D)->bool:return n.skeleton!=null))
    for i in h.STATIONS.size():
        h.close_panel();h.hero.position=h.workshop.spawns[0];h.request_station(i)
        check("station route exists %d"%i,not h.route.is_empty())
        var max_y:=0.0
        for step in 1600:
            h._process(1.0/60);max_y=maxf(max_y,h.hero.position.y)
            if step%120==0:await frames(1)
            if h.route_station<0:break
        check("walk to station %d reaches its real approach without clipping"%i,h.hero.position.distance_to(h.STATIONS[i])<1.85 and (h.panel.visible or h.talent_tree.visible),{"position":h.hero.position,"height":max_y})
        if i==3:check("radio route physically climbs the loft stairs",max_y>=h.workshop.LOFT_Y-.05)
        if h.talent_tree.visible:h.talent_tree.hide()
    h.close_panel();h.hero.position=h.workshop.spawns[0];h._process(.016)
    check("center has no remote interaction prompt",h.nearest<0 and not h.arrival_hint.visible)
    var key:=InputEventKey.new();key.keycode=KEY_D;key.physical_keycode=KEY_D;key.pressed=true;Input.parse_input_event(key);await frames(2)
    var start:Vector3=h.hero.position
    for step in 12:h._process(1.0/60)
    key.pressed=false;Input.parse_input_event(key);await frames(2)
    check("real keyboard input moves the hub avatar",h.hero.position.distance_to(start)>.4)
    h.hero.position=h.workshop.spawns[0]
    var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=h.view_camera.unproject_position(h.workshop.ref_point(Vector2(940,740)))
    h._unhandled_input(click)
    check("click floor computes a real walking route",not h.route.is_empty() and h.route_station<0)
    h.route.clear()
    for id in 4:
        h.campaign.selected_hero=id;h._process(.016);await frames(2)
        var cast:Array=[h.hero_visual.character_index]
        for npc in h.town_npcs:cast.append(npc.character_index)
        cast.sort()
        check("hero %d keeps one instance of each companion"%id,cast==[0,1,2,3])
    h.campaign.selected_hero=0;h._process(.016);await frames(2)
    var before:Dictionary=h.campaign.profile.data.duplicate(true)
    h.hero.position=h.STATIONS[5];h._process(.016)
    var e:=InputEventKey.new();e.keycode=KEY_E;e.physical_keycode=KEY_E;e.pressed=true;h._input(e)
    check("E at shop opens the real purchase and crafting interface",h.page=="SHOP" and h.panel.visible and h.stack.find_children("*","Button",true,false).any(func(b:Button)->bool:return b.text.begins_with("DRAW SELECTED")))
    check("visiting facilities does not award money XP or consume a core",before==h.campaign.profile.data)
    await shot("03-shop")
    h.close_panel();h.hero.position=Vector3(-7.0,.0,2.5)
    var below:Vector3=h.STATIONS[3];below.y=0
    var stop:Vector3=h.workshop.move_actor(below,Vector3.RIGHT,.05)
    check("loft side cannot be entered without stairs",stop.y==0)
    h.hero.position=h.workshop.spawns[0];h.request_station(3)
    check("station shortcut requests walking rather than teleport",h.hero.position==h.workshop.spawns[0] and h.route_station==3)
    h.route.clear();h.route_station=-1
    h.close_panel();h.request_station(4)
    for step in 900:
        h._process(1.0/60)
        if h.route_station<0:break
    h.campaign.depart();await frames(4)
    check("departure starts existing campaign with hub renderer off",s.screen=="play" and s.sim.campaign_enabled and not h.visible and h.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED)
    h.campaign.show_city();await frames(4)
    check("safe return restores new hub with expedition snapshot",s.screen=="city" and h.visible and not h.campaign.profile.data.run.is_empty())
