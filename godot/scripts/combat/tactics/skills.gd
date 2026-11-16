extends RefCounted
## Story tactics: fixed-tick costs, charge, swept projectiles and contacts.
## Every impact uses the ordinary block/parry/armour/campaign damage authority.
const Expanded=preload("res://scripts/combat/tactics/expanded.gd")
const NAMES=[["RETURN TAG", "CORNER KICK", "HIGHWAY DELIVERY", "RETURN SPIN", "TWO-STOP DELIVERY", "STREET EXPRESS"], ["RIVET SHOT", "GROUND LINE", "GATE CRASH", "DISMANTLE LINE", "PRESSURE VENT", "WORKSITE SEAL"], ["BREAKBEAT", "RETURN SAMPLE", "NEGATIVE SPACE", "CUT THREE", "SILENCE WINDOW", "ORIGINAL RETURN"], ["LINE THROW", "REMOTE MIX", "CROSS WIRE", "RETURN MONITOR", "FLOATING TEST", "CITY BROADCAST"]]
const INFO=[["Mark a target, then close in. The first enemy can intercept the tag.","A committed step kick. A live mark extends the approach."],["Tap for a quick rivet; hold for shield pressure. Guard or dodge cancels at a cost.","A ground-only shock line. Jumping enemies escape it."],["A narrow pulse catches recovery; it cannot silence a boss.","Briefly receive one pistol round. Press again to send the sample."],["Throw a connector into the shared two-node network.","Detonate existing nodes after a readable delay. No nodes, no cast."]]
const COSTS=[[15, 20, 20, 20, 30, 30], [20, 25, 20, 25, 20, 30], [20, 15, 15, 25, 25, 30], [15, 20, 25, 20, 25, 35]]
const COOLDOWNS=[[180, 240, 240, 240, 360, 420], [240, 300, 240, 300, 300, 420], [240, 300, 210, 300, 420, 420], [180, 240, 300, 240, 420, 480]]
const UNLOCKS=[1,3,6,9,12,15] # Guaranteed after first encounter / first district.
const MOVE_NAMES=["tactic_a","tactic_b"]
var enabled:=false
var config:Array=[{},{}]
var shots:Array[Dictionary]=[]
var serial:=0

static func defaults() -> Dictionary:return {"skills":[0,1],"variants":[0,0,0,0,0,0],"supports":[0,0,0,0,0,0]}
static func fresh() -> Dictionary:return {"cd":[0,0],"charge":-1,"slot":-1,"full":false,"fired":false,"spent":0,"mark":-1,"mark_ttl":0,"sample_window":0,"return_ready":0,"relay":0,"relay_budget":0,"chain_stage":0,"chain_target":-1,"follow_left":0,"follow_window":0}
static func is_move(name:String) -> bool:return name in MOVE_NAMES
static func valid_config(value:Variant) -> bool:
    if not value is Dictionary:return false
    for key in ["skills","variants","supports"]:
        if not value.get(key) is Array or value[key].size()!=(2 if key=="skills" else 6):return false
        for item in value[key]:
            if not (item is int or item is float) or item!=floorf(item) or item<0 or item>(5 if key=="skills" else 1):return false
    return value.skills[0]!=value.skills[1]
