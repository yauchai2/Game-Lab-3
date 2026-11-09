extends SceneTree
var checks: Array[Dictionary] = []
func _initialize() -> void:
    call_deferred("run")
func check(label: String, condition: bool) -> void:
    checks.append({"name":label,"passed":condition})
    if not condition: push_error("INPUT FAIL: "+label)
func key(code: Key, down: bool) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.physical_keycode = code
    event.pressed = down
    Input.parse_input_event(event)
func tap(code: Key) -> void:
    key(code,true)
    await process_frame
    key(code,false)
    await process_frame
func frames(count: int) -> void:
    for i in count: await physics_frame
func run() -> void:
    var scene := preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    current_scene = scene
    await frames(3)
    await tap(KEY_ENTER)
    check("native keyboard starts match from title",scene.screen=="play")
    scene.sim.ai_enabled = false
    await frames(75)
    var old_x: float = scene.sim.fighters[0].x
    key(KEY_D,true)
    await frames(12)
    key(KEY_D,false)
    await frames(2)
    check("held physical movement key moves fighter",scene.sim.fighters[0].x>old_x+0.6)
    await tap(KEY_SPACE)
    await frames(3)
    check("jump key reaches gameplay",scene.sim.fighters[0].y>0.1)
    await tap(KEY_K)
    await frames(3)
    check("airborne K selects accessible meteor",scene.sim.fighters[0].move=="meteor")
    await tap(KEY_ESCAPE)
    check("escape pauses through viewport input",scene.screen=="pause")
    var ticks: int = scene.sim.tick_count
    await frames(8)
    check("pause freezes simulation clock",scene.sim.tick_count==ticks)
    await tap(KEY_M)
    check("mute shortcut works in pause",scene.audio.muted)
    await tap(KEY_F2)
    check("reduced-effects shortcut works in pause",scene.reduced_effects)
    await tap(KEY_ESCAPE)
    check("escape resumes through viewport input",scene.screen=="play")
    await tap(KEY_F6)
    await frames(4)
    check("F6 switches to preserved walk scene",current_scene.name=="StreetWalk")
    await tap(KEY_F6)
    await frames(4)
    check("walk F6 returns to fight title",current_scene.name=="StreetFight" and current_scene.screen=="title")
    var arena=current_scene
    arena.set_process(false)
    arena.set_physics_process(false)
    arena.audio.muted=true
    arena.start_match(true)
    arena.sim.fighters[0].x=-.45
    arena.sim.fighters[1].x=.45
    await tap(KEY_G)
    check("viewport G queues a throw",arena.pending.get("attack","")=="grab")
    for i in 12:arena._physics_process(1.0/60)
    check("native throw input reaches the real contact and damage rule",arena.sim.fighters[1].health==88)
    arena.reset_training()
    arena.sim.fighters[0].x=-.45
    arena.sim.fighters[1].x=.45
    arena.sim.fighters[1].state="attack"
    arena.sim.fighters[1].move="grab"
    arena.sim.fighters[1].frame=10
    await tap(KEY_G)
    arena._physics_process(1.0/60)
    check("viewport G also breaks an incoming throw without damage",arena.sim.fighters[0].health==100 and arena.sim.fighters[1].health==100 and arena.sim.events.any(func(e:Dictionary)->bool:return e.kind=="throw_tech"))
    arena.reset_training()
    arena.sim.training=false # Resource checks must not use infinite practice energy.
    var player: Dictionary=arena.sim.fighters[0]
    player.x=8.19
    player.y=.4
    player.vx=10
    player.state="stun"
    player.stun=30
    player.meter=40
    arena._physics_process(1.0/60)
    await tap(KEY_E)
    arena._physics_process(1.0/60)
    check("viewport E performs edge recovery and spends exactly twenty energy",player.state=="dash" and player.meter==20 and player.vx<0 and arena.sim.events.any(func(e:Dictionary)->bool:return e.kind=="wall_tech"))
    current_scene.queue_free()
    await frames(3)
    # AudioServer releases stopped playbacks on its mixer thread.
    await create_timer(0.10).timeout
    var failed := checks.filter(func(c: Dictionary)->bool: return not c.passed).size()
    var file := FileAccess.open("res://../docs/evidence/combat/input-verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"method":"Input.parse_input_event through native viewport; automated, not human keyboard playtest"},"  "))
    file.close()
    print("COMBAT_INPUT_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(0 if failed==0 else 1)
