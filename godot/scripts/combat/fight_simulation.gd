extends RefCounted
## Deterministic 60 Hz gameplay. Presentation uses a separate, unfrozen clock.
const PARRY_WINDOW := 12
const COUNTER_WINDOW := 36
const INPUT_BUFFER := 14
const STEP := 1.0 / 60.0
const EDGE := 8.2
const MAX_HEALTH := 100
const ROUND_SECONDS := 75.0
const AirMotion=preload("res://scripts/combat/aerial_motion.gd")
var air_motion:=AirMotion.new()
var air_counter=preload("res://scripts/combat/air_counter.gd").new()
var air_lesson_stage:=""
var air_lesson_ticks:=0
var practice_scenario:="free"
const MOVES := {
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
    "special": {"startup": 18, "active": 10, "recovery": 31, "damage": 27, "reach": 3.4, "stun": 40, "push": 14.0, "lift": 5.0, "stop": 17}
}
var rally = preload("res://scripts/combat/kinetic_rally.gd").new()
var rally_enabled := false
var rally_drill := false
var guard_was_down := [false,false]
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
var pressure_drill := false
var partner_mode := 0 # 0 standing, 1 guard, 2 sparring
var training_rest := 0
var last_combo_hits := 0
var last_combo_damage := 0

func _init() -> void:
    reset_round()

func reset_round() -> void:
    exchange.reset()
    practice_scenario="free"
    air_counter.reset()
    air_lesson_stage=""
    air_lesson_ticks=0
    rally.reset()
    rally_enabled=false
    rally_drill=false
    guard_was_down=[false,false]
    pressure_drill=false
    fighters.clear()
    for i in 2:
        fighters.append({"x": -3.0 if i == 0 else 3.0, "y": 0.0, "vx": 0.0, "vy": 0.0,
            "air":AirMotion.fresh(), "face": 1 if i == 0 else -1, "health": MAX_HEALTH, "meter": 0.0, "guard": 100.0,
            "state": "idle", "move": "", "frame": 0, "stun": 0, "connected": false,
            "buffer": "", "buffer_ttl": 0, "chain": 0, "chain_ttl": 0, "dash_cd": 0,
            "invuln": 0, "flash": 0, "guarding": false, "guard_frames": 0, "parry_cd": 0, "parry_allowed": true, "entry_parry_window":0, "counter_window":0, "counter_attack":false, "jump_buffer":0, "juggle":0, "hit_confirmed":false,"throw_cd":0,"tech_window":0,"wall_bounces":0,"wall_tech_window":0,"wall_tech_buffer":0})
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

func restart_match() -> void:
    wins = [0, 0]
    round_number = 1
    reset_round()

func next_round() -> void:
    if phase == "round_over":
        round_number += 1
        reset_round()

func ai_command() -> Dictionary:
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
    if is_aerial() and level>0 and not a.air.parry_used and b.move in ["air_finisher","meteor"] and b.state=="attack" and b.frame==MOVES[b.move].startup-5 and (ai_tick+round_number)%3<level:
        command["guard_pressed"]=true
    return command

func tick(player: Dictionary = {}, opponent: Dictionary = {}) -> void:
    events.clear()
    tick_count += 1
    if phase == "ready":
        countdown -= 1
        if countdown <= 0:
            phase = "fight"
            events.append({"kind": "fight"})
        return
    if phase != "fight":
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
    var commands := [player.duplicate(),partner.duplicate()]
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
    # Resolve simultaneous active attacks from the same frame; trades are allowed.
    var contacts: Array[int] = []
    for i in 2:
        if _can_hit(i):
            contacts.append(i)
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
    if training:
        _update_training()
        return
    if fighters[0].health <= 0 or fighters[1].health <= 0 or remaining <= 0:
        _finish_round()

func _advance_fighter(i: int, command: Dictionary) -> void:
    var f: Dictionary = fighters[i]
    var other: Dictionary = fighters[1-i]
    f.parry_allowed = command.get("allow_parry",true)
    f.counter_window=maxi(0,f.counter_window-1)
    f.entry_parry_window=PARRY_WINDOW if command.get("guard_pressed",false) else maxi(0,f.entry_parry_window-1)
    var was_guarding: bool = f.guarding
    f.throw_cd=maxi(0,f.throw_cd-1)
    f.tech_window=maxi(0,f.tech_window-1)
    if f.state=="stun" and f.wall_tech_window>0 and f.wall_tech_buffer>0 and f.meter>=20:
        _wall_tech(i)
    f.wall_tech_window=maxi(0,f.wall_tech_window-1)
    f.wall_tech_buffer=maxi(0,f.wall_tech_buffer-1)
    if f.state=="idle" and f.y<=.01:f.wall_bounces=0
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
        var move: Dictionary = MOVES[f.move]
        var end: int = move.startup + move.active + move.recovery
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
        if f.hit_confirmed and f.move in ["air_jab","air_kick"] and f.frame>=move.startup+move.active and f.buffer=="light" and f.buffer_ttl>0:
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
            f.vx = (signf(command.get("axis", 0.0)) if absf(command.get("axis", 0.0)) > 0.1 else float(f.face)) * 14.0
            events.append({"kind": "dash", "target": i})
        else:
            f.guarding = (command.get("guard", false) or (f.entry_parry_window>0 and f.parry_allowed and f.parry_cd==0 and f.jump_buffer<=0)) and f.y <= 0.01 and f.guard > 0
            f.vx = float(command.get("axis", 0.0)) * (1.6 if f.guarding else 5.8)
            if f.jump_buffer>0 and f.y <= 0.01 and not f.guarding:
                if is_aerial():air_motion.request_jump(f)
                else:
                    f.vy = 10.3
                    f.jump_buffer = 0
                    events.append({"kind": "jump", "target": i})
            if f.counter_window>0 and f.buffer_ttl>0 and f.buffer in ["light","heavy","special"]:f.guarding=false
            if f.state=="idle" and f.buffer_ttl > 0 and (not f.guarding or f.buffer=="grab"):
                _start_attack(i, f.buffer)
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
        var signal_kind: String=air_motion.integrate(f,EDGE)
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
    f.guard_frames = f.guard_frames+1 if f.guarding and was_guarding else (1 if f.guarding else 0)
    f.guard = minf(100.0, f.guard + (0.06 if f.guarding else 0.30))
    f.jump_buffer = maxi(0,f.jump_buffer-1)
    if f.buffer_ttl > 0:
        f.buffer_ttl -= 1
    if f.buffer_ttl == 0:
        f.buffer = ""

