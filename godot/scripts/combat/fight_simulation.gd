extends RefCounted
## Deterministic 60 Hz gameplay. Presentation uses a separate, unfrozen clock.
const PARRY_WINDOW := 12
const COUNTER_WINDOW := 36
const INPUT_BUFFER := 14
const STEP := 1.0 / 60.0
const EDGE := 8.2
const ArenaBox=preload("res://scripts/combat/arena_box.gd")
const MAX_HEALTH := 100
const ROUND_SECONDS := 75.0
const Profiles=preload("res://scripts/combat/fighter_profiles.gd")
var character_choices := [0,0]
var last_service_enabled:=false
var service_perks:Array=[[],[]]
var service_contacts:Array=[]
const ServiceProfiles=preload("res://scripts/combat/last_service/profiles.gd")
var service_rules=preload("res://scripts/combat/last_service/rules.gd").new()
func profile_for(index:int) -> Dictionary:
    return ServiceProfiles.profile(index) if last_service_enabled else Profiles.profile(index)

const AirMotion=preload("res://scripts/combat/aerial_motion.gd")
var air_motion:=AirMotion.new()
var air_counter=preload("res://scripts/combat/air_counter.gd").new()
var air_lesson_stage:=""
var air_lesson_ticks:=0
var arcade_enabled:=false
var endless:=false
var rush_agent=preload("res://scripts/combat/rush_agent.gd").new()
var practice_scenario:="free"
const MOVES := {
    "node_pulse":{"startup":8,"active":1,"recovery":32,"damage":12,"reach":0.0,"stun":18,"push":5.0,"lift":2.0,"stop":7},
    "air_counter":{"startup":14,"active":4,"recovery":22,"damage":18,"reach":2.3,"stun":28,"push":7.0,"lift":-10.0,"stop":10},
    "air_jab":{"startup":6,"active":3,"recovery":12,"damage":6,"reach":1.7,"stun":22,"push":1.2,"lift":1.0,"stop":4},
    "air_kick":{"startup":8,"active":3,"recovery":16,"damage":8,"reach":2.0,"stun":25,"push":1.8,"lift":1.0,"stop":5},
    "air_finisher":{"startup":12,"active":4,"recovery":22,"damage":12,"reach":2.2,"stun":28,"push":8.0,"lift":2.0,"stop":8},
    "meteor":{"startup":14,"active":4,"recovery":22,"damage":14,"reach":2.1,"stun":30,"push":2.0,"lift":-16.0,"stop":9},
    "grab": {"startup":11,"active":3,"recovery":25,"damage":12,"reach":1.15,"stun":24,"push":8.0,"lift":5.0,"stop":9},
    "jab": {"startup": 5, "active": 5, "recovery": 13, "damage": 7, "reach": 1.65, "stun": 18, "push": 3.0, "lift": 0.0, "stop": 5},
    "cross": {"startup": 6, "active": 5, "recovery": 15, "damage": 9, "reach": 1.85, "stun": 21, "push": 4.0, "lift": 0.0, "stop": 6},
    "finisher": {"startup": 9, "active": 6, "recovery": 23, "damage": 13, "reach": 2.1, "stun": 28, "push": 9.0, "lift": 3.8, "stop": 9},
    "heavy": {"startup": 16, "active": 7, "recovery": 26, "damage": 18, "reach": 2.25, "stun": 32, "push": 10.0, "lift": 2.5, "stop": 11},
    "launcher": {"startup": 13, "active": 7, "recovery": 27, "damage": 14, "reach": 1.8, "stun": 39, "push": 3.0, "lift": 10.0, "stop": 10},
    "overdrive": {"startup":30,"active":8,"recovery":42,"damage":38,"reach":3.8,"stun":48,"push":18.0,"lift":7.0,"stop":26},
    "special": {"startup": 18, "active": 10, "recovery": 31, "damage": 27, "reach": 3.4, "stun": 40, "push": 14.0, "lift": 5.0, "stop": 17}
}
var rally = preload("res://scripts/combat/kinetic_rally.gd").new()
var rally_enabled := false
var rally_drill := false
var guard_was_down := [false,false]
var continuation=preload("res://scripts/combat/continuation_buffer.gd").new()
var exchange = preload("res://scripts/combat/pressure_exchange.gd").new()
var fighters: Array[Dictionary] = []
var events: Array[Dictionary] = []
var phase := "ready"
var countdown := 72
var remaining := ROUND_SECONDS
var hitstop := 0
var hitstop_total := 1
var wins := [0, 0]
var winner := -1
var round_number := 1
var tick_count := 0
var ai_enabled := true
var combo_hits := 0
var combo_owner := -1
var combo_damage := 0
var ai_tick := 0
var difficulty := 1
var training := false
var surge_lab_enabled:=false
var surge_lab_fixture:=false
var surge_release:Array=[]
var surge_guards:Array=[0,0]
var pressure_drill := false
var partner_mode := 0 # 0 standing, 1 guard, 2 sparring
var training_rest := 0
var last_combo_hits := 0
var last_combo_damage := 0

func _init() -> void:
    reset_round()

func reset_round() -> void:
    rush_agent.reset()
    surge_lab_enabled=false;surge_lab_fixture=false;surge_release.clear();surge_guards=[0,0]
    exchange.reset()
    continuation.clear()
    practice_scenario="free"
    air_counter.reset()
    air_lesson_stage=""
    air_lesson_ticks=0
    rally.reset()
    rally_enabled=false
    rally_drill=false
    guard_was_down=[false,false]
    pressure_drill=false
    service_contacts.clear()
    fighters.clear()
    for i in 2:
        fighters.append({"x": -3.0 if i == 0 else 3.0, "y": 0.0, "vx": 0.0, "vy": 0.0,
            "character":character_choices[i],"air":AirMotion.fresh(),"ricochet":ArenaBox.fresh(), "face": 1 if i == 0 else -1, "health": MAX_HEALTH, "meter": 0.0, "guard": 100.0,
            "state": "idle", "move": "", "frame": 0, "stun": 0, "connected": false,
            "buffer": "", "buffer_ttl": 0, "chain": 0, "chain_ttl": 0, "dash_cd": 0,
            "invuln": 0, "flash": 0, "guarding": false, "guard_frames": 0, "parry_cd": 0, "parry_allowed": true, "entry_parry_window":0, "counter_window":0, "counter_attack":false, "break_lock":0, "impact_load":0.0, "jump_buffer":0, "juggle":0, "hit_confirmed":false,"throw_cd":0,"tech_window":0,"wall_bounces":0,"wall_tech_window":0,"wall_tech_buffer":0})
    for i in 2:
        fighters[i]["service"]=service_rules.fresh()
        fighters[i]["perks"]=service_perks[i].duplicate()
    phase = "ready"
    countdown = 72
    remaining = ROUND_SECONDS
    hitstop = 0
    winner = -1
    combo_hits = 0
    combo_damage = 0
    combo_owner = -1
    events.clear()
    ai_tick = 0
    training_rest = 0
    last_combo_hits = 0
    last_combo_damage = 0
    if training:
        for fighter in fighters: fighter.meter = 100.0
        if arcade_enabled:
            fighters[0].x=-.7;fighters[1].x=.7
    elif arcade_enabled:
        countdown=36
        for i in 2:
            fighters[i].x=-1.6 if i==0 else 1.6
            fighters[i].meter=60.0

