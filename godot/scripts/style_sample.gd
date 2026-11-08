extends Node3D
## Small reversible style experiment layered on the S1 scene.
const ToonShader = preload("res://shaders/sample_toon.gdshader")
const SkyShader = preload("res://shaders/stylized_sky.gdshader")
const GeneratedSkyTexture = preload("res://assets/SKY_BLUE_A01.png")
var generated_sky: Sky
var procedural_sky: Sky
var image_sky_enabled := false
var clouds_enabled := true
var sample_environment: Environment
var sky_motion = preload("res://scripts/sky_drift.gd").new()
var mode := 1 # 0 original, 1 two bands, 2 three bands
var affected: Array[MeshInstance3D] = []
var originals: Array[Material] = []
var replacements: Array[ShaderMaterial] = []
var glyphs: Array[Node3D] = []
var details: Node3D
var detail_groups: Dictionary = {}
var detail_instance_count := 0
var two_sided_shader: Shader
var aircraft_shader: Shader
var aircraft_two_sided_shader: Shader
@onready var street: Node3D = get_parent().get_node("Street")
func _ready() -> void:
    # Per-instance environment: keep highlights readable without changing S1 resources.
    var world: WorldEnvironment = street.get_node("WorldEnvironment")
    world.environment = world.environment.duplicate(true)
    world.environment.ambient_light_energy = .35
    world.environment.background_color = Color("41b3dc")
    sample_environment = world.environment
    var sky_material := ShaderMaterial.new()
    sky_material.shader = SkyShader
    var sample_sky := Sky.new()
    sample_sky.sky_material = sky_material
    procedural_sky = sample_sky
    generated_sky = Sky.new()
    var panorama := PanoramaSkyMaterial.new()
    panorama.panorama = GeneratedSkyTexture
    generated_sky.sky_material = panorama
    sample_environment.sky = procedural_sky
    set_image_sky(true)
    var sun: DirectionalLight3D = street.get_node("Sun")
    sun.light_energy = .62
    sun.light_color = Color("ffe4c4")
    # Bring the landmark sign slightly into the street and warm its face;
    # the standalone S1 whitebox remains untouched.
    for title in ["VerticalSignFrame","VerticalSignFace"]:
        var sign: MeshInstance3D = street.get_node("Landmarks/"+title)
        sign.position.x += .8
        var original: BaseMaterial3D = sign.get_active_material(0)
        var styled: BaseMaterial3D = original.duplicate(true)
        styled.albedo_color = Color("dbab3c") if title == "VerticalSignFrame" else Color("59402d")
        sign.material_override = styled
    two_sided_shader = Shader.new()
    two_sided_shader.code = ToonShader.code.replace("specular_disabled;", "specular_disabled, cull_disabled;")
    # Thin aircraft details produced shadow acne on the white fuselage. The plane
    # still casts street shadows, but its stylized surface does not receive them.
    aircraft_shader = Shader.new()
    aircraft_shader.code = ToonShader.code.replace("specular_disabled;", "specular_disabled, shadows_disabled;")
    aircraft_two_sided_shader = Shader.new()
    aircraft_two_sided_shader.code = ToonShader.code.replace("specular_disabled;", "specular_disabled, shadows_disabled, cull_disabled;")
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
    for child in get_parent().get_node("Player/Visual/CharacterModel").find_children("*","MeshInstance3D",true,false):
        _enroll(child)
    for child in get_parent().get_node("ParkedCar").find_children("*","MeshInstance3D",true,false):
        _enroll(child)
    for child in get_parent().get_node("ParkedTruck").find_children("*","MeshInstance3D",true,false):
        _enroll(child)
    for child in street.get_node("AircraftProxy").find_children("*","MeshInstance3D",true,false):
        _enroll(child,true)
    details = Node3D.new()
    details.name = "SampleDetails"
    add_child(details)
    _build_details()
    _flush_detail_groups()
    set_mode(mode)
