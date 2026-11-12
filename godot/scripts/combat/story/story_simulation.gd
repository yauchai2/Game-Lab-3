extends "res://scripts/combat/enemies/squad_simulation.gd"
## M1: a finite three-wave story encounter, isolated from existing modes.
const CampaignRules=preload("res://scripts/combat/story/campaign_rules.gd")
const Balance=preload("res://scripts/combat/city/city_balance.gd")
const WAVES=[["grunt","grunt","grunt"],["grunt","rusher","grunt","rusher"],["guard","grunt","rusher","grunt","guard","grunt"]]
const SPAWNS=[2.8,4.6,-3.7,-5.6,7.0,-7.0]
var campaign_enabled:=false
var campaign_skills:Array=[]
var campaign_stats:Dictionary={}
var campaign_room:=0
var campaign_boss:=""
var campaign_route:="combat"
var campaign_hazards:Array=[]
var campaign_props:Array=[]
var reinforcements:Array=[]
var campaign_lesson:=""
var campaign_tier:=0
var campaign_captain:=false
var campaign_caption:=""
var campaign_counter:=""
var parry_refund_left:=12.0
var chase_refund_left:=10.0
var wave_recipes:Array=WAVES.duplicate(true)
var story_enabled:=false
var wave_index:=0
var wave_revision:=0
var story_state:=""
var arrival_left:=0
var break_left:=0
var checkpoint:Dictionary={}
var body_chain=preload("res://scripts/combat/story/body_chain.gd").new()

func begin_story() -> void:
    story_enabled=true;training=false;arcade_enabled=true;endless=false
    checkpoint={"health":100,"meter":60.0}
    _load_wave(0,100,60.0)

func end_squad() -> void:
    campaign_boss="";campaign_route="combat";campaign_lesson="";campaign_hazards.clear();campaign_props.clear();reinforcements.clear()
    campaign_tier=0;campaign_captain=false;campaign_caption="";campaign_counter=""
    campaign_enabled=false;campaign_skills.clear();campaign_stats.clear();wave_recipes=WAVES.duplicate(true)
    story_enabled=false;story_state="";checkpoint.clear();body_chain.clear()
    super.end_squad()

func _load_wave(index:int,hp:int,meter:float) -> void:
    campaign_hazards.clear();campaign_props=[]
    if campaign_enabled and campaign_lesson=="":campaign_props=[{"x":-4.0,"hp":2,"hits":[]},{"x":3.8,"hp":2,"hits":[]}]
    reinforcements=wave_recipes[index].slice(6)
    wave_index=index;wave_revision+=1;body_chain.clear();parry_refund_left=12.0;chase_refund_left=10.0
    reset_round();phase="fight";countdown=0;remaining=99999.0
    squad_enabled=true;squad_level=clampi(difficulty,0,2);squad_clock=0;squad_focus=0;next_attack_at=75
    struck.clear();strike_serial=-1;squad_members.clear()
    var template:Dictionary=fighters[1].duplicate(true)
    for id in mini(6,wave_recipes[index].size()):
        var f:Dictionary=template.duplicate(true);var role:String=wave_recipes[index][id]
        f.character=4;f["squad_id"]=id;f["story_role"]=role
        f["max_health"]={"grunt":35,"rusher":28,"guard":48,"jammer":26,"heavy":65,"captain":65,"boss":230}[role]
        if campaign_enabled:
            f.max_health+=floori(float(campaign_room)/3.0)*4
            if (campaign_captain if campaign_tier>0 else campaign_room%3==2) and id==0 and role in ["guard","captain"]:
                f.max_health=80+campaign_room*4+campaign_tier*15;f["captain"]=true
            f.max_health=ceili(f.max_health*(1.0+minf(.5,float(campaign_stats.get("enemy_hp",0)))))
            if role=="boss":
                f.max_health=roundi((180 if campaign_boss=="gantry" else 240)*(1.0+minf(.3,float(campaign_stats.get("enemy_hp",0)))))
                CampaignRules.boss(f,campaign_boss)
        f.health=f.max_health;f.x=5.5 if role=="boss" else SPAWNS[id];f.face=1 if f.x<0 else -1;f.meter=0.0
        f["arrival"]=45;f["dead_age"]=0
        f["rush_charge"]=0;f["rush_cd"]=0;f["rush_follow"]=false;f["rush_direction"]=f.face
        squad_members.append(f)
    fighters[0].x=0.0;fighters[0].health=hp;fighters[0].meter=clampf(meter,0,100);fighters[1]=squad_members[0]
    checkpoint={"health":hp,"meter":meter}
    story_state="combat";arrival_left=75;break_left=0
    events=[{"kind":"story_wave_start","wave":index+1}]

