extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var world := Node3D.new()
    root.add_child(world)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("b4c8ce")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("dfebed")
    env.environment.ambient_light_energy = .7
    world.add_child(env)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45,-35,0)
    light.light_energy = 1.0
    world.add_child(light)
    var model := (load("res://assets/CHAR_PLAYER_A01.glb") as PackedScene).instantiate()
    model.scale = Vector3.ONE*1.75
    world.add_child(model)
    var camera := Camera3D.new()
    world.add_child(camera)
    camera.current = true
    camera.fov = 40
    var poses := [Vector3(0,1.1,3.6),Vector3(3.6,1.1,0),Vector3(0,1.1,-3.6),Vector3(-3.6,1.1,0)]
    for i in poses.size():
        camera.position = poses[i]
        camera.look_at(Vector3(0,.9,0),Vector3.UP)
        for frame in 8:
            await process_frame
        await RenderingServer.frame_post_draw
        if root.get_texture().get_image().save_png("res://../docs/evidence/character/inspect_"+str(i)+".png") != OK:
            push_error("Character capture failed")
            quit(1)
            return
    print("CHARACTER_INSPECT_CAPTURED renderer=",RenderingServer.get_video_adapter_name())
    world.queue_free()
    await process_frame
    quit()
