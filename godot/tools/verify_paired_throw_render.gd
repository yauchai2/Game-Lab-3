extends SceneTree
## Independent renderer skin bake, not the CPU floor helper being tested.
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const Motion=preload("res://scripts/combat/paired_throw_motion.gd")
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
    if DisplayServer.get_name()=="headless":push_error("Native display required");quit(2);return
    if not Sim.ThrowData.available():push_error("Bundled shoulder-throw asset missing or incompatible");quit(2);return
    var actors:Array=[]
    var capture_nodes:Array=[]
    var args:PackedStringArray=OS.get_cmdline_user_args()
    var capture_path:String=args[1] if args.size()>1 else ""
    var label:Label
    if not capture_path.is_empty():
        DirAccess.make_dir_recursive_absolute(capture_path)
        var env:=WorldEnvironment.new();root.add_child(env);capture_nodes.append(env);env.environment=Environment.new()
        env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("202a38")
        env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.85
        var light:=DirectionalLight3D.new();root.add_child(light);capture_nodes.append(light);light.rotation_degrees=Vector3(-45,-35,0)
        var camera:=Camera3D.new();root.add_child(camera);capture_nodes.append(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=5.0
        camera.position=Vector3(5,3.5,10);camera.look_at(Vector3(0,1.1,3));camera.current=true
        label=Label.new();root.add_child(label);capture_nodes.append(label);label.position=Vector2(25,25);label.add_theme_font_size_override("font_size",23)
    for i in 2:
        var v=Visual.new();root.add_child(v);actors.append(v)
    for hero in 4:
        for face in [-1,1]:
            var sim=Sim.new();sim.character_choices=[hero,(hero+1)%4];sim.last_service_enabled=true;sim.ai_enabled=false
            sim.reset_round();sim.phase="fight";sim.fighters[0].x=-.45*face;sim.fighters[1].x=.45*face
            for i in 2:actors[i].setup(Color.WHITE,sim.character_choices[i])
            for tick in 200:
                sim.tick({"attack":"grab"} if tick==0 else {},{})
                if not sim.paired_throw.active() or sim.paired_throw.age not in [8,32,60,80,96,120,140,143]:continue
                if sim.hitstop>0:continue
                for i in 2:actors[i].present(sim.fighters[i],1.0/60.0,false,false)
                Motion.correct_contacts(actors[0],actors[1])
                await process_frame
                await RenderingServer.frame_post_draw
                var low:=INF
                for v in actors:
                    for mesh in v.model.find_children("*","MeshInstance3D",true,false):
                        if mesh.skin==null:continue
                        var baked:Mesh=mesh.bake_mesh_from_current_skeleton_pose()
                        for surface in baked.get_surface_count():
                            for vertex in baked.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:low=minf(low,mesh.to_global(vertex).y)
                checks.append({"hero":hero,"face":face,"age":sim.paired_throw.age,"renderer_skin_low_y":low,"pass":low>=-.015})
                if not capture_path.is_empty() and face==1 and sim.paired_throw.age>=80:
                    label.text="%s throws %s | Getting Up | shared tick %d"%[["ZIP","RIVET","HUSH","LOOP"][hero],["ZIP","RIVET","HUSH","LOOP"][(hero+1)%4],sim.paired_throw.age]
                    await process_frame;await RenderingServer.frame_post_draw
                    root.get_texture().get_image().save_png(capture_path+"/%d-%03d.png"%[hero,sim.paired_throw.age])
    for node in capture_nodes:node.queue_free()
    if not capture_nodes.is_empty():
        await process_frame;await RenderingServer.frame_post_draw
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path="";scene.progression_path="";root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false)
    await process_frame
    await RenderingServer.frame_post_draw
    scene.start_match(false);scene.round_theatre.clear();scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=-.45;scene.sim.fighters[1].x=.45;scene.sim.fighters[1].health=5
    await process_frame
    await RenderingServer.frame_post_draw
    for tick in 200:
        if tick==0:scene.pending={"attack":"grab"}
        scene._combat_step();scene._process(1.0/60.0)
        if tick%15==0:
            await process_frame
            await RenderingServer.frame_post_draw
    checks.append({"check":"landed throw KO does not replay airborne KO tumble","pass":scene.screen=="result" and scene.sim.fighters[1].health==0 and not scene.ko_tumble.active()})
    scene.return_to_title();scene.queue_free();scene=null
    for v in actors:v.queue_free()
    actors.clear()
    for frame in 8:await process_frame
    await RenderingServer.frame_post_draw
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.pass).size()
    FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"method":"Native renderer bake of actual deformed hero mesh, independent of CPU floor calculation"},"  "))
    print("PAIRED_RENDER_RESULT ",checks.size()-failed,"/",checks.size())
    quit(1 if failed else 0)
