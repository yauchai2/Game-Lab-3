extends SceneTree
## Actual hero rigs, all legal move families and locomotion; explicit pose fixtures.
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const Data=preload("res://scripts/combat/mixamo_motion_library.gd")
var checks:Array=[]
var rows:Array=[]
var out:=OS.get_user_data_dir().path_join("motion_completion")
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"ok":ok})
    if not ok:push_error(label)
func run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
    DirAccess.make_dir_recursive_absolute(out)
    if not Data.available() or not Sim.ThrowData.available():push_error("Bundled motion files missing");quit(2);return
    check("default libraries are inside tracked game assets",Data.DEFAULT_PATH.begins_with("res://assets/") and Sim.ThrowData.DEFAULT_PATH.begins_with("res://assets/"))
    check("all 23 supplied motion derivatives available",Data.data.clips.size()>=23)
    var world:=Node3D.new();root.add_child(world)
    var env:=WorldEnvironment.new();world.add_child(env);env.environment=Environment.new()
    env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("1f2633")
    env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.85
    var light:=DirectionalLight3D.new();world.add_child(light);light.rotation_degrees=Vector3(-40,-35,0)
    var camera:=Camera3D.new();world.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=5.0
    camera.position=Vector3(5,2.6,9);camera.look_at(Vector3(0,1.25,3));camera.current=true
    var floor_mesh:=MeshInstance3D.new();world.add_child(floor_mesh);floor_mesh.mesh=PlaneMesh.new();floor_mesh.mesh.size=Vector2(20,20)
    var label:=Label.new();root.add_child(label);label.position=Vector2(20,20);label.add_theme_font_size_override("font_size",23)
    var actor=Visual.new();world.add_child(actor);actor.neon_enabled=true
    var sim=Sim.new();sim.last_service_enabled=true;sim.arcade_enabled=true;sim.ai_enabled=false
    for hero in 4:
        actor.setup(Color.WHITE,hero)
        await process_frame;await RenderingServer.frame_post_draw
        for face in [-1,1]:
            for airborne in [false,true]:
                for move in Sim.MOVES:
                    if move=="gun" or (move=="node_pulse" and hero!=3) or (move=="grab" and airborne):continue
                    if not airborne and move.begins_with("air_"):continue
                    if not airborne and move=="meteor":continue
                    sim.character_choices=[hero,0];sim.reset_round()
                    var f:Dictionary=sim.fighters[0];f.x=0.0;f.face=face;f.state="attack";f.move=move
                    f.y=1.2 if airborne else 0.0;f.vx=0.0;f.air_enabled=true;f.rush_visual=true
                    f.air.phase="apex" if airborne else "ground";f.move_data=sim.move_for(f,move)
                    var valid:=true;var floor_ok:=true;var frozen:=true
                    for frame in [0,int(f.move_data.startup)-1,int(f.move_data.startup),int(f.move_data.startup+f.move_data.active),int(f.move_data.startup+f.move_data.active+f.move_data.recovery)]:
                        f.frame=frame
                        var before:String=JSON.stringify(f)
                        actor.present(f,1.0/60.0,false,false)
                        valid=valid and actor.motions.pose_owner!="legacy" and actor.oversized_bones.is_empty() and before==JSON.stringify(f)
                        for bone in actor.skeleton.get_bone_count():valid=valid and actor.skeleton.get_bone_global_pose(bone).is_finite()
                        if not airborne:floor_ok=floor_ok and actor.lowest_skin_y()>=.008
                        var snapshot:Array=[]
                        for bone in actor.skeleton.get_bone_count():snapshot.append(actor.skeleton.get_bone_global_pose(bone))
                        var model_transform:Transform3D=actor.model.transform
                        actor.present(f,1.0/60.0,true,true)
                        for bone in actor.skeleton.get_bone_count():frozen=frozen and snapshot[bone].is_equal_approx(actor.skeleton.get_bone_global_pose(bone))
                        frozen=frozen and model_transform.is_equal_approx(actor.model.transform)
                        if face==1 and airborne and move in ["air_jab","air_kick","meteor"] and frame==int(f.move_data.startup):
                            label.text="%s | %s | %s"%[["ZIP","RIVET","HUSH","LOOP"][hero],move,actor.motions.clip_name]
                            await process_frame;await RenderingServer.frame_post_draw
                            root.get_texture().get_image().save_png(out+"/%d-%s.png"%[hero,move])
                    var key:String="%d/%d/%s/%s"%[hero,face,str(airborne),move]
                    check("finite exclusive owner and no simulation writes "+key,valid)
                    check("floor "+key,floor_ok)
                    check("F2 and hitstop "+key,frozen)
                    rows.append({"hero":hero,"face":face,"airborne":airborne,"move":move,"clip":actor.motions.clip_name,"owner":actor.motions.pose_owner})
            for state in ["idle","dash","stun","blockstun","jump_squat","landing","chase"]:
                sim.reset_round();var f:Dictionary=sim.fighters[0];f.character=hero;f.x=0;f.face=face;f.state=state;f.air_enabled=true
                f.y=.7 if state=="chase" else 0.0;f.frame=6
                f.air.phase="squat" if state=="jump_squat" else ("land" if state=="landing" else ("apex" if state=="chase" else "ground"))
                actor.present(f,.1,false,false)
                check("state owner %d/%d/%s"%[hero,face,state],actor.motions.pose_owner!="legacy")
        sim.reset_round();var corpse:Dictionary=sim.fighters[0];corpse.character=hero;corpse.x=0;corpse.state="idle";corpse.health=100
        actor.present(corpse,.1,false,false);corpse.health=0;actor.present(corpse,.1,false,false);actor.present(corpse,4.0,false,false)
        check("authored KO settles %d"%hero,actor.motions.clip_name=="Death01" and actor.motions.library.clips.Death01==Data.data.clips.MX_KnockedOut and absf(actor.lowest_skin_y()-.015)<.01)
        label.text="%s | Knocked Out"%["ZIP","RIVET","HUSH","LOOP"][hero]
        await process_frame;await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(out+"/%d-knocked-out.png"%hero)
    actor.queue_free();label.queue_free();world.queue_free()
    for frame in 8:await process_frame
    var passed:=0
    for item in checks:
        if item.ok:passed+=1
    FileAccess.open(out+"/report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"total":checks.size(),"checks":checks,"coverage":rows},"  "))
    print("MOTION_COMPLETION ",passed,"/",checks.size())
    quit(0 if passed==checks.size() else 1)
