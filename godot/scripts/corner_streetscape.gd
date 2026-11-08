extends Node3D
## Reversible street-corner dressing. Coordinates match the unscaled S1 street.
## Material/mesh batches share draw calls; large solids alone receive collision.
const TOON = preload("res://shaders/sample_toon.gdshader")
const PLASTER = preload("res://assets/textures/corner_plaster_128.png")
const TILES = preload("res://assets/textures/corner_tiles_128.png")
const SHUTTER = preload("res://assets/textures/corner_shutter_128.png")
const ROAD = preload("res://assets/textures/road_asphalt_128.png")
const SIDEWALK = preload("res://assets/textures/sidewalk_tiles_128.png")
var groups: Dictionary = {}
var detail_bounds: Array[AABB] = []
var building_bounds: Array[AABB] = []
var zone_counts: Dictionary = {}
var collision_count := 0
var instance_count := 0
var batch_count := 0
var retained_materials: Array[ShaderMaterial] = []
var material_cache: Dictionary = {}
var zone := "front_left"
const INK := Color("30434a")
const IVORY := Color("d5d5b9")
const GLASS := Color("214452")
const RUST := Color("8b6650")

func _ready() -> void:
    name="CornerStreetscape"
    _front_left()
    _front_right()
    _neighbors()
    _corner_signs()
    _street_objects()
    _road_finish()
    _flush()

func _emit(role: String, shape: String, at: Vector3, size: Vector3, tint: Color, angles := Vector3.ZERO) -> void:
    var key := role+"/"+shape
    if not groups.has(key): groups[key]=[]
    var pose := Transform3D(Basis.from_euler(angles).scaled_local(size),at)
    groups[key].append({"pose":pose,"tint":tint})
    detail_bounds.append(pose*AABB(Vector3.ONE*-.5,Vector3.ONE))
    instance_count+=1
    zone_counts[zone]=zone_counts.get(zone,0)+1

func _box(role: String, at: Vector3, size: Vector3, tint: Color, angles := Vector3.ZERO) -> void:
    _emit(role,"box",at,size,tint,angles)

func _bar(start: Vector3, end: Vector3, width: float, tint := INK) -> void:
    var offset := end-start
    if offset.length()<0.001: return
    var key := "solid/box"
    if not groups.has(key): groups[key]=[]
    var pose := Transform3D(Basis(Quaternion(Vector3.UP,offset.normalized())).scaled_local(Vector3(width,offset.length(),width)),(start+end)*.5)
    groups[key].append({"pose":pose,"tint":tint})
    detail_bounds.append(pose*AABB(Vector3.ONE*-.5,Vector3.ONE))
    instance_count+=1
    zone_counts[zone]=zone_counts.get(zone,0)+1

func _collision(label: String, at: Vector3, size: Vector3, yaw := 0.0) -> void:
    var body := StaticBody3D.new()
    body.name=label
    body.position=at
    body.rotation.y=yaw
    var shape := BoxShape3D.new()
    shape.size=size
    var collider := CollisionShape3D.new()
    collider.shape=shape
    body.add_child(collider)
    add_child(body)
    collision_count+=1

func _window(x: float, y: float, face: float, width: float, height: float, cage: bool, variant: int) -> void:
    _box("solid",Vector3(x,y,face+.045),Vector3(width+.16,height+.16,.09),INK)
    _box("glass",Vector3(x,y,face+.104),Vector3(width,height,.032),GLASS if variant%3 else Color("375560"))
    for dx in [-width*.5,width*.5]:
        _box("solid",Vector3(x+dx,y,face+.14),Vector3(.065,height+.12,.075),IVORY)
    for dy in [-height*.5,height*.5]:
        _box("solid",Vector3(x,y+dy,face+.14),Vector3(width+.1,.065,.075),IVORY)
    _box("solid",Vector3(x,y,face+.152),Vector3(.055,height,.07),IVORY)
    if variant%4==0:
        _box("solid",Vector3(x+width*.24,y,face+.17),Vector3(width*.42,height-.12,.025),Color("aab6aa"))
    else:
        _box("solid",Vector3(x-width*.3,y+height*.23,face+.17),Vector3(width*.11,height*.44,.018),Color("54818b"))
    if cage:
        var front := face+.43
        for dx in [-width*.56,width*.56]:
            _bar(Vector3(x+dx,y-height*.57,face+.15),Vector3(x+dx,y-height*.57,front),.045)
            _bar(Vector3(x+dx,y-height*.57,front),Vector3(x+dx,y+height*.56,front),.035)
        for dy in [-height*.57,height*.10,height*.56]:
            _bar(Vector3(x-width*.56,y+dy,front),Vector3(x+width*.56,y+dy,front),.035)
        for i in 5:
            var bx := x-width*.45+i*width*.225
            _bar(Vector3(bx,y-height*.57,front),Vector3(bx,y+height*.56,front),.022)

