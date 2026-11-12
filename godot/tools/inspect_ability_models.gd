extends SceneTree
const OUT="res://../docs/evidence/ability-draw/tripo-models/"
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var world:=Node3D.new();root.add_child(world)
    var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("72717e");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.8;world.add_child(env)
    var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-20,0);light.light_energy=1.2;world.add_child(light)
    var files:=["res://assets/ability_draw/source/tripo_convert_36d4f0c3-b64c-4ea1-841e-104fd70e96ae.glb","res://assets/ability_draw/source/tripo_convert_275dc57f-e328-47e0-89e5-10195d3209c4.glb"]
    for i in 2:
        var model=(load(files[i]) as PackedScene).instantiate();world.add_child(model);model.scale=Vector3.ONE*(3.0 if i==0 else 2.0);model.position=Vector3(-1.6 if i==0 else 1.6,0,0)
        var rigs=model.find_children("*","Skeleton3D",true,false)
        if not rigs.is_empty():
            var rig:Skeleton3D=rigs[0];print("RIG ",rig.get_path()," ",rig.get_bone_count()," BASIS ",rig.global_basis)
            for bone in rig.get_bone_count():
                var name:=rig.get_bone_name(bone)
                if name.ends_with("Hips") or name.ends_with("Head") or name.ends_with("Arm") or name.ends_with("ForeArm") or name.ends_with("Hand") or name.ends_with("UpLeg") or name.ends_with("Leg") or name.ends_with("Foot"):
                    print("BONE ",bone," ",name," skeleton ",rig.get_bone_global_pose(bone).origin," world ",rig.to_global(rig.get_bone_global_pose(bone).origin))
    var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(0,1.65,7.8);camera.look_at(Vector3(0,1.5,0));camera.fov=42;camera.make_current()
    if DisplayServer.get_name()!="headless":
        for i in 3:await process_frame
        await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+"source-models-front.png")
        camera.position=Vector3(5,2.4,6);camera.look_at(Vector3(0,1.5,0))
        for i in 2:await process_frame
        await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+"source-models-angle.png")
    world.queue_free()
    for i in 8:await process_frame
    quit()
