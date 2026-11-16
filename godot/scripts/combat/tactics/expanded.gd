extends RefCounted
## Later chapter tactics. No presentation object or input polling owns their rules.
const INFO=[
 ["An airborne diving kick. It spends the existing air budget and does not reset jumps.","Step back, then kick a returning arc. No dodge invulnerability.","Spend two routes. Equipping this banks routes on E instead of spending them on boosted dodges. Confirm a hit, then press again for a different target.","Run along a fixed street line. Press again to stop and kick; a blocked route stops the run."],
 ["A committed shoulder rush. The defender can block and punish recovery.","A short cable pulls an ordinary enemy only after a real hit. Bosses stay anchored.","During L charge, replace the punch with a fan. Only the fan fee is kept; resolved or interrupted preload cannot be spent again.","Place one visible delayed ground shock. Jump or leave the warning area to escape."],
 ["Step back and punish a committed approach. Delayed attacks can catch the step.","A close three-hit sequence. Each extra hit needs a fresh press after a confirmed hit.","Disrupt nearby forward-facing gun and jammer preparation once. Existing bullets and boss moves continue.","Spend one sample on a pulse. Confirm a hit, then press again for a second pulse."],
 ["Consume two nodes to strike the line between them once. Enemies can jump or break setup.","Step back, push with the baton and recover one node into a weaker pulse.","Turn two nodes into one destructible elevated emitter. Press again to fire it once.","Consume two nodes for two fixed line segments. The route never follows a moving enemy."]]

static func move(hero:int,id:int) -> Dictionary:
    var m:={"startup":14,"active":1,"recovery":26,"damage":12,"reach":0.0,"stun":18,"push":4.0,"lift":0.0,"stop":0,"guard_multiplier":1.0,"ricochet":false}
    match hero:
        0:
            match id:
                2:m.startup=6;m.damage=13;m.push=5.0;m.lift=-5.0
                3:m.startup=14;m.damage=9;m.push=3.0
                4:m.startup=18;m.damage=12;m.push=6.0;m.stun=22
                5:m.startup=30;m.damage=17;m.push=7.0;m.recovery=34
        1:
            match id:
                2:m.startup=18;m.damage=15;m.push=8.0;m.stun=24
                3:m.startup=20;m.damage=8;m.push=1.0;m.stun=20
                4:m.startup=12;m.damage=13;m.push=6.0;m.guard_multiplier=1.3
                5:m.startup=22;m.damage=15;m.push=7.0;m.stun=24
        2:
            match id:
                2:m.startup=16;m.damage=12;m.push=2.0
                3:m.startup=10;m.damage=7;m.push=1.0;m.stun=18;m.recovery=20
                4:m.startup=18;m.damage=0
                5:m.startup=16;m.damage=13;m.push=3.0;m.stun=18
        3:
            match id:
                2:m.startup=22;m.damage=12;m.push=3.0
                3:m.startup=12;m.damage=8;m.push=4.0
                4:m.startup=18;m.damage=10;m.push=2.0
                5:m.startup=30;m.damage=14;m.push=5.0;m.recovery=34
    return m

static func reason(s:RefCounted,side:int,id:int,follow:=false) -> String:
    var f:Dictionary=s.fighters[side]
    if f.character==0 and id==2:
        if f.y<=.1:return "Jump before using this diving tactic."
        if f.air.fast_used:return "This jump has already spent its diving tactic."
        return ""
    if f.y>.01:return "This tactic needs solid ground."
    if f.character==0 and id==4 and follow:
        if not s.tactics.targets(s,side).any(func(target:Dictionary)->bool:return target.health>0 and target.invuln<=0 and int(target.get("squad_id",0))!=f.tactical.chain_target and (target.x-f.x)*f.face>=.8 and (target.x-f.x)*f.face<=5.5):return "No second legal target on this route."
    if f.character==0 and id==4 and not follow and f.service.routes<2:return "Earn two routes before a two-stop delivery."
    if f.character==1 and id==4 and (f.service.preload<=0 or f.service.get("preload_spent",false)):return "Charge L first to store preload."
    if f.character==3:
        if id in [2,4,5] and f.service.nodes.size()<2:return "Place two nodes first."
        if id==3 and f.service.nodes.is_empty():return "Place a node first."
    return ""

