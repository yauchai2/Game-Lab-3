extends Node3D
## Reversible scene dressing; storefronts are visual, lamp poles use simple collision.
## Boxes sharing a material are batched to keep the number of draw submissions modest.
const GRAFFITI = preload("res://assets/art/graffiti_swift_A01.png")
var groups: Dictionary = {}
var material_colors := {
    "frame": Color("273c45"),
    "glass": Color("183d49"),
    "glass_light": Color("285761"),
    "cream": Color("e2d5b4"),
    "ivory": Color("f1e4bd"),
    "warm": Color("d97a51"),
    "red": Color("b74337"),
    "teal": Color("287d82"),
    "blue": Color("266078"),
    "yellow": Color("e8b64d"),
    "road_paint": Color("e9d7a8"),
    "road_dark": Color("56636a"),
    "leaf": Color("568764"),
    "awning_red": Color("ad5144"),
}
var labels: Node3D
var static_batches: Node3D
var shared_font: SystemFont
var box_count := 0

func _ready() -> void:
    shared_font = SystemFont.new()
    shared_font.font_names = PackedStringArray(["Noto Sans CJK TC","Microsoft JhengHei","PingFang TC","sans-serif"])
    shared_font.font_weight = 700
    labels = Node3D.new()
    labels.name = "Lettering"
    add_child(labels)
    static_batches = Node3D.new()
    static_batches.name = "BatchedGeometry"
    add_child(static_batches)
    _make_road()
    _make_manholes()
    _make_storefronts()
    _make_corner_facades()
    _make_upper_facades()
    _make_balcony_planters()
    _make_signs()
    _make_landmark_scaffold()
    _make_street_furniture()
    _make_cables()
    _make_graffiti()
    _make_background()
    _flush_groups()

func _box(group: String, at: Vector3, size: Vector3) -> void:
    if not groups.has(group):
        groups[group] = []
    groups[group].append(Transform3D(Basis.from_scale(size),at))
    box_count += 1

func _segment(group: String, start: Vector3, end: Vector3, width: float) -> void:
    if not groups.has(group):
        groups[group] = []
    var delta := end-start
    var rotation := Basis(Quaternion(Vector3.UP,delta.normalized()))
    groups[group].append(Transform3D(rotation.scaled_local(Vector3(width,delta.length(),width)),(start+end)*.5))
    box_count += 1

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 1.0
    return material

func _flush_groups() -> void:
    var box := BoxMesh.new()
    box.size = Vector3.ONE
    for key in groups:
        var transforms: Array = groups[key]
        var batch := MultiMesh.new()
        batch.transform_format = MultiMesh.TRANSFORM_3D
        batch.mesh = box
        batch.instance_count = transforms.size()
        for i in transforms.size():
            batch.set_instance_transform(i,transforms[i])
        var instance := MultiMeshInstance3D.new()
        instance.name = "Batch_"+key
        instance.multimesh = batch
        instance.material_override = _material(material_colors[key])
        # Fine, uncollidable details do not need hundreds of separate shadow casters.
        instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        static_batches.add_child(instance)
    groups.clear()

func _label(text: String, at: Vector3, rotation_y: float, font_size: int, pixel_size: float, color: Color) -> void:
    var sign := Label3D.new()
    sign.name = "SignText_"+str(labels.get_child_count())
    sign.text = text
    sign.font_size = font_size
    sign.pixel_size = pixel_size
    sign.modulate = color
    sign.outline_size = 0
    sign.position = at
    sign.rotation.y = rotation_y
    sign.font = shared_font
    labels.add_child(sign)

func _make_road() -> void:
    # A pedestrian crossing at the entrance; paint is visual only and sits above the road surface.
    for i in 8:
        var x := -3.5+i*1.0
        _box("road_paint",Vector3(x,.012,3.0),Vector3(.53,.016,3.0))
    for side in [-1,1]:
        # Short double yellow kerb lines with gaps at the entrance and the alley.
        for z in [-8.0,-18.0,-26.0,-40.0,-50.0,-59.0]:
            for inset in [0.0,.16]:
                _box("yellow",Vector3(side*(3.72-inset),.013,z),Vector3(.055,.012,5.6))
    # A few long, understated tarmac joints break up the empty surface.
    for z in [-7.0,-20.0,-35.0,-48.0,-59.0]:
        _box("road_dark",Vector3(0,.008,z),Vector3(7.8,.008,.025))

