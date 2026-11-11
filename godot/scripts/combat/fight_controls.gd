extends RefCounted
## Local devices for one or two players: split keyboard, gamepads and hot-plug.
## Reads input events only; combat rules stay in fight_simulation.gd.
const LSHIFT := -1
const RSHIFT := -2
const AUTO := 0
const KEYBOARD := 1
const GAMEPAD := 2
const KB_SOLO := {KEY_A:"left",KEY_LEFT:"left",KEY_D:"right",KEY_RIGHT:"right",KEY_W:"up",KEY_UP:"up",KEY_S:"down",KEY_DOWN:"down",KEY_J:"light",KEY_K:"heavy",KEY_L:"skill",KEY_G:"grab",KEY_SPACE:"jump",KEY_E:"dash",LSHIFT:"guard",RSHIFT:"guard"}
const KB_LEFT := {KEY_A:"left",KEY_D:"right",KEY_W:"up",KEY_S:"down",KEY_F:"light",KEY_G:"heavy",KEY_R:"skill",KEY_T:"grab",KEY_SPACE:"jump",KEY_E:"dash",LSHIFT:"guard"}
const KB_RIGHT := {KEY_LEFT:"left",KEY_RIGHT:"right",KEY_UP:"up",KEY_DOWN:"down",KEY_K:"light",KEY_L:"heavy",KEY_O:"skill",KEY_P:"grab",KEY_SEMICOLON:"jump",KEY_I:"dash",RSHIFT:"guard",KEY_KP_1:"light",KEY_KP_2:"heavy",KEY_KP_3:"skill",KEY_KP_4:"grab",KEY_KP_0:"jump",KEY_KP_6:"dash",KEY_KP_5:"guard"}
const LAYOUTS := {"kb_solo":KB_SOLO,"kb_left":KB_LEFT,"kb_right":KB_RIGHT}
const PAD_BUTTONS := {JOY_BUTTON_X:"light",JOY_BUTTON_Y:"heavy",JOY_BUTTON_B:"skill",JOY_BUTTON_A:"jump",JOY_BUTTON_RIGHT_SHOULDER:"dash",JOY_BUTTON_LEFT_SHOULDER:"grab",JOY_BUTTON_DPAD_LEFT:"left",JOY_BUTTON_DPAD_RIGHT:"right",JOY_BUTTON_DPAD_UP:"up",JOY_BUTTON_DPAD_DOWN:"down",JOY_BUTTON_START:"start"}
const STICK_DEADZONE := .35
const STICK_MODIFIER := .55
const TRIGGER_POINT := .5
const LEGEND := {"kb_solo":"WASD/ARROWS MOVE - J K L ATTACK - G THROW - SHIFT GUARD - E DODGE - SPACE JUMP","kb_left":"WASD MOVE - F LIGHT - G HEAVY - R BURST - T THROW - L-SHIFT GUARD - E DODGE - SPACE JUMP","kb_right":"ARROWS MOVE - K LIGHT - L HEAVY - O BURST - P THROW - R-SHIFT GUARD - I DODGE - ; JUMP (NUMPAD 1 2 3 4 5 6 0)","pad":"STICK/D-PAD MOVE - X LIGHT - Y HEAVY - B BURST - LB THROW - LT/RT GUARD - RB DODGE - A JUMP - START PAUSE"}

const SHORT := {"kb_solo":"J RUSH  K LAUNCH  L SKILL  W+L SUPER","kb_left":"F RUSH  G LAUNCH  R SKILL  W+R SUPER","kb_right":"K RUSH  L LAUNCH  O SKILL  UP+O SUPER","pad":"X RUSH  Y LAUNCH  B SKILL  UP+B SUPER"}