func restart_match() -> void:
    wins = [0, 0]
    round_number = 1
    reset_round()

func next_round() -> void:
    if phase == "round_over":
        round_number += 1
        reset_round()

func ai_command() -> Dictionary:
    if arcade_enabled:return rush_agent.choose(self,1,ai_tick,difficulty)
    var a: Dictionary = fighters[1]
    var b: Dictionary = fighters[0]
    var distance: float = absf(a.x - b.x)
    var desired_distance := .95 if b.guarding and a.throw_cd==0 else 1.45
    var command := {"axis": signf(b.x - a.x) if distance > desired_distance else 0.0, "allow_parry":false}
    # Deliberate reaction windows and punishable heavy attacks, not perfect reads.
    var level := clampi(difficulty,0,2)
    var reaction_period: int = [36,22,14][level]
    var attack_period: int = [40,25,18][level]
    if ai_tick % reaction_period < [4,12,8][level] and b.state == "attack" and distance < 2.8:
        if b.move=="grab" and b.frame>=4 and a.dash_cd==0:
            command["dash"]=true
            command["axis"]=-signf(b.x-a.x)
        else:
            command["guard"] = true
            command["axis"] = 0.0
    if ai_tick % attack_period == 0 and distance < 2.5:
        command["attack"] = "grab" if b.guarding and distance<1.15 and a.throw_cd==0 else ("special" if a.meter >= 50 and ai_tick % 100 == 0 else ("heavy" if ai_tick % 75 == 0 else "light"))
    if a.wall_tech_window>0 and a.wall_tech_window<=(6 if level==1 else 9) and a.meter>=20 and level>0:command["dash"]=true
    if b.y > 1.0 and ai_tick % [72,48,36][level] == 0:
        command["jump"] = true
    if is_aerial() and level>0 and not a.air.parry_used and b.move in ["air_finisher","meteor"] and b.state=="attack" and b.frame==move_for(b,b.move).startup-5 and (ai_tick+round_number)%3<level:
        command["guard_pressed"]=true
    return command

func tick(player: Dictionary = {}, opponent: Dictionary = {}) -> void:
    events.clear()
    service_contacts.clear()
    tick_count += 1
    if phase == "ready":
        countdown -= 1
        if countdown <= 0:
            phase = "fight"
            events.append({"kind": "fight"})
        return
    if phase != "fight":
        exchange.cancel_decision();surge_release.clear()
        return
    if exchange.decision_active():
        _tick_surge_decision([player,opponent])
        return
    if is_air_lesson():
        if air_lesson_stage in ["read","review"] and player.get("lesson_start",false):
            if air_lesson_stage=="review":
                configure_air_lesson()
                events.append({"kind":"air_lesson_reset"})
            air_lesson_stage="attack"
            air_lesson_ticks=0
            _start_attack(1,"air_finisher")
            events.append({"kind":"air_lesson_start"})
            return
        if air_lesson_stage=="read":
            guard_was_down[0]=player.get("guard",false)
            return
        air_lesson_ticks+=1
        if air_lesson_stage=="attack" and not air_counter.active() and air_lesson_ticks>42 and fighters[1].state=="idle":air_lesson_stage="review"
    var partner: Dictionary = ai_command() if ai_enabled else opponent
    if training:
        if partner_mode==1: partner={"guard":true,"allow_parry":false}
        elif partner_mode==2: partner=ai_command()
    if training and pressure_drill:partner={}
    if training and rally_drill:
        partner={}
        if not rally.active():
            var rival: Dictionary=fighters[1]
            partner={"axis":signf(fighters[0].x-rival.x) if absf(fighters[0].x-rival.x)>1.4 else 0.0,"allow_parry":false}
            if ai_tick%100==60:partner["attack"]="light"
        elif rally.owner==1 and rally.phase=="compress" and rally.age>=2:
            partner={"attack":"light"}
        elif rally.owner==0 and rally.phase=="windup":
            # Precommitted teaching partner: first three returns, then a visible miss.
            var aim: int=rally.WINDUP-2 if rally.tier<4 else rally.WINDUP+5
            partner={"guard":rally.age>=aim,"guard_pressed":rally.age==aim}
    if is_air_lesson():partner=opponent if not opponent.is_empty() else {}
    if surge_lab_fixture and training:partner=surge_partner_command()
    var commands := [player.duplicate(),partner.duplicate()]
    var releasing_surge:bool=not surge_release.is_empty()
    if releasing_surge:
        commands=surge_release.duplicate(true);surge_release.clear()
    if not releasing_surge and _try_surge_decision(commands):return
    for side in 2:
        if surge_guards[side]>0:
            if fighters[side].state in ["stun","ko"]:surge_guards[side]=0
            else:
                commands[side]["guard"]=true;commands[side]["axis"]=0.0
                if hitstop<=0:surge_guards[side]-=1
    if arcade_enabled:
        for side in 2:
            var choice:String="dash" if commands[side].get("dash",false) else commands[side].get("attack","")
            if continuation.offer(side,choice):
                commands[side].erase("attack");commands[side].erase("dash")
            var queued:Dictionary=continuation.command(side,hitstop>0,fighters[side].state not in ["stun","blockstun"])
            if not queued.is_empty():
                if queued.get("dash",false) and fighters[side].air.chase_window<=0:queued["axis"]=-float(fighters[side].face)
                if queued.has("attack") and queued.attack=="heavy":
                    queued["up"]=fighters[side].y<=.1;queued["down"]=fighters[side].y>.1
                commands[side].merge(queued,true)
            # Held rush is normal chaining, never a fresh continuation decision.
            if not continuation.slots[side].is_empty() and continuation.slots[side].choice!="" and not continuation.slots[side].spent:commands[side].erase("rush")
    if arcade_enabled:
        for i in 2:
            var f: Dictionary=fighters[i]
            if commands[i].get("rush",false) and not commands[i].has("attack") and not (f.buffer_ttl>0 and f.buffer in ["special","overdrive","launcher","heavy","meteor","grab"]):commands[i]["attack"]="light"
            if commands[i].get("attack","")=="light" and f.air.chase_window>0 and not f.air.chase_used and fighters[1-i].state=="stun":commands[i]["dash"]=true
    if is_air_lesson() and air_lesson_stage=="attack" and not air_counter.active():commands[0].erase("attack")
    if is_aerial() and not air_counter.active():
        _advance_air_limits()
        for side in 2:
            var air: Dictionary=fighters[side].air
            if commands[side].get("down_pressed",false) and fighters[side].state in ["idle","dash"]:air.drop_buffer=6
            if commands[side].get("dash",false) and air.chase_window>0:air.chase_buffer=8
    for side in 2:
        var down: bool=commands[side].get("guard",false)
        if not commands[side].has("guard_pressed"):
            commands[side]["guard_pressed"]=down and not guard_was_down[side]
        guard_was_down[side]=down
    if is_aerial():
        if air_counter.active():
            _tick_air_counter(commands)
            _update_training()
            return
        _air_parry_inputs(commands)
    if rally.active():
        _tick_rally(commands)
        if training:_update_training()
        return
    if exchange.active():
        var automated: bool=ai_enabled or training
        if exchange.tick(commands,automated,8+clampi(difficulty,0,2)*3):
            _resolve_exchange()
            if training:_update_training()
            elif fighters[0].health<=0 or fighters[1].health<=0:_finish_round()
        return
    for i in 2:
        if last_service_enabled:service_rules.before(self,i,commands[i])
        var f: Dictionary = fighters[i]
        f.flash = maxi(0, f.flash - 1)
        if commands[i].get("jump",false): f.jump_buffer=8
        if commands[i].get("dash",false) and f.state=="stun":f.wall_tech_buffer=8
        if commands[i].has("attack"):
            f.buffer = "meteor" if is_aerial() and fighters[i].y>.01 and commands[i].attack=="heavy" and commands[i].get("down",false) else ("launcher" if commands[i].attack == "heavy" and commands[i].get("up", false) else commands[i].attack)
            f.buffer_ttl = INPUT_BUFFER
            if commands[i].attack=="grab":f.tech_window=7
    if hitstop > 0:
        hitstop -= 1
        return
    if pressure_drill:exchange.quiet_ticks=0
    exchange.advance_idle(absf(fighters[0].x-fighters[1].x)>3.8)
    ai_tick += 1
    if not training: remaining = maxf(0.0, remaining - STEP)
    for i in 2:
        _advance_fighter(i, commands[i])
    _separate_bodies()
    if last_service_enabled:service_rules.advance(self)
    # Resolve simultaneous active attacks from the same frame; trades are allowed.
    var contacts: Array[int] = []
    for i in 2:
        if _can_hit(i):
            contacts.append(i)
    # Node contacts share the ordinary simultaneous-contact snapshot.
    for contact in service_contacts:service_rules.resolve_pulse(self,contact.owner,contact.origin)
    service_contacts.clear()
    # Ordinary strikes interrupt a simultaneous throw on either player side.
    if contacts.size()==2 and fighters[contacts[0]].move=="grab" and fighters[contacts[1]].move!="grab":contacts.reverse()
    # Decide a clash from the simultaneous contact snapshot, before either hit
    # can stun the other participant or raise pressure within this same frame.
    var exchange_contact := -1
    for i in contacts:
        if _can_open_exchange(i):
            exchange_contact=i
            break
    if exchange_contact>=0:
        _resolve_hit(exchange_contact)
    else:
        for i in contacts:_resolve_hit(i,false)
    if last_service_enabled:
        for event in events.duplicate():service_rules.observe(self,event)
    if arcade_enabled:
        for event in events:
            if event.kind=="hit":
                continuation.cancel(event.target)
                if event.move=="launcher":continuation.open(event.attacker)
            elif event.kind=="parry":
                continuation.cancel(event.attacker)
                continuation.open(event.target)
            elif event.kind=="block":continuation.open(event.target)
            elif event.kind in ["guard_break","air_counter_start"]:continuation.cancel(event.get("target",event.get("owner",0)))
    if training:
        _update_training()
        return
    if fighters[0].health <= 0 or fighters[1].health <= 0 or remaining <= 0:
        _finish_round()

