extends SceneTree
const Sim=preload("res://scripts/combat/fight_simulation.gd")
const Squad=preload("res://scripts/combat/enemies/squad_simulation.gd")
const Visual=preload("res://scripts/combat/fighter_visual.gd")
const Motion=preload("res://scripts/combat/paired_throw_motion.gd")
const Data=preload("res://scripts/combat/paired_throw_library.gd")
var checks:Array=[]
var stats:Dictionary={"max_wrist_gap_m":0.0,"min_skin_y":INF,"max_ground_error_m":0.0}
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"check":label,"pass":ok,"detail":detail})
    print("PAIRED ",label," ",ok," ",detail if not ok else "")
func fresh(a:=0,b:=1,face:=1,side:=0) -> RefCounted:
    var s=Sim.new();s.last_service_enabled=true;s.ai_enabled=false
    s.character_choices=[a,b];s.reset_round();s.phase="fight"
    s.fighters[side].x=-.45*face;s.fighters[1-side].x=.45*face
    s.fighters[side].face=face;s.fighters[1-side].face=-face
    return s
func command(s:RefCounted,tick:int,side:=0,spam:=false) -> void:
    var input:Dictionary={"attack":"grab"} if tick==0 else ({"attack":"special","jump":true,"dash":true,"guard":true} if spam and s.paired_throw.active() else {})
    s.tick(input if side==0 else {},input if side==1 else {})
func snapshots(v:Node3D) -> Array:
    var result:Array=[]
    for bone in v.skeleton.get_bone_count():result.append(v.skeleton.get_bone_global_pose(bone))
    result.append(v.model.transform)
    return result