func _aircon(x: float,y: float,face: float, variant: int) -> void:
    _box("solid",Vector3(x,y,face+.28),Vector3(.94,.55,.50),Color("c1c7b6"))
    _box("solid",Vector3(x+.18,y,face+.542),Vector3(.39,.36,.024),INK)
    for i in 4:
        _box("solid",Vector3(x-.31+i*.07,y,face+.548),Vector3(.025,.31,.025),Color("5d7478"))
    _emit("solid","cylinder",Vector3(x+.18,y,face+.563),Vector3(.29,.018,.29),Color("849794"),Vector3(PI*.5,0,0))
    for dx in [-.34,.34]:
        _bar(Vector3(x+dx,y-.3,face+.05),Vector3(x+dx,y-.3,face+.49),.05,RUST)
    _box("solid",Vector3(x-.23,y-.62,face+.017),Vector3(.045,.66,.018),Color("738278") if variant%2 else Color("9b9c80"))

func _awning(x: float, face: float, width: float, depth: float, tint: Color) -> void:
    var center_z := face+depth*.5
    _box("shutter",Vector3(x,3.02,center_z),Vector3(width,.105,depth),tint,Vector3(.12,0,0))
    _box("solid",Vector3(x,2.86,face+depth),Vector3(width,.25,.065),tint.darkened(.13))
    for i in 5:
        var sx := x-width*.40+i*width*.20
        _box("solid",Vector3(sx,3.084,center_z),Vector3(width*.07,.016,depth*.94),IVORY,Vector3(.12,0,0))
    for dx in [-width*.43,width*.43]:
        _bar(Vector3(x+dx,3.34,face+.05),Vector3(x+dx,2.98,face+depth*.90),.045)

func _shop(x: float,face: float,width: float,closed: bool,tint: Color) -> void:
    _box("solid",Vector3(x,1.42,face+.045),Vector3(width,2.65,.09),Color("233b40"))
    _box("tiles",Vector3(x,.50,face+.11),Vector3(width-.08,.95,.10),Color("adb6a7"))
    if closed:
        _box("shutter",Vector3(x,1.69,face+.12),Vector3(width-.24,2.05,.08),Color("a1aca1"))
    else:
        _box("glass",Vector3(x,1.70,face+.13),Vector3(width-.22,2.10,.07),Color("193b41"))
        for dx in [-width*.22,width*.22]:
            _box("solid",Vector3(x+dx,1.55,face+.20),Vector3(.055,2.35,.08),IVORY)
        _box("solid",Vector3(x,1.16,face+.24),Vector3(width-.24,.12,.16),Color("838c76"))
        _box("solid",Vector3(x,2.63,face+.21),Vector3(width*.72,.035,.055),Color("b2d6ba"))
    # Blank fronts are intentionally ready for the user's later sign textures.
    _box("solid",Vector3(x,3.46,face+.13),Vector3(width+.12,.58,.18),IVORY)
    _box("solid",Vector3(x,3.46,face+.24),Vector3(width-.04,.43,.045),tint)

