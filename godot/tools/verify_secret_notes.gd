extends SceneTree
## G6 secret MONO skin code, and G5 dev note after all tags. Title-screen key sequence Z Z X X Q.
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("SECRET FAIL: "+label)
func key(code:Key) -> void:
    for down in [true,false]:
        var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down
        Input.parse_input_event(e)
        await process_frame;await process_frame
func run() -> void:
    var dir:="user://test_secret"
    for f in ["options.cfg","banter.cfg","tags.cfg"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(dir+"/"+f))
    var scene=load("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=dir+"/options.cfg"
    root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    scene.screen="title"
    check("starts locked",not scene.secret_mono)
    for k in 4:await key(KEY_N)
    check("N cycles only four presets while locked",scene.time_of_day_choice==0)
    for k in [KEY_Z,KEY_Z,KEY_X,KEY_Q]:await key(k)
    check("wrong sequence does not unlock",not scene.secret_mono)
    for k in [KEY_Z,KEY_Z,KEY_X,KEY_X,KEY_Q]:await key(k)
    check("Z Z X X Q unlocks and switches to MONO",scene.secret_mono and scene.time_of_day_choice==4 and scene.backdrop.environment.adjustment_saturation==0.0)
    scene.screen="play"
    for k in [KEY_Z,KEY_Z,KEY_X,KEY_X,KEY_Q]:await key(k)
    scene.screen="title"
    for k in 5:await key(KEY_N)
    check("after unlock N cycles five presets",scene.time_of_day_choice==4)
    scene.free()
    var again=load("res://scenes/combat/street_fight.tscn").instantiate()
    again.preferences_path=dir+"/options.cfg"
    root.add_child(again);again.set_process(false);again.set_physics_process(false);again.audio.muted=true
    check("secret and MONO persist",again.secret_mono and again.time_of_day_choice==4)
    again.language="en"
    for id in again.tag_store.IDS:if id!="clean":again.tag_store.unlock(id)
    again.character_choices=[0,1]
    again.start_match(false)
    again.sim.phase="match_over";again.sim.winner=0;again.sim.wins=[2,0]
    again._physics_process(1.0/60)
    check("collecting the last tag shows a dev note",again.tag_store.count()==8 and again.result_line.contains("DEV NOTE: "))
    again.start_match(false)
    for e in [{"kind":"hit","attacker":0},{"kind":"hit","attacker":1},{"kind":"block","target":0},{"kind":"parry","target":0},{"kind":"homing_chase","target":0},{"kind":"block","target":1}]:again._count_style(e)
    check("style counters follow only player events",again.style_stats=={"hits":1,"defense":3,"air":1})
    again.start_match(false)
    check("style counters reset each match",again.style_stats=={"hits":0,"defense":0,"air":0})
    again.free()
    for f in ["options.cfg","banter.cfg","tags.cfg"]:DirAccess.remove_absolute(ProjectSettings.globalize_path(dir+"/"+f))
    var failed:=checks.filter(func(c):return not c.passed)
    print("SECRET NOTES: %d/%d checks passed"%[checks.size()-failed.size(),checks.size()])
    quit(1 if not failed.is_empty() else 0)
