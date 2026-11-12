extends "res://scripts/combat/enemies/squad_simulation.gd"
## M1: a finite three-wave story encounter, isolated from existing modes.
const WAVES=[["grunt","grunt","grunt"],["grunt","rusher","grunt","rusher"],["guard","grunt","rusher","grunt","guard","grunt"]]
const SPAWNS=[2.8,4.6,-3.7,-5.6,7.0,-7.0]
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
    story_enabled=false;story_state="";checkpoint.clear();body_chain.clear()
    super.end_squad()

func _load_wave(index:int,hp:int,meter:float) -> void:
    wave_index=index;wave_revision+=1;body_chain.clear()
    reset_round();phase="fight";countdown=0;remaining=99999.0
    squad_enabled=true;squad_level=clampi(difficulty,0,2);squad_clock=0;squad_focus=0;next_attack_at=75
    struck.clear();strike_serial=-1;squad_members.clear()
    var template:Dictionary=fighters[1].duplicate(true)
    for id in WAVES[index].size():
        var f:Dictionary=template.duplicate(true);var role:String=WAVES[index][id]
        f.character=4;f["squad_id"]=id;f["story_role"]=role
        f["max_health"]={"grunt":35,"rusher":28,"guard":48}[role]
        f.health=f.max_health;f.x=SPAWNS[id];f.face=1 if f.x<0 else -1;f.meter=0.0
        f["rush_charge"]=0;f["rush_cd"]=0;f["rush_follow"]=false;f["rush_direction"]=f.face
        squad_members.append(f)
    fighters[0].x=0.0;fighters[0].health=hp;fighters[0].meter=meter;fighters[1]=squad_members[0]
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
        _finish_round()

func ai_command() -> Dictionary:
    if not story_enabled:return super.ai_command()
    var f:Dictionary=fighters[1]
    if arrival_left>0:return {"axis":signf(fighters[0].x-f.x)*.25,"allow_parry":false}
    if f.story_role=="rusher" and f.state=="idle" and f.rush_charge==0 and f.rush_cd==0 and hitstop==0 and squad_clock>=next_attack_at and fighters[0].state not in ["stun","blockstun"] and absf(f.x-fighters[0].x)>2.0:
        f.rush_charge=24
        f.rush_direction=signf(fighters[0].x-f.x)
        events.append({"kind":"story_rush_charge","squad_id":f.squad_id})
    if f.rush_charge>0:return {"allow_parry":false}
    return super.ai_command()

func _advance_fighter(i:int,command:Dictionary) -> void:
    var f:Dictionary=fighters[i]
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
        if f.story_role=="guard" and f.state=="idle" and f.y<=.01 and f.guard>22 and squad_clock%150<95 and absf(f.x-fighters[0].x)<2.7:
            command={"guard":true,"allow_parry":false};f.buffer="";f.buffer_ttl=0
    super._advance_fighter(i,command)
    if story_enabled and i==1 and f.has("rush_charge") and f.rush_charge>0:f.face=f.rush_direction

func _choose_focus(player:Dictionary) -> void:
    if story_enabled and not squad_members.is_empty():
        var current:Dictionary=squad_members[squad_focus]
        if current.health>0 and (current.rush_charge>0 or current.rush_follow or current.state=="dash"):return
    super._choose_focus(player)

func _can_hit(i:int) -> bool:
    if story_enabled and (fighters[i].health<=0 or fighters[1-i].health<=0):return false
    return super._can_hit(i)

func _resolve_hit(side:int,allow_exchange:=true) -> void:
    var start:int=events.size()
    super._resolve_hit(side,allow_exchange)
    if not story_enabled:return
    for event in events.slice(start):
        if event.kind=="hit" and side==0:
            var serial:int=fighters[0].service.serial
            if not body_chain.roots.has(serial):body_chain.roots[serial]={"hit":{},"count":0,"age":0}
            body_chain.roots[serial].hit[fighters[1].squad_id]=true
            if event.move in ["heavy","grab","meteor","air_finisher","overdrive"]:
                body_chain.arm(fighters[1],fighters[0].service.serial,event.damage)

func _finish_round() -> void:
    if not story_enabled:super._finish_round();return
    if story_state!="combat" or phase!="fight":return
    if fighters[0].health<=0:
        story_state="failed";winner=1;phase="match_over"
        events.append({"kind":"ko","winner":1,"squad_id":squad_focus})
    elif remaining_enemies()==0:
        body_chain.clear();hitstop=0;continuation.clear();exchange.cancel_decision()
        if wave_index==WAVES.size()-1:
            story_state="complete";winner=0;phase="match_over"
            events.append({"kind":"ko","winner":0,"squad_id":squad_focus})
        else:
            story_state="break";break_left=180
            events.append({"kind":"story_wave_clear","wave":wave_index+1})
