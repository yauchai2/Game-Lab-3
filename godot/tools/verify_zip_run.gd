extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Delivery=preload("res://scripts/combat/last_service/zip_delivery.gd")
const Motion=preload("res://scripts/combat/last_service/street_motion.gd")
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":label,"passed":ok,"detail":detail});print("ZIP_RUN ",label," ",ok)
func fresh(face:int,gap:float) -> RefCounted:
    var s:=Sim.new();s.last_service_enabled=true;s.arcade_enabled=true;s.ai_enabled=false;s.character_choices=[0,1];s.reset_round();s.phase="fight"
    s.fighters[0].x=0;s.fighters[1].x=gap*face;s.fighters[0].face=face;s.fighters[1].face=-face;s.fighters[0].meter=100
    s.tick({"attack":"overdrive"});return s
func run() -> void:
    for face in [-1,1]:
        var s:RefCounted=fresh(face,4.4);var f:Dictionary=s.fighters[0]
        var positions:Array=[float(f.x)];var invuln:=false
        for tick in 20:
            s.tick();positions.append(float(f.x));invuln=invuln or f.invuln>0
        check("Visible world-space running displacement %d"%face,float(f.x)*face>1.8 and float(f.x)*face<=Delivery.RUN_LIMIT+.01,positions)
        check("Run never passes through the opponent %d"%face,(s.fighters[1].x-f.x)*face>=Delivery.STOP_GAP-.01)
        check("Run creates no free invulnerability %d"%face,not invuln)
        var stopped:float=f.x
        for tick in 3:s.tick()
        check("Transition brakes before first kick %d"%face,absf(float(f.x)-stopped)<.001)
        s=fresh(face,.8);f=s.fighters[0]
        for tick in 8:s.tick()
        check("Near opponent skips in-place running %d"%face,absf(f.x)<.001 and not Delivery.running(f))
        var markers:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/animations/street_library.json")).markers
        var pose:Dictionary=Motion.describe(f,s.move_for(f,"overdrive"),markers)
        check("Blocked run uses a planted guard pose %d"%face,pose.clip=="KK_Guard")
        s=fresh(face,7);f=s.fighters[0]
        for tick in 6:s.tick()
        pose=Motion.describe(f,s.move_for(f,"overdrive"),markers)
        var held:float=f.x;var sampled:float=pose.phase
        for render in 10:pose=Motion.describe(f,s.move_for(f,"overdrive"),markers)
        check("Render-only frames cannot move feet or actor %d"%face,pose.phase==sampled and f.x==held)
        check("Run gait follows actual travelled distance %d"%face,is_equal_approx(sampled,fposmod(Delivery.run_distance(f)/Delivery.RUN_STRIDE,1.0)))
        s=fresh(face,7);f=s.fighters[0];f.x=face*(s.EDGE-.1);f.service.delivery_origin=f.x
        for tick in 30:s.tick()
        check("Arena boundary remains solid %d"%face,absf(f.x)<=s.EDGE and f.x*face>=0)
        s=fresh(face,4.4);f=s.fighters[0]
        for tick in 5:s.tick()
        var before:float=f.x;s.hitstop=3
        for tick in 3:s.tick()
        check("Hitstop freezes real run displacement %d"%face,f.x==before)
        s=fresh(face,7);f=s.fighters[0];f.y=1.0;f.vx=face*2.0
        s.tick()
        check("Airborne overdrive keeps existing horizontal momentum %d"%face,absf(f.vx)>1.0 and not Delivery.running(f))
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed},"  "))
    call_deferred("quit",0 if failed==0 else 1)
