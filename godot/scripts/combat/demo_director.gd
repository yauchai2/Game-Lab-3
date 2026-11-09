extends RefCounted
## Two deterministic showcase agents send normal simulation commands.
## Chapter presets are explicit demonstrations, not claims of competitive AI skill.
const CHAPTERS := ["combo","heavy","block","guard_break","parry","grab","throw_tech","dodge","special","pressure_press","pressure_turn","pressure_slip","jump","air_combo","meteor","air_counter_kick","air_counter_escape","air_counter_evade","wall_bounce","wall_tech","kinetic","duel","finale"]
var chapter:=0
var cycle:=0
var age:=0
var needs_setup:=true
var seen: Dictionary={}
var chapter_seen: Dictionary={}
var lead:=0
var sent:=false
func key() -> String:return CHAPTERS[chapter]
func limit() -> int:return 900 if key()=="duel" else (240 if key()=="kinetic" else 180)
func next() -> void:
    chapter+=1
    if chapter>=CHAPTERS.size():chapter=0;cycle+=1
    age=0;sent=false;needs_setup=true;chapter_seen.clear()
func prepare(s: RefCounted) -> void:
    s.training=true
    s.reset_training()
    s.ai_enabled=false;s.partner_mode=0
    lead=(chapter+cycle)%2
    var air: bool=key() in ["jump","air_combo","meteor","air_counter_kick","air_counter_escape","air_counter_evade","duel"]
    s.practice_scenario="air" if air else "free"
    for i in 2:
        s.fighters[i].x=-.5 if i==0 else .5
        s.fighters[i].meter=100.0
    if key().begins_with("air_counter") or key()=="meteor":
        for f in s.fighters:
            f.y=1.4;f.air.phase="apex"
        s.fighters[lead].chain=2
        s.fighters[lead].chain_ttl=45
    if key().begins_with("pressure"):s.exchange.pressure=90.0
    if key()=="guard_break":s.fighters[1-lead].guard=20.0
    if key() in ["wall_tech","wall_bounce"]:
        s.fighters[lead].x=6.8 if lead==0 else -6.8
        s.fighters[1-lead].x=7.8 if lead==0 else -7.8
    if key()=="jump":
        s.fighters[0].x=-2.0;s.fighters[1].x=2.0
    if key()=="kinetic":s.rally_enabled=true
    if key()=="finale":
        s.training=false
        for f in s.fighters:f.health=24
    age=0;sent=false;needs_setup=false;chapter_seen.clear()
