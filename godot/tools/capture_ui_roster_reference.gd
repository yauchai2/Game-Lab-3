extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var stage:=Node3D.new();root.add_child(stage);current_scene=stage
    var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("eee5d0");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.8;world.environment=env;stage.add_child(world)
    var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-25,0);sun.light_energy=1.4;stage.add_child(sun)
    var camera:=Camera3D.new();camera.position=Vector3(0,1.2,12);camera.fov=35;stage.add_child(camera);camera.look_at(Vector3(0,1.05,3));camera.current=true
    var sim=preload("res://scripts/combat/fight_simulation.gd").new()
    for i in 4:
        var visual=preload("res://scripts/combat/fighter_visual.gd").new();stage.add_child(visual);visual.setup(Color.WHITE,i)
        var pose:Dictionary=sim.fighters[0].duplicate(true);pose.x=-3.0+i*2.0
        for t in 90:visual.present(pose,1.0/60,false,true)
        visual.rotation.y=.12
    for i in 4:await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://../references/ui-jsr-2026-11-09/roster-model-reference.png")
    stage.queue_free();await process_frame;call_deferred("quit")