func _enroll(target: MeshInstance3D, aircraft := false) -> void:
    var source := target.get_active_material(0)
    var replacement := ShaderMaterial.new()
    replacement.shader = aircraft_shader if aircraft else ToonShader
    if source is BaseMaterial3D:
        if source.cull_mode == BaseMaterial3D.CULL_DISABLED:
            replacement.shader = aircraft_two_sided_shader if aircraft else two_sided_shader
        replacement.set_shader_parameter("base_color",source.albedo_color)
        replacement.set_shader_parameter("use_world_uv",source.uv1_triplanar and source.uv1_world_triplanar)
        replacement.set_shader_parameter("texture_scale",source.uv1_scale)
        replacement.set_shader_parameter("texture_offset",source.uv1_offset)
        replacement.set_shader_parameter("use_texture",source.albedo_texture != null)
        if source.albedo_texture != null:
            replacement.set_shader_parameter("base_texture",source.albedo_texture)
            replacement.set_shader_parameter("world_texture",source.albedo_texture)
    affected.append(target)
    originals.append(target.material_override)
    replacements.append(replacement)
func _flat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 1.0
    return m
func _queue_detail(kind: String, at: Vector3, size: Vector3, mat: Material) -> void:
    var key := kind+"_"+str(mat.get_instance_id())
    if not detail_groups.has(key):
        detail_groups[key] = {"kind":kind,"material":mat,"transforms":[]}
    detail_groups[key].transforms.append(Transform3D(Basis.from_scale(size),at))
    detail_instance_count += 1
func _box(_title: String, at: Vector3, size: Vector3, mat: Material) -> void:
    _queue_detail("box",at,size,mat)
func _bulb(at: Vector3, mat: Material) -> void:
    _queue_detail("bulb",at,Vector3.ONE,mat)
func _flush_detail_groups() -> void:
    var box := BoxMesh.new()
    box.size = Vector3.ONE
    var sphere := SphereMesh.new()
    sphere.radius = .12
    sphere.height = .24
    sphere.radial_segments = 8
    sphere.rings = 4
    for key in detail_groups:
        var group: Dictionary = detail_groups[key]
        var transforms: Array = group.transforms
        var batch := MultiMesh.new()
        batch.transform_format = MultiMesh.TRANSFORM_3D
        batch.mesh = box if group.kind == "box" else sphere
        batch.instance_count = transforms.size()
        for i in transforms.size():
            batch.set_instance_transform(i,transforms[i])
        var instance := MultiMeshInstance3D.new()
        instance.name = "SampleBatch_"+group.kind
        instance.multimesh = batch
        instance.material_override = group.material
        details.add_child(instance,true)
    detail_groups.clear()
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
    # Window frames add depth without changing the underlying whitebox collision.
    for floor_index in range(1,5):
        var y := floor_index*3.3+1.8
        for z in [-11.1,-6.0,-.9]:
            for x in [-5.80,5.80]:
                _box("WindowSash",Vector3(x,y,z),Vector3(.10,1.55,.08),pale)
                for edge in [-1,1]:
                    _box("WindowFrame",Vector3(x,y,z+edge*1.52),Vector3(.10,1.65,.10),dark)
    # StreetDressing owns the receding signs, avoiding duplicate panels at -39 m.
    # Scene lettering is supplied later as user artwork; do not create hidden fonts.
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

func set_clouds(enabled: bool) -> void:
    image_sky_enabled = false
    clouds_enabled = enabled
    sample_environment.sky = procedural_sky
    sample_environment.sky_rotation = Vector3(0,sky_motion.offset,0)
    sample_environment.background_mode = Environment.BG_SKY if enabled else Environment.BG_COLOR

func set_image_sky(enabled: bool) -> void:
    if not enabled:
        set_clouds(true)
        return
    image_sky_enabled = true
    clouds_enabled = true
    sample_environment.sky = generated_sky
    sample_environment.sky_rotation = Vector3(0,PI*0.5+sky_motion.offset,0)
    sample_environment.background_mode = Environment.BG_SKY

func sky_label() -> String:
    if image_sky_enabled:
        return "Image sky"
    return "Clouds" if clouds_enabled else "Flat sky"

func _process(delta: float) -> void:
    sky_motion.advance(sample_environment,delta,PI*0.5 if image_sky_enabled else 0.0)
