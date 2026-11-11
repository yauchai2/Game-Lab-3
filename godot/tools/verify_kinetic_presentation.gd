extends SceneTree
var scene: Node
var checks: Array[Dictionary]=[]
var folder:="res://../docs/evidence/kinetic-overdrive/presentation"
func _initialize() -> void:call_deferred("run")
func check(label: String, value: bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("KINETIC PRESENTATION FAIL: "+label)
func key(code: Key, down: bool) -> void:
    var event:=InputEventKey.new()
    event.keycode=code
    event.physical_keycode=code
    event.pressed=down
    Input.parse_input_event(event)
    await process_frame
    await process_frame
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene)
    current_scene=scene
    scene.set_process(false)
    scene.set_physics_process(false)
    scene.audio.muted=true
    await key(KEY_F10,true)
    await key(KEY_F10,false)
    check("viewport F10 enters real rally practice",scene.practice and scene.sim.rally_enabled and scene.sim.rally_drill and scene.screen=="play")
    check("rally entry never opens legacy choices",not scene.sim.exchange.active() and scene.hud.choice_buttons.all(func(b:Button)->bool:return not b.visible))
    scene.sim.rally_drill=false
    scene.sim.fighters[1].state="attack"
    scene.sim.fighters[1].move="jab"
    scene.sim.fighters[1].frame=4
    await key(KEY_SHIFT,true)
    scene._physics_process(1.0/60)
    check("viewport new Shift opens real parry rally",scene.sim.rally.active() and scene.sim.rally.owner==0)
    await key(KEY_SHIFT,false)
    await key(KEY_J,true)
    await key(KEY_J,false)
    scene._physics_process(1.0/60)
    check("viewport J commits the counter",scene.sim.rally.chosen)
    scene._process(.02)
    scene.pause_game()
    var tick: int=scene.sim.tick_count
    var age: float=scene.spectacle.age
    scene._physics_process(1.0/60)
    scene._process(.3)
    check("pause freezes both rule and visual clocks",scene.sim.tick_count==tick and scene.spectacle.age==age)
    scene.resume_game()
    scene._physics_process(1.0/60)
    check("resume keeps the same commitment",scene.sim.rally.active() and scene.sim.rally.chosen)
    scene.sim.rally.tier=4
    scene._process(.02)
    check("high tier enables scoped world grade",scene.grade.visible)
    check("grade is below the untouched HUD",scene.grade.get_parent().layer<scene.hud.get_parent().layer)
    check("echo captures actual posed skeleton segments",scene.fighters[0].capture_echo().size()==10)
    scene._spawn_vfx("echo",Vector2.ZERO,.18,{"bones":scene.fighters[0].capture_echo()})
    scene.reduced_effects=true
    scene._process(.02)
    check("reduced effects immediately disables world grade",not scene.grade.visible)
    check("reduced effects has no camera kick",scene.spectacle.camera_punch(true)==0)
    for i in 100:scene._spawn_vfx("dust",Vector2.ZERO,.2)
    check("all cosmetic effects stay within sixty four",scene.effects.size()==64)
    scene.reset_training()
    check("training reset clears every visual pending effect",scene.effects.is_empty() and scene.impact_queue.is_empty() and scene.spectacle.mode=="" and not scene.grade.visible)
    check("training reset clears experimental state",not scene.sim.rally.active() and not scene.sim.rally_enabled)
    scene.start_match(false)
    scene.reduced_effects=false
    scene.sim.phase="fight"
    scene.sim.ai_enabled=false
    scene.sim.fighters[1].health=0
    scene._physics_process(1.0/60)
    check("KO is resolved before the visual finish",scene.screen=="result" and scene.sim.wins[0]==1 and scene.spectacle.mode=="finish")
    check("finish first shows action rather than the result menu",not scene.hud.menu.visible)
    var frozen: Array=scene.sim.fighters.duplicate(true)
    scene._process(.4)
    check("finish camera never changes simulation",scene.sim.fighters==frozen)
    check("finish camera is bounded",scene.camera.fov>=42 and scene.camera.fov<=48)
    scene._process(.5)
    check("finish presents operable result after point eight two seconds",scene.hud.menu.visible and scene.finish_menu_open)
    scene.advance_round()
    check("next round resets camera and grade",is_equal_approx(scene.camera.fov,48) and not scene.grade.visible and scene.spectacle.mode=="")
    scene.sim.phase="fight"
    scene.sim.fighters[1].health=0
    scene._physics_process(1.0/60)
    await key(KEY_ENTER,true)
    await key(KEY_ENTER,false)
    check("viewport Enter skips the finish and advances once",scene.screen=="play" and scene.sim.phase=="ready" and scene.sim.round_number==1 and scene.sim.wins==[0,0])
    check("skip cannot buffer a following attack",scene.pending.is_empty())
    scene.prime_rally_drill() # Ignored outside practice.
    check("formal match cannot enable rally from prime call",not scene.sim.rally_enabled)
    scene.start_match(true)
    scene.prime_rally_drill()
    scene._handle_event({"kind":"rally_contact","owner":0,"tier":4})
    scene.return_to_title()
    scene._process(.02)
    check("title clears grade core clock and rule state",not scene.grade.visible and scene.spectacle.mode=="" and scene.effects.is_empty() and not scene.sim.rally.active())
    for language in ["zh","en"]:
        scene.set_language(language)
        for extent in [Vector2i(960,540),Vector2i(1280,720),Vector2i(960,720)]:
            root.size=extent
            for i in 5:await process_frame
            var rect: Rect2=scene.hud.menu.get_global_rect()
            var bounds: Vector2=scene.hud.get_viewport_rect().size
            check("menu fits viewport "+language+str(extent),rect.end.x<=bounds.x+2 and rect.end.y<=bounds.y+2 and rect.position.x>=0 and rect.position.y>=0)
            check("main actions do not require scroll "+language+str(extent),scene.hud.menu_scroll.get_v_scroll_bar().max_value<=scene.hud.menu_scroll.size.y+2)
    scene.queue_free()
    for i in 3:await process_frame
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open(folder+"/verification.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"total":checks.size(),"display":DisplayServer.get_name()},"  "))
    print("KINETIC_PRESENTATION_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(1 if failed else 0)
