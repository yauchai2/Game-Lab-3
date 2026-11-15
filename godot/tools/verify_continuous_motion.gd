extends SceneTree
const Clock=preload("res://scripts/combat/combat_rhythm.gd")
const Blend=preload("res://scripts/combat/motion_interpolation.gd")
var s:Node
var checks:Array=[]
var hits:Array=[]
var wall:=0
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":label,"passed":ok,"detail":detail});print("CONTINUOUS ",label," ",ok)
func step() -> void:
    s._physics_process(1.0/60);s._process(1.0/60);wall+=1
func start(hero:int) -> void:
    s.return_to_title();s.reduced_effects=false;s.set_character(0,hero);s.set_character(1,(hero+1)%4)
    s.start_match(true);s.round_theatre.clear();s.sim.phase="fight";s.sim.ai_enabled=false
    s.sim.fighters[0].x=-.6;s.sim.fighters[1].x=.6;s.sim.fighters[0].meter=100
    hits.clear();wall=0
func run() -> void:
    for kind in Clock.PROFILES:
        for fps in [30,60,120]:
            var clock:=Clock.new();clock.trigger(kind,0)
            var phases:Dictionary={};var low:=1.0;var high:=0.0;var max_steps:=0;var steps:=0
            for frame in fps*2:
                var n:int=clock.take_steps(1.0/float(fps),true)
                phases[clock.phase()]=true;low=minf(low,clock.view_speed());high=maxf(high,clock.view_speed());max_steps=maxi(max_steps,n);steps+=n
            check("%s / %d fps never enters a stopped phase"%[kind,fps],low>=.35 and high<=1.001 and not phases.has("hold"),{"min":low,"max":high})
            check("%s / %d fps eases back to bounded real flow"%[kind,fps],not clock.active() and max_steps<=2 and steps>=100 and phases.has("slow") and phases.has("release") and phases.has("flow"),steps)
    var base=preload("res://scripts/combat/enemies/squad_simulation.gd").new()
    base.ai_enabled=false;base.phase="fight";base.fighters[0].state="attack";base.fighters[0].move="special";base.fighters[0].frame=10;base.fighters[0].x=0
    var blend:=Blend.new();blend.remember(base);base.fighters[0].frame=11;base.fighters[0].x=1.0
    var snapshot:String=JSON.stringify(base.fighters);var previous_frame:=9.0
    for weight in [0.0,.25,.5,.75,1.0]:
        blend.alpha=weight;var pose:Dictionary=blend.sample(base.fighters[0],"p0")
        check("Committed pose interpolates monotonically %.2f"%weight,pose.frame>previous_frame and is_equal_approx(pose.x,weight));previous_frame=pose.frame
    check("Interpolation never edits authoritative state",snapshot==JSON.stringify(base.fighters))
    base.fighters[0].service.serial+=1;base.fighters[0].frame=0
    check("New attack serial cannot blend backwards",blend.sample(base.fighters[0],"p0").frame==0)
    blend.clear();check("Reset discards interpolation history",blend.previous.is_empty())
    base.begin_squad();blend.clear();blend.remember(base)
    var distinct:=true
    for id in base.squad_members.size():
        var member:Dictionary=base.squad_members[id];var original:float=member.x
        member.x+=.2;blend.alpha=.5
        distinct=distinct and is_equal_approx(blend.sample(member,blend.key_for(member,1,true)).x,original+.1)
    check("Squad interpolation tracks each persistent enemy ID",distinct)
    check("Player and squad enemy interpolation keys cannot collide",blend.key_for(base.fighters[0],0,true)!=blend.key_for(base.squad_members[0],1,true))
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path=""
    root.add_child(s);s.set_process(false);s.set_physics_process(false)
    s.combat_event.connect(func(e:Dictionary):
        if e.kind=="hit" and e.get("attacker",-1)==0:hits.append({"wall":wall,"move":e.move,"stop":s.sim.hitstop,"damage":e.damage}))
    await process_frame;await RenderingServer.frame_post_draw
    for hero in 4:
        for move in ["special","overdrive"]:
            start(hero)
            if hero==3:
                s.pending={"attack":"special"}
                for frame in 50:step()
                hits.clear()
            s.pending={"attack":"node_pulse" if hero==3 and move=="special" else move}
            var same:=0;var longest:=0;var last_frame:float=-1;var min_rate:=1.0
            for frame in 200:
                step();var pose:Dictionary=s.presentation_pose(0);min_rate=minf(min_rate,s.rhythm.view_speed())
                if not hits.is_empty() and pose.state=="attack":
                    same=same+1 if is_equal_approx(float(pose.frame),last_frame) else 0
                    longest=maxi(longest,same);last_frame=float(pose.frame)
            check("Hero %d / %s still hits through normal input"%[hero,move],not hits.is_empty(),hits.duplicate())
            check("Hero %d / %s has zero native skill freeze"%[hero,move],not hits.is_empty() and hits.all(func(h:Dictionary)->bool:return h.stop==0))
            check("Hero %d / %s stays visibly moving after contact"%[hero,move],longest<=2 and min_rate>=.35,{"same_pose_frames":longest,"min_rate":min_rate})
    start(0);s.pending={"attack":"overdrive"}
    for frame in 24:step()
    var held_pose:Dictionary=s.presentation_pose(0);var held_alpha:float=s.render_motion.alpha
    s.pause_game();s._process(.15)
    check("Explicit pause still freezes the sampled pose",s.presentation_pose(0).frame==held_pose.frame and s.render_motion.alpha==held_alpha)
    s.resume_game();s.reduced_effects=true;step()
    check("F2 returns to ordinary realtime",s.rhythm.view_speed()==1.0 and not s.rhythm.active())
    s.return_to_title();check("Exit clears interpolation state",s.render_motion.previous.is_empty())
    await process_frame;await RenderingServer.frame_post_draw
    s.queue_free();s=null
    for frame in 8:await process_frame
    await RenderingServer.frame_post_draw
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var args:=OS.get_cmdline_user_args()
    var out:String=args[0] if not args.is_empty() else "res://../docs/evidence/continuous-slow-motion/verification.json"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
    FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed},"  "))
    call_deferred("quit",0 if failed==0 else 1)
