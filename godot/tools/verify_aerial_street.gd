extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Air=preload("res://scripts/combat/aerial_motion.gd")
var checks: Array[Dictionary]=[]
var metrics: Dictionary={}
func _initialize() -> void:call_deferred("run")
func check(label: String, value: bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("AIR FAIL: "+label)
func fresh() -> RefCounted:
    var s:=Sim.new()
    s.training=true
    s.practice_scenario="air"
    s.phase="fight"
    s.ai_enabled=false
    s.fighters[0].x=-.7
    s.fighters[1].x=.7
    for f in s.fighters:f.meter=100.0
    return s
func launch(s: RefCounted, side:=0) -> void:
    var f: Dictionary=s.fighters[side]
    f.state="attack";f.move="launcher";f.frame=12
    s.tick()
func run() -> void:
    for warning in ["shadowed_variable_base_class","shadowed_global_identifier","integer_division"]:
        ProjectSettings.set_setting("debug/gdscript/warnings/"+warning,2)
    for name in ["aerial_motion","aerial_poses","fight_simulation","fight_session","combat_motions","fighter_visual","fight_hud","fight_vfx","fight_audio"]:
        var script:=GDScript.new()
        script.source_code=FileAccess.get_file_as_string("res://scripts/combat/"+name+".gd")
        check("strict compile "+name,script.reload()==OK)
    var motion:=preload("res://scripts/combat/combat_motions.gd").new()
    var track:={"times":[0.0,.5,1.0],"values":[[0,0,0],[1,2,3],[4,5,6]],"interpolation":"STEP"}
    check("STEP translation holds before a key",motion._sample_vector(track,.49)==Vector3.ZERO)
    check("STEP translation switches exactly on a key",motion._sample_vector(track,.5)==Vector3(1,2,3))
    check("STEP final key is not the previous pose",motion._sample_vector(track,1.0)==Vector3(4,5,6))
    var quaternion_track:={"times":[0.0,1.0],"values":[[0,0,0,1],[0,1,0,0]],"interpolation":"STEP"}
    check("STEP rotations do not interpolate",motion._sample_quat(quaternion_track,.8).is_equal_approx(Quaternion.IDENTITY))
    check("STEP rotation reaches the final pose",motion._sample_quat(quaternion_track,1.0).is_equal_approx(Quaternion(0,1,0,0)))
    var shapes:=preload("res://scripts/combat/impact_shapes.gd").new()
    var valid_shapes:=true
    for move in ["air_jab","air_kick","air_finisher","meteor"]:
        for kind in ["swing","hit","release"]:
            for frame in 6:
                for face in [-1.0,1.0]:
                    for reduced in [false,true]:
                        for shape in shapes.build(kind,move,float(frame)/6,Color.CYAN,face,reduced):
                            valid_shapes=valid_shapes and Geometry2D.triangulate_polygon(shape.points).size()>0
                            for point in shape.points:valid_shapes=valid_shapes and point.is_finite()
    check("all new air attack cels triangulate in both directions",valid_shapes)
    var s=fresh()
    s.tick({"jump":true})
    check("jump begins with ground load",s.fighters[0].y==0 and s.fighters[0].state=="jump_squat")
    for i in 2:s.tick()
    check("three full load ticks stay grounded",s.fighters[0].y==0)
    s.tick()
    check("fourth tick takes off exactly once",s.fighters[0].y>0 and s.events.filter(func(e:Dictionary)->bool:return e.kind=="jump").size()==1)
    var peak:=0.0
    var apex_ticks:=0
    var states: Array[String]=[]
    var air_ticks:=1
    for i in 90:
        s.tick()
        var f: Dictionary=s.fighters[0]
        peak=maxf(peak,f.y)
        if f.y>0:air_ticks+=1
        if f.air.phase=="apex":apex_ticks+=1
        if not f.air.phase in states:states.append(f.air.phase)
    check("jump matches bounded metre scale",peak>2.15 and peak<2.23)
    check("apex hang is finite and visible",apex_ticks>=15 and apex_ticks<25)
    check("one tap returns to grounded idle",s.fighters[0].y==0 and s.fighters[0].state=="idle")
    check("jump exposes rise apex fall landing phases",states.has("rise") and states.has("apex") and states.has("fall") and states.has("land"))
    metrics["jump"]={"peak_m":peak,"apex_ticks":apex_ticks,"air_ticks":air_ticks}
    s=fresh()
    s.tick({"jump":true})
    for i in 20:s.tick()
    s.tick({"down_pressed":true})
    check("fresh down triggers real fast fall",s.fighters[0].vy<=-18 and s.fighters[0].air.fast)
    var hit_points: int=s.fighters[1].health
    for i in 18:s.tick()
    check("plain fast fall has no contact damage",s.fighters[1].health==hit_points)
    check("fast fall lands and resets once-per-flight flag",s.fighters[0].y==0 and not s.fighters[0].air.fast_used)
    s=fresh()
    s.fighters[0].y=2
    s.fighters[0].state="stun"
    s.fighters[0].stun=25
    s.tick({"down_pressed":true})
    check("down cannot cancel hitstun",s.fighters[0].state=="stun" and not s.fighters[0].air.fast)
    s=fresh()
    s.fighters[0].y=2
    for i in 4:
        s.air_motion.attack_stall(s.fighters[0])
        for tick in 4:s.tick()
    check("empty swings consume shared twelve tick stall budget",s.fighters[0].air.stall_left==0)
    for i in 90:s.tick({"attack":"light"} if i%12==0 else {})
    check("repeated air swings cannot fly forever",s.fighters[0].y==0)
    for side in 2:
        s=fresh()
        launch(s,side)
        var defender:=1-side
        check("launcher starts one finite victim timer "+str(side),s.fighters[defender].air.combo_left==150 and s.fighters[side].air.chase_window==30)
        var commands:=[{},{}]
        commands[side]={"dash":true}
        s.tick(commands[0],commands[1])
        while s.hitstop>0:s.tick()
        s.tick()
        check("buffered chase works before victim leaves ground "+str(side),s.fighters[side].state=="chase" and s.fighters[side].meter>=80 and s.fighters[side].meter<100)
        var positions: Array=[]
        for i in 10:
            s.tick()
            var f: Dictionary=s.fighters[side]
            positions.append(Vector2(f.x,f.y))
        check("ten tick chase arrives without an automatic hit "+str(side),s.fighters[side].state=="idle" and s.fighters[side].air.chase_used and s.fighters[defender].health==86)
        check("chase path stays inside the arena "+str(side),positions.all(func(p:Vector2)->bool:return absf(p.x)<=Sim.EDGE and p.y>0 and p.y<=4.5))
        var spent: float=s.fighters[side].meter
        s.fighters[side].air.chase_window=20
        commands=[{},{}];commands[side]={"dash":true}
        s.tick(commands[0],commands[1])
        check("second chase cannot spend again "+str(side),s.fighters[side].meter==spent and s.fighters[side].state!="chase")
    s=fresh()
    launch(s)
    s.fighters[0].meter=19
    s.tick({"dash":true})
    while s.hitstop>0:s.tick()
    s.tick()
    check("insufficient chase energy is not a free fallback dash",s.fighters[0].state!="chase" and s.fighters[0].state!="dash" and s.fighters[0].meter==19)
    s=fresh()
    s.fighters[0].y=1.3
    s.fighters[1].y=1.3
    for move in ["air_jab","air_kick","air_finisher"]:
        s.fighters[0].state="idle"
        s._start_attack(0,"light")
        check("air chain selects "+move,s.fighters[0].move==move)
        var connected:=false
        for i in 45:
            s.tick()
            if s.events.any(func(e:Dictionary)->bool:return e.kind=="hit"):
                connected=true
                break
        check("air move really contacts "+move,connected)
        while s.hitstop>0:s.tick()
    check("three follow-up contacts consume juggle allowance",s.fighters[1].juggle==3)
    s.fighters[0].state="idle"
    s._start_attack(0,"light")
    s.fighters[0].frame=6
    s.fighters[1].y=maxf(.5,s.fighters[1].y)
    check("fourth airborne hit is rejected",not s._can_hit(0))
    s=fresh()
    s.fighters[0].y=1.2
    s.fighters[1].y=1.2
    s.tick({"attack":"heavy","down":true})
    check("down heavy maps to airborne meteor",s.fighters[0].move=="meteor")
    var bounces:=0
    for i in 110:
        s.tick()
        for e in s.events:
            if e.kind=="ground_bounce":bounces+=1
    check("meteor earns exactly one ground bounce",bounces==1)
    s=fresh()
    s.fighters[1].y=2
    s.fighters[1].air.combo_left=1
    s.fighters[1].state="stun"
    s.fighters[1].stun=100
    s.hitstop=20
    s.tick()
    check("combo wall-clock limit releases even during hitstop",s.fighters[1].state=="idle" and s.fighters[1].invuln>0 and s.hitstop==0)
    s=fresh()
    s.fighters[0].y=2
    s.fighters[0].state="attack"
    s.fighters[0].move="air_jab"
    s.fighters[0].frame=0
    s.fighters[0].air.combo_left=1
    s.tick()
    check("an old victim timer cannot interrupt regained control",s.fighters[0].state=="attack" and s.fighters[0].air.combo_left==0 and not s.events.any(func(e:Dictionary)->bool:return e.kind=="air_escape"))
    s.reset_training()
    check("reset exits air scenario and clears all budgets",not s.is_aerial() and s.practice_scenario=="free" and s.fighters[0].air.stall_left==12)
    var legacy:=Sim.new()
    legacy.phase="fight";legacy.ai_enabled=false
    legacy.tick({"jump":true})
    check("formal baseline still jumps immediately with original gravity",legacy.fighters[0].y>0 and is_equal_approx(legacy.fighters[0].vy,10.3-26.0/60.0))
    var a=fresh();var b=fresh()
    var rng:=RandomNumberGenerator.new();rng.seed=110926
    var deterministic:=true
    for tick in 25000:
        var commands:=[{},{}]
        for side in 2:
            if tick%6==0:commands[side]={"axis":rng.randi_range(-1,1),"jump":rng.randf()<.2,"down_pressed":rng.randf()<.12,"down":rng.randf()<.2,"dash":rng.randf()<.15,"attack":"light" if rng.randf()<.7 else "heavy","up":rng.randf()<.2}
        a.tick(commands[0],commands[1]);b.tick(commands[0],commands[1])
        if a.fighters!=b.fighters or a.events!=b.events:deterministic=false
        if tick%1000==999:
            a=fresh();b=fresh()
    check("25000 mixed air ticks remain deterministic",deterministic)
    var folder:="res://../docs/evidence/aerial-street"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open(folder+"/rules.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"metrics":metrics,"replay_ticks":25000},"  "))
    print("AIR_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(1 if failed else 0)
