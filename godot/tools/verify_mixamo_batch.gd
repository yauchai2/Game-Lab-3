extends SceneTree
## Native rig diagnostic. Attack state samples are fixtures, not a gameplay recording.
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const Data=preload("res://scripts/combat/mixamo_motion_library.gd")
const Profiles=preload("res://scripts/combat/mixamo_profiles.gd")
var checks:Array=[]
var captures:=false
var out:=OS.get_user_data_dir().path_join("mixamo_batch_diagnostic")
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"ok":ok})
    if not ok:push_error(label)
func run() -> void:
    captures="--capture" in OS.get_cmdline_user_args()
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
    DirAccess.make_dir_recursive_absolute(out)
    if not Data.available():push_error("Install the private first batch library first");quit(2);return
    var world:=Node3D.new();root.add_child(world)
    var env:=WorldEnvironment.new();world.add_child(env);env.environment=Environment.new()
    env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("202a38")
    env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.8
    var light:=DirectionalLight3D.new();world.add_child(light);light.rotation_degrees=Vector3(-45,-35,0)
    var camera:=Camera3D.new();world.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=4.4
    camera.position=Vector3(5,2.6,9);camera.look_at(Vector3(0,1.1,3));camera.current=true
    var floor_mesh:=MeshInstance3D.new();world.add_child(floor_mesh);floor_mesh.mesh=PlaneMesh.new();floor_mesh.mesh.size=Vector2(30,30)
    var label:=Label.new();root.add_child(label);label.position=Vector2(25,25);label.add_theme_font_size_override("font_size",24)
    var sim=Sim.new();sim.last_service_enabled=true;sim.training=true;sim.ai_enabled=false
    var actor=Visual.new();world.add_child(actor)
    var rows:Array=[]
    for hero in 4:
        actor.setup(Color.WHITE,hero)
        await process_frame;await RenderingServer.frame_post_draw
        for face in [-1,1]:
            for move in ["jab","cross","heavy","finisher"]:
                if hero==3 and move in ["jab","launcher"]:continue
                sim.character_choices=[hero,0];sim.reset_round()
                var f:Dictionary=sim.fighters[0]
                f.state="attack";f.move=move;f.x=0.0;f.face=face;f.vx=0.0;f.y=0.0
                f.move_data=sim.move_for(f,move)
                var valid:=true
                var minimum:=INF
                var snapshots:Array=[]
                for frame in range(int(f.move_data.startup+f.move_data.active+f.move_data.recovery)+1):
                    f.frame=frame
                    var before:String=JSON.stringify(f)
                    actor.present(f,1.0/60.0,false,false)
                    valid=valid and actor.motions.pose_owner.begins_with("mixamo_") and actor.position==Vector3(0,0,3) and before==JSON.stringify(f)
                    minimum=minf(minimum,actor.lowest_skin_y())
                    for bone in actor.skeleton.get_bone_count():
                        var basis:Basis=actor.skeleton.get_bone_global_pose(bone).basis
                        valid=valid and basis.is_finite() and absf(basis.determinant()-1.0)<.002
                    if frame==int(f.move_data.startup):
                        var limb:String=Profiles.limb(f)
                        snapshots.append(limb)
                        check("contact limb %d/%s/%d"%[hero,move,face],limb!="" and limb==preload("res://scripts/combat/last_service/street_motion.gd").striking_limb(f))
                    if captures and face==1 and frame in [0,int(f.move_data.startup),int(f.move_data.startup+f.move_data.active+f.move_data.recovery)]:
                        label.text="%s | %s | frame %d | %s"%[["ZIP","RIVET","HUSH","LOOP"][hero],move,frame,actor.motions.clip_name]
                        await process_frame;await RenderingServer.frame_post_draw
                        root.get_texture().get_image().save_png(out+"/%d-%s-%03d.png"%[hero,move,frame])
                check("finite single owner %d/%s/%d"%[hero,move,face],valid)
                check("rendered skin floor %d/%s/%d"%[hero,move,face],minimum>=.008)
                rows.append({"hero":hero,"move":move,"face":face,"min_skin_y":minimum,"clip":actor.motions.clip_name,"limbs":snapshots})
        sim.character_choices=[hero,0];sim.reset_round()
        var f:Dictionary=sim.fighters[0];f.x=0.0
        for speed in [1.0,-1.0,6.0]:
            f.vx=speed;f.face=1
            var descriptor:Dictionary=Profiles.describe(f,{})
            check("forward walking only %d/%s"%[hero,speed],(descriptor.get("clip","")=="MX_Walking")==(speed==1.0))
        if Data.data.clips.has("MX_Run"):
            for face in [-1,1]:
                f.face=face
                f.vx=3.6*face
                var running:Dictionary=Profiles.describe(f,{})
                var min_run_y:=INF
                for tick in 60:
                    actor.present(f,1.0/60.0,false,false)
                    min_run_y=minf(min_run_y,actor.lowest_skin_y())
                check("forward run retarget and skin floor %d/%d"%[hero,face],running.get("clip","")=="MX_Run" and running.loop and actor.motions.clip_name=="MX_Run" and min_run_y>=.008)
                f.vx=-3.6*face
                var reverse:Dictionary=Profiles.describe(f,{})
                check("medium reverse keeps its own source %d/%d"%[hero,face],reverse.get("clip","")==("MX_RunBack" if Data.data.clips.has("MX_RunBack") else ""))
        if Data.data.clips.has("MX_Sprint"):
            for face in [-1,1]:
                f.face=face
                f.vx=8.0*face
                var min_sprint_y:=INF
                for tick in 70:
                    actor.present(f,1.0/60.0,false,false)
                    min_sprint_y=minf(min_sprint_y,actor.lowest_skin_y())
                check("full-speed sprint and skin floor %d/%d"%[hero,face],actor.motions.clip_name=="MX_Sprint" and min_sprint_y>=.008)
        if Data.data.clips.has("MX_WalkBack"):
            for face in [-1,1]:
                f.face=face
                f.guarding=true
                f.vx=-1.6*face
                var backward:Dictionary=Profiles.describe(f,{})
                var minimum_y:=INF
                var before:=JSON.stringify(f)
                for tick in 105:
                    actor.present(f,1.0/60.0,false,false)
                    minimum_y=minf(minimum_y,actor.lowest_skin_y())
                check("guarded backwalk %d/%d"%[hero,face],backward.get("clip","")=="MX_WalkBack" and backward.loop and backward.guard_arms and actor.motions.clip_name=="MX_WalkBack")
                check("backwalk floor and presentation only %d/%d"%[hero,face],minimum_y>=.008 and before==JSON.stringify(f))
                f.vx=-6.0*face
                var expected_reverse:String="MX_RunBack" if Data.data.clips.has("MX_RunBack") else ""
                var reversed_pose:Dictionary=Profiles.describe(f,{})
                check("fast reverse uses a separate gait %d/%d"%[hero,face],reversed_pose.get("clip","")==expected_reverse)
                if expected_reverse!="":
                    var min_reverse_y:=INF
                    for tick in 45:
                        actor.present(f,1.0/60.0,false,false)
                        min_reverse_y=minf(min_reverse_y,actor.lowest_skin_y())
                    check("fast reverse retarget and skin floor %d/%d"%[hero,face],actor.motions.clip_name==expected_reverse and min_reverse_y>=.008)
            var back_clip:Dictionary=Data.data.clips.MX_WalkBack
            var closes:=true
            for track in back_clip.tracks.values():
                if track.has("rotation"):
                    var values:Array=track.rotation.values
                    var first:Array=values.front()
                    var last:Array=values.back()
                    closes=closes and Quaternion(first[0],first[1],first[2],first[3]).angle_to(Quaternion(last[0],last[1],last[2],last[3]))<.015
            check("backwalk closes at source seam %d"%hero,closes)
        f.guarding=true;f.vx=1.4;f.face=1
        actor.present(f,1.0/60.0,false,false)
        check("guard walking keeps arms %d"%hero,Profiles.describe(f,{}).guard_arms and actor.motions.clip_name=="MX_Walking")
        var old:Array=[]
        for bone in actor.skeleton.get_bone_count():old.append(actor.skeleton.get_bone_pose_rotation(bone))
        var frozen:=true
        for tick in 4:
            actor.present(f,1.0/60.0,true,false)
            for bone in actor.skeleton.get_bone_count():frozen=frozen and old[bone].is_equal_approx(actor.skeleton.get_bone_pose_rotation(bone))
        check("hitstop holds walk clock %d"%hero,frozen)
        f.vx=0.0;f["cinematic_clip"]="Idle_Loop"
        check("cinematic owns %d"%hero,not Profiles.owns(f));f.erase("cinematic_clip")
        f.health=0
        check("death owner preserved %d"%hero,not Profiles.owns(f))
    var saved:Dictionary=Data.data;Data.data={};Data.checked=true
    var f:Dictionary=sim.fighters[0];f.health=100
    check("missing data fallback",not Profiles.owns(f));Data.data=saved
    label.queue_free();actor.queue_free();world.queue_free()
    for i in 8:await process_frame
    var passed:=0
    for item in checks:
        if item.ok:passed+=1
    var file:=FileAccess.open(out+"/report.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":passed,"total":checks.size(),"checks":checks,"rig_rows":rows},"  "));file.close()
    print("MIXAMO_BATCH ",passed,"/",checks.size())
    quit(0 if passed==checks.size() else 1)