func _make_manholes() -> void:
    var ring := CylinderMesh.new()
    ring.top_radius = .36
    ring.bottom_radius = .36
    ring.height = .018
    ring.radial_segments = 16
    var cover_material := _material(Color("4e5a5e"))
    for spec in [[-1.0,-4.0],[.8,-27.0],[-.8,-49.0]]:
        var cover := MeshInstance3D.new()
        cover.name = "ManholeCover"
        cover.mesh = ring
        cover.material_override = cover_material
        cover.position = Vector3(spec[0],.02,spec[1])
        cover.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(cover,true)
        for offset in [-.15,0.0,.15]:
            _box("road_dark",Vector3(spec[0]+offset,.033,spec[1]),Vector3(.025,.012,.46))
    # Narrow drain grates at the edges of the carriageway.
    for side in [-1,1]:
        for z in [-11.5,-24.0,-46.0]:
            _box("road_dark",Vector3(side*3.77,.017,z),Vector3(.34,.016,.9))
            for i in 5:
                _box("frame",Vector3(side*3.77,.027,z-.32+i*.16),Vector3(.27,.009,.025))

func _shop(side: int, z: float, width: float, sign_group: String, title: String) -> void:
    var face := side*5.81
    var edge := side*5.72
    var glass := "glass" if side < 0 else "glass_light"
    # Existing S1 wall remains the solid backing; shop windows are shallow decorative layers.
    _box(glass,Vector3(face,1.5,z),Vector3(.12,2.65,width))
    _box("frame",Vector3(edge,1.5,z),Vector3(.08,2.65,.12))
    for z_offset in [-width*.47,width*.47]:
        _box("frame",Vector3(edge,1.5,z+z_offset),Vector3(.08,2.65,.10))
    for y in [.22,2.78]:
        _box("frame",Vector3(edge,y,z),Vector3(.08,.11,width))
    # One contrasting door, with a large simple window and handle.
    var door_z := z-width*.29
    _box("frame",Vector3(side*5.67,1.28,door_z),Vector3(.12,2.45,.78))
    _box("glass_light",Vector3(side*5.59,1.48,door_z),Vector3(.06,1.55,.62))
    _box("ivory",Vector3(side*5.54,1.05,door_z+.22),Vector3(.04,.25,.035))
    # Small notices on the windows suggest inhabited shops without using tiny illegible text.
    _box("cream",Vector3(side*5.61,1.50,z+width*.25),Vector3(.03,.48,.34))
    _box("yellow",Vector3(side*5.58,1.65,z+width*.25),Vector3(.03,.09,.26))
    _box("red",Vector3(side*5.57,1.42,z+width*.25),Vector3(.03,.035,.23))
    # Fascia band and small frame edging; all text is fictional and editable.
    _box(sign_group,Vector3(side*5.74,3.13,z),Vector3(.14,.65,width+.14))
    _box("ivory",Vector3(side*5.65,3.48,z),Vector3(.05,.07,width+.18))
    _label(title,Vector3(side*5.62,3.13,z),PI/2.0 if side < 0 else -PI/2.0,52,.0065,Color("f2d785"))

func _make_storefronts() -> void:
    _shop(-1,-3.0,4.3,"teal","海風茶居")
    _shop(-1,-9.3,4.2,"red","街角士多")
    _shop(-1,-19.0,4.3,"blue","新星影音")
    _shop(-1,-25.0,3.5,"red","日日小館")
    _shop(-1,-42.0,4.6,"teal","順風商店")
    _shop(1,-3.5,4.6,"red","金城餐室")
    _shop(1,-10.2,4.2,"teal","街市茶水")
    _shop(1,-21.0,4.5,"blue","飛雲商店")
    _shop(1,-29.0,4.0,"red","樂記雜貨")
    _shop(1,-46.0,4.2,"teal","早安冰室")

func _make_corner_facades() -> void:
    # The entrance-facing gables are visible from the photo-aligned camera.
    _box("blue",Vector3(-9.0,10.5,2.07),Vector3(2.35,8.2,.16))
    _box("ivory",Vector3(-9.0,10.5,2.17),Vector3(2.18,8.05,.08))
    _box("teal",Vector3(-9.0,10.5,2.23),Vector3(1.95,7.8,.06))
    _label("新\n興\n茶\n室",Vector3(-9.0,10.5,2.28),0,100,.011,Color("c4e88e"))
    # A vertical edge band and shallow vent windows articulate the orange corner.
    _box("warm",Vector3(6.35,10.0,2.08),Vector3(.32,19.5,.12))
    for y in [5.1,8.4,11.7,15.0]:
        _box("frame",Vector3(8.1,y,2.09),Vector3(1.65,1.2,.12))
        _box("glass_light",Vector3(8.1,y,2.17),Vector3(1.5,1.05,.06))

