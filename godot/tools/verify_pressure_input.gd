extends SceneTree
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("PRESSURE INPUT FAIL: "+label)
func tap(code: Key) -> void:
    var event:=InputEventKey.new()
    event.keycode=code
    event.physical_keycode=code
    event.pressed=true
    Input.parse_input_event(event)
    await process_frame
    event=event.duplicate()
    event.pressed=false
    Input.parse_input_event(event)
    await process_frame
func run() -> void:
    var scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    current_scene=scene
    scene.set_physics_process(false)
    scene.set_process(false)
    scene.audio.muted=true
    await process_frame
    await tap(KEY_T)
    check("viewport T starts training",scene.practice and scene.screen=="play")
    await tap(KEY_F8)
    check("viewport F8 primes pressure drill",scene.sim.exchange.pressure==60 and scene.sim.fighters[0].x==-.8)
    await tap(KEY_K)
    for i in 17:
        scene._physics_process(1.0/60)
        scene._process(1.0/60)
    check("viewport K opens actual heavy clash",scene.sim.exchange.active())
    await tap(KEY_SHIFT)
    scene._physics_process(1.0/60)
    check("viewport Shift chooses turn without normal attack input",scene.sim.exchange.clash.choices[0]=="turn" and scene.sim.fighters[0].buffer=="")
    await tap(KEY_J)
    scene._physics_process(1.0/60)
    check("viewport repeated choice cannot replace commitment",scene.sim.exchange.clash.choices[0]=="turn")
    await tap(KEY_ESCAPE)
    var left: int=scene.sim.exchange.clash.remaining
    scene._physics_process(1.0/60)
    scene._process(.2)
    check("viewport Escape freezes active deadline",scene.screen=="pause" and scene.sim.exchange.clash.remaining==left)
    await tap(KEY_F2)
    check("viewport F2 works during paused clash",scene.reduced_effects and scene.sim.exchange.active())
    await tap(KEY_ESCAPE)
    check("viewport Escape resumes same choice",scene.screen=="play" and scene.sim.exchange.clash.choices[0]=="turn")
    for i in left:
        scene._physics_process(1.0/60)
        scene._process(1.0/60)
    check("viewport decision resolves as player turn win",scene.sim.exchange.last_result.winner==0 and scene.sim.fighters[1].health==84 and scene.sim.exchange.pressure==0)
    check("outcome stays readable after hit event",scene.hud.notice=="YOU / TURN")
    await tap(KEY_F8)
    check("viewport F8 clears prior result and impact effects",scene.sim.exchange.last_result.is_empty() and scene.impact_queue.is_empty() and scene.effects.is_empty())
    scene.queue_free()
    await process_frame
    await create_timer(.15).timeout
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/pressure-exchange/input-verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"method":"X11 Godot viewport Input.parse_input_event; not a physical keyboard or human playtest"},"  "))
    print("PRESSURE_INPUT_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
