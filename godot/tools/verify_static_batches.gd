extends SceneTree
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("STATIC BATCH FAIL: "+label)
func run() -> void:
    if DisplayServer.get_name()=="headless":
        push_error("Use a native Compatibility renderer: the dummy renderer does not store MultiMesh transforms for readback.")
        quit(2)
        return
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    var bg=scene.backdrop
    var stats: Dictionary=bg.static_batch_stats
    check("hundreds of static boxes are grouped into a smaller material set",stats.source_boxes>100 and stats.batches<stats.source_boxes/3.0)
    var bounds_match:=true
    var normals_match:=true
    var materials_match:=true
    var hidden_sources:=true
    var original_uvs:=true
    var sources:=0
    var cube:=BoxMesh.new()
    cube.size=Vector3.ONE
    var uv: PackedVector2Array=cube.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
    for mesh in bg.street.find_children("*","MeshInstance3D",true,false):
        if not mesh.has_meta("static_batch_id"):continue
        sources+=1
        var batch: MultiMeshInstance3D=bg.street.get_node("StaticStreetBatches/Batch_%02d"%mesh.get_meta("static_batch_id"))
        var instance: Transform3D=batch.multimesh.get_instance_transform(mesh.get_meta("static_batch_index"))
        var pose: Transform3D=batch.global_transform*instance
        var a: AABB=mesh.global_transform*mesh.mesh.get_aabb()
        var b: AABB=pose*cube.get_aabb()
        var same_bounds: bool=a.position.distance_to(b.position)<.0001 and a.size.distance_to(b.size)<.0001
        if not same_bounds:print("BOUNDS_DIFF ",mesh.get_path()," source=",a," batch=",b," box=",mesh.mesh.size)
        bounds_match=bounds_match and same_bounds
        for axis in [Vector3.RIGHT,Vector3.UP,Vector3.BACK]:
            var a_normal: Vector3=(mesh.global_basis.inverse().transposed()*axis).normalized()
            var b_normal: Vector3=(pose.basis.inverse().transposed()*axis).normalized()
            normals_match=normals_match and a_normal.distance_to(b_normal)<.00001
        hidden_sources=hidden_sources and mesh.layers==0 and mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and batch.layers==mesh.get_meta("static_batch_source_layers") and batch.cast_shadow==mesh.get_meta("static_batch_source_shadow")
        var material: ShaderMaterial=mesh.get_active_material(0)
        materials_match=materials_match and material.shader==batch.material_override.shader
        for uniform in material.shader.get_shader_uniform_list():materials_match=materials_match and material.get_shader_parameter(uniform.name)==batch.material_override.get_shader_parameter(uniform.name)
        var original: PackedVector2Array=mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
        original_uvs=original_uvs and original==uv
    check("every source has exactly one batch slot",sources==stats.source_boxes)
    check("world-space box bounds are unchanged",bounds_match)
    check("hard face normals survive nonuniform instance scaling",normals_match)
    check("all supported shader uniforms textures and colors are identical",materials_match)
    check("unit cube UVs equal original BoxMesh UVs",original_uvs)
    check("source draws and shadows are suppressed while batches preserve masks",hidden_sources)
    check("animated aircraft remains outside static batch root",bg.plane.get_parent()==bg and bg.plane.find_children("*","MeshInstance3D",true,false).any(func(m:MeshInstance3D)->bool:return m.layers>0))
    check("character skin geometry remains unbatched",scene.fighters[0].model.find_children("*","MeshInstance3D",true,false).all(func(m:MeshInstance3D)->bool:return not m.has_meta("static_batch_id") and m.layers>0))
    check("existing colored corner MultiMeshes remain intact",bg.street.get_node("CornerStreetscape").batch_count==10)
    var source=preload("res://scenes/combat/street_fight.tscn").instantiate()
    source.preferences_path=""
    source.static_batches_enabled=false
    root.add_child(source)
    source.set_process(false)
    source.set_physics_process(false)
    source.audio.muted=true
    check("debug opt-out retains original drawing route",source.backdrop.static_batch_stats.is_empty() and not source.backdrop.street.has_node("StaticStreetBatches") and source.backdrop.street.get_node("BuildingMasses/BlueFront").layers>0)
    check("colliders are preserved independently of render batching",bg.street.find_children("*","CollisionShape3D",true,false).size()==source.backdrop.street.find_children("*","CollisionShape3D",true,false).size())
    var walk=preload("res://scenes/street_walk.tscn").instantiate()
    root.add_child(walk)
    check("walk mode retains interactive material comparison",not walk.get_node("Street").has_node("StaticStreetBatches") and walk.has_node("StyleSample"))
    walk.queue_free()
    source.queue_free()
    scene.queue_free()
    await process_frame
    await create_timer(.15).timeout
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/extended-polish/static-batches/verification.json",FileAccess.WRITE)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../docs/evidence/extended-polish/static-batches"))
    if not file:file=FileAccess.open("res://../docs/evidence/extended-polish/static-batches/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"stats":stats},"  "))
    print("STATIC_BATCH_CHECKS ",checks.size()-failed,"/",checks.size()," ",JSON.stringify(stats))
    quit(0 if failed==0 else 1)
