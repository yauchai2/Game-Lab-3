extends SceneTree
var scene: Node
var checks: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,passed:bool) -> void:
    checks.append({"name":label,"passed":passed})
    if not passed:push_error("DEMO INPUT FAIL: "+label)
func key(code:Key) -> void:
    var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true
    Input.parse_input_event(e);await process_frame
    e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=false
    Input.parse_input_event(e);await process_frame
func step() -> void:
    scene._physics_process(1.0/60);scene._process(1.0/60);scene.hud._process(1.0/60)
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path=""
    root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    scene.sim.partner_mode=2
    await key(KEY_F12);step()
    check("F12 starts autonomous showcase",scene.demo!=null and scene.screen=="play")
    check("demo has three visible native transport buttons",scene.hud.demo_buttons.all(func(b:Button)->bool:return b.visible))
    check("demo hides manual air and clash choices",not scene.hud.air_lesson.visible and scene.hud.choice_buttons.all(func(b:Button)->bool:return not b.visible))
    var saved: Dictionary=scene.pending.duplicate()
    await key(KEY_J);await key(KEY_K);await key(KEY_F5);await key(KEY_F7);await key(KEY_F8)
    check("gameplay keys cannot control either AI or change scenario",scene.pending==saved and scene.demo.chapter==0 and scene.sim.partner_mode==0)
    await key(KEY_ESCAPE)
    var age: int=scene.demo.age
    for i in 20:step()
    check("Escape pauses agents and simulation",scene.screen=="pause" and scene.demo.age==age)
    check("paused transport buttons hidden",scene.hud.demo_buttons.all(func(b:Button)->bool:return not b.visible))
    await key(KEY_ESCAPE);step()
    check("resume continues original chapter",scene.screen=="play" and scene.demo.age==age+1)
    await key(KEY_N);step()
    check("N advances chapter and clears previous effects",scene.demo.chapter==1 and scene.sim.fighters.all(func(f:Dictionary)->bool:return f.health==100) and scene.effects.is_empty())
    scene.hud.demo_buttons[0].pressed.emit();step()
    check("native Next uses same transition",scene.demo.chapter==2)
    await key(KEY_R);step()
    check("R restarts whole demo",scene.demo.chapter==0 and scene.demo.cycle==0)
    check("restart preserves original partner preference",scene.demo_partner==2)
    await key(KEY_F2)
    check("F2 can reduce demo effects",scene.reduced_effects)
    scene.pause_game();scene.hud.open_page("settings")
    check("settings opens over paused demo",scene.demo!=null and scene.screen=="pause")
    check("demo settings cannot change scripted partner",not scene.hud.menu_stack.find_children("*","OptionButton",true,false).any(func(b:OptionButton)->bool:return b.get_meta("ui_key","")=="partner"))
    scene.hud.close_page();scene.resume_game()
    var counts: Dictionary={}
    scene.combat_event.connect(func(e:Dictionary):counts[e.kind]=counts.get(e.kind,0)+1)
    var maximum:=0
    var finale:=false
    for i in 8000:
        step();maximum=maxi(maximum,scene.effects.size())
        if scene.screen=="result":finale=true
        if scene.demo.cycle>=1:break
    check("native scene completes and loops all chapters",scene.demo.cycle==1 and scene.demo.chapter==0)
    check("KO goes through real result presentation",finale and counts.get("ko",0)==1)
    check("native event dispatch includes air and ground exchanges",counts.get("air_counter_start",0)>=3 and counts.get("clash_start",0)>=3 and counts.get("homing_chase",0)>0 and counts.get("rally_contact",0)>=4)
    check("effects remain bounded",maximum<=64)
    check("wev is retained as demo background music",scene.audio.music_credit.contains("wev"))
    for language in ["zh","en"]:
        scene.set_language(language)
        for size in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:
            root.size=size;await process_frame;scene.hud._process(0)
            check("transport bounds "+language+str(size),scene.hud.demo_buttons.all(func(b:Button)->bool:return b.get_global_rect().end.x<=scene.hud.layout_root.size.x+.1 and b.get_global_rect().end.y<=scene.hud.layout_root.size.y+.1))
    await key(KEY_F12);step()
    check("F12 exits demo to title cleanly",scene.demo==null and scene.screen=="title" and scene.effects.is_empty())
    check("exit restores original partner preference",scene.sim.partner_mode==2)
    scene.start_match(false);step()
    check("normal match retains player control and ordinary AI",scene.demo==null and not scene.practice and scene.sim.ai_enabled)
    scene.return_to_title();scene.hud.rebuild_menu()
    var buttons=scene.hud.menu_stack.find_children("*","Button",true,false)
    var entry=buttons.filter(func(b:Button)->bool:return b.get_meta("ui_key","")=="demo")
    check("title exposes a native demo entry",entry.size()==1)
    entry[0].pressed.emit();step()
    check("pointer also starts showcase",scene.demo!=null and scene.screen=="play")
    scene.hud.demo_buttons[2].pressed.emit();step()
    check("pointer Exit clears director",scene.demo==null and scene.screen=="title")
    var passed:=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    FileAccess.open("res://../docs/evidence/ai-demo/input.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"events":counts,"max_effects":maximum,"scope":"Native viewport key dispatch and real session/controller simulation, manually stepped; not a human or target GPU playtest."},"  "))
    scene.queue_free();await process_frame;await process_frame
    print("DEMO_INPUT_CHECKS ",passed,"/",checks.size())
    call_deferred("quit",0 if passed==checks.size() else 1)
