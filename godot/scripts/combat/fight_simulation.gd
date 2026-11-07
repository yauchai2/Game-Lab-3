extends RefCounted
## Deterministic 60 Hz gameplay. Presentation uses a separate, unfrozen clock.
const STEP := 1.0 / 60.0
const EDGE := 8.2
const MAX_HEALTH := 100
const ROUND_SECONDS := 75.0
const MOVES := {
    "jab": {"startup": 5, "active": 5, "recovery": 13, "damage": 7, "reach": 1.65, "stun": 18, "push": 3.0, "lift": 0.0, "stop": 5},
    "cross": {"startup": 6, "active": 5, "recovery": 15, "damage": 9, "reach": 1.85, "stun": 21, "push": 4.0, "lift": 0.0, "stop": 6},
    "finisher": {"startup": 9, "active": 6, "recovery": 23, "damage": 13, "reach": 2.1, "stun": 28, "push": 9.0, "lift": 3.8, "stop": 9},
    "heavy": {"startup": 16, "active": 7, "recovery": 26, "damage": 18, "reach": 2.25, "stun": 32, "push": 10.0, "lift": 2.5, "stop": 11},
    "launcher": {"startup": 13, "active": 7, "recovery": 27, "damage": 14, "reach": 1.8, "stun": 39, "push": 3.0, "lift": 10.0, "stop": 10},
    "special": {"startup": 18, "active": 10, "recovery": 31, "damage": 27, "reach": 3.4, "stun": 40, "push": 14.0, "lift": 5.0, "stop": 17}
}
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

func _init() -> void:
    reset_round()

func reset_round() -> void:
    fighters.clear()
    for i in 2:
        fighters.append({"x": -3.0 if i == 0 else 3.0, "y": 0.0, "vx": 0.0, "vy": 0.0,
            "face": 1 if i == 0 else -1, "health": MAX_HEALTH, "meter": 0.0, "guard": 100.0,
            "state": "idle", "move": "", "frame": 0, "stun": 0, "connected": false,
            "buffer": "", "buffer_ttl": 0, "chain": 0, "chain_ttl": 0, "dash_cd": 0,
            "invuln": 0, "flash": 0, "guarding": false})
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
    var command := {"axis": signf(b.x - a.x) if distance > 1.45 else 0.0}
    # Deliberate reaction windows and punishable heavy attacks, not perfect reads.
    if ai_tick % 22 < 12 and b.state == "attack" and distance < 2.8:
        command["guard"] = true
        command["axis"] = 0.0
    if ai_tick % 25 == 0 and distance < 2.5:
        command["attack"] = "special" if a.meter >= 50 and ai_tick % 100 == 0 else ("heavy" if ai_tick % 75 == 0 else "light")
    if b.y > 1.0 and ai_tick % 48 == 0:
        command["jump"] = true
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
    var commands := [player, ai_command() if ai_enabled else opponent]
    for i in 2:
        var f: Dictionary = fighters[i]
        f.flash = maxi(0, f.flash - 1)
        if commands[i].has("attack"):
            f.buffer = "launcher" if commands[i].attack == "heavy" and commands[i].get("up", false) else commands[i].attack
            f.buffer_ttl = 10
    if hitstop > 0:
        hitstop -= 1
        return
    ai_tick += 1
    remaining = maxf(0.0, remaining - STEP)
    for i in 2:
        _advance_fighter(i, commands[i])
    _separate_bodies()
    # Resolve simultaneous active attacks from the same frame; trades are allowed.
    var contacts: Array[int] = []
    for i in 2:
        if _can_hit(i):
            contacts.append(i)
    for i in contacts:
        _resolve_hit(i)
    if fighters[0].health <= 0 or fighters[1].health <= 0 or remaining <= 0:
        _finish_round()

