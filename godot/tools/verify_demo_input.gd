extends SceneTree
var scene: Node
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,value:bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("LIVE INPUT FAIL: "+label)
func key(code:Key,down:=true) -> void:
    var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down
    Input.parse_input_event(e);await process_frame;await process_frame
func tap(code:Key) -> void:await key(code);await key(code,false)
func step(n:=1) -> void:
    for i in n:scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path=""
    root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    await process_frame;await process_frame
    scene.sim.partner_mode=2
    await tap(KEY_F12);step()
    check("F12 starts endless live combat",scene.demo!=null and scene.sim.endless and scene.sim.arcade_enabled)
    check("only restart and exit transport remain",scene.hud.demo_buttons.size()==2 and scene.hud.demo_buttons.all(func(b:Button)->bool:return b.visible))
    check("no player laboratory controls cover the demo",not scene.hud.air_lesson.visible and scene.hud.choice_buttons.all(func(b:Button)->bool:return not b.visible))
    var age: int=scene.demo.age
    await tap(KEY_N);await tap(KEY_J);await tap(KEY_F5);step()
    check("old Next and player keys cannot reset or control the fight",scene.demo.age==age+1 and scene.pending.is_empty())
    await tap(KEY_ESCAPE);age=scene.demo.age;step(15)
    check("pause freezes both autonomous agents",scene.screen=="pause" and scene.demo.age==age)
    await tap(KEY_ESCAPE);step()
    check("resume continues the same fight",scene.screen=="play" and scene.demo.age==age+1)
    var max_effects:=0
    var giant_seen:=false
    var stable_live:=true
    var previous_age:int=scene.demo.age
    for i in 1800:
        step();max_effects=maxi(max_effects,scene.effects.size())
        stable_live=stable_live and scene.demo.age>=previous_age and scene.demo.age-previous_age<=2
        previous_age=scene.demo.age
        giant_seen=giant_seen or scene.fighters.any(func(f:Node)->bool:return not f.oversized_bones.is_empty())
    check("native scene keeps fighting without KO pages or chapters",stable_live and scene.screen=="play" and scene.sim.phase=="fight" and scene.demo.age>600)
    check("both live agents hit naturally",scene.demo.hits[0]>10 and scene.demo.hits[1]>10)
    check("native demo includes chase and meteor payoff",scene.demo.seen.get("homing_chase",0)>5 and scene.demo.seen.get("hit/meteor",0)>2)
    check("effects remain bounded",max_effects<=64)
    check("active attacks really enlarge a hand or foot",giant_seen)
    check("new heavyweight effects actually spawn",scene.audio.sounds.has("slam") and scene.audio.sounds.has("launch"))
    await tap(KEY_R);step()
    check("explicit restart returns to fresh live opening",scene.demo.age==1 and scene.demo.hits==[0,0])
    check("restart retains original player preferences",scene.demo_partner==2)
    await tap(KEY_F2);step()
    check("F2 stops oversized bones and strong grading",scene.reduced_effects and not scene.grade.visible and scene.fighters.all(func(f:Node)->bool:return f.oversized_bones.is_empty()))
    for locale in ["zh","en"]:
        scene.set_language(locale)
        for extent in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:
            root.size=extent;await process_frame;scene.hud._process(0)
            check("compact transport bounds "+locale+str(extent),scene.hud.demo_buttons.all(func(b:Button)->bool:return b.get_global_rect().end.x<=1280 and b.get_global_rect().end.y<=720))
    root.size=Vector2i(1280,720);scene.set_language("zh")
    await tap(KEY_F12);step()
    check("F12 exits and restores partner preference",scene.demo==null and scene.screen=="title" and scene.sim.partner_mode==2)
    scene.start_match(false);await key(KEY_J)
    var moves:={}
    scene.combat_event.connect(func(e:Dictionary):
        if e.kind=="hit" and e.attacker==0:moves[e.move]=true)
    for i in 500:
        step()
        if scene.screen=="result":break
    await key(KEY_J,false)
    check("native held J earns an aerial combo on first play",moves.has("launcher") and moves.has("air_jab") and moves.has("meteor"))
    check("first-play player can win a real round",scene.screen=="result" and scene.sim.winner==0)
    scene.start_match(true);step()
    check("free practice uses the same accessible core",scene.sim.arcade_enabled and scene.sim.is_aerial())
    await tap(KEY_F11);step()
    check("manual air lab stays available separately",not scene.sim.arcade_enabled and scene.sim.practice_scenario=="air")
    scene.return_to_title();scene.hud.rebuild_menu()
    var entry=scene.hud.menu_stack.find_children("*","Button",true,false).filter(func(b:Button)->bool:return b.get_meta("ui_key","")=="demo")
    entry[0].pressed.emit();step()
    check("pointer starts endless demo",scene.demo!=null and scene.sim.endless)
    scene.hud.demo_buttons[1].pressed.emit();step()
    check("pointer exit clears combat effects and pending commands",scene.demo==null and scene.effects.is_empty() and scene.pending.is_empty())
    var passed:=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open("res://../docs/evidence/rush-rework/input.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"max_effects":max_effects,"player_moves":moves,"scope":"Native viewport inputs with manual simulation/presentation steps. Not human judgement."},"  "))
    scene.queue_free();await process_frame;await process_frame
    print("LIVE_INPUT_CHECKS ",passed,"/",checks.size());call_deferred("quit",0 if passed==checks.size() else 1)