func _balcony(x: float, y: float, face: float, width: float, tint: Color, plants: bool) -> void:
    _box("plaster",Vector3(x,y,face+.42),Vector3(width,.20,.96),tint)
    for dx in [-width*.46,width*.46]:
        _box("plaster",Vector3(x+dx,y+.58,face+.46),Vector3(.14,1.10,.80),tint)
    for dy in [.18,.92]:
        _bar(Vector3(x-width*.46,y+dy,face+.90),Vector3(x+width*.46,y+dy,face+.90),.055,Color("8a9d91"))
    for i in 10:
        var rx := x-width*.44+i*width*.88/9.0
        _bar(Vector3(rx,y+.18,face+.90),Vector3(rx,y+.92,face+.90),.027,Color("788d82"))
    for dx in [-width*.34,width*.34]:
        _bar(Vector3(x+dx,y-.12,face+.76),Vector3(x+dx,y-.62,face+.02),.09,tint.darkened(.16))
    if plants:
        for i in 5:
            var px := x-width*.34+i*width*.17
            _box("solid",Vector3(px,y+.27,face+.55),Vector3(.30,.29,.30),Color("8f6f4e"))
            _box("solid",Vector3(px,y+.55,face+.55),Vector3(.42,.37+.07*(i%2),.36),Color("627f4a") if i%2 else Color("78904e"))

func _pipe(x: float,top: float,face: float,tint: Color) -> void:
    _bar(Vector3(x,.3,face+.10),Vector3(x,top,face+.10),.09,tint)
    for y in [1.2,4.4,7.6,10.8,14.0]:
        if y>top: continue
        _box("solid",Vector3(x,y,face+.16),Vector3(.22,.055,.09),INK)

func _aerial(x: float,y: float,z: float) -> void:
    _bar(Vector3(x,y,z),Vector3(x,y+1.7,z),.042)
    _bar(Vector3(x-.8,y+1.20,z),Vector3(x+.8,y+1.20,z),.032)
    for i in 5:
        var ax := x-.6+i*.3
        _bar(Vector3(ax,y+1.20,z-.29),Vector3(ax,y+1.20,z+.29),.025)
    _bar(Vector3(x,y+.40,z),Vector3(x+.46,y+.9,z+.20),.035)

func _front_left() -> void:
    zone="front_left"
    for x in [-14.6,-12.2,-7.0]:
        for floor_index in 4:
            var y := 5.6+floor_index*3.05
            _window(x,y,2.035,1.28,1.42,x<-10 or floor_index%2==0,floor_index+int(absf(x)))
            if floor_index%2==0 or x<-12:
                _aircon(x+.25,y-.96,2.035,floor_index)
    _box("tiles",Vector3(-11,.60,2.08),Vector3(9.92,1.18,.10),Color("6e8b8a"))
    for x in [-14.25,-11.6,-7.12]:
        _shop(x,2.035,2.16,x<-13,Color("395f66") if x<-10 else Color("a16a4b"))
        _awning(x,2.035,2.30,1.00 if x<-10 else .24,Color("aa6b50") if x<-13 else Color("6c887b"))
    for x in [-15.77,-10.72,-6.25]: _pipe(x,15.5,2.035,Color("607c7d"))
    for i in 13:
        var x := -15.4+float((i*19)%41)*.21
        var y := 1.4+float((i*13)%29)*.41
        if x>-10.3 and x<-7.8 and y>5: continue
        _box("solid",Vector3(x,y,2.042),Vector3(.12+(i%3)*.10,.32+(i%4)*.14,.012),Color("6c9296") if i%2 else Color("497e8c"))
    _box("plaster",Vector3(-13.2,16.58,-1.1),Vector3(4.3,.20,5.9),Color("9bad9f"))
    for x in [-14.4,-7.3]: _aerial(x,16.7,-1.3)

func _front_right() -> void:
    zone="front_right"
    for floor_index in 5:
        var y := 5.64+floor_index*3.0
        _window(12.65,y,2.04,4.8,1.85,false,floor_index)
        _balcony(12.65,y-1.04,2.04,5.1,Color("d37856"),floor_index in [0,2])
        if floor_index%2==0: _aircon(15.3,y+.14,2.04,floor_index)
    for x in [6.42,10.12,15.65]:
        _box("tiles",Vector3(x,1.55,2.12),Vector3(.44,3.05,.25),Color("a9a58e"))
    for x in [8.25,12.65]:
        _shop(x,2.03,3.1,false,Color("855f45"))
        _awning(x,2.035,3.25,.24 if x<9 else 1.05,Color("c69c69"))
    for y in [4.55,7.55,10.55,13.55]:
        for x in [6.95,10.45]:
            _bar(Vector3(x,y,2.14),Vector3(x,y,2.65),.065,Color("958d69"))
            for dx in [-.18,.18]:
                _bar(Vector3(x,y,2.62),Vector3(x+dx,y+.28,2.62),.045,Color("958d69"))
                _emit("bulb","sphere",Vector3(x+dx,y+.36,2.62),Vector3.ONE*.29,Color("f3e5b8"))
    _pipe(15.81,19.2,2.04,Color("a47858"))
    _aerial(14.8,19.9,-.8)

