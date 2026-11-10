extends SceneTree
## Automated demonstration. Inputs are scripted; this is not human playtest evidence.
var scene: Node3D
var frame := 0
var hit_count := 0
var guard_count := 0
var finishing := false
func _initialize() -> void:
    call_deferred("start")
func start() -> void:
    scene = preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.start_match()
    scene.audio.muted = not OS.get_cmdline_user_args().has("--with-audio")
    scene.set_physics_process(false)
    scene.sim.phase = "fight"
    scene.sim.fighters[0].x = -1.1
    scene.sim.fighters[1].x = 1.1
    scene.sim.fighters[0].meter = 60
func _process(_delta: float) -> bool:
    if finishing or not is_instance_valid(scene): return false
    frame += 1
    var a: Dictionary = scene.sim.fighters[0]
    var b: Dictionary = scene.sim.fighters[1]
    var command := {"axis":signf(b.x-a.x) if absf(b.x-a.x)>1.35 else 0.0}
    if frame < 60:
        command["axis"] = -1.0
    elif frame < 120:
        command["axis"] = 1.0
    if frame >= 120 and frame % 16 == 0:
        command["attack"] = "light"
    if frame == 135:
        command["attack"] = "heavy"
        command["up"] = true
    if frame == 210:
        command["attack"] = "special"
    if frame > 250 and frame < 290:
        command["guard"] = true
    if frame == 320:
        command["jump"] = true
    scene.sim.tick(command)
    for event in scene.sim.events:
        if event.kind == "hit": hit_count += 1
        if event.kind == "block": guard_count += 1
        scene._handle_event(event)
    if frame >= 420:
        print("DEMO_COMPLETE scripted_frames=",frame," hits=",hit_count," blocks=",guard_count," adapter=",RenderingServer.get_video_adapter_name())
        finishing = true
        call_deferred("finish")
    return false

func finish() -> void:
    # Give the asynchronous audio mixer time to release stopped playback.
    scene.set_process(false)
    scene.audio.set_process(false)
    scene.audio.stop_all()
    scene.audio.music.stream_paused = false
    scene.audio.music.stop()
    scene.audio.music.stream = null
    await create_timer(0.10).timeout
    quit()