func retry_story_wave() -> void:
    if not story_enabled:return
    _load_wave(wave_index,maxi(60,checkpoint.health),maxf(60.0,checkpoint.meter))

func next_story_wave() -> void:
    if not story_enabled or story_state!="break":return
    _load_wave(wave_index+1,fighters[0].health,fighters[0].meter)

func tick(player:Dictionary={},opponent:Dictionary={}) -> void:
    if not story_enabled:super.tick(player,opponent);return
    if story_state!="combat":
        events.clear()
        if story_state=="break":
            var focus:Dictionary=fighters[1]
            for f in squad_members:
                fighters[1]=f;f.state="stun";f.stun=999;f.ricochet.ticks=0;f.air.stall=0;f.air.bounce_granted=false;f.vy=minf(0,f.vy)
                f.flash=maxi(0,f.flash-1)
                super._advance_fighter(1,{})
            fighters[1]=focus
            events.clear()
            break_left-=1
            if break_left<=0:next_story_wave()
        return
    var previous:Array=[]
    for f in squad_members:previous.append(Vector2(f.x,f.y))
    var clock:int=ai_tick
    super.tick(player,opponent)
    if ai_tick>clock:
        arrival_left=maxi(0,arrival_left-1)
        body_chain.advance(self,previous)
        if campaign_enabled:
            CampaignRules.hazards(self)
            if story_state=="combat":CampaignRules.props(self,previous)
            _reinforce()
        _finish_round()

func ai_command() -> Dictionary:
    if not story_enabled:return super.ai_command()
    var f:Dictionary=fighters[1]
    if f.has("boss"):return {}
    if arrival_left>0 or (campaign_enabled and int(f.get("arrival",0))>0):return {"axis":signf(fighters[0].x-f.x)*.25,"allow_parry":false}
    if f.story_role=="jammer" and f.state=="idle" and squad_clock>=next_attack_at:
        if squad_clock%150==0 and campaign_hazards.size()<3:
            campaign_hazards.append({"kind":"jammer","x":float(fighters[0].x),"half":1.3,"warn":60,"active":6,"age":0,"source":f.squad_id,"boss":false,"face":f.face,"struck":false})
            next_attack_at=squad_clock+90
        if absf(f.x-fighters[0].x)>3:return {"axis":-signf(fighters[0].x-f.x)*.15,"allow_parry":false}
    if f.story_role=="rusher" and f.state=="idle" and f.rush_charge==0 and f.rush_cd==0 and hitstop==0 and squad_clock>=next_attack_at and fighters[0].state not in ["stun","blockstun"] and absf(f.x-fighters[0].x)>2.0:
        f.rush_charge=24
        f.rush_direction=signf(fighters[0].x-f.x)
        events.append({"kind":"story_rush_charge","squad_id":f.squad_id})
    if f.rush_charge>0:return {"allow_parry":false}
    return super.ai_command()

func _advance_fighter(i:int,command:Dictionary) -> void:
    var f:Dictionary=fighters[i]
    var event_start:=events.size()
    if campaign_enabled and i==1:
        f["arrival"]=maxi(0,int(f.get("arrival",0))-1)
        if f.health<=0:f["dead_age"]=int(f.get("dead_age",0))+1
        if f.has("boss") and f.health>0:
            if arrival_left<=0:CampaignRules.boss_step(self,f)
            return
    if campaign_enabled and i==0:f["city_counter"]=maxi(0,int(f.get("city_counter",0))-1)
    if story_enabled and i==1 and f.health<=0:f.flash=maxi(0,f.flash-1)
    if story_enabled and i==1 and f.has("story_role") and f.health>0:
        command=command.duplicate()
        f.rush_cd=maxi(0,f.rush_cd-1)
        if f.state in ["stun","blockstun"]:f.rush_charge=0;f.rush_follow=false
        if f.rush_charge>0:
            f.rush_charge-=1;command={"axis":0.0,"allow_parry":false};f.buffer="";f.buffer_ttl=0
            if f.rush_charge==0:
                command={"dash":true,"axis":float(f.rush_direction),"allow_parry":false}
                f.rush_cd=150;f.rush_follow=true
        if f.rush_follow and f.state=="dash" and f.frame>=10:
            f.buffer="light";f.buffer_ttl=14
        elif f.rush_follow and f.state=="attack":f.rush_follow=false
        if f.story_role in ["guard","heavy","captain"] and f.state=="idle" and f.y<=.01 and f.guard>22 and squad_clock%150<95 and absf(f.x-fighters[0].x)<2.7:
            command={"guard":true,"allow_parry":false};f.buffer="";f.buffer_ttl=0
    if campaign_enabled and i==0:
        if "double_jump" not in campaign_skills and f.y>.01:f.jump_buffer=0
        if "chase" not in campaign_skills:
            f.air.chase_window=0;f.air.chase_buffer=0
    super._advance_fighter(i,command)
    if campaign_enabled and i==1 and f.health>0 and f.get("story_role","")!="captain" and squad_members.any(func(member:Dictionary)->bool:return member.health>0 and member.get("story_role","")=="captain"):
        f.guard=minf(100,f.guard+.15)
    if campaign_enabled and i==0:
        for event in events.slice(event_start):
            if event.kind=="homing_chase" and event.target==0:
                var refund:=minf(chase_refund_left,float(campaign_stats.get("chase_refund",0)))
                chase_refund_left-=refund;f.meter=minf(100,f.meter+refund)
    if story_enabled and i==1 and f.has("rush_charge") and f.rush_charge>0:f.face=f.rush_direction

