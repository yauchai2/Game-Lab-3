extends SceneTree
## F5 gamepad rumble: routing by side, options persistence, off paths. Feel only.
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("RUMBLE FAIL: "+label)
func run() -> void:
    var path:="user://test_rumble/options.cfg"
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    var scene=load("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=path
    root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    var c=scene.controls
    c.pads_override=[7,8]
    scene.start_match(false,true)
    c.pads_override=[7,8];c.assign(true)
    scene.screen="play"
    c.rumble_log.clear()
    scene._event_rumble({"kind":"hit","target":1,"attacker":0,"move":"heavy"})
    check("heavy hit: victim strong, attacker light, each on own pad",c.rumble_log.size()==2 and c.rumble_log[0].side==1 and c.rumble_log[0].strong>c.rumble_log[1].strong and c.rumble_log[0].device!=c.rumble_log[1].device)
    c.rumble_log.clear()
    scene._event_rumble({"kind":"hit","target":0,"attacker":1,"move":"light"})
    check("light hit: only a short tap for the victim",c.rumble_log.size()==1 and c.rumble_log[0].seconds<=.1)
    c.rumble_log.clear()
    scene._event_rumble({"kind":"parry","target":0})
    check("parry rumbles the defender",c.rumble_log.size()==1 and c.rumble_log[0].side==0)
    c.rumble_log.clear()
    scene._event_rumble({"kind":"ko","target":1})
    check("KO rumbles both",c.rumble_log.size()==2)
    c.rumble_enabled=false;c.rumble_log.clear()
    scene._event_rumble({"kind":"ko","target":1})
    check("disabled option: silent",c.rumble_log.is_empty())
    c.rumble_enabled=true;scene.reduced_effects=true
    scene._event_rumble({"kind":"ko","target":1})
    check("reduced effects: silent",c.rumble_log.is_empty())
    scene.reduced_effects=false;scene.screen="pause"
    scene._event_rumble({"kind":"ko","target":1})
    check("not while paused",c.rumble_log.is_empty())
    scene.screen="play";c.pads_override=[];c.assign(true)
    scene._event_rumble({"kind":"ko","target":1})
    check("no pad: nothing to rumble",c.rumble_log.is_empty())
    scene.start_match(false,false);c.pads_override=[7];c.assign(true)
    check("solo: every pad drives P1, none drives CPU",c.rumble_devices(0)==[7] and c.rumble_devices(1).is_empty())
    c.rumble_enabled=false;scene.save_options()
    var back:Dictionary=scene.preferences.read_options(path)
    check("rumble option persists",back.rumble==false)
    check("default is on",scene.preferences.read_options("").rumble==true)
    scene.free()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    var failed:=checks.filter(func(x):return not x.passed)
    print("RUMBLE: %d/%d checks passed"%[checks.size()-failed.size(),checks.size()])
    quit(1 if not failed.is_empty() else 0)