func _advance_fighter(i: int, command: Dictionary) -> void:
    var f: Dictionary = fighters[i]
    var other: Dictionary = fighters[1-i]
    f.parry_allowed = command.get("allow_parry",true)
    f.break_lock=maxi(0,f.break_lock-1)
    f.counter_window=maxi(0,f.counter_window-1)
    f.entry_parry_window=PARRY_WINDOW if command.get("guard_pressed",false) else maxi(0,f.entry_parry_window-1)
    var was_guarding: bool = f.guarding
    f.throw_cd=maxi(0,f.throw_cd-1)
    f.tech_window=maxi(0,f.tech_window-1)
    if f.state=="stun" and f.wall_tech_window>0 and f.wall_tech_buffer>0 and f.meter>=20:
        _wall_tech(i)
    f.wall_tech_window=maxi(0,f.wall_tech_window-1)
    f.wall_tech_buffer=maxi(0,f.wall_tech_buffer-1)
    if f.state=="idle" and f.y<=.01:
        f.wall_bounces=0;f.ricochet=ArenaBox.fresh()
    if ArenaBox.active(f) and f.state!="stun":f.ricochet.ticks=0
    if ArenaBox.active(f):f.stun=maxi(f.stun,2)
    f.parry_cd = maxi(0,f.parry_cd-1)
    f.dash_cd = maxi(0, f.dash_cd - 1)
    f.invuln = maxi(0, f.invuln - 1)
    f.chain_ttl = maxi(0, f.chain_ttl - 1)
    if f.chain_ttl == 0:
        f.chain = 0
    f.guarding = false
    if is_aerial():
        if f.air.chase_buffer>0 and f.air.chase_window>0 and f.state in ["idle","attack"]:
            command=command.duplicate()
            command["dash"]=false
            var outcome: String=air_motion.start_chase(f,other,EDGE)
            f.air.chase_buffer=0
            if outcome=="started":events.append({"kind":"homing_chase","target":i,"cost":AirMotion.CHASE_COST})
            elif outcome=="no_meter":events.append({"kind":"no_chase_meter","target":i})
            else:events.append({"kind":"chase_unavailable","target":i})
        if f.state=="landing" and f.air.land<=0:f.state="idle"
    if f.state in ["stun", "blockstun"]:
        if f.state == "blockstun":
            f.guarding = (command.get("guard", false) or (f.entry_parry_window>0 and f.parry_allowed and f.parry_cd==0 and f.jump_buffer<=0)) and f.y <= 0.01 and f.guard > 0
        f.stun -= 1
        if f.stun <= 0:
            f.state = "idle"
    elif f.state == "attack":
        f.frame += 1
        var move: Dictionary = move_for(f,f.move)
        var end: int = move.startup + move.active + (maxi(8,roundi(move.recovery*.55)) if arcade_enabled else move.recovery)
        if last_service_enabled and f.character==3 and f.move=="special" and f.frame>=move.startup+move.active and f.buffer=="node_pulse" and f.buffer_ttl>0 and not f.service.nodes.is_empty():
            _start_attack(i,"node_pulse")
        # Confirm a grounded launcher, then buffer Space during its hitstop to chase.
        if f.hit_confirmed and f.move=="launcher" and f.jump_buffer>0 and f.y<=0.01:
            f.state = "idle"
            if is_aerial():air_motion.request_jump(f)
            else:
                f.vy = 10.3
                f.jump_buffer = 0
                events.append({"kind":"jump","target":i})
            events.append({"kind":"air_chase","target":i})
        # Confirmed light attacks cancel into the next light during recovery.
        if arcade_enabled and f.hit_confirmed and f.buffer_ttl>0 and f.buffer in ["special","overdrive","launcher","meteor"] and f.frame>=move.startup+move.active:
            _start_attack(i,f.buffer)
        elif f.hit_confirmed and f.move in ["air_jab","air_kick"] and f.frame>=move.startup+move.active and f.buffer=="light" and f.buffer_ttl>0:
            _start_attack(i,"light")
        elif f.connected and f.move in ["jab", "cross"] and f.frame >= move.startup + move.active and f.buffer == "light" and f.buffer_ttl > 0:
            _start_attack(i, "light")
        elif f.frame >= end:
            f.state = "idle"
    elif f.state == "dash":
        f.frame += 1
        if f.frame >= 14:
            f.state = "idle"
    if f.state == "idle":
        f.face = 1 if other.x >= f.x else -1
        if command.get("dash", false) and f.dash_cd == 0:
            f.state = "dash"
            f.frame = 0
            f.invuln = 7
            f.dash_cd = 42
            f.vx = (signf(command.get("axis", 0.0)) if absf(command.get("axis", 0.0)) > 0.1 else float(f.face)) * 14.0 * profile_for(f.get("character",0)).speed*(1.1 if f.get("draw_core","")=="speed" else 1.0)
            events.append({"kind": "dash", "target": i})
        else:
            f.guarding = (command.get("guard", false) or (f.entry_parry_window>0 and f.parry_allowed and f.parry_cd==0 and f.jump_buffer<=0)) and f.y <= 0.01 and f.guard > 0
            f.vx = float(command.get("axis", 0.0)) * (1.6 if f.guarding else (8.0 if arcade_enabled else 5.8))*profile_for(f.get("character",0)).speed*(1.2 if f.get("draw_core","")=="speed" else 1.0)
            if f.jump_buffer>0 and f.y <= 0.01 and not f.guarding:
                if is_aerial():air_motion.request_jump(f)
                else:
                    f.vy = 10.3
                    f.jump_buffer = 0
                    events.append({"kind": "jump", "target": i})
            elif is_aerial() and f.jump_buffer>0 and air_motion.request_air_jump(f):
                events.append({"kind":"double_jump","target":i})
            if f.counter_window>0 and f.buffer_ttl>0 and f.buffer in ["light","heavy","special"]:f.guarding=false
            if f.state=="idle" and f.buffer_ttl > 0 and (not f.guarding or f.buffer=="grab"):
                _start_attack(i, f.buffer)
    if box_active() and ArenaBox.active(f):
        for contact in ArenaBox.integrate(f,EDGE):
            contact["kind"]="arena_bounce";contact["target"]=i
            events.append(contact)
            hitstop=maxi(hitstop,4);hitstop_total=hitstop
    else:
        if f.state != "idle" and f.state != "dash":
            f.vx = move_toward(f.vx, 0.0, STEP * 18.0)
        var next_x: float=f.x+f.vx*STEP
        if absf(next_x)>EDGE and f.state=="stun" and absf(f.vx)>6 and f.wall_bounces==0:
            f.wall_bounces=1
            f.wall_tech_window=12
            if f.wall_tech_buffer>0 and f.meter>=20:
                f.x=clampf(next_x,-EDGE,EDGE)
                _wall_tech(i)
            else:
                f.vx=-signf(next_x)*absf(f.vx)*.60
                f.vy=maxf(f.vy,4.0)
                f.stun=maxi(f.stun,18)
                events.append({"kind":"wall_bounce","target":i})
        f.x=clampf(next_x,-EDGE,EDGE)
        if is_aerial():
            var was_juggled: bool=f.juggle>=3
            var signal_kind: String=air_motion.integrate(f,EDGE)
            if arcade_enabled and signal_kind=="air_land" and was_juggled and f.state=="stun":
                f.state="idle";f.stun=0;f.invuln=maxi(f.invuln,18)
                events.append({"kind":"air_escape","target":i})
            if signal_kind!="":
                events.append({"kind":signal_kind,"target":i,"hard":f.air.hard_land})
                if signal_kind=="ground_bounce":
                    hitstop=maxi(hitstop,6)
                    hitstop_total=hitstop
        else:
            f.vy -= 26.0 * STEP
            var previous_y: float = f.y
            f.y = maxf(0.0, f.y + f.vy * STEP)
            if f.y == 0:
                f.vy = 0.0
                if previous_y > 0.0:
                    f.juggle = 0
                    events.append({"kind": "land", "target": i})
        if box_active() and f.y>ArenaBox.CEILING:
            f.y=ArenaBox.CEILING;f.vy=minf(f.vy,-2.0)
    f.guard_frames = f.guard_frames+1 if f.guarding and was_guarding else (1 if f.guarding else 0)
    f.guard = minf(100.0, f.guard + (0.06 if f.guarding else 0.30)*(1.35 if f.get("draw_core","")=="guard" else 1.0))
    # Landing recovery is bounded (4/8 ticks). Preserve an early Space press
    # through it, just as native hitstop already preserves the input buffer.
    if f.state!="landing":f.jump_buffer = maxi(0,f.jump_buffer-1)
    if f.buffer_ttl > 0:
        f.buffer_ttl -= 1
    if f.buffer_ttl == 0:
        f.buffer = ""

