extends SceneTree
## F1 local versus session board; banter/tags/style stay out of two-human matches.
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("VERSUS SOCIAL FAIL: "+label)
func finish(scene,winner:int) -> void:
    scene.sim.phase="match_over";scene.sim.winner=winner;scene.sim.wins=[2,0] if winner==0 else [0,2]
    scene._physics_process(1.0/60)
func run() -> void:
    var dir:="user://test_versus_social"
    for f in ["options.cfg","banter.cfg","tags.cfg"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(dir+"/"+f))
    var scene=load("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=dir+"/options.cfg"
    root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    scene.language="en"
    scene.start_match(false,true)
    check("versus has no CPU-rival taunt",scene.versus and scene.intro_line=="")
    finish(scene,0)
    check("first result shows 1-0 and no streak",scene.result_line.contains("P1 1 - 0 P2") and not scene.result_line.contains("STREAK"))
    scene.start_match(false,true);finish(scene,0)
    check("second P1 win shows streak 2",scene.result_line.contains("P1 2 - 0 P2") and scene.result_line.contains("P1 STREAK 2"))
    scene.start_match(false,true);finish(scene,1)
    check("P2 win resets to a streak of 1 (no label)",scene.result_line.contains("P1 2 - 1 P2") and not scene.result_line.contains("STREAK"))
    scene.start_match(false,true);finish(scene,1)
    check("P2 streak 2 labelled",scene.result_line.contains("P2 STREAK 2"))
    check("versus never touched tags, banter memory or style",scene.tag_store.count()==0 and scene.banter_store.streak==0 and scene.style_stats.hits==0)
    scene.start_match(false,false);finish(scene,0)
    check("a CPU match afterwards still earns tags and keeps the versus board",scene.tag_store.has("zip") and scene.versus_score==[2,2])
    scene.language="zh";scene.start_match(false,true);finish(scene,0)
    check("Chinese board text",scene.result_line.contains("本機連戰"))
    scene.free()
    for f in ["options.cfg","banter.cfg","tags.cfg"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(dir+"/"+f))
    var failed:=checks.filter(func(c):return not c.passed)
    print("VERSUS SOCIAL: %d/%d checks passed"%[checks.size()-failed.size(),checks.size()])
    quit(1 if not failed.is_empty() else 0)
