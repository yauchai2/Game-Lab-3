extends Node3D
const PlayerController = preload("res://scripts/test_player.gd")
var walking := true
@onready var player: PlayerController = $Player
@onready var street: Node3D = $Street
func _ready() -> void:
    # S1 camera shortcuts remain available when its scene runs on its own.
    street.set_process_unhandled_key_input(false)
    $Street/Overlay/Help.mouse_filter = Control.MOUSE_FILTER_IGNORE
    activate_walk()
func activate_walk(capture_mouse := true) -> void:
    walking = true
    player.activate_camera(capture_mouse)
    update_help()
func select_reference(index: int) -> void:
    walking = false
    player.set_control_enabled(false)
    player.set_mouse_capture(false)
    street.select_view(index)
    update_help()
func update_help() -> void:
    var mode := "WALK / FIRST PERSON" if player.first_person else "WALK / THIRD PERSON"
    if not walking:
        mode = "REFERENCE / "+str($Street/ReferenceCameras.get_child(street.active_view).get_meta("label"))
    $Street/Overlay/Help.text = mode+"   |   STYLE: "+$StyleSample.mode_label()+"   |   SKY: "+$StyleSample.sky_label()+"\nWASD / Arrows: move   Shift: faster   Space: jump   Mouse: look\n0: walk   1-5 / Tab: reference views   V: first/third person\nB: materials   C: flat/cloud   N: image sky   P: flyby   R: reset   Esc: release mouse   Click: capture"
func _unhandled_key_input(event: InputEvent) -> void:
    if not event.is_pressed() or event.is_echo():
        return
    if event.keycode >= KEY_1 and event.keycode <= KEY_5:
        select_reference(event.keycode-KEY_1)
    elif event.keycode == KEY_TAB:
        select_reference(0 if walking else street.active_view+1)
    elif event.keycode == KEY_0:
        activate_walk()
    elif event.keycode == KEY_B:
        $StyleSample.set_mode($StyleSample.mode+1)
        update_help()
    elif event.keycode == KEY_C:
        $StyleSample.set_clouds(not $StyleSample.clouds_enabled)
        update_help()
    elif event.keycode == KEY_N:
        $StyleSample.set_image_sky(not $StyleSample.image_sky_enabled)
        update_help()
    elif event.keycode == KEY_P:
        $AircraftFlyby.restart()
    elif event.keycode == KEY_R:
        player.reset_to_spawn()
        activate_walk()
    elif event.keycode == KEY_V and walking:
        player.set_first_person(not player.first_person)
        update_help()
    elif event.keycode == KEY_ESCAPE:
        player.set_mouse_capture(false)
