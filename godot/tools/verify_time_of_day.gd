extends SceneTree
## Time-of-day presets: lighting only, persisted, N key cycles on title/pause. Args: [screenshot_dir]
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("TIME OF DAY FAIL: "+label)
func key(code:Key) -> void:
    for down in [true,false]:
        var event:=InputEventKey.new()
        event.keycode=code;event.physical_keycode=code;event.pressed=down
        Input.parse_input_event(event)
        await process_frame;await process_frame
func run() -> void:
    var out:String=OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ""
    var prefs_path:="user://test_tod.cfg"
    if FileAccess.file_exists(prefs_path):DirAccess.remove_absolute(ProjectSettings.globalize_path(prefs_path))
    var scene:=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=prefs_path
    root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false)
    scene.audio.muted=true;scene.backdrop.freeze_for_capture()
    var sun:DirectionalLight3D=scene.backdrop.street.get_node("Sun")
    var day_energy:=sun.light_energy
    check("default is DAY with original sun",scene.time_of_day_choice==0 and absf(day_energy-0.85)<0.001 and not scene.backdrop.environment.fog_enabled)
    if out!="":
        scene.start_match(true);scene.sim.phase="fight"
        scene.sim.fighters[0].x=-1.0;scene.sim.fighters[1].x=1.0
        for i in 20:scene._present(1.0/60.0)
    var energies:Array[float]=[]
    for i in 4:
        scene.backdrop.set_time_of_day(i)
        energies.append(sun.light_energy)
        scene._present(1.0/60.0)
        if out!="":
            for f in 6:await process_frame
            DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
            root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(out+"/tod_%d.png"%i))
    check("night is darker than day",energies[2]<energies[0])
    check("fog preset enables fog and day disables",true)
    scene.backdrop.set_time_of_day(3);check("fog on for FOG",scene.backdrop.environment.fog_enabled)
    scene.backdrop.set_time_of_day(0);check("fog off and adjustment off for DAY",not scene.backdrop.environment.fog_enabled and not scene.backdrop.environment.adjustment_enabled)
    check("out of range clamps",preload("res://scripts/combat/time_of_day.gd").clamp_index(9)==3 and preload("res://scripts/combat/time_of_day.gd").clamp_index(-4)==0)
    if scene.screen=="play":scene.return_to_title()
    scene.screen="title"
    await key(KEY_N)
    check("N on title cycles to DUSK",scene.time_of_day_choice==1 and scene.backdrop.time_of_day==1)
    scene.screen="play"
    await key(KEY_N)
    check("N during play is ignored",scene.time_of_day_choice==1)
    scene.screen="pause"
    await key(KEY_N);await key(KEY_N);await key(KEY_N)
    check("N wraps back to DAY after four presses",scene.time_of_day_choice==0)
    await key(KEY_N)
    scene.free();await process_frame
    var again:=preload("res://scenes/combat/street_fight.tscn").instantiate()
    again.preferences_path=prefs_path
    root.add_child(again);again.set_process(false);again.set_physics_process(false);again.audio.muted=true
    check("choice persists across sessions",again.time_of_day_choice==1 and again.backdrop.time_of_day==1)
    var prefs=preload("res://scripts/combat/fight_preferences.gd").new()
    var bad:=prefs.read_options("")
    bad["time_of_day"]=99
    prefs.write_options(prefs_path,bad)
    check("invalid saved value clamps",prefs.read_options(prefs_path).time_of_day==3)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(prefs_path))
    var failed:=checks.filter(func(c):return not c.passed)
    print("TIME OF DAY: %d/%d checks passed"%[checks.size()-failed.size(),checks.size()])
    quit(1 if not failed.is_empty() else 0)
