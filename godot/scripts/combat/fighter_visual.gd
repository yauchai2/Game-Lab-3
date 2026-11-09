extends Node3D
const Model = preload("res://assets/CHAR_PLAYER_A01.glb")
const Toon = preload("res://shaders/fighter_toon.gdshader")
const Outline = preload("res://shaders/fighter_outline.gdshader")
var model: Node3D
var skeleton: Skeleton3D
var materials: Array[ShaderMaterial] = []
var team := Color("66e5db")
var oversized_bones: Array[int]=[]
var elapsed := 0.0
var motions := preload("res://scripts/combat/combat_motions.gd").new()

func setup(color: Color) -> void:
    team = color
    model = Model.instantiate()
    model.scale = Vector3.ONE * 2.1
    add_child(model)
    for mesh in model.find_children("*", "MeshInstance3D", true, false):
        for surface in mesh.mesh.get_surface_count():
            var original: Material = mesh.get_active_material(surface)
            var mat := ShaderMaterial.new()
            mat.shader = Toon
            mat.set_shader_parameter("tint", Color.WHITE.lerp(team, 0.50))
            if original is BaseMaterial3D and original.albedo_texture:
                mat.set_shader_parameter("use_texture", true)
                mat.set_shader_parameter("base_texture", original.albedo_texture)
            var outline := ShaderMaterial.new()
            outline.shader = Outline
            mat.next_pass = outline
            mesh.set_surface_override_material(surface, mat)
            materials.append(mat)
    var list := model.find_children("*", "Skeleton3D", true, false)
    if not list.is_empty():
        skeleton = list[0]
        motions.setup(skeleton,model)

func present(f: Dictionary, delta: float, stopped: bool, reduced: bool, opponent_x := INF) -> void:
    for bone in oversized_bones:skeleton.set_bone_pose_scale(bone,Vector3.ONE)
    oversized_bones.clear()
    elapsed += delta
    position = Vector3(f.x, f.y, 3.0)
    # Imported +Z forward maps to gameplay +X at +90 degrees.
    rotation.y = PI * 0.5 if f.face > 0 else -PI * 0.5
    var shake := 0.0 if reduced or not stopped else 0.025
    var lunge := 0.0
    if f.state=="attack":
        var move: Dictionary = preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move]
        var amount := clampf(float(f.frame)/move.startup,0,1)
        if f.frame>move.startup+move.active:
            amount = 1.0-clampf(float(f.frame-move.startup-move.active)/move.recovery,0,1)
        lunge = amount * (0.60 if f.move in ["heavy","finisher"] else 0.45)
        if is_finite(opponent_x): lunge = minf(lunge,maxf(0.0,absf(opponent_x-f.x)-0.8))
    model.position = Vector3(sin(elapsed * 137.0) * shake,0,lunge)
    var exchange_choice: String=f.get("exchange_choice","")
    model.rotation.x={"press":-.12,"turn":.10,"slip":.22}.get(exchange_choice,0.0)
    if exchange_choice!="":
        model.position.z += {"press":.12,"turn":-.06,"slip":-.18}.get(exchange_choice,0.0)
    # Authored visual deformation, kept separate from gameplay transforms.
    var stretch:=Vector3.ONE
    if not reduced:
        if stopped:stretch=Vector3(1.06,.94,1.06)
        elif f.state=="dash":stretch=Vector3(.91,.92,1.20)
        elif f.state=="attack" and f.move in ["heavy","special","finisher"]:
            var move: Dictionary=preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move]
            var anticip: float=clampf(float(f.frame)/move.startup,0,1)
            stretch=Vector3(1.0+anticip*.05,1.0-anticip*.07,1.0+anticip*.11)
    var rally_phase: String=f.get("rally_phase","")
    if rally_phase!="":
        var amount: float=clampf(f.get("rally_amount",0.0),0,1)
        var attacking: bool=f.get("rally_owner",false)
        model.rotation.x=(-.12-amount*.12 if attacking else .12) if rally_phase=="compress" else 0.0
        if rally_phase=="compress" and not reduced:stretch=Vector3(1.05,.93,1.08)
    if f.get("air_enabled",false):stretch*=motions.air_poses.stretch(f,reduced)
    model.rotation.y=0.0
    if f.get("air_enabled",false) and not reduced and f.state=="idle" and f.air.phase=="rise" and f.air.air_ticks<=8:
        model.rotation.y=TAU*float(f.air.air_ticks)/8.0
    if f.get("ko_theatre",-1.0)>=0:
        var pose_time:float=f.ko_theatre
        model.rotation.x+=(-.35 if f.health<=0 else .12)*sin(pose_time*PI/.64)
        if f.health<=0:model.rotation.z=sin(pose_time*PI/.64)*.55
        stretch*=Vector3(1.18,.92,1.18)
    else:model.rotation.z=0.0
    model.scale=Vector3.ONE*2.1*stretch
    for mat in materials:
        mat.set_shader_parameter("flash", 1.0 if f.flash > 0 and not reduced else 0.0)
    if skeleton:
        motions.present(f,delta,stopped)
        if f.get("rush_visual",false) and f.state=="attack":
            var move: Dictionary=preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move]
            if f.frame>=move.startup-1 and f.frame<move.startup+move.active:
                var limbs:Array=["LeftHand","RightHand"] if f.move=="meteor" else ["RightFoot" if f.move in ["air_kick","air_counter"] else ("LeftHand" if f.move in ["jab","air_jab"] else "RightHand")]
                for limb in limbs:
                    var index:=skeleton.find_bone("mixamorig_"+limb)
                    if index>=0:
                        skeleton.set_bone_pose_scale(index,Vector3.ONE*2.1)
                        oversized_bones.append(index)
                model.scale*=Vector3(1.05,.94,1.20)

func capture_echo() -> Array:
    var segments: Array=[]
    if not is_instance_valid(skeleton):return segments
    var pairs := [["Hips","Spine2",.19],["Spine2","Head",.15],
        ["LeftArm","LeftForeArm",.075],["LeftForeArm","LeftHand",.06],
        ["RightArm","RightForeArm",.075],["RightForeArm","RightHand",.06],
        ["LeftUpLeg","LeftLeg",.11],["LeftLeg","LeftFoot",.09],
        ["RightUpLeg","RightLeg",.11],["RightLeg","RightFoot",.09]]
    for pair in pairs:
        var indices:=[]
        for label in [pair[0],pair[1]]:
            var found:=-1
            for i in skeleton.get_bone_count():
                if skeleton.get_bone_name(i).trim_prefix("mixamorig_")==label or skeleton.get_bone_name(i).get_slice(":",1)==label:
                    found=i
                    break
            indices.append(found)
        if indices[0]<0 or indices[1]<0:continue
        var a: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(indices[0]).origin
        var b: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(indices[1]).origin
        segments.append({"a":a,"b":b,"width":pair[2]})
    return segments
