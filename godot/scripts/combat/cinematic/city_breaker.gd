extends Node3D
## KO presentation only. Uses the live stage/roster; never writes simulation state.
## Closed-form paths allow frame-independent playback, capture and complete rollback.
const DURATION := 10.0
const CUTS := [0.0, 13.0/24, 43.0/24, 83.0/24, 125.0/24, 149.0/24, 172.0/24, 189.0/24, 10.0]
const SHOTS := ["LAUNCH", "WALL BREAK", "STREET RUSH", "CHAIN REACTION", "SKYWARD", "AIRCRAFT HIT", "AIRBURST", "K.O."]
var session: Node3D
var running := false
var age := 0.0
var winner := 0
var victim := 1
var shot := 0
var origin := Vector3.ZERO
var handedness := 1.0
var container: Node3D
var pieces: Array[Dictionary] = []
var bursts: Array[Dictionary] = []
var batches: Array[Dictionary] = []
var hidden_sources: Array[Dictionary] = []
var plane_state: Dictionary = {}
var actor_states: Array[Dictionary] = []
var camera_state: Dictionary = {}
var wave: MeshInstance3D
var sky_wave: MeshInstance3D
var ring: MeshInstance3D
var plane_copy: Node3D
var rng := RandomNumberGenerator.new()
var body_position := Vector3.ZERO
var cues_fired: Dictionary = {}
var burst_materials: Array[Material] = []
var prepared := false

func setup(owner_session: Node3D) -> void:
    session = owner_session
    name = "CityBreaker"
    container = Node3D.new()
    container.name = "ReversibleDestruction"
    add_child(container)
    container.hide()

func active() -> bool:
    return running

func begin(side: int) -> void:
    clear()
    winner = clampi(side, 0, 1)
    victim = 1 - winner
    # This is an authored down-street cinematic, independent of combat facing.
    handedness = 1.0 if session.sim.fighters[victim].x >= 0.0 else -1.0
    origin = Vector3(session.sim.fighters[victim].x, maxf(0.0, session.sim.fighters[victim].y), session.FIGHT_Z)
    actor_states.clear()
    for actor in session.fighters:
        actor_states.append({"node": actor, "transform": actor.transform, "visible": actor.visible})
    var plane: Node3D = session.backdrop.plane
    plane_state = {"transform": plane.transform, "visible": plane.visible, "frozen": session.backdrop.frozen}
    camera_state = {"transform": session.camera.transform, "fov": session.camera.fov, "far": session.camera.far, "environment": session.camera.environment}
    session.backdrop.frozen = true
    # Reposition this SAME aircraft for the authored sequence; restore after it.
    plane.position = Vector3(-2, 48, -70)
    plane.rotation_degrees = Vector3(0, -145, 0)
    plane.visible = true
    if not prepared:
        _prepare()
        prepared = true
    else:
        # Cached shards use the same live aircraft pose on every playback.
        plane_copy.transform = plane.transform
    rng.seed = 640360
    age = 0.0
    shot = 0
    running = true
    cues_fired.clear()
    container.show()
    sample(0.0)

func advance(delta: float, paused: bool) -> void:
    if not running:
        return
    if paused:
        sample(age)
        return
    var previous := age
    age = minf(DURATION, age + maxf(delta, 0.0))
    # Crossing-based events fire once even if a rendered frame crosses two cues.
    var cues := [[0.0, "launch", 1.0], [.82, "heavy", .75], [1.72, "guard_break", .8], [2.82, "slam", .75], [3.18, "slam", .9], [3.65, "slam", 1.0], [5.05, "chase", 1.0], [6.4, "guard_break", .7], [172.0/24, "slam", .65], [7.3, "sub", .65], [8.0, "ko", 1.0]]
    for i in cues.size():
        if age >= cues[i][0] and (previous <= cues[i][0]) and not cues_fired.has(i):
            cues_fired[i] = true
            session.audio.play_sound(cues[i][1], cues[i][2], -5.0)
    sample(age)
    if age >= DURATION:
        clear()

