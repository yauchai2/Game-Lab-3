extends SceneTree
## Captures the Nightshift hub station pages: godot --rendering-driver opengl3 --path godot --script res://tools/capture_hub_ui.gd -- --out=/tmp/hub/
var s:Node
var h:Node
var OUT:="/tmp/hub/"
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var out:="/tmp/hub/"
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--out="):out=a.substr(6)
    OUT=out
    DirAccess.make_dir_recursive_absolute(out)
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.city_save_path="user://hub-ui-capture/profile.json";s.story_opening_on_boot=false
    root.add_child(s);s.audio.muted=true
    for i in 8:await process_frame
    s.city_campaign.open_city();h=s.city_campaign.hub;h.hud_expanded=true
    var p=s.city_campaign.profile
    if "--rich" in OS.get_cmdline_user_args():
        p.data.best=10;p.data.credits=400;p.data.parts=20;p.data.points=3
    for i in 8:await process_frame
    var pages:={"skills":0,"deal":2,"radio":3,"depart":4,"shop":5}
    for key in pages:
        h.open_station(pages[key])
        for i in 6:await process_frame
        await RenderingServer.frame_post_draw
        root.get_viewport().get_texture().get_image().save_png(out+key+".png")
    # Gear fixture: a few drawn items so the DEALER result card, SHOP bag and compare card are visible.
    p.data.inventory.clear();p.data.credits=900;p.data.parts=30;p.data.pity=6;p.data.unique_pity=17
    for i in 10:
        p.data.item_serial=int(p.data.item_serial)+1
        p.data.inventory.append(p.Loot.make(int(p.data.item_serial),i%3,[0,1,2,3,1,2,0,3,1,2][i],5,p.data.skills,40+i))
    p.equip(int(p.data.inventory[1].id));p.data.run={}
    h.selected_item=int(p.data.inventory[3].id);h.refresh_header()
    h.open_station(2);await for_shot("deal_gear")
    h.open_station(5);await for_shot("shop_gear")
    h.scroll.scroll_vertical=9999;await for_shot("shop_gear_bag")
    h.inventory_page=1;h.open_station(5);await for_shot("shop_gear_page2")
    h.inventory_page=0;h.close_panel()
    p.data.points=3;p.data.talents[0]=["break_1","break_2"];h.refresh_header()
    var tree=h.talent_tree;tree.open(p,0);tree.selected="break_3";tree._detail();await for_shot("circuit")
    tree.selected="break_11";tree._detail();await for_shot("circuit_keystone")
    tree.hide()
    if p.start_run(0,3):
        h.open_station(4);await for_shot("run")
        p.data.run["boon_due"]=true;h.open_station(4);await for_shot("boon")
        p.data.run["boon_due"]=false;p.data.run["route_due"]=true;h.open_station(4);await for_shot("route")
        p.data.run["route_due"]=false;p.abandon()
    p.data.best=18
    p._contract(1,0,1147);p._contract(5,5,1555);h.refresh_header()
    h.open_station(4);await for_shot("contracts")
    h.open_station(0);await for_shot("skills_late")
    quit()
func for_shot(key:String) -> void:
    for i in 4:await process_frame
    await RenderingServer.frame_post_draw
    root.get_viewport().get_texture().get_image().save_png(OUT+key+".png")
