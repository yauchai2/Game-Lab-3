extends Node3D
## Small reversible style experiment layered on the S1 scene.
const ToonShader = preload("res://shaders/sample_toon.gdshader")
var mode := 1 # 0 original, 1 two bands, 2 three bands
var affected: Array[MeshInstance3D] = []
var originals: Array[Material] = []
var replacements: Array[ShaderMaterial] = []
var glyphs: Array[Node3D] = []
var details: Node3D
var two_sided_shader: Shader
@onready var street: Node3D = get_parent().get_node("Street")
func _ready() -> void:
    # Per-instance environment: keep highlights readable without changing S1 resources.
    var world: WorldEnvironment = street.get_node("WorldEnvironment")
    world.environment = world.environment.duplicate(true)
    world.environment.ambient_light_energy = .35
    var sun: DirectionalLight3D = street.get_node("Sun")
    sun.light_energy = .55
    two_sided_shader = Shader.new()
    two_sided_shader.code = ToonShader.code.replace("specular_disabled;", "specular_disabled, cull_disabled;")
    for child in street.get_node("BuildingMasses").get_children():
        if child is MeshInstance3D and (child.name.begins_with("OrangeFront") or child.name.begins_with("BlueFront")):
            _enroll(child)
    for child in street.get_node("Landmarks").get_children():
        if child is MeshInstance3D:
            if child.name.begins_with("SignGlyphProxy"):
                glyphs.append(child)
            else:
                _enroll(child)
    for asset_id in ["PROP_HYDRANT_A01", "VEH_VAN_A01"]:
        for child in street.get_node("Props/"+asset_id).find_children("*","MeshInstance3D",true,false):
            _enroll(child)
    details = Node3D.new()
    details.name = "SampleDetails"
    add_child(details)
    _build_details()
    set_mode(mode)
func _enroll(target: MeshInstance3D) -> void:
    var source := target.get_active_material(0)
    var replacement := ShaderMaterial.new()
    replacement.shader = ToonShader
    if source is BaseMaterial3D:
        if source.cull_mode == BaseMaterial3D.CULL_DISABLED:
            replacement.shader = two_sided_shader
        replacement.set_shader_parameter("base_color",source.albedo_color)
        replacement.set_shader_parameter("use_texture",source.albedo_texture != null)
        if source.albedo_texture != null:
            replacement.set_shader_parameter("base_texture",source.albedo_texture)
    affected.append(target)
    originals.append(target.material_override)
    replacements.append(replacement)
func _flat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 1.0
    return m
func _box(title: String, at: Vector3, size: Vector3, mat: Material) -> void:
    var shape := BoxMesh.new()
    shape.size = size
    var part := MeshInstance3D.new()
    part.name = title
    part.mesh = shape
    part.material_override = mat
    part.position = at
    details.add_child(part)
func _bulb(at: Vector3, mat: Material) -> void:
    var shape := SphereMesh.new()
    shape.radius = .12
    shape.height = .24
    shape.radial_segments = 8
    shape.rings = 4
    var part := MeshInstance3D.new()
    part.name = "BalconyBulb"
    part.mesh = shape
    part.position = at
    part.material_override = mat
    details.add_child(part)
func _build_details() -> void:
    var dark := _flat(Color("273b46"))
    var pale := _flat(Color("f2dfb9"))
    var teal := _flat(Color("287b82"))
    var amber := _flat(Color("e4b741"))
    var coral := _flat(Color("c25b40"))
    # Orange facade spans approximately z=-14..2; details remain outside the walking corridor.
    for floor_index in range(1,5):
        var y := floor_index*3.3
        _box("BalconyRail",Vector3(5.38,y+1.08,-6),Vector3(.11,.12,15),dark)
        for i in range(11):
            var z := -12.8+i*1.35
            _box("BalconyPicket",Vector3(5.38,y+.61,z),Vector3(.10,.95,.09),dark)
        for i in range(4):
            var z := -11.2+i*3.5
            _box("LampBracket",Vector3(5.35,y+1.45,z),Vector3(.7,.07,.07),dark)
            _bulb(Vector3(4.99,y+1.45,z),pale)
    # Shop awnings and a few deliberately grouped features at the pedestrian edge.
    _box("LeftAwning",Vector3(-5.55,2.85,-6),Vector3(.85,.18,6.2),teal)
    _box("LeftAwningTrim",Vector3(-5.1,2.77,-6),Vector3(.08,.28,6.2),pale)
    _box("RightAwning",Vector3(5.50,2.9,-5.8),Vector3(.95,.18,6),coral)
    _box("RightShopSign",Vector3(5.90,3.55,-6),Vector3(.15,.8,5.7),teal)
    for z in [-10.0,-4.0]:
        _box("FacadeAC",Vector3(-5.80,4.25,z),Vector3(.4,.55,.85),pale)
        _box("ACVent",Vector3(-5.57,4.25,z),Vector3(.06,.35,.58),dark)
    _box("LeftVerticalPipe",Vector3(-5.82,8,-11.7),Vector3(.10,15,.10),dark)
    _box("SmallSign",Vector3(-5.50,4.4,-11.5),Vector3(1.0,1.0,.12),amber)
    # Label uses system font fallback; exact glyph availability depends on client fonts.
    var label := Label3D.new()
    label.name = "OriginalSignText"
    label.text = "高\n空\n航\n道"
    label.font_size = 96
    label.pixel_size = .012
    label.modulate = Color("f4c75d")
    label.position = Vector3(-4.8,10.7,-14.72)
    var font := SystemFont.new()
    font.font_names = PackedStringArray(["Noto Sans CJK TC","Microsoft JhengHei","PingFang TC","sans-serif"])
    font.font_weight = 700
    label.font = font
    details.add_child(label)
func set_mode(value: int) -> void:
    mode = posmod(value,3)
    if not is_instance_valid(details):
        return
    # Keep sample geometry identical across modes so B compares materials.
    details.visible = true
    for glyph in glyphs:
        glyph.visible = false
    for i in affected.size():
        if mode == 0:
            affected[i].material_override = originals[i]
        else:
            replacements[i].set_shader_parameter("bands",2 if mode == 1 else 3)
            affected[i].material_override = replacements[i]
func mode_label() -> String:
    return ["Original materials", "Two bands", "Three bands"][mode]
