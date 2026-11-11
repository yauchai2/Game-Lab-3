extends SceneTree
## G1 street tags: pure unlock rules, local save, session integration, wall visuals.
const Tags=preload("res://scripts/combat/street_tags.gd")
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("STREET TAGS FAIL: "+label)
func run() -> void:
    var path:="user://test_tags.cfg"
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    var t=Tags.new(path)
    check("starts empty",t.count()==0)
    check("loss earns nothing (non-mirror)",t.evaluate(0,1,false,0,0,1).is_empty() and t.count()==0)
    check("win with ZIP earns zip only in day with a dropped round",t.evaluate(0,1,true,1,0,1)==["zip"])
    check("same win again earns nothing",t.evaluate(0,1,true,1,0,1).is_empty())
    check("win with LOOP at dusk, flawless",t.evaluate(3,1,true,2,1,0)==["loop","dusk","clean"])
    check("5 streak adds streak tag",t.evaluate(1,2,true,5,0,2)==["rivet","streak"])
    check("mirror even on loss",t.evaluate(2,2,false,0,0,2)==["mirror"])
    check("hush from a win",t.evaluate(2,0,true,1,0,2)==["hush"])
    check("all 8 earned",t.count()==8)
    var re=Tags.new(path)
    check("persists across loads",re.count()==8 and re.has("mirror"))
    check("unknown id rejected",not re.unlock("bogus"))
    var bad:=ConfigFile.new();bad.set_value("tags","version",1);bad.set_value("tags","unlocked",["zip","evil",7,"clean"]);bad.save(path)
    var clean=Tags.new(path)
    check("invalid saved ids dropped",clean.count()==2 and clean.has("zip") and clean.has("clean"))
    bad.set_value("tags","version",9);bad.save(path)
    check("unknown version ignored",Tags.new(path).count()==0)
    check("empty path stays in memory",Tags.new("").unlock("zip"))
    for id in Tags.IDS:check("title "+id,Tags.title(id,true).length()>3 and Tags.title(id,false).length()>=3)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    # Session integration (isolated prefs folder)
    var dir:="user://test_tags_session"
    for f in ["options.cfg","banter.cfg","tags.cfg"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(dir+"/"+f))
    var scene=load("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=dir+"/options.cfg"
    root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    scene.language="en"
    check("eight board nodes exist and start hidden",scene.backdrop.tag_nodes.size()==8 and scene.backdrop.tag_nodes.values().all(func(n):return not n.visible))
    scene.character_choices=[0,1]
    scene.start_match(false)
    scene.sim.phase="match_over";scene.sim.winner=0;scene.sim.wins=[2,0]
    scene._physics_process(1.0/60)
    check("real win unlocks zip + clean and reports them",scene.tag_store.has("zip") and scene.tag_store.has("clean") and scene.result_line.contains("NEW TAG: ZIP ROUTE MARK") and scene.result_line.contains("TAGS 2 / 8") and not scene.result_line.contains("RADIO"))
    check("unlocked boards become visible, others stay hidden",scene.backdrop.tag_nodes["zip"].visible and scene.backdrop.tag_nodes["clean"].visible and not scene.backdrop.tag_nodes["loop"].visible)
    scene.start_match(true)
    scene.character_choices=[3,3]
    scene.sim.phase="match_over";scene.sim.winner=0
    scene._physics_process(1.0/60)
    check("training never unlocks",scene.tag_store.count()==2 and not scene.tag_store.has("mirror"))
    scene.free()
    var scene2=load("res://scenes/combat/street_fight.tscn").instantiate()
    scene2.preferences_path=dir+"/options.cfg"
    root.add_child(scene2);scene2.set_process(false);scene2.set_physics_process(false);scene2.audio.muted=true
    check("tags persist into a new session and boards show",scene2.tag_store.count()==2 and scene2.backdrop.tag_nodes["zip"].visible)
    scene2.free()
    for f in ["options.cfg","banter.cfg","tags.cfg"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(dir+"/"+f))
    var failed:=checks.filter(func(c):return not c.passed)
    print("STREET TAGS: %d/%d checks passed"%[checks.size()-failed.size(),checks.size()])
    quit(1 if not failed.is_empty() else 0)