func _choose_focus(player:Dictionary) -> void:
    if campaign_enabled:
        for f in squad_members:
            if f.has("boss") and f.health>0:squad_focus=int(f.squad_id);fighters[1]=f;return
    if story_enabled and not squad_members.is_empty():
        var current:Dictionary=squad_members[squad_focus]
        if current.health>0 and (current.rush_charge>0 or current.rush_follow or current.state=="dash"):return
    super._choose_focus(player)

func _can_hit(i:int) -> bool:
    if story_enabled and (fighters[i].health<=0 or fighters[1-i].health<=0):return false
    if campaign_enabled and i==0 and fighters[1].has("boss"):
        var a:Dictionary=fighters[0]
        if a.state!="attack" or a.connected:return false
        var m:Dictionary=move_for(a,a.move)
        return a.state=="attack" and not a.connected and a.frame>=m.startup and a.frame<m.startup+m.active and absf(a.x-fighters[1].x)<=m.reach+.65 and a.y<=3.7 and (fighters[1].x-a.x)*a.face>=-.2
    return super._can_hit(i)

func _resolve_hit(side:int,allow_exchange:=true) -> void:
    var start:int=events.size()
    var victim:Dictionary=fighters[1-side];var before_hp:=int(victim.health)
    var before_meter:=float(fighters[0].meter);var before_hero_hp:=int(fighters[0].health);var before_healed:=int(fighters[0].get("draw_healed",0))
    if campaign_enabled and side==0 and victim.has("boss") and fighters[0].move=="grab":
        fighters[0].connected=true;events.append({"kind":"block","target":1,"attacker":0,"squad_id":victim.squad_id});return
    super._resolve_hit(side,allow_exchange)
    if campaign_enabled and side==0 and victim.has("boss"):CampaignRules.boss_hit(self,victim,before_hp,fighters[0].move,before_meter,before_hero_hp,before_healed)
    if not story_enabled:return
    for event in events.slice(start):
        if campaign_enabled and event.kind=="parry" and event.target==0:
            fighters[0]["city_counter"]=180
            var refund:=minf(parry_refund_left,float(campaign_stats.get("parry_meter",0)))
            parry_refund_left-=refund;fighters[0].meter=minf(100,fighters[0].meter+refund)
        if event.kind=="hit" and side==0:
            if campaign_enabled:fighters[0]["city_counter"]=0
            var serial:int=fighters[0].service.serial
            if not body_chain.roots.has(serial):body_chain.roots[serial]={"hit":{},"count":0,"age":0}
            body_chain.roots[serial].hit[fighters[1].squad_id]=true
            if not fighters[1].has("boss") and event.move in ["heavy","grab","meteor","air_finisher","overdrive"]:
                body_chain.arm(fighters[1],fighters[0].service.serial,event.damage)

func _finish_round() -> void:
    if not story_enabled:super._finish_round();return
    if story_state!="combat" or phase!="fight":return
    if fighters[0].health<=0:
        story_state="failed";winner=1;phase="match_over"
        events.append({"kind":"ko","winner":1,"squad_id":squad_focus})
    elif remaining_enemies()==0:
        body_chain.clear();hitstop=0;continuation.clear();exchange.cancel_decision()
        if wave_index==wave_recipes.size()-1:
            story_state="complete";winner=0;phase="match_over"
            events.append({"kind":"ko","winner":0,"squad_id":squad_focus})
        else:
            story_state="break";break_left=180
            events.append({"kind":"story_wave_clear","wave":wave_index+1})

