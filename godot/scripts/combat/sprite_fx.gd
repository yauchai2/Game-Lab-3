extends RefCounted
## Canvas-side flipbook sprites for contact feedback. Textures are CC0 (assets/vfx/SOURCES.md),
## baked white+alpha so every fighter colour comes from `tint` at draw time. Presentation only.
const INK := Color("111a32")
const PAPER := Color("fff8dc")
const CELL := 96.0
## Frames 0-5 of the source sheet carry a smooth shockwave ring, so playback starts at the jagged burst (frame 6 still shows a faint ring remnant).
const FIRST_FRAME := 7
const LAST_FRAME := 13
## Sheet art travels toward the upper-right (-45 degrees on screen).
const NATIVE_ANGLE := -PI / 4.0
var tint_sheet: Texture2D = load("res://assets/vfx/hit_spark_tint.png")
var core_sheet: Texture2D = load("res://assets/vfx/hit_spark_core.png")
var ink_sheet: Texture2D = load("res://assets/vfx/hit_spark_ink.png")
var slash_tint: Texture2D = load("res://assets/vfx/slash_tint.png")
var slash_core: Texture2D = load("res://assets/vfx/slash_core.png")
var slash_ink: Texture2D = load("res://assets/vfx/slash_ink.png")

## Draws one textured quad without touching the canvas transform (the HUD owns a base scale).
func _quad(canvas: Control, texture: Texture2D, src: Rect2, at: Vector2, size: Vector2, roll: float, color: Color) -> void:
    var sheet: Vector2 = texture.get_size()
    var corners := PackedVector2Array()
    for corner in [Vector2(-.5, -.5), Vector2(.5, -.5), Vector2(.5, .5), Vector2(-.5, .5)]:
        corners.append(at + (corner * size).rotated(roll))
    var uvs := PackedVector2Array([src.position / sheet, Vector2(src.end.x, src.position.y) / sheet, src.end / sheet, Vector2(src.position.x, src.end.y) / sheet])
    canvas.draw_colored_polygon(corners, color, uvs, texture)

## `heading` is the screen-space direction the sparks travel; `size` is the on-screen cell edge in pixels.
func hit_spark(canvas: Control, at: Vector2, phase: float, tint: Color, heading: float, size: float) -> void:
    var frame: int = FIRST_FRAME + clampi(floori(clampf(phase, 0.0, 0.9999) * float(LAST_FRAME - FIRST_FRAME + 1)), 0, LAST_FRAME - FIRST_FRAME)
    var src := Rect2(Vector2(frame % 4, frame / 4) * CELL, Vector2(CELL, CELL))
    # Cel style: no alpha fade. The burst shrinks away on its last frames instead.
    var shrink: float = 1.0 - maxf(0.0, phase - 0.7) / 0.3 * 0.35
    var roll: float = heading - NATIVE_ANGLE
    var edge := Vector2(size, size) * shrink
    _quad(canvas, ink_sheet, src, at, edge, roll, INK)
    _quad(canvas, tint_sheet, src, at, edge, roll, tint)
    _quad(canvas, core_sheet, src, at, edge, roll, PAPER)

const SLASH_W := 66.0
const SLASH_H := 49.0
## Pixel-art sword-slash crescent (CC0, tbbk) used for every swing; `facing` mirrors it, `length` is screen px.
func slash(canvas: Control, at: Vector2, phase: float, tint: Color, facing: float, roll: float, length: float, thickness := 1.0) -> void:
    var frame: int = clampi(floori(clampf(phase, 0.0, 0.9999) * 9.0), 0, 8)
    var src := Rect2(Vector2(frame % 3, frame / 3) * Vector2(SLASH_W, SLASH_H), Vector2(SLASH_W, SLASH_H))
    var size := Vector2(length, length * SLASH_H / SLASH_W * thickness)
    var center: Vector2 = at + Vector2(facing * length * 0.18, 0).rotated(roll)
    var sheet: Vector2 = slash_tint.get_size()
    for pass_index in 3:
        var tex: Texture2D = [slash_ink, slash_tint, slash_core][pass_index]
        var color: Color = [INK, tint, PAPER][pass_index]
        var corners := PackedVector2Array()
        for corner in [Vector2(-.5, -.5), Vector2(.5, -.5), Vector2(.5, .5), Vector2(-.5, .5)]:
            corners.append(center + Vector2(corner.x * size.x * facing, corner.y * size.y).rotated(roll))
        var uvs := PackedVector2Array([src.position / sheet, Vector2(src.end.x, src.position.y) / sheet, src.end / sheet, Vector2(src.position.x, src.end.y) / sheet])
        canvas.draw_colored_polygon(corners, color, uvs, tex)

var puff_sheet: Texture2D = load("res://assets/vfx/puffs.png")
## One soft dust puff (CC0 Kenney smoke pack) from the 3x2 atlas; `index` picks the silhouette.
func puff(canvas: Control, at: Vector2, index: int, size: Vector2, roll: float, color: Color) -> void:
    _quad(canvas, puff_sheet, Rect2(Vector2(index % 3, (index / 3) % 2) * 48.0, Vector2(48, 48)), at, size, roll, color)

## Ground shock: puffs rolling outward along the floor ellipse, with a dust sheet fading behind them.
func ground_shock(canvas: Control, at: Vector2, time: float, color: Color, count: int, reach: float) -> void:
    var spread: float = reach * (1.0 - pow(1.0 - time, 2.0))
    for i in count:
        var a: float = float(i) / float(count) * TAU + 0.4
        var p: Vector2 = at + Vector2(cos(a) * spread, sin(a) * spread * 0.28)
        var edge: float = (26.0 + 22.0 * time) * (0.8 + 0.4 * float((i * 7) % 3) / 2.0)
        var life: float = 1.0 - maxf(0.0, time - 0.45) / 0.55
        puff(canvas, p, i, Vector2(edge, edge * 0.8) * life, float(i) * 0.9, color)

## Charge-up: small sparks streaming inward to `at` on a shrinking radius, .
func converge(canvas: Control, at: Vector2, time: float, tint: Color, radius: float, count: int) -> void:
    for i in count:
        var a: float = float(i) / float(count) * TAU + time * 0.9
        var p: Vector2 = at + Vector2.from_angle(a) * radius
        hit_spark(canvas, p, 0.15 + 0.35 * fposmod(time * 3.0 + float(i) * 0.37, 1.0), tint, a + PI, 96.0)
