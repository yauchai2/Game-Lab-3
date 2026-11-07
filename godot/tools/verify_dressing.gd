extends SceneTree
var checks: Array = []
var failed := false
func _initialize() -> void:
    call_deferred("run")
func check(value: bool, title: String, details := {}) -> void:
    checks.append({"check":title,"passed":value,"details":details})
    if not value:
        failed = true
        push_error(title+": "+JSON.stringify(details))
func key(scene: Node, code: int) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    scene._unhandled_key_input(event)
func ticks(count: int) -> void:
    for i in count:
        await physics_frame
func run() -> void:
    var scene = (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    await ticks(5)
    var dressing = scene.get_node("StreetDressing")
    check(dressing.has_method("_make_storefronts") and dressing.box_count>300,"dressing_geometry_loaded",{"batched_boxes":dressing.box_count})
    check(dressing.static_batches.get_child_count() <= 16,"geometry_uses_shared_batches",{"batch_count":dressing.static_batches.get_child_count()})
    check(dressing.labels.get_child_count() == 0,"sign_panels_have_no_generated_text",{"count":dressing.labels.get_child_count()})
    check(dressing.find_children("LampPoleCollider*","StaticBody3D",true,false).size() == 4,"lamp_pole_collision_count")
    var fly = scene.get_node("AircraftFlyby")
    check(fly.anchor.distance_to(Vector3(-6,41,-52))<.01,"walk_flyby_anchor_adjusted",{"anchor":[fly.anchor.x,fly.anchor.y,fly.anchor.z]})
    check(fly.plane.has_node("GreenLiveryDetail"),"aircraft_green_livery_present")
    check(scene.get_node("ParkedTruck/RearDoorDetails").get_child_count() >= 10,"truck_has_rear_door_details")
    var original = (load("res://scenes/street_whitebox.tscn") as PackedScene).instantiate()
    check(original.get_node("AircraftProxy").position.distance_to(Vector3(-3,45,-60))<.01 and not original.has_node("StreetDressing"),"standalone_whitebox_unchanged")
    original.free()
    var outline: MeshInstance3D = scene.get_node("OutlinePass")
    check(not outline.visible,"outline_off_by_default")
    key(scene,KEY_O)
    check(outline.visible,"o_enables_outline")
    key(scene,KEY_O)
    check(not outline.visible,"o_disables_outline")
    var player = scene.get_node("Player")
    scene.activate_walk(false)
    player.set_mouse_capture(true)
    player.global_position = Vector3(-4.5,.24,-.5)
    await ticks(30)
    Input.action_press("walk_left")
    await ticks(75)
    Input.action_release("walk_left")
    check(player.global_position.x > -5.30 and player.global_position.x < -4.7,"player_is_blocked_by_lamp_pole",{"player_x":player.global_position.x})
    check(player.is_on_floor(),"player_remains_on_sidewalk")
    var report := {"passed":not failed,"checks":checks,"display_driver":DisplayServer.get_name(),"human_playtest":false,"engine":Engine.get_version_info().string}
    var file := FileAccess.open("res://../docs/evidence/dressing/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("DRESSING_VERIFIED ",JSON.stringify(report))
    scene.get_node("AircraftFlyby").sound.stop()
    scene.queue_free()
    await process_frame
    quit(1 if failed else 0)
