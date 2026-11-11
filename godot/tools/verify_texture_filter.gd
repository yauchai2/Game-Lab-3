extends SceneTree
var checks: Array = []
var failed := false
func _initialize() -> void:
    call_deferred("run")
func check(value: bool, title: String) -> void:
    checks.append({"check":title,"passed":value})
    if not value:
        failed = true
        push_error(title)
func run() -> void:
    var scene = (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    await process_frame
    var sample = scene.get_node("StyleSample")
    var wall: MeshInstance3D = scene.get_node("Street/BuildingMasses/OrangeFront")
    var wall_index: int = sample.affected.find(wall)
    check(wall_index >= 0, "front_wall_enrolled")
    if wall_index >= 0:
        var material: ShaderMaterial = sample.replacements[wall_index]
        check(material.get_shader_parameter("use_world_uv"), "wall_uses_world_projection")
        check(material.get_shader_parameter("world_texture") == material.get_shader_parameter("base_texture"), "samplers_use_same_wall_texture")
        check(material.shader.code.contains("world_texture : source_color, filter_nearest_mipmap"), "world_texture_nearest_with_mipmaps")
        check(material.shader.code.contains("base_texture : source_color, filter_linear_mipmap"), "imported_texture_linear_filter_preserved")
        check(is_equal_approx(material.get_shader_parameter("texture_scale").x * 128.0, 32.0), "wall_density_32_texels_per_metre")
    var road: MeshInstance3D = scene.get_node("Street/StreetGeometry/MainRoad")
    var road_material: BaseMaterial3D = road.material_override
    check(road_material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS, "road_nearest_with_mipmaps")
    check(is_equal_approx(road_material.uv1_scale.x * 128.0, 32.0), "road_density_32_texels_per_metre")
    var model = scene.get_node("Player/Visual/CharacterModel")
    var meshes = model.find_children("*", "MeshInstance3D", true, false)
    var character_index: int = sample.affected.find(meshes[0])
    check(character_index >= 0 and not sample.replacements[character_index].get_shader_parameter("use_world_uv"), "character_uses_original_uv_sampler")
    sample.set_mode(0)
    check(wall.material_override == sample.originals[wall_index], "original_material_mode_restored")
    sample.set_mode(1)
    check(wall.material_override == sample.replacements[wall_index], "toon_material_mode_restored")
    var report := {"passed":not failed,"checks":checks,"display_driver":DisplayServer.get_name(),"human_playtest":false,"engine":Engine.get_version_info().string}
    var file := FileAccess.open("res://../docs/evidence/style-reference/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("TEXTURE_FILTER_VERIFIED ",JSON.stringify(report))
    scene.get_node("AircraftFlyby").sound.stop()
    scene.queue_free()
    await process_frame
    quit(1 if failed else 0)
