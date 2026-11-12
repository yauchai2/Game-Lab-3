extends SceneTree
const OUT="res://../docs/evidence/city-expansion/"
var s:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("EXPANSION_NATIVE ",label," ",ok)
    if not ok:push_error(label)
func frames(n:=3) -> void:
    for i in n:await process_frame
    await RenderingServer.frame_post_draw
func tap(code:Key) -> void:
    for down in [true,false]:
        var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=down;Input.parse_input_event(e);await frames(2)
    await station_travel()
func click(control:Control) -> void:
    # Rebuilt long station panels need a layout pass before ensure_control_visible.
    await frames(3)
    var parent:=control.get_parent()
    while parent!=null:
        if parent is ScrollContainer:parent.ensure_control_visible(control);await frames(3);break
        parent=parent.get_parent()
    for down in [true,false]:
        var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down
        e.position=control.get_global_rect().get_center();e.global_position=e.position;root.push_input(e,true);await frames(2)
func button(parent:Node,prefix:String) -> Button:
    for child in parent.find_children("*","Button",true,false):
        if child.text.begins_with(prefix):return child
    return null
func shot(name:String) -> void:
    await frames();root.get_texture().get_image().save_png(OUT+name+".png")
func complete_fixture() -> void:
    for f in s.sim.squad_members:f.health=0
    s.sim._finish_round();s._combat_step();s._process(2);await frames()
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var path:="user://city-expansion/native.json"
    for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.city_save_path=path
    root.add_child(s);s.audio.muted=true;s.set_process(false);s.set_physics_process(false);await frames(5)
    check("actual game viewport is 960x540",root.get_visible_rect().size==Vector2(960,540))
    check("nearest texture filter and AA-free toon renderer retained",ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")==0 and root.msaa_3d==Viewport.MSAA_DISABLED and root.screen_space_aa==Viewport.SCREEN_SPACE_AA_DISABLED)
    check("title preview also renders at new resolution",s.hud.title_motion.viewport.size==Vector2i(960,540))
    await shot("main-menu")
    await click(s.hud.art_buttons.story)
    var c=s.city_campaign;var h=c.hub;var p=c.profile
    check("main Story still opens the isometric city",s.screen=="city" and h.visible and not s.hud.visible)
    check("city viewport matches upgraded whole-game resolution",h.viewport.size==Vector2i(960,540))
    await shot("city")
    await tap(KEY_5)
    var board:Control=h.stack.get_children().filter(func(n:Node)->bool:return n.get_meta("city_board","")=="map")[0]
    await click(board.get_child(0))
    check("native map pointer starts the first story encounter",s.screen=="play" and s.sim.campaign_enabled and p.data.run.room==0)
    s.sim.ai_enabled=false;s.sim.arrival_left=0;s.sim.squad_members[0].x=.9
    await tap(KEY_J)
    for i in 18:s._combat_step();s._process(1.0/60)
    check("real input still causes combat damage",s.sim.squad_members[0].health<35)
    await shot("battle-960")
    await complete_fixture();await tap(KEY_ENTER)
    check("clear banks an equipment drop and spendable talent point",s.screen=="city" and p.data.inventory.size()==1 and p.data.points==1 and p.data.credits==100)
    await tap(KEY_1);await click(button(h.stack,"LEARN  DOUBLE"))
    check("native skill station preserves gradual unlock",p.data.skills.has("double_jump") and not p.data.skills.has("overdrive"))
    await tap(KEY_2)
    var tree=h.talent_tree
    check("full-screen connected talent board contains all 48 nodes",tree.visible and tree.buttons.size()==48)
    await click(tree.buttons.break_1);await click(button(tree.detail,"CONNECT"))
    check("native node selection plus Connect spends one actual point",p.data.talents[0]==["break_1"] and p.stats(0).heavy_damage>0)
    var old_zoom:float=tree.zoom
    var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_WHEEL_UP;e.pressed=true
    e.position=tree.board.get_global_rect().get_center();e.global_position=e.position;root.push_input(e,true);await frames()
    check("native mouse wheel zooms the tree",tree.zoom>old_zoom)
    var old_pan:Vector2=tree.pan
    var drag:=InputEventMouseButton.new();drag.button_index=MOUSE_BUTTON_RIGHT;drag.pressed=true
    drag.position=tree.board.get_global_rect().get_center();drag.global_position=drag.position;root.push_input(drag,true);await frames(2)
    var motion:=InputEventMouseMotion.new();motion.position=drag.position+Vector2(35,20);motion.global_position=motion.position;motion.relative=Vector2(35,20);motion.button_mask=MOUSE_BUTTON_MASK_RIGHT;root.push_input(motion,true);await frames(2)
    drag.pressed=false;drag.position=motion.position;drag.global_position=drag.position;root.push_input(drag,true);await frames(2)
    check("native right drag pans the connected tree",tree.pan.distance_to(old_pan)>1)
    # Explicit advanced-tree fixture for readability, not earned progression.
    p.data.xp=1900;p.data.best=18;p._points();p.respec(0)
    for id in ["break_1","break_2","break_3","break_4","break_5","break_6","break_10","break_11"]:p.allocate(0,id)
    tree.open(p,0);tree.zoom=.68;tree.pan=Vector2(420,260);tree._positions();tree.selected="break_11";tree._detail();await shot("talent-tree")
    await tap(KEY_ESCAPE);await tap(KEY_3)
    p.data.credits=1000;p.data.pity=9;p.data.unique_pity=39;p.save_data();h.open_station(2)
    await click(button(h.stack,"DRAW SELECTED"))
    check("native dealer rolls and persists a signature affix item",p.data.credits==900 and p.data.inventory.size()==2 and p.data.inventory[-1].tier==3 and p.data.inventory[-1].affixes.size()==2)
    var selected:=int(p.data.inventory[-1].id)
    await click(button(h.stack,"INSPECT #%d"%selected));await shot("gear-comparison")
    check("inventory inspection shows real before-after comparison",button(h.stack,"EQUIP FOR THIS HERO")!=null)
    await click(button(h.stack,"EQUIP FOR THIS HERO"))
    check("equipment compare action changes the selected hero loadout",int(p.gear_for(0)[0].id)==selected)
    p.abandon();p._contract(1,0,1147);p._contract(5,5,1555);p.save_data();h.refresh_header()
    await tap(KEY_5);await shot("contracts")
    var contract_id:=int(p.data.contracts[0].id)
    await click(button(h.stack,"START CONTRACT #%d"%contract_id))
    check("native contract entry consumes only its one item",s.screen=="play" and p.data.contracts.size()==1 and p.data.run.get("mode","")=="contract")
    check("contract tier and modifiers reach actual simulation HP",s.sim.campaign_tier==1 and s.sim.campaign_stats.enemy_hp>0 and s.sim.squad_members[0].max_health>28 and s.sim.squad_members.size()<=6)
    await shot("contract-fight")
    s.sim.fighters[0].health=0;s.sim._finish_round();s._combat_step();s._process(2);await tap(KEY_ENTER)
    check("challenge defeat returns home with two saved attempts",s.screen=="city" and p.data.run.tries==2 and p.data.run.wave==0)
    var reload_profile=preload("res://scripts/combat/city/city_profile.gd").new();reload_profile.path=path;reload_profile.load_data()
    check("real disk reload preserves challenge seed attempts and item balance",reload_profile.error=="" and reload_profile.data.run.contract.seed==1147 and reload_profile.data.run.tries==2 and reload_profile.data.contracts.size()==1)
    p.abandon();c.leave_city();s.start_match(false);s.round_theatre.clear()
    check("ordinary Fight restores full kit with no city stat modifiers",not s.sim.campaign_enabled and not c.active and s.sim.campaign_stats.is_empty())
    s.sim.fighters[0].meter=100;s.sim._start_attack(0,"overdrive")
    check("ordinary Fight overdrive does not require story unlock",s.sim.fighters[0].move=="overdrive")
    var failed:int=checks.filter(func(test:Dictionary)->bool:return not test.passed).size()
    var file:=FileAccess.open(OUT+"native.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks},"  "));file.close()
    s.queue_free();await frames(8);await create_timer(.3).timeout
    print("EXPANSION_NATIVE RESULT ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)

func station_travel() -> void:
    if s.screen!="city":return
    var h=s.city_campaign.hub
    for tick in 1500:
        if h.route_station<0:return
        h._process(1.0/60)
        if tick%120==0:await frames(1)
    check("station travel completes before UI assertions",false)
