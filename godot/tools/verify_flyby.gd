extends SceneTree
var checks: Array = []
var failed := false
func _initialize() -> void:
    call_deferred("run")
func check(value: bool, name: String, details := {}) -> void:
    checks.append({"check":name,"passed":value,"details":details})
    if not value:
        failed = true
        push_error(name+": "+JSON.stringify(details))
func frames(count: int) -> void:
    for i in count:
        await process_frame
func run() -> void:
    var scene := (load("res://scenes/street_walk.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    var fly = scene.get_node("AircraftFlyby")
    await frames(12)
    check(fly.active and fly.plane.visible,"entrance_triggers_automatically",{"elapsed":fly.elapsed})
    check(fly.sound.stream is AudioStreamWAV and fly.sound.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and fly.sound.playing,"placeholder_loop_started")
    check(fly.plane.find_children("AdditionalMainWheel*","MeshInstance3D",true,false).size() == 8,"additional_wheels_present")
    var camera := root.get_viewport().get_camera_3d()
    var start_distance: float = fly.plane.global_position.distance_to(fly.anchor)
    await frames(260)
    var midpoint_distance: float = fly.plane.global_position.distance_to(fly.anchor)
    check(midpoint_distance < 15.0 and start_distance > 200.0,"passes_reference_pose",{"start_distance":start_distance,"midpoint_distance":midpoint_distance,"elapsed":fly.elapsed})
    check(root.get_viewport().get_camera_3d() == camera,"does_not_steal_camera")
    check(fly.sound.volume_db > -5.0,"audio_envelope_louder_at_midpoint",{"volume_db":fly.sound.volume_db})
    await frames(285)
    check(not fly.active and not fly.plane.visible and not fly.sound.playing and fly.cooldown > 0,"event_finishes_and_hides")
    var event := InputEventKey.new()
    event.keycode = KEY_P
    event.pressed = true
    scene._unhandled_key_input(event)
    check(fly.active and fly.plane.visible and fly.elapsed < .01,"p_replays_during_cooldown")
    check(root.get_viewport().get_camera_3d() == camera,"replay_keeps_camera")
    fly.freeze_for_capture()
    check(fly.preview and not fly.active and not fly.sound.playing and fly.plane.global_position.distance_to(fly.anchor) < .01,"capture_freezes_anchor")
    fly.restart()
    check(fly.active and not fly.preview,"replay_ends_capture_preview")
    var report := {"engine":Engine.get_version_info().string,"display_driver":DisplayServer.get_name(),"fixed_fps":60,"audio_driver":"dummy; not listened to","human_playtest":false,"checks":checks,"passed":not failed}
    var file := FileAccess.open("res://../docs/evidence/flyby/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    print("FLYBY_VERIFIED ",JSON.stringify(report))
    fly.sound.stop()
    scene.queue_free()
    await frames(4)
    quit(1 if failed else 0)
