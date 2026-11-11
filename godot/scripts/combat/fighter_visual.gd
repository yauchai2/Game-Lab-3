extends Node3D
const Roster = preload("res://scripts/combat/fighter_roster.gd")
const Toon = preload("res://shaders/fighter_toon.gdshader")
const Outline = preload("res://shaders/fighter_outline.gdshader")
static var retired_materials:Array[ShaderMaterial]=[]
var model: Node3D
var skeleton: Skeleton3D
var materials: Array[ShaderMaterial] = []
var team := Color("66e5db")
var neon_enabled:=false
var character_index := 0
var model_scale := 2.1
var oversized_bones: Array[int]=[]
var elapsed := 0.0
var motions := preload("res://scripts/combat/combat_motions.gd").new()

func setup(color: Color, selection := 0, model_path_override:="") -> void:
    team = color
    character_index=clampi(selection,0,Roster.BLACK_SUIT_INDEX)
    var entry:Dictionary=Roster.entry(character_index)
    if is_instance_valid(model):
        # Compatibility may still process dependencies for an outgoing instance
        # on this frame, especially before its first draw. Keep its materials
        # alive until that draw completes rather than leave stale renderer RIDs.
        if DisplayServer.get_name()!="headless" and not materials.is_empty():
            retired_materials.append_array(materials)
            if not RenderingServer.frame_post_draw.is_connected(_release_retired_materials):
                RenderingServer.frame_post_draw.connect(_release_retired_materials,CONNECT_ONE_SHOT)
        remove_child(model)
        model.queue_free()
    skeleton=null
    materials.clear()
    oversized_bones.clear()
    motions=preload("res://scripts/combat/combat_motions.gd").new()
    elapsed=0.0
    model_scale=entry.scale
    model = (load(entry.path if model_path_override.is_empty() else model_path_override) as PackedScene).instantiate()
    model.scale = Vector3.ONE * model_scale
    add_child(model)
    for mesh in model.find_children("*", "MeshInstance3D", true, false):
        for surface in mesh.mesh.get_surface_count():
            var original: Material = mesh.get_active_material(surface)
            var mat := ShaderMaterial.new()
            mat.shader = preload("res://shaders/neon/neon_actor.gdshader") if neon_enabled else Toon
            mat.set_shader_parameter("tint", Color.WHITE.lerp(team, 0.50))
            if character_index==Roster.BLACK_SUIT_INDEX:mat.set_shader_parameter("tint",original.albedo_color if original is BaseMaterial3D else Color.WHITE)
            if original is BaseMaterial3D and original.albedo_texture:
                mat.set_shader_parameter("use_texture", true)
                mat.set_shader_parameter("base_texture", original.albedo_texture)
            if neon_enabled:
                mat.set_shader_parameter("tint",original.albedo_color if character_index==Roster.BLACK_SUIT_INDEX and original is BaseMaterial3D else Color.WHITE)
                mat.set_shader_parameter("neon_accent",preload("res://scripts/combat/neon/neon_style_profile.tres").accent(character_index))
            var outline := ShaderMaterial.new()
            outline.shader = Outline
            outline.set_shader_parameter("repaired_suit_neck",character_index==Roster.BLACK_SUIT_INDEX)
            if character_index!=Roster.BLACK_SUIT_INDEX or not str(mesh.name).begins_with("Repair") and str(mesh.name) not in ["NeckBridge","CleanShirtInsert","TieKnot","TieBlade"]:
                mat.next_pass = outline
            mesh.set_surface_override_material(surface, mat)
            materials.append(mat)
    var list := model.find_children("*", "Skeleton3D", true, false)
    if not list.is_empty():
        skeleton = list[0]
        motions.setup(skeleton,model)
        if character_index==3:_add_signal_baton()

static func _release_retired_materials() -> void:
    retired_materials.clear()

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
        var move: Dictionary = f.get("move_data",preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move])
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
        elif f.state=="attack" and f.move in ["heavy","special","overdrive","finisher"]:
            var move: Dictionary=f.get("move_data",preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move])
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
    model.scale=Vector3.ONE*model_scale*stretch
    for mat in materials:
        mat.set_shader_parameter("flash", 1.0 if f.flash > 0 and not reduced else 0.0)
    if skeleton:
        motions.present(f,delta,stopped)
        if neon_enabled:preload("res://scripts/combat/neon/neon_signature_motion.gd").apply(motions,f)
        if f.get("rush_visual",false) and f.state=="attack":
            var move: Dictionary=f.get("move_data",preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move])
            if f.frame>=move.startup-1 and f.frame<move.startup+move.active:
                var limbs:Array=["LeftHand","RightHand"] if f.move in ["meteor","overdrive"] else ["RightFoot" if f.move in ["air_kick","air_counter"] else ("LeftHand" if f.move in ["jab","air_jab"] else "RightHand")]
                if character_index==0:
                    limbs=["LeftFoot" if f.move in ["jab","special"] else "RightFoot"]
                for limb in limbs:
                    var index:=motions.bone_index(limb)
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
        segments.append({"a":a,"b":b,"width":pair[2]*model_scale/2.1})
    return segments

func set_neon_silhouette(enabled:bool) -> void:
    if not neon_enabled:return
    for mat in materials:
        mat.set_shader_parameter("neon_silhouette",1.0 if enabled else 0.0)
        if mat.next_pass:mat.next_pass.set_shader_parameter("silhouette_preview",enabled)

func _add_signal_baton() -> void:
    var hand:int=motions.bone_index("RightHand")
    if hand<0:return
    var mount:=BoneAttachment3D.new();mount.name="SignalBaton";mount.bone_name=skeleton.get_bone_name(hand);skeleton.add_child(mount)
    for spec in [[Vector3.ZERO,Vector3(.035,.25,.035),Color("10151a")],[Vector3(0,.125,0),Vector3(.05,.04,.05),Color("b8ff00")]]:
        var box:=BoxMesh.new();box.size=spec[1]
        var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/neon/neon_actor.gdshader") if neon_enabled else Toon
        mat.set_shader_parameter("tint",spec[2])
        if neon_enabled:mat.set_shader_parameter("neon_accent",Color("b8ff00"))
        var border:=ShaderMaterial.new();border.shader=Outline;mat.next_pass=border
        box.material=mat
        var node:=MeshInstance3D.new();node.name="SignalBatonMesh";node.mesh=box;node.position=spec[0];mount.add_child(node)
        materials.append(mat)