func _neighbors() -> void:
    var specs := [
        [-20.3,8.6,15.5,2.00,Color("a5ab96"),false],
        [-28.0,6.8,18.1,1.65,Color("8b9e94"),true],
        [-34.9,7.0,13.6,1.25,Color("bcb79c"),false],
        [20.2,8.4,17.4,1.75,Color("a3a591"),true],
        [27.9,7.0,20.1,1.50,Color("8f9f99"),false],
        [34.8,6.8,15.0,1.25,Color("c0bca3"),true]]
    for index in specs.size():
        var spec: Array=specs[index]
        var x: float=spec[0]
        var width: float=spec[1]
        var height: float=spec[2]
        var face: float=spec[3]
        var tint: Color=spec[4]
        zone="neighbors_left" if x<0 else "neighbors_right"
        var at:=Vector3(x,height*.5,face-7.0)
        var size:=Vector3(width,height,14.0)
        _box("plaster",at,size,tint)
        _collision("NeighborBuilding_"+str(index),at,size)
        building_bounds.append(AABB(at-size*.5,size))
        _box("plaster",Vector3(x,height+.08,face-6.5),Vector3(width+.15,.19,13.5),tint.lightened(.12))
        var floors:=int((height-3.5)/3.0)
        for floor_index in floors:
            var y:=5.05+floor_index*3.0
            for column in 3:
                var wx:=x+(column-1)*width*.29
                _window(wx,y,face+.03,width*.225,1.57,true,index+column+floor_index)
                if (column+floor_index+index)%3==0: _aircon(wx+.12,y-.97,face+.03,column)
            if floor_index%2==index%2:
                _balcony(x,y-1.06,face+.03,width*.86,tint.darkened(.05),floor_index==1)
        for sx in [-width*.47,width*.46]: _pipe(x+sx,height-.4,face+.03,Color("708276"))
        for column in 2:
            var shop_x:=x+(column-.5)*width*.47
            _shop(shop_x,face+.03,width*.44,column==index%2,Color("a66451") if index%2 else Color("466c69"))
            _awning(shop_x,face+.03,width*.46,1.15,Color("a75b4c") if index%2 else Color("a59a78"))
        _aerial(x-width*.22,height+.2,face-1.0)
        # Patches are broad, low-contrast paint chips, not a full-screen noise layer.
        for i in 7:
            var px:=x-width*.38+float((i*7+index)%13)*width*.055
            var py:=2.0+float((i*5+index)%19)*.62
            if py>height-.8:continue
            _box("solid",Vector3(px,py,face+.012),Vector3(.24+(i%2)*.23,.44+(i%3)*.26,.018),tint.darkened(.11))
    # Cross-street extensions sit outside the original 40 m roadway.
    zone="sidewalks"
    for side in [-1,1]:
        _box("road",Vector3(side*31.0,-.10,7.0),Vector3(22.0,.20,18.0),Color("616d73"))
        _box("pavement",Vector3(side*28.0,.08,2.65),Vector3(24.0,.16,2.30),Color("abae9c"))
        _collision("CornerSidewalk_"+str(side),Vector3(side*28.0,.08,2.65),Vector3(24.0,.16,2.30))
        _box("solid",Vector3(side*28.0,.10,3.83),Vector3(24.0,.20,.10),Color("c0bea9"))

func _scooter(at: Vector3,yaw: float,tint: Color,index: int) -> void:
    var basis:=Basis(Vector3.UP,yaw)
    for z in [-.59,.59]:
        _emit("solid","cylinder",at+basis*Vector3(0,.28,z),Vector3(.50,.17,.50),Color("293b40"),Vector3(0,yaw,PI*.5))
    for spec in [[Vector3(0,.57,0),Vector3(.43,.38,1.28),tint],[Vector3(0,.91,.22),Vector3(.45,.14,.74),INK],[Vector3(0,.84,-.51),Vector3(.43,.72,.20),tint],[Vector3(0,1.18,-.65),Vector3(.56,.055,.07),INK]]:
        _box("solid",at+basis*spec[0],spec[1],spec[2],Vector3(0,yaw,0))
    _bar(at+basis*Vector3(0,.36,-.55),at+basis*Vector3(0,1.16,-.62),.055)
    _emit("bulb","sphere",at+basis*Vector3(0,.96,-.64),Vector3(.21,.20,.10),IVORY,Vector3(0,yaw,0))
    _collision("ParkedScooter_"+str(index),at+Vector3(0,.65,0),Vector3(.60,1.30,1.55),yaw)

