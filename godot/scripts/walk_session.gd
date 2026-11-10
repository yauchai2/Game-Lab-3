extends Node3D
const PlayerController = preload("res://scripts/test_player.gd")
var walking := true
var street_hud: Control
var preferences=preload("res://scripts/combat/fight_preferences.gd").new()
@export var preferences_path:="user://afterhours.cfg"
var options: Dictionary={}
@onready var player: PlayerController = $Player
@onready var street: Node3D = $Street
func _ready() -> void:
    # S1 camera shortcuts remain available when its scene runs on its own.
    street.set_process_unhandled_key_input(false)
    $Street/Overlay/Help.hide()
    var canvas:=CanvasLayer.new()
    add_child(canvas)
    street_hud=preload("res://scripts/combat/ui/street_hud.gd").new()
    street_hud.session=self
    options=preferences.read_options(preferences_path)
    street_hud.copy.language=options.language
    $AircraftFlyby.set_audio_options(options.muted,options.effects_level)
    canvas.add_child(street_hud)
    preload("res://scripts/combat/street_backdrop.gd").strip_scene_text(self)
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
    if is_instance_valid(street_hud):street_hud.refresh()
func _unhandled_key_input(event: InputEvent) -> void:
    if not event.is_pressed() or event.is_echo():
        return
    if event.keycode == KEY_F6:
        return_to_fight()
    elif event.keycode == KEY_H:
        street_hud.expanded=not street_hud.expanded
        street_hud.refresh()
    elif event.keycode == KEY_M:
        options.muted=not options.muted
        $AircraftFlyby.set_audio_options(options.muted,options.effects_level)
        preferences.write_options(preferences_path,options)
        street_hud.refresh()
    elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
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
    elif event.keycode == KEY_O:
        $OutlinePass.visible = not $OutlinePass.visible
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
func return_to_fight() -> void:
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
    get_tree().change_scene_to_file("res://scenes/combat/street_fight.tscn")
