extends RefCounted
## Simulation-only telegraphs. View and gear never decide whether an attack landed.
static func boss(f:Dictionary,kind:String) -> void:
    f["boss"]={"kind":kind,"phase":1,"age":0,"cycle":0,"step":"rest","left":70,"open":0,"stagger":0,"face":-1,"anchor":5.5,"cue":"","part":"ARMOURED LEGS"}
    f.x=5.5;f.face=-1;f.guard=100;f.y=0;f.vx=0;f.vy=0
static func boss_step(s:RefCounted,f:Dictionary) -> void:
    if f.health<=0:return
    var b:Dictionary=f.boss;var hero:Dictionary=s.fighters[0]
    b.age+=1;b.open=maxi(0,int(b.open)-1)
    var desired:int=3 if b.kind=="signal" and f.health<float(f.max_health)*.34 else (2 if f.health<float(f.max_health)*(.67 if b.kind=="signal" else .5) else 1)
    if desired>int(b.phase):
        s.campaign_hazards.clear()
        b.phase=desired;b.step="transition";b.left=70;b.open=0;b.cue="PHASE %d"%desired
        s.events.append({"kind":"boss_phase","phase":desired,"squad_id":f.squad_id})
    f.x=b.anchor;f.y=0;f.vx=0;f.vy=0;f.state="idle";f.stun=0;f.air.stall=0;f.guarding=false;f.face=b.face
    b.left-=1
    if b.left>0:
        b.part="EXPOSED CORE" if int(b.open)>0 else "ARMOURED LEGS"
        return
    if b.step in ["rest","recover","transition"]:
        b.cycle+=1;var attack:int=(int(b.cycle)-1)%3
        b.step="windup";b.left=60 if b.phase==1 else 48;b.face=1 if hero.x>f.x else -1
        b.cue=["JUMP","MOVE","PARRY / DODGE"][attack]
        var center:float=hero.x if attack==1 else f.x+b.face*2.4
        var width:float=1.8 if attack==1 else 4.6
        s.events.append({"kind":"boss_cue","squad_id":f.squad_id})
        s.campaign_hazards.append({"kind":["sweep","slam","bolt"][attack],"x":center,"half":width,"warn":int(b.left),"active":4,"age":0,"source":f.squad_id,"boss":true,"face":b.face,"struck":false,"bolt_x":float(f.x),"bolt_dir":float(b.face)})
    elif b.step=="windup":
        s.events.append({"kind":"boss_attack","squad_id":f.squad_id})
        b.step="recover";b.left=95 if b.phase==1 else 75;b.open=maxi(int(b.open),int(b.left));b.cue="PUNISH"
static func hurt(s:RefCounted,zone:Dictionary) -> void:
    var h:Dictionary=s.fighters[0]
    if h.health<=0:return
    var source:Dictionary=s.squad_members[int(zone.source)] if int(zone.source)<s.squad_members.size() else s.fighters[1]
    if h.invuln>0:
        if h.character==0 and h.state=="dash" and absf(h.x-source.x)<=3 and not zone.get("route_rewarded",false):
            zone["route_rewarded"]=true;h.service.routes=mini(2,int(h.service.routes)+1);h.service.route_ttl=300 if "zip_route" in h.perks else 180
            s.events.append({"kind":"route_gained","target":0})
        return
    var parryable:bool=zone.kind in ["sweep","bolt"]
    var in_front:bool=(float(source.x)-float(h.x))*float(h.face)>=-.1
    if parryable and h.guarding and in_front:
        if h.guard_frames<=12 and h.parry_cd==0:
            var refund:=minf(s.parry_refund_left,float(s.campaign_stats.get("parry_meter",0)));s.parry_refund_left-=refund
            h.parry_cd=60;h.meter=minf(100,h.meter+18+refund);h.counter_window=24;h["city_counter"]=180
            if source.has("boss"):source.boss.open=150;source.boss.cue="REFLECT / CORE OPEN";source.health=maxi(0,int(source.health)-8)
            var parry_event:Dictionary={"kind":"parry","target":0,"attacker":1,"move":"heavy","distance":absf(h.x-source.x),"squad_id":int(zone.source)}
            s.events.append(parry_event);s.service_rules.observe(s,parry_event)
        else:
            h.guard=maxf(0,h.guard-28);h.state="blockstun";h.stun=10
            s.events.append({"kind":"block","target":0,"attacker":1,"squad_id":int(zone.source)})
        return
    var base:int=22 if zone.kind=="slam" else (16 if zone.kind in ["sweep","bolt"] else 10)
    var damage:int=maxi(1,roundi(base*(1.0+minf(.25,float(s.campaign_stats.get("enemy_damage",0))))*(1.0-float(s.campaign_stats.get("defence",0)))*(.85 if h.get("draw_core","")=="plate" else 1.0)))
    h.health=maxi(0,h.health-damage);h.state="stun";h.stun=22;h.invuln=35;h.flash=8;h.buffer="";h.buffer_ttl=0;h.jump_buffer=0
    h.vx=signf(h.x-float(source.x))*4;h.vy=0;h.guarding=false;s.air_motion.cancel_stall(h)
    s.events.append({"kind":"hit","target":0,"attacker":1,"damage":damage,"move":"heavy","strength":.6,"face":signf(h.x-source.x),"squad_id":int(zone.source),"hazard":true})