func run() -> void:
    if not Data.available():push_error("Bundled shoulder-throw asset missing; pull assets or rebuild with tools/import_mixamo_throw.py");quit(2);return
    for a in 4:
        for b in 4:
            for face in [-1,1]:
                for side in 2:
                    var s:RefCounted=fresh(a,b,face,side)
                    var hits:=0;var landings:=0;var starts:=0;var end:=0
                    var valid:=true
                    for tick in 200:
                        command(s,tick,side,true)
                        for event in s.events:
                            if event.kind=="hit":hits+=1;valid=valid and s.paired_throw.age==60
                            if event.kind=="throw_land":landings+=1
                            if event.kind=="throw_start":starts+=1
                            if event.kind=="throw_end":end+=1
                        if s.paired_throw.active() and not s.paired_throw.landed:valid=valid and s.fighters[1-side].health==100
                        if s.paired_throw.active() and s.paired_throw.age>=80:
                            for i in 2:valid=valid and (s.fighters[1-i].x-s.fighters[i].x)*s.fighters[i].face>=0
                        if s.paired_throw.active() and s.paired_throw.age==143:
                            for f in s.fighters:valid=valid and absf(f.paired_throw.depth)<.002
                        for f in s.fighters:valid=valid and is_finite(f.x) and absf(f.x)<=s.EDGE and f.y==0
                    check("matrix %d/%d face %d owner %d"%[a,b,face,side],valid and hits==1 and landings==1 and starts==1 and end==1 and s.fighters[1-side].health==88 and not s.paired_throw.active())
    var trade:RefCounted=fresh()
    for tick in 40:trade.tick({"attack":"grab"} if tick==0 else {},{"attack":"light"} if tick==6 else {})
    check("simultaneous jab interrupts capture",trade.fighters[0].health<100 and trade.fighters[1].health==100 and not trade.paired_throw.active())
    var guarding:RefCounted=fresh()
    for tick in 200:guarding.tick({"attack":"grab"} if tick==0 else {},{"guard":true,"allow_parry":false})
    check("legal throw still beats sustained guard",guarding.fighters[1].health==88 and not guarding.paired_throw.active())
    var counter_throw:RefCounted=fresh();counter_throw.fighters[0].counter_window=30
    var counter_events:=0
    for tick in 200:
        command(counter_throw,tick)
        for event in counter_throw.events:
            if event.kind=="counter_success":counter_events+=1
    check("earned counter feedback survives capture and fires once on landing",counter_events==1)
    var miss:RefCounted=fresh();miss.fighters[1].x=4
    var escaped:RefCounted=fresh()
    var tech:RefCounted=fresh()
    for tick in 50:
        command(miss,tick)
        escaped.tick({"attack":"grab"} if tick==0 else {},{"jump":true} if tick==2 else {})
        tech.tick({"attack":"grab"} if tick==0 else {},{"attack":"grab"} if tick==0 else {})
    check("miss does not attach or damage",miss.fighters[1].health==100 and not miss.paired_throw.active())
    check("jump before contact escapes",escaped.fighters[1].health==100 and not escaped.paired_throw.active())
    check("simultaneous grabs tech before capture",tech.fighters.all(func(f:Dictionary)->bool:return f.health==100) and not tech.paired_throw.active())
    for face in [-1,1]:
        var wall:RefCounted=fresh(0,3,face)
        wall.fighters[0].x=7.7*face;wall.fighters[1].x=8.15*face
        var inside:=true
        for tick in 200:
            command(wall,tick)
            for f in wall.fighters:inside=inside and absf(f.x)<=wall.EDGE
        check("shared root keeps wall pair in bounds %d"%face,inside and wall.fighters[1].health==88)
    var lethal:RefCounted=fresh();lethal.fighters[1].health=5
    var ko:=0;var premature:=false
    for tick in 200:
        command(lethal,tick)
        if lethal.paired_throw.active() and lethal.phase!="fight":premature=true
        for event in lethal.events:
            if event.kind=="ko":ko+=1
    check("lethal landing finishes once after release",not premature and ko==1 and lethal.winner==0 and lethal.fighters[1].health==0)
    var practice:RefCounted=fresh();practice.training=true;practice.fighters[1].health=5
    for tick in 200:command(practice,tick)
    check("training lethal gets up and never becomes a corpse",practice.phase=="fight" and practice.fighters[1].health>=1 and practice.fighters[1].state=="idle" and not practice.fighters[1].has("paired_throw"))
    var interrupted:RefCounted=fresh()
    for tick in 24:command(interrupted,tick)
    interrupted.fighters[0].state="stun";interrupted.fighters[0].stun=20
    interrupted.tick()
    check("external interruption releases both without landing damage",not interrupted.paired_throw.active() and interrupted.fighters[0].state=="stun" and interrupted.fighters[1].health==100 and interrupted.fighters.all(func(f:Dictionary)->bool:return not f.has("paired_throw")))
    var reset:RefCounted=fresh()
    for tick in 24:command(reset,tick)
    reset.reset_round()
    check("round reset clears attachment and source pose",not reset.paired_throw.active() and reset.fighters.all(func(f:Dictionary)->bool:return not f.has("paired_throw")))
    var changed:RefCounted=fresh()
    for tick in 24:command(changed,tick)
    changed.phase="ready";changed.tick()
    check("leaving fight for countdown cancels the pair",not changed.paired_throw.active() and changed.fighters.all(func(f:Dictionary)->bool:return not f.has("paired_throw")))
    var squad=Squad.new();squad.last_service_enabled=true;squad.ai_enabled=false;squad.reset_round();squad.phase="fight";squad.begin_squad()
    for f in squad.squad_members:f.x=6
    squad.squad_members[0].x=.45;squad.squad_members[0].health=5;squad.fighters[0].x=-.45
    var focus_ok:=true
    for tick in 200:
        squad.tick({"attack":"grab"} if tick==0 else {})
        if squad.paired_throw.active():focus_ok=focus_ok and squad.squad_focus==0
    check("squad retains lethal victim until throw ends",focus_ok and squad.squad_members[0].health==0 and not squad.paired_throw.active() and squad.remaining_enemies()>0)
    var enabled:RefCounted=fresh();var disabled:RefCounted=fresh();disabled.paired_throws_enabled=false
    var equivalent:=true
    for tick in 600:
        var input:Dictionary={"attack":"light"} if tick%45==0 else ({"axis":1.0} if tick%110<8 else {})
        enabled.tick(input);disabled.tick(input)
        equivalent=equivalent and JSON.stringify(enabled.fighters)==JSON.stringify(disabled.fighters) and enabled.events==disabled.events
    check("ordinary non-grab simulation unchanged",equivalent)
    var saved:Dictionary=Data.data;Data.data={}
    var fallback:RefCounted=fresh()
    for tick in 60:command(fallback,tick)
    check("missing private curves uses existing legal grab fallback",fallback.fighters[1].health==88 and not fallback.paired_throw.active())
    Data.data=saved
    await visual_checks()
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.pass).size()
    var args:PackedStringArray=OS.get_cmdline_user_args()
    if args.size()>0:FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"metrics":stats},"  "))
    print("PAIRED_RESULT ",checks.size()-failed,"/",checks.size()," ",stats)
    quit(1 if failed>0 else 0)