func _street_objects() -> void:
    zone="street_objects"
    _scooter(Vector3(-18.1,.16,3.30),1.30,Color("457b80"),0)
    _scooter(Vector3(-25.4,.16,3.30),1.68,Color("a55f4f"),1)
    for x in [-12.1,-20.0,19.4,25.2]:
        _box("solid",Vector3(x,.65,2.73),Vector3(.80,1.0,.42),Color("9d855f"))
        _box("solid",Vector3(x,.65,2.97),Vector3(.65,.82,.035),Color("456b68"))
        for dx in [-.32,.32]:
            _bar(Vector3(x+dx,.16,3.04),Vector3(x+dx,1.19,2.72),.045,Color("89734c"))
        _box("solid",Vector3(x+.62,.42,2.72),Vector3(.56,.52,.43),Color("ab9270"))
        for dy in [-.15,.15]:
            _box("solid",Vector3(x+.62,.42+dy,2.95),Vector3(.53,.045,.035),Color("77694f"))
    for side in [-1,1]:
        for i in 2:
            var x: float=side*(17.4+i*5.7)
            _box("solid",Vector3(x,.38,2.80),Vector3(.42,.44,.42),Color("927759"))
            _emit("solid","sphere",Vector3(x,.86,2.80),Vector3(.68,.68,.58),Color("698652"))
    for side in [-1,1]:
        var vehicle: Node3D=preload("res://scenes/VEH_CAR_A01.tscn").instantiate()
        vehicle.name="CrossStreetCar_"+str(side)
        vehicle.position=Vector3(side*23.1,0,5.0)
        vehicle.rotation.y=PI*.5
        add_child(vehicle)
    # Slightly sagging overhead bundles and shop-side junction boxes.
    for side in [-1,1]:
        var start:=Vector3(side*15.9,9.6,2.30)
        for i in 5:
            var a:=start+Vector3(side*i*1.6,-sin(i*PI/5)*.34,0)
            var b:=start+Vector3(side*(i+1)*1.6,-sin((i+1)*PI/5)*.34,0)
            _bar(a,b,.027)
        _box("solid",Vector3(side*15.7,3.85,2.22),Vector3(.50,.76,.22),Color("8b9c94"))

func _corner_signs() -> void:
    # Deliberately sparse silhouettes; these anchors accept user artwork later.
    zone="signs"
    for spec in [[-17.4,5.6,2.0,1.0,1.8,"LeftCornerBlade",Color("936d43")],[-26.4,4.6,1.65,1.35,.85,"LeftOuterBlade",Color("527b76")],[17.5,5.0,1.95,1.1,1.35,"RightCornerBlade",Color("547679")],[26.6,5.4,1.6,1.3,.9,"RightOuterBlade",Color("99634e")]]:
        var x: float=spec[0]
        var y: float=spec[1]
        var face: float=spec[2]
        var width: float=spec[3]
        var height: float=spec[4]
        var front:=face+1.02
        _box("solid",Vector3(x,y,front),Vector3(width+.12,height+.12,.16),IVORY)
        _box("solid",Vector3(x,y,front+.095),Vector3(width,height,.04),spec[6])
        for dx in [-width*.32,width*.32]:
            _bar(Vector3(x+dx,y+height*.5,face+.05),Vector3(x+dx,y+height*.5,front),.055)
            _bar(Vector3(x+dx,y+height*.5+.42,face+.05),Vector3(x+dx,y+height*.5,front),.045)
        var anchor:=Node3D.new()
        anchor.name=spec[5]
        anchor.position=Vector3(x,y,front+.12)
        anchor.set_meta("artwork_size_m",Vector2(width,height))
        anchor.set_meta("texture_status","blank_pending_user_artwork")
        add_child(anchor)

