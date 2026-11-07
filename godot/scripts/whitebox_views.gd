extends Node3D
## Fixed S1 inspection cameras only. A walk controller belongs to S2.
var active_view := 0
func _ready() -> void:
    select_view(0)
func select_view(index: int) -> void:
    var cameras = $ReferenceCameras.get_children()
    active_view = posmod(index, cameras.size())
    cameras[active_view].make_current()
    $Overlay/Help.text = "WHITEBOX / S1    1–5: views    Tab: next\n" + str(cameras[active_view].get_meta("label", cameras[active_view].name))
func _unhandled_key_input(event: InputEvent) -> void:
    if not event.is_pressed() or event.is_echo():
        return
    if event.keycode >= KEY_1 and event.keycode <= KEY_5:
        select_view(event.keycode - KEY_1)
    elif event.keycode == KEY_TAB:
        select_view(active_view + 1)
