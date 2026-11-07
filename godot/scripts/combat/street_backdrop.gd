extends Node3D
## Street, actors, shadows and camera share one perspective world.
const Toon = preload("res://shaders/sample_toon.gdshader")
var street: Node3D
var plane: Node3D
var environment: Environment
var elapsed := 0.0
var frozen := false
const FLIGHT_SECONDS := 12.0
var cycle := 24.0
var anchor := Vector3(-3,18,-36)
var retained_materials: Array[Material] = []

func _ready() -> void:
    street = preload("res://scenes/street_whitebox.tscn").instantiate()
    street.name = "Street"
    add_child(street)
    street.set_process_unhandled_key_input(false)
    street.get_node("Overlay").hide()
    for camera in street.get_node("ReferenceCameras").get_children(): camera.current = false
    street.scale.x = 2.4
    var dressing := Node3D.new()
    dressing.set_script(preload("res://scripts/street_dressing.gd"))
    street.add_child(dressing)
    strip_scene_text(street)
    _style_surfaces(street)
    var world: WorldEnvironment = street.get_node("WorldEnvironment")
    world.environment = world.environment.duplicate(true)
    environment = world.environment
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ShaderMaterial.new()
    sky_material.shader = preload("res://shaders/stylized_sky.gdshader")
    sky_material.set_shader_parameter("blue",Color("075bbd"))
    sky.sky_material = sky_material
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("9eb8db")
    environment.ambient_light_energy = 0.7
    var sun: DirectionalLight3D = street.get_node("Sun")
    sun.light_color = Color("ffe8c2")
    sun.light_energy = 0.85
    sun.shadow_blur = 0.0
    plane = street.get_node("AircraftProxy")
    var detail_builder := preload("res://scripts/aircraft_flyby.gd").new()
    detail_builder.plane = plane
    detail_builder._add_detail()
    detail_builder.free()
    _style_surfaces(plane)
    plane.reparent(self)
    plane.scale = Vector3.ONE * 0.75
    plane.position = anchor
    plane.rotation_degrees.y = -145

static func strip_scene_text(root: Node) -> void:
    for label in root.find_children("*","Label3D",true,false):
        label.hide()
    for node in root.find_children("*","MeshInstance3D",true,false):
        if node.name.begins_with("SignGlyphProxy") or "Graffiti" in str(node.name):
            node.hide()

func _style_surfaces(root: Node) -> void:
    for mesh in root.find_children("*","MeshInstance3D",true,false):
        var sources: Array[Material] = []
        for surface in mesh.mesh.get_surface_count(): sources.append(mesh.get_active_material(surface))
        mesh.material_override = null
        for surface in mesh.mesh.get_surface_count():
            var source: Material = sources[surface]
            if not source is BaseMaterial3D: continue
            var material := ShaderMaterial.new()
            material.shader = Toon
            material.set_shader_parameter("base_color",source.albedo_color)
            material.set_shader_parameter("bands",2)
            material.set_shader_parameter("shadow_tint",Vector3(0.38,0.55,0.76))
            if source.albedo_texture:
                material.set_shader_parameter("use_texture",true)
                material.set_shader_parameter("base_texture",source.albedo_texture)
            mesh.set_surface_override_material(surface,material)
            retained_materials.append(material)

func present(delta: float, paused: bool) -> void:
    if frozen or paused: return
    elapsed = fmod(elapsed+delta,cycle)
    var phase := fmod(elapsed+FLIGHT_SECONDS*0.5,cycle)
    plane.visible = phase<=FLIGHT_SECONDS
    plane.position = anchor + Vector3(-0.55,0,-0.84)*((phase/FLIGHT_SECONDS-0.5)*150.0)

func freeze_for_capture() -> void:
    frozen = true
    plane.visible = true
    plane.position = anchor
