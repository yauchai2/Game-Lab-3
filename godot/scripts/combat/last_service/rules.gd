extends RefCounted
## Fixed-tick character resources and real, blockable contact. No presentation authority.
static func fresh() -> Dictionary:
    return {"routes":0,"route_ttl":0,"evade_serial":-1,"evade_candidate":-1,"candidate_ticks":0,"preload":0,"preload_age":0,"sample":0,"sample_ttl":0,"sample_boost":false,"nodes":[],"node_cd":0,"serial":0,"placed":false,"zip_second":false,"zip_second_at":0,"followup":0,"flurry_left":0,"encore":[],"refund_serial":-1}
static func perk(f:Dictionary,id:String) -> bool:return id in f.get("perks",[])
func before(s:RefCounted,i:int,command:Dictionary) -> void:
    var f:Dictionary=s.fighters[i];var r:Dictionary=f.service
    if f.character==3 and command.get("attack","")=="special" and command.get("down",false):command.attack="node_pulse"
    if command.get("attack","")=="special":f["node_far"]=absf(command.get("axis",0.0))>.1
    if s.hitstop>0:return
    var enemy:Dictionary=s.fighters[1-i]
    if command.get("dash",false) and f.character==0 and f.state=="idle" and f.dash_cd==0 and enemy.state=="attack" and absf(f.x-enemy.x)<=s.move_for(enemy,enemy.move).reach+.5 and (f.x-enemy.x)*enemy.face>0:
        r.evade_candidate=enemy.service.serial;r.candidate_ticks=14
    r["use_route"]=command.get("dash",false) and f.state=="idle" and f.dash_cd==0 and r.routes>0
    if f.character==2 and f.state=="attack" and f.move=="special" and f.frame<5:f.vx=-f.face*3.0
    # This runs before the normal input buffer is collected.
    if f.character==1 and f.state=="attack" and f.move=="special" and f.frame>=8 and f.frame<24:
        var previous_tier:int=r.preload
        r.preload_age+=1
        r.preload=2 if r.preload_age>=(24 if perk(f,"rivet_fast") else 30) else (1 if r.preload_age>=12 else 0)
        if previous_tier!=r.preload:s.events.append({"kind":"preload_tier","target":i,"tier":r.preload})
        if command.get("skill_held",false) and r.preload_age<36:f.frame=7
func started(s:RefCounted,i:int,name:String) -> void:
    var f:Dictionary=s.fighters[i];var r:Dictionary=f.service
    r.serial+=1;r.placed=false;r.zip_second=false;r.zip_second_at=0;r.followup=0;r.flurry_left=2
    r.preload=0;r.preload_age=0;r.sample_boost=false
    if f.character==2 and r.sample>0 and name in ["cross","heavy","launcher","special","overdrive"]:
        r.sample=0;r.sample_ttl=0;r.sample_boost=true
        s.events.append({"kind":"sample_spent","target":i})
    if f.character==3 and name=="overdrive":r.encore=r.nodes.duplicate(true)
