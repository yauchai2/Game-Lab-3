extends Node
## Independent perspective world: preserve the reference's upward street view
## while combat keeps its own readable horizontal orthographic plane.
const Toon = preload("res://shaders/sample_toon.gdshader")
var viewport: SubViewport
var street: Node3D
var camera: Camera3D
var plane: Node3D
var canvas: CanvasLayer
var elapsed := 0.0
var frozen := false
var was_paused := false
const FLIGHT_SECONDS := 12.0
var cycle := 24.0
var anchor := Vector3(-2, 31, -38)
var retained_materials: Array[Material] = []

func _ready() -> void:
    viewport = SubViewport.new()
    viewport.name = "StreetPerspective"
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.handle_input_locally = false
    add_child(viewport)
    _resize()
    var assembly := Node3D.new()
    viewport.add_child(assembly)
    street = preload("res://scenes/street_whitebox.tscn").instantiate()
    street.name = "Street"
    assembly.add_child(street)
    street.set_process_unhandled_key_input(false)
    street.get_node("Overlay").hide()
    var dressing := Node3D.new()
    dressing.set_script(preload("res://scripts/street_dressing.gd"))
    street.add_child(dressing)
    # The source sign uses proxy glyphs. Layer legible type in this wrapper only.
    for part in street.get_node("Landmarks").get_children():
        if part.name.begins_with("SignGlyphProxy"):
            part.hide()
    var title := Label3D.new()
    title.text = "新\n隆\n街\n坊"
    title.font_size = 96
    title.pixel_size = 0.015
    title.modulate = Color("f5c944")
    title.outline_modulate = Color("79511d")
    title.outline_size = 8
    title.position = Vector3(-4.8,10.7,-14.73)
    title.no_depth_test = true
    street.add_child(title)
    var font := SystemFont.new()
    font.font_names = PackedStringArray(["Noto Sans CJK TC","Microsoft JhengHei","sans-serif"])
    title.font = font
    _style_surfaces(street)
    var world: WorldEnvironment = street.get_node("WorldEnvironment")
    world.environment = world.environment.duplicate(true)
    world.environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_material := ShaderMaterial.new()
    sky_material.shader = preload("res://shaders/stylized_sky.gdshader")
    sky_material.set_shader_parameter("blue",Color("075bbd"))
    sky.sky_material = sky_material
    world.environment.sky = sky
    world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world.environment.ambient_light_color = Color("8ca9d3")
    world.environment.ambient_light_energy = 0.55
    var sun: DirectionalLight3D = street.get_node("Sun")
    sun.light_color = Color("ffe8c2")
    sun.light_energy = 1.0
    sun.shadow_blur = 0.0
    plane = street.get_node("AircraftProxy")
    var detail_builder := preload("res://scripts/aircraft_flyby.gd").new()
    detail_builder.plane = plane
    detail_builder._add_detail()
    detail_builder.free()
    # Style the added livery and wheels as well as the source geometry.
    _style_surfaces(plane)
    plane.reparent(assembly)
    plane.scale = Vector3.ONE * 0.9
    street.scale.x = 2.1
    plane.position = anchor
    plane.rotation_degrees.y = -145
    camera = Camera3D.new()
    camera.name = "ReferenceLowAngle"
    camera.position = Vector3(0,1.1,8)
    camera.rotation_degrees.x = 27
    camera.fov = 72.0
    camera.far = 500.0
    assembly.add_child(camera)
    camera.make_current()
    var ink := MeshInstance3D.new()
    ink.set_script(preload("res://scripts/screen_outline.gd"))
    assembly.add_child(ink)
    ink.visible = true
    ink.material_override.set_shader_parameter("ink_strength",0.68)
    ink.material_override.set_shader_parameter("edge_threshold",0.025)
    retained_materials.append(ink.material_override)
    canvas = CanvasLayer.new()
    canvas.name = "PerspectiveBackground"
    canvas.layer = -10
    add_child(canvas)
    var picture := TextureRect.new()
    picture.name = "StreetView"
    picture.texture = viewport.get_texture()
    picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    picture.stretch_mode = TextureRect.STRETCH_SCALE
    picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(picture)
    get_viewport().size_changed.connect(_resize)

func _resize() -> void:
    var extent := get_viewport().get_visible_rect().size
    var scale_factor := minf(1.0,1280.0 / maxf(1.0,extent.x))
    viewport.size = Vector2i(maxi(1,roundi(extent.x*scale_factor)),maxi(1,roundi(extent.y*scale_factor)))

func _style_surfaces(root: Node) -> void:
    for mesh in root.find_children("*","MeshInstance3D",true,false):
        var sources: Array[Material] = []
        for surface in mesh.mesh.get_surface_count():
            sources.append(mesh.get_active_material(surface))
        mesh.material_override = null
        for surface in mesh.mesh.get_surface_count():
            var source: Material = sources[surface]
            if not source is BaseMaterial3D:
                continue
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
    if frozen:
        return
    if paused != was_paused:
        viewport.render_target_update_mode = SubViewport.UPDATE_ONCE if paused else SubViewport.UPDATE_ALWAYS
        was_paused = paused
    if paused:
        return
    elapsed = fmod(elapsed + delta,cycle)
    # One straight pass followed by an off-screen cooldown, never reverse flight.
    var phase := fmod(elapsed + FLIGHT_SECONDS * 0.5,cycle)
    plane.visible = phase <= FLIGHT_SECONDS
    var distance := (phase / FLIGHT_SECONDS - 0.5) * 150.0
    plane.position = anchor + Vector3(-0.55,0,-0.84) * distance

func freeze_for_capture() -> void:
    frozen = true
    plane.visible = true
    plane.position = anchor