func _start_attack(i: int, requested: String) -> void:
    var f: Dictionary = fighters[i]
    var name := requested
    if requested == "light":
        name = (["air_jab","air_kick","meteor" if arcade_enabled else "air_finisher"] if is_aerial() and f.y>.01 else ["jab", "cross", "launcher" if arcade_enabled else "finisher"])[mini(f.chain, 2)]
    if name=="node_pulse" and (not last_service_enabled or f.character!=3):return
    if not MOVES.has(name):
        return
    if name=="grab":
        if f.throw_cd>0 or f.y>.01:
            f.buffer=""
            f.buffer_ttl=0
            return
        f.throw_cd=60
    if name=="overdrive" and not arcade_enabled:return
    if last_service_enabled and f.character==3 and name=="node_pulse":
        if f.service.nodes.is_empty() or f.service.node_cd>0:
            f.buffer="";f.buffer_ttl=0
            events.append({"kind":"node_unavailable","target":i})
            return
    if name in ["special","overdrive","node_pulse"]:
        var cost:int=10 if name=="node_pulse" else (75 if name=="overdrive" else (20 if last_service_enabled and f.character==3 else 50))
        if f.meter < cost:
            f.buffer = ""
            f.buffer_ttl = 0
            events.append({"kind": "no_meter", "target": i,"cost":cost})
            return
        f.meter -= cost
    if is_aerial():air_motion.attack_stall(f)
    f.counter_attack=f.counter_window>0
    f.counter_window=0
    f.state = "attack"
    f.guarding=false
    f.move = name
    if last_service_enabled:service_rules.started(self,i,name)
    f["move_data"]=move_for(f,name)
    f.frame = 0
    f.connected = false
    f.hit_confirmed = false
    f.buffer = ""
    f.buffer_ttl = 0
    f.vx = f.vx*0.75 if f.y>0.01 else (f.face*2.3 if arcade_enabled and name in ["jab","cross","launcher"] else 0.0)
    events.append({"kind": "swing", "target": i, "move": name})

