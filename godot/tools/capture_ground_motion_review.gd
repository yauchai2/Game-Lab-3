extends SceneTree
const Sim=preload("res://scripts/combat/enemies/squad_simulation.gd")
const Blend=preload("res://scripts/combat/motion_interpolation.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
var world:Node3D
var actor:Node3D
var camera:Camera3D
var caption:Label
var rows:Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
    world=Node3D.new();root.add_child(world)
    var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("151822");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.7;world.add_child(env)
    var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,-35,0);world.add_child(light)
    var ground:=MeshInstance3D.new();ground.mesh=PlaneMesh.new();ground.mesh.size=Vector2(36,20);var material:=StandardMaterial3D.new();material.albedo_color=Color("454a55");ground.material_override=material;world.add_child(ground)
    var edge:=MeshInstance3D.new();edge.mesh=BoxMesh.new();edge.mesh.size=Vector3(.03,.08,4);edge.position=Vector3(Sim.EDGE+.1,.04,3);var accent:=StandardMaterial3D.new();accent.albedo_color=Color("ff459d");edge.material_override=accent;world.add_child(edge)
    camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=3.8;world.add_child(camera);camera.make_current()
    var overlay:=CanvasLayer.new();root.add_child(overlay);caption=Label.new();caption.position=Vector2(25,20);caption.add_theme_font_size_override("font_size",24);overlay.add_child(caption)
    var number:=0
    for hero in 4:
        if actor!=null:actor.queue_free();await process_frame;await RenderingServer.frame_post_draw
        actor=Visual.new();actor.neon_enabled=true;world.add_child(actor);actor.setup(Color.WHITE,hero)
        var sim=Sim.new();sim.last_service_enabled=true;sim.arcade_enabled=true;sim.ai_enabled=false;sim.character_choices=[hero,1];sim.reset_round();sim.phase="fight"
        sim.fighters[0].x=7.0;sim.fighters[1].x=-7;var f:Dictionary=sim.fighters[0];f.face=-1
        var blend=Blend.new()
        for tick in 90:
            var old_x:float=f.x;blend.remember(sim);sim.tick({"axis":1.0 if tick<60 else -1.0});blend.alpha=1.0
            var pose:Dictionary=blend.sample(f,"p0");pose.air_enabled=true;pose.rush_visual=true
            actor.present(pose,1.0/60,sim.hitstop>0,false)
            camera.global_position=actor.global_position+Vector3(3.8,1.7,5);camera.look_at(actor.global_position+Vector3(0,.85,0))
            caption.text=["ZIP","RIVET","HUSH","LOOP"][hero]+" / "+("EDGE" if tick<60 else "RELEASE / RETURN")+"\nACTUAL %.2f  REQUEST %.2f  POSE %.2f"%[(f.x-old_x)*60,f.vx,pose.vx]
            rows.append({"hero":hero,"tick":tick,"x":f.x,"requested_vx":f.vx,"pose_vx":pose.vx,"clip":actor.motions.clip_name})
            if tick%2==0:
                await process_frame;await RenderingServer.frame_post_draw
                root.get_texture().get_image().save_png(out+"/frame_%04d.png"%number);number+=1
    FileAccess.open(out+"/capture.json",FileAccess.WRITE).store_string(JSON.stringify({"frames":number,"fps":30,"seconds":6,"rows":rows,"scope":"Four real hero rigs; ordinary semantic movement into physical arena limit and return. Neutral diagnostic floor/camera/lighting, not the playable street camera. Rendered at fixed60Hz, not hardware FPS or human art certification."},"  "))
    world.queue_free();overlay.queue_free()
    for i in 8:await process_frame;await RenderingServer.frame_post_draw
    quit(0)