static func begin(s:RefCounted,side:int,id:int,follow:bool) -> void:
    var f:Dictionary=s.fighters[side];var t:Dictionary=f.tactical
    t["origin"]=float(f.x);t["aim"]=int(s.fighters[1-side].get("squad_id",0));t["stopped"]=false
    t["cast_skill"]=id
    if not follow:t.chain_stage=0;t.follow_left=0;t.follow_window=0
    else:t.chain_stage+=1;t.follow_left-=1;t.follow_window=0
    if f.character==0:
        if id==2:f.air.fast_used=true;s.air_motion.cancel_stall(f);f.vy=-8.0
        if id==4 and not follow:f.service.routes-=2
        if id==4 and follow:
            var chosen:Dictionary={};var distance:=INF
            for target in s.tactics.targets(s,side):
                if target.health<=0 or target.invuln>0 or int(target.get("squad_id",0))==t.chain_target:continue
                var gap:float=(target.x-f.x)*f.face
                if gap>=.8 and gap<=5.5 and gap<distance:chosen=target;distance=gap
            t.aim=int(chosen.get("squad_id",-1))
    if f.character==1 and id==4:t["vent_tier"]=int(f.service.preload);f.service.preload=0
    if f.character==2 and id==5 and not follow:
        t["original_sample"]=f.service.sample>0
        f.service.sample=0;f.service.sample_ttl=0
    if f.character==3 and id==4:t["send_emitter"]=emitter(f)

static func emitter(f:Dictionary) -> bool:
    return f.service.nodes.size()==2 and f.service.nodes.all(func(n:Dictionary)->bool:return n.get("emitter",false))
static func follow_ready(f:Dictionary,id:int) -> bool:
    if f.health<=0 or f.state in ["stun","blockstun"]:return false
    if f.character==3 and id==4:return emitter(f)
    return f.tactical.follow_window>0 and f.tactical.follow_left>0 and int(f.tactical.get("cast_skill",-1))==id

static func before(s:RefCounted,side:int,command:Dictionary) -> void:
    var f:Dictionary=s.fighters[side];var t:Dictionary=f.tactical
    if t.follow_window>0 and f.state in ["stun","blockstun"]:t.follow_window=0;t.follow_left=0
    if s.hitstop>0:return
    if f.character==1 and f.state=="attack" and f.move=="special" and f.frame<s.move_for(f,"special").startup and f.service.preload>0 and not f.service.get("preload_spent",false):
        var requested:String=command.get("attack","")
        if s.TacticalSkills.is_move(requested):
            var slot:int=s.TacticalSkills.MOVE_NAMES.find(requested)
            var credit:int=s.tactics.conversion_credit(s,side,s.tactics.skill(side,slot))
            if credit>0 and s.tactics.quote(s,side,slot,credit).ready and not command.get("guard",false) and not command.get("dash",false) and not command.get("jump",false) and f.jump_buffer<=0:
                # Transfer the paid L commitment once; the replacement then pays its own cost.
                f.meter=minf(100,f.meter+credit);f.service_skill_paid=0;f.state="idle";f.buffer="";f.buffer_ttl=0
    if f.state!="attack" or not s.TacticalSkills.is_move(f.move):return
    var id:int=s.tactics.skill(side,s.TacticalSkills.MOVE_NAMES.find(f.move))
    if id<2:return
    if f.character==0 and id==5 and command.get("attack","")==f.move and f.frame>=6 and not t.fired:
        t.stopped=true;f.frame=int(s.move_for(f,f.move).startup)-1;command.erase("attack")
    elif (command.get("attack","")==f.move or (f.buffer==f.move and f.buffer_ttl>0)) and follow_ready(f,id) and (f.hit_confirmed or (f.character==3 and id==4 and emitter(f))) and reason(s,side,id,true)=="" and f.frame>=s.move_for(f,f.move).startup+s.move_for(f,f.move).active:
        f.state="idle" # Only a real confirmed chain window permits the next paid-in-advance stage.
    if f.character==0 and id==2:s.air_motion.cancel_stall(f);f.vy=minf(f.vy,-8.0)