func _separate_bodies() -> void:
    var a: Dictionary = fighters[0]
    var b: Dictionary = fighters[1]
    var distance: float = absf(a.x - b.x)
    if distance < 0.75 and absf(a.y - b.y) < 1.5:
        var direction: float = 1.0 if b.x >= a.x else -1.0
        var correction := (0.75 - distance) * 0.5
        a.x = clampf(a.x - direction * correction, -EDGE, EDGE)
        b.x = clampf(b.x + direction * correction, -EDGE, EDGE)

func _can_hit(i: int) -> bool:
    var a: Dictionary = fighters[i]
    var b: Dictionary = fighters[1-i]
    if a.state != "attack" or a.connected or b.invuln > 0 or (b.y>0.1 and b.juggle>=3):
        return false
    var m: Dictionary = move_for(a,a.move)
    if last_service_enabled and a.character==3 and a.move in ["special","node_pulse"]:return false
    if a.move=="grab" and (a.y>.01 or b.y>.01 or b.state in ["stun","blockstun"]):return false
    if a.frame < m.startup or a.frame >= m.startup + m.active:
        return false
    var dx: float = b.x - a.x
    return dx * a.face >= -0.15 and absf(dx) <= m.reach and absf(b.y - a.y) <= (2.4 if a.move == "launcher" else 1.65)

func _wall_tech(i: int) -> void:
    var f: Dictionary=fighters[i]
    var normal:Vector2=f.ricochet.normal
    var was_ricochet:bool=ArenaBox.active(f)
    if was_ricochet:ArenaBox.release(f)
    f.meter=maxf(0,f.meter-20)
    f.state="dash"
    f.frame=6
    f.invuln=10
    f.vx=-signf(f.x)*8.0
    f.vy=-5.0 if was_ricochet and normal.y<0 else 6.5
    if was_ricochet and normal.x==0:f.vx=-f.face*8.0
    f.wall_tech_window=0
    f.wall_tech_buffer=0
    f.wall_bounces=1
    f.dash_cd=maxi(f.dash_cd,42)
    f.juggle=0
    f.buffer=""
    f.buffer_ttl=0
    f.jump_buffer=0
    f.stun=0
    events.append({"kind":"wall_tech","target":i})

func _can_open_exchange(i: int) -> bool:
    var a: Dictionary=fighters[i]
    var b: Dictionary=fighters[1-i]
    return not is_aerial() and not (training and rally_enabled) and a.state=="attack" and a.move=="heavy" and exchange.pressure>=exchange.THRESHOLD and exchange.cooldown==0 and a.y<=.01 and b.y<=.01 and b.state in ["idle","attack"]

func _resolve_hit(i: int, allow_exchange := true) -> void:
    var a: Dictionary = fighters[i]
    var b: Dictionary = fighters[1-i]
    var move_name: String = a.move
    var m: Dictionary = move_for(a,move_name)
    if move_name=="grab" and (a.connected or a.state!="attack"):return
    a.connected = true
    if is_aerial() and move_name in ["air_finisher","meteor"] and b.air.parry_window>0 and b.y>.1 and b.state in ["idle","stun"]:
        _begin_air_counter(1-i)
        return
    if move_name=="grab" and (b.tech_window>0 or (b.state=="attack" and b.move=="grab" and b.frame<=MOVES.grab.startup+MOVES.grab.active)):
        for side in 2:
            var fighter: Dictionary=fighters[side]
            fighter.connected=true
            fighter.state="blockstun"
            fighter.stun=10
            fighter.vx=-signf(fighters[1-side].x-fighter.x)*4.0
            fighter.buffer=""
            fighter.buffer_ttl=0
            fighter.tech_window=0
        hitstop=6
        hitstop_total=6
        exchange.contact(12)
        events.append({"kind":"throw_tech","target":1-i})
        return
    if allow_exchange and _can_open_exchange(i):
        var intent: String=exchange.CHOICES[(exchange.serial+clampi(difficulty,0,2))%3]
        if training and partner_mode in [0,1]:intent=exchange.CHOICES[partner_mode]
        var cue: String=intent
        if ai_enabled and not training and difficulty>0:
            var feint: bool=exchange.serial%4==3 if difficulty==1 else exchange.serial%2==1
            if feint:cue=exchange.CHOICES[(exchange.CHOICES.find(intent)+1)%3]
        continuation.clear()
        exchange.begin(i,intent,cue)
        pressure_drill=false
        hitstop=0
        for fighter in fighters:
            fighter.buffer=""
            fighter.buffer_ttl=0
            fighter.jump_buffer=0
            fighter.counter_window=0;fighter.counter_attack=false
        events.append({"kind":"clash_start","attacker":i})
        return
    var attack_x:float=a.get("pulse_origin",a.x)
    if a.has("pulse_origin") and absf(attack_x-b.x)<.01:attack_x=a.x
    var hit_face:float=signf(b.x-attack_x) if a.has("pulse_origin") else a.face
    if move_name!="grab" and b.guarding and (attack_x - b.x) * b.face > 0:
        if b.parry_allowed and b.guard_frames<=PARRY_WINDOW and b.parry_cd==0 and b.guard>=25:
            b.parry_cd = 60
            b.meter = minf(100.0,b.meter+18.0)
            b.guard = maxf(0.0,b.guard-8.0)
            if training and rally_enabled and b.entry_parry_window>0 and a.y<=.01 and b.y<=.01 and exchange.cooldown==0:
                hitstop=0
                exchange.contact(16)
                _begin_rally(1-i)
                return
            a.state = "stun"
            a.stun = 30
            b.counter_window=COUNTER_WINDOW
            a.vx = -a.face*5.0
            hitstop = maxi(hitstop,8)
            hitstop_total = hitstop
            exchange.contact(16)
            events.append({"kind":"parry","target":1-i,"attacker":i,"move":move_name,"distance":absf(a.x-b.x)})
            return
        var guard_pressure:float=8.0 if last_service_enabled and a.character==1 and a.service.preload>=2 else 0.0
        if last_service_enabled and a.character==1 and service_rules.perk(a,"rivet_guard"):guard_pressure+=5.0
        b.guard = maxf(0.0, b.guard - m.damage * 2.8-guard_pressure)
        b.state = "blockstun"
        b.stun = 10
        b.vx = hit_face * 2.2
        hitstop = maxi(hitstop, 4)
        hitstop_total = hitstop
        exchange.contact(8)
        events.append({"kind": "block", "target": 1-i, "attacker": i})
        if b.guard <= 0:
            b.state = "stun"
            b.stun = 65
            b.guarding = false
            events.append({"kind": "guard_break", "target": 1-i})
        return
    if a.counter_attack:
        events.append({"kind":"counter_success","target":i})
        a.counter_attack=false
    exchange.contact(10)
    a.hit_confirmed = true
    if combo_owner != i or b.state != "stun":
        combo_owner = i
        combo_hits = 0
        combo_damage = 0
    var counter: bool = move_name!="grab" and b.state=="attack" and b.frame<move_for(b,b.move).startup
    combo_hits += 1
    var damage: int = maxi(3, roundi(m.damage * maxf(0.45, 1.0 - (combo_hits - 1) * 0.12)))
    if counter: damage = roundi(damage*1.15)
    combo_damage += damage
    last_combo_hits = combo_hits
    last_combo_damage = combo_damage
    b.counter_window=0;b.counter_attack=false
    b.health = maxi(0, b.health - damage)
    if is_aerial():
        air_motion.cancel_stall(b)
        b.air.fast=false
        if b.air.combo_left==0 and (b.y>.1 or m.lift>0):b.air.combo_left=AirMotion.COMBO_TICKS
        if move_name=="launcher":a.air.chase_window=30
    var armor:bool=arcade_enabled and b.state=="attack" and b.move in ["special","overdrive"] and b.frame<move_for(b,b.move).startup and move_name!="grab"
    if last_service_enabled:armor=armor and b.character==1 and b.frame>=move_for(b,b.move).startup-6
    b.state = "attack" if armor else "stun"
    b.stun = 0 if armor else m.stun
    b.vx = 0.0 if armor else hit_face * m.push
    if b.y>0.1: b.juggle += 1
    b.vy = minf(b.vy,-3.5) if b.juggle>=3 else maxf(b.vy,m.lift)
    if is_aerial() and move_name in ["air_jab","air_kick"] and b.y>.1:
        b.air.saved_vy=b.vy
        b.air.stall=8
    if is_aerial() and move_name=="air_counter":b.vy=minf(b.vy,-10.0)
    if is_aerial() and move_name=="meteor":
        b.vy=-16.0
        b.air.bounce_granted=not b.air.bounce_used and b.wall_bounces==0
    if box_active() and not armor and move_name in ["heavy","finisher","launcher","meteor","special","overdrive","air_finisher","air_counter","grab"] and (m.push>=7 or move_name in ["launcher","meteor","air_counter"]):
        ArenaBox.arm(b,move_name,hit_face,m.push)
    var stop_ticks: int={"jab":3,"cross":4,"launcher":9,"air_jab":3,"air_kick":4,"meteor":14,"special":20,"overdrive":26}.get(move_name,m.stop) if arcade_enabled else m.stop
    b.flash = stop_ticks + 7
    if endless:
        b.impact_load=minf(100.0,b.impact_load+damage)
        if b.break_lock==0 and (b.health<=0 or (b.impact_load>=55 and move_name in ["meteor","special","overdrive","air_counter"])):
            b.break_lock=180;b.impact_load=0.0
            events.append({"kind":"break_finish","attacker":i,"target":1-i})
    b.buffer = ""
    b.buffer_ttl = 0
    b.chain = 0
    a.meter = minf(100.0, a.meter + damage * 1.1 * profile_for(a.get("character",0)).gain)
    b.meter = minf(100.0, b.meter + damage * 0.5)
    a.chain = (a.chain + 1) % 3 if move_name in ["jab", "cross", "finisher","air_jab","air_kick","air_finisher"] else 0
    a.chain_ttl = 45
    hitstop = maxi(hitstop, stop_ticks)
    hitstop_total = hitstop
    if is_air_lesson() and move_name in ["air_finisher","air_counter"]:air_lesson_stage="review"
    events.append({"kind": "hit", "target": 1-i, "attacker": i, "damage": damage, "move": move_name, "strength": (.95 if move_name=="meteor" else .8) if is_aerial() and move_name in ["air_finisher","meteor","air_counter"] else float(m.damage) / 27.0, "counter": counter,"face":hit_face})