func _road_finish() -> void:
    zone="road_finish"
    for spec in [[-4.9,6.8,2.8,1.1,.07],[4.6,6.3,2.0,1.5,-.12],[-11.2,5.0,3.0,1.0,.10],[10.8,5.3,2.4,.8,-.08]]:
        _box("road",Vector3(spec[0],.006,spec[1]),Vector3(spec[2],.009,spec[3]),Color("52636a"),Vector3(0,spec[4],0))
    _emit("solid","cylinder",Vector3(.35,.014,6.6),Vector3(.92,.020,.92),Color("485a61"))
    for i in 7:
        var offset: float=(i-3)*.105
        var length:=2.0*sqrt(.39*.39-offset*offset)
        _box("solid",Vector3(.35,.028,6.6+offset),Vector3(length,.008,.018),Color("788282"))
    for x in [-10.5,10.5,-18.0,18.0]:
        _box("solid",Vector3(x,.014,3.92),Vector3(.85,.024,.33),INK)
        for i in 7:
            _box("solid",Vector3(x-.33+i*.11,.032,3.92),Vector3(.035,.012,.28),Color("8d998f"))

func _flat_mesh(primitive: PrimitiveMesh) -> ArrayMesh:
    var arrays:=primitive.surface_get_arrays(0)
    var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
    var source_normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
    var result:=SurfaceTool.new()
    result.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(0,indices.size(),3):
        var a:=vertices[indices[i]]
        var b:=vertices[indices[i+1]]
        var c:=vertices[indices[i+2]]
        var normal: Vector3=(b-a).cross(c-a).normalized()
        if normal.dot(source_normals[indices[i]])<0: normal=-normal
        for point in [a,b,c]:
            result.set_normal(normal)
            result.add_vertex(point)
    return result.commit()

func _material(role: String) -> ShaderMaterial:
    if material_cache.has(role): return material_cache[role]
    var material:=ShaderMaterial.new()
    material.shader=TOON
    if role=="bulb":
        var bulb_shader:=Shader.new()
        bulb_shader.code=TOON.code.replace("render_mode diffuse_lambert, specular_disabled;","render_mode unshaded;")
        material.shader=bulb_shader
    material.set_shader_parameter("base_color",Color.WHITE)
    material.set_shader_parameter("use_instance_color",true)
    material.set_shader_parameter("shadow_tint",Vector3(.42,.57,.70))
    var textures: Dictionary={"plaster":PLASTER,"tiles":TILES,"shutter":SHUTTER,"road":ROAD,"pavement":SIDEWALK}
    if textures.has(role):
        material.set_shader_parameter("use_texture",true)
        material.set_shader_parameter("use_world_uv",true)
        material.set_shader_parameter("world_texture",textures[role])
        material.set_shader_parameter("texture_scale",Vector3.ONE*(.25 if role in ["plaster","road"] else .5))
    retained_materials.append(material)
    material_cache[role]=material
    return material

func _flush() -> void:
    var box:=BoxMesh.new()
    box.size=Vector3.ONE
    var sphere:=SphereMesh.new()
    sphere.radius=.5
    sphere.height=1.0
    sphere.radial_segments=8
    sphere.rings=3
    var cylinder:=CylinderMesh.new()
    cylinder.top_radius=.5
    cylinder.bottom_radius=.5
    cylinder.height=1.0
    cylinder.radial_segments=12
    var meshes: Dictionary={"box":box,"sphere":_flat_mesh(sphere),"cylinder":_flat_mesh(cylinder)}
    for key in groups:
        var parts: PackedStringArray=key.split("/")
        var entries: Array=groups[key]
        var multimesh:=MultiMesh.new()
        multimesh.transform_format=MultiMesh.TRANSFORM_3D
        multimesh.use_colors=true
        multimesh.mesh=meshes[parts[1]]
        multimesh.instance_count=entries.size()
        for i in entries.size():
            multimesh.set_instance_transform(i,entries[i].pose)
            multimesh.set_instance_color(i,entries[i].tint)
        var instance:=MultiMeshInstance3D.new()
        instance.name="CornerBatch_"+key.replace("/","_")
        instance.multimesh=multimesh
        instance.material_override=_material(parts[0])
        instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if parts[0]=="plaster" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(instance)
        batch_count+=1
    groups.clear()
