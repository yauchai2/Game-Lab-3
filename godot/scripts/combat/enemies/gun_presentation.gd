extends RefCounted
## Presentation for the Black Suit pistol. Reads sim state and events only; never writes combat state.
## Look: Jet Set Radio pixel-cel. Flat colour, hard ink outline, chunky stepped shapes, no gradients.
const HOT := Color("ff3d6e")      # enemy fire
const REFLECT := Color("1ee6d6")  # a bullet that was parried back
const PAPER := Color("fff8dc")
const INK := Color("111a32")
const GUN_KINDS := ["gun_fire", "gun_hit", "gun_block", "gun_deflect", "gun_dodge"]
const GunShot = preload("res://scripts/combat/enemies/gun_shot.gd")

## Returns true when the event was fully handled here (the generic swing/hit presentation must not also run).
static func handle(session: Node, event: Dictionary) -> bool:
    var kind: String = event.kind
    var sim: RefCounted = session.sim
    if kind == "swing" and event.get("move", "") == "gun":
        session.audio.play_sound("gun_aim", 1.0, -3.0)
        return true
    if kind not in GUN_KINDS:return false
    var at := Vector2(event.get("x", 0.0), event.get("y", 1.0))
    var dir: float = event.get("dir", 1.0)
    match kind:
        "gun_fire":
            session._spawn_vfx("gun_muzzle", at, .10, {"face": dir, "color": HOT, "attacker": event.target})
            session.audio.play_sound("gun_shot", 1.0, -1.0)
            session.trauma = maxf(session.trauma, .28)
        "gun_hit":
            if sim.arcade_enabled and not session.reduced_effects:session.rhythm.trigger("impact",1-int(event.target),"gun",sim.exchange.tier())
            var shooter: int = 1 - int(event.target)
            session._spawn_vfx("hit", at, .16, {"strength": .5, "color": REFLECT if event.get("reflected", false) else HOT, "move": "jab", "face": dir, "attacker": shooter})
            session._spawn_vfx("gun_spark", at, .22, {"face": dir, "color": PAPER, "attacker": shooter})
            session.audio.play_sound("gun_hit", 1.0, -1.0)
            session.audio.play_sound("hit", 1.25, -8.0)
            session.trauma = maxf(session.trauma, .4)
            var visual: Node3D = session.fighters[clampi(event.target, 0, 1)]
            visual.fx_flash_age = 0.0
            if event.get("reflected", false) and event.target == 1:
                session.hud.notice = "REFLECTED"
                session.hud.notice_time = .8
        "gun_block":
            session._spawn_vfx("block", at, .22, {"strength": .45, "color": Color("eaf078"), "move": "jab", "face": -dir, "attacker": 1 - int(event.target)})
            session._spawn_vfx("gun_spark", at, .18, {"face": -dir, "color": Color("eaf078"), "attacker": 1 - int(event.target)})
            session.audio.play_sound("gun_ricochet", 1.0, -3.0)
            session.audio.play_sound("block", 1.1, -6.0)
            if event.get("broken", false):
                session.audio.play_sound("guard_break", 1.0, -3.0)
                session.hud.notice = "GUARD BREAK"
                session.hud.notice_time = .8
            elif event.target == 0:
                session.hud.notice = "BLOCKED"
                session.hud.notice_time = .5
        "gun_deflect":
            session._spawn_vfx("parry", at, .26, {"strength": .8, "color": Color("eaf078"), "move": "jab", "face": -dir, "attacker": 1 - int(event.target)})
            session._spawn_vfx("gun_spark", at, .22, {"face": -dir, "color": REFLECT, "attacker": 1 - int(event.target)})
            session.audio.play_sound("parry", 1.1, -4.0)
            session.audio.play_sound("gun_ricochet", 1.25, -3.0)
            session.trauma = maxf(session.trauma, .3)
            if event.target == 0:
                session.hud.notice = "DEFLECT / SEND IT BACK"
                session.hud.notice_time = .9
            if sim.arcade_enabled and not session.reduced_effects:
                session.rhythm.trigger("parry", clampi(event.target, 0, 1), "", sim.exchange.tier())
        "gun_dodge":
            session.audio.play_sound("swing", 1.45, -11.0)
            if event.target == 0 and event.get("how", "") == "dash":
                session.hud.notice = "DODGE"
                session.hud.notice_time = .5
    return true

## Live telegraph and bullets, drawn every frame straight from simulation state.
static func draw_overlay(canvas: Control, session: Node3D) -> void:
    var sim: RefCounted = session.sim
    var shooters: Array = sim.squad_members if sim.squad_enabled else [sim.fighters[1]]
    for f in shooters:
        if f.health > 0 and f.state == "attack" and f.move == "gun":_draw_sight(canvas, session, f)
    for p in sim.projectiles:_draw_bullet(canvas, session, p)

