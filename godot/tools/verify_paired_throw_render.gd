extends SceneTree
## Independent renderer skin bake, not the CPU floor helper being tested.
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const Motion=preload("res://scripts/combat/paired_throw_motion.gd")
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
    if DisplayServer.get_name()=="headless":push_error("Native display required");quit(2);return
    if not Sim.ThrowData.available():push_error("Private animation library required");quit(2);return
    var actors:Array=[]
    for i in 2:
        var v=Visual.new();root.add_child(v);actors.append(v)
    for hero in 4:
        for face in [-1,1]:
            var sim=Sim.new();sim.character_choices=[hero,(hero+1)%4];sim.last_service_enabled=true;sim.ai_enabled=false
            sim.reset_round();sim.phase="fight";sim.fighters[0].x=-.45*face;sim.fighters[1].x=.45*face
            for i in 2:actors[i].setup(Color.WHITE,sim.character_choices[i])
            for tick in 130:
                sim.tick({"attack":"grab"} if tick==0 else {},{})
                if not sim.paired_throw.active() or sim.paired_throw.age not in [8,32,60,96]:continue
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
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path="";scene.progression_path="";root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false)
    await process_frame
    await RenderingServer.frame_post_draw
    scene.start_match(false);scene.round_theatre.clear();scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=-.45;scene.sim.fighters[1].x=.45;scene.sim.fighters[1].health=5
    await process_frame
    await RenderingServer.frame_post_draw
    for tick in 150:
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