func _make_upper_facades() -> void:
    # Groups in the middle street pick up the window rhythm missing from the whitebox.
    for side in [-1,1]:
        for z in [-19.0,-24.0,-39.0,-45.0,-52.0]:
            for floor_index in [1,2,3,4]:
                var y: float = floor_index*3.3+1.8
                if floor_index == 4 and z == -52.0:
                    continue
                var face: float = side*5.83
                for dz in [-.85,.85]:
                    _box("cream",Vector3(face,y,z+dz),Vector3(.10,1.55,.07))
                _box("frame",Vector3(side*5.76,y,z),Vector3(.08,1.45,.065))
                _box("cream",Vector3(side*5.75,y+.76,z),Vector3(.11,.07,1.75))
                _box("cream",Vector3(side*5.75,y-.76,z),Vector3(.11,.07,1.75))
    # Repeated air conditioner boxes, spaced apart from the pedestrian area.
    for spec in [[-1,-17.0,5.2],[-1,-23.5,8.5],[-1,-41.0,5.4],[1,-22.0,8.5],[1,-42.0,5.4]]:
        var side: int = spec[0]
        var z: float = spec[1]
        var y: float = spec[2]
        _box("ivory",Vector3(side*5.72,y,z),Vector3(.48,.55,.72))
        _box("frame",Vector3(side*5.45,y,z),Vector3(.035,.34,.52))
        for dz in [-.18,0.0,.18]:
            _box("cream",Vector3(side*5.42,y,z+dz),Vector3(.03,.30,.025))

func _make_balcony_planters() -> void:
    # The reference's orange building uses long planted balcony edges.
    # All details remain shallow and above the walkable sidewalk.
    for floor_index in [1, 2, 3]:
        var base_y: float = floor_index * 3.3
        for z in [-10.0, -6.5, -3.0]:
            _box("frame", Vector3(5.43, base_y + .40, z), Vector3(.30, .36, 2.2))
            _box("warm", Vector3(5.25, base_y + .40, z), Vector3(.08, .30, 2.12))
            for i in 5:
                var leaf_z: float = z - .83 + i * .41
                var leaf_height := .30 + float((floor_index + i) % 3) * .09
                _box("leaf", Vector3(5.32, base_y + .66 + leaf_height * .5, leaf_z), Vector3(.28, leaf_height, .36))
    # A few window-mounted cages echo the real street's projecting metalwork.
    for spec in [[-10.0, 8.6], [-4.0, 11.9], [-21.0, 8.6]]:
        var z: float = spec[0]
        var y: float = spec[1]
        for dz in [-.42, .42]:
            _box("frame", Vector3(5.50, y, z + dz), Vector3(.62, .055, .055))
            _box("frame", Vector3(5.19, y + .24, z + dz), Vector3(.055, .48, .055))
        _box("frame", Vector3(5.19, y + .48, z), Vector3(.055, .055, .90))

func _projecting_sign(side: int, z: float, y: float, panel: String, text: String) -> void:
    var x := side*5.08
    _box("frame",Vector3(side*5.55,y,z),Vector3(1.0,.09,.09))
    _box("ivory",Vector3(x,y,z),Vector3(1.15,1.05,.13))
    _box(panel,Vector3(x,y,z+.09),Vector3(1.0,.88,.07))
    # Signs face the entry end of the street (+Z).
    _label(text,Vector3(x,y,z+.135),0,44,.005,Color("ffda83"))

func _make_signs() -> void:
    _projecting_sign(-1,-9.5,5.2,"blue","影音")
    _projecting_sign(-1,-19.5,6.2,"red","茶")
    _projecting_sign(1,-21.0,5.8,"teal","小食")
    _projecting_sign(1,-34.5,7.1,"red","電器")
    # Small crossing signs recede along the street rather than forming a solid wall.
    for spec in [[.65,7.9,-22.0,"blue","華興茶室"],[-.7,7.0,-39.0,"red","永記商店"],[.4,7.5,-52.0,"teal","海港電器"]]:
        var x: float = spec[0]
        var y: float = spec[1]
        var z: float = spec[2]
        _box("ivory",Vector3(x,y,z),Vector3(3.0,.82,.13))
        _box(spec[3],Vector3(x,y,z+.08),Vector3(2.85,.68,.06))
        _label(spec[4],Vector3(x,y,z+.125),0,48,.007,Color("f7d575"))
    # Additional sign silhouettes add depth without spanning the full street.
    for spec in [[-1,-29.0,7.9,"yellow"],[1,-43.0,8.2,"teal"],[-1,-48.0,6.3,"red"]]:
        var side: int = spec[0]
        var z: float = spec[1]
        var y: float = spec[2]
        _box("ivory",Vector3(side*5.15,y,z),Vector3(1.25,1.1,.12))
        _box(spec[3],Vector3(side*5.15,y,z+.08),Vector3(1.1,.95,.06))