func _begin_rally(side: int) -> void:
    rally.begin(side)
    _hold_rally()
    events.append({"kind":"rally_contact","owner":side,"tier":rally.tier})

func _hold_rally() -> void:
    hitstop=0
    combo_hits=0
    combo_owner=-1
    combo_damage=0
    for i in 2:
        var f: Dictionary=fighters[i]
        f.state="idle"
        f.move=""
        f.frame=0
        f.vx=0.0
        f.vy=0.0
        f.flash=0
        f.guarding=false
        f.guard_frames=0
        f.buffer=""
        f.buffer_ttl=0
        f.jump_buffer=0
        f.counter_window=0;f.counter_attack=false
        f.connected=false
        f.face=1 if fighters[1-i].x>=f.x else -1

func _tick_rally(commands: Array) -> void:
    var was_phase: String=rally.phase
    var transition: String=rally.tick(commands)
    if transition=="end":
        _end_rally(rally.reason)
        return
    if was_phase=="compress":
        if transition=="windup":events.append({"kind":"rally_windup","owner":rally.owner,"tier":rally.tier})
        return
    var owner: int=rally.owner
    var defender:=1-owner
    # Only the defender can move/guard/escape; no ordinary attacks buffered through it.
    var defense: Dictionary=commands[defender].duplicate()
    defense.erase("attack")
    defense["allow_parry"]=false
    defense["guard"]=defense.get("guard",false) or rally.guard_window[defender]>0
    if defense.get("jump",false):fighters[defender].jump_buffer=8
    _advance_fighter(defender,defense)
    _advance_fighter(owner,{"guard":true,"allow_parry":false})
    fighters[owner].vx=0.0
    _separate_bodies()
    if transition=="release":
        fighters[owner].state="attack"
        fighters[owner].move="cross"
        fighters[owner].frame=MOVES.cross.startup
        fighters[owner].connected=false
        events.append({"kind":"rally_release","owner":owner,"tier":rally.tier})
    if rally.phase!="active" or not _can_hit(owner):return
    var a: Dictionary=fighters[owner]
    var b: Dictionary=fighters[defender]
    if b.guarding and rally.guard_window[defender]>0 and b.guard>=25 and (a.x-b.x)*b.face>0:
        b.guard=maxf(0,b.guard-8)
        if rally.return_parry(defender):
            _hold_rally()
            events.append({"kind":"rally_contact","owner":defender,"tier":rally.tier})
        else:_end_rally("limit")
        return
    if b.guarding and (a.x-b.x)*b.face>0:
        b.guard=maxf(0,b.guard-20-rally.tier*3)
        b.state="blockstun"
        b.stun=12
        b.vx=a.face*4.0
        events.append({"kind":"block","target":defender,"attacker":owner})
        _end_rally("blocked",true)
        return
    var damage: int=rally.DAMAGE[rally.tier-1]
    b.health=maxi(0,b.health-damage)
    b.state="stun"
    b.stun=30
    b.vx=a.face*(8.0+rally.tier)
    b.vy=3.0+rally.tier*.5
    b.flash=15
    a.connected=true
    last_combo_hits=1
    last_combo_damage=damage
    combo_hits=1
    combo_owner=owner
    combo_damage=damage
    events.append({"kind":"hit","attacker":owner,"target":defender,"damage":damage,"move":"cross","strength":.55+rally.tier*.11,"rally_tier":rally.tier})
    hitstop=8+rally.tier*2
    hitstop_total=hitstop
    _end_rally("hit",true)