# Campaign ability permissions are enforced at the move owner, including held-J
# and buffered/automatic routes. Existing M1 and all standard modes delegate.
func _start_attack(i:int,requested:String) -> void:
    if not campaign_enabled or i!=0:super._start_attack(i,requested);return
    var f:Dictionary=fighters[i]
    var resolved:=requested
    if requested=="light":
        resolved=(["air_jab","air_kick","meteor"] if f.y>.01 else ["jab","cross","launcher"])[mini(f.chain,2)]
    if resolved=="launcher" and "launcher" not in campaign_skills:requested="finisher"
    if resolved in ["meteor","air_finisher"] and "finisher" not in campaign_skills:requested="air_kick"
    if resolved=="overdrive" and "overdrive" not in campaign_skills:requested="special"
    super._start_attack(i,requested)

func move_for(fighter:Dictionary,name:String) -> Dictionary:
    var move:Dictionary=super.move_for(fighter,name)
    if not campaign_enabled:return move
    move=move.duplicate(true)
    if fighter.get("character",4)==4:
        var defence:float=float(campaign_stats.get("defence",0))
        if fighters[0].get("draw_core","")=="plate":defence=minf(defence,1.0-.8/.85)
        move.damage=maxi(1,roundi(float(move.damage)*(1.0+float(campaign_stats.get("enemy_damage",0)))*(1.0-defence)))
    else:
        var bonus:float=float(campaign_stats.get("damage",0))
        if name=="special":bonus+=float(campaign_stats.get("skill_damage",0))
        if fighter.y>.01:bonus+=float(campaign_stats.get("aerial_damage",0))
        else:bonus+=float(campaign_stats.get("ground_penalty",0))
        if name in ["heavy","finisher"]:bonus+=float(campaign_stats.get("heavy_damage",0))
        if name in ["meteor","air_finisher"]:bonus+=float(campaign_stats.get("finisher_damage",0))
        if int(fighter.get("city_counter",0))>0:bonus+=minf(.6,float(campaign_stats.get("counter_damage",0)))
        move["guard_multiplier"]=1.0+minf(.4,float(campaign_stats.get("guard_damage",0)))
        if name in ["heavy","grab","meteor","air_finisher","overdrive"]:move.push*=1.0+minf(.3,float(campaign_stats.get("launch_force",0)))
        bonus=Balance.attack_bonus(bonus,int(fighter.get("city_counter",0))>0)
        var total_cap:float=1.60 if int(fighter.get("city_counter",0))>0 else 1.50
        move.damage=maxi(1,roundi(float(move.damage)*minf(1.0+bonus,total_cap/(1.15 if fighter.get("draw_core","")=="fury" else 1.0))))
        if fighters[1].get("story_role","")=="heavy" and name in ["jab","cross"] and fighter.y<.5 and (fighter.x-fighters[1].x)*fighters[1].face>0:move.damage=maxi(1,roundi(move.damage*.65))
    return move

func skill_cost(f:Dictionary,name:String) -> int:
    var cost:int=super.skill_cost(f,name)
    if campaign_enabled and f.get("character",4)!=4:
        var plain:Dictionary=f.duplicate();plain.erase("draw_core")
        var base:int=super.skill_cost(plain,name)
        cost=maxi(1,ceili(base*maxf(.8,(1.0-float(campaign_stats.get("economy",0)))*(.8 if f.get("draw_core","")=="eco" else 1.0))))
    return cost

func remaining_enemies() -> int:return super.remaining_enemies()+reinforcements.size() if campaign_enabled else super.remaining_enemies()
func _reinforce() -> void:
    if reinforcements.is_empty():return
    for id in squad_members.size():
        var dead:Dictionary=squad_members[id]
        if dead.health>0 or dead.y>.01 or int(dead.get("dead_age",0))<35:continue
        var role:String=reinforcements.pop_front()
        var f:Dictionary=fighters[0].duplicate(true)
        f.character=4;f.squad_id=id;f.story_role=role;f.max_health={"grunt":35,"rusher":28,"guard":48,"heavy":65,"jammer":26,"captain":65}.get(role,35)
        f.health=f.max_health;f.state="idle";f.move="";f.frame=0;f.x=7.3 if id%2==0 else -7.3;f.face=-1 if f.x>0 else 1;f.y=0;f.vx=0;f.vy=0;f.meter=0.0
        f.guard=100;f.buffer="";f.buffer_ttl=0;f.invuln=45;f.flash=0;f.stun=0;f.air=AirMotion.fresh();f.service=ServiceRules.fresh();f.ricochet=ArenaBox.fresh()
        f["rush_charge"]=0;f["rush_cd"]=0;f["rush_follow"]=false;f["rush_direction"]=f.face;f["arrival"]=60;f["dead_age"]=0;f["new_arrival"]=true
        f.erase("draw_core");f.erase("city_counter");squad_members[id]=f
        squad_focus=id;fighters[1]=f;wave_revision+=1;body_chain.clear();next_attack_at=squad_clock+60
        events.append({"kind":"reinforcement","squad_id":id})
        break
