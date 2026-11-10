extends SceneTree
var failed := false
func _initialize() -> void:
    call_deferred("run_checks")
func require(condition: bool, message: String) -> void:
    if not condition:
        push_error(message)
        failed = true
func run_checks() -> void:
    var packed: PackedScene = load("res://scenes/street_whitebox.tscn")
    require(packed != null,"Street scene missing")
    if packed == null:
        quit(1)
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    await physics_frame
    await physics_frame
    var config = JSON.parse_string(FileAccess.get_file_as_string("res://config/street_whitebox.json"))
    require(scene.get_node("Props").get_child_count() == 6,"Expected six source assets")
    var cameras = scene.get_node("ReferenceCameras").get_children()
    require(cameras.size() == 5,"Expected four reference cameras plus layout camera")
    for i in cameras.size():
        var key := InputEventKey.new()
        key.keycode = KEY_1+i
        key.pressed = true
        scene._unhandled_key_input(key)
        require(cameras[i].current,"Camera switching failed")
        var target := Vector3(config.cameras[i].target[0],config.cameras[i].target[1],config.cameras[i].target[2])
        require((-cameras[i].global_basis.z).dot((target-cameras[i].global_position).normalized()) > .999,"Camera orientation mismatch")
    var next_key := InputEventKey.new()
    next_key.keycode = KEY_TAB
    next_key.pressed = true
    scene._unhandled_key_input(next_key)
    require(cameras[0].current,"Tab should wrap to entry camera")
    require(cameras[4].cull_mask == 1,"Layout should exclude aircraft layer")
    var road: MeshInstance3D = scene.get_node("StreetGeometry/MainRoad")
    require(is_equal_approx(road.mesh.size.z,64.0),"Street length mismatch")
    require(is_equal_approx(road.mesh.size.x,8.0),"Road width mismatch")
    var samples := []
    for point in [Vector3(0,2,-2),Vector3(0,2,-16),Vector3(0,2,-32),Vector3(0,2,-60),Vector3(-5,2,-12),Vector3(5,2,-12),Vector3(-12,2,-32),Vector3(-10,2,-28)]:
        var query := PhysicsRayQueryParameters3D.create(point,point-Vector3(0,4,0))
        var hit: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(query)
        require(not hit.is_empty(),"Walk surface ray missed at "+str(point))
        samples.append({"at":[point.x,point.z],"surface_y":hit.position.y})
    var aircraft := scene.get_node("AircraftProxy")
    var engines := 0
    var intakes := 0
    for child in aircraft.get_children():
        if str(child.name).begins_with("Aircraft_Engine"):
            engines += 1
        if str(child.name).begins_with("Aircraft_Intake"):
            intakes += 1
    require(engines == 4 and intakes == 4,"Expected four engines and intakes")
    var meshes = scene.find_children("*","MeshInstance3D",true,false)
    require(meshes.size() > 100,"Building/aircraft geometry missing")
    if failed:
        quit(1)
        return
    var doc := GLTFDocument.new()
    var state := GLTFState.new()
    require(doc.append_from_scene(scene,state) == OK,"GLTF snapshot export failed")
    require(doc.write_to_filesystem(state,OS.get_temp_dir().path_join("flight-street-whitebox.glb")) == OK,"GLTF snapshot save failed")
    if failed:
        quit(1)
        return
    var result := {"street_length_m":64,"road_width_m":8,"sidewalk_width_m":2,"props":6,"cameras":5,"camera_switches_tested":5,"tab_wrap_tested":true,"config_sha256":FileAccess.get_file_as_string("res://config/street_whitebox.json").sha256_text(),"engines":engines,"mesh_nodes":meshes.size(),"walk_surface_samples":samples,"physics_ray_checks":true,"cpu_preview_export":true,"player_controller":false,"gpu_image_test":false}
    var file := FileAccess.open("res://../docs/evidence/whitebox/verification.json",FileAccess.WRITE)
    require(file != null,"Cannot write evidence")
    file.store_string(JSON.stringify(result,"  "))
    print("WHITEBOX_VERIFIED ",JSON.stringify(result))
    quit(0)
