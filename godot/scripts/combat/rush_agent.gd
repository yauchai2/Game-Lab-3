extends RefCounted
## Public-state policy with committed neutral decisions. No pending input or direct state edits.
var last_burst:=[-300,-300]
var last_cannon:=[-600,-600]
var cannon_primed:=[false,false]
var plans:Array=[{},{}]
var plan_until:=[0,0]
var issued:=[false,false]
var last_clock:=[-1,-1]
var intent:=["approach","approach"]
func reset() -> void:
    for side in 2:_reset_side(side)
func _reset_side(side:int) -> void:
    plans[side]={};plan_until[side]=0;issued[side]=false;last_clock[side]=-1
    last_burst[side]=-300;last_cannon[side]=-600;cannon_primed[side]=false;intent[side]="approach"
func choose(s:RefCounted,side:int,clock:int,level:=2,showcase:=false) -> Dictionary:
    level=clampi(level,0,2)
    if clock<last_clock[side]:_reset_side(side)
    last_clock[side]=clock
    var f:Dictionary=s.fighters[side];var other:Dictionary=s.fighters[1-side]
    var dx:float=other.x-f.x;var distance:float=absf(dx)
    var command:Dictionary={"axis":signf(dx) if distance>1.12 else 0.0,"allow_parry":level>0}
    if s.combo_owner==side and s.combo_hits>=4 and f.state=="attack" and f.move in ["air_kick","meteor"]:cannon_primed[side]=true
    if s.hitstop>0:
        if plans[side].get("guard",false):command["guard"]=true;command["axis"]=0.0
        if f.hit_confirmed:command["rush"]=true
        return command
    if s.air_counter.active():
        if s.air_counter.owner==side and s.air_counter.phase=="hold":command["air_choice"]="escape" if (s.air_counter.serial+side)%4==0 else "kick"
        elif s.air_counter.owner!=side and s.air_counter.phase=="windup" and s.air_counter.age==5 and (clock+side)%3==0:command["dash"]=true;command["axis"]=-f.face
        return command
    # Sample the published windup at a bounded reaction cadence, not an exact-frame oracle.
    var reaction:int=[18,12,8][level]
    if level>0 and clock%reaction==(side*3)%reaction and s.can_air_parry(side) and other.frame>=s.move_for(other,other.move).startup-s.air_counter.PARRY_WINDOW and other.frame<s.move_for(other,other.move).startup:
        command["guard_pressed"]=true
    if f.state=="blockstun":
        if plans[side].get("guard",false):command["guard"]=true;command["axis"]=0.0
        return command
    if f.state=="stun":
        if f.wall_tech_window>0 and level>0 and (not s.ArenaBox.active(f) or f.wall_tech_window<=8):command["dash"]=true
        return command
    if f.air.chase_window>0 and not f.air.chase_used and other.state=="stun" and f.meter>=s.AirMotion.CHASE_COST:
        command["rush"]=true
        return command
    if f.state=="attack":
        if s.last_service_enabled and f.character==3 and f.move=="special" and f.frame>=14 and _loop_ready(s,f,other):command["attack"]="node_pulse"
        if s.last_service_enabled and f.character==1 and f.move=="special":command["skill_held"]=f.service.preload_age<30
        if f.hit_confirmed and f.move in ["jab","cross","air_jab","air_kick"]:command["rush"]=true
        return command
    if f.state not in ["idle","landing"]:return command
    if f.y>.1:
        if other.y>.1 and absf(other.y-f.y)<1.6 and distance<s.move_for(f,"air_jab").reach:command["rush"]=true
        elif f.air.phase=="fall":command["down_pressed"]=true
        return command
    if f.counter_window>0:
        intent[side]="counter";plans[side]={};command["rush"]=true
        return command
    if plans[side].is_empty() or clock>=plan_until[side]:
        plans[side]=_plan(s,side,clock,level,showcase)
        plan_until[side]=clock+[20,14,9][level]
        issued[side]=false
    var planned:Dictionary=plans[side].duplicate()
    # Attack/dash/jump are one-shot commitments; movement and guard last for the plan.
    if issued[side]:
        for key in ["attack","dash","jump"]:planned.erase(key)
    issued[side]=true
    command.merge(planned,true)
    return command