func visual_checks() -> void:
    var actors:Array=[]
    for side in 2:
        var v=Visual.new();root.add_child(v);actors.append(v)
    for a in 4:
        for b in 4:
            for face in [-1,1]:
                for side in 2:actors[side].setup(Color.WHITE,a if side==0 else b)
                var s:RefCounted=fresh(a,b,face)
                var floor_ok:=true;var inversion:=false;var stable:=true;var grip:=0.0
                for tick in 200:
                    command(s,tick)
                    if not s.paired_throw.active():continue
                    if s.paired_throw.age not in [0,8,20,32,44,52,60,80,96,106,120,136,143]:continue
                    for side in 2:actors[side].present(s.fighters[side],1.0/60.0,s.hitstop>0,false)
                    grip=maxf(grip,Motion.correct_contacts(actors[0],actors[1]))
                    for v in actors:
                        var lowest:float=v.lowest_skin_y()
                        stats.min_skin_y=minf(stats.min_skin_y,lowest)
                        floor_ok=floor_ok and lowest>=-.015
                    var victim:Node3D=actors[1]
                    var head:Vector3=Motion._world_bone(victim,"Head")
                    var hip:Vector3=Motion._world_bone(victim,"Hips")
                    if s.paired_throw.age in [32,44]:inversion=inversion or head.y<hip.y
                    if s.paired_throw.age==60:stats.max_ground_error_m=maxf(stats.max_ground_error_m,absf(victim.lowest_skin_y()-.01))
                    var before:Array=[snapshots(actors[0]),snapshots(actors[1])]
                    var state:String=JSON.stringify(s.fighters)
                    for side in 2:actors[side].present(s.fighters[side],1.0,true,true)
                    Motion.correct_contacts(actors[0],actors[1])
                    stable=stable and state==JSON.stringify(s.fighters)
                    for side in 2:
                        var after:Array=snapshots(actors[side])
                        for i in after.size():stable=stable and before[side][i].is_equal_approx(after[i])
                stats.max_wrist_gap_m=maxf(stats.max_wrist_gap_m,grip)
                check("real rigs floor/inversion/freeze/F2 %d/%d/%d"%[a,b,face],floor_ok and inversion and stable,{"floor":floor_ok,"inversion":inversion,"stable":stable})
                check("wrist grip residual %d/%d/%d"%[a,b,face],grip<.04,grip)
    for face in [-1,1]:
        actors[0].setup(Color.WHITE,0);actors[1].setup(Color.WHITE,4)
        var enemy:RefCounted=fresh(0,4,face)
        var enemy_ok:=true
        for tick in 132:
            command(enemy,tick)
            if not enemy.paired_throw.active() or enemy.paired_throw.age not in [8,32,52,60]:continue
            var pistol:Node3D=actors[1].skeleton.get_node_or_null("Pistol")
            if pistol!=null:pistol.visible=true
            for side in 2:actors[side].present(enemy.fighters[side],1.0/60.0,enemy.hitstop>0,false)
            enemy_ok=enemy_ok and pistol!=null and not pistol.visible
            enemy_ok=enemy_ok and Motion.correct_contacts(actors[0],actors[1])<.04
            enemy_ok=enemy_ok and actors[1].lowest_skin_y()>=-.015
        check("black suit retarget, wrist and floor %d"%face,enemy_ok)
    for side in 2:actors[side].setup(Color.WHITE,side)
    var swap:RefCounted=fresh()
    var swap_ok:=true
    for tick in 400:
        if tick==200:
            swap.fighters[0].x=-.45;swap.fighters[1].x=.45
        swap.tick({"attack":"grab"} if tick==0 else {},{"attack":"grab"} if tick==200 else {})
        for side in 2:actors[side].present(swap.fighters[side],1.0/60.0,swap.hitstop>0,false)
        var residual:float=Motion.correct_contacts(actors[0],actors[1])
        swap_ok=swap_ok and residual<.04
    check("same rig swaps throw roles without stale calibration or floor cache",swap_ok and swap.paired_throw.serial==2 and swap.fighters[0].health==88 and swap.fighters[1].health==88)
    for v in actors:v.free()