func clear() -> void:shots.clear();serial=0
func setup_fighter(f:Dictionary) -> void:f["tactical"]=fresh()
func active(s:RefCounted,side:int) -> bool:return enabled and side==0 and s.last_service_enabled and s.arcade_enabled and s.fighters[side].character in range(4)
func settings(side:int) -> Dictionary:return config[side] if valid_config(config[side]) else defaults()
func skill(side:int,slot:int) -> int:return int(settings(side).skills[slot])
func variant(side:int,id:int) -> int:return int(settings(side).variants[id])
func support(side:int,id:int) -> int:return int(settings(side).supports[id])
func reject(s:RefCounted,side:int,reason:String) -> void:s.events.append({"kind":"tactic_unavailable","target":side,"reason":reason})
static func adjusted_cost(base:int,economy:float) -> int:return maxi(1,ceili(base*clampf(1.0-economy,.8,1.2)))
func cost(f:Dictionary,id:int) -> int:return adjusted_cost(COSTS[f.character][id],float(f.get("tactic_economy",0)))
func move(f:Dictionary,name:String) -> Dictionary:
    if f.has("tactic_impact"):return f.tactic_impact.duplicate()
    var slot:int=MOVE_NAMES.find(name)
    var id:int=skill(0,slot)
    var m:={"startup":12,"active":1,"recovery":24,"damage":8,"reach":0.0,"stun":14,"push":2.0,"lift":0.0,"stop":0,"guard_multiplier":1.0,"ricochet":false}
    match int(f.character):
        0:
            if id==1:m.startup=16;m.active=4;m.recovery=28;m.damage=12;m.reach=2.0;m.push=3.0
        1:
            m.startup=14;m.damage=12;m.stun=18;m.push=3.0
            if id==1:m.startup=22;m.damage=10;m.push=5.0;m.stun=22;m.recovery=30
            elif f.get("tactical",{}).get("full",false):m.damage=16;m.push=5.0;m.guard_multiplier=1.55
        2:
            m.startup=10;m.damage=9;m.stun=12;m.recovery=20
            if id==1:m.startup=8;m.damage=13;m.stun=18
        3:
            m.startup=16;m.damage=0;m.recovery=22
            if id==1:m.startup=30 if f.get("tactic_anchor",false) else 24;m.damage=12;m.stun=20;m.push=4.0
    if id>=2:m=Expanded.move(f.character,id)
    if f.get("tactic_relay",false):m.damage=maxi(0,roundi(m.damage*.8))
    if variant(0,id)==1:
        if id>=2:m.startup=maxi(6,roundi(m.startup*.8));m.recovery=maxi(12,roundi(m.recovery*.8))
        if f.character==3 and id==0:m.startup=8
        m.damage=maxi(0,roundi(m.damage*.75));m.guard_multiplier=.7
        if f.character==1 and id==0:m.recovery=18
    return m

func before(s:RefCounted,side:int,command:Dictionary) -> void:
    var f:Dictionary=s.fighters[side]
    if not f.has("tactical"):setup_fighter(f)
    if not active(s,side):
        if is_move(command.get("attack","")):command.erase("attack")
        return
    var t:Dictionary=f.tactical
    if f.character==0 and int(f.get("tactic_unlocked",0))>4 and 4 in settings(side).skills:command["bank_routes"]=true
    Expanded.before(s,side,command)
    # An explicit tactic takes precedence over held rush; ordinary attacks cannot overwrite charge.
    if t.charge>=0:
        command.erase("attack");command.erase("rush")
        if f.state!="attack" or not is_move(f.move) or f.health<=0:t.charge=-1;return
        if command.get("guard",false) or command.get("dash",false):
            cancel(s,side);return
        if s.hitstop>0:return
        t.charge+=1
        var extra:int=adjusted_cost(10,float(f.get("tactic_economy",0)))
        if t.charge==36 and f.meter>=extra:
            f.meter-=extra;t.spent+=extra;t.full=true;t.cd[t.slot]=450 if f.get("tactic_anchor",false) else 360
            s.events.append({"kind":"tactic_tier","target":side})
        var held:bool=command.get("tactic_a_held",false) if t.slot==0 else command.get("tactic_b_held",false)
        if held and t.charge<54:f.frame=3
        else:t.charge=-1
    if is_move(command.get("attack","")):
        command.erase("rush")
        if command.get("guard",false) or command.get("dash",false):command.erase("attack")