func _make_landmark_scaffold() -> void:
    # Pale metal bracing supports the moved landmark sign; geometry is overhead.
    var z := -15.04
    var left := -5.94
    var right := -5.04
    for x in [left,right]:
        _box("cream",Vector3(x,10.7,z),Vector3(.075,8.8,.075))
    for y in [6.35,8.5,10.7,12.9,15.05]:
        _box("cream",Vector3((left+right)*.5,y,z),Vector3(right-left,.075,.075))
    for i in 4:
        var y := 6.35+i*2.175
        _segment("cream",Vector3(left,y,z+.02),Vector3(right,y+2.175,z+.02),.055)
        _segment("cream",Vector3(right,y,z-.02),Vector3(left,y+2.175,z-.02),.055)
    for y in [7.2,14.2]:
        _segment("frame",Vector3(-6.0,y,-16.1),Vector3(-5.0,y,-15.0),.09)

func _make_street_furniture() -> void:
    # Slender lamps on the sidewalk, visual only. The original collision corridor remains unchanged.
    for spec in [[-1,-.5],[-1,-21.5],[1,-26.0],[1,-52.0]]:
        var side: int = spec[0]
        var z: float = spec[1]
        var x := side*5.48
        _box("frame",Vector3(x,3.0,z),Vector3(.11,6.0,.11))
        _box("frame",Vector3(x-side*.37,5.95,z),Vector3(.85,.10,.1))
        _box("ivory",Vector3(x-side*.78,5.84,z),Vector3(.25,.16,.32))
        var pole := StaticBody3D.new()
        pole.name = "LampPoleCollider_"+str(get_child_count())
        pole.position = Vector3(x,0,z)
        var shape := CollisionShape3D.new()
        var cylinder := CylinderShape3D.new()
        cylinder.radius = .09
        cylinder.height = 6.0
        shape.shape = cylinder
        shape.position.y = 3.0
        pole.add_child(shape)
        add_child(pole)
    # A few potted shrubs on elevated facade ledges, out of the pedestrian path.
    for z in [-3.2,-7.5,-11.5]:
        _box("warm",Vector3(5.44,7.2,z),Vector3(.42,.32,1.2))
        for dz in [-.35,0.0,.35]:
            _box("leaf",Vector3(5.42,7.48,z+dz),Vector3(.32,.35,.28))

func _make_cables() -> void:
    # A few restrained spans provide sky depth. They are non-colliding visual details.
    for z in [-24.0,-37.0,-52.0]:
        var last := Vector3(-5.8,12.3,z)
        for i in range(1,9):
            var t := float(i)/8.0
            var point := Vector3(lerpf(-5.8,5.8,t),12.3-.85*4.0*t*(1.0-t),z)
            _segment("frame",last,point,.025)
            last = point

func _make_graffiti() -> void:
    # One original graphic in the side alley, away from the photo's main view.
    var surface := QuadMesh.new()
    surface.size = Vector2(4.4,2.25)
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = GRAFFITI
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
    var art := MeshInstance3D.new()
    art.name = "AlleyGraffiti"
    art.mesh = surface
    art.material_override = mat
    art.position = Vector3(-10.5,3.2,-33.90)
    art.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(art)

func _make_background() -> void:
    # The far whitebox remains a collision boundary; layered signs/windows give it depth.
    _box("blue",Vector3(-5.5,7.0,-72.88),Vector3(5.5,13.2,.18))
    _box("cream",Vector3(4.1,6.6,-72.84),Vector3(7.5,12.6,.18))
    for x in [-7.1,-5.4,-3.7,1.7,4.0,6.3]:
        for y in [4.2,7.2,10.2]:
            _box("glass",Vector3(x,y,-72.72),Vector3(1.15,1.45,.10))
    _box("red",Vector3(0,3.7,-72.66),Vector3(8.0,1.0,.12))
    _label("雲港商場",Vector3(0,3.7,-72.56),0,60,.012,Color("f6d781"))
