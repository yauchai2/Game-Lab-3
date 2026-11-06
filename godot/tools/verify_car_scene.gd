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
func ticks(count: int) -> void:
    for i in count:
        await physics_frame
func run() -> void:
    var scene = (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    var car: StaticBody3D = scene.get_node("ParkedCar")
    var meshes = car.find_children("*","MeshInstance3D",true,false)
    var triangles := 0
    for mesh in meshes:
        triangles += mesh.mesh.get_faces().size() / 3
    check(triangles == 1524,"car_mesh_triangle_count",{"triangles":triangles})
    check(car.get_node("Collision").shape is BoxShape3D,"car_has_simple_collision")
    check(absf(car.get_node("Collision").shape.size.z-4.2) < .001,"target_length_4_2m")
    var sample = scene.get_node("StyleSample")
    check(meshes.size() > 0 and sample.affected.has(meshes[0]),"car_participates_in_style_toggle")
    var player = scene.get_node("Player")
    scene.activate_walk(false)
    player.set_mouse_capture(true)
    player.global_position = Vector3(-.4,.08,-17)
    await ticks(30)
    Input.action_press("walk_left")
    await ticks(90)
    Input.action_release("walk_left")
    var car_right_edge: float = car.global_position.x + car.get_node("Collision").shape.size.x/2.0
    check(player.global_position.x > car_right_edge and player.global_position.x < -.5,"player_is_blocked_by_car",{"player_x":player.global_position.x,"car_right_edge":car_right_edge})
    check(player.is_on_floor(),"player_remains_on_road")
    var report := {"passed":not failed,"checks":checks,"display_driver":DisplayServer.get_name(),"human_playtest":false,"engine":Engine.get_version_info().string}
    var file := FileAccess.open("res://../docs/evidence/car/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("CAR_SCENE_VERIFIED ",JSON.stringify(report))
    scene.get_node("AircraftFlyby").sound.stop()
    scene.queue_free()
    await process_frame
    quit(1 if failed else 0)