func begin(s:RefCounted,side:int,name:String) -> bool:
    if not active(s,side):return false
    var f:Dictionary=s.fighters[side];var t:Dictionary=f.tactical
    var slot:int=MOVE_NAMES.find(name);var id:int=skill(side,slot)
    var unlocked:int=int(f.get("tactic_unlocked",0))
    var follow:bool=id>=2 and Expanded.follow_ready(f,id)
    var reason:=""
    if id>=unlocked:reason="Clear the next story milestone to learn this tactic."
    elif t.cd[slot]>0 and not follow and not (f.character==2 and id==1 and t.return_ready>0 and f.service.sample>0):reason="Tactic is cooling down."
    elif id>=2:reason=Expanded.reason(s,side,id,follow)
    elif id<2 and f.y>.01:reason="This tactic needs solid ground."
    elif f.character==3 and id==1 and f.service.nodes.is_empty():reason="Place a node first."
    if reason=="" and f.meter<cost(f,id) and not follow and not (f.character==2 and id==1 and t.return_ready>0 and f.service.sample>0):reason="Not enough energy for this tactic."
    if reason=="" and shots.size()>8:reason="Wait for active tactics to finish."
    if reason!="":reject(s,side,reason);return false
    var returning:bool=f.character==2 and id==1 and t.return_ready>0 and f.service.sample>0
    var price:int=0 if returning or follow else cost(f,id)
    t["cast_skill"]=id
    f.meter-=price;t.spent=price;t.slot=slot;t.full=false;t.fired=false
    if not returning and not follow:t.cd[slot]=roundi(COOLDOWNS[f.character][id]*(.75 if support(side,id)==1 and not (f.character in [1,2] and id==0) else 1.0))
    t.charge=0 if f.character==1 and id==0 else -1
    if f.get("tactic_anchor",false) and not returning and not follow:t.cd[slot]=ceili(float(t.cd[slot])*1.25)
    # One sample is either received or sent, never duplicated by a second press.
    if f.character==2 and id==1:
        t["send_sample"]=f.service.sample>0
        if t.send_sample:f.service.sample=0;f.service.sample_ttl=0;t.return_ready=0
        else:t.sample_window=24
    if id>=2:Expanded.begin(s,side,id,follow)
    s.events.append({"kind":"tactic_start","target":side,"skill":id,"slot":slot})
    return true
func cancel(s:RefCounted,side:int) -> void:
    var f:Dictionary=s.fighters[side]
    if not f.has("tactical"):return
    f.tactical.charge=-1;f.tactical.sample_window=0
    if f.state=="attack" and is_move(f.move):f.state="idle";f.move="";f.frame=0
    f.buffer="";f.buffer_ttl=0
    s.continuation.cancel(side)
func suspend(s:RefCounted) -> void:
    for side in 2:
        var f:Dictionary=s.fighters[side]
        if not f.has("tactical"):continue
        if f.tactical.charge>=0:cancel(s,side)
        else:f.tactical.sample_window=0

func targets(s:RefCounted,side:int) -> Array:
    if side==0 and s.get("squad_enabled")==true:return s.get("squad_members")
    return [s.fighters[1-side]]
func advance(s:RefCounted) -> void:
    if not enabled:return
    for side in 2:
        if not active(s,side):continue
        var f:Dictionary=s.fighters[side];var t:Dictionary=f.tactical
        for slot in 2:
            if t.charge<0 or slot!=t.slot:t.cd[slot]=maxi(0,t.cd[slot]-1)
        t.follow_window=maxi(0,t.follow_window-1)
        if f.character==3 and f.service.nodes.any(func(n:Dictionary)->bool:return n.get("emitter",false)) and not Expanded.emitter(f):
            f.service.nodes=f.service.nodes.filter(func(n:Dictionary)->bool:return not n.get("emitter",false))
        t.mark_ttl=maxi(0,t.mark_ttl-1);t.sample_window=maxi(0,t.sample_window-1);t.return_ready=maxi(0,t.return_ready-1);t.relay=maxi(0,t.relay-1)
        if f.health<=0:t.charge=-1;t.sample_window=0;continue
        if f.state!="attack" or not is_move(f.move):
            t.charge=-1
            if f.state in ["stun","blockstun"]:t.sample_window=0
        else:
            var m:Dictionary=s.move_for(f,f.move)
            var id:int=skill(side,MOVE_NAMES.find(f.move))
            if id>=2:Expanded.advance(s,side,id)
            if f.character==0 and id==1 and f.frame<m.startup:
                var gap:float=(s.fighters[1-side].x-f.x)*f.face
                var marked:bool=t.mark_ttl>0 and int(s.fighters[1-side].get("squad_id",0))==t.mark
                var speed:=2.0 if variant(side,id)==1 else (6.0 if marked else 4.0)
                if gap>1.05:f.x=clampf(f.x+f.face*minf(speed*s.STEP,gap-1.05),-s.EDGE,s.EDGE)
            if f.frame>=m.startup and not t.fired:
                t.fired=true;emit(s,side,id,move(f,f.move))
    var kept:Array[Dictionary]=[]
    for shot in shots:
        if step_shot(s,shot):kept.append(shot)
    shots=kept

