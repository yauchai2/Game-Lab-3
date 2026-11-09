extends SceneTree
var scene: Node
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("FRIENDLY INPUT FAIL: "+label)
func key(code:Key,down:bool) -> void:
    var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down
    Input.parse_input_event(e);await process_frame;await process_frame
func step(n:=1) -> void:
    for i in n:scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
func shot(name:String) -> void:
    await process_frame;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://../docs/evidence/friendly-defense/"+name+".png")
func setup(frame:int) -> void:
    scene.start_match(false);scene.sim.phase="fight";scene.sim.ai_enabled=false
    scene.sim.fighters[0].x=-.6;scene.sim.fighters[1].x=.6
    scene.sim.fighters[1].state="attack";scene.sim.fighters[1].move="heavy";scene.sim.fighters[1].frame=frame
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path="";root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    scene.backdrop.freeze_for_capture()
    await process_frame
    await process_frame
    setup(5)
    await key(KEY_SHIFT,true);step(11)
    check("native early Shift earns a real parry",scene.sim.fighters[0].counter_window==36 and scene.sim.fighters[0].health==100)
    check("parry toast tells player what to do next",scene.hud.notice=="PERFECT GUARD" and scene.hud.notice_time>0)
    check("localized counter prompt is positive",scene.hud.tr_text("counter_ready").contains("J"))
    await shot("01_parry_ready")
    scene.pause_game();var window: int=scene.sim.fighters[0].counter_window
    step(15)
    check("pause does not consume counter opportunity",scene.sim.fighters[0].counter_window==window)
    scene.resume_game()
    await key(KEY_J,true);step();await key(KEY_J,false)
    step(20)
    check("held Shift does not swallow the counter input",scene.sim.fighters[1].health==93)
    check("actual contact earns success feedback",scene.hud.notice=="COUNTER SUCCESS" and scene.hud.notice_time>0)
    await shot("02_counter_success")
    await key(KEY_SHIFT,false)
    setup(15);scene.sim.fighters[0].parry_cd=60
    await key(KEY_SHIFT,true);step();await key(KEY_SHIFT,false)
    check("ordinary block also gets positive feedback",scene.hud.notice=="NICE BLOCK" and scene.sim.fighters[0].health==100)
    await shot("03_nice_block")
    scene.start_match(true)
    check("restart clears counter hint and buffered attack",scene.sim.fighters[0].counter_window==0 and scene.sim.fighters[0].buffer=="")
    scene.prime_air_defense()
    scene.pending.lesson_start=true;step(2)
    check("dojo offers earlier visible parry access",scene.hud.air_parry.visible and not scene.hud.air_parry.disabled)
    scene.pending.guard_pressed=true;step(11)
    check("early air input succeeds before damage",scene.sim.air_counter.active() and scene.sim.fighters[0].health==100)
    check("air choice gets half a second",scene.sim.air_counter.HOLD==30)
    scene.reduced_effects=true;scene._process(.01);scene.hud._process(0)
    await shot("04_reduced_air_success")
    check("reduced effects retain native choice feedback",scene.hud.air_choices[0].visible and scene.hud.tr_text("air_reversal").contains("成功"))
    scene.return_to_title()
    check("exit clears feedback opportunity",not scene.sim.air_counter.active() and scene.sim.fighters[0].counter_window==0)
    var passed:=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open("res://../docs/evidence/friendly-defense/input.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"scope":"Native key dispatch and actual simulation contacts; controlled fixtures and manual 60Hz stepping, not human playtest."},"  "))
    scene.queue_free();await process_frame;await process_frame
    print("FRIENDLY_INPUT_CHECKS ",passed,"/",checks.size())
    call_deferred("quit",0 if passed==checks.size() else 1)
