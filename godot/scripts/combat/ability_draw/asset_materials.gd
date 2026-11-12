extends RefCounted
## Preserve original embedded albedo; wrapper materials never rewrite source GLBs.
static func style(root:Node,cabinet:=false) -> void:
    for instance in root.find_children("*","MeshInstance3D",true,false):
        var node:MeshInstance3D=instance
        for surface in node.mesh.get_surface_count():
            var original:=node.get_active_material(surface)
            if original is BaseMaterial3D and original.albedo_texture!=null:
                var material:=ShaderMaterial.new();material.shader=preload("res://shaders/ability_draw_asset.gdshader")
                material.set_shader_parameter("base_texture",original.albedo_texture)
                material.set_shader_parameter("cabinet_cutout",cabinet)
                var outline:=ShaderMaterial.new();outline.shader=preload("res://shaders/ability_draw_asset_outline.gdshader")
                outline.set_shader_parameter("cabinet_cutout",cabinet)
                material.next_pass=outline;node.set_surface_override_material(surface,material)
