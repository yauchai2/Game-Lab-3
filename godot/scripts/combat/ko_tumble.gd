extends RefCounted
const L10n=preload("res://scripts/combat/ui/locale_text.gd")
## Presentation-only knockout flight: freeze, launch away from the winner, mid-air
## backflip, hard landing, bounce and slide to rest. Single owner of the KO body
## path and its screen-space accents. It never touches simulation state; it only
## reads the victim's final pose and hands the session a replacement x/y/spin.
const HIT_STOP := .11
const FLIGHT := .58
const BOUNCE := .24
const SLIDE := .38
const TOTAL := HIT_STOP + FLIGHT + BOUNCE + SLIDE
const ARENA_EDGE := 8.0
const MAX_TRAVEL := 4.0
var victim := -1
var age := 0.0
var x0 := 0.0
var y0 := 0.0
var dir := 1.0
var face := 1.0
var travel := 0.0
var fired: Dictionary = {}
var slide_puffs := 0

func clear() -> void:
    victim = -1;age = 0.0;fired.clear();slide_puffs = 0

func active() -> bool:
    return victim >= 0

func begin(victim_side: int, winner_x: float, x: float, y: float, facing: float) -> void:
    victim = victim_side;age = 0.0;fired.clear();slide_puffs = 0
    x0 = x;y0 = y;face = 1.0 if facing >= 0.0 else -1.0
    dir = 1.0 if x >= winner_x else -1.0
    var room: float = (ARENA_EDGE - x) if dir > 0.0 else (x + ARENA_EDGE)
    travel = clampf(room, .6, MAX_TRAVEL)

func _smooth(u: float) -> float:
    u = clampf(u, 0.0, 1.0)
    return u * u * (3.0 - 2.0 * u)

## Returns the body pose for the current age: x, y, spin (radians about the
## torso, 0 means upright), squash (0..1 contact squash) and phase name.
func sample() -> Dictionary:
    var out := {"x": x0, "y": y0, "spin": 0.0, "squash": 0.0, "phase": "freeze"}
    if victim < 0:return out
    var backward: float = -1.0 if dir == -face else 1.0
    var flight_x: float = travel * .68
    var bounce_x: float = travel * .15
    var slide_x: float = travel * .17
    if age < HIT_STOP:
        out.squash = 1.0
        return out
    var t: float = age - HIT_STOP
    if t < FLIGHT:
        var u: float = t / FLIGHT
        out.phase = "flight"
        out.x = x0 + dir * flight_x * (1.0 - pow(1.0 - u, 2.0))
        out.y = y0 * (1.0 - u) + 1.5 * 4.0 * u * (1.0 - u)
        out.spin = backward * TAU * _smooth(u)
        out.squash = maxf(0.0, 1.0 - u * 6.0) * .6
        return out
    t -= FLIGHT
    var land_x: float = x0 + dir * flight_x
    if t < BOUNCE:
        var v: float = t / BOUNCE
        out.phase = "bounce"
        out.x = land_x + dir * bounce_x * v
        out.y = .42 * 4.0 * v * (1.0 - v)
        out.spin = backward * .2 * sin(v * PI)
        out.squash = maxf(0.0, 1.0 - v * 5.0)
        return out
    t -= BOUNCE
    var w: float = clampf(t / SLIDE, 0.0, 1.0)
    out.phase = "slide" if age < TOTAL else "rest"
    out.x = land_x + dir * (bounce_x + slide_x * (1.0 - pow(1.0 - w, 3.0)))
    out.y = 0.0
    return out

## Advances the clock and returns one-shot beats for the session to answer with
## dust, camera and sound: launch, land, bounce, dust (during slide), rest.
func advance(delta: float) -> Array:
    var beats: Array = []
    if victim < 0:return beats
    age += delta
    var marks := {"launch": HIT_STOP, "land": HIT_STOP + FLIGHT, "bounce": HIT_STOP + FLIGHT + BOUNCE, "rest": TOTAL}
    for key in marks:
        if age >= marks[key] and not fired.has(key):
            fired[key] = true;beats.append(key)
    var slide_t: float = age - (HIT_STOP + FLIGHT + BOUNCE)
    if slide_t > 0.0 and slide_t < SLIDE and slide_puffs < int(slide_t / .11) + 1:
        slide_puffs += 1;beats.append("dust")
    return beats

func draw(canvas: Control, session: Node3D) -> void:
    if victim < 0 or session.reduced_effects or session.screen != "result":return
    var pose := sample()
    var ink := Color("201223")
    var paper := Color("fff0ca")
    var yellow := Color("ffd83e")
    var scale: float = session.fighters[victim].model_scale
    var chest: Vector2 = session.project(Vector2(pose.x, pose.y + scale * .5))
    var step := floorf(age * 12.0) / 12.0
    # Impact star at the contact moment, hard-edged and unrotated per frame.
    if age < .2:
        var radius: float = 70.0 + age * 260.0
        var star := PackedVector2Array()
        for i in 16:star.append(chest + Vector2.from_angle(i * PI / 8.0 + .15) * (radius if i % 2 == 0 else radius * .14))
        canvas.draw_colored_polygon(star, yellow if age < .11 else paper)
    # Ink speed lines trail the body during the flight (horizontal slivers).
    if pose.phase == "flight":
        var trail: float = -dir
        var life: float = 1.0 - clampf((age - HIT_STOP) / FLIGHT, 0.0, 1.0)
        for i in 9:
            var row: float = float(i) - 4.0
            var start := chest + Vector2(trail * (36.0 + float((i * 37) % 5) * 12.0), row * 24.0 + sin(step * 9.0 + i) * 4.0)
            var length: float = (130.0 + float((i * 53) % 4) * 55.0) * (.4 + life * .6)
            var finish := start + Vector2(trail * length, row * 2.0)
            canvas.draw_colored_polygon(PackedVector2Array([start + Vector2(0, -3), finish, start + Vector2(0, 3)]), ink if i % 3 else paper)
    # K.O. beat: pops in over the freeze, holds through the flight, then clears.
    var word_age: float = age
    if word_age < 1.15:
        var pop: float = clampf(word_age / .12, 0.0, 1.0)
        var size: int = int(lerpf(150.0, 96.0, pop))
        var fade: float = clampf((1.15 - word_age) / .25, 0.0, 1.0)
        var spot := Vector2(640.0 - size * .95, 190.0)
        var shift := Vector2(7, 7)
        canvas.draw_string(session.hud.bold, spot + shift,L10n.text( "K.O."), HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(ink, fade))
        canvas.draw_string(session.hud.bold, spot,L10n.text( "K.O."), HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(paper, fade))