func _start_attack(i: int, requested: String) -> void:
    var f: Dictionary = fighters[i]
    var name := requested
    if requested == "light":
        name = (["air_jab","air_kick","air_finisher"] if is_aerial() and f.y>.01 else ["jab", "cross", "finisher"])[mini(f.chain, 2)]
    if not MOVES.has(name):
        return
    if name=="grab":
        if f.throw_cd>0 or f.y>.01:
            f.buffer=""
            f.buffer_ttl=0
            return
        f.throw_cd=60
    if name == "special":
        if f.meter < 50:
            f.buffer = ""
            f.buffer_ttl = 0
            events.append({"kind": "no_meter", "target": i})
            return
        f.meter -= 50
    if is_aerial():air_motion.attack_stall(f)
    f.counter_attack=f.counter_window>0
    f.counter_window=0
    f.state = "attack"
    f.guarding=false
    f.move = name
    f.frame = 0
    f.connected = false
    f.hit_confirmed = false
    f.buffer = ""
    f.buffer_ttl = 0
    f.vx = f.vx*0.75 if f.y>0.01 else 0.0
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
    var m: Dictionary = MOVES[a.move]
    if a.move=="grab" and (a.y>.01 or b.y>.01 or b.state in ["stun","blockstun"]):return false
    if a.frame < m.startup or a.frame >= m.startup + m.active:
        return false
    var dx: float = b.x - a.x
    return dx * a.face >= -0.15 and absf(dx) <= m.reach and absf(b.y - a.y) <= (2.4 if a.move == "launcher" else 1.65)

func _wall_tech(i: int) -> void:
    var f: Dictionary=fighters[i]
    f.meter=maxf(0,f.meter-20)
    f.state="dash"
    f.frame=6
    f.invuln=10
    f.vx=-signf(f.x)*8.0
    f.vy=6.5
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
    var m: Dictionary = MOVES[move_name]
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
    if move_name!="grab" and b.guarding and (a.x - b.x) * b.face > 0:
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
            events.append({"kind":"parry","target":1-i,"attacker":i})
            return
        b.guard = maxf(0.0, b.guard - m.damage * 2.8)
        b.state = "blockstun"
        b.stun = 10
        b.vx = a.face * 2.2
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
    var counter: bool = move_name!="grab" and b.state=="attack" and b.frame<MOVES[b.move].startup
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
    b.state = "stun"
    b.stun = m.stun
    b.vx = a.face * m.push
    if b.y>0.1: b.juggle += 1
    b.vy = minf(b.vy,-3.5) if b.juggle>=3 else maxf(b.vy,m.lift)
    if is_aerial() and move_name in ["air_jab","air_kick"] and b.y>.1:
        b.air.saved_vy=b.vy
        b.air.stall=8
    if is_aerial() and move_name=="air_counter":b.vy=minf(b.vy,-10.0)
    if is_aerial() and move_name=="meteor":
        b.vy=-16.0
        b.air.bounce_granted=not b.air.bounce_used and b.wall_bounces==0
    b.flash = m.stop + 7
    b.buffer = ""
    b.buffer_ttl = 0
    b.chain = 0
    a.meter = minf(100.0, a.meter + damage * 1.1)
    b.meter = minf(100.0, b.meter + damage * 0.5)
    a.chain = (a.chain + 1) % 3 if move_name in ["jab", "cross", "finisher","air_jab","air_kick","air_finisher"] else 0
    a.chain_ttl = 45
    hitstop = maxi(hitstop, m.stop)
    hitstop_total = hitstop
    if is_air_lesson() and move_name in ["air_finisher","air_counter"]:air_lesson_stage="review"
    events.append({"kind": "hit", "target": 1-i, "attacker": i, "damage": damage, "move": move_name, "strength": (.95 if move_name=="meteor" else .8) if is_aerial() and move_name in ["air_finisher","meteor","air_counter"] else float(m.damage) / 27.0, "counter": counter})


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
        if not is_aerial():fighter.meter = 100.0
    var settled := true
    for fighter in fighters:
        if fighter.state!="idle" or fighter.y>0.01: settled=false
    training_rest = training_rest+1 if settled else 0
    if training_rest>=90:
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
    return training and practice_scenario in ["air","air_defense"]

func _advance_air_limits() -> void:
    for i in 2:
        var f: Dictionary=fighters[i]
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
    return a.frame<MOVES[a.move].startup and absf(a.x-f.x)<=MOVES[a.move].reach+.3 and absf(a.y-f.y)<=1.65 and (f.x-a.x)*a.face>0

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