func emit(s:RefCounted,side:int,id:int,m:Dictionary) -> void:
    if shots.size()>=12:return
    var f:Dictionary=s.fighters[side];var t:Dictionary=f.tactical
    serial+=1
    if id>=2:
        var expanded_data:Dictionary=m.duplicate()
        if support(side,id)==1:expanded_data.damage=maxi(0,roundi(expanded_data.damage*.8))
        Expanded.emit(s,side,id,expanded_data)
        return
    var kind:="bolt";var speed:=.16;var life:=36;var radius:=.35;var limit:=1
    if f.character==0 and id==1:kind="kick";speed=0;life=1;radius=2.0
    if f.character==1:
        speed=.13 if t.full else .18;life=38 if t.full else 28
        if id==1:kind="ground";speed=.14;life=32
    if f.character==2:
        speed=.30;life=28;radius=.24
        if id==1 and not t.get("send_sample",false):return
        if variant(side,id)==0:limit=2 # a narrow line; expansion gives up this penetration
    if f.character==3:
        if id==0:kind="connector";speed=.16;life=12 if variant(side,id)==1 else 20
        else:
            # Nodes are consumed on commitment to the pulse, never free duplicates.
            for node in f.service.nodes:
                var copy:Dictionary=m.duplicate()
                var radius_at:float=(1.2 if variant(side,id)==1 else .85)+(.25 if f.get("tactic_anchor",false) else 0.0)
                add_shot(f,side,id,"pulse",float(node.x),0,0,1,radius_at,1,copy)
                s.events.append({"kind":"tactic_pulse","target":side,"x":node.x,"low":node.x-radius_at,"high":node.x+radius_at})
            f.service.nodes.clear();return
    if variant(side,id)==1:
        radius*=1.8;life=mini(life,20)
        if kind=="kick":radius=2.6;limit=3
    if support(side,id)==1 and f.character in [1,2] and id==0:limit+=1
    if f.get("tactic_anchor",false):life=ceili(float(life)*1.35)
    var data:Dictionary=m.duplicate()
    if support(side,id)==1:data.damage=maxi(1,roundi(data.damage*.8))
    add_shot(f,side,id,kind,float(f.x)+f.face*.5,float(f.face),speed,life,radius,limit,data)
    s.events.append({"kind":"tactic_fire","target":side,"skill":id,"x":f.x,"y":f.y+.9})

func add_shot(f:Dictionary,side:int,id:int,kind:String,x:float,dir:float,speed:float,life:int,radius:float,limit:int,data:Dictionary) -> void:
    shots.append({"id":serial,"move":f.move,"swing":f.service.serial,"owner":side,"fighter":f,"skill":id,"kind":kind,"x":x,"previous":x,"y":.9 if kind not in ["ground","pulse"] else .15,"dir":dir,"speed":speed,"life":life,"age":0,"radius":radius,"limit":limit,"hit":[],"data":data,"variant":variant(side,id),"support":support(side,id),"counter":f.counter_attack,"aim":f.tactical.get("aim",-1)})
func step_shot(s:RefCounted,p:Dictionary) -> bool:
    p.age+=1
    if p.fighter.health<=0:return false
    if p.get("delay",0)>p.age:return true
    if p.kind=="zone" and p.age==p.get("delay",30):s.events.append({"kind":"tactic_pulse","target":p.owner,"x":p.x,"low":p.x-p.radius,"high":p.x+p.radius})
    if p.kind=="arc" and p.age==p.get("turn_at",8):p.dir=-p.dir
    p.previous=p.x;p.x+=p.dir*p.speed
    if absf(p.x)>s.EDGE+.6:return false
    if p.kind=="connector":
        if p.age>=p.life:
            var f:Dictionary=p.fighter
            if f.service.nodes.size()>=2:f.service.nodes.pop_front()
            f.service.nodes.append({"x":clampf(p.x,-s.EDGE,s.EDGE),"life":180 if p.variant==1 else (405 if p.fighter.get("tactic_anchor",false) else 300),"id":100000+p.id})
            if p.support==1:f.service.nodes[-1].life=roundi(float(f.service.nodes[-1].life)*.75)
            else:f.tactical.relay=120;f.tactical.relay_budget=1
            s.events.append({"kind":"node_placed","target":p.owner,"x":p.x})
            return false
        return true
    for target in targets(s,p.owner):
        if target.health<=0 or target in p.hit or target.invuln>0:continue
        if p.fighter.character==0 and p.skill==4 and int(target.get("squad_id",0))!=int(p.aim):continue
        if p.kind in ["ground","pulse","wire","zone"] and target.y>.35:continue
        if p.kind=="kick" and absf(target.y+.7-p.y)>1.1:continue
        if p.kind not in ["ground","pulse","kick","wire","zone"] and absf(target.y+.9-p.y)>.65:continue
        var low:float=minf(p.previous,p.x)-p.radius;var high:float=maxf(p.previous,p.x)+p.radius
        if p.kind=="kick":low=p.fighter.x if p.dir>=0 else p.fighter.x-p.radius;high=p.fighter.x+p.radius if p.dir>=0 else p.fighter.x
        if target.x<low-.001 or target.x>high+.001:continue
        p.hit.append(target)
        impact(s,p,target)
        if p.hit.size()>=p.limit:return false
    return p.age<p.life

