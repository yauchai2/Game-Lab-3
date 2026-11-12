extends SceneTree
## Before/after capture for the sprite VFX + soft shadow swap. Usage: --script res://tools/capture_vfx_swap.gd -- <out_dir>
var scene: Node
var out_dir:="/tmp/vfxcap"
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var args:=OS.get_cmdline_user_args()
    if args.size()>0:out_dir=args[0]
    DirAccess.make_dir_recursive_absolute(out_dir)
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    scene.backdrop.freeze_for_capture()
    for move in ["jab","heavy","launcher","special"]:
        prepare(move)
        for i in scene.Simulation.MOVES[move].startup:
            scene._physics_process(1.0/60)
            scene._process(1.0/60)
        await shot(move+"_contact")
        for i in scene.sim.hitstop:
            scene._physics_process(1.0/60)
            scene._process(1.0/60)
        for i in 4:
            scene._physics_process(1.0/60)
            scene._process(1.0/60)
        await shot(move+"_release")
    # Idle pair for the grounding shadow.
    scene.start_match(true)
    for i in 40:scene._present(1.0/60)
    await shot("idle_shadow")
    scene.queue_free()
    await process_frame
    quit()
func prepare(move: String) -> void:
    scene.reduced_effects=false
    scene.start_match(true)
    scene.sim.fighters[0].x=-.8
    scene.sim.fighters[1].x=.8
    scene.sim.fighters[0].meter=100
    for i in 70:scene._present(1.0/60)
    scene.sim._start_attack(0,move)
    for event in scene.sim.events:scene._handle_event(event)
func shot(label: String) -> void:
    scene.hud.queue_redraw()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("%s/%s.png"%[out_dir,label])