func _advance_fighter(i: int, command: Dictionary) -> void:
    var f: Dictionary = fighters[i]
    var other: Dictionary = fighters[1-i]
    f.dash_cd = maxi(0, f.dash_cd - 1)
    f.invuln = maxi(0, f.invuln - 1)
    f.chain_ttl = maxi(0, f.chain_ttl - 1)
    if f.chain_ttl == 0:
        f.chain = 0
    f.guarding = false
    if f.state in ["stun", "blockstun"]:
        if f.state == "blockstun":
            f.guarding = command.get("guard", false) and f.y <= 0.01 and f.guard > 0
        f.stun -= 1
        if f.stun <= 0:
            f.state = "idle"
    elif f.state == "attack":
        f.frame += 1
        var move: Dictionary = MOVES[f.move]
        var end: int = move.startup + move.active + move.recovery
        # Confirmed light attacks cancel into the next light during recovery.
        if f.connected and f.move in ["jab", "cross"] and f.frame >= move.startup + move.active and f.buffer == "light" and f.buffer_ttl > 0:
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
            f.guarding = command.get("guard", false) and f.y <= 0.01 and f.guard > 0
            f.vx = float(command.get("axis", 0.0)) * (1.6 if f.guarding else 5.8)
            if command.get("jump", false) and f.y <= 0.01 and not f.guarding:
                f.vy = 10.3
                events.append({"kind": "jump", "target": i})
            if f.buffer_ttl > 0 and not f.guarding:
                _start_attack(i, f.buffer)
    if f.state != "idle" and f.state != "dash":
        f.vx = move_toward(f.vx, 0.0, STEP * 18.0)
    f.x = clampf(f.x + f.vx * STEP, -EDGE, EDGE)
    f.vy -= 26.0 * STEP
    var previous_y: float = f.y
    f.y = maxf(0.0, f.y + f.vy * STEP)
    if f.y == 0:
        f.vy = 0.0
        if previous_y > 0.0:
            events.append({"kind": "land", "target": i})
    f.guard = minf(100.0, f.guard + (0.06 if f.guarding else 0.30))
    if f.buffer_ttl > 0:
        f.buffer_ttl -= 1
    if f.buffer_ttl == 0:
        f.buffer = ""

func _start_attack(i: int, requested: String) -> void:
    var f: Dictionary = fighters[i]
    var name := requested
    if requested == "light":
        name = ["jab", "cross", "finisher"][mini(f.chain, 2)]
    if not MOVES.has(name):
        return
    if name == "special":
        if f.meter < 50:
            f.buffer = ""
            f.buffer_ttl = 0
            events.append({"kind": "no_meter", "target": i})
            return
        f.meter -= 50
    f.state = "attack"
    f.move = name
    f.frame = 0
    f.connected = false
    f.buffer = ""
    f.buffer_ttl = 0
    f.vx = 0.0
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
    if a.state != "attack" or a.connected or b.invuln > 0:
        return false
    var m: Dictionary = MOVES[a.move]
    if a.frame < m.startup or a.frame >= m.startup + m.active:
        return false
    var dx: float = b.x - a.x
    return dx * a.face >= -0.15 and absf(dx) <= m.reach and absf(b.y - a.y) <= (2.4 if a.move == "launcher" else 1.65)

func _resolve_hit(i: int) -> void:
    var a: Dictionary = fighters[i]
    var b: Dictionary = fighters[1-i]
    var move_name: String = a.move
    var m: Dictionary = MOVES[move_name]
    a.connected = true
    if b.guarding and (a.x - b.x) * b.face > 0:
        b.guard = maxf(0.0, b.guard - m.damage * 2.8)
        b.state = "blockstun"
        b.stun = 10
        b.vx = a.face * 2.2
        hitstop = maxi(hitstop, 4)
        hitstop_total = hitstop
        events.append({"kind": "block", "target": 1-i, "attacker": i})
        if b.guard <= 0:
            b.state = "stun"
            b.stun = 65
            b.guarding = false
            events.append({"kind": "guard_break", "target": 1-i})
        return
    if combo_owner != i or b.state != "stun":
        combo_owner = i
        combo_hits = 0
        combo_damage = 0
    combo_hits += 1
    var damage: int = maxi(3, roundi(m.damage * maxf(0.45, 1.0 - (combo_hits - 1) * 0.12)))
    combo_damage += damage
    b.health = maxi(0, b.health - damage)
    b.state = "stun"
    b.stun = m.stun
    b.vx = a.face * m.push
    b.vy = maxf(b.vy, m.lift)
    b.flash = m.stop + 7
    b.buffer = ""
    b.buffer_ttl = 0
    b.chain = 0
    a.meter = minf(100.0, a.meter + damage * 1.1)
    b.meter = minf(100.0, b.meter + damage * 0.5)
    a.chain = (a.chain + 1) % 3 if move_name in ["jab", "cross", "finisher"] else 0
    a.chain_ttl = 45
    hitstop = maxi(hitstop, m.stop)
    hitstop_total = hitstop
    events.append({"kind": "hit", "target": 1-i, "attacker": i, "damage": damage, "move": move_name, "strength": float(m.damage) / 27.0})

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
