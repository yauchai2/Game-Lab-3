extends RefCounted
const StageView=preload("res://scripts/combat/city/campaign_stage_view.gd")
static func enemy(visual:Node,pose:Dictionary) -> void:
    if pose.get("story_role","")!="boss":return
    visual.model.hide()
    var robot:Node3D=visual.get_node_or_null("CampaignBoss")
    if robot==null:
        robot=load("res://assets/campaign/generated/%s.glb"%("gantry_warden" if pose.boss.kind=="gantry" else "signal_leviathan")).instantiate()
        robot.name="CampaignBoss";visual.add_child(robot);StageView.paint(robot)
        var label:=Label3D.new();label.name="Cue";label.font_size=48;label.pixel_size=.012;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position=Vector3(0,5.8,0);robot.add_child(label)
    var b:Dictionary=pose.boss;var charging:bool=b.step=="windup"
    for name in ["Arm_L","Arm_R"]:
        var arm:=robot.find_child(name,true,false)
        if arm:arm.rotation.x=(-.9 if charging else .12)*minf(1,float(b.age%60)/20.0) if pose.health>0 else .4
    var core:=robot.find_child("CorePivot",true,false)
    if core:core.scale=Vector3.ONE*(1.12 if int(b.open)>0 else 1.0)
    robot.get_node("Cue").text=b.cue if pose.health>0 else "SIGNAL RESTORED"
    robot.get_node("Cue").modulate=Color("00e5df") if int(b.open)>0 else Color("ffe15b")
    robot.rotation.y=.42
    robot.rotation.z=0.0 if pose.health>0 else -.45;robot.position.y=0.0
    if pose.health<=0:
        var low:=INF
        for mesh in robot.find_children("*","MeshInstance3D",true,false):
            var bounds:AABB=mesh.get_aabb()
            for corner in 8:low=minf(low,(mesh.global_transform*bounds.get_endpoint(corner)).y)
        if is_finite(low):robot.position.y=.02-low
static func equipment(visual:Node,items:Array) -> void:
    if visual.skeleton==null:return
    var signature:String=str(visual.skeleton.get_instance_id())+str(items.map(func(i:Dictionary)->String:return "%d:%d"%[int(i.get("id",0)),int(i.get("tier",0))]))
    if visual.get_meta("city_loadout","")==signature:return
    visual.set_meta("city_loadout",signature)
    for child in visual.skeleton.get_children():
        if str(child.name).begins_with("CityGear"):visual.skeleton.remove_child(child);child.queue_free()
    for slot in 3:
        if items[slot].is_empty():continue
        var attachment:=BoneAttachment3D.new();attachment.name="CityGear%d"%slot
        visual.skeleton.add_child(attachment);attachment.bone_name=visual.skeleton.get_bone_name(visual.motions.bone_index(["LeftHand","LeftFoot","Hips"][slot]))
        var mesh:=MeshInstance3D.new();var shape:=BoxMesh.new();shape.size=[Vector3(.14,.12,.16),Vector3(.15,.07,.25),Vector3(.16,.18,.12)][slot]
        mesh.mesh=shape;mesh.position=Vector3(.18,0,.03) if slot==2 else Vector3.ZERO
        var mat:=StandardMaterial3D.new();mat.albedo_color=[Color("ded9e5"),Color("00cbd9"),Color("d3eb30"),Color("ff008c")][int(items[slot].tier)];mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
        mesh.material_override=mat;attachment.add_child(mesh)
static func clear_equipment(visual:Node) -> void:
    visual.remove_meta("city_loadout") if visual.has_meta("city_loadout") else null
    if visual.skeleton!=null:
        for child in visual.skeleton.get_children():
            if str(child.name).begins_with("CityGear"):visual.skeleton.remove_child(child);child.queue_free()
