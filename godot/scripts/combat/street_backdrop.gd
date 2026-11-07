extends Node3D
## Street, actors, shadows and camera share one perspective world.
const Toon = preload("res://shaders/sample_toon.gdshader")
var street: Node3D
var plane: Node3D
var environment: Environment
var elapsed := 0.0
var frozen := false
var flight_direction := Vector3.FORWARD
var vehicle_nodes: Array[Node3D] = []
var environment_textures: Node
var source_detail_count := 0
var aircraft_shader: Shader
var aircraft_two_sided_shader: Shader
var two_sided_shader: Shader
const FLIGHT_SECONDS := 12.0
var cycle := 24.0
var anchor := Vector3(-3,31,-64)
var retained_materials: Array[Material] = []

func _ready() -> void:
    street = preload("res://scenes/street_whitebox.tscn").instantiate()
    street.name = "Street"
    add_child(street)
    street.set_process_unhandled_key_input(false)
    street.get_node("Overlay").hide()
    for camera in street.get_node("ReferenceCameras").get_children(): camera.current = false
    street.scale = Vector3.ONE
    _restore_vehicles()
    environment_textures = Node.new()
    environment_textures.name = "EnvironmentTextures"
    environment_textures.set_script(preload("res://scripts/environment_textures.gd"))
    add_child(environment_textures)
    var dressing := Node3D.new()
    dressing.set_script(preload("res://scripts/street_dressing.gd"))
    street.add_child(dressing)
    _restore_style_details()
    strip_scene_text(street)
    two_sided_shader = Shader.new()
    two_sided_shader.code = Toon.code.replace("specular_disabled;","specular_disabled, cull_disabled;")
    aircraft_shader = Shader.new()
    aircraft_shader.code = Toon.code.replace("specular_disabled;","specular_disabled, shadows_disabled;")
    aircraft_two_sided_shader = Shader.new()
    aircraft_two_sided_shader.code = Toon.code.replace("specular_disabled;","specular_disabled, shadows_disabled, cull_disabled;")
    _style_surfaces(street)
    _extend_crossing()
    var world: WorldEnvironment = street.get_node("WorldEnvironment")
    world.environment = world.environment.duplicate(true)
    environment = world.environment
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := PanoramaSkyMaterial.new()
    sky_material.panorama = preload("res://assets/SKY_BLUE_A01.png")
    sky.sky_material = sky_material
    environment.sky = sky
    environment.sky_rotation = Vector3(0,deg_to_rad(90),0)
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
    flight_direction = -plane.basis.z.normalized()

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
            var is_aircraft: bool = mesh.name.begins_with("Aircraft_") or mesh.find_parent("AircraftProxy") != null
            if is_aircraft:
                material.shader = aircraft_two_sided_shader if source.cull_mode==BaseMaterial3D.CULL_DISABLED else aircraft_shader
            else:
                material.shader = two_sided_shader if source.cull_mode==BaseMaterial3D.CULL_DISABLED else Toon
            material.set_shader_parameter("base_color",source.albedo_color)
            material.set_shader_parameter("bands",2)
            material.set_shader_parameter("shadow_tint",Vector3(0.38,0.55,0.76))
            material.set_shader_parameter("use_world_uv",source.uv1_triplanar and source.uv1_world_triplanar)
            material.set_shader_parameter("texture_scale",source.uv1_scale)
            material.set_shader_parameter("texture_offset",source.uv1_offset)
            if source.albedo_texture:
                material.set_shader_parameter("use_texture",true)
                material.set_shader_parameter("base_texture",source.albedo_texture)
                material.set_shader_parameter("world_texture",source.albedo_texture)
            mesh.set_surface_override_material(surface,material)
            retained_materials.append(material)

func present(delta: float, paused: bool) -> void:
    if frozen or paused: return
    elapsed = fmod(elapsed+delta,cycle)
    var phase := fmod(elapsed+FLIGHT_SECONDS*0.5,cycle)
    plane.visible = phase<=FLIGHT_SECONDS
    plane.position = anchor + flight_direction*((phase/FLIGHT_SECONDS-0.5)*150.0)

func freeze_for_capture() -> void:
    frozen = true
    plane.visible = true
    plane.position = anchor

func _restore_vehicles() -> void:
    for spec in [[preload("res://scenes/VEH_CAR_A01.tscn"),Vector3(-2.9,0,-17),"ParkedCar"],[preload("res://scenes/VEH_TRUCK_A01.tscn"),Vector3(2.6,0,-36),"ParkedTruck"]]:
        var vehicle: Node3D = spec[0].instantiate()
        vehicle.name = spec[2]
        vehicle.position = spec[1]
        street.add_child(vehicle)
        vehicle_nodes.append(vehicle)

func _extend_crossing() -> void:
    # Widen only the entrance crossing paint. Buildings, windows and vehicles stay at source scale.
    var stripe := BoxMesh.new()
    stripe.size = Vector3(0.53,0.016,3.0)
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = stripe
    batch.instance_count = 10
    var index := 0
    for side in [-1,1]:
        for offset in 5:
            batch.set_instance_transform(index,Transform3D(Basis.IDENTITY,Vector3(side*(4.5+offset),0.012,3.0)))
            index += 1
    var paint := MultiMeshInstance3D.new()
    paint.name = "CrossingExtension"
    paint.multimesh = batch
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("e9d7a8")
    material.roughness = 1.0
    paint.material_override = material
    paint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(paint)

func _restore_style_details() -> void:
    # Reuse the source scene's builder without starting its walk-only controller.
    var builder := preload("res://scripts/style_sample.gd").new()
    builder.details = Node3D.new()
    builder.details.name = "SourceStyleDetails"
    street.add_child(builder.details)
    builder._build_details()
    builder._flush_detail_groups()
    source_detail_count = builder.detail_instance_count
    builder.free()
    for title in ["VerticalSignFrame","VerticalSignFace"]:
        var panel: MeshInstance3D = street.get_node("Landmarks/"+title)
        panel.position.x += 0.8
        var source: BaseMaterial3D = panel.get_active_material(0)
        var replacement: BaseMaterial3D = source.duplicate(true)
        replacement.albedo_color = Color("dbab3c") if title=="VerticalSignFrame" else Color("59402d")
        panel.material_override = replacement
