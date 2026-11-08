extends Node3D
const Model = preload("res://assets/CHAR_PLAYER_A01.glb")
const Toon = preload("res://shaders/fighter_toon.gdshader")
const Outline = preload("res://shaders/fighter_outline.gdshader")
var model: Node3D
var skeleton: Skeleton3D
var materials: Array[ShaderMaterial] = []
var team := Color("66e5db")
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
        motions.setup(skeleton,model)

func present(f: Dictionary, delta: float, stopped: bool, reduced: bool, opponent_x := INF) -> void:
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
    for mat in materials:
        mat.set_shader_parameter("flash", 1.0 if f.flash > 0 and not reduced else 0.0)
    if skeleton:
        motions.present(f,delta,stopped)
