extends SceneTree
const OUT="res://../docs/evidence/last-service-runtime/"
var s:Node
func _initialize() -> void:call_deferred("run")
func render() -> void:await process_frame;await RenderingServer.frame_post_draw
func shot(label:String) -> void:
    s.hud.queue_redraw();await render();root.get_texture().get_image().save_png(OUT+label+".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute("/tmp/service-capture.cfg"+suffix)
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/service-capture.cfg"
    root.add_child(s);s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    s.hud.open_page("roster")
    var report:Array=[]
    for i in 4:
        s.set_character(0,i)
        for frame in 24:s.hud._process(1.0/60.0);await process_frame
        await shot("roster-"+str(i))
        var f:Node=s.fighters[0]
        report.append({"character":i,"bones":f.skeleton.get_bone_count(),"mapped":f.motions.mapping.size(),"head":f.motions.bone_index("Head"),"up":str(f.motions.model_up),"forward":str(f.motions.model_forward)})
    s.hud.open_page("skills");await shot("skills-fresh")
    s.growth.reward(3,"capture-fixture",true,3);s.growth.unlock(3,0);s.growth.toggle(3,0)
    s.hud.rebuild_menu();await shot("skills-one-unlock")
    s.hud.close_page();s.start_match(true)
    for frame in 24:s._process(1.0/60.0)
    await shot("fight")
    s.return_to_title();s.set_character(0,3);s.set_character(1,0);s.start_match(true)
    s.sim.fighters[0].x=-2;s.sim.fighters[1].x=2
    s.pending={"attack":"special"}
    for frame in 150:s._physics_process(1.0/60.0);s._process(1.0/60.0)
    await shot("loop-node")
    FileAccess.open(OUT+"models.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    s.queue_free();s=null;await process_frame;await render();await create_timer(.3).timeout;call_deferred("quit")
