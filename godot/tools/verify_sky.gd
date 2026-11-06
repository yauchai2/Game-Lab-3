extends SceneTree
var failed := false
var checks: Array = []
func _initialize() -> void:
    call_deferred("run")
func check(value: bool, title: String) -> void:
    checks.append({"check":title,"passed":value})
    if not value:
        failed = true
        push_error(title)
func key(scene: Node, code: int) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    scene._unhandled_key_input(event)
func run() -> void:
    var scene = (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    await process_frame
    var sample = scene.get_node("StyleSample")
    var env: Environment = scene.get_node("Street/WorldEnvironment").environment
    var camera: Camera3D = root.get_viewport().get_camera_3d()
    check(sample.clouds_enabled and env.background_mode == Environment.BG_SKY and env.sky.sky_material.shader != null,"cloud_sky_enabled_by_default")
    var original = (load("res://scenes/street_whitebox.tscn") as PackedScene).instantiate()
    var original_env: Environment = original.get_node("WorldEnvironment").environment
    check(original_env != env and original_env.background_mode == Environment.BG_COLOR,"whitebox_environment_unchanged")
    original.free()
    var ambient := env.ambient_light_energy
    var style: int = sample.mode
    key(scene,KEY_C)
    check(not sample.clouds_enabled and env.background_mode == Environment.BG_COLOR,"c_restores_flat_sky")
    check(sample.mode == style and env.ambient_light_energy == ambient,"sky_toggle_preserves_style_and_ambient_setting")
    check(root.get_viewport().get_camera_3d() == camera and scene.get_node("Player").controls_enabled,"sky_toggle_keeps_camera_and_controls")
    key(scene,KEY_C)
    check(sample.clouds_enabled and env.background_mode == Environment.BG_SKY,"c_restores_clouds")
    key(scene,KEY_B)
    check(sample.mode == 2 and sample.clouds_enabled,"material_toggle_keeps_sky")
    var report := {"passed":not failed,"checks":checks,"engine":Engine.get_version_info().string,"display_driver":DisplayServer.get_name(),"hardware_gpu_verified":false,"human_playtest":false}
    var file := FileAccess.open("res://../docs/evidence/sky/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("SKY_VERIFIED ",JSON.stringify(report))
    scene.get_node("AircraftFlyby").sound.stop()
    scene.queue_free()
    await process_frame
    quit(1 if failed else 0)