func sample(time: float) -> void:
    if not running:
        return
    age = clampf(time, 0.0, DURATION)
    shot = 0
    for i in SHOTS.size():
        if age >= CUTS[i]: shot = i
    var u := clampf((age - CUTS[shot]) / (CUTS[shot + 1] - CUTS[shot]), 0.0, 1.0)
    session.backdrop.visible = true
    session.camera.environment = null
    session.camera.far = 350.0
    session.backdrop.plane.visible = age < 6.4
    plane_copy.visible = age >= 6.4
    _sources_at(age)
    _pieces_at(age)
    _bursts_at(age)
    _wave_at(age)
    _actors_at(age)
    _camera_at(u)
    for shadow in session.silhouettes: shadow.visible = false

func victim_path(time: float) -> Vector3:
    var points := [origin + Vector3(0, .7, 0), Vector3(handedness*4.6, 7.5, -5), Vector3(handedness*3.5, 10.5, -12), Vector3(handedness*2.0, 16, -27), Vector3(handedness*1.0, 28, -42), Vector3(-handedness*3.0, 39, -48), Vector3(-handedness*5, 43, -55), Vector3(-handedness*8, 37, -64), Vector3(-handedness*10, 28, -70)]
    var times := [0.0, .82, 43.0/24, 83.0/24, 125.0/24, 149.0/24, 172.0/24, 189.0/24, 10.0]
    for i in range(times.size()-1):
        if time <= times[i+1]:
            var t := clampf((time-times[i])/(times[i+1]-times[i]), 0.0, 1.0)
            return points[i].lerp(points[i+1], t)
    return points[-1]

func _actors_at(time: float) -> void:
    body_position = victim_path(time)
    var actor: Node3D = session.fighters[victim]
    actor.visible = shot not in [5, 6]
    actor.position = body_position
    actor.rotation = Vector3(.55 + time*.82, handedness*.55, -.8 + time*.34)
    actor.model.position = Vector3.ZERO
    actor.model.rotation = Vector3.ZERO
    actor.model.scale = Vector3.ONE * actor.model_scale * (1.6 if time < 83.0/24 else 2.2)
    # Retarget through the existing skeleton owner; no named model is baked in.
    var m = actor.motions
    if is_instance_valid(actor.skeleton):
        var up: Vector3 = m.model_up
        var fwd: Vector3 = m.model_forward
        m._aim_limb("LeftArm", "LeftForeArm", up*.45-fwd, 1.0)
        m._aim_limb("LeftForeArm", "LeftHand", up+fwd*.2, 1.0)
        m._aim_limb("RightArm", "RightForeArm", -up*.15+fwd, 1.0)
        m._aim_limb("RightForeArm", "RightHand", up*.7+fwd*.5, 1.0)
        m._aim_limb("LeftUpLeg", "LeftLeg", -up+fwd*.8, 1.0)
        m._aim_limb("LeftLeg", "LeftFoot", -up-fwd*.5, 1.0)
        m._aim_limb("RightUpLeg", "RightLeg", -up-fwd*.4, 1.0)
        m._aim_limb("RightLeg", "RightFoot", -up+fwd, 1.0)
    # Obscure identity in long shots without substituting another person's model.
    actor.set_neon_silhouette(false)
    for mat in actor.materials:
        if actor.neon_enabled:
            mat.set_shader_parameter("ko_silhouette", true)
            mat.set_shader_parameter("tint", Color("222032"))
        mat.set_shader_parameter("flash", 0.0)
    var hero: Node3D = session.fighters[winner]
    hero.visible = time >= 189.0/24
    if hero.visible:
        hero.position = Vector3(-handedness*2.3, 0, 3)
        hero.rotation = Vector3(0, handedness*.8, 0)

