extends RefCounted
## Tutorial objectives observe real Simulation events. Never edits fighters or awards XP.
const TITLES := ["LINK TWO HITS","PARRY THEN COUNTER","LAUNCH / CHASE / AIR HIT","LAND A PAID SUPER"]
const KEYS := ["A/D CLOSE IN / HOLD J TO LINK", "SHIFT ON WINDUP / THEN J", "K LAUNCH / E CHASE / J AIR HIT", "W + L / COSTS 75 ENERGY"]
const HINTS := ["Two hits in one real combo.","A parry alone is not a counter hit.","Chase costs 20. Stay close enough.","Startup is not success. Land the hit."]
var index:=0
var status:="ready"
var completed:Array=[false,false,false,false]
var elapsed:=0.0
var partner_clock:=0
var parried:=false
var launched:=false
var chased:=false
var paid:=false
var combo_max:=0
var feedback:=""
var watched_move:=""
var contacted:=false
func reset_attempt() -> void:
    status="ready";partner_clock=0;parried=false;launched=false;chased=false;paid=false;combo_max=0
    completed[index]=false;feedback="";watched_move="";contacted=false
func advance() -> bool:
    if status=="ready":status="running";return false
    if status!="passed":return false
    index+=1
    reset_attempt();status="running"
    return true
func pass_lesson() -> void:
    completed[index]=true
    status="complete" if index==3 else "passed"
    feedback="REAL CONTACT CONFIRMED"
func command(s:RefCounted) -> Dictionary:
    if status!="running" or index!=1:return {}
    if s.hitstop>0:return {}
    partner_clock+=1
    var f:Dictionary=s.fighters[1];var other:Dictionary=s.fighters[0]
    if f.state!="idle" or other.state=="stun":return {}
    var gap:float=other.x-f.x
    if absf(gap)>1.35:return {"axis":signf(gap)}
    # A slow, precommitted rhythm; no access to player pending or hidden choices.
    return {"attack":"heavy"} if partner_clock%150==90 else {}
func observe(s:RefCounted) -> void:
    if status!="running":return
    var counter_contact:=false
    for e in s.events:
        if e.kind=="counter_success" and e.target==0:counter_contact=true
    for e in s.events:
        if e.kind=="swing" and e.target==0:
            if watched_move!="" and not contacted:feedback="MISS / A-D CLOSE IN / F5 RETRY"
            watched_move=e.move;contacted=false
            if e.move=="overdrive":paid=s.fighters[0].meter<=25.0
        elif e.kind=="parry" and e.target==0:
            parried=true;feedback="PARRY CONFIRMED / J TO COUNTER"
        elif e.kind=="homing_chase" and e.target==0 and launched:
            chased=true;feedback="CHASE CONFIRMED / LAND J IN THE AIR"
        elif e.kind=="no_chase_meter" and e.target==0:feedback="CHASE NEEDS 20 / F5 RETRY"
        elif e.kind=="chase_unavailable" and e.target==0:feedback="CHASE MISSED / CHECK RANGE / F5 RETRY"
        elif e.kind=="no_meter" and e.target==0:feedback="NOT ENOUGH ENERGY / F5 RETRY"
        elif e.kind=="block" and e.attacker==0:
            contacted=true;feedback="BLOCKED / FIND AN OPENING"
        elif e.kind=="parry" and e.attacker==0:
            contacted=true;feedback="P2 PARRIED / F5 RETRY"
        elif e.kind=="hit":
            if e.attacker==0:
                contacted=true
                combo_max=maxi(combo_max,s.combo_hits if s.combo_owner==0 else 0)
                if index==0 and combo_max>=2:pass_lesson()
                elif index==1 and parried and counter_contact:pass_lesson()
                elif index==2:
                    if e.move=="launcher":launched=true;chased=false;feedback="LAUNCH CONFIRMED / E TO CHASE"
                    elif launched and chased and s.fighters[0].y>.1 and e.move in ["air_jab","air_kick","air_finisher","meteor"]:pass_lesson()
                elif index==3 and paid and e.move=="overdrive":pass_lesson()
            elif e.target==0:
                parried=false;launched=false;chased=false
                if s.fighters[0].state!="attack" or s.fighters[0].move!="overdrive":paid=false
                feedback="HIT TAKEN / RESET DISTANCE / F5 RETRY"
        elif e.kind=="air_land" and e.target==0 and index==2 and not completed[2]:
            launched=false;chased=false;feedback="LANDED / TRY K THEN E THEN J"
    if index==1 and parried and status=="running" and s.fighters[0].counter_window<=0 and not s.fighters[0].counter_attack:
        parried=false;feedback="COUNTER WINDOW CLOSED / READ NEXT WINDUP"
    if index==2 and launched and not chased and status=="running" and s.fighters[0].air.chase_window<=0 and s.hitstop<=0:
        launched=false;feedback="CHASE WINDOW CLOSED / K AGAIN OR F5"
    if watched_move!="" and s.fighters[0].state=="idle":
        if not contacted and status=="running":feedback="MISS / A-D CLOSE IN / F5 RETRY"
        watched_move=""
func cue(s:RefCounted) -> String:
    if status=="ready":return "ENTER TO BEGIN / F5 RETRY"
    if status=="passed":return "PASSED / ENTER NEXT / F5 RETRY"
    if status=="complete":return "4 / 4 COMPLETE / ENTER MAIN MENU"
    if index==1 and not parried:
        var rival:Dictionary=s.fighters[1]
        var player:Dictionary=s.fighters[0]
        if player.guarding and player.guard_frames>s.PARRY_WINDOW:
            return "RELEASE SHIFT / TAP ON NEXT WINDUP"
        var can_guard:bool=player.state=="idle" and player.y<=.01 and player.guard>=25 and player.parry_cd==0 and player.jump_buffer==0
        if rival.state=="attack" and can_guard and (rival.x-player.x)*player.face>0 and (player.x-rival.x)*rival.face>0 and absf(player.x-rival.x)<=s.move_for(rival,rival.move).reach:
            var startup:int=s.move_for(rival,rival.move).startup
            if rival.frame<startup and rival.frame>=startup-s.PARRY_WINDOW:
                return "P2 WINDUP / SHIFT NOW"
        return "WATCH P2 / WAIT FOR THE WINDUP"
    if feedback!="":return feedback
    return HINTS[index]
