extends SceneTree
## Real X11 focus changes, not a direct call to the application's notification.
const FOCUS_PYTHON:="""
import ctypes, sys
x=ctypes.CDLL('libX11.so.6')
x.XOpenDisplay.argtypes=[ctypes.c_char_p]; x.XOpenDisplay.restype=ctypes.c_void_p
x.XDefaultRootWindow.argtypes=[ctypes.c_void_p]; x.XDefaultRootWindow.restype=ctypes.c_ulong
x.XSetInputFocus.argtypes=[ctypes.c_void_p,ctypes.c_ulong,ctypes.c_int,ctypes.c_ulong]
x.XSync.argtypes=[ctypes.c_void_p,ctypes.c_int]
x.XCloseDisplay.argtypes=[ctypes.c_void_p]
d=x.XOpenDisplay(None)
assert d, 'X11 display unavailable'
w=int(sys.argv[1]) or x.XDefaultRootWindow(d)
x.XSetInputFocus(d,w,2,0)
x.XSync(d,0)
x.XCloseDisplay(d)
"""
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("FOCUS FLOW FAIL: "+label)
func focus_window(handle: int) -> void:
    var output: Array=[]
    var code:=OS.execute("python",["-c",FOCUS_PYTHON,str(handle)],output,true)
    if code!=0:push_error("X11 focus helper: "+str(output))
func frames(count := 3) -> void:
    for i in count:await process_frame
func escape() -> void:
    var event:=InputEventKey.new()
    event.keycode=KEY_ESCAPE
    event.physical_keycode=KEY_ESCAPE
    event.pressed=true
    Input.parse_input_event(event)
    await frames(1)
    event=event.duplicate()
    event.pressed=false
    Input.parse_input_event(event)
    await frames()
func run() -> void:
    if DisplayServer.get_name()!="X11":
        push_error("This focus fixture requires an X11 native Godot window.")
        quit(2)
        return
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    scene.audio.muted=true
    var handle: int=DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE)
    focus_window(handle)
    await frames()
    scene.start_match(true)
    await frames()
    check("Godot owns actual X11 keyboard focus before the test",DisplayServer.window_is_focused())
    focus_window(0)
    await frames()
    check("leaving the OS window pauses active gameplay",scene.screen=="pause")
    var ticks: int=scene.sim.tick_count
    await create_timer(.25).timeout
    check("simulation stays frozen while the application is unfocused",scene.sim.tick_count==ticks)
    focus_window(handle)
    await frames()
    check("returning OS focus keeps the pause menu open",scene.screen=="pause" and DisplayServer.window_is_focused())
    await escape()
    check("Escape explicitly resumes the same game after focus returns",scene.screen=="play" and scene.sim.tick_count>ticks)
    scene.prime_pressure_drill()
    scene.pending["attack"]="heavy"
    for i in 17:scene._physics_process(1.0/60)
    focus_window(0)
    await frames()
    var remaining: int=scene.sim.exchange.clash.get("remaining",-1)
    await create_timer(.25).timeout
    check("OS focus loss freezes an active clash deadline",scene.screen=="pause" and scene.sim.exchange.active() and scene.sim.exchange.clash.remaining==remaining)
    focus_window(handle)
    await frames()
    check("focus return cannot silently consume or resume the clash",scene.screen=="pause" and scene.sim.exchange.active() and scene.sim.exchange.clash.remaining==remaining)
    scene.queue_free()
    await frames(4)
    await RenderingServer.frame_post_draw
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/extended-polish/focus-flow.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"method":"X11 XSetInputFocus away/from native window plus Godot viewport Escape; no direct notification call"},"  "))
    print("FOCUS_FLOW_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
