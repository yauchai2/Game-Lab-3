extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const Motion=preload("res://scripts/combat/last_service/street_motion.gd")
var checks:Array=[]
var actor:Node3D
func _initialize() -> void:call_deferred("run")
func check(label:String,passed:bool,detail:Variant=null) -> void:
    checks.append({"check":label,"pass":passed,"detail":detail});print("STREET_MOTION ",label," ",passed," ",detail)
func fresh(character:int,far:=true) -> RefCounted:
    var sim:=Sim.new();sim.last_service_enabled=true;sim.arcade_enabled=true;sim.ai_enabled=false
    sim.character_choices=[character,1-character];sim.reset_round();sim.phase="fight"
    sim.fighters[0].x=0;sim.fighters[1].x=7 if far else 1.2;sim.fighters[0].meter=100
    return sim
func present(f:Dictionary,stopped:=false,reduced:=false) -> void:
    f.air_enabled=true;f.rush_visual=true
    actor.present(f,1.0/60,stopped,reduced)
func stable(f:Dictionary) -> void:
    for tick in 8:present(f)
func run() -> void:
    actor=Visual.new();root.add_child(actor);actor.neon_enabled=true;actor.setup(Color.WHITE,0)
    check("Earlier kick and hook entries remain available",["KK_Kick","KK_Kick_Mirror","KK_Punch","KK_Guard","KK_Run","KK_Walk","KK_DodgeBack","KK_DodgeForward","KK_Backstep","UAL2_Hook","UAL2_Hook_Rec"].all(func(clip:String)->bool:return actor.motions.library.clips.has(clip)))
    for character in [0,1]:
        actor.setup(Color.WHITE,character)
        var sim:RefCounted=fresh(character);var f:Dictionary=sim.fighters[0]
        for action in ["jab","cross","heavy","finisher","launcher","special","overdrive"]:
            sim=fresh(character);f=sim.fighters[0];sim._start_attack(0,action)
            var move:Dictionary=sim.move_for(f,action);f.move_data=move
            for face in [-1,1]:
                f.face=face;f.frame=move.startup;stable(f)
                var finite:=true
                for bone in actor.skeleton.get_bone_count():finite=finite and actor.skeleton.get_bone_global_pose(bone).is_finite()
                var owner:String="zip_kicks" if character==0 else "rivet_boxing"
                check("Full pose owns %d/%s/%d without inflation"%[character,action,face],finite and actor.motions.pose_owner==owner and actor.oversized_bones.is_empty())
                var socket:String="LeftFoot" if character==0 and action in ["cross","finisher"] else ("RightFoot" if character==0 else "RightHand")
                var before:Vector3=actor.fx_socket(socket);present(f,true);present(f,false,true)
                check("Hitstop and F2 preserve %d/%s/%d"%[character,action,face],before.distance_to(actor.fx_socket(socket))<.001)
        sim=fresh(character);f=sim.fighters[0]
        for velocity in [-2.5,2.5,5.0]:
            f.vx=velocity;stable(f)
            var expected:String="KK_Backstep" if velocity<0 else ("KK_Run" if velocity>4 else "KK_Walk")
            var before_time:float=actor.motions.clip_elapsed
            present(f)
            check("Locomotion %d/%s uses a forward-playing source"%[character,expected],actor.motions.clip_name==expected and actor.motions.clip_elapsed>before_time)
        for velocity in [-8.0,8.0]:
            f.state="dash";f.vx=velocity;f.frame=7;stable(f)
            check("Dash %d/%s uses step motion"%[character,str(velocity)],actor.motions.clip_name==("KK_DodgeBack" if velocity<0 else "KK_DodgeForward"))
        f.state="stun";present(f)
        check("Interruption transfers to reaction %d"%character,actor.motions.pose_owner==("zip_reaction" if character==0 else "rivet_reaction"))
        f.state="idle";f.y=1;present(f)
        check("Air transfers to hero profile %d"%character,actor.motions.pose_owner==("zip_air" if character==0 else "rivet_air"))
        f.y=0;f.air.phase="land";f.air.land=4;present(f)
        check("Landing keeps hero profile without stretch %d"%character,actor.motions.pose_owner==("zip_air" if character==0 else "rivet_air"))
    actor.setup(Color.WHITE,0)
    for action in ["special","overdrive"]:
        var sim:RefCounted=fresh(0,false);var f:Dictionary=sim.fighters[0]
        sim.tick({"attack":action});var hit_clips:Array=[];var max_reach:=0.0
        for tick in 120:
            present(f)
            for event in sim.events:
                if event.kind=="hit" and event.attacker==0:
                    # Simulation may already have armed the next confirmed leg;
                    # record both the actual hit and pending followup selection.
                    hit_clips.append({"tick":tick,"clip":actor.motions.clip_name,"frame":f.frame})
                    var limb:String=preload("res://scripts/combat/ink_fx/fx_recipes.gd").limb(action,0,f)
                    check("Real contact trail follows the current leg "+action+"/"+str(tick),limb==("LeftFoot" if actor.motions.clip_name=="KK_Kick_Mirror" else "RightFoot"))
            max_reach=maxf(max_reach,(actor.fx_socket("RightFoot").x-f.x)*f.face)
            sim.tick()
        check("ZIP "+action+" still confirms its bounded actual contacts",hit_clips.size()==(2 if action=="special" else 3),hit_clips)
        var sequence:Array=hit_clips.map(func(c:Dictionary)->String:return c.clip)
        check("ZIP "+action+" alternates only on confirmed contacts",sequence==(["KK_Kick","KK_Kick_Mirror"] if action=="special" else ["KK_Kick","KK_Kick_Mirror","KK_Kick"]))
        check("ZIP "+action+" presents imported full-body kicks",hit_clips.all(func(c:Dictionary)->bool:return c.clip in ["KK_Kick","KK_Kick_Mirror"]) and max_reach>.35,max_reach)
        sim=fresh(0);f=sim.fighters[0];sim.tick({"attack":action});var mirrored_seen:=false
        for tick in 100:
            present(f);mirrored_seen=mirrored_seen or actor.motions.clip_name=="KK_Kick_Mirror";sim.tick()
        check("ZIP "+action+" miss never invents a followup leg",not mirrored_seen and sim.fighters[1].health==100)
    actor.setup(Color.WHITE,1)
    var sim:RefCounted=fresh(1);var f:Dictionary=sim.fighters[0]
    sim._start_attack(0,"overdrive");f.move_data=sim.move_for(f,"overdrive");f.frame=f.move_data.startup;stable(f)
    check("RIVET shutdown uses the straight punch source",actor.motions.clip_name=="Punch_Cross")
    check("RIVET heavy accents use a fist socket",preload("res://scripts/combat/ink_fx/fx_recipes.gd").limb("overdrive",1,f)=="RightHand")
    f.frame=f.move_data.startup+f.move_data.active+4;stable(f)
    check("RIVET shutdown keeps its nonloop straight recovery",actor.motions.clip_name=="Punch_Cross")
    sim=fresh(1);f=sim.fighters[0];sim._start_attack(0,"launcher");f.move_data=sim.move_for(f,"launcher");f.frame=f.move_data.startup;stable(f)
    check("RIVET launcher sends a fist above its shoulder",actor.fx_socket("RightHand").y>actor.fx_socket("RightArm").y+.1)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.pass).size()
    var output:String=OS.get_cmdline_user_args()[0]
    FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"passed":checks.size()-failed,"scope":"Real rigs, explicit pose fixtures and ordinary fixed-tick skill inputs. Not a human art-quality, shoe-floor or hardware performance test."},"  "))
    actor.queue_free();await process_frame;await RenderingServer.frame_post_draw;quit(1 if failed else 0)
