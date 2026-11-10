extends SceneTree
var scene: Node
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, value: bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("AIR COUNTER INPUT FAIL: "+label)
func key(code: Key) -> void:
    var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true
    Input.parse_input_event(event)
    await process_frame
    event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false
    Input.parse_input_event(event)
    await process_frame
func step(count:=1) -> void:
    for i in count:
        scene._physics_process(1.0/60)
        scene._process(1.0/60)
    scene.hud._process(0)
func parry_lesson() -> void:
    scene.prime_air_defense()
    scene.pending["lesson_start"]=true
    step()
    step(8)
    scene.pending["guard_pressed"]=true
    for i in 4:
        step()
        if scene.sim.air_counter.active():break
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    await key(KEY_F11);step()
    check("F11 retains ordinary air practice",scene.sim.practice_scenario=="air")
    await key(KEY_F8);step()
    check("context F8 enters read-first counter lesson",scene.sim.is_air_lesson() and scene.sim.air_lesson_stage=="read")
    check("lesson exposes native Start and free-air return",scene.hud.air_begin.visible and scene.hud.air_lesson.visible and not scene.hud.air_parry.visible)
    var before: Array=scene.sim.fighters.duplicate(true)
    step(120)
    check("lesson can be read indefinitely without falling",scene.sim.fighters==before)
    await key(KEY_K);step();step(8)
    check("native K starts the real finisher",scene.sim.fighters[1].move=="air_finisher" and scene.sim.fighters[1].frame==8)
    check("native parry is enabled in a valid attack window",scene.hud.air_parry.visible and not scene.hud.air_parry.disabled)
    await key(KEY_SHIFT)
    for i in 4:
        step()
        if scene.sim.air_counter.active():break
    check("native Shift really intercepts the incoming hit",scene.sim.air_counter.active() and scene.sim.fighters[0].health==100 and scene.sim.fighters[0].meter==75)
    check("held contact shows two native choices",scene.hud.air_choices.all(func(b:Button)->bool:return b.visible and not b.disabled))
    check("parry has a distinct original key pose",scene.fighters[0].motions.air_pose_name=="Air_Parry_Stomp")
    before=scene.sim.fighters.duplicate(true)
    var age: int=scene.sim.air_counter.age
    scene.pause_game();step(8)
    check("pause freezes the counter and both logical bodies",scene.sim.air_counter.age==age and scene.sim.fighters==before)
    check("pause hides gameplay choice buttons",scene.hud.air_choices.all(func(b:Button)->bool:return not b.visible))
    scene.resume_game();step()
    check("resume returns to the same reversal",scene.sim.air_counter.active() and scene.sim.air_counter.owner==0)
    scene.hud.air_choices[0].pressed.emit()
    scene.hud.air_choices[1].pressed.emit()
    step()
    check("pointer uses the same first valid commitment",scene.sim.air_counter.choice=="kick" and scene.hud.air_choices.all(func(b:Button)->bool:return b.disabled))
    check("locked choice gets a visible selected skin",scene.hud.air_choice_skin[0]==1)
    for i in 45:
        step()
        if not scene.sim.air_counter.active():break
    check("pointer kick causes eighteen real damage",scene.sim.fighters[1].health==82 and scene.sim.air_lesson_stage=="review")
    check("review offers an explicit retry",scene.hud.air_begin.visible)
    await key(KEY_K);step()
    check("native retry restores resources and starts fresh",scene.sim.fighters[0].meter==100 and scene.sim.air_lesson_stage=="attack" and scene.sim.fighters[1].frame==0)
    parry_lesson()
    await key(KEY_E);step()
    for i in scene.sim.air_counter.HOLD+2:
        step()
        if not scene.sim.air_counter.active():break
    check("native E chooses safe escape without damage",scene.sim.air_counter.reason=="escape" and scene.sim.fighters[1].health==100)
    check("escape leaves no held counter core",not scene.effects.any(func(e:Dictionary)->bool:return e.kind=="air_counter_core"))
    parry_lesson()
    scene.hud.air_choices[0].pressed.emit();step()
    scene.reduced_effects=true;scene._process(.01)
    check("F2 suppresses grade and model stretch during reversal",not scene.grade.visible and scene.fighters[0].model.scale.is_equal_approx(Vector3.ONE*2.1))
    check("F2 keeps the core and choice information",scene.effects.any(func(e:Dictionary)->bool:return e.kind=="air_counter_core") and scene.hud.air_choices[0].visible)
    await key(KEY_F11);step()
    check("F11 exits lesson and reversal cleanly",scene.sim.practice_scenario=="air" and not scene.sim.air_counter.active() and not scene.effects.any(func(e:Dictionary)->bool:return e.kind=="air_counter_core"))
    scene.hud.air_lesson.pressed.emit();step()
    check("pointer can also enter the lesson",scene.sim.is_air_lesson())
    scene.hud.air_begin.pressed.emit();step();step(8)
    scene.hud.air_parry.pressed.emit();step(4)
    check("pointer parry uses the widened twelve tick rule",scene.sim.air_counter.active() and scene.sim.fighters[0].meter==75)
    await key(KEY_F5);step()
    check("F5 clears lesson and return windows",not scene.sim.is_aerial() and not scene.sim.air_counter.active())
    scene.prime_air_defense();scene.pause_game();scene.hud.open_page("settings")
    check("settings pauses a ready lesson",scene.screen=="pause" and scene.sim.air_lesson_stage=="read")
    scene.hud.close_page();scene.resume_game()
    parry_lesson()
    scene.return_to_title();scene._process(.01)
    check("title clears reversal clocks core grade and choices",not scene.sim.air_counter.active() and scene.effects.is_empty() and not scene.grade.visible and scene.pending.is_empty())
    scene.start_match(true)
    for language in ["zh","en"]:
        scene.set_language(language);parry_lesson()
        for extent in [Vector2i(1280,720),Vector2i(960,540),Vector2i(960,720)]:
            root.size=extent
            for i in 4:await process_frame
            scene.hud._process(0)
            var bounds: Vector2=scene.hud.get_viewport_rect().size
            var fit:=true
            for button in scene.hud.air_choices:
                var rect: Rect2=button.get_global_rect()
                fit=fit and rect.end.x<=bounds.x and rect.end.y<=bounds.y and rect.position.x>=0 and rect.position.y>=0
            check("choices fit viewport "+language+str(extent),fit)
    scene.queue_free()
    for i in 3:await process_frame
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/air-reversal/input.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"display":DisplayServer.get_name(),"method":"native viewport key events and native Button callbacks through the real session and 60Hz simulation; not human feel/target GPU"},"  "))
    print("AIR_COUNTER_INPUT_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(1 if failed else 0)
