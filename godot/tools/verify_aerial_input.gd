extends SceneTree
var scene: Node
var checks: Array[Dictionary]=[]
var framing: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label: String, value: bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("AIR INPUT FAIL: "+label)
func key(code: Key, down: bool) -> void:
    var event:=InputEventKey.new()
    event.keycode=code;event.physical_keycode=code;event.pressed=down
    Input.parse_input_event(event)
    await process_frame
    await process_frame
func step(count:=1) -> void:
    for i in count:
        scene._physics_process(1.0/60)
        scene._process(1.0/60)
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false)
    scene.audio.muted=true
    scene.sim.partner_mode=1
    await key(KEY_F11,true);await key(KEY_F11,false)
    check("air dojo starts with a launchable standing partner",scene.sim.partner_mode==0)
    check("viewport F11 enters exclusive aerial practice",scene.screen=="play" and scene.sim.is_aerial() and not scene.sim.rally_enabled and not scene.sim.pressure_drill)
    await key(KEY_SPACE,true)
    step()
    check("viewport Space begins the three tick load",scene.sim.fighters[0].state=="jump_squat" and scene.sim.fighters[0].y==0)
    step(2)
    check("load stays on ground for all three ticks",scene.sim.fighters[0].y==0)
    step()
    check("fourth physical tick takes off",scene.sim.fighters[0].y>0)
    step(65)
    check("holding native Space cannot auto repeat jumps",scene.sim.fighters[0].y==0 and scene.sim.fighters[0].state=="idle")
    await key(KEY_SPACE,false)
    await key(KEY_SPACE,true);await key(KEY_SPACE,false)
    step(24)
    var frozen: Array=scene.sim.fighters.duplicate(true)
    scene.pause_game()
    step(4)
    check("pause preserves air budgets and positions",scene.sim.fighters==frozen)
    await key(KEY_S,true)
    scene.resume_game()
    step()
    check("S pressed while paused is not an automatic fast fall",not scene.sim.fighters[0].air.fast)
    await key(KEY_S,false);await key(KEY_S,true);await key(KEY_S,false)
    step()
    check("new viewport S activates fast fall",scene.sim.fighters[0].air.fast and scene.sim.fighters[0].vy<=-18)
    step(20)
    scene.prime_air_drill()
    await key(KEY_W,true);await key(KEY_K,true);await key(KEY_K,false);await key(KEY_W,false)
    step()
    check("viewport W K selects launcher in air lab",scene.sim.fighters[0].move=="launcher")
    for i in 25:
        step()
        if scene.sim.events.any(func(e:Dictionary)->bool:return e.kind=="hit"):break
    check("native launcher actually confirms",scene.sim.fighters[0].hit_confirmed and scene.sim.fighters[0].air.chase_window>0)
    await key(KEY_E,true);await key(KEY_E,false)
    step()
    while scene.sim.hitstop>0:step()
    step()
    check("viewport E buffers into ten tick physical chase",scene.sim.fighters[0].state=="chase" and scene.sim.fighters[0].meter<100)
    step(10)
    check("native chase arrives without a free hit",scene.sim.fighters[0].state=="idle" and scene.sim.fighters[1].health==86)
    await key(KEY_J,true);await key(KEY_J,false)
    step()
    check("viewport J chooses air jab",scene.sim.fighters[0].move=="air_jab")
    for move in ["air_jab","air_kick","air_finisher"]:
        var connected:=false
        for i in 50:
            step()
            if scene.sim.events.any(func(e:Dictionary)->bool:return e.kind=="hit" and e.move==move):connected=true;break
        check("native chain contacts "+move,connected)
        if move!="air_finisher":await key(KEY_J,true);await key(KEY_J,false)
    check("native chain records real combo damage",scene.sim.last_combo_hits>=4 and scene.sim.last_combo_damage>14)
    scene.prime_air_drill()
    await key(KEY_SPACE,true);await key(KEY_SPACE,false)
    step(18)
    await key(KEY_S,true);await key(KEY_K,true);await key(KEY_K,false);await key(KEY_S,false)
    step()
    check("viewport down K selects meteor",scene.sim.fighters[0].move=="meteor")
    scene.prime_air_drill()
    scene.sim.fighters[0].y=2
    scene.sim.fighters[0].air.phase="apex"
    scene._present(.1)
    check("original apex key pose is presented",scene.fighters[0].motions.air_pose_name=="Air_Apex_Swagger")
    var regular_scale: Vector3=scene.fighters[0].model.scale
    await key(KEY_F2,true);await key(KEY_F2,false)
    scene._process(.01)
    check("F2 removes exaggerated air stretch",scene.reduced_effects and scene.fighters[0].model.scale.is_equal_approx(Vector3.ONE*2.1) and not regular_scale.is_equal_approx(scene.fighters[0].model.scale))
    check("F2 preserves a readable key pose",scene.fighters[0].motions.air_pose_name=="Air_Apex_Swagger")
    scene.pause_game();scene.hud.open_page("settings")
    scene.set_partner_mode(1)
    check("partner setting keeps air scenario and pause",scene.sim.is_aerial() and scene.screen=="pause" and scene.sim.partner_mode==1)
    scene.hud.close_page();scene.resume_game();scene.sim.partner_mode=0
    await key(KEY_F5,true);await key(KEY_F5,false)
    check("F5 exits experiment and clears all air budgets",not scene.sim.is_aerial() and scene.sim.fighters[0].air.combo_left==0 and scene.sim.fighters[0].air.stall_left==12)
    await key(KEY_F10,true);await key(KEY_F10,false)
    check("existing F10 lab remains available",scene.sim.rally_enabled)
    await key(KEY_F11,true);await key(KEY_F11,false)
    check("switching F10 to F11 clears the rally",scene.sim.is_aerial() and not scene.sim.rally_enabled and not scene.sim.rally.active())
    scene.reduced_effects=false
    for extent in [Vector2i(1280,720),Vector2i(960,540),Vector2i(960,720)]:
        root.size=extent
        for i in 4:await process_frame
        var safe:=true
        for pair in [[-8.2,-7.4],[-8.2,8.2],[-.75,.75],[7.4,8.2]]:
            for altitude in [0.0,2.18,4.5]:
                scene.sim.fighters[0].x=pair[0];scene.sim.fighters[1].x=pair[1]
                scene.sim.fighters[0].y=altitude;scene.sim.fighters[1].y=0
                for f in scene.sim.fighters:f.vy=0
                for i in 8:scene._present(1.0)
                var body_safe:=true
                var points: Array=[]
                for f in scene.sim.fighters:
                    for height in [0.0,2.4]:
                        var point: Vector2=scene.project(Vector2(f.x,f.y+height))
                        points.append(str(point))
                        body_safe=body_safe and point.x>24 and point.x<1256 and point.y>105 and point.y<545
                framing.append({"viewport":str(extent),"pair":pair,"altitude":altitude,"safe":body_safe,"points":points})
                safe=safe and body_safe
        check("air camera keeps both envelopes visible "+str(extent),safe)
    scene.return_to_title()
    for language in ["zh","en"]:
        scene.set_language(language)
        for i in 4:await process_frame
        check("five title entries still fit without forced scrolling "+language,scene.hud.menu_scroll.get_v_scroll_bar().max_value<=scene.hud.menu_scroll.size.y+2)
    scene.queue_free()
    for i in 3:await process_frame
    var failed:=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    var file:=FileAccess.open("res://../docs/evidence/aerial-street/input.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"framing":framing,"display":DisplayServer.get_name(),"method":"viewport Input.parse_input_event plus manual 60Hz actual session steps; not human play or realtime performance"},"  "))
    print("AIR_INPUT_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(1 if failed else 0)
