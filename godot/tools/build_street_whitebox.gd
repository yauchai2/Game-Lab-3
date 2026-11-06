extends SceneTree
## Deterministic S1 scene generation. Run from the Godot project with --script.
var root_node: Node3D
var materials := {}
func v(a: Array) -> Vector3:
    return Vector3(a[0], a[1], a[2])
func material(key: String, color: Color) -> StandardMaterial3D:
    if not materials.has(key):
        var m := StandardMaterial3D.new()
        m.albedo_color = color
        m.roughness = 1.0
        materials[key] = m
    return materials[key]
func node(parent: Node, title: String) -> Node3D:
    var n := Node3D.new()
    n.name = title
    parent.add_child(n,true)
    n.owner = root_node
    return n
func mesh(parent: Node3D, title: String, geometry: Mesh, at: Vector3, mat: Material, collidable := false) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = title
    n.mesh = geometry
    n.material_override = mat
    n.position = at
    parent.add_child(n,true)
    n.owner = root_node
    if str(parent.name).begins_with("Aircraft"):
        n.layers = 2
    if collidable:
        var body := StaticBody3D.new()
        body.name = "StaticCollision"
        n.add_child(body)
        body.owner = root_node
        var shape := CollisionShape3D.new()
        var box_shape := BoxShape3D.new()
        box_shape.size = geometry.get_aabb().size
        shape.shape = box_shape
        body.add_child(shape)
        shape.owner = root_node
    return n
func box(parent: Node3D, title: String, size: Vector3, at: Vector3, mat: Material, collision := false) -> MeshInstance3D:
    var geometry := BoxMesh.new()
    geometry.size = size
    return mesh(parent, title, geometry, at, mat, collision)
func cylinder(parent: Node3D, title: String, radius: float, height: float, at: Vector3, mat: Material) -> MeshInstance3D:
    var geometry := CylinderMesh.new()
    geometry.top_radius = radius
    geometry.bottom_radius = radius
    geometry.height = height
    geometry.radial_segments = 12
    return mesh(parent, title, geometry, at, mat)
