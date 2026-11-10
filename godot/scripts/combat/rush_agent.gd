extends RefCounted
## Live state policy. Chooses legal inputs, never moves actors or edits damage.
var last_burst:=[0,-120]
var last_cannon:=[-600,-600]
var cannon_primed:=[false,false]
func choose(s: RefCounted, side: int, clock: int, level:=2, showcase:=false) -> Dictionary:
    var f: Dictionary=s.fighters[side]
    var other: Dictionary=s.fighters[1-side]
    if s.combo_owner==side and s.combo_hits>=5 and f.state=="attack" and f.move in ["air_kick","meteor"]:cannon_primed[side]=true
    var dx: float=other.x-f.x
    var distance:=absf(dx)
    var command:={"axis":signf(dx) if distance>1.12 else 0.0,"allow_parry":true}
    if s.hitstop>0:
        if f.hit_confirmed:command["rush"]=true
        return command
    if s.air_counter.active():
        if s.air_counter.owner==side and s.air_counter.phase=="hold":
            command["air_choice"]="escape" if (floori(clock/7.0)+side)%7==0 else "kick"
        elif s.air_counter.owner!=side and s.air_counter.phase=="windup" and s.air_counter.age==5 and (clock+side)%3==0:command["dash"]=true;command["axis"]=-f.face
        return command
    if s.can_air_parry(side) and other.frame==s.move_for(other,other.move).startup-4 and (clock+side*7)%4<(2 if showcase else level):command["guard_pressed"]=true
    if f.state=="stun":
        if f.wall_tech_window>0:command["dash"]=true
        return command
    if f.air.chase_window>0 and not f.air.chase_used and other.state=="stun":
        command["rush"]=true
        return command
    if f.state=="attack":
        if s.last_service_enabled and f.character==3 and f.move=="special" and f.frame>=14 and _loop_ready(f,other):command["attack"]="node_pulse"
        if s.last_service_enabled and f.character==1 and f.move=="special":command["skill_held"]=f.service.preload_age<30
        if f.hit_confirmed and f.move in ["jab","cross","air_jab","air_kick"]:command["rush"]=true
        return command
    if f.state not in ["idle","landing"]:return command
    if f.y>.1:
        if other.y>.1 and absf(other.y-f.y)<1.6 and distance<2.0:command["rush"]=true
        elif f.air.phase=="fall":command["down_pressed"]=true
        return command
    if other.move=="grab" and other.state=="attack" and other.frame==7 and distance<1.4:command["dash"]=true;command["axis"]=-f.face;return command
    if (showcase or level>=2 or other.move not in ["special","overdrive"]) and other.state=="attack" and other.frame==s.move_for(other,other.move).startup-4 and distance<2.4 and (clock+side*13)%7<(2 if showcase else level):
        command["guard"]=true;command["guard_pressed"]=true;command["axis"]=0.0
        return command
    if f.counter_window>0:command["rush"]=true;return command
    if s.last_service_enabled and f.character==2 and distance>1.8 and distance<3.2:
        # HUSH holds intercept distance instead of endlessly chasing into melee.
        command["axis"]=signf(dx) if distance>2.25 else 0.0
        if f.meter>=50 and distance<2.6 and clock-last_burst[side]>240:
            command["attack"]="special";last_burst[side]=clock
        return command
    if s.last_service_enabled and f.character==3 and other.y<1.45:
        var nodes:Array=f.service.nodes
        if _loop_ready(f,other):command["attack"]="node_pulse";return command
        if distance<1.6 and other.state=="attack" and f.dash_cd==0 and nodes.is_empty():
            command["dash"]=true;command["axis"]=-f.face;return command
        if nodes.size()<2 and f.meter>=20 and distance>2.6 and distance<6 and clock-last_burst[side]>100:
            command["attack"]="special";command["axis"]=signf(dx) if nodes.is_empty() else 0.0;last_burst[side]=clock
            return command
    if showcase and f.meter>=50 and distance<3.25 and absf(other.y-f.y)<1.3 and clock-last_burst[side]>=300:
        var charged:bool=f.meter>=75 and cannon_primed[side] and clock-last_cannon[side]>=600
        command["attack"]="overdrive" if charged else "special";last_burst[side]=clock
        if charged:last_cannon[side]=clock;cannon_primed[side]=false
        return command
    if s.last_service_enabled and f.character==3 and not f.service.nodes.is_empty() and f.service.node_cd==0 and other.y<1.3:
        for node in f.service.nodes:
            if absf(node.x-other.x)<1.0:command["attack"]="node_pulse";return command
    if distance>3.0 and f.dash_cd==0:command["dash"]=true;return command
    var beat: int=3 if showcase else [12,8,4][clampi(level,0,2)]
    if distance<1.7 and (clock+side*11)%beat==0:
        var style:=posmod(floori(float(clock+side*29)/97.0),5)
        if style==3 and f.meter>=50:command["attack"]="special"
        elif style in [1,4]:command["attack"]="launcher"
        else:command["rush"]=true
    return command

func _loop_ready(f:Dictionary,other:Dictionary) -> bool:
    var nodes:Array=f.service.nodes
    if nodes.is_empty() or f.service.node_cd>0 or f.meter<10:return false
    var x:float=other.x+other.vx*.12
    if other.y+other.vy*.12>1.45:return false
    return x>=minf(nodes[0].x,nodes[-1].x)-.75 and x<=maxf(nodes[0].x,nodes[-1].x)+.75