static func advance(s:RefCounted,side:int,id:int) -> void:
    var f:Dictionary=s.fighters[side];var t:Dictionary=f.tactical
    var m:Dictionary=s.move_for(f,f.move)
    if f.frame>=m.startup:return
    var dx:=0.0
    if f.character==0:
        if id==2:dx=float(f.face)*3.0*s.STEP
        if id==3 and f.frame<7:dx=-float(f.face)*4.0*s.STEP
        if id in [4,5] and not t.get("stopped",false):
            if absf(f.x-float(t.origin))<(2.4 if id==4 else 4.0):dx=float(f.face)*(7.0 if id==4 else 8.0)*s.STEP
    elif f.character==1 and id==2:dx=float(f.face)*5.0*s.STEP
    elif f.character==2:
        if id==2 and f.frame<7:dx=-float(f.face)*5.0*s.STEP
        elif id==3:dx=float(f.face)*1.5*s.STEP
    elif f.character==3 and id==3 and f.frame<6:dx=-float(f.face)*3.0*s.STEP
    if dx*float(f.face)>0:
        # A rush follows physical space, cannot teleport through the first body or a boss.
        for target in s.tactics.targets(s,side):
            if target.health<=0 or absf(target.y-f.y)>1.0:continue
            var gap:float=(target.x-f.x)*f.face
            if gap>=0:dx=float(f.face)*minf(absf(dx),maxf(0,gap-.85))
    f.x=clampf(f.x+dx,-s.EDGE,s.EDGE)