func _camera_at(u: float) -> void:
    var p := Vector3.ZERO
    var target := Vector3.ZERO
    var roll := 0.0
    var fov := 65.0
    match shot:
        0:
            p = Vector3(0, 1.6, 16).lerp(Vector3(-.6, 2.3, 14), u)
            target = Vector3(0, 5, -19).lerp(Vector3(handedness*2, 8, -20), u)
            fov = 68
        1:
            p = body_position + Vector3(-handedness*5.5, 1.5, 7).lerp(Vector3(-handedness*5, 2, 6), u)
            target = body_position + Vector3(0, 1, 0)
            roll = handedness * -.12
            fov = 61
        2:
            p = Vector3(-handedness*1.2, 1.6, 4).lerp(Vector3(handedness*.6, 2.8, -15), u)
            target = body_position + Vector3(0, -3, -5)
            roll = handedness * .08 * sin(u*PI)
            fov = 78
        3:
            p = Vector3(-handedness*25, 36, 14).lerp(Vector3(-handedness*28, 42, 1), u)
            target = Vector3(0, 13, -27).lerp(Vector3(0, 20, -36), u)
            fov = 66
        4:
            p = Vector3(handedness*1.5, 9, -23).lerp(Vector3(handedness, 14, -30), u)
            target = body_position.lerp(Vector3(-2, 48, -70), u*.65)
            roll = -.13*handedness
            fov = 79
        5:
            p = Vector3(-32, 35, -35).lerp(Vector3(-28, 36, -37), u)
            target = Vector3(-2, 48, -70)
            fov = 62
            roll = -.08
        6:
            p = Vector3(-35, 36, -30).lerp(Vector3(-39, 35, -25), u)
            target = Vector3(-2, 48, -70)
            fov = 70
        7:
            p = Vector3(0, 2.0, 16).lerp(Vector3(-handedness*.7, 1.7, 15), u)
            target = Vector3(0, 5.8, -20)
            fov = 70
    var shake := 0.0
    for hit in [.82, 1.72, 2.82, 3.18, 3.65, 6.4, 172.0/24, 8.0]:
        var dt: float = age-hit
        if dt >= 0 and dt < .3: shake += .16*exp(-dt*12)
    if not session.reduced_effects:
        p += Vector3(sin(age*117)*shake, cos(age*93)*shake*.6, 0)
    session.camera.position = p
    session.camera.look_at(target)
    session.camera.rotation.z = roll
    session.camera.fov = fov

func _prepare() -> void:
    rng.seed = 640360
    var specs := [["OrangeFront", .82], ["BlueFront", .82], ["OldLeftA", 1.72], ["OrangeMid", 2.82], ["OldLeftB", 3.18], ["RightOld", 3.65]]
    for spec in specs:
        var body: MeshInstance3D = session.backdrop.street.get_node("BuildingMasses/"+spec[0])
        var bounds: AABB = body.global_transform * body.get_aabb()
        _break_building(body, bounds, spec[1])
        _make_burst(Vector3(signf(body.position.x)*8.2, minf(12,body.position.y), body.position.z-3), spec[1], 3.5)
    _collect_batch_details()
    _extend_city()
    _ground_rubble()
    _prepare_plane()
    _make_burst(Vector3(-2,48,-70), 6.4, 10.0)
    _make_burst(Vector3(-2,48,-70), 172.0/24, 16.0)
    wave = _mesh(BoxMesh.new(), _unlit(Color("05edf0")))
    sky_wave = _mesh(CylinderMesh.new(), _unlit(Color("05edf0")))
    var cone: CylinderMesh = sky_wave.mesh
    cone.top_radius = .15; cone.bottom_radius = 1.1; cone.height = 1; cone.radial_segments = 5
    ring = _mesh(TorusMesh.new(), _unlit(Color("8bffff")))
    var torus: TorusMesh = ring.mesh
    torus.inner_radius = .88; torus.outer_radius = 1.0; torus.rings = 24; torus.ring_segments = 4

