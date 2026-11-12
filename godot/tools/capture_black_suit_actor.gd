extends SceneTree
## Native render of three instances of the same reusable actor, not gameplay AI.
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var world:=Node3D.new();root.add_child(world)
    var env:=WorldEnvironment.new();env.environment=Environment.new()
    env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("15111d")
    env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.8;world.add_child(env)
    var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-25,0);world.add_child(light)
    var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=3.2;world.add_child(camera)
    camera.position=Vector3(0,1.25,7);camera.look_at(Vector3(0,1.15,0));camera.current=true
    for i in 3:
        var actor=preload("res://scenes/characters/black_suit_actor.tscn").instantiate()
        actor.posture=["idle","walk","guard"][i];actor.position=Vector3((i-1)*1.8,0,0);actor.rotation.y=[.35,-.8,.35][i]
        world.add_child(actor);actor.set_process(false)
        for tick in 12:actor.advance(1.0/30)
    for frame in 8:await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://../docs/evidence/black-suit/actor-poses.png")
    world.queue_free()
    for frame in 8:await process_frame
    await create_timer(.3).timeout;call_deferred("quit")
