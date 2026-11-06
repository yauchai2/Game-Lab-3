extends SceneTree
var failed := false
var checks: Array = []
func _initialize() -> void:
    call_deferred("run_checks")
func check(value: bool, name: String, data := {}) -> void:
    checks.append({"check":name,"passed":value,"details":data})
    if not value:
        failed = true
        push_error(name+": "+JSON.stringify(data))
func key(scene: Node, code: int) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    scene._unhandled_key_input(event)
func run_checks() -> void:
    var packed: PackedScene = load("res://scenes/street_walk.tscn")
    if packed == null:
        push_error("Cannot load walk scene")
        quit(1)
        return
    var scene = packed.instantiate()
    root.add_child(scene)
    await process_frame
    var sample = scene.get_node("StyleSample")
    check(sample.mode == 1,"initial_two_band_mode")
    check(sample.affected.size() > 30 and sample.affected.size() == sample.originals.size(),"sample_has_reversible_materials",{"count":sample.affected.size()})
    check(sample.details.visible and sample.detail_instance_count > 50,"sample_details_exist",{"instances":sample.detail_instance_count,"batches":sample.details.get_child_count()})
    check(not sample.glyphs[0].visible,"sample_uses_new_sign")
    var textured := 0
    for i in sample.replacements.size():
        if sample.replacements[i].get_shader_parameter("use_texture"):
            textured += 1
    check(textured >= 2,"source_prop_textures_preserved",{"textured_materials":textured})
    var double_sided := 0
    for replacement in sample.replacements:
        if replacement.shader == sample.two_sided_shader:
            double_sided += 1
    check(double_sided >= 2,"double_sided_source_materials_preserved",{"materials":double_sided})
    key(scene,KEY_B)
    check(sample.mode == 2 and sample.replacements[0].get_shader_parameter("bands") == 3,"toggle_three_bands")
    key(scene,KEY_B)
    check(sample.mode == 0 and sample.affected[0].material_override == sample.originals[0],"toggle_restores_original_material")
    check(sample.details.visible and not sample.glyphs[0].visible,"comparison_preserves_geometry")
    key(scene,KEY_B)
    check(sample.mode == 1 and sample.replacements[0].get_shader_parameter("bands") == 2,"toggle_two_bands")
    var original_scene = (load("res://scenes/street_whitebox.tscn") as PackedScene).instantiate()
    var original_environment: WorldEnvironment = original_scene.get_node("WorldEnvironment")
    var sample_environment: WorldEnvironment = scene.get_node("Street/WorldEnvironment")
    check(is_equal_approx(original_environment.environment.ambient_light_energy,.65) and is_equal_approx(sample_environment.environment.ambient_light_energy,.35),"sample_lighting_does_not_mutate_s1")
    original_scene.free()
    check(scene.get_node("Player").controls_enabled and scene.get_node("Player/ViewPivot/SpringArm3D/Camera3D").current,"walk_controls_remain_active")
    var report := {"passed":not failed,"checks":checks,"engine":Engine.get_version_info().string,"gpu_render_test":false,"human_review":false}
    var file := FileAccess.open("res://../docs/evidence/style/verification.json",FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(report,"  "))
    print("STYLE_VERIFIED ",JSON.stringify(report))
    quit(1 if failed else 0)