func impact(s:RefCounted,p:Dictionary,target:Dictionary) -> void:
    var owner:int=p.owner;var f:Dictionary=p.fighter
    var saved_target:Dictionary=s.fighters[1-owner]
    var saved_move:String=f.move;var connected:bool=f.connected;var confirmed:bool=f.hit_confirmed
    var saved_face:int=f.face;var had_data:bool=f.has("move_data");var saved_data:Variant=f.get("move_data")
    var chain:int=f.chain;var chain_ttl:int=f.chain_ttl;var counter_attack:bool=f.counter_attack
    var meter:float=f.meter
    s.fighters[1-owner]=target
    f.move=p.move
    f.counter_attack=p.counter
    f["tactic_impact"]=p.data;f["pulse_origin"]=p.previous
    f.face=int(p.dir) if p.dir!=0 else saved_face
    var start:int=s.events.size()
    s._resolve_hit(owner,false)
    var hit:bool=false
    for e in s.events.slice(start):
        if e.kind=="hit":hit=true
        # The event side index is transient in squad combat; retain real identity.
        e["squad_id"]=int(target.get("squad_id",0))
        if e.kind in ["hit","block","parry"]:e["tactic"]=true
    # Ranged tactics do not refund themselves once per pierced target.
    f.meter=minf(f.meter,meter)
    if hit:
        if f.character==0 and p.skill==0:f.tactical.mark=int(target.get("squad_id",0));f.tactical.mark_ttl=90 if p.variant==1 else (240 if f.get("tactic_anchor",false) else 180)
        if p.support==0:f.tactical.relay=120;f.tactical.relay_budget=1
        Expanded.hit(s,p,target)
    f.erase("tactic_impact");f.erase("pulse_origin");f.move=saved_move;f.connected=connected;f.hit_confirmed=confirmed or (hit and f.state=="attack" and saved_move==p.move and f.service.serial==p.swing)
    f.face=saved_face;f.chain=chain;f.chain_ttl=chain_ttl;f.counter_attack=counter_attack
    p.counter=false
    if had_data:f.move_data=saved_data
    else:f.erase("move_data")
    s.fighters[1-owner]=saved_target

func observe(s:RefCounted,event:Dictionary) -> void:
    if not enabled or event.kind!="hit" or event.get("attacker",-1)!=0 or event.get("tactic",false):return
    var f:Dictionary=s.fighters[0]
    if not f.has("tactical") or f.tactical.relay<=0 or f.tactical.relay_budget<=0:return
    if event.get("move","") not in ["jab","cross","heavy","launcher"]:return
    var refund:int=6 if f.get("tactic_relay",false) else 4
    f.tactical.relay_budget=0;f.tactical.relay=0;f.meter=minf(100,f.meter+refund)
    s.events.append({"kind":"tactic_relay","target":0,"amount":refund})

static func description(hero:int,id:int) -> String:
    return INFO[hero][id] if id<2 else Expanded.INFO[hero][id-2]

static func variant_labels(hero:int,id:int) -> Array:
    if id>=2:return ["COMMITTED / FULL IMPACT","QUICK / LOWER IMPACT"]
    if hero==0:return ["LONG MARK","BROAD / SHORT MARK"] if id==0 else ["STEP KICK","SWEEP / LOW DAMAGE"]
    if hero==3:return ["LONG PLACEMENT","QUICK / SHORT PLACEMENT"] if id==0 else ["FOCUSED PULSE","WIDE / LOW DAMAGE"]
    return ["FOCUSED / LONG REACH","WIDE / SHORT REACH"]
