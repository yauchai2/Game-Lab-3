extends SceneTree
const Visual=preload("res://scripts/combat/fighter_visual.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var world:=Node3D.new();root.add_child(world)
    var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("303038")
    env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.9;world.add_child(env)
    var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-25,-30,0);world.add_child(light)
    var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.55;world.add_child(camera);camera.current=true
    for version in ["before","after"]:
        var path:String="res://assets/characters/black_suit/source/tripo_convert_6bb9e9c2-dd66-4f86-864f-2ceab3aa0a09.glb" if version=="before" else ""
        var visual:=Visual.new();visual.neon_enabled=true;world.add_child(visual);visual.setup(Color.WHITE,4,path)
        if version=="before":
            for mat in visual.materials:
                if mat.next_pass:mat.next_pass.set_shader_parameter("repaired_suit_neck",false)
        for side in ["front","profile","rear"]:
            camera.position=Vector3(0,1.82,4) if side=="front" else (Vector3(4,1.82,0) if side=="profile" else Vector3(2,1.82,-4))
            camera.look_at(Vector3(0,1.82,0))
            for frame in 5:await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://../docs/evidence/black-suit-squad/repair-%s-%s.png"%[version,side])
        visual.queue_free()
        for frame in 5:await process_frame
    world.queue_free()
    for frame in 8:await process_frame
    await create_timer(.3).timeout;call_deferred("quit")
