extends SceneTree
var checks: Array[Dictionary]=[]
func _initialize() -> void: call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed: push_error(label)
func run() -> void:
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    var bg=scene.backdrop
    var env: Environment=bg.environment
    var sun: DirectionalLight3D=bg.street.get_node("Sun")
    var sun_pose:=sun.transform
    var light:=env.ambient_light_energy
    check("uses original image panorama",env.sky.sky_material is PanoramaSkyMaterial and env.sky.sky_material.panorama==preload("res://assets/SKY_BLUE_A01.png"))
    var initial:=env.sky_rotation.y
    bg.present(60.0,false)
    check("cloud image drifts 4.8 degrees per minute",is_equal_approx(env.sky_rotation.y-initial,deg_to_rad(4.8)))
    var yaw:=env.sky_rotation.y
    bg.present(10.0,true)
    check("pause freezes sky",is_equal_approx(env.sky_rotation.y,yaw))
    bg.present(10.0,false,true)
    check("reduced effects freezes sky",is_equal_approx(env.sky_rotation.y,yaw))
    bg.freeze_for_capture()
    bg.present(10.0,false)
    check("capture freeze freezes sky",is_equal_approx(env.sky_rotation.y,yaw))
    check("sun and ambient lighting remain fixed",sun.transform==sun_pose and env.ambient_light_energy==light)
    bg.frozen=false
    scene.reduced_effects=true
    scene._present(1.0)
    check("F2 session state reaches sky controller",is_equal_approx(env.sky_rotation.y,yaw))
    scene.reduced_effects=false
    scene.screen="pause"
    scene._present(1.0)
    check("pause session state reaches sky controller",is_equal_approx(env.sky_rotation.y,yaw))
    var motion=preload("res://scripts/sky_drift.gd").new()
    motion.advance(env,1e8,PI*.5)
    check("long sessions keep finite bounded angle",is_finite(motion.offset) and absf(motion.offset)<=PI)
    var old_offset: float=motion.offset
    motion.advance(env,-3,PI*.5)
    check("negative delta cannot reverse drift",is_equal_approx(old_offset,motion.offset))
    var walk=preload("res://scenes/street_walk.tscn").instantiate()
    root.add_child(walk)
    var sample=walk.get_node("StyleSample")
    sample.set_process(false)
    sample._process(10.0)
    check("walk also animates original sky",sample.sky_motion.offset>0 and sample.image_sky_enabled)
    var walk_offset: float=sample.sky_motion.offset
    sample.set_clouds(false)
    sample._process(10.0)
    check("flat sky stops drift",is_equal_approx(sample.sky_motion.offset,walk_offset))
    sample.set_clouds(true)
    sample._process(10.0)
    check("procedural sky drifts too",sample.sky_motion.offset>walk_offset)
    sample.set_image_sky(true)
    check("switching sky keeps drift without reset",is_equal_approx(sample.sample_environment.sky_rotation.y,PI*.5+sample.sky_motion.offset))
    for node in [bg.street.get_node("CornerStreetscape"),walk.get_node("CornerStreetscape")]:
        var anchors:=0
        for label in ["LeftCornerBlade","LeftOuterBlade","RightCornerBlade","RightOuterBlade"]:
            if node.has_node(label) and node.get_node(label).get_meta("texture_status")=="blank_pending_user_artwork":anchors+=1
        check("four blank supported sign anchors in "+str(node.get_parent().name),anchors==4)
    check("duplicate distant sign label removed",not bg.street.get_node("SourceStyleDetails").has_node("CrossStreetLabel"))
    var visible_labels:=0
    for label in scene.find_children("*","Label3D",true,false):
        if label.is_visible_in_tree(): visible_labels+=1
    check("no visible 3D sign text",visible_labels==0)
    walk.queue_free()
    scene.queue_free()
    await process_frame
    await create_timer(.15).timeout
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/scene-composition/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed},"  "))
    print("SKY_MOTION_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