func _break_building(body: MeshInstance3D, bounds: AABB, start: float) -> void:
    var source := {"node":body, "start":start, "layers":body.layers, "visible":body.visible, "bounds":bounds}
    hidden_sources.append(source)
    # Fracture source BoxMesh, using its real material and world-space footprint.
    var size: Vector3 = body.mesh.size
    var cell := size / Vector3(3, 5, 3)
    for x in 3:
        for y in 5:
            for z in 3:
                var mesh := BoxMesh.new(); mesh.size = cell * .985
                var local_at := -size*.5 + cell*(Vector3(x,y,z)+Vector3.ONE*.5)
                var transform := body.global_transform * Transform3D(Basis.IDENTITY, local_at)
                _add_piece(mesh, body.get_active_material(0), transform, start, bounds.get_center(), false)
    # All facade parts in this footprint are removed at the same instant.
    var region := bounds.grow(1.5)
    for node in session.backdrop.street.find_children("*", "MeshInstance3D", true, false):
        if node == body or not node.is_visible_in_tree() or node.mesh == null: continue
        if node.get_parent() is MeshInstance3D: continue
        var center: Vector3 = node.global_transform * node.get_aabb().get_center()
        if center.y < .4 or not region.has_point(center): continue
        if hidden_sources.any(func(s: Dictionary) -> bool: return s.node == node): continue
        hidden_sources.append({"node":node, "start":start, "layers":node.layers, "visible":node.visible})
        if pieces.size() < 380 and node.mesh.get_aabb().size.length() > .35:
            _add_piece(node.mesh, node.get_active_material(0), node.global_transform, start+.035, bounds.get_center(), false)

func _collect_batch_details() -> void:
    for batch in session.backdrop.street.find_children("*", "MultiMeshInstance3D", true, false):
        if batch.multimesh == null: continue
        var entries: Array = []
        for i in batch.multimesh.instance_count:
            var transform: Transform3D = batch.multimesh.get_instance_transform(i)
            var world: Transform3D = batch.global_transform * transform
            var at: Vector3 = world.origin
            for source in hidden_sources:
                if not source.has("bounds"): continue
                if source.bounds.grow(1.5).has_point(at) and at.y > .3:
                    entries.append({"index":i, "transform":transform, "start":source.start})
                    break
        if not entries.is_empty(): batches.append({"node":batch, "entries":entries})

func _extend_city() -> void:
    # Distant context reuses real stage meshes/materials, with no copied scripts,
    # physics, lights or actors. Only visible inside this cinematic container.
    var floor_mesh := BoxMesh.new(); floor_mesh.size = Vector3(180,.15,230)
    var floor_node := _mesh(floor_mesh,session.backdrop.street.get_node("StreetGeometry/MainRoad").get_active_material(0))
    floor_node.position = Vector3(0,-.25,-70)
    var unit := BoxMesh.new(); unit.size = Vector3.ONE
    var source_groups: Dictionary = {}
    for node in session.backdrop.street.get_node("BuildingMasses").get_children():
        if not node is MeshInstance3D or not node.mesh is BoxMesh: continue
        var material: Material = node.get_active_material(0)
        if material==null:continue
        var key := material.get_instance_id()
        if not source_groups.has(key):source_groups[key]={"material":material,"transforms":[]}
        for offset in [Vector3(-35,0,-22),Vector3(35,0,-22),Vector3(-70,0,-44),Vector3(70,0,-44),Vector3(0,0,-80),Vector3(-35,0,-102),Vector3(35,0,-102)]:
            var transform: Transform3D = node.global_transform
            transform.origin+=offset
            transform.basis=transform.basis.scaled_local(node.mesh.size)
            source_groups[key].transforms.append(transform)
    for group in source_groups.values():
        var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=unit;mm.instance_count=group.transforms.size()
        for i in mm.instance_count:mm.set_instance_transform(i,group.transforms[i])
        var instance:=MultiMeshInstance3D.new();instance.multimesh=mm;instance.material_override=group.material
        instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        container.add_child(instance)

