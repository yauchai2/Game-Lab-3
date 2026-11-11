extends SceneTree
var checks: Array = []
var failed := false
func _initialize() -> void:
    call_deferred("run")
func check(value: bool, title: String, details := {}) -> void:
    checks.append({"check":title,"passed":value,"details":details})
    if not value:
        failed = true
        push_error(title+": "+JSON.stringify(details))
func ticks(count: int) -> void:
    for i in count:
        await physics_frame
func key(scene: Node, code: int) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    scene._unhandled_key_input(event)
func run() -> void:
    var scene = (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    await ticks(60)
    var player = scene.get_node("Player")
    var model: Node3D = player.get_node("Visual/CharacterModel")
    var driver = player.get_node("Visual/PoseDriver")
    var skeletons = model.find_children("*","Skeleton3D",true,false)
    var meshes = model.find_children("*","MeshInstance3D",true,false)
    check(skeletons.size()==1 and skeletons[0].get_bone_count()==65,"character_skeleton_loaded")
    var skeleton: Skeleton3D = skeletons[0]
    var triangles := 0
    for mesh in meshes:
        triangles += mesh.mesh.get_faces().size()/3
    check(triangles==1664,"character_mesh_triangles",{"count":triangles})
    check(absf(model.scale.y-1.75)<.001 and (model.transform.basis*Vector3.BACK).normalized().dot(Vector3.FORWARD)>.99,"character_scale_and_forward")
    check(not player.get_node("Visual/Body").visible and model.visible,"character_replaces_placeholder_visually")
    check(scene.get_node("StyleSample").affected.has(meshes[0]),"character_uses_toon_material_modes")
    var hip: int = skeleton.find_bone("mixamorig_LeftUpLeg")
    var rest: Quaternion = driver.base_rotations["LeftUpLeg"]
    var maximum := 0.0
    scene.activate_walk(false)
    player.set_mouse_capture(true)
    Input.action_press("walk_forward")
    for i in 120:
        await ticks(1)
        maximum = maxf(maximum,skeleton.get_bone_pose_rotation(hip).angle_to(rest))
    Input.action_release("walk_forward")
    check(maximum>.1 and player.global_position.z<3.0,"walking_updates_bones_and_position",{"max_bone_angle":maximum,"z":player.global_position.z})
    await ticks(80)
    check(driver.motion_blend<.01 and absf(skeleton.get_bone_pose_rotation(hip).angle_to(rest))<.03,"gait_returns_to_idle")
    key(scene,KEY_V)
    check(player.first_person and not player.get_node("Visual").visible,"first_person_hides_character")
    key(scene,KEY_V)
    check(not player.first_person and player.get_node("Visual").visible,"third_person_restores_character")
    var sample = scene.get_node("StyleSample")
    var environment: Environment = scene.get_node("Street/WorldEnvironment").environment
    check(sample.image_sky_enabled and environment.sky==sample.generated_sky,"image_sky_is_default")
    var texturing = scene.get_node("EnvironmentTextures")
    check(texturing.applied.size()==14,"environment_textures_applied",{"count":texturing.applied.size()})
    var wall: MeshInstance3D = scene.get_node("Street/BuildingMasses/BlueFront")
    var wall_index: int = sample.affected.find(wall)
    check(wall_index>=0 and sample.replacements[wall_index].get_shader_parameter("use_world_uv"),"toon_wall_uses_world_texture")
    var graffiti: MeshInstance3D = scene.get_node("StreetDressing/AlleyGraffiti")
    var texture: Texture2D = graffiti.material_override.albedo_texture
    check(texture.get_width()==256 and texture.get_height()==131,"mural_import_is_low_resolution",{"width":texture.get_width(),"height":texture.get_height()})
    check(graffiti.find_children("*","CollisionShape3D",true,false).is_empty(),"mural_does_not_block_player")
    var report := {"passed":not failed,"checks":checks,"display_driver":DisplayServer.get_name(),"human_playtest":false,"engine":Engine.get_version_info().string}
    var file := FileAccess.open("res://../docs/evidence/character/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("CHARACTER_TEXTURES_VERIFIED ",JSON.stringify(report))
    scene.get_node("AircraftFlyby").sound.stop()
    scene.queue_free()
    await process_frame
    quit(1 if failed else 0)
