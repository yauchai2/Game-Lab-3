extends SceneTree
const OUT="res://../docs/evidence/nightshift-reference/"
var s:Node
var h:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func frames(n:=3) -> void:
    for i in n:await process_frame
    await RenderingServer.frame_post_draw
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("REFERENCE ",label," ",ok)
    if not ok:push_error(label)
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.city_save_path="user://reference-test/profile.json";s.story_opening_on_boot=false
    root.add_child(s);s.audio.muted=true;s.set_process(false);s.set_physics_process(false);await frames(6)
    s.city_campaign.open_city();h=s.city_campaign.hub;h.set_process(false);await frames(3)
    h._avatar(.1,Vector2.ZERO);h.workshop.pulse_time=0;h.workshop.sample(0,false);await frames()
    print("POSE ",h.hero_visual.motions.model_up," ",h.hero_visual.skeleton.get_bone_pose_rotation(h.hero_visual.motions.bone_index("RightArm")))
    for time in [0.0,1.5,5.5,8.0,10.5,14.5]:
        h.workshop.pulse_time=time;h._avatar(.1,Vector2.ZERO);h.workshop.sample(time,false);await frames()
        h.viewport.get_texture().get_image().save_png(OUT+"frame-%04d.png"%int(time*10))
    check("calibrated scene contains real depth geometry and five rigged actors",h.workshop.trace_root.get_child_count()>=8 and h.town_npcs.size()==3 and h.workshop.dealer_rig.skeleton!=null)
    for station in h.STATIONS.size():
        h.close_panel();h.hero.position=h.workshop.spawns[0];h.request_station(station)
        for tick in 1800:
            h._process(1.0/60)
            if tick%150==0:await frames(1)
            if h.route_station<0:break
        check("reference station %d remains reachable"%station,h.hero.position.distance_to(h.STATIONS[station])<1.85 and (h.panel.visible or h.talent_tree.visible))
        if h.talent_tree.visible:h.talent_tree.hide()
    h.close_panel()
    h.workshop.sample(10.5,true)
    check("reduced effects disables beams smoke and electrical arcs",h.workshop.beams.all(func(n:Node3D)->bool:return not n.visible) and h.workshop.arcs.all(func(n:Node3D)->bool:return not n.visible))
    s.queue_free();await frames(6);FileAccess.open(OUT+"verification.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks},"  "));quit()
