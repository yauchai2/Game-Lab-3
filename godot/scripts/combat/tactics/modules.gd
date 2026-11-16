extends RefCounted
## Optional second support. One transformation per shot; no spawned child effects.
const LABELS=["SECOND SUPPORT / NONE","RETURN / TWO LEGS","DELAY / WARNED AREA","AIR DROP / LANDING COMMITMENT"]
const INFO=["Optional second support. Incompatible choices are disabled; no module is required.","One outward hit and one different returning target. Damage -30%, guard pressure -20%, half outward travel. Cannot combine with PIERCE.","A fixed ground area warns for 24 ticks, then bursts once. Damage -15%; wider coverage, no moving projectile.","Throw a tag or connector diagonally from the air. Spends this jump's fast-fall budget; aerial tag damage -20%, landing recovery +8 ticks. Ground casts keep their original behavior."]
static func compatible(hero:int,id:int,module:int,primary:int) -> bool:
    return reason(hero,id,module,primary)==""
static func reason(hero:int,id:int,module:int,primary:int) -> String:
    if module==0:return ""
    if module==1:
        if id!=0 or hero not in [0,1,2]:return "RETURN needs a straight tag, rivet or pulse."
        if hero in [1,2] and primary==1:return "Remove PIERCE before fitting RETURN."
        return ""
    if module==2:
        if (hero==1 or hero==3) and id==1:return ""
        return "DELAY needs GROUND LINE or REMOTE MIX."
    if module==3:
        if hero in [0,3] and id==0:return ""
        return "AIR DROP needs RETURN TAG or LINE THROW."
    return "Unknown support module."
static func apply(p:Dictionary,module:int,edge:float) -> void:
    p["module"]=module
    if module==1:
        p.kind="return";p["leg"]=0;p["turn_at"]=maxi(2,ceili(float(p.life)*.5));p.limit=2
        p.data.damage=maxi(1,roundi(float(p.data.damage)*.7));p.data.guard_multiplier=float(p.data.get("guard_multiplier",1.0))*.8
    elif module==2:
        if p.kind=="ground":
            p.x=clampf(p.fighter.x+p.dir*2.8,-edge,edge)
            p.radius=(1.9 if p.variant==1 else 1.35)+(.25 if p.fighter.get("tactic_anchor",false) else 0.0)
        else:p.radius*=1.25
        p.previous=p.x;p.kind="zone";p.y=.15;p.speed=0;p.dir=0;p["delay"]=24;p.life=24
        p.data.damage=maxi(1,roundi(float(p.data.damage)*.85))
    elif module==3 and p.fighter.tactical.get("air_cast",false):
        p["airdrop"]=true;p.y=p.fighter.y+.9;p["fall_speed"]=maxf(.08,(p.y-.15)/float(p.life))
        p.data.damage=maxi(0,roundi(float(p.data.damage)*.8))