func ellipsoid(parent: Node3D, title: String, size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
    var geometry := SphereMesh.new()
    geometry.radius = 1
    geometry.height = 2
    geometry.radial_segments = 16
    geometry.rings = 8
    var n := mesh(parent, title, geometry, at, mat)
    n.scale = size
    return n
func prism(parent: Node3D, title: String, polygon: Array, thickness: float, mat: Material) -> void:
    # Polygon lies in X/Z; simple convex fan, closed volume.
    var area := 0.0
    for i in polygon.size():
        var p: Vector2 = polygon[i]
        var q: Vector2 = polygon[(i+1) % polygon.size()]
        area += p.x*q.y-q.x*p.y
    if area < 0:
        polygon.reverse()
    var vertices := PackedVector3Array()
    for point in polygon:
        vertices.append(Vector3(point.x, thickness / 2, point.y))
    for point in polygon:
        vertices.append(Vector3(point.x, -thickness / 2, point.y))
    var count := polygon.size()
    var indices := PackedInt32Array()
    for i in range(1, count-1):
        indices.append_array([0, i+1, i, count, count+i, count+i+1])
    for i in count:
        var j := (i+1) % count
        indices.append_array([i,j,count+j,i,count+j,count+i])
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in indices:
        st.add_vertex(vertices[i])
    st.generate_normals()
    mesh(parent, title, st.commit(), Vector3.ZERO, mat)
func building(parent: Node3D, title: String, x: float, z: float, depth: float, floors: int, floor_height: float, mat: Material) -> void:
    var h := floor_height * floors
    box(parent,title,Vector3(10,h,depth),Vector3(x,h/2,z),mat,true)
    var street_face := x+5.0 if x < 0 else x-5.0
    var facing := 1.0 if x < 0 else -1.0
    var dark := material("window",Color("253e4c"))
    var ledge := material("ledge",Color("c5bfa2"))
    # Large proxy windows only; fine facade kit belongs to S3.
    for floor_index in floors:
        for slot in 3:
            var wz := z-depth*0.32 + slot*depth*0.32
            box(parent,title+"_Window",Vector3(0.12,1.45,depth*0.19),Vector3(street_face+facing*0.07,floor_index*floor_height+1.8,wz),dark)
        if x > 0 and title.begins_with("Orange"):
            box(parent,title+"_BalconyBand",Vector3(0.65,0.30,depth*0.94),Vector3(street_face-.28,floor_index*floor_height+0.4,z),mat)
        else:
            box(parent,title+"_FloorBand",Vector3(0.22,0.16,depth),Vector3(street_face+facing*0.1,floor_index*floor_height,z),ledge)
    for slot in 2:
        box(parent,title+"_ShopOpening",Vector3(0.14,2.6,depth*0.34),Vector3(street_face+facing*0.09,1.3,z+(slot-.5)*depth*.46),dark)
func make_aircraft(parent: Node3D, config: Dictionary) -> void:
    parent.position = v(config.aircraft_position)
    parent.rotation_degrees.y = config.aircraft_yaw_degrees
    var white := material("aircraft_white",Color("e4e7de"))
    var green := material("aircraft_green",Color("278a78"))
    var metal := material("aircraft_metal",Color("8d999e"))
    var black := material("aircraft_dark",Color("202b35"))
    var fuselage := cylinder(parent,"Aircraft_Fuselage",2.65,52,Vector3.ZERO,white)
    fuselage.rotation.x = PI/2
    ellipsoid(parent,"Aircraft_Nose",Vector3(2.65,2.65,7),Vector3(0,0,-26),white)
    ellipsoid(parent,"Aircraft_TailCone",Vector3(2.25,2.25,6),Vector3(0,0,26),white)
    ellipsoid(parent,"Aircraft_UpperDeck",Vector3(2.1,1.1,10),Vector3(0,2.0,-16),white)
    for side in [-1,1]:
        box(parent,"Aircraft_Livery",Vector3(.08,.65,38),Vector3(side*2.65,.6,-5),green)
        prism(parent,"Aircraft_MainWing",[Vector2(side*2,-6),Vector2(side*29,7),Vector2(side*29,10),Vector2(side*2,8)],.65,white)
        var tailplane := node(parent,"Aircraft_Tailplane")
        tailplane.position.z = 24
        prism(tailplane,"Aircraft_TailWing",[Vector2(side*1,-3),Vector2(side*11,4),Vector2(side*11,6),Vector2(side*1,3)],.4,white)
        for engine_index in 2:
            var x: float = side*(9+engine_index*9)
            var z := 1.0+engine_index*4
            box(parent,"Aircraft_Pylon",Vector3(.5,2.2,3.5),Vector3(x,-1.1,z),metal)
            var engine := cylinder(parent,"Aircraft_Engine",1.25,5.8,Vector3(x,-2.6,z),white)
            engine.rotation.x = PI/2
            var intake := cylinder(parent,"Aircraft_Intake",1.02,.12,Vector3(x,-2.6,z-2.94),black)
            intake.rotation.x = PI/2
        box(parent,"Aircraft_MainGearStrut",Vector3(.3,3,.3),Vector3(side*2,-3.6,7),metal)
        for axle in 2:
            for wheel in 2:
                var tire := cylinder(parent,"Aircraft_MainWheel",.65,.45,Vector3(side*(2+wheel*.55),-5.1,5.5+axle*1.7),black)
                tire.rotation.z = PI/2
    box(parent,"Aircraft_NoseStrut",Vector3(.25,2.8,.25),Vector3(0,-3.5,-23),metal)
    for side in [-1,1]:
        var tire := cylinder(parent,"Aircraft_NoseWheel",.5,.35,Vector3(side*.4,-4.9,-23),black)
        tire.rotation.z = PI/2
    # Thin triangular vertical fin, rotated from the same prism helper.
    var fin := node(parent,"Aircraft_Fin")
    fin.position = Vector3(0,0,23)
    fin.rotation_degrees.z = 90
    prism(fin,"Aircraft_VerticalTail",[Vector2(0,-3),Vector2(10,5),Vector2(0,8)],.7,green)
func _initialize() -> void:
    var config = JSON.parse_string(FileAccess.get_file_as_string("res://config/street_whitebox.json"))
    root_node = Node3D.new()
    root_node.name = "FlightStreetWhitebox"
    root_node.set_script(load("res://scripts/whitebox_views.gd"))
    root.add_child(root_node)
    var street := node(root_node,"StreetGeometry")
    var buildings := node(root_node,"BuildingMasses")
    var landmarks := node(root_node,"Landmarks")
    var props := node(root_node,"Props")
    var aircraft := node(root_node,"AircraftProxy")
    var road := material("road",Color("606970"))
    var pavement := material("pavement",Color("c6bfa9"))
    var blue := material("blue",Color("286b83"))
    var orange := material("orange",Color("d97850"))
    var cream := material("cream",Color("c5bfa2"))
    var grey := material("grey",Color("81918a"))
    var gold := material("gold",Color("e5b744"))
    var dark := material("dark",Color("343e46"))
    var length: float = config.street_length
    var width: float = config.road_width
    var walk: float = config.sidewalk_width
    box(street,"GroundBase",Vector3(52,.4,length+16),Vector3(0,-.22,-length/2+8),material("ground",Color("939588")),true)
    box(street,"MainRoad",Vector3(width,.2,length),Vector3(0,-.1,-length/2),road,true)
    box(street,"EntranceCrossStreet",Vector3(40,.2,16),Vector3(0,-.1,8),road,true)
    for side in [-1,1]:
        box(street,"Sidewalk",Vector3(walk,config.sidewalk_height,length),Vector3(side*(width+walk)/2,config.sidewalk_height/2,-length/2),pavement,true)
        box(street,"Curb",Vector3(.18,.2,length),Vector3(side*(width/2+.05),.1,-length/2),cream)
    box(street,"SideAlley",Vector3(14,.2,4),Vector3(-(width/2+walk+7),-.1,-32),road,true)
    var fh: float = config.floor_height
    for row in [["BlueFront",-11,-5,14,5,blue],["OldLeftA",-11,-20,13,5,cream],["OldLeftB",-11,-43,18,6,grey],["OldLeftC",-11,-58,10,4,cream],["OrangeFront",11,-6,16,6,orange],["OrangeMid",11,-23,15,5,orange],["RightOld",11,-40,16,6,grey],["RightFar",11,-56,14,5,cream]]:
        building(buildings,row[0],sign(row[1])*(width/2+walk+5),row[2],row[3],row[4],fh,row[5])
    box(buildings,"DistantBlock",Vector3(22,16,8),Vector3(1,8,-77),grey)
    var sign_at := v(config.sign_position)
    box(landmarks,"VerticalSignFrame",v(config.sign_size),sign_at,gold)
    box(landmarks,"VerticalSignFace",Vector3(config.sign_size[0]-.23,config.sign_size[1]-.25,.39),sign_at,dark)
    # Four broad proxy glyph tiles establish sign rhythm; not final lettering.
    for i in 4:
        box(landmarks,"SignGlyphProxy",Vector3(1.1,.85,.10),sign_at+Vector3(0,2.65-i*1.75,.25),gold)
    for y in [7.2,14.2]:
        box(landmarks,"SignBracket",Vector3(1.8,.12,.16),Vector3(-5.65,y,-15),dark)
    for spec in [["PROP_HYDRANT_A01",Vector3(5.1,.16,-1.5),0],["PROP_BIN_A01",Vector3(-5.1,.16,-29),0],["VEH_VAN_A01",Vector3(2.8,0,-8),0],["PROP_SHOP_STOOL_A01",Vector3(-5.3,.16,-19),15],["PROP_CRATES_A01",Vector3(-5.2,.16,-21),0],["PROP_MAILBOX_A01",Vector3(5.25,.16,-18),180]]:
        var packed: PackedScene = load("res://scenes/"+spec[0]+".tscn")
        var instance := packed.instantiate()
        instance.name = spec[0]
        props.add_child(instance)
        instance.owner = root_node
        instance.position = spec[1]
        instance.rotation_degrees.y = spec[2]
    make_aircraft(aircraft,config)
    var cameras := node(root_node,"ReferenceCameras")
    for spec in config.cameras:
        var camera := Camera3D.new()
        camera.name = spec.id
        cameras.add_child(camera)
        camera.owner = root_node
        camera.position = v(spec.position)
        camera.basis = Basis.looking_at(v(spec.target)-v(spec.position),Vector3.FORWARD if spec.has("orthographic_size") else Vector3.UP)
        camera.set_meta("label",spec.label)
        camera.keep_aspect = Camera3D.KEEP_HEIGHT
        if spec.has("orthographic_size"):
            camera.projection = Camera3D.PROJECTION_ORTHOGONAL
            camera.size = spec.orthographic_size
            camera.cull_mask = 1
        else:
            camera.fov = spec.fov
        camera.far = 500
    var environment := WorldEnvironment.new()
    environment.name = "WorldEnvironment"
    environment.environment = Environment.new()
    environment.environment.background_mode = Environment.BG_COLOR
    environment.environment.background_color = Color("80c4e7")
    environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.environment.ambient_light_color = Color("c5dced")
    environment.environment.ambient_light_energy = .65
    root_node.add_child(environment)
    environment.owner = root_node
    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-48,-32,0)
    sun.light_energy = 1.0
    sun.shadow_enabled = true
    root_node.add_child(sun)
    sun.owner = root_node
    var overlay := CanvasLayer.new()
    overlay.name = "Overlay"
    root_node.add_child(overlay)
    overlay.owner = root_node
    var help := Label.new()
    help.name = "Help"
    help.position = Vector2(18,16)
    help.add_theme_color_override("font_color",Color.WHITE)
    help.add_theme_color_override("font_shadow_color",Color.BLACK)
    help.add_theme_constant_override("shadow_offset_x",1)
    help.add_theme_constant_override("shadow_offset_y",1)
    overlay.add_child(help)
    help.owner = root_node
    var packed := PackedScene.new()
    var error := packed.pack(root_node)
    if error == OK:
        error = ResourceSaver.save(packed,"res://scenes/street_whitebox.tscn")
    if error != OK:
        push_error("Whitebox save failed: "+str(error))
        quit(1)
        return
    print("WHITEBOX_BUILT ",config.street_length,"m; cameras=5; props=6")
    quit(0)