static func emit(s:RefCounted,side:int,id:int,data:Dictionary) -> void:
    var tactics:RefCounted=s.tactics;var f:Dictionary=s.fighters[side];var t:Dictionary=f.tactical
    var kind:="kick";var x:float=f.x;var dir:float=f.face;var speed:=0.0;var life:=1;var radius:=1.8
    var budget:=1
    match int(f.character):
        0:
            if id==2:radius=1.7
            if id==3:kind="arc";x=f.x+dir*.5;speed=.14;life=16;radius=.45
            if id==4:radius=1.9
            if id==5:radius=2.0;budget=3
        1:
            if id==2:radius=1.6
            if id==3:kind="cable";speed=.24;life=16;radius=.3
            if id==4:radius=2.5;budget=3;data.damage+=mini(2,int(t.get("vent_tier",0)))*2
            if id==5:kind="zone";x=clampf(f.x+dir*3.0,-s.EDGE,s.EDGE);radius=1.0;life=33;budget=4
        2:
            if id in [2,3]:radius=1.8
            if id==4:
                for target in tactics.targets(s,side):
                    var gap:float=(target.x-f.x)*f.face
                    if target.health>0 and not target.has("boss") and gap>=0 and gap<=(4.0 if f.get("tactic_anchor",false) else 3.5) and absf(target.y-f.y)<1.5:
                        target["tactic_silence"]=75 if f.get("tactic_anchor",false) else 60
                s.events.append({"kind":"tactic_pulse","target":side,"x":f.x+dir*1.7,"low":f.x,"high":f.x+dir*3.5})
                return
            if id==5:
                kind="bolt";speed=.3;life=25;radius=.25
                if not t.get("original_sample",false):data.damage=roundi(float(data.damage)*.55)
        3:
            if id==2:
                if f.service.nodes.size()!=2:return
                line(s,side,id,f.service.nodes[0].x,f.service.nodes[1].x,data)
                f.service.nodes.clear();return
            if id==3:
                if not f.service.nodes.is_empty():
                    var node:Dictionary=f.service.nodes.pop_back();var pulse:Dictionary=data.duplicate();pulse.damage=maxi(1,roundi(float(data.damage)*.5))
                    tactics.add_shot(f,side,id,"pulse",float(node.x),0,0,1,.65,2,pulse)
                    s.events.append({"kind":"tactic_pulse","target":side,"x":node.x,"low":node.x-.65,"high":node.x+.65})
            if id==4:
                if t.get("send_emitter",false):
                    if not emitter(f):return
                    x=float(f.service.nodes[0].x);kind="elevated";speed=.23;life=24;radius=.35
                    f.service.nodes.clear()
                else:
                    if f.service.nodes.size()!=2:return
                    var at:float=(float(f.service.nodes[0].x)+float(f.service.nodes[1].x))*.5
                    f.service.nodes=[{"x":at,"life":243 if f.get("tactic_anchor",false) else 180,"id":200000+tactics.serial,"emitter":true},{"x":at,"life":243 if f.get("tactic_anchor",false) else 180,"id":300000+tactics.serial,"emitter":true,"hidden":true}]
                    s.events.append({"kind":"tactic_pulse","target":side,"x":at,"low":at-.3,"high":at+.3});return
            if id==5:
                if f.service.nodes.size()!=2:return
                var nodes:Array=f.service.nodes.duplicate(true);f.service.nodes.clear()
                var start:int=tactics.shots.size()
                line(s,side,id,f.x,nodes[0].x,data)
                line(s,side,id,nodes[0].x,nodes[1].x,data)
                var common:Array=[]
                for index in range(start,tactics.shots.size()):tactics.shots[index].hit=common;tactics.shots[index].limit=4
                return
    if f.get("tactic_anchor",false):
        if kind in ["arc","cable","bolt","elevated"]:life=ceili(float(life)*1.35)
        elif kind in ["kick","zone"]:radius+=.25
    tactics.add_shot(f,side,id,kind,x,dir,speed,life,radius,budget,data)
    var shot:Dictionary=tactics.shots[-1]
    if kind=="kick":shot.y=f.y+.7
    if kind=="arc":shot["turn_at"]=8
    if kind=="zone":shot["delay"]=30
    if kind=="elevated":shot.y=2.0
    s.events.append({"kind":"tactic_fire","target":side,"skill":id,"x":x,"y":shot.y})

static func line(s:RefCounted,side:int,id:int,a:float,b:float,data:Dictionary) -> void:
    if absf(a-b)<.1:return
    s.tactics.add_shot(s.fighters[side],side,id,"wire",(a+b)*.5,0,0,1,absf(b-a)*.5,4,data.duplicate())
    s.events.append({"kind":"tactic_pulse","target":side,"x":(a+b)*.5,"low":minf(a,b),"high":maxf(a,b)})

static func hit(_s:RefCounted,p:Dictionary,target:Dictionary) -> void:
    var f:Dictionary=p.fighter;var t:Dictionary=f.tactical
    if p.skill<2:return
    if f.character==0 and p.skill==2 and target.health>0:target.vy=minf(target.vy,-5.0)
    if f.character==1 and p.skill==3 and not target.has("boss") and target.health>0:
        if target.get("story_role","")!="heavy" or target.state=="stun":target.vx=-signf(target.x-f.x)*4.0
    var same:bool=f.state=="attack" and f.move==p.move and f.service.serial==p.swing
    if not same:return
    if f.character==0 and p.skill==4:
        t.chain_target=int(target.get("squad_id",0));t.follow_left=1 if t.chain_stage==0 else 0;t.follow_window=30
    elif f.character==2 and p.skill in [3,5]:
        t.follow_left=(2 if p.skill==3 else 1)-int(t.chain_stage);t.follow_window=24
