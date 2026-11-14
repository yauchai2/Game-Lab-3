extends "res://scripts/combat/fight_simulation.gd"
## Reuses the two-side contact rules. All squad members keep live, independent state;
## only the current pressure fighter may initiate an attack. Others can still be hit.
var squad_enabled:=false
var squad_members:Array[Dictionary]=[]
var squad_focus:=0
var squad_level:=1
var squad_clock:=0
var next_attack_at:=45
var struck:Dictionary={}
var strike_serial:=-1

func begin_squad() -> void:
    squad_enabled=true;squad_level=clampi(difficulty,0,2);squad_clock=0;next_attack_at=60
    struck.clear();strike_serial=-1;squad_focus=0;squad_members.clear()
    var template:Dictionary=fighters[1].duplicate(true)
    for id in [3,4,5][squad_level]:
        var f:Dictionary=template.duplicate(true)
        f.character=4;f["squad_id"]=id;f["max_health"]=[35,45,55][squad_level];f.health=f.max_health
        f.x=[2.0,-3.5,4.8,-5.8,6.8][id];f.face=1 if f.x<0 else -1;f.meter=0.0
        squad_members.append(f)
    fighters[0].x=-.5;fighters[1]=squad_members[0]
    remaining=180.0

func end_squad() -> void:
    squad_enabled=false;squad_members.clear();struck.clear()

func remaining_enemies() -> int:
    return squad_members.filter(func(f:Dictionary)->bool:return f.health>0).size()

func move_for(f:Dictionary,name:String) -> Dictionary:
    var m:Dictionary=super.move_for(f,name)
    if squad_enabled and f.has("squad_id"):
        m.damage=maxi(3,roundi(m.damage*[.45,.55,.65][squad_level]))
        m.startup+=[7,5,3][squad_level];m.recovery+=[8,6,4][squad_level]
    return m

func ai_command() -> Dictionary:
    var command:Dictionary=super.ai_command()
    if not squad_enabled:return command
    if squad_clock<next_attack_at or fighters[0].state in ["stun","blockstun"]:
        command.erase("attack");command.erase("rush");command.erase("jump")
    return command

func tick(player:Dictionary={},opponent:Dictionary={}) -> void:
    if not squad_enabled:
        super.tick(player,opponent)
        return
    _choose_focus(player)
    fighters[1]=squad_members[squad_focus]
    var previous_clock:int=ai_tick
    super.tick(player,opponent)
    for event in events:
        if not event.has("squad_id"):event["squad_id"]=squad_focus
    if phase!="fight" or ai_tick==previous_clock:return
    squad_clock+=1
    var hero:Dictionary=fighters[0]
    if hero.service.serial!=strike_serial:
        strike_serial=hero.service.serial;struck.clear()
    for event in events:
        if (event.kind in ["hit","block","parry"] and event.get("attacker",-1)==0) or (event.kind=="throw_tech"):
            struck[squad_focus]=true
    var pulses:Array=events.filter(func(e:Dictionary)->bool:return e.kind=="node_pulse_fx" and e.target==0).duplicate(true)
    for id in squad_members.size():
        if id==squad_focus:continue
        var f:Dictionary=squad_members[id]
        fighters[1]=f
        var movement_start:int=events.size()
        f.air.parry_window=0 # Waiting members cannot start a two-party air reversal.
        _advance_air_limit(1)
        if f.health<=0:
            f.state="stun";f.stun=999
            _advance_fighter(1,{})
            _tag_since(movement_start,id)
            continue
        f.flash=maxi(0,f.flash-1)
        # Waiting fighters occupy distinct places on both sides, without attacking.
        var desired:float=clampf(hero.x+(-1.0 if id%2 else 1.0)*(2.7+float(id)*.7),-EDGE+.2,EDGE-.2)
        var axis:float=signf(desired-f.x)*.22 if absf(desired-f.x)>.25 else 0.0
        f.buffer="";f.buffer_ttl=0
        _advance_fighter(1,{"axis":axis,"allow_parry":false})
        _separate_bodies()
        _tag_since(movement_start,id)
        # Sweeps/normal strikes can contact more than one nearby opponent once.
        # Throws and signature follow-ups retain a single target, as do air reversals.
        if hero.state=="attack" and hero.move not in ["grab","special","overdrive"] and not struck.has(id) and not air_counter.active():
            var connected:bool=hero.connected;hero.connected=false
            if _can_hit(0):
                var first_event:int=events.size();_resolve_hit(0,false);struck[id]=true
                for event in events.slice(first_event):service_rules.observe(self,event)
            hero.connected=hero.connected or connected
        for pulse in pulses:
            if f.y<=1.45 and f.x>=pulse.low and f.x<=pulse.high and f.invuln==0:
                var first_event:int=events.size();service_rules.resolve_pulse(self,0,pulse.x)
                for event in events.slice(first_event):service_rules.observe(self,event)
    fighters[1]=squad_members[squad_focus]
    if remaining_enemies()==0:_finish_round()

func _tag_since(start:int,id:int) -> void:
    for event in events.slice(start):event["squad_id"]=id

func _resolve_hit(side:int,allow_exchange:=true) -> void:
    var start:int=events.size()
    super._resolve_hit(side,allow_exchange)
    if not squad_enabled:return
    var id:int=fighters[1].get("squad_id",squad_focus)
    for event in events.slice(start):
        event["squad_id"]=id
        if event.kind=="hit" and event.target==0:
            # A real hit earns breathing space; no simultaneous tag-team stun lock.
            next_attack_at=squad_clock+[100,80,60][squad_level]
            fighters[0].invuln=maxi(fighters[0].invuln,[36,30,24][squad_level])

func _choose_focus(player:Dictionary) -> void:
    if paired_throw.active():return
    if squad_members.is_empty():return
    var current:Dictionary=squad_members[squad_focus]
    if current.health>0:
        if hitstop>0 or air_counter.active() or exchange.active():return
        if current.state=="attack" or fighters[0].state!="idle" or fighters[0].counter_window>0:return
        if combo_owner==0 and current.state=="stun":return
    var selected:int=-1;var best:=INF
    var axis:float=player.get("axis",0.0)
    for id in squad_members.size():
        var f:Dictionary=squad_members[id]
        if f.health<=0:continue
        var distance:float=absf(f.x-fighters[0].x)
        if absf(axis)>.1 and (f.x-fighters[0].x)*axis<0:distance+=20.0
        if distance<best:best=distance;selected=id
    if selected>=0 and selected!=squad_focus:
        squad_focus=selected;fighters[1]=squad_members[selected]
        continuation.clear();rush_agent.reset()
        next_attack_at=maxi(next_attack_at,squad_clock+[50,36,24][squad_level])

func _finish_round() -> void:
    if not squad_enabled:
        super._finish_round()
        return
    if phase!="fight":return
    if fighters[0].health>0 and remaining_enemies()>0 and remaining>0:return
    winner=0 if remaining_enemies()==0 and fighters[0].health>0 else 1
    wins[winner]+=1;phase="match_over"
    exchange.cancel_decision();continuation.clear()
    events.append({"kind":"ko","winner":winner,"squad_id":squad_focus})
