extends Node3D
const Model = preload("res://assets/CHAR_PLAYER_A01.glb")
const Toon = preload("res://shaders/fighter_toon.gdshader")
const Outline = preload("res://shaders/fighter_outline.gdshader")
var model: Node3D
var skeleton: Skeleton3D
var bones: Dictionary = {}
var base: Dictionary = {}
var axes: Dictionary = {}
var materials: Array[ShaderMaterial] = []
var team := Color("66e5db")
var elapsed := 0.0

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
            mat.set_shader_parameter("tint", Color.WHITE.lerp(team, 0.32))
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
        for part in ["LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "LeftArm", "RightArm", "LeftForeArm", "RightForeArm", "Spine", "Spine1"]:
            var index := skeleton.find_bone("mixamorig_" + part)
            if index >= 0:
                bones[part] = index
                base[part] = skeleton.get_bone_pose_rotation(index)
                axes[part] = skeleton.get_bone_global_rest(index).basis.inverse()

func present(f: Dictionary, delta: float, stopped: bool, reduced: bool) -> void:
    elapsed += delta if not stopped else 0.0
    position = Vector3(f.x, f.y, 0)
    rotation.y = -PI * 0.5 if f.face > 0 else PI * 0.5
    var shake := 0.0 if reduced or not stopped else 0.025
    model.position = Vector3(sin(elapsed * 137.0 + f.frame) * shake, 0, 0)
    for mat in materials:
        mat.set_shader_parameter("flash", 1.0 if f.flash > 0 and not reduced else 0.0)
    if not skeleton:
        return
    for part in bones:
        skeleton.set_bone_pose_rotation(bones[part], base[part])
    # Provisional procedural poses layered on the imported skeleton, sampled at 15 Hz.
    var stepped := floorf(elapsed * 15.0) / 15.0
    var stride: float = sin(stepped * 14.0) * minf(absf(f.vx) / 6.0, 1.0)
    _pose("LeftUpLeg", Vector3.RIGHT, stride * 0.45)
    _pose("RightUpLeg", Vector3.RIGHT, -stride * 0.45)
    _pose("LeftLeg", Vector3.RIGHT, maxf(0, -stride) * 0.5)
    _pose("RightLeg", Vector3.RIGHT, maxf(0, stride) * 0.5)
    _pose("LeftArm", Vector3.FORWARD, -0.85)
    _pose("RightArm", Vector3.FORWARD, 0.85)
    _pose("LeftForeArm", Vector3.RIGHT, -0.8)
    _pose("RightForeArm", Vector3.RIGHT, -0.8)
    if f.guarding:
        _pose("LeftArm", Vector3.RIGHT, -0.8)
        _pose("RightArm", Vector3.RIGHT, -0.8)
        _pose("Spine", Vector3.RIGHT, 0.17)
    if f.y > 0.05:
        _pose("LeftUpLeg", Vector3.RIGHT, -0.5)
        _pose("RightLeg", Vector3.RIGHT, 0.8)
    if f.state == "attack":
        var move: Dictionary = preload("res://scripts/combat/fight_simulation.gd").MOVES[f.move]
        var active: bool = f.frame >= move.startup
        _pose("Spine", Vector3.UP, -0.45 if active else 0.35)
        _pose("RightArm", Vector3.RIGHT, -1.4 if active else 0.4)
        _pose("RightForeArm", Vector3.RIGHT, 0.0 if active else -1.1)
        if f.move in ["finisher", "heavy"]:
            _pose("RightUpLeg", Vector3.RIGHT, -1.35 if active else -0.25)
            _pose("RightLeg", Vector3.RIGHT, 0.08 if active else 1.0)
        if f.move == "launcher":
            _pose("RightArm", Vector3.RIGHT, -2.7 if active else 0.4)
        if f.move == "special":
            _pose("LeftArm", Vector3.RIGHT, -1.5 if active else 0.2)
    elif f.state == "stun":
        _pose("Spine", Vector3.RIGHT, -0.45)
        _pose("LeftArm", Vector3.RIGHT, 0.6)
        _pose("RightArm", Vector3.RIGHT, 0.6)
    elif f.state == "dash":
        _pose("Spine", Vector3.RIGHT, 0.6)

func _pose(part: String, world_axis: Vector3, angle: float) -> void:
    if bones.has(part):
        var axis: Vector3 = axes[part] * world_axis
        skeleton.set_bone_pose_rotation(bones[part], skeleton.get_bone_pose_rotation(bones[part]) * Quaternion(axis.normalized(), angle))
