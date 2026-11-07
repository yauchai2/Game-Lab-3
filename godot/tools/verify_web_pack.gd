extends SceneTree
## External script: --main-pack <exported game.pck>. Loads only exported resources.
var checks: Array[Dictionary] = []
func _initialize() -> void:
    call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed: push_error(label)
func run() -> void:
    check("raw animation JSON is present in exported pack",FileAccess.file_exists("res://assets/animations/quaternius_combat.json"))
    var library: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/animations/quaternius_combat.json"))
    check("exported animation JSON parses",library is Dictionary)
    var scene: Node3D = load("res://scenes/combat/street_fight.tscn").instantiate()
    root.add_child(scene)
    current_scene = scene
    await process_frame
    check("exported main scene builds both animated fighters",scene.fighters.size()==2 and scene.hud!=null)
    check("exported panorama and red car load",scene.backdrop.street.has_node("ParkedCar") and scene.backdrop.environment.sky.sky_material.panorama!=null)
    check("exported music and impact resources load",scene.audio.music.stream!=null and scene.audio.sounds.hit[0]!=null)
    scene.start_match(true)
    scene.set_physics_process(false)
    scene.sim.phase = "fight"
    scene.sim.fighters[0].x = -0.65
    scene.sim.fighters[1].x = 0.65
    for i in 90:
        scene.sim.tick({"attack":"light"} if i%16==0 else {},{})
        for event in scene.sim.events: scene._handle_event(event)
        scene._present(1.0/60.0)
    check("exported simulation attacks and consumes retargeted animation",scene.sim.fighters[1].health<100)
    scene.return_to_street()
    for i in 4: await process_frame
    check("exported F6 destination street loads",current_scene.name=="StreetWalk")
    var key := InputEventKey.new()
    key.keycode = KEY_F6
    key.pressed = true
    current_scene._unhandled_key_input(key)
    for i in 4: await process_frame
    check("exported street returns to fight title",current_scene.name=="StreetFight" and current_scene.screen=="title")
    current_scene.queue_free()
    await process_frame
    await create_timer(0.1).timeout
    var failed := checks.filter(func(result:Dictionary)->bool:return not result.passed).size()
    print("WEB_PACK_CHECKS ",JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"method":"native Godot runtime using exported Web PCK; not browser rendering"}))
    call_deferred("quit",0 if failed==0 else 1)