var mode := "solo" # "solo": keyboard plus every pad drive P1. "versus": one device per player.
var wanted := [AUTO,AUTO]
var devices: Array = [{"kind":"kb_solo","id":-1},{"kind":"none","id":-1}]
var fallback := [false,false] # A requested gamepad is missing; keyboard is used instead.
var keys: Dictionary = {}
var pad_buttons: Dictionary = {}
var pad_axes: Dictionary = {}
var pads_override: Variant = null # Tests inject a pad list; null reads the OS list.

func pads() -> Array:
    var list: Array = pads_override.duplicate() if pads_override is Array else Array(Input.get_connected_joypads())
    list.sort()
    return list

func set_mode(value: String) -> void:
    var next := "versus" if value=="versus" else "solo"
    var changed := next!=mode
    mode = next
    assign(changed)

## fresh=false keeps a still-connected gamepad with the player already holding it,
## so unplugging one pad mid-match never hands the other pad to the wrong player.
func assign(fresh := false) -> void:
    var free: Array = pads()
    fallback = [false,false]
    if mode!="versus":
        devices = [{"kind":"kb_solo","id":-1},{"kind":"none","id":-1}]
        return
    var chosen := [{},{}]
    if not fresh:
        for side in 2:
            if devices[side].kind=="pad" and devices[side].id in free and wanted[side]!=KEYBOARD:
                chosen[side]=devices[side].duplicate();free.erase(devices[side].id)
    for side in 2:
        if wanted[side]==GAMEPAD and chosen[side].is_empty():
            if free.is_empty():fallback[side]=true
            else:chosen[side]={"kind":"pad","id":free.pop_front()}
    var automatic: Array = []
    for side in 2:
        if wanted[side]==AUTO and chosen[side].is_empty():automatic.append(side)
    # A single spare pad goes to P2, so P1 keeps the keyboard layout already learned in Story.
    if automatic.size()==2 and free.size()==1:automatic.reverse()
    for side in automatic:
        if not free.is_empty():chosen[side]={"kind":"pad","id":free.pop_front()}
    var typing: Array = []
    for side in 2:
        if chosen[side].is_empty():typing.append(side)
    for side in typing:
        chosen[side]={"kind":"kb_solo" if typing.size()==1 else ("kb_left" if side==0 else "kb_right"),"id":-1}
    devices = chosen

func key_id(event: InputEventKey) -> int:
    var code: int = event.physical_keycode if event.physical_keycode!=0 else event.keycode
    if code==KEY_SHIFT:return RSHIFT if event.location==KEY_LOCATION_RIGHT else LSHIFT
    return code

func is_bound_key(event: InputEventKey) -> bool:
    if mode!="versus":return false
    var id := key_id(event)
    for side in 2:
        if LAYOUTS.has(devices[side].kind) and LAYOUTS[devices[side].kind].has(id):return true
    return false

func side_for_pad(device: int) -> int:
    if mode!="versus":return 0 if device in pads() else -1
    for side in 2:
        if devices[side].kind=="pad" and devices[side].id==device:return side
    return -1

func uses_pad(device: int) -> bool:
    return side_for_pad(device)>=0

## Updates held state and returns fresh presses as {"side","action","pad"}.
func feed(event: InputEvent) -> Array:
    var presses: Array = []
    if event is InputEventKey:
        var id := key_id(event)
        if event.pressed:keys[id]=true
        else:keys.erase(id)
        if mode=="versus" and event.pressed and not event.echo:
            for side in 2:
                var layout: Dictionary = LAYOUTS.get(devices[side].kind,{})
                if layout.has(id):presses.append({"side":side,"action":layout[id],"pad":false})
    elif event is InputEventJoypadButton:
        if not pad_buttons.has(event.device):pad_buttons[event.device]={}
        var was: bool = pad_buttons[event.device].get(event.button_index,false)
        if event.pressed:pad_buttons[event.device][event.button_index]=true
        else:pad_buttons[event.device].erase(event.button_index)
        var side := side_for_pad(event.device)
        if event.pressed and not was and side>=0 and PAD_BUTTONS.has(event.button_index):
            presses.append({"side":side,"action":PAD_BUTTONS[event.button_index],"pad":true})
    elif event is InputEventJoypadMotion:
        if not pad_axes.has(event.device):pad_axes[event.device]={}
        var before: float = pad_axes[event.device].get(event.axis,0.0)
        pad_axes[event.device][event.axis]=event.axis_value
        var side := side_for_pad(event.device)
        if side>=0:
            if event.axis in [JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT] and before<TRIGGER_POINT and event.axis_value>=TRIGGER_POINT:
                presses.append({"side":side,"action":"guard","pad":true})
            elif event.axis==JOY_AXIS_LEFT_Y and before<STICK_MODIFIER and event.axis_value>=STICK_MODIFIER:
                presses.append({"side":side,"action":"down","pad":true})
    return presses