func _plan(s:RefCounted,side:int,clock:int,level:int,showcase:bool) -> Dictionary:
    var f:Dictionary=s.fighters[side];var other:Dictionary=s.fighters[1-side]
    var dx:float=other.x-f.x;var distance:float=absf(dx)
    var character:int=f.character if s.last_service_enabled else 0
    var style:int=posmod(floori(float(clock+side*37)/[72,54,42][level])+character,5)
    var jab:Dictionary=s.move_for(f,"jab")
    var attacking:bool=other.state=="attack"
    var enemy_move:Dictionary=s.move_for(other,other.move) if attacking else {}
    # Real throws threaten held guard; walk into the original throw range first.
    if other.guarding and other.y<=.01 and other.guard_frames>=[18,12,6][level]:
        if distance<=s.move_for(f,"grab").reach-.05 and other.state=="idle" and f.throw_cd==0:
            intent[side]="throw_guard";return {"attack":"grab","axis":0.0}
        if distance>1.0:
            intent[side]="close_guard";return {"axis":signf(dx)}
    if level>0 and f.guard<45 and attacking and distance<2.6 and f.dash_cd==0:
        intent[side]="recover_guard";return {"dash":true,"axis":-float(f.face)}
    if attacking and other.move=="grab" and distance<1.5 and level>0:
        intent[side]="evade_throw"
        return {"dash":true,"axis":-float(f.face)} if f.dash_cd==0 else {"jump":true,"axis":-float(f.face)}
    if attacking and not other.connected and other.frame>=enemy_move.startup+enemy_move.active and distance<=jab.reach+.1:
        intent[side]="punish_recovery";return {"attack":"light","axis":signf(dx)}
    if attacking and other.frame<enemy_move.startup and distance<=enemy_move.reach+.2 and other.move!="grab" and f.guard>25 and ((level==2 and not showcase) or posmod(floori(clock/8.0)+side+character,4)<=level):
        intent[side]="read_guard";return {"guard":true,"axis":0.0}
    if s.last_service_enabled and character==3 and other.y<1.45:
        if _loop_ready(s,f,other):intent[side]="pulse";return {"attack":"node_pulse","axis":0.0}
        if f.service.nodes.size()<2 and f.meter>=s.skill_cost(f,"special") and distance>2.2 and distance<5.5 and clock-last_burst[side]>=100:
            intent[side]="place_node";last_burst[side]=clock
            return {"attack":"special","axis":signf(dx) if f.service.nodes.is_empty() else 0.0}
        if distance<1.2 and f.dash_cd==0 and not f.service.nodes.is_empty() and style==2:
            intent[side]="defend_nodes";return {"dash":true,"axis":-float(f.face)}
    var opportunity:bool=other.state in ["stun","blockstun"] or (attacking and other.frame>=enemy_move.startup+enemy_move.active)
    var super_move:Dictionary=s.move_for(f,"overdrive")
    if f.meter>=s.skill_cost(f,"overdrive") and clock-last_cannon[side]>=[600,480,360][level] and clock-last_burst[side]>=140 and distance<=super_move.reach-.15 and absf(other.y-f.y)<1.2 and (opportunity or cannon_primed[side] or (showcase and style==4)):
        intent[side]="super";last_cannon[side]=clock;last_burst[side]=clock;cannon_primed[side]=false
        return {"attack":"overdrive","axis":0.0}
    var special:Dictionary=s.move_for(f,"special")
    if character!=3 and f.meter>=s.skill_cost(f,"special") and clock-last_burst[side]>=[330,240,180][level] and distance<=special.reach-.15 and absf(other.y-f.y)<1.2 and (style==3 or opportunity or (character==2 and distance>1.7)):
        intent[side]="signature";last_burst[side]=clock
        return {"attack":"special","axis":0.0}
    # HUSH only keeps intercept distance when SAMPLE/energy can pay for that threat.
    # LOOP without a funded node/pulse falls back to melee instead of waiting forever.
    var desired:float=2.05 if character==2 and f.meter>=s.skill_cost(f,"special") and clock-last_burst[side]>=180 else (2.6 if character==3 and f.meter>=s.skill_cost(f,"special") and f.service.nodes.is_empty() else 1.08)
    if distance>desired+.12:
        intent[side]="approach"
        if distance>3.4 and f.dash_cd==0:return {"dash":true,"axis":signf(dx)}
        return {"axis":signf(dx)}
    if distance<=jab.reach-.05:
        if other.guarding and f.throw_cd>0 and distance<=s.move_for(f,"heavy").reach:
            intent[side]="guard_pressure";return {"attack":"heavy"}
        var name:String="launcher" if style in [1,4] and distance<=s.move_for(f,"launcher").reach-.1 else ("heavy" if style==2 and level>0 else "light")
        intent[side]="launch" if name=="launcher" else "pressure"
        return {"attack":name,"axis":0.0}
    intent[side]="close_melee"
    return {"axis":signf(dx)}
func _loop_ready(s:RefCounted,f:Dictionary,other:Dictionary) -> bool:
    var nodes:Array=f.service.nodes
    if nodes.is_empty() or f.service.node_cd>0 or f.meter<s.skill_cost(f,"node_pulse"):return false
    var x:float=other.x+other.vx*.12
    if other.y+other.vy*.12>1.45:return false
    return x>=minf(nodes[0].x,nodes[-1].x)-.75 and x<=maxf(nodes[0].x,nodes[-1].x)+.75
