extends RefCounted
## Canvas-side flipbook sprites for contact feedback. Textures are CC0 (assets/vfx/SOURCES.md),
## baked white+alpha so every fighter colour comes from `tint` at draw time. Presentation only.
const INK := Color("111a32")
const PAPER := Color("fff8dc")
## One texel = one 640x360 game pixel = PX screen pixels on the 1280x720 HUD canvas. Never scale or rotate sprites
## off that grid; pick the small or big sheet instead.
const PX := 2.0
const CELL := 64.0
const BIG_CELL := 128.0
const BIG_AT := 200.0
## Authored comic starburst: frames 0-3 grow/hold, 4-7 break into shards.
const FIRST_FRAME := 0
const LAST_FRAME := 7
## Burst spikes point along +x.
const NATIVE_ANGLE := 0.0
var tint_sheet: Texture2D = load("res://assets/vfx/hit_spark_tint.png")
var core_sheet: Texture2D = load("res://assets/vfx/hit_spark_core.png")
var ink_sheet: Texture2D = load("res://assets/vfx/hit_spark_ink.png")
var big_tint: Texture2D = load("res://assets/vfx/hit_spark_big_tint.png")
var big_core: Texture2D = load("res://assets/vfx/hit_spark_big_core.png")
var big_ink: Texture2D = load("res://assets/vfx/hit_spark_big_ink.png")
var slash_tint: Texture2D = load("res://assets/vfx/slash_tint.png")
var slash_core: Texture2D = load("res://assets/vfx/slash_core.png")
var slash_ink: Texture2D = load("res://assets/vfx/slash_ink.png")

## Draws one textured quad on the pixel grid (axis-aligned, optional mirror), without touching the canvas transform.
func _quad(canvas: Control, texture: Texture2D, src: Rect2, at: Vector2, size: Vector2, mirror_x: bool, mirror_y: bool, color: Color) -> void:
    var sheet: Vector2 = texture.get_size()
    var center := Vector2(roundf(at.x / PX) * PX, roundf(at.y / PX) * PX)
    var half: Vector2 = size * 0.5
    var corners := PackedVector2Array([center + Vector2(-half.x, -half.y), center + Vector2(half.x, -half.y), center + Vector2(half.x, half.y), center + Vector2(-half.x, half.y)])
    var u0: float = src.position.x / sheet.x
    var u1: float = src.end.x / sheet.x
    var v0: float = src.position.y / sheet.y
    var v1: float = src.end.y / sheet.y
    if mirror_x:
        var t: float = u0; u0 = u1; u1 = t
    if mirror_y:
        var t: float = v0; v0 = v1; v1 = t
    canvas.draw_colored_polygon(corners, color, PackedVector2Array([Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]), texture)

## Comic starburst. `heading` only picks the mirror (left/right); `size` only picks the small (128px) or big (256px) sheet.
func hit_spark(canvas: Control, at: Vector2, phase: float, tint: Color, heading: float, size: float) -> void:
    var big: bool = size >= BIG_AT
    var cell: float = BIG_CELL if big else CELL
    var frame: int = FIRST_FRAME + clampi(floori(clampf(phase, 0.0, 0.9999) * float(LAST_FRAME - FIRST_FRAME + 1)), 0, LAST_FRAME - FIRST_FRAME)
    var src := Rect2(Vector2(frame % 4, floori(float(frame) / 4.0)) * cell, Vector2(cell, cell))
    var edge := Vector2(cell, cell) * PX
    var flip: bool = cos(heading) < 0.0
    _quad(canvas, big_ink if big else ink_sheet, src, at, edge, flip, false, INK)
    _quad(canvas, big_tint if big else tint_sheet, src, at, edge, flip, false, tint)
    _quad(canvas, big_core if big else core_sheet, src, at, edge, flip, false, PAPER)

const SLASH_W := 66.0
const SLASH_H := 49.0
## Pixel-art sword-slash crescent (CC0, tbbk), always at 1 texel = 1 game pixel. `facing` mirrors it horizontally;
## `down` flips it vertically for downward swings.
func slash(canvas: Control, at: Vector2, phase: float, tint: Color, facing: float, down: bool) -> void:
    var frame: int = clampi(floori(clampf(phase, 0.0, 0.9999) * 9.0), 0, 8)
    var src := Rect2(Vector2(frame % 3, floori(float(frame) / 3.0)) * Vector2(SLASH_W, SLASH_H), Vector2(SLASH_W, SLASH_H))
    var size := Vector2(SLASH_W, SLASH_H) * PX
    var center: Vector2 = at + Vector2(facing * SLASH_W * PX * 0.18, 0)
    var mirror: bool = facing < 0.0
    _quad(canvas, slash_ink, src, center, size, mirror, down, INK)
    _quad(canvas, slash_tint, src, center, size, mirror, down, tint)
    _quad(canvas, slash_core, src, center, size, mirror, down, PAPER)

var puff_sheet: Texture2D = load("res://assets/vfx/puffs.png")
## One soft dust puff (CC0 Kenney smoke pack) from the 3x2 atlas; `index` picks the silhouette.
func puff(canvas: Control, at: Vector2, index: int, _size: Vector2, _roll: float, color: Color) -> void:
    # Always whole texels at PX screen px each, no rotation; the caller makes it vanish instead of scaling.
    _quad(canvas, puff_sheet, Rect2(Vector2(index % 3, floori(float(index) / 3.0) % 2) * 24.0, Vector2(24, 24)), at, Vector2(24, 24) * PX, index % 2 == 1, false, color)

## Ground shock: puffs rolling outward along the floor ellipse, with a dust sheet fading behind them.
func ground_shock(canvas: Control, at: Vector2, time: float, color: Color, count: int, reach: float) -> void:
    var spread: float = reach * (1.0 - pow(1.0 - time, 2.0))
    for i in count:
        var a: float = float(i) / float(count) * TAU + 0.4
        var p: Vector2 = at + Vector2(cos(a) * spread, sin(a) * spread * 0.28)
        var edge: float = (26.0 + 22.0 * time) * (0.8 + 0.4 * float((i * 7) % 3) / 2.0)
        if time < 0.7:puff(canvas, p, i, Vector2(edge, edge), 0.0, color)

## Charge-up: a few thick ink speed streaks sliding inward to `at` (hard polygons, same language as the game's wedges).
func converge(canvas: Control, at: Vector2, _time: float, tint: Color, radius: float, count: int) -> void:
    for i in count:
        var a: float = float(i) / float(count) * TAU + 0.35
        var dir: Vector2 = Vector2.from_angle(a)
        var tip: Vector2 = at + dir * maxf(radius * 0.55, 10.0)
        var tail: Vector2 = at + dir * (radius + 26.0)
        var side: Vector2 = dir.orthogonal()
        canvas.draw_colored_polygon(PackedVector2Array([tail + side * 5.0, tip, tail - side * 5.0]), INK)
        canvas.draw_colored_polygon(PackedVector2Array([tail + side * 2.5, tip + dir * 3.0, tail - side * 2.5]), tint)
