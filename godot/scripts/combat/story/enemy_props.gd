extends RefCounted
## Derived procedural accessories; original character GLB remains untouched.
static func decorate(visual:Node,role:String) -> void:
    if role in ["grunt","boss"]:return
    var side:String="LeftForeArm" if role=="guard" else "RightArm"
    var attachment:=BoneAttachment3D.new();attachment.name="StoryRole"
    visual.skeleton.add_child(attachment)
    attachment.bone_name=visual.skeleton.get_bone_name(visual.motions.bone_index(side))
    var mesh:=MeshInstance3D.new();var shape:=BoxMesh.new()
    shape.size={"guard":Vector3(.40,.52,.10),"heavy":Vector3(.7,.28,.55),"jammer":Vector3(.22,.55,.22),"captain":Vector3(.2,.7,.35)}.get(role,Vector3(.18,.20,.22))
    mesh.mesh=shape;mesh.position=Vector3(0,-.12,.06) if role=="guard" else Vector3.ZERO
    var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_color={"guard":Color("ffd84c"),"heavy":Color("e87d39"),"jammer":Color("dd27ff"),"captain":Color("d8ff39")}.get(role,Color("00d7d7"))
    mesh.material_override=mat;attachment.add_child(mesh)

static func present(visual:Node,f:Dictionary) -> void:
    preload("res://scripts/combat/city/campaign_visuals.gd").enemy(visual,f)
    var node:Node=visual.model.find_child("StoryRole",true,false)
    if node!=null:node.visible=f.health>0
    var cue:=visual.get_node_or_null("ArrivalCue")
    if cue==null:
        cue=Label3D.new();cue.name="ArrivalCue";cue.text="INCOMING";cue.font_size=36;cue.pixel_size=.012;cue.billboard=BaseMaterial3D.BILLBOARD_ENABLED;cue.position=Vector3(0,2.65,0);visual.add_child(cue)
    cue.visible=f.get("new_arrival",false) and int(f.get("arrival",0))>0 and f.invuln>0 and f.health>0
