extends SceneTree
const Corner = preload("res://scripts/corner_streetscape.gd")
var checks: Array[Dictionary]=[]
func _initialize() -> void: call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed: push_error("CORNER FAIL: "+label)
func run() -> void:
    for category in ["shadowed_variable_base_class","shadowed_global_identifier","integer_division"]:
        ProjectSettings.set_setting("debug/gdscript/warnings/"+category,2)
    var compiled:=GDScript.new()
    compiled.source_code=FileAccess.get_file_as_string("res://scripts/corner_streetscape.gd")
    check("new scene builder compiles with relevant warnings treated as errors",compiled.reload()==OK)
    var corner=Corner.new()
    root.add_child(corner)
    check("both front facades gain substantial detail",corner.zone_counts.front_left>100 and corner.zone_counts.front_right>100)
    check("both sides have a connected old-building frontage",corner.zone_counts.neighbors_left>400 and corner.zone_counts.neighbors_right>400)
    check("six neighboring building masses added",corner.building_bounds.size()==6)
    check("neighboring blocks keep plausible six-storey heights",corner.building_bounds.all(func(b:AABB)->bool:return b.size.y>=13 and b.size.y<=20.5))
    check("new buildings have individual solid collision",corner.find_children("NeighborBuilding_*","StaticBody3D",true,false).size()==6)
    check("original car asset reused twice at the street edges",corner.has_node("CrossStreetCar_-1") and corner.has_node("CrossStreetCar_1"))
    check("parked cars stay beyond the fight space",absf(corner.get_node("CrossStreetCar_-1").position.x)>20 and absf(corner.get_node("CrossStreetCar_1").position.x)>20)
    check("two parked scooters use simple blockers",corner.find_children("ParkedScooter_*","StaticBody3D",true,false).size()==2)
    check("new outer sidewalks have matching collision",corner.find_children("CornerSidewalk_*","StaticBody3D",true,false).size()==2)
    check("details are batched by mesh and material",corner.instance_count>1500 and corner.batch_count<=12)
    check("tints share role materials instead of per-object material copies",corner.retained_materials.size()<=8)
    var clear:=AABB(Vector3(-8.8,.04,2.4),Vector3(17.6,4.26,2.0))
    var infringements:=0
    for bounds in corner.detail_bounds:
        if bounds.intersects(clear):infringements+=1
    check("all new geometry clears the full running and jumping fight envelope",infringements==0)
    var collision_infringements:=0
    for body in corner.find_children("*","StaticBody3D",true,false):
        for shape in body.find_children("*","CollisionShape3D",true,false):
            if shape.shape is BoxShape3D:
                var size:Vector3=shape.shape.size
                var bounds:AABB=shape.global_transform*AABB(-size*.5,size)
                if bounds.intersects(clear):collision_infringements+=1
    check("new collision never enters the fighting corridor",collision_infringements==0)
    check("no generated scene text or new real-time lights",corner.find_children("*","Label3D",true,false).is_empty() and corner.find_children("*","Light3D",true,false).is_empty())
    var opaque:=true
    var color_batches:=true
    var structural_shadows:=true
    var flat_curves:=true
    for batch in corner.find_children("CornerBatch_*","MultiMeshInstance3D",true,false):
        var material:ShaderMaterial=batch.material_override
        color_batches=color_batches and batch.multimesh.use_colors and material.get_shader_parameter("use_instance_color")
        if not str(batch.name).contains("plaster"):
            structural_shadows=structural_shadows and batch.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        else:
            structural_shadows=structural_shadows and batch.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        for i in batch.multimesh.instance_count:
            opaque=opaque and is_equal_approx(batch.multimesh.get_instance_color(i).a,1.0)
        if batch.multimesh.mesh is ArrayMesh:
            var arrays: Array=batch.multimesh.mesh.surface_get_arrays(0)
            var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
            for i in range(0,normals.size(),3):
                flat_curves=flat_curves and normals[i].is_equal_approx(normals[i+1]) and normals[i].is_equal_approx(normals[i+2])
    check("multi-instance color shader enabled only on new batches",color_batches)
    check("new objects remain opaque",opaque)
    check("structural solids cast shadows while tiny details do not",structural_shadows)
    check("round props have flat per-triangle normals",flat_curves)
    var texture_results: Array[Dictionary]=[]
    for path in ["res://assets/textures/corner_plaster_128.png","res://assets/textures/corner_tiles_128.png","res://assets/textures/corner_shutter_128.png"]:
        var texture:Texture2D=load(path)
        var bitmap:=texture.get_image()
        var valid:=bitmap.get_width()==128 and bitmap.get_height()==128 and bitmap.has_mipmaps()
        check("low-resolution texture imports with mipmaps: "+path.get_file(),valid)
        texture_results.append({"path":path,"mipmaps":bitmap.get_mipmap_count(),"sha256":FileAccess.get_sha256(path)})
    var vanilla:=ShaderMaterial.new()
    vanilla.shader=preload("res://shaders/sample_toon.gdshader")
    check("existing toon materials keep per-instance tint disabled",not vanilla.get_shader_parameter("use_instance_color"))
    var original=preload("res://scenes/street_whitebox.tscn").instantiate()
    root.add_child(original)
    check("independent whitebox is preserved",not original.has_node("CornerStreetscape") and original.get_node("BuildingMasses/BlueFront").position==Vector3(-11,8.25,-5))
    original.queue_free()
    var metrics={"instances":corner.instance_count,"batches":corner.batch_count,"materials":corner.retained_materials.size(),"zone_counts":corner.zone_counts,"building_count":corner.building_bounds.size(),"collider_count":corner.collision_count,"fight_envelope_infringements":infringements,"collision_infringements":collision_infringements,"textures":texture_results}
    corner.queue_free()
    await process_frame
    var fight=preload("res://scenes/combat/street_fight.tscn").instantiate()
    fight.preferences_path=""
    root.add_child(fight)
    fight.set_physics_process(false)
    fight.set_process(false)
    fight.audio.muted=true
    check("combat assembly receives the shared street-corner module",fight.backdrop.street.has_node("CornerStreetscape"))
    check("combat street scale and accepted sky remain unchanged",fight.backdrop.street.scale==Vector3.ONE and fight.backdrop.environment.sky.sky_material.panorama.resource_path=="res://assets/SKY_BLUE_A01.png")
    fight.queue_free()
    await process_frame
    var walk=preload("res://scenes/street_walk.tscn").instantiate()
    root.add_child(walk)
    check("walk assembly receives the same module",walk.has_node("CornerStreetscape"))
    check("existing walk road and lamp layout remain intact",walk.get_node("Street/StreetGeometry/MainRoad").position.z==-32 and walk.get_node("StreetDressing").find_children("LampPoleCollider_*","StaticBody3D",true,false).size()==4)
    walk.queue_free()
    await process_frame
    await create_timer(0.1).timeout
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var output:=FileAccess.open("res://../docs/evidence/corner-density/verification.json",FileAccess.WRITE)
    output.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"metrics":metrics,"method":"Godot 4.6.3 headless geometry bounds, collision, batching, textures, normals and both runtime scene assemblies; no GPU performance claim"},"  "))
    output.close()
    print("CORNER_DENSITY_CHECKS ",checks.size()-failed,"/",checks.size()," ",JSON.stringify(metrics))
    call_deferred("quit",0 if failed==0 else 1)
