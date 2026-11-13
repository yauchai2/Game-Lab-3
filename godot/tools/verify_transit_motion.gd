extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const Transit=preload("res://scripts/combat/last_service/transit_motion.gd")
const Recipes=preload("res://scripts/combat/ink_fx/fx_recipes.gd")
var actor:Node3D
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"check":label,"pass":ok,"detail":detail});print("TRANSIT ",label," ",ok)
func fresh(character:int) -> RefCounted:
    var sim:=Sim.new();sim.last_service_enabled=true;sim.arcade_enabled=true;sim.ai_enabled=false
    sim.character_choices=[character,0];sim.reset_round();sim.phase="fight"
    sim.fighters[0].x=0;sim.fighters[1].x=1.05
    sim.fighters[0].meter=100
    return sim
func present(f:Dictionary,stopped:=false,reduced:=false) -> void:
    var pose:Dictionary=f.duplicate(true);pose.air_enabled=true;pose.rush_visual=true
    actor.present(pose,1.0/60,stopped,reduced)
func stable(f:Dictionary) -> void:
    for tick in 8:present(f)
func matrices() -> Array:
    var result:Array=[]
    for bone in actor.skeleton.get_bone_count():result.append(actor.skeleton.get_bone_global_pose(bone))
    return result
func run() -> void:
    actor=Visual.new();root.add_child(actor);actor.neon_enabled=true
    for hero in 4:
        actor.setup(Color.WHITE,hero)
        for move in ["air_jab","air_kick","air_finisher","meteor","air_counter","special","overdrive","node_pulse","grab"]:
            if move=="node_pulse" and hero!=3:continue
            for face in [-1,1]:
                var sim:RefCounted=fresh(hero);var f:Dictionary=sim.fighters[0]
                f.face=face;f.y=0.0 if move=="grab" else 1.2;f.air.phase="ground" if move=="grab" else "apex"
                if move=="node_pulse":f.service.nodes=[{"x":1.0,"life":300,"id":1}] # Explicit pose/resource fixture.
                sim._start_attack(0,move);f.frame=sim.move_for(f,move).startup;f.move_data=sim.move_for(f,move)
                var snapshot:String=JSON.stringify(sim.fighters);stable(f)
                var finite:=true
                for matrix in matrices():finite=finite and matrix.is_finite()
                var expected:String=Transit.KEYS[hero]+("_throw" if move=="grab" else "_air")
                var limb:String=Recipes.limb(move,hero,f)
                var expected_limb:String="BatonTip" if hero==3 else ("LeftHand" if move=="air_jab" else "RightHand")
                if hero==0:expected_limb="LeftHand" if move=="grab" else ("LeftFoot" if move in ["air_jab","air_finisher"] else "RightFoot")
                if hero==2 and move=="air_kick":expected_limb="RightFoot"
                check("Source/contact owner %d/%s/%d"%[hero,move,face],finite and actor.motions.pose_owner==expected and limb==expected_limb and actor.fx_socket(limb).is_finite(),{"clip":actor.motions.clip_name,"limb":limb})
                var before:Array=matrices()
                for tick in 12:present(f,true,tick%2==0)
                check("Frozen pose, uniform body, F2 and no sim write %d/%s/%d"%[hero,move,face],before==matrices() and actor.oversized_bones.is_empty() and actor.model.scale.is_equal_approx(Vector3.ONE*actor.model_scale) and actor.model.rotation.y==0 and actor.model.position==Vector3.ZERO and snapshot==JSON.stringify(sim.fighters))
        var sim:RefCounted=fresh(hero);var f:Dictionary=sim.fighters[0]
        for phase in ["squat","rise","apex","stall","fall","fast","land","chase"]:
            f.state="chase" if phase=="chase" else ("jump_squat" if phase=="squat" else ("landing" if phase=="land" else "idle"))
            f.air.phase=phase;f.air.air_ticks=5;f.air.squat=1;f.air.land=3
            f.y=0.0 if phase in ["squat","land"] else 1.2;f.vy=5.0 if phase=="rise" else -2.0
            stable(f)
            check("Lifecycle %d/%s"%[hero,phase],actor.motions.pose_owner==Transit.KEYS[hero]+"_air" and actor.model.rotation.y==0 and actor.model.scale.is_equal_approx(Vector3.ONE*actor.model_scale))
        f.state="stun";f.y=.8;f.flash=8;stable(f)
        var before:Array=matrices()
        for tick in 6:present(f,true)
        check("Air reaction freezes %d"%hero,before==matrices() and actor.motions.pose_owner==Transit.KEYS[hero]+"_reaction")
        f.flash=2;present(f);f.flash=8;present(f)
        check("New hit restarts reaction %d"%hero,actor.motions.clip_elapsed==0)
        f.y=0;f.vy=0;f.air.phase="ground";f.state="idle";stable(f)
        check("Return to grounded owner %d"%hero,actor.motions.pose_owner==["zip_kicks","rivet_boxing","hush_intercept","loop_baton"][hero])
        f.y=1;f.state="stun"
        for exclusion in ["showcase","cinematic_clip","rally_phase","ko_theatre","ko_spin","air_counter_phase","ricochet"]:
            var pose:Dictionary=f.duplicate(true)
            match exclusion:
                "showcase":pose.showcase=true
                "cinematic_clip":pose.cinematic_clip="Idle_Loop"
                "rally_phase":pose.rally_phase="compress"
                "ko_theatre":pose.ko_theatre=.1
                "ko_spin":pose.ko_spin=.2
                "air_counter_phase":pose.air_counter_phase="hold"
                "ricochet":pose.ricochet.ticks=5
            check("Exclusive owner handoff %d/%s"%[hero,exclusion],not Transit.owns(pose))
        f.health=0;stable(f)
        check("Death keeps source and clears air label %d"%hero,actor.motions.clip_name=="Death01" and actor.motions.air_pose_name=="")
        # Real normal-input jumps, launcher/chase/air hits and grounded throw. No injected damage.
        sim=fresh(hero);f=sim.fighters[0];var events:Dictionary={};var air_contacts:=0
        for tick in 240:
            var command:Dictionary={}
            if tick==0:command={"attack":"launcher"}
            if tick>=15 and tick<130:command={"rush":true,"jump":tick==18 or tick==28}
            sim.tick(command)
            for event in sim.events:
                events[event.kind]=int(events.get(event.kind,0))+1
                if event.kind=="hit" and event.attacker==0 and event.move in Transit.AIR_ATTACKS:air_contacts+=1
            present(f,sim.hitstop>0)
        check("Real launcher/chase/air confirmation %d"%hero,events.get("homing_chase",0)>0 and air_contacts>0,events)
        sim=fresh(hero);f=sim.fighters[0];var thrown:=0
        for tick in 90:
            sim.tick({"attack":"grab"} if tick==0 else {})
            for event in sim.events:
                if event.kind=="hit" and event.move=="grab":thrown+=1
            present(f,sim.hitstop>0)
        check("Real throw resolves once %d"%hero,thrown==1 and sim.fighters[1].health<100)
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.pass).size()
    FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"scope":"Four real rigs, explicit source/face/hold fixtures including one seeded node for pulse pose only; separate normal-input launcher/chase/air and throw flows without seeded damage. Not terrain foot IK, paired throw mocap, human or hardware FPS validation."},"  "))
    actor.queue_free();await process_frame;await RenderingServer.frame_post_draw;quit(0 if failed==0 else 1)
