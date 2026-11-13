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
