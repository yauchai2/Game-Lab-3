extends RefCounted
## Bake only undeformed BoxMesh surfaces using the supported static toon shaders.
## Source nodes/collisions remain as provenance; zero render layers suppress old draws.
static func bake(root: Node3D, supported: Array) -> Dictionary:
    var groups: Dictionary={}
    var sources:=0
    var unit:=BoxMesh.new()
    unit.size=Vector3.ONE
    for mesh in root.find_children("*","MeshInstance3D",true,false):
        if not mesh.mesh is BoxMesh or not mesh.is_visible_in_tree() or mesh.layers==0:continue
        if mesh.mesh.flip_faces or mesh.global_basis.determinant()<=0:continue
        var material: Material=mesh.get_active_material(0)
        if not material is ShaderMaterial or material.shader not in supported or material.next_pass!=null:continue
        var signature: Array=[material.shader.get_instance_id(),material.render_priority,mesh.layers,mesh.cast_shadow]
        for uniform in material.shader.get_shader_uniform_list():
            var value: Variant=material.get_shader_parameter(uniform.name)
            if value is Object:value=value.get_instance_id() if is_instance_valid(value) else 0
            signature.append(value)
        var key:=var_to_bytes(signature).hex_encode()
        if not groups.has(key):groups[key]={"id":groups.size(),"material":material,"layers":mesh.layers,"shadow":mesh.cast_shadow,"transforms":[]}
        var transform: Transform3D=root.global_transform.affine_inverse()*mesh.global_transform
        transform.basis=transform.basis.scaled_local(mesh.mesh.size)
        mesh.set_meta("static_batch_id",groups[key].id)
        mesh.set_meta("static_batch_index",groups[key].transforms.size())
        groups[key].transforms.append(transform)
        mesh.set_meta("static_batch_source_layers",mesh.layers)
        mesh.set_meta("static_batch_source_shadow",mesh.cast_shadow)
        mesh.layers=0
        mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        sources+=1
    var container:=Node3D.new()
    container.name="StaticStreetBatches"
    root.add_child(container)
    for key in groups:
        var group: Dictionary=groups[key]
        var multimesh:=MultiMesh.new()
        multimesh.transform_format=MultiMesh.TRANSFORM_3D
        multimesh.mesh=unit
        multimesh.instance_count=group.transforms.size()
        for i in group.transforms.size():multimesh.set_instance_transform(i,group.transforms[i])
        var instance:=MultiMeshInstance3D.new()
        instance.name="Batch_%02d"%group.id
        instance.multimesh=multimesh
        instance.material_override=group.material
        instance.layers=group.layers
        instance.cast_shadow=group.shadow
        container.add_child(instance)
    return {"source_boxes":sources,"batches":groups.size(),"primitive":"unit BoxMesh","source_nodes_preserved":true,"walk_material_comparison_unmodified":true}