static func _draw_sight(canvas: Control, session: Node3D, f: Dictionary) -> void:
    var sim: RefCounted = session.sim
    var move: Dictionary = sim.move_for(f, "gun")
    if f.frame > move.startup:return
    var t: float = clampf(float(f.frame) / float(move.startup), 0.0, 1.0)
    var reduced: bool = session.reduced_effects
    var dir: float = float(f.face)
    var y: float = f.y + GunShot.BULLET_Y
    var start: Vector2 = session.project(Vector2(f.x + dir * GunShot.MUZZLE_X, y))
    var far: float = clampf(f.x + dir * 11.0, -session.sim.EDGE - .8, session.sim.EDGE + .8)
    var reach: float = lerpf(.25, 1.0, minf(1.0, t * 1.6))
    var finish: Vector2 = session.project(Vector2(lerpf(f.x + dir * GunShot.MUZZLE_X, far, reach), y))
    var warning: bool = move.startup - f.frame <= 10
    var blink: bool = warning and not reduced and int(f.frame / 2) % 2 == 0
    var color: Color = PAPER if blink else HOT
    var length: float = start.distance_to(finish)
    var direction: Vector2 = (finish - start).normalized() if length > 1.0 else Vector2(dir, 0)
    var width: float = lerpf(2.0, 6.0, t) if not reduced else 4.0
    # Chunky dashed line of fire: ink under-stroke, flat colour on top.
    var step: float = 26.0
    var cursor: float = 0.0
    var index: int = 0
    while cursor < length:
        if index % 2 == 0 or warning:
            var a: Vector2 = start + direction * cursor
            var b: Vector2 = start + direction * minf(length, cursor + step * .7)
            canvas.draw_line(a, b, INK, width + 4.0)
            canvas.draw_line(a, b, color, width)
        cursor += step
        index += 1
    # "!" plate above the head, the same hard-edge block language as the other tells.
    var head: Vector2 = session.project(Vector2(f.x, f.y + 2.55))
    if warning or t > .35:
        var plate := Rect2(head + Vector2(-13, -31), Vector2(26, 34))
        canvas.draw_rect(Rect2(plate.position - Vector2(3, 3), plate.size + Vector2(6, 6)), INK)
        canvas.draw_rect(plate, color if not blink else HOT)
        canvas.draw_rect(Rect2(head + Vector2(-3, -26), Vector2(6, 15)), INK)
        canvas.draw_rect(Rect2(head + Vector2(-3, -7), Vector2(6, 6)), INK)

static func _draw_bullet(canvas: Control, session: Node3D, p: Dictionary) -> void:
    var at: Vector2 = session.project(Vector2(p.x, p.y))
    var dir: float = float(p.dir)
    var color: Color = REFLECT if p.reflected else HOT
    var reduced: bool = session.reduced_effects
    # Stepped hard-edge trail (3 blocks), then an ink-outlined slug with a paper core.
    for i in (1 if reduced else 3):
        var offset: float = -dir * (24.0 + i * 24.0)
        var block := Rect2(at + Vector2(offset - 10.0, -4.0 + i), Vector2(20, 8 - i * 2))
        canvas.draw_rect(block, Color(color, 1.0 - i * .28))
    var tail: Vector2 = at - Vector2(dir * 18.0, 0)
    var tip: Vector2 = at + Vector2(dir * 18.0, 0)
    var outline := PackedVector2Array([tail + Vector2(0, -9), at + Vector2(dir * 6.0, -9), tip + Vector2(dir * 5.0, 0), at + Vector2(dir * 6.0, 9), tail + Vector2(0, 9)])
    canvas.draw_colored_polygon(outline, INK)
    var body := PackedVector2Array([tail + Vector2(dir * 2.0, -6), at + Vector2(dir * 5.0, -6), tip + Vector2(dir * 1.0, 0), at + Vector2(dir * 5.0, 6), tail + Vector2(dir * 2.0, 6)])
    canvas.draw_colored_polygon(body, color)
    canvas.draw_line(tail + Vector2(dir * 5.0, 0), at + Vector2(dir * 12.0, 0), PAPER, 3.0)

## Effect kinds spawned by `handle` and drawn by fight_vfx.
static func draw_effect(canvas: Control, session: Node3D, effect: Dictionary) -> void:
    var at: Vector2 = session.project(effect.at)
    var time: float = clampf(effect.age / effect.life, 0.0, 1.0)
    var stage: float = floorf(time * 4.0) / 4.0
    var face: float = effect.get("face", 1.0)
    var tint: Color = effect.color
    var reduced: bool = session.reduced_effects
    match effect.kind:
        "gun_muzzle":
            var spikes: int = 4 if reduced else 7
            for i in spikes:
                var angle: float = (float(i) / float(spikes) - .5) * 1.7 + (0.0 if face > 0 else PI)
                var direction := Vector2.from_angle(angle)
                var tangent := direction.orthogonal()
                @warning_ignore("integer_division")
                var length: float = (70.0 if i == spikes / 2 else 38.0) * (1.0 - stage * .5)
                var tip: Vector2 = at + direction * length
                canvas.draw_colored_polygon(PackedVector2Array([at + tangent * 10.0, tip, at - tangent * 10.0]), INK)
                canvas.draw_colored_polygon(PackedVector2Array([at + tangent * 6.0, at + direction * (length - 8.0), at - tangent * 6.0]), PAPER if i % 2 == 0 else tint)
            canvas.draw_circle(at, 13.0 * (1.0 - stage * .6), PAPER)
        "gun_spark":
            var shards: int = 4 if reduced else 8
            for i in shards:
                var angle: float = (float(i) / float(shards) - .5) * 2.4 + (0.0 if face > 0 else PI)
                var direction := Vector2.from_angle(angle)
                var tangent := direction.orthogonal()
                var base: Vector2 = at + direction * (10.0 + time * 54.0)
                var size: float = 9.0 * (1.0 - stage * .6)
                canvas.draw_colored_polygon(PackedVector2Array([base + direction * size * 1.6, base + tangent * size * .6, base - tangent * size * .6]), tint if i % 2 else PAPER)