func _ground_rubble() -> void:
    for i in 34:
        var mesh:=BoxMesh.new();mesh.size=Vector3(rng.randf_range(.3,1.4),rng.randf_range(.15,.65),rng.randf_range(.3,1.4))
        var material:=_unlit(Color("645a78") if i%2==0 else Color("9d90af"))
        var node:=_mesh(mesh,material)
        node.position=Vector3(rng.randf_range(-4.8,4.8),.15,rng.randf_range(-42,7))
        node.rotation=Vector3(.1,rng.randf()*TAU,.2)
        pieces.append({"node":node,"base":node.transform,"start":1.65+i*.03,"velocity":Vector3.ZERO,"spin":Vector3.ZERO,"plane":false,"rubble":true})

func _prepare_plane() -> void:
    var plane: Node3D = session.backdrop.plane
    plane_copy = Node3D.new(); plane_copy.name = "LiveAircraftFragments"
    container.add_child(plane_copy); plane_copy.transform = plane.transform
    for part in plane.find_children("*", "MeshInstance3D", true, false):
        if part.mesh == null: continue
        var mesh: Mesh = part.mesh
        var base: Transform3D = plane.global_transform.affine_inverse() * part.global_transform
        # Split fuselage lengthwise into surface-preserving triangle clusters.
        if "Fuselage" in str(part.name) or "MainWing" in str(part.name) or "Livery" in str(part.name):
            for cluster in _split_mesh(mesh, 6):
                _add_plane_piece(cluster, part.get_active_material(0), base, plane_copy)
        else:
            _add_plane_piece(mesh, part.get_active_material(0), base, plane_copy)

func _split_mesh(source: Mesh, count: int) -> Array[Mesh]:
    var result: Array[Mesh] = []
    var aabb := source.get_aabb()
    var axis := aabb.size.max_axis_index()
    for bin_index in count:
        var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
        var vertices := 0
        for s in source.get_surface_count():
            var arrays := source.surface_get_arrays(s)
            var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
            var total := indices.size() if not indices.is_empty() else points.size()
            for t in range(0,total-2,3):
                var ids := [t,t+1,t+2] if indices.is_empty() else [indices[t],indices[t+1],indices[t+2]]
                var center: Vector3 = (points[ids[0]]+points[ids[1]]+points[ids[2]])/3.0
                var bucket := clampi(floori((center[axis]-aabb.position[axis])/maxf(.001,aabb.size[axis])*count),0,count-1)
                if bucket != bin_index: continue
                for id in ids:
                    if arrays[Mesh.ARRAY_NORMAL] != null: surface.set_normal(arrays[Mesh.ARRAY_NORMAL][id])
                    if arrays[Mesh.ARRAY_TEX_UV] != null: surface.set_uv(arrays[Mesh.ARRAY_TEX_UV][id])
                    surface.add_vertex(points[id]); vertices += 1
        if vertices > 0: result.append(surface.commit())
    return result

func _add_plane_piece(mesh: Mesh, material: Material, base: Transform3D, parent: Node3D) -> void:
    var center: Vector3 = base * mesh.get_aabb().get_center()
    # Centre each part's pivot so wings/tail spin about themselves, not fuselage.
    var node := MeshInstance3D.new(); node.mesh = mesh; node.material_override = material
    parent.add_child(node)
    var start_transform := base
    var velocity := center.normalized()*rng.randf_range(10,18)+Vector3(rng.randf_range(-4,4),rng.randf_range(2,8),0)
    pieces.append({"node":node,"base":start_transform,"start":6.4,"velocity":velocity,"spin":Vector3(rng.randf(),rng.randf(),rng.randf())*.9,"plane":true,"pivot":center})

func _add_piece(mesh: Mesh, material: Material, base: Transform3D, start: float, center: Vector3, aircraft: bool) -> void:
    var node := _mesh(mesh,material)
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var offset := base.origin-center
    var velocity := Vector3(signf(center.x)*rng.randf_range(1,4),rng.randf_range(2,6),rng.randf_range(-2,2)) + offset*.25
    pieces.append({"node":node,"base":base,"start":start,"velocity":velocity,"spin":Vector3(rng.randf_range(-1,1),rng.randf_range(-1,1),rng.randf_range(-1,1)),"plane":aircraft})

