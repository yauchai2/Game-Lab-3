extends RefCounted
## One simulation clock for both participants. Damage occurs once, on landing.
const Data=preload("res://scripts/combat/paired_throw_library.gd")
const CONTACT_TICKS=80
const RECOVERY_TICKS=64 # Full get-up after landing; no hit/input rules change during the pair.
const IMPACT_TICK=60 # source 106, after the airborne over-shoulder rotation
var serial:=0
var owner:=-1
var age:=0
var landed:=false
var resolving_impact:=false
var anchor:=0.0
var face:=1.0
var starts:Array=[]
func active() -> bool:return owner>=0
func clear(s:RefCounted=null) -> void:
    if s!=null:
        for f in s.fighters:f.erase("paired_throw")
    owner=-1;age=0;landed=false;resolving_impact=false;starts.clear()
func begin(s:RefCounted,side:int) -> void:
    serial+=1
    owner=side;age=0;landed=false
    face=float(s.fighters[side].face)
    starts=[float(s.fighters[0].x),float(s.fighters[1].x)]
    var low:=INF
    var high:=-INF
    for role in ["aggressor","victim"]:
        for frame in range(61,122):
            var x:float=Data.offset(role,frame,face).x
            low=minf(low,x);high=maxf(high,x)
    anchor=clampf(s.fighters[side].x,-s.EDGE-low,s.EDGE-high)
    s.continuation.clear()
    var counter:bool=s.fighters[side].counter_attack
    for f in s.fighters:
        f.buffer="";f.buffer_ttl=0;f.jump_buffer=0;f.counter_window=0;f.counter_attack=false
        f.guarding=false;f.tech_window=0;f.vx=0.0;f.vy=0.0
        f.state="throw";f.connected=true;f.air=s.AirMotion.fresh();f.ricochet=s.ArenaBox.fresh()
    s.fighters[side].counter_attack=counter
    _stamp(s)
    s.events.append({"kind":"throw_start","attacker":owner,"target":1-owner})
func tick(s:RefCounted) -> void:
    if not active():return
    if s.fighters[owner].state!="throw" or s.fighters[1-owner].state!="throw" or s.fighters[owner].health<=0 or (not landed and s.fighters[1-owner].health<=0):
        cancel(s)
        return
    for f in s.fighters:
        for field in ["throw_cd","dash_cd","parry_cd"]:f[field]=maxi(0,int(f[field])-1)
    age+=1
    _stamp(s)
    if age==IMPACT_TICK and not landed:
        landed=true;resolving_impact=true
        var a:Dictionary=s.fighters[owner]
        a.state="attack";a.move="grab";a.connected=false
        s._resolve_hit(owner,false)
        if s.training:s.fighters[1-owner].health=maxi(1,s.fighters[1-owner].health)
        resolving_impact=false
        for f in s.fighters:
            f.state="throw";f.vx=0.0;f.vy=0.0;f.connected=true;f.buffer="";f.buffer_ttl=0
        s.events.append({"kind":"throw_land","attacker":owner,"target":1-owner})
    if age>=CONTACT_TICKS+RECOVERY_TICKS:
        var attacker:int=owner
        for i in 2:
            var f:Dictionary=s.fighters[i]
            var corpse:bool=f.health<=0 and i!=owner
            if corpse:f.paired_throw["corpse"]=true
            else:f.erase("paired_throw")
            f.state="stun" if corpse else "idle";f.stun=999 if corpse else 0
            f.move="";f.frame=0;f.vx=0.0;f.vy=0.0;f.y=0.0;f.flash=0
            f.buffer="";f.buffer_ttl=0;f.jump_buffer=0;f.invuln=0
        clear()
        s.events.append({"kind":"throw_end","attacker":attacker,"target":1-attacker})
func cancel(s:RefCounted) -> void:
    for f in s.fighters:
        f.erase("paired_throw")
        if f.state not in ["stun","blockstun","dash"]:
            f.state="stun" if f.health<=0 else "idle"
            f.stun=999 if f.health<=0 else 0;f.move="";f.vx=0.0;f.vy=0.0;f.y=0.0
        f.buffer="";f.buffer_ttl=0;f.jump_buffer=0;f.connected=false
    clear()
    s.events.append({"kind":"throw_cancel"})
func _stamp(s:RefCounted) -> void:
    for i in 2:
        var f:Dictionary=s.fighters[i]
        var role:String="aggressor" if i==owner else "victim"
        var frame:float=minf(121,61+float(age)*.75)
        if i!=owner:frame=minf(106,frame)
        var p:Vector3=Data.offset(role,frame,face)
        var recover:float=clampf(float(age-CONTACT_TICKS)/RECOVERY_TICKS,0,1)
        f.x=lerpf(starts[i],anchor+p.x,clampf(float(age)/6.0,0,1))
        f.y=0.0;f.face=int(face) if i==owner else -int(face)
        # Rejoin the common fighting plane during the get-up, not in one frame at release.
        var depth:float=p.z if f.health<=0 else p.z*(1.0-smoothstep(0,1,recover))
        f["paired_throw"]={"serial":serial,"role":role,"source_frame":frame,"age":age,"face":face,"depth":depth,"recover":recover,"corpse":false}
    if age>=CONTACT_TICKS:
        for i in 2:s.fighters[i].face=1 if s.fighters[1-i].x>=s.fighters[i].x else -1