func commands(s: RefCounted) -> Array:
    age+=1
    var inputs:=[{"allow_parry":false},{"allow_parry":false}]
    var a: Dictionary=s.fighters[lead]
    var b: Dictionary=s.fighters[1-lead]
    var attack: Dictionary=inputs[lead]
    var defense: Dictionary=inputs[1-lead]
    var kind:=key()
    if s.air_counter.active():
        var owner: int=s.air_counter.owner
        if s.air_counter.phase=="hold" and s.air_counter.age>=3:
            inputs[owner]["air_choice"]="escape" if kind=="air_counter_escape" else "kick"
        elif kind=="air_counter_evade" and s.air_counter.phase=="windup" and s.air_counter.age==2:
            inputs[1-owner]["dash"]=true
        return inputs
    if s.rally.active():
        if s.rally.phase=="compress" and s.rally.age>=3:inputs[s.rally.owner]["attack"]="light"
        elif s.rally.phase=="windup" and s.rally.age>=s.rally.WINDUP-2:
            inputs[1-s.rally.owner]["guard"]=true
            inputs[1-s.rally.owner]["guard_pressed"]=s.rally.age==s.rally.WINDUP-2
        return inputs
    if s.exchange.active():
        if int(s.exchange.clash.remaining)<=20:
            var choice:=kind.trim_prefix("pressure_")
            inputs[lead]["clash_choice"]=choice
            inputs[1-lead]["clash_choice"]={"press":"slip","turn":"press","slip":"turn"}.get(choice,"press")
        return inputs
    if kind=="duel":
        for side in 2:inputs[side]=duel_command(s,side)
        return inputs
    if kind=="jump":
        for side in 2:
            if age==8+side*12:inputs[side]["jump"]=true
            if age==42+side*12:inputs[side]["down_pressed"]=true
        return inputs
    if kind in ["combo","air_combo"]:
        if not sent and age>=12:
            attack["attack"]="heavy" if kind=="air_combo" else "light"
            if kind=="air_combo":attack["up"]=true
            sent=true
        elif kind=="air_combo" and a.air.chase_window>0 and not a.air.chase_used:attack["dash"]=true
        elif a.state=="idle" and a.y>.1 and a.air.chase_used and not chapter_seen.has("hit/air_jab"):attack["attack"]="light"
        elif a.state=="attack" and a.hit_confirmed and a.move in ["jab","cross","air_jab","air_kick"]:attack["attack"]="light"
        return inputs
    if kind in ["block","guard_break"]:defense["guard"]=true
    if kind in ["parry","kinetic"] and a.state=="attack" and a.frame>=s.MOVES[a.move].startup-2:
        defense["guard"]=true;defense["allow_parry"]=true
        defense["guard_pressed"]=a.frame==s.MOVES[a.move].startup-2
    if kind=="throw_tech" and a.state=="attack" and a.move=="grab" and a.frame==8:defense["attack"]="grab"
    if kind=="dodge" and a.state=="attack" and a.frame==s.MOVES[a.move].startup-3:
        defense["dash"]=true;defense["axis"]=-b.face
    if kind=="wall_tech" and b.state=="stun" and absf(b.vx)>6:defense["dash"]=true
    if kind.begins_with("air_counter") and s.can_air_parry(1-lead) and a.frame==s.MOVES[a.move].startup-3:defense["guard_pressed"]=true
    if not sent and age>=(1 if kind=="meteor" or kind.begins_with("air_counter") else 16):
        attack["attack"]="grab" if kind in ["grab","throw_tech"] else ("special" if kind in ["special","finale"] else ("light" if kind=="kinetic" or kind.begins_with("air_counter") else "heavy"))
        if kind=="meteor":attack["down"]=true
        sent=true
    return inputs
func duel_command(s: RefCounted, side: int) -> Dictionary:
    var f: Dictionary=s.fighters[side]
    var other: Dictionary=s.fighters[1-side]
    var distance: float=absf(other.x-f.x)
    var clock:=age+side*17
    var command:={"axis":signf(other.x-f.x) if distance>1.15 else 0.0,"allow_parry":true}
    if s.can_air_parry(side) and other.frame==s.MOVES[other.move].startup-3:command["guard_pressed"]=true
    if other.state=="attack" and f.y<=.01 and clock%3!=0 and other.frame>=s.MOVES[other.move].startup-3:
        command["guard"]=true;command["axis"]=0.0
        command["guard_pressed"]=other.frame==s.MOVES[other.move].startup-3
    if f.state=="stun" and (f.wall_tech_window>0 or absf(f.vx)>6):command["dash"]=true
    if f.air.chase_window>0 and not f.air.chase_used:command["dash"]=true
    elif f.state=="attack" and f.hit_confirmed and f.move in ["jab","cross","air_jab","air_kick"]:command["attack"]="light"
    elif f.state=="idle" and distance<2.3 and clock%18==0:
        command["attack"]="light" if f.y>.1 else (["light","heavy","special","grab"][(floori(clock/18.0))%4] if f.meter>=50 else "heavy")
        if command.attack=="heavy":command["up"]=clock%36==0
    if f.state=="idle" and f.y>.1 and clock%29==0:command["attack"]="heavy";command["down"]=true
    if f.state=="idle" and f.y<=.01 and clock%113==0:command["jump"]=true
    return command
func observe(s: RefCounted) -> void:
    for event in s.events:
        var label: String=event.kind
        if event.kind in ["hit","swing"]:label+="/"+str(event.get("move",""))
        seen[label]=seen.get(label,0)+1
        chapter_seen[label]=chapter_seen.get(label,0)+1
    if age>=limit() and not s.air_counter.active() and not s.exchange.active() and not s.rally.active() and (s.hitstop==0 or s.phase in ["round_over","match_over"]):next()
