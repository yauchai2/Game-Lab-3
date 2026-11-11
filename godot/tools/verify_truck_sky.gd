extends SceneTree
var checks: Array = []
var failed := false
func _initialize() -> void:
    call_deferred("run")
func check(value: bool, title: String, data := {}) -> void:
    checks.append({"check":title,"passed":value,"details":data})
    if not value:
        failed = true
        push_error(title+": "+JSON.stringify(data))
func key(scene: Node, code: int) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    scene._unhandled_key_input(event)
func ticks(count: int) -> void:
    for i in count:
        await physics_frame
func run() -> void:
    var scene = (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    var truck: StaticBody3D = scene.get_node("ParkedTruck")
    var meshes = truck.get_node("Visual").find_children("*","MeshInstance3D",true,false)
    var triangles := 0
    for mesh in meshes:
        triangles += mesh.mesh.get_faces().size() / 3
    check(triangles == 1510,"truck_mesh_triangle_count",{"triangles":triangles})
    check(truck.get_node("Collision").shape is BoxShape3D and absf(truck.get_node("Collision").shape.size.z-5.5)<.001,"truck_has_5_5m_collision")
    var sample = scene.get_node("StyleSample")
    check(meshes.size()>0 and sample.affected.has(meshes[0]),"truck_uses_style_sample")
    var camera := root.get_viewport().get_camera_3d()
    var env: Environment = scene.get_node("Street/WorldEnvironment").environment
    var ambient := env.ambient_light_energy
    check(sample.image_sky_enabled and env.sky==sample.generated_sky,"image_sky_is_default")
    key(scene,KEY_N)
    check(not sample.image_sky_enabled and env.sky==sample.procedural_sky,"n_switches_to_procedural")
    key(scene,KEY_N)
    check(sample.image_sky_enabled and env.background_mode==Environment.BG_SKY and env.sky==sample.generated_sky,"n_enables_image_sky")
    check(root.get_viewport().get_camera_3d()==camera and env.ambient_light_energy==ambient,"sky_preserves_camera_ambient")
    key(scene,KEY_N)
    check(not sample.image_sky_enabled and env.sky==sample.procedural_sky,"n_returns_to_procedural")
    key(scene,KEY_C)
    check(not sample.clouds_enabled and env.background_mode==Environment.BG_COLOR,"c_still_toggles_flat")
    key(scene,KEY_N)
    check(sample.image_sky_enabled and env.sky==sample.generated_sky,"n_works_from_flat")
    key(scene,KEY_C)
    check(not sample.image_sky_enabled and not sample.clouds_enabled and env.background_mode==Environment.BG_COLOR,"c_works_from_image")
    var player = scene.get_node("Player")
    scene.activate_walk(false)
    player.set_mouse_capture(true)
    player.global_position = Vector3(0,.08,-36)
    await ticks(30)
    Input.action_press("walk_right")
    await ticks(90)
    Input.action_release("walk_right")
    var left_edge: float = truck.global_position.x-truck.get_node("Collision").shape.size.x/2.0
    check(player.global_position.x < left_edge and player.global_position.x > .3,"player_blocked_by_truck",{"player_x":player.global_position.x,"left_edge":left_edge})
    check(player.is_on_floor(),"player_stays_on_road")
    var report := {"passed":not failed,"checks":checks,"display_driver":DisplayServer.get_name(),"human_playtest":false,"engine":Engine.get_version_info().string}
    var file := FileAccess.open("res://../docs/evidence/truck-sky/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("TRUCK_SKY_VERIFIED ",JSON.stringify(report))
    scene.get_node("AircraftFlyby").sound.stop()
    scene.queue_free()
    await process_frame
    quit(1 if failed else 0)