func _end_rally(why: String, preserve_outcome := false) -> void:
    rally.finish(why)
    exchange.pressure=0
    exchange.cooldown=90
    exchange.quiet_ticks=0
    for f in fighters:
        f.buffer=""
        f.buffer_ttl=0
        f.jump_buffer=0
        f.counter_window=0;f.counter_attack=false
        f.guarding=false
        f.parry_cd=maxi(f.parry_cd,90)
        if not preserve_outcome:
            f.state="idle"
            f.move=""
            f.vx=0.0
    events.append({"kind":"rally_end","reason":why})

func _resolve_exchange() -> void:
    var result: Dictionary=exchange.last_result
    var winner_index: int=result.winner
    # Flush buffered normal moves; a clash decision cannot become a later attack.
    for fighter in fighters:
        fighter.buffer=""
        fighter.buffer_ttl=0
        fighter.jump_buffer=0
        fighter.counter_window=0;fighter.counter_attack=false
        fighter.guarding=false
        fighter.flash=0
        fighter.connected=true
        fighter.hit_confirmed=false
    combo_hits=0
    combo_damage=0
    combo_owner=-1
    events.append({"kind":"clash_end","winner":winner_index,"choice":result.choice,"feint":result.rival_feint})
    if winner_index<0:
        for i in 2:
            fighters[i].state="stun"
            fighters[i].stun=8
            fighters[i].vx=-signf(fighters[1-i].x-fighters[i].x)*4
        hitstop=4
    else:
        var a: Dictionary=fighters[winner_index]
        var b: Dictionary=fighters[1-winner_index]
        a.face=1 if b.x>=a.x else -1
        b.face=-a.face
        if result.choice=="slip":
            a.state="dash"
            a.frame=6
            a.vx=-a.face*11.0
            a.invuln=8
            a.dash_cd=maxi(a.dash_cd,42)
            b.state="stun"
            b.stun=10
            b.vx=0.0
            hitstop=0
            events.append({"kind":"dash","target":winner_index})
        else:
            var damage: int=22 if result.choice=="press" else 16
            b.health=maxi(0,b.health-damage)
            b.state="stun"
            b.stun=28 if result.choice=="press" else 32
            b.vx=a.face*(13.0 if result.choice=="press" else 9.0)
            b.vy=3.0 if result.choice=="press" else 4.0
            b.flash=15
            a.state="attack"
            a.move="heavy"
            a.frame=23
            a.vx=0.0
            a.meter=minf(100,a.meter+12)
            combo_owner=winner_index
            combo_hits=1
            combo_damage=damage
            last_combo_hits=1
            last_combo_damage=damage
            hitstop=8
            events.append({"kind":"hit","target":1-winner_index,"attacker":winner_index,"move":"heavy","damage":damage,"strength":.8,"counter":result.choice=="turn","exchange":true})
    hitstop_total=maxi(1,hitstop)

func _finish_round() -> void:
    exchange.cancel_decision();surge_release.clear();surge_guards=[0,0]
    continuation.clear()
    phase = "round_over"
    if fighters[0].health == fighters[1].health:
        winner = -1
    else:
        winner = 0 if fighters[0].health > fighters[1].health else 1
        wins[winner] += 1
    if wins[0] >= 2 or wins[1] >= 2:
        phase = "match_over"
    events.append({"kind": "ko", "winner": winner})

func _update_training() -> void:
    # Never end a practice round, even on a lethal hit or timer expiry.
    for fighter in fighters:
        fighter.health = maxi(1,fighter.health)
        if endless and fighter.state not in ["stun","blockstun"]:fighter.health=mini(MAX_HEALTH,fighter.health+1)
        if endless:fighter.meter=minf(100.0,fighter.meter+.12)
        if not is_aerial():fighter.meter = 100.0
    var settled := true
    for fighter in fighters:
        if fighter.state!="idle" or fighter.y>0.01: settled=false
    training_rest = training_rest+1 if settled else 0
    if training_rest>=90 and not endless:
        for fighter in fighters:
            fighter.health=MAX_HEALTH
            fighter.guard=100.0
            if is_aerial():fighter.meter=100.0
        combo_hits=0
        combo_damage=0
        combo_owner=-1
        training_rest=0

func reset_training() -> void:
    if not training: return
    reset_round()
    phase="fight"

func is_aerial() -> bool:
    return arcade_enabled or (training and practice_scenario in ["air","air_defense"])

func _advance_air_limits() -> void:
    for i in 2:
        var f: Dictionary=fighters[i]
        if ArenaBox.active(f):continue
        if f.air.combo_left<=0:continue
        if f.state!="stun":
            f.air.combo_left=0
            continue
        f.air.combo_left-=1
        if f.air.combo_left==0:
            air_motion.cancel_stall(f)
            f.state="idle"
            f.vy=minf(f.vy,-4.0)
            f.vx=-f.face*4.0
            f.invuln=maxi(f.invuln,18)
            f.buffer=""
            f.buffer_ttl=0
            f.air.bounce_granted=false
            hitstop=0
            events.append({"kind":"air_escape","target":i})

func is_air_lesson() -> bool:
    return training and practice_scenario=="air_defense"

func configure_air_lesson() -> void:
    if not training:return
    reset_training()
    practice_scenario="air_defense"
    partner_mode=0
    air_lesson_stage="read"
    for i in 2:
        var f: Dictionary=fighters[i]
        f.x=-.65 if i==0 else .65
        f.y=1.4
        f.meter=100.0
        f.air.phase="apex"

func can_air_parry(side: int) -> bool:
    if not is_aerial() or air_counter.active() or hitstop>0:return false
    var f: Dictionary=fighters[side]
    var a: Dictionary=fighters[1-side]
    if f.air.parry_used or f.y<=.1 or a.y<=.1 or f.invuln>0 or f.state not in ["idle","stun"]:return false
    if a.state!="attack" or a.move not in ["air_finisher","meteor"]:return false
    return a.frame<move_for(a,a.move).startup and absf(a.x-f.x)<=move_for(a,a.move).reach+.3 and absf(a.y-f.y)<=1.65 and (f.x-a.x)*a.face>0

func _air_parry_inputs(commands: Array) -> void:
    if hitstop>0:return
    for side in 2:
        var f: Dictionary=fighters[side]
        f.air.parry_window=maxi(0,f.air.parry_window-1)
        if not commands[side].get("guard_pressed",false) or not can_air_parry(side):continue
        if f.meter<air_counter.COST:
            events.append({"kind":"air_parry_no_meter","target":side})
            continue
        f.meter-=air_counter.COST
        f.air.parry_used=true
        f.air.parry_window=air_counter.PARRY_WINDOW
        events.append({"kind":"air_parry_attempt","target":side})

