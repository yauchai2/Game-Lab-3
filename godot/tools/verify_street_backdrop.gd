extends SceneTree
var checks: Array[Dictionary] = []
func _initialize() -> void:
    call_deferred("run")
func check(label: String, condition: bool) -> void:
    checks.append({"name":label,"passed":condition})
    if not condition: push_error("BACKDROP FAIL: "+label)
func run() -> void:
    var scene := preload("res://scenes/combat/street_fight.tscn").instantiate()
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    await process_frame
    var bg: Node = scene.backdrop
    check("street uses an independent 3D world",bg.viewport.own_world_3d and bg.viewport.world_3d!=scene.get_world_3d())
    check("reference background camera looks upwards",bg.camera.projection==Camera3D.PROJECTION_PERSPECTIVE and is_equal_approx(bg.camera.rotation_degrees.x,27.0) and bg.camera.position.y<1.5)
    check("combat keeps its orthographic camera",scene.camera.projection==Camera3D.PROJECTION_ORTHOGONAL)
    check("both reference street walls remain visible",bg.street.get_node("BuildingMasses/BlueFront").visible and bg.street.get_node("BuildingMasses/OrangeFront").visible)
    check("source street is unrotated in the background wrapper",is_zero_approx(bg.street.rotation.y))
    check("backdrop input cannot consume combat controls",not bg.viewport.handle_input_locally and not bg.street.is_processing_unhandled_key_input())
    var transform: Transform3D = bg.camera.global_transform
    scene.sim.fighters[0].x = -7
    scene.sim.fighters[1].x = -3
    scene._present(0.4)
    check("fighter framing does not move the street camera",bg.camera.global_transform==transform)
    bg.elapsed = 0
    bg.present(0.1,false)
    var first: Vector3 = bg.plane.position
    bg.present(0.1,false)
    var second: Vector3 = bg.plane.position
    bg.present(0.1,false)
    var third: Vector3 = bg.plane.position
    check("aircraft follows a straight constant-speed path",(second-first).is_equal_approx(third-second) and (second-first).length()>0.1)
    var elapsed_before: float = bg.elapsed
    var position_before: Vector3 = bg.plane.position
    bg.present(1.0,true)
    check("pause freezes flight and schedules one background refresh",bg.elapsed==elapsed_before and bg.plane.position==position_before and bg.viewport.render_target_update_mode==SubViewport.UPDATE_ONCE)
    bg.present(7.0,false)
    check("flight cooldown hides aircraft without reverse travel",not bg.plane.visible and bg.viewport.render_target_update_mode==SubViewport.UPDATE_ALWAYS)
    bg.freeze_for_capture()
    bg.present(1.0,false)
    check("fixed capture uses the reproducible overhead pose",bg.plane.visible and bg.plane.position==bg.anchor)
    check("background render width is bounded",bg.viewport.size.x<=1280 and bg.viewport.size.x>0 and bg.viewport.size.y>0)
    var picture: TextureRect = bg.canvas.get_node("StreetView")
    check("background display passes through mouse input",picture.mouse_filter==Control.MOUSE_FILTER_IGNORE and bg.canvas.layer<0)
    check("foreground composites canvas behind the fighters",scene.stage_environment.background_mode==Environment.BG_CANVAS and scene.stage_environment.background_canvas_max_layer<0)
    scene.queue_free()
    await process_frame
    await process_frame
    var failed := checks.filter(func(c: Dictionary)->bool: return not c.passed).size()
    var file := FileAccess.open("res://../docs/evidence/street-angle/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"method":"headless scene, projection, composition and flight checks; visual evidence is separate"},"  "))
    file.close()
    print("BACKDROP_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
