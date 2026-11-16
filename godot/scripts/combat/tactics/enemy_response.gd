extends RefCounted
## Role-specific, sampled responses to visible player warning zones. No hit authority.
const STEP_ROLES=["grunt","rusher","jammer"]
const GUARD_ROLES=["guard","captain"]
static func command(s:RefCounted,f:Dictionary) -> Dictionary:
    if s.hitstop>0 or not s.campaign_enabled or not s.ai_enabled or not s.tactics.enabled or s.arrival_left>0 or f.get("arrival",0)>0 or f.has("boss"):return {}
    f["tactic_response_cd"]=maxi(0,int(f.get("tactic_response_cd",0))-1)
    var idle:bool=f.health>0 and f.state=="idle" and f.y<=.01 and f.get("rush_charge",0)==0 and not f.get("rush_follow",false)
    if not idle:f["tactic_response_left"]=0;return {}
    if f.get("tactic_response_left",0)>0:
        f.tactic_response_left-=1
        if f.tactic_response_left==0:return {}
        return apply(f)
    if f.tactic_response_cd>0:return {}
    var cadence:int=[18,12,8][clampi(s.difficulty,0,2)]
    if s.squad_clock%cadence!=posmod(int(f.get("squad_id",0))*3,cadence):return {}
    var role:String=f.get("story_role","")
    if role not in STEP_ROLES and role not in GUARD_ROLES:return {}
    var warning:Dictionary={};var nearest:=INF
    for shot in s.tactics.shots:
        var delay:int=int(shot.get("delay",0))
        if shot.owner!=0 or shot.kind!="zone" or shot.age<8 or shot.age>=delay:continue
        var gap:float=absf(f.x-shot.x)
        if gap<=shot.radius+.3 and gap<nearest:warning=shot;nearest=gap
    if warning.is_empty():return {}
    if role in GUARD_ROLES and f.guard<=22:return {}
    var dir:float=signf(f.x-warning.x)
    if dir==0:dir=signf(f.x-s.fighters[0].x)
    if dir==0:dir=float(f.face)
    var room:float=s.EDGE-f.x if dir>0 else f.x+s.EDGE
    if room<maxf(.4,warning.radius-nearest+.3):dir=-dir
    f["tactic_response_dir"]=dir
    f["tactic_response_guard"]=role in GUARD_ROLES
    f["tactic_response_left"]=mini(20,int(warning.delay)-int(warning.age)+1)
    f.tactic_response_cd=180
    s.events.append({"kind":"tactic_brace" if f.tactic_response_guard else "tactic_step_out","target":1,"squad_id":int(f.get("squad_id",0))})
    return apply(f)
static func apply(f:Dictionary) -> Dictionary:
    f.buffer="";f.buffer_ttl=0
    return {"guard":true,"allow_parry":false} if f.tactic_response_guard else {"axis":f.tactic_response_dir,"allow_parry":false}