func _sources_at(time: float) -> void:
    for source in hidden_sources:
        source.node.visible = source.visible and time < source.start
    for group in batches:
        var mm: MultiMesh = group.node.multimesh
        for entry in group.entries:
            var transform: Transform3D = entry.transform
            if time >= entry.start: transform.basis = Basis.IDENTITY.scaled(Vector3.ZERO)
            mm.set_instance_transform(entry.index, transform)

func _pieces_at(time: float) -> void:
    for p in pieces:
        var dt: float = time-p.start
        p.node.visible = dt >= 0.0
        if dt < 0.0: continue
        var move: Vector3 = p.velocity*dt + Vector3(0,-(1.8 if p.plane else 3.0)*dt*dt,0)
        var transform: Transform3D = p.base
        var spin := Basis.from_euler(p.spin*dt)
        if p.has("pivot"):
            transform.origin = p.pivot + spin*(p.base.origin-p.pivot)+move
        else:
            transform.origin += move
            transform.origin.y = maxf(.3, transform.origin.y)
        transform.basis = spin*p.base.basis
        if not p.plane and not p.has("rubble"):
            var settle: float = clampf(1.0-maxf(0,dt-2.2)/2.0,.001,1.0)
            transform.basis = transform.basis.scaled(Vector3.ONE*settle)
        p.node.transform = transform

func _make_burst(at: Vector3, start: float, radius: float) -> void:
    var nodes: Array = []
    for i in 20:
        var color := Color(["ffcf18","ff8a12","f74c24","f727a0","422039"][mini(4,i/4)])
        var node := _mesh(_octahedron(),_unlit(color))
        var offset := Vector3(rng.randf_range(-1,1),rng.randf_range(-.6,1),rng.randf_range(-1,1)).normalized()*rng.randf_range(.2,.9)
        nodes.append({"node":node,"offset":offset,"rotation":Vector3(rng.randf(),rng.randf(),rng.randf())*TAU,"scale":rng.randf_range(.28,.55),"smoke":i>=15})
    for i in 10:
        var cone:=CylinderMesh.new();cone.top_radius=0;cone.bottom_radius=.18;cone.height=1;cone.radial_segments=3
        var ray:=_mesh(cone,_unlit(Color("ffb914") if i%2==0 else Color("ff6920")))
        var direction:=Vector3(cos(i*TAU/10),sin(i*TAU/10),rng.randf_range(-.3,.3)).normalized()
        nodes.append({"node":ray,"offset":direction,"ray":true,"smoke":false,"scale":.8,"rotation":Vector3.ZERO})
    bursts.append({"at":at,"start":start,"radius":radius,"nodes":nodes})

func _bursts_at(time: float) -> void:
    for burst in bursts:
        var dt: float = time-burst.start
        var life := 4.3 if burst.start>=6.0 else 2.1
        for item in burst.nodes:
            var node: MeshInstance3D = item.node
            node.visible = dt >= 0.0 and dt < (.65 if item.has("ray") else life)
            if not node.visible: continue
            var grow := minf(1,dt/.26)
            var fade := clampf((life-dt)/.7,0,1)
            var size: float = burst.radius*grow*(.75+minf(dt,1.5)*.25)
            node.position = burst.at + item.offset*size + Vector3(0,dt*(1.8 if item.smoke else .6),0)
            node.rotation = item.rotation + Vector3(0,dt*.15,0)
            node.scale = Vector3.ONE * maxf(.001,size*item.scale*fade)
            if item.has("ray"):
                node.quaternion=Quaternion(Vector3.UP,item.offset)
                node.position=burst.at+item.offset*size*.7
                node.scale=Vector3(size*.7,size*1.2,size*.7)