static func hazards(s:RefCounted) -> void:
    for zone in s.campaign_hazards:
        zone.age+=1
        var active:bool=int(zone.age)>=int(zone.warn)
        if not active or zone.struck:continue
        var hero:Dictionary=s.fighters[0]
        if zone.kind=="bolt":
            zone.bolt_x+=float(zone.bolt_dir)*.30;zone.active=60
            if absf(hero.x-float(zone.bolt_x))<.6 and hero.y<1.8:zone.struck=true;hurt(s,zone)
        elif absf(hero.x-float(zone.x))<=float(zone.half) and (hero.y<.85 if zone.kind!="slam" else hero.y<3.0):
            zone.struck=true;hurt(s,zone)
    s.campaign_hazards=s.campaign_hazards.filter(func(z:Dictionary)->bool:return int(z.age)<int(z.warn)+int(z.active))
    if s.campaign_room in [7,8,13,14] or s.campaign_route=="hazard":
        if s.squad_clock>100 and s.squad_clock%240==0 and s.campaign_hazards.size()<3:
            s.campaign_hazards.append({"kind":"street","x":float(s.fighters[0].x),"half":1.4,"warn":65,"active":7,"age":0,"source":s.squad_focus,"boss":false,"face":1,"struck":false})
static func boss_hit(s:RefCounted,f:Dictionary,before:int,move:String,before_meter:float,before_hero_hp:int,before_healed:int) -> void:
    var b:Dictionary=f.boss;var open:bool=int(b.open)>0
    var dealt:=maxi(0,before-int(f.health));var cap:=14 if open and s.fighters[0].y>.8 else (11 if open else 3)
    if b.step=="transition":cap=0
    var applied:=mini(cap,dealt);f.health=maxi(0,before-applied)
    var hero:Dictionary=s.fighters[0]
    var gain:float=maxf(0,hero.meter-before_meter)
    hero.meter=minf(100,before_meter+minf(gain,applied*1.1*float(s.profile_for(hero.character).gain)*(1.3 if hero.get("draw_core","")=="flow" else 1.0)))
    if applied==0:hero.health=before_hero_hp;hero["draw_healed"]=before_healed
    s.combo_damage=maxi(0,s.combo_damage-(dealt-applied));s.last_combo_damage=s.combo_damage
    for event in s.events:
        if event.kind=="hit" and event.get("attacker",-1)==0 and event.get("squad_id",f.squad_id)==f.squad_id:
            event.damage=applied;event["boss_part"]="core" if open else "legs"
    if not open and move in ["heavy","launcher","finisher"]:
        b.stagger+=1
        if b.stagger>=3:b.open=130;b.stagger=0;b.cue="KNEE BREAK / CORE OPEN"
    f.x=b.anchor;f.y=0;f.vx=0;f.vy=0;f.state="idle";f.stun=0;f.air.stall=0;f.air.combo_left=0;f.air.bounce_granted=false;f.ricochet.ticks=0

static func props(s:RefCounted,previous:Array) -> void:
    var hero:Dictionary=s.fighters[0]
    for prop in s.campaign_props:
        if int(prop.hp)<=0:continue
        var serial:=-1;var source:Dictionary=hero;var body:Dictionary={}
        if hero.state=="attack" and hero.move in ["heavy","finisher","meteor","air_finisher","overdrive"]:
            var move:Dictionary=s.move_for(hero,hero.move)
            if hero.frame>=move.startup and hero.frame<move.startup+move.active and absf(hero.x-float(prop.x))<move.reach and (float(prop.x)-hero.x)*hero.face>=-.2 and hero.y<1.5:
                serial=int(hero.service.serial)
        if serial<0:
            for moving in s.body_chain.bodies:
                var f:Dictionary=s.squad_members[int(moving.id)]
                if absf(f.vx)<6 or f.y>1.5:continue
                if float(prop.x)>=minf(previous[int(moving.id)].x,f.x)-.5 and float(prop.x)<=maxf(previous[int(moving.id)].x,f.x)+.5:
                    serial=int(moving.serial);source=f;body=moving;break
        if serial<0 or serial in prop.hits:continue
        prop.hits.append(serial);prop.hp-=2 if hero.move=="overdrive" or not body.is_empty() else 1
        if int(prop.hp)>0:continue
        if not s.body_chain.roots.has(serial):s.body_chain.roots[serial]={"hit":{},"count":0,"age":0}
        s.body_chain.roots[serial]["keep"]=90
        if body.is_empty():body={"id":0,"serial":serial,"damage":18,"depth":0,"left":0}
        body=body.duplicate();body["prop"]=true
        var center:=Vector2(float(prop.x),0)
        for id in s.squad_members.size():
            if Vector2(s.squad_members[id].x,s.squad_members[id].y).distance_to(center)<=1.8:s.body_chain._impact(s,body,id,source,center,[],true)
        s.events.append({"kind":"prop_break","x":float(prop.x)})