func advance(s:RefCounted) -> void:
    for i in 2:
        var f:Dictionary=s.fighters[i];var b:Dictionary=s.fighters[1-i];var r:Dictionary=f.service
        r.candidate_ticks=maxi(0,r.candidate_ticks-1)
        r.route_ttl=maxi(0,r.route_ttl-1);r.sample_ttl=maxi(0,r.sample_ttl-1);r.node_cd=maxi(0,r.node_cd-1)
        if r.route_ttl==0:r.routes=0
        if r.sample_ttl==0:r.sample=0
        for node in r.nodes:node.life-=1
        r.nodes=r.nodes.filter(func(node:Dictionary)->bool:return node.life>0)
        if f.character==0:
            if f.state=="dash" and f.invuln>0 and b.state=="attack" and b.frame>=s.move_for(b,b.move).startup and b.frame<s.move_for(b,b.move).startup+s.move_for(b,b.move).active and (absf(b.x-f.x)<=s.move_for(b,b.move).reach+.4 or (r.candidate_ticks>0 and r.evade_candidate==b.service.serial)) and absf(b.y-f.y)<1.3 and r.evade_serial!=b.service.serial:
                r.evade_serial=b.service.serial;r.routes=mini(2,r.routes+1);r.route_ttl=300 if perk(f,"zip_route") else 180
                s.events.append({"kind":"route_gained","target":i})
            if r.followup>0 and f.state=="attack" and f.frame>=r.followup:
                r.followup=0;r.zip_second=true;f.connected=false
        if f.character==3:
            if b.state=="attack" and b.y<1.2 and b.frame>=s.move_for(b,b.move).startup and b.frame<s.move_for(b,b.move).startup+s.move_for(b,b.move).active:
                var old:int=r.nodes.size()
                r.nodes=r.nodes.filter(func(node:Dictionary)->bool:return absf(node.x-b.x)>s.move_for(b,b.move).reach+.25 or (node.x-b.x)*b.face<0)
                if old!=r.nodes.size():s.events.append({"kind":"node_broken","target":i})
            if f.state=="attack" and f.move=="special" and f.frame>=s.move_for(f,f.move).startup and not r.placed:
                r.placed=true
                if r.nodes.size()==2:r.nodes.pop_front()
                var position:float=clampf(f.x+f.face*(2.4 if f.get("node_far",false) else 1.2),-s.EDGE,s.EDGE)
                r.nodes.append({"x":position,"life":420 if perk(f,"loop_life") else 300,"id":r.serial})
                s.events.append({"kind":"node_placed","target":i,"x":position})
            elif f.state=="attack" and f.move=="node_pulse" and f.frame>=8 and not r.placed:
                r.placed=true
                var nodes:Array=r.nodes.duplicate(true);r.nodes.clear();r.node_cd=60 if perk(f,"loop_cycle") else 84
                if not nodes.is_empty():
                    var low:float=nodes[0].x;var high:float=nodes[-1].x
                    pulse(s,i,minf(low,high)-.70,maxf(low,high)+.70,(low+high)*.5)
            elif f.state=="attack" and f.move=="overdrive" and not r.encore.is_empty() and f.frame>=s.move_for(f,f.move).startup+(2-r.encore.size())*4:
                var node:Dictionary=r.encore.pop_front()
                if r.nodes.any(func(live:Dictionary)->bool:return live.id==node.id):
                    r.nodes=r.nodes.filter(func(live:Dictionary)->bool:return live.id!=node.id)
                    pulse(s,i,node.x-.85,node.x+.85,node.x)
            elif f.state!="attack":r.encore.clear()
func pulse(s:RefCounted,i:int,low:float,high:float,origin:float) -> void:
    var b:Dictionary=s.fighters[1-i]
    s.events.append({"kind":"node_pulse_fx","target":i,"x":origin,"low":low,"high":high})
    if b.y>1.45 or b.x<low or b.x>high or b.invuln>0:return
    s.service_contacts.append({"owner":i,"origin":origin})
func resolve_pulse(s:RefCounted,i:int,origin:float) -> void:
    var f:Dictionary=s.fighters[i]
    var saved_move:String=f.move;var connected:bool=f.connected;var saved_data:Variant=f.get("move_data",null)
    f.move="node_pulse";f.pulse_origin=origin
    s._resolve_hit(i,false)
    f.erase("pulse_origin");f.move=saved_move;f.connected=connected
    if saved_data!=null:f.move_data=saved_data
func observe(s:RefCounted,event:Dictionary) -> void:
    var kind:String=event.kind
    if kind=="parry":
        var f:Dictionary=s.fighters[event.target]
        if f.character==2 and event.get("move","")!="node_pulse" and event.get("distance",0.0)<=3.0:
            f.service.sample=1;f.service.sample_ttl=360 if perk(f,"hush_hold") else 240
            s.events.append({"kind":"sample_gained","target":event.target})
    if kind=="dash":
        var f:Dictionary=s.fighters[event.target]
        if f.character==0 and f.service.routes>0 and f.service.get("use_route",false):
            f.service.routes-=1;f.service.use_route=false;f.dash_cd=24 if perk(f,"zip_dash") else 30;f.vx*=1.12
            s.events.append({"kind":"route_spent","target":event.target})
    if kind=="hit":
        var f:Dictionary=s.fighters[event.attacker];var r:Dictionary=f.service
        if f.character==0 and event.move=="special" and not r.zip_second:
            r.followup=f.frame+preload("res://scripts/combat/last_service/zip_express.gd").FOLLOWUP_DELAY
            r.zip_second_at=r.followup
        if f.character==0 and event.move=="overdrive" and r.flurry_left>0:r.flurry_left-=1;r.followup=f.frame+5
        if r.refund_serial!=r.serial:
            var refund:=0.0
            if f.character==0 and event.move in ["special","overdrive"] and perk(f,"zip_confirm"):refund=4
            if f.character==2 and r.sample_boost and perk(f,"hush_gain"):refund=5
            if f.character==3 and event.move=="node_pulse" and perk(f,"loop_gain"):refund=4
            if refund>0:f.meter=minf(100,f.meter+refund);r.refund_serial=r.serial
