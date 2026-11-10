extends RefCounted
## Shared pure 60 Hz air movement. No Node, Tween or input polling.
const STEP := 1.0/60.0
const JUMP_SPEED := 12.5
const AIR_JUMP_SPEED := 10.5
const SQUAT := 3
const STALL_BUDGET := 12
const CHASE_TICKS := 10
const CHASE_COST := 20
const COMBO_TICKS := 150

static func fresh() -> Dictionary:
    return {"phase":"ground","squat":0,"land":0,"hard_land":false,"air_ticks":0,
        "stall_left":STALL_BUDGET,"stall":0,"saved_vy":0.0,"fast_used":false,"fast":false,
        "drop_buffer":0,"chase_window":0,"chase_buffer":0,"chase_used":false,"chase_tick":0,"points":[],
        "parry_used":false,"parry_window":0,"combo_left":0,"bounce_granted":false,"bounce_used":false,
        "double_used":false,"double_pose":0}

func request_air_jump(f: Dictionary) -> bool:
    # A second impulse, never a stun/attack cancel or a refill of air resources.
    if f.state!="idle" or f.y<=.01 or f.air.double_used:return false
    cancel_stall(f)
    f.air.double_used=true
    f.air.double_pose=8
    f.air.fast=false
    f.air.drop_buffer=0
    f.air.phase="rise"
    f.vy=AIR_JUMP_SPEED
    f.jump_buffer=0
    return true

func request_jump(f: Dictionary) -> void:
    f.state="jump_squat"
    f.frame=0
    f.air.squat=SQUAT
    f.air.phase="squat"
    f.jump_buffer=0
    f.vx*=.4

func attack_stall(f: Dictionary) -> void:
    if f.y<=.01 or f.air.stall_left<=0:return
    if f.air.stall==0:f.air.saved_vy=f.vy
    var amount:=mini(4,int(f.air.stall_left))
    f.air.stall=amount
    f.air.stall_left-=amount

func cancel_stall(f: Dictionary) -> void:
    if f.air.stall>0:f.vy=f.air.saved_vy
    f.air.stall=0

func start_chase(f: Dictionary, target: Dictionary, edge: float) -> String:
    if f.air.chase_used or (target.y<.1 and target.vy<=0) or target.state!="stun":return "unavailable"
    var from:=Vector2(f.x,f.y)
    var destination:=Vector2(clampf(target.x-f.face*1.1,-edge+.45,edge-.45),clampf(target.y+target.vy*.12,.3,4.5))
    if from.distance_to(destination)>4.0:return "range"
    if f.meter<CHASE_COST:return "no_meter"
    f.meter-=CHASE_COST
    cancel_stall(f)
    f.air.chase_used=true
    f.air.chase_window=0
    f.air.chase_buffer=0
    f.air.chase_tick=0
    f.air.points=[from,from+Vector2(f.face*.35,1.0),destination+Vector2(-f.face*.25,.65),destination]
    f.state="chase"
    f.frame=0
    f.vx=0.0
    f.vy=0.0
    f.guarding=false
    f.buffer=""
    f.buffer_ttl=0
    f.jump_buffer=0
    return "started"

func integrate(f: Dictionary, edge: float) -> String:
    var air: Dictionary=f.air
    air.double_pose=maxi(0,air.double_pose-1)
    air.land=maxi(0,air.land-1)
    air.drop_buffer=maxi(0,air.drop_buffer-1)
    air.chase_window=maxi(0,air.chase_window-1)
    air.chase_buffer=maxi(0,air.chase_buffer-1)
    if f.state=="chase":
        air.chase_tick+=1
        air.phase="chase"
        var t:=clampf(float(air.chase_tick)/CHASE_TICKS,0,1)
        var p: Array=air.points
        var at: Vector2=p[0]*(1-t)*(1-t)*(1-t)+p[1]*3*(1-t)*(1-t)*t+p[2]*3*(1-t)*t*t+p[3]*t*t*t
        f.x=clampf(at.x,-edge,edge)
        f.y=clampf(at.y,.04,4.5)
        air.air_ticks+=1
        if air.chase_tick>=CHASE_TICKS:
            f.state="idle"
            f.vy=0.0
            return "chase_arrive"
        return ""
    if f.state=="jump_squat":
        air.phase="squat"
        if air.squat>0:
            air.squat-=1
            return ""
        f.state="idle"
        f.vy=JUMP_SPEED
        air.air_ticks=0
        air.stall_left=STALL_BUDGET
        air.fast_used=false
        air.fast=false
        air.phase="rise"
        # Signal takeoff while still integrating this physical tick.
    var takeoff: bool=air.air_ticks==0 and f.y<=.01 and f.vy==JUMP_SPEED
    if f.y>.01 or f.vy>0:air.air_ticks+=1
    if f.y>.01 and f.state in ["idle","dash"] and air.drop_buffer>0 and not air.fast_used:
        cancel_stall(f)
        f.vy=minf(f.vy,-18.0)
        air.fast_used=true
        air.fast=true
        air.drop_buffer=0
        air.phase="fast"
        return _vertical(f,edge,"fast_fall")
    if air.stall>0:
        air.phase="stall"
        air.stall-=1
        f.vy=0.0
        if air.stall==0:f.vy=air.saved_vy
        return ""
    return _vertical(f,edge,"jump" if takeoff else "")

func _vertical(f: Dictionary, _edge: float, signal_kind: String) -> String:
    var air: Dictionary=f.air
    var old_y: float=f.y
    var gravity:=36.0 if f.vy>2.4 else (14.0 if absf(f.vy)<=2.4 else 50.0)
    if f.state=="stun":gravity=32.0
    f.vy=maxf(-24.0,f.vy-gravity*STEP)
    f.y=maxf(0,f.y+f.vy*STEP)
    if f.y>0:
        air.phase="fast" if air.fast else ("rise" if f.vy>2.4 else ("apex" if absf(f.vy)<=2.4 else "fall"))
        return signal_kind
    if old_y>0:
        if air.bounce_granted and not air.bounce_used and f.wall_bounces==0 and f.state=="stun" and air.combo_left>0:
            air.bounce_granted=false
            air.bounce_used=true
            f.wall_bounces=1
            f.y=.04
            f.vy=7.0
            f.stun=maxi(f.stun,18)
            f.wall_tech_window=12
            air.phase="rise"
            return "ground_bounce"
        air.hard_land=air.fast or f.vy<-14
        air.land=8 if air.hard_land else 4
        air.phase="land"
        air.fast=false
        air.fast_used=false
        air.air_ticks=0
        air.stall_left=STALL_BUDGET
        air.stall=0
        air.chase_used=false
        air.chase_window=0
        air.chase_buffer=0
        air.combo_left=0
        air.bounce_granted=false
        air.bounce_used=false
        air.parry_used=false
        air.parry_window=0
        air.double_used=false
        air.double_pose=0
        f.vy=0.0
        f.juggle=0
        if f.state=="idle":f.state="landing"
        return "air_land"
    f.vy=0.0
    if air.land==0:air.phase="ground"
    return signal_kind
