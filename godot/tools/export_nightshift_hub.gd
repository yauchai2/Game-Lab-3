extends SceneTree
## Rebuilds the derived GLB for Blender/Tripo-independent editing. Does not edit sources.
var textures:Dictionary={}
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var scene:=preload("res://scripts/combat/city/nightshift/reference_workshop.gd").new();root.add_child(scene);scene.build()
    scene.sample(0.0,true)
    for transient in scene.beams+scene.pools+scene.smoke+scene.arcs+[scene.aperture]:transient.free()
    for node:MeshInstance3D in scene.find_children("*","MeshInstance3D",true,false):
        if node.mesh is PrimitiveMesh:node.mesh=node.mesh.duplicate()
        for surface in node.mesh.get_surface_count():
            var current:Material=node.get_active_material(surface)
            if not current is ShaderMaterial:continue
            var standard:=StandardMaterial3D.new();standard.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;standard.cull_mode=BaseMaterial3D.CULL_DISABLED
            if current==scene.projection_material:
                standard.albedo_texture=current.get_shader_parameter("plate")
                var source_mesh:Mesh=node.mesh;var replacement:=ArrayMesh.new()
                for slot in source_mesh.get_surface_count():
                    var arrays:Array=source_mesh.surface_get_arrays(slot)
                    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var uv:=PackedVector2Array()
                    var span:Vector2=current.get_shader_parameter("ref_span")
                    for vertex in vertices:
                        var point:Vector3=node.global_transform*vertex-Vector3(0,1,0)
                        uv.append(Vector2(point.dot(scene.camera.global_basis.x)/span.x+.5,.5-point.dot(scene.camera.global_basis.y)/span.y))
                    arrays[Mesh.ARRAY_TEX_UV]=uv;replacement.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
                node.mesh=replacement
            elif current.shader==scene.material_shader:standard.albedo_color=current.get_shader_parameter("base_color")
            else:
                if current.shader==preload("res://scripts/combat/city/nightshift/light.gdshader"):node.hide();continue
                var source:Texture2D=current.get_shader_parameter("base_texture")
                if source!=null:standard.albedo_texture=duotone(source)
            node.set_surface_override_material(surface,standard)
    var state:=GLTFState.new();var doc:=GLTFDocument.new()
    var result:Error=doc.append_from_scene(scene,state)
    if result==OK:result=doc.write_to_filesystem(state,"res://assets/city/nightshift_workshop.glb")
    print("NIGHTSHIFT_GLB_EXPORT ",result)
    scene.queue_free();await process_frame;quit(0 if result==OK else 1)
func duotone(source:Texture2D) -> Texture2D:
    if textures.has(source):return textures[source]
    var image:Image=source.get_image()
    if image.is_compressed():image.decompress()
    image.convert(Image.FORMAT_RGBA8)
    for y in image.get_height():
        for x in image.get_width():
            var c:Color=image.get_pixel(x,y)
            var color:=Color("eaeaf2") if c.r*.299+c.g*.587+c.b*.114>=.31 else Color("0a0a0f")
            if c.g>=c.r*1.7 and c.g>=.48 and c.b>=.45:color=Color("00d2ef")
            image.set_pixel(x,y,color)
    var texture:=ImageTexture.create_from_image(image);textures[source]=texture;return texture
