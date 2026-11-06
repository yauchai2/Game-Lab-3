extends Node3D
## Runtime-only flyby for the walk scene; the S1 whitebox remains static.
const DURATION := 12.0
const DISTANCE := 540.0
const COOLDOWN := 30.0
# Walk-scene framing only; S1 static whitebox remains unchanged.
const WALK_ANCHOR_OFFSET := Vector3(-3,-4,8)
const WALK_YAW_DEGREES := -150.0
var anchor: Vector3
var direction: Vector3
var elapsed := 0.0
var cooldown := 0.0
var active := false
var preview := false
var plane: Node3D
var sound: AudioStreamPlayer3D

func _ready() -> void:
    plane = get_parent().get_node("Street/AircraftProxy")
    plane.global_position += WALK_ANCHOR_OFFSET
    plane.rotation_degrees.y = WALK_YAW_DEGREES
    anchor = plane.global_position
    direction = -plane.global_basis.z.normalized()
    _add_detail()
    sound = AudioStreamPlayer3D.new()
    sound.name = "PlaceholderEngine"
    var stream: AudioStreamWAV = load("res://audio/engine_placeholder.wav").duplicate()
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = stream.data.size() / 2
    sound.stream = stream
    sound.unit_size = 100.0
    sound.max_distance = 650.0
    plane.add_child(sound)
    var area := Area3D.new()
    area.name = "EntranceTrigger"
    area.collision_layer = 0
    area.collision_mask = 2
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(14,6,28)
    shape.shape = box
    area.position = Vector3(0,3,0)
    area.add_child(shape)
    add_child(area)
    area.body_entered.connect(_on_entered)
    plane.visible = false

func _on_entered(body: Node3D) -> void:
    if body == get_parent().get_node("Player") and not active and cooldown <= 0.0 and not preview:
        restart()

func restart() -> void:
    preview = false
    active = true
    elapsed = 0.0
    cooldown = 0.0
    plane.visible = true
    _place(0.0)
    sound.volume_db = -60.0
    sound.play()

func _process(delta: float) -> void:
    if active:
        elapsed = minf(DURATION,elapsed+delta)
        _place(elapsed / DURATION)
        sound.volume_db = linear_to_db(maxf(.001,minf(1.0,minf(elapsed/2.0,(DURATION-elapsed)/2.0))))
        if elapsed >= DURATION:
            active = false
            cooldown = COOLDOWN
            plane.visible = false
            sound.stop()
    elif cooldown > 0:
        cooldown = maxf(0.0,cooldown-delta)

func _place(ratio: float) -> void:
    plane.global_position = anchor + direction * ((ratio-.5)*DISTANCE)

## Captures use a fixed pose; this does not represent a runtime recording.
func freeze_for_capture(ratio := .5) -> void:
    preview = true
    active = false
    plane.visible = true
    sound.stop()
    _place(clampf(ratio,0.0,1.0))

func _add_detail() -> void:
    var metal := StandardMaterial3D.new()
    metal.albedo_color = Color("8d999e")
    var rubber := StandardMaterial3D.new()
    rubber.albedo_color = Color("202b35")
    var green := StandardMaterial3D.new()
    green.albedo_color = Color("248b78")
    green.roughness = 1.0
    green.cull_mode = BaseMaterial3D.CULL_DISABLED
    _make_livery(green)
    for side in [-1,1]:
        _box("AdditionalGearStrut",Vector3(side*2.0,-3.6,14),Vector3(.3,3,.3),metal)
        for axle in 2:
            for wheel in 2:
                var mesh := CylinderMesh.new()
                mesh.top_radius = .65
                mesh.bottom_radius = .65
                mesh.height = .45
                mesh.radial_segments = 12
                var tire := MeshInstance3D.new()
                tire.name = "AdditionalMainWheel_%s_%s_%s" % [side,axle,wheel]
                tire.mesh = mesh
                tire.material_override = rubber
                tire.position = Vector3(side*(2+wheel*.55),-5.1,13.2+axle*1.7)
                tire.rotation_degrees.z = 90
                tire.layers = 2
                plane.add_child(tire)
        for x in [9.0,17.0,24.0]:
            _box("FlapDetail",Vector3(side*x,-.55,8.4),Vector3(5,.25,1.4),metal)
func _box(title: String, at: Vector3, size: Vector3, mat: Material) -> void:
    var mesh := BoxMesh.new()
    mesh.size = size
    var part := MeshInstance3D.new()
    part.name = title
    part.position = at
    part.mesh = mesh
    part.material_override = mat
    part.layers = 2
    plane.add_child(part)

func _make_livery(material: Material) -> void:
    # Livery wraps the cylindrical fuselage and the tapered nose rather than
    # floating as flat decals. Original S1 geometry remains intact.
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1.0,1.0]:
        for z_index in range(18):
            var z0 := lerpf(-25.0,20.0,float(z_index)/18.0)
            var z1 := lerpf(-25.0,20.0,float(z_index+1)/18.0)
            var p00 := _band_point(side,-.48,z0)
            var p01 := _band_point(side,-.16,z0)
            var p10 := _band_point(side,-.48,z1)
            var p11 := _band_point(side,-.16,z1)
            for point in [p00,p10,p11,p00,p11,p01]:
                surface.add_vertex(point)
    # Upper and side portions of a green nose cap, retaining the white belly.
    for z_index in range(6):
        var z0 := lerpf(-32.85,-29.0,float(z_index)/6.0)
        var z1 := lerpf(-32.85,-29.0,float(z_index+1)/6.0)
        for ring in range(16):
            var t0 := lerpf(-.38,PI+.38,float(ring)/16.0)
            var t1 := lerpf(-.38,PI+.38,float(ring+1)/16.0)
            var p00 := _nose_point(z0,t0)
            var p01 := _nose_point(z0,t1)
            var p10 := _nose_point(z1,t0)
            var p11 := _nose_point(z1,t1)
            for point in [p00,p10,p11,p00,p11,p01]:
                surface.add_vertex(point)
    surface.generate_normals()
    var livery := MeshInstance3D.new()
    livery.name = "GreenLiveryDetail"
    livery.mesh = surface.commit()
    livery.material_override = material
    # Thin color surfaces must not self-shadow onto the fuselage.
    livery.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    livery.layers = 2
    plane.add_child(livery)

func _band_point(side: float, angle: float, z: float) -> Vector3:
    return Vector3(side*2.70*cos(angle),2.70*sin(angle),z)

func _nose_point(z: float, angle: float) -> Vector3:
    var normalized_z := clampf((z+26.0)/7.0,-.999,.999)
    var radius := 2.74*sqrt(1.0-normalized_z*normalized_z)
    return Vector3(radius*cos(angle),radius*sin(angle),z)