func _pad_held(device: int) -> Dictionary:
    var buttons: Dictionary = pad_buttons.get(device,{})
    var axes: Dictionary = pad_axes.get(device,{})
    var x: float = axes.get(JOY_AXIS_LEFT_X,0.0)
    var y: float = axes.get(JOY_AXIS_LEFT_Y,0.0)
    var axis := float(buttons.has(JOY_BUTTON_DPAD_RIGHT))-float(buttons.has(JOY_BUTTON_DPAD_LEFT))
    if absf(x)>=STICK_DEADZONE:axis=signf(x)
    return {"axis":axis,"up":buttons.has(JOY_BUTTON_DPAD_UP) or y<=-STICK_MODIFIER,"down":buttons.has(JOY_BUTTON_DPAD_DOWN) or y>=STICK_MODIFIER,"guard":axes.get(JOY_AXIS_TRIGGER_LEFT,0.0)>=TRIGGER_POINT or axes.get(JOY_AXIS_TRIGGER_RIGHT,0.0)>=TRIGGER_POINT,"light":buttons.has(JOY_BUTTON_X),"skill":buttons.has(JOY_BUTTON_B)}

func _keyboard_held(layout: Dictionary) -> Dictionary:
    var down: Dictionary = {}
    for id in layout:
        if keys.has(id):down[layout[id]]=true
    return {"axis":float(down.has("right"))-float(down.has("left")),"up":down.has("up"),"down":down.has("down"),"guard":down.has("guard"),"light":down.has("light"),"skill":down.has("skill")}

## Held state from the devices this module owns. In solo mode that is every pad;
## the original keyboard polling in fight_session.gd stays the keyboard owner.
func held(side: int) -> Dictionary:
    var result := {"axis":0.0,"up":false,"down":false,"guard":false,"light":false,"skill":false}
    if mode!="versus":
        if side!=0:return result
        for device in pads():
            var state := _pad_held(device)
            if state.axis!=0.0:result.axis=state.axis
            for key in ["up","down","guard","light","skill"]:result[key]=result[key] or state[key]
        return result
    var device: Dictionary = devices[side]
    if device.kind=="pad":return _pad_held(device.id)
    if LAYOUTS.has(device.kind):return _keyboard_held(LAYOUTS[device.kind])
    return result

func release_all() -> void:
    keys.clear();pad_buttons.clear();pad_axes.clear()

func forget_pad(device: int) -> void:
    pad_buttons.erase(device);pad_axes.erase(device)

func describe(side: int) -> String:
    var device: Dictionary = devices[side]
    var label: String = {"kb_solo":"KEYBOARD","kb_left":"KEYBOARD LEFT (WASD)","kb_right":"KEYBOARD RIGHT (ARROWS)","none":"-"}.get(device.kind,"GAMEPAD %d"%(pads().find(device.id)+1))
    if fallback[side]:label+=" / NO GAMEPAD FOUND"
    return label

func legend(side: int) -> String:
    return LEGEND.get(devices[side].kind,"")

func short_legend(side: int) -> String:
    return SHORT.get(devices[side].kind,"")
