extends RefCounted
## Black Suit pistol: one owner for the rules of the "gun" move (deterministic, 60 Hz).
## It is a rare, readable ranged option, never a spam tool:
##   * only fighters with character 4 can use it, and only the AI asks for it (`wants`);
##   * 30-tick wind-up (stretched further by squad scaling), cancelled by any hit it takes;
##   * a long per-fighter cooldown plus a sim-wide gap so two guns never overlap;
##   * one slow, visible bullet that dash i-frames, a jump, a block or a parry all answer.
## Presentation lives in gun_presentation.gd and only reads `sim.projectiles` and events.
const SPEED := 15.0 / 60.0       # world units per tick (~15 u/s: about 0.4 s across a 6 u gap)
const MUZZLE_X := .75
const BULLET_Y := 1.0
const JUMP_CLEAR := 1.0          # a fighter whose feet are above this lets the bullet pass underneath
const HIT_HALF := .5
const MIN_RANGE := 3.4           # closer than this the suit prefers melee
const MAX_RANGE := 9.0
const COOLDOWN := [480, 360, 270]   # per fighter, by difficulty (8 s / 6 s / 4.5 s)
const GLOBAL_GAP := 150             # ticks after any shot before another gun may start
const OPENING_DELAY := 150          # no shots in the first 2.5 s after a fighter appears
const STUN := 16
const REFLECT_DAMAGE := 14
const MELEE_ONLY_ROLES := ["rusher", "guard", "heavy", "jammer", "boss"]

static func cooldown(difficulty: int) -> int:
    return COOLDOWN[clampi(difficulty, 0, 2)]

## AI gate, evaluated every tick by both AI paths. Returns true on the rare tick it wants to shoot.
static func wants(s: RefCounted, side: int, clock: int, level: int) -> bool:
    var f: Dictionary = s.fighters[side]
    var o: Dictionary = s.fighters[1 - side]
    if int(f.get("character", 0)) != 4 or f.get("story_role", "") in MELEE_ONLY_ROLES:return false
    if not f.has("gun_cd"):
        f["gun_cd"] = OPENING_DELAY + int(f.get("squad_id", 0)) * 40
        return false
    if int(f.gun_cd) > 0 or s.tick_count < s.gun_next_ok:return false
    if f.state != "idle" or f.y > .01 or f.health <= 0 or f.guarding:return false
    if o.health <= 0 or o.state in ["stun", "blockstun", "ko"] or o.y > .01 or o.invuln > 0:return false
    if s.phase != "fight" or s.exchange.active() or s.air_counter.active() or s.rally.active():return false
    var distance: float = absf(o.x - f.x)
    if distance < MIN_RANGE or distance > MAX_RANGE or (o.x - f.x) * f.face < 0:return false
    # Roll the dice only every 0.75 s so a funded cooldown does not mean an instant shot.
    var salt: int = int(f.get("squad_id", 0)) * 29
    if posmod(clock + salt, 45) != 0:return false
    return posmod(floori(float(clock) / 45.0) * 37 + salt, 100) < [25, 35, 50][clampi(level, 0, 2)]

## Called when the move starts. Returns false when the move is not allowed (caller clears the buffer).
static func begin(s: RefCounted, f: Dictionary) -> bool:
    if int(f.get("character", 0)) != 4 or f.y > .01 or int(f.get("gun_cd", 0)) > 0:return false
    f["gun_cd"] = cooldown(s.difficulty)
    f["gun_fired"] = false
    s.gun_next_ok = s.tick_count + GLOBAL_GAP
    return true

static func tick_cooldown(f: Dictionary) -> void:
    if f.has("gun_cd"):f["gun_cd"] = maxi(0, int(f.gun_cd) - 1)

## Spawns bullets on the exact fire frame, then moves and resolves every live bullet.
static func advance(s: RefCounted) -> void:
    for side in 2:
        var f: Dictionary = s.fighters[side]
        if f.state == "attack" and f.move == "gun" and not f.get("gun_fired", true):
            var move: Dictionary = s.move_for(f, "gun")
            if f.frame >= move.startup:
                f["gun_fired"] = true
                _spawn(s, side, f, move)
    var kept: Array[Dictionary] = []
    for p in s.projectiles:
        if _step(s, p):kept.append(p)
    s.projectiles = kept