func _begin_air_counter(side: int) -> void:
    continuation.clear()
    air_counter.begin(side)
    hitstop=0
    combo_hits=0;combo_damage=0;combo_owner=-1
    for i in 2:
        var f: Dictionary=fighters[i]
        air_motion.cancel_stall(f)
        f.state="counter_hold"
        f.vx=0.0;f.vy=0.0;f.flash=0
        f.guarding=false
        f.buffer="";f.buffer_ttl=0;f.jump_buffer=0
        f.counter_window=0;f.counter_attack=false
        f.air.combo_left=0
        f.air.drop_buffer=0;f.air.chase_buffer=0;f.air.chase_window=0
        f.air.parry_window=0;f.air.bounce_granted=false
        f.air.phase="parry" if i==side else "recoil"
        f.face=1 if fighters[1-i].x>=f.x else -1
    events.append({"kind":"air_counter_start","owner":side})

func _tick_air_counter(commands: Array) -> void:
    var owner: int=air_counter.owner
    var defender:=1-owner
    var old_choice: String=air_counter.choice
    var transition: String=air_counter.tick(commands,(ai_enabled or partner_mode==2) and owner==1)
    if old_choice=="" and air_counter.choice!="":events.append({"kind":"air_counter_choice","owner":owner,"choice":air_counter.choice})
    if transition=="escape":
        var f: Dictionary=fighters[owner]
        f.state="dash";f.frame=6;f.vx=-f.face*8.0;f.vy=-2.0;f.invuln=10
        fighters[defender].state="idle"
        _end_air_counter("escape")
        events.append({"kind":"dash","target":owner})
        return
    if transition=="end":
        _end_air_counter(air_counter.reason)
        return
    if air_counter.phase=="hold":return
    if transition=="windup":
        for f in fighters:f.state="idle"
        _start_attack(owner,"air_counter")
        events.append({"kind":"air_counter_windup","owner":owner})
        return
    var defense: Dictionary=commands[defender].duplicate()
    defense.erase("attack")
    defense["allow_parry"]=false
    if defense.get("dash",false) and absf(defense.get("axis",0.0))<.1:defense["axis"]=-fighters[defender].face
    _advance_fighter(defender,defense)
    # A counter starts at frame 0; the first live windup tick already counts as 1.
    _advance_fighter(owner,{"allow_parry":false})
    _separate_bodies()
    if transition=="release":events.append({"kind":"air_counter_release","owner":owner})
    if _can_hit(owner):
        _resolve_hit(owner,false)
        _end_air_counter("hit")

func _end_air_counter(why: String) -> void:
    air_counter.finish(why)
    for f in fighters:
        if f.state=="counter_hold":f.state="idle"
        f.buffer="";f.buffer_ttl=0;f.jump_buffer=0
        f.counter_window=0;f.counter_attack=false
        f.air.parry_window=0
        if f.air.phase in ["parry","recoil"]:f.air.phase="fall"
    if is_air_lesson():air_lesson_stage="review"
    events.append({"kind":"air_counter_end","reason":why,"owner":air_counter.owner})

func move_for(fighter:Dictionary,name:String) -> Dictionary:
    if last_service_enabled:return ServiceProfiles.move(MOVES[name],fighter.get("character",0),name,fighter)
    return Profiles.move(MOVES[name],fighter.get("character",0),name)

# Explicit, opt-in comparison fixture; no pending player inputs are inspected.
func surge_partner_command() -> Dictionary:
    var gap:float=fighters[0].x-fighters[1].x
    if absf(gap)>1.4:return {"axis":signf(gap)}
    return {"attack":"heavy"} if ai_tick%120==90 else {}

func _surge_pair_ready() -> bool:
    if not training or not arcade_enabled or not surge_lab_enabled or phase!="fight":return false
    if hitstop>0 or air_counter.active() or rally.active() or exchange.active():return false
    for f in fighters:
        if f.health<=0 or f.state!="idle" or f.stun>0 or f.y>.01 or f.buffer_ttl>0 or f.jump_buffer>0:return false
    return true

func _try_surge_decision(commands:Array) -> bool:
    if not _surge_pair_ready() or exchange.pressure<exchange.THRESHOLD or exchange.cooldown>0:return false
    # Both are still neutral: no active attack, paid start or stun is ever cancelled.
    var candidates:Array[int]=[]
    for side in 2:
        var attack:String=commands[side].get("attack","")
        if attack not in ["heavy","launcher"] or commands[side].get("jump",false) or commands[side].get("dash",false):continue
        var f:Dictionary=fighters[side];var other:Dictionary=fighters[1-side]
        var move_name:String="launcher" if attack=="launcher" or commands[side].get("up",false) else "heavy"
        var gap:float=other.x-f.x
        if gap*f.face>0 and absf(gap)<=minf(1.8,move_for(f,move_name).reach):candidates.append(side)
    if candidates.is_empty():return false
    # Alternating priority is deterministic if both propose a strike in the same step.
    var initiator:int=candidates[exchange.serial%candidates.size()]
    var next_move:String=commands[initiator].attack
    if next_move=="heavy" and commands[initiator].get("up",false):next_move="launcher"
    var intents:Array=[]
    for side in 2:
        var f:Dictionary=fighters[side]
        var option:int=posmod(ai_tick+round_number+side+exchange.serial,3)
        intents.append("evade" if option==2 and f.dash_cd==0 else ("guard" if option==1 and f.guard>0 else "strike"))
    # Computer intent is fixed before either side can send a window choice.
    exchange.begin_decision(initiator,next_move,intents,commands)
    continuation.clear()
    events.append({"kind":"surge_decision_start","initiator":initiator,"serial":exchange.serial})
    return true

func _tick_surge_decision(commands:Array) -> void:
    if not _surge_pair_ready():
        exchange.cancel_decision();surge_release.clear()
        events.append({"kind":"surge_decision_cancel"})
        return
    var initiator:int=exchange.decision.initiator
    if absf(fighters[0].x-fighters[1].x)>minf(1.8,move_for(fighters[initiator],exchange.decision.move).reach):
        exchange.cancel_decision();surge_release.clear()
        events.append({"kind":"surge_decision_cancel"})
        return
    var automated:Array=[false,ai_enabled or (training and partner_mode==2) or surge_lab_fixture]
    if not exchange.advance_decision(commands,automated):return
    var result:Dictionary=exchange.decision_result
    surge_release=[{},{}]
    for side in 2:
        var choice:String=result.choices[side]
        # Timeout preserves both original proposals, including a same-step defender input.
        if choice=="":
            surge_release[side]=result.defaults[side].duplicate()
            continue
        match choice:
            "strike":surge_release[side]={"attack":result.move if side==result.initiator else "light"}
            "guard":
                surge_release[side]={"guard":true,"guard_pressed":true}
                surge_guards[side]=24
            "evade":surge_release[side]={"dash":true,"axis":-float(fighters[side].face)}
    events.append({"kind":"surge_decision_end","choices":result.choices.duplicate(),"serial":result.serial})

func box_active() -> bool:
    return arcade_enabled and not rally_enabled and not pressure_drill and not surge_lab_fixture and air_lesson_stage==""