func _wave_at(time: float) -> void:
    wave.visible = time < 149.0/24
    var length := minf(58, 8 + time*17)
    wave.mesh.size = Vector3(.28,.10,length)
    wave.position = Vector3(0,.18,3-length*.5)
    sky_wave.visible = time < 7.25
    if sky_wave.visible:
        var end := Vector3(-2,48,-70) if time>=125.0/24 else victim_path(time)
        var start := Vector3(0,.3,-32) if time>=125.0/24 else origin+Vector3(0,.5,0)
        var span := end-start
        sky_wave.position = start+span*.5
        sky_wave.quaternion = Quaternion(Vector3.UP,span.normalized())
        sky_wave.scale = Vector3(1,span.length(),1)
    ring.visible = time < .65
    if ring.visible:
        ring.position = origin + Vector3(0,.2,0)
        ring.scale = Vector3.ONE * (.5+time*14)

func _mesh(mesh: Mesh, material: Material) -> MeshInstance3D:
    var node := MeshInstance3D.new(); node.mesh = mesh; node.material_override = material
    container.add_child(node)
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    return node

func _unlit(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    burst_materials.append(material)
    return material

func _octahedron() -> ArrayMesh:
    var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var v := [Vector3.UP,Vector3.RIGHT,Vector3.BACK,Vector3.LEFT,Vector3.FORWARD,Vector3.DOWN]
    for face in [[0,1,2],[0,2,3],[0,3,4],[0,4,1],[5,2,1],[5,3,2],[5,4,3],[5,1,4]]:
        for index in face: surface.add_vertex(v[index])
    surface.generate_normals()
    return surface.commit()

func draw(canvas: Control) -> void:
    if not running: return
    var ink := Color("11101d")
    # Native overlay, never bake text or HUD into a video texture.
    canvas.draw_rect(Rect2(0,0,1280,28),ink)
    canvas.draw_rect(Rect2(0,692,1280,28),ink)
    canvas.draw_string(session.hud.font,Vector2(28,710),"ENTER / SPACE  SKIP     ESC  PAUSE",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("d9d2e5"))
    if age >= 189.0/24:
        var enter := clampf((age-189.0/24)/.15,0,1)
        canvas.draw_set_transform(Vector2(930+(1-enter)*300,535)*canvas.size/Vector2(1280,720),-.14,canvas.size/Vector2(1280,720))
        canvas.draw_colored_polygon(PackedVector2Array([Vector2(-40,-85),Vector2(300,-115),Vector2(270,25),Vector2(-55,55)]),Color("f50091"))
        canvas.draw_string(session.hud.bold,Vector2(8,7),"K.O.",HORIZONTAL_ALIGNMENT_LEFT,-1,140,ink)
        canvas.draw_string(session.hud.bold,Vector2.ZERO,"K.O.",HORIZONTAL_ALIGNMENT_LEFT,-1,140,Color("c4ff00"))
        canvas.draw_set_transform(Vector2.ZERO,0,canvas.size/Vector2(1280,720))

func clear() -> void:
    running = false
    if is_instance_valid(container): container.hide()
    for source in hidden_sources:
        if is_instance_valid(source.node): source.node.visible = source.visible
    for group in batches:
        if is_instance_valid(group.node):
            for entry in group.entries: group.node.multimesh.set_instance_transform(entry.index,entry.transform)
    if is_instance_valid(session) and not plane_state.is_empty():
        session.backdrop.plane.transform = plane_state.transform
        session.backdrop.plane.visible = plane_state.visible
        session.backdrop.frozen = plane_state.frozen
        for state in actor_states:
            if not is_instance_valid(state.node): continue
            state.node.transform = state.transform
            state.node.visible = state.visible
            state.node.model.rotation = Vector3.ZERO
            state.node.set_neon_silhouette(false)
            for mat in state.node.materials:
                if state.node.neon_enabled:
                    mat.set_shader_parameter("ko_silhouette",false)
                    mat.set_shader_parameter("tint",Color.WHITE)
        for shadow in session.silhouettes: shadow.visible = true
        session.camera.transform = camera_state.transform
        session.camera.fov = camera_state.fov
        session.camera.far = camera_state.far
        session.camera.environment = camera_state.environment
    plane_state.clear()
    actor_states.clear()
