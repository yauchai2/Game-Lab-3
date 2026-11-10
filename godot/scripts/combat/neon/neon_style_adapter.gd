extends RefCounted
const ENV=preload("res://shaders/neon/neon_environment.gdshader")
## Called before static baking; same source colours/transforms yield same groups.
static func configure_surface(material:ShaderMaterial,mesh:GeometryInstance3D) -> void:
    material.set_shader_parameter("palette_strength",1.0)
    material.set_shader_parameter("bands",3)
    material.set_shader_parameter("shadow_tint",Vector3(.40,.27,.51))
    var label:=str(mesh.name).to_lower()
    var landmark:bool=("bluefront" in label or "orangefront" in label) and not ("window" in label or "opening" in label)
    material.set_shader_parameter("landmark",landmark)
    var role:=0
    if "road" in label or "alley" in label or "groundbase" in label:role=1
    if "window" in label or "opening" in label:role=2
    material.set_shader_parameter("value_role",role)
    material.set_shader_parameter("accent",Vector3(0.0,.84,.91) if "blue" in label else Vector3(1.0,.04,.48))
static func style_extras(root:Node3D) -> void:
    # Existing detail MultiMeshes also need the palette; do not unbatch or tint GLB actors.
    for instance in root.find_children("*","GeometryInstance3D",true,false):
        if instance is MultiMeshInstance3D:
            var source:Material=instance.material_override
            var derived:=ShaderMaterial.new()
            if source is BaseMaterial3D:
                derived.shader=ENV
                derived.set_shader_parameter("base_color",source.albedo_color)
                if source.albedo_texture:
                    derived.set_shader_parameter("use_texture",true)
                    derived.set_shader_parameter("base_texture",source.albedo_texture)
            elif source is ShaderMaterial and source.shader==preload("res://shaders/sample_toon.gdshader"):
                derived=source.duplicate();derived.shader=ENV
            else:continue
            configure_surface(derived,instance)
            instance.material_override=derived
static func style_living(root:Node3D) -> void:
    for mesh in root.find_children("*","MeshInstance3D",true,false):
        if mesh.find_parent("Skeleton3D")!=null:continue
        for surface in mesh.mesh.get_surface_count():
            var source:Material=mesh.get_active_material(surface)
            if source is ShaderMaterial and source.shader==preload("res://shaders/sample_toon.gdshader"):
                var derived:ShaderMaterial=source.duplicate()
                derived.shader=ENV
                configure_surface(derived,mesh)
                mesh.set_surface_override_material(surface,derived)
