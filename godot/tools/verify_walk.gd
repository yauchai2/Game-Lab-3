extends SceneTree
const PlayerController = preload("res://scripts/test_player.gd")
var failed := false
var results: Array = []
var session: Node3D
var player: PlayerController
var actions := ["walk_forward","walk_back","walk_left","walk_right","walk_jump","walk_sprint"]
func _initialize() -> void:
    call_deferred("run_checks")
func check(value: bool, title: String, details: Dictionary = {}) -> void:
    results.append({"check":title,"passed":value,"details":details})
    if not value:
        failed = true
        push_error(title+": "+JSON.stringify(details))
func ticks(count: int) -> void:
    for i in count:
        await physics_frame
func release_actions() -> void:
    for action in actions:
        Input.action_release(action)
func key(code: int) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    session._unhandled_key_input(event)
func place(at: Vector3) -> void:
    release_actions()
    session.activate_walk(false)
    player.set_mouse_capture(true)
    player.reset_to_spawn()
    player.global_position = at
    await ticks(30)
func run_checks() -> void:
    var packed: PackedScene = load("res://scenes/street_walk.tscn")
    if packed == null:
        push_error("Walk scene could not load")
        quit(1)
        return
    session = packed.instantiate()
    root.add_child(session)
    player = session.get_node("Player")
    await ticks(90)
    check(player.is_on_floor() and absf(player.position.y) < .05,"spawn_settles_on_road",{"feet_y":player.position.y})
    check(player.controls_enabled and player.camera.current,"walk_camera_is_default")
    check(player.collision_layer == 2 and player.arm.collision_mask == 1,"camera_excludes_player_layer")
    var start := player.position
    Input.action_press("walk_forward")
    await ticks(60)
    release_actions()
    var straight_distance := Vector2(player.position.x-start.x,player.position.z-start.z).length()
    check(player.position.z < start.z-3.5 and absf(player.position.x) < .1,"forward_input_moves_along_street",{"distance_m":straight_distance})
    await ticks(30)
    check(Vector2(player.velocity.x,player.velocity.z).length() < .01,"movement_stops_after_release")
    await place(Vector3(0,.08,5.5))
    start = player.position
    Input.action_press("walk_forward")
    Input.action_press("walk_right")
    await ticks(60)
    release_actions()
    var diagonal_distance := Vector2(player.position.x-start.x,player.position.z-start.z).length()
    check(absf(diagonal_distance-straight_distance) < .2,"diagonal_has_no_speed_boost",{"straight_m":straight_distance,"diagonal_m":diagonal_distance})
    await place(Vector3(0,.08,5.5))
    Input.action_press("walk_forward")
    Input.action_press("walk_sprint")
    await ticks(60)
    release_actions()
    check(player.position.z < 5.5-straight_distance-1.5,"sprint_is_faster",{"distance_m":5.5-player.position.z})
    await place(Vector3(0,.08,5.5))
    Input.action_press("walk_jump")
    await ticks(1)
    Input.action_release("walk_jump")
    var peak := player.position.y
    for i in 90:
        await ticks(1)
        peak = maxf(peak,player.position.y)
    check(peak > .65 and player.is_on_floor() and absf(player.position.y) < .05,"jump_and_land",{"peak_feet_y":peak,"land_feet_y":player.position.y})
    await place(Vector3(3.2,.08,-12))
    Input.action_press("walk_right")
    Input.action_press("walk_jump")
    await ticks(1)
    Input.action_release("walk_jump")
    await ticks(24)
    Input.action_release("walk_right")
    await ticks(80)
    check(player.position.x > 4.25 and player.position.x < 5.75 and absf(player.position.y-.16) < .04 and player.is_on_floor(),"jump_onto_sidewalk",{"feet":[player.position.x,player.position.y,player.position.z]})
    await place(Vector3(0,.08,5.5))
    var initial_respawns := player.respawn_count
    Input.action_press("walk_forward")
    await ticks(720)
    release_actions()
    check(player.position.z < -47 and player.is_on_floor() and player.respawn_count == initial_respawns,"walk_over_50m_without_falling",{"end_z":player.position.z,"respawns":player.respawn_count-initial_respawns})
    await place(Vector3(-5,.24,-32))
    Input.action_press("walk_left")
    await ticks(120)
    release_actions()
    check(player.position.x < -12 and player.is_on_floor() and absf(player.position.y) < .05,"sidewalk_to_side_alley",{"feet":[player.position.x,player.position.y,player.position.z]})
    await place(Vector3(-5,.24,-5))
    Input.action_press("walk_left")
    await ticks(120)
    release_actions()
    check(player.position.x > -5.75 and player.position.x < -5.5,"building_wall_blocks_player",{"stop_x":player.position.x})
    await place(Vector3(2.8,.08,-3))
    Input.action_press("walk_forward")
    await ticks(120)
    release_actions()
    check(player.position.z > -5.85 and player.position.z < -5.2,"parked_van_blocks_player",{"stop_z":player.position.z})
    await place(Vector3(5.25,.24,-15))
    Input.action_press("walk_forward")
    await ticks(120)
    release_actions()
    check(player.position.z > -17.55 and player.position.z < -16.9,"mailbox_blocks_player",{"stop_z":player.position.z})
    await place(Vector3(-5,.24,-5))
    player.yaw = -PI/2
    player.apply_look(Vector2.ZERO)
    await ticks(20)
    var arm_hit := player.arm.get_hit_length()
    check(arm_hit > .05 and arm_hit < 1.2,"spring_arm_retracts_at_wall",{"requested_m":player.camera_distance,"actual_m":arm_hit})
    await place(Vector3(0,.08,5.5))
    player.set_mouse_capture(true)
    var motion := InputEventMouseMotion.new()
    motion.relative = Vector2(100,-100000)
    player._unhandled_input(motion)
    check(is_equal_approx(player.pitch,deg_to_rad(80)) and absf(player.yaw) > .1,"mouse_look_and_pitch_limit")
    key(KEY_V)
    check(player.first_person and not player.get_node("Visual").visible and is_zero_approx(player.arm.spring_length),"first_person_toggle")
    key(KEY_V)
    check(not player.first_person and player.get_node("Visual").visible and is_equal_approx(player.arm.spring_length,player.camera_distance),"third_person_toggle")
    key(KEY_1)
    check(not session.walking and not player.controls_enabled and session.get_node("Street/ReferenceCameras").get_child(0).current,"reference_camera_disables_movement")
    start = player.position
    Input.action_press("walk_forward")
    await ticks(30)
    release_actions()
    check(Vector2(player.position.x-start.x,player.position.z-start.z).length() < .01,"no_player_drift_in_reference_view")
    for code in [KEY_2,KEY_3,KEY_4,KEY_5]:
        key(code)
    key(KEY_TAB)
    check(session.get_node("Street/ReferenceCameras").get_child(0).current,"reference_tab_wrap")
    key(KEY_0)
    check(session.walking and player.controls_enabled and player.camera.current,"return_to_walk_camera")
    key(KEY_ESCAPE)
    check(not player.mouse_look_enabled,"escape_requests_cursor_release")
    start = player.position
    Input.action_press("walk_forward")
    await ticks(30)
    release_actions()
    check(Vector2(player.position.x-start.x,player.position.z-start.z).length() < .01,"cursor_release_pauses_movement")
    var click := InputEventMouseButton.new()
    click.button_index = MOUSE_BUTTON_LEFT
    click.pressed = true
    player._unhandled_input(click)
    check(player.mouse_look_enabled,"click_requests_cursor_capture")
    player._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
    check(not player.mouse_look_enabled,"focus_loss_releases_input")
    key(KEY_R)
    await ticks(5)
    check(player.position.distance_to(player.spawn_transform.origin) < .2 and absf(player.yaw) < .001 and player.camera.current,"reset_returns_to_start")
    initial_respawns = player.respawn_count
    player.position = Vector3(0,-15,0)
    await ticks(10)
    check(player.respawn_count == initial_respawns+1 and player.position.distance_to(player.spawn_transform.origin) < .2,"fall_recovery")
    var report := {"passed":not failed,"engine":Engine.get_version_info().string,"physics_hz":Engine.physics_ticks_per_second,"checks":results,"godot_gpu_capture":false,"human_playtest":false,"os_cursor_capture_verified":false,"display_driver":DisplayServer.get_name()}
    var file := FileAccess.open("res://../docs/evidence/walk/verification.json",FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(report,"  "))
    print("WALK_VERIFIED ",JSON.stringify(report))
    quit(1 if failed else 0)