static func _spawn(s: RefCounted, side: int, f: Dictionary, move: Dictionary) -> void:
    var dir: float = float(f.face)
    var p := {"owner": side, "shooter": f, "target": s.fighters[1 - side], "x": f.x + dir * MUZZLE_X, "y": f.y + BULLET_Y,
        "dir": dir, "age": 0, "damage": move.damage, "passed": false, "reflected": false}
    s.projectiles.append(p)
    s.events.append(_tag({"kind": "gun_fire", "target": side, "x": p.x, "y": p.y, "dir": dir, "damage": p.damage}, f))

## Returns false when the bullet is finished.
static func _step(s: RefCounted, p: Dictionary) -> bool:
    p.age += 1
    p.x += p.dir * SPEED
    if absf(p.x) > s.EDGE + 1.2:return false
    if p.passed:return true
    var t: Dictionary = p.target
    if t.health <= 0:
        p.passed = true
        return true
    var rel: float = (t.x - p.x) * p.dir
    if rel > HIT_HALF:return true
    if rel < -HIT_HALF:
        p.passed = true
        return true
    var victim: int = 1 - int(p.owner)
    var at := {"x": p.x, "y": p.y, "dir": p.dir, "reflected": p.reflected}
    if t.invuln > 0 or t.y > JUMP_CLEAR:
        # i-frames (dash) or a jump: the bullet flies on. A dash dodge pays a little energy back.
        var how: String = "dash" if t.state == "dash" else ("jump" if t.y > JUMP_CLEAR else "invuln")
        if how == "dash" and not p.reflected:t.meter = minf(100.0, t.meter + 6.0)
        s.events.append({"kind": "gun_dodge", "target": victim, "how": how, "x": p.x, "y": p.y})
        p.passed = true
        return true
    var facing_shooter: bool = t.face == -int(p.dir) and t.guarding and t.y <= .01
    if facing_shooter and t.parry_allowed and t.guard_frames <= s.PARRY_WINDOW and t.parry_cd == 0 and t.guard >= 25.0 and not p.reflected:
        t.parry_cd = 60
        t.meter = minf(100.0, t.meter + 18.0)
        t.guard = maxf(0.0, t.guard - 8.0)
        t.counter_window = s.COUNTER_WINDOW
        s.hitstop = maxi(s.hitstop, 1 if s.arcade_enabled else 6)
        s.hitstop_total = s.hitstop
        var shooter: Dictionary = p.shooter
        s.events.append({"kind": "gun_deflect", "target": victim, "x": p.x, "y": p.y, "dir": p.dir})
        # The deflected round goes back where it came from and can hurt the shooter if they are still alive.
        p.owner = victim
        p.target = shooter
        p.dir = -p.dir
        p.reflected = true
        p.damage = REFLECT_DAMAGE
        p.age = 0
        return true
    if facing_shooter:
        t.guard = maxf(0.0, t.guard - float(p.damage) * 2.0)
        t.state = "blockstun"
        t.stun = 8
        t.vx = p.dir * 1.8
        s.hitstop = maxi(s.hitstop, 1 if s.arcade_enabled else 3)
        s.hitstop_total = s.hitstop
        var broken: bool = t.guard <= 0.0
        if broken:
            t.state = "stun"
            t.stun = 65
            t.guarding = false
        s.events.append({"kind": "gun_block", "target": victim, "x": p.x, "y": p.y, "dir": p.dir, "broken": broken})
        return false
    _hit(s, p, t, victim)
    return false

static func _hit(s: RefCounted, p: Dictionary, t: Dictionary, victim: int) -> void:
    var damage: int = maxi(1, int(p.damage))
    t.health = maxi(0, t.health - damage)
    t.state = "stun"
    t.stun = STUN
    t.vx = p.dir * 3.0
    t.flash = 13
    t.counter_window = 0
    t.counter_attack = false
    t.buffer = ""
    t.buffer_ttl = 0
    t.invuln = maxi(t.invuln, 10)
    t.meter = minf(100.0, t.meter + damage * .5)
    s.hitstop = maxi(s.hitstop, 1 if s.arcade_enabled else 6)
    s.hitstop_total = s.hitstop
    s.events.append(_tag({"kind": "gun_hit", "target": victim, "damage": damage, "x": p.x, "y": p.y, "dir": p.dir,
        "reflected": p.reflected}, t))

## Squad/story events must name the member they belong to, but only members have an id.
static func _tag(event: Dictionary, f: Dictionary) -> Dictionary:
    if f.has("squad_id"):event["squad_id"] = f.squad_id
    return event
