extends RefCounted
## Derived procedural accessories; original character GLB remains untouched.
static func decorate(visual:Node,role:String) -> void:
    if role=="grunt":return
    var side:String="LeftForeArm" if role=="guard" else "RightArm"
    var attachment:=BoneAttachment3D.new();attachment.name="StoryRole"
    visual.skeleton.add_child(attachment)
    attachment.bone_name=visual.skeleton.get_bone_name(visual.motions.bone_index(side))
    var mesh:=MeshInstance3D.new();var shape:=BoxMesh.new()
    shape.size=Vector3(.40,.52,.10) if role=="guard" else Vector3(.18,.20,.22)
    mesh.mesh=shape;mesh.position=Vector3(0,-.12,.06) if role=="guard" else Vector3.ZERO
    var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color=Color("ffd84c") if role=="guard" else Color("00d7d7")
    mesh.material_override=mat;attachment.add_child(mesh)

static func present(visual:Node,f:Dictionary) -> void:
    var node:Node=visual.model.find_child("StoryRole",true,false)
    if node!=null:node.visible=f.health>0
