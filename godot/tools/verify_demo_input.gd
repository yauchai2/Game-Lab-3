extends SceneTree
var scene:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("DEMO_INPUT ",label," ",ok)
    if not ok:push_error(label)
func key(code:int) -> void:
    var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;scene._unhandled_key_input(e)
func step(n:int=1) -> void:
    for i in n:scene._physics_process(1.0/60);scene._process(1.0/60)
func run() -> void:
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate();scene.preferences_path="";scene.progression_path="/tmp/demo-loop-input-growth.cfg"
    root.add_child(scene);scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true;scene.reduced_effects=false
    await process_frame;await process_frame
    scene.sim.partner_mode=2;key(KEY_F12)
    check("F12 starts a normal-health demo with full entry",scene.demo!=null and not scene.sim.training and not scene.sim.endless and scene.round_theatre.intro)
    step(40);check("agents cannot act inside entry",scene.demo.age==0)
    key(KEY_J);key(KEY_K);key(KEY_N)
    check("entry rejects attacks and retired next-chapter key",scene.pending.is_empty())
    key(KEY_ESCAPE);var age:float=scene.round_theatre.age;step(30)
    check("Esc pauses opening and its audio",scene.screen=="pause" and scene.round_theatre.age==age and scene.round_theatre.score.stream_paused)
    check("demo still has the native pause menu",scene.hud.menu.visible)
    key(KEY_ESCAPE);key(KEY_ENTER);step(60)
    check("Enter skips entry, normal countdown enters fight",not scene.round_theatre.intro and scene.sim.phase=="fight")
    var d=scene.demo
    key(KEY_J);key(KEY_G);key(KEY_N)
    check("player keys do not feed the autonomous agents",scene.pending.is_empty() and scene.demo==d)
    step(4200)
    check("normal controls survive two complete KO loops",scene.demo==d and d.rounds_finished>=2 and d.seen.get("ko",0)>=2 and scene.screen in ["play","result"])
    key(KEY_R)
    check("R starts a fresh opening and statistics",scene.demo!=d and scene.demo.rounds_finished==0 and scene.demo.age==0 and scene.round_theatre.intro)
    check("restart retains original partner preference",scene.demo_partner==2)
    key(KEY_F12)
    check("F12 clears all presentations and restores preference",scene.demo==null and scene.screen=="title" and scene.sim.partner_mode==2 and not scene.round_theatre.lens.visible and not scene.city_breaker.active())
    scene.audio.set_process(false);scene.audio.music.stop();scene.audio.fading_music.stop()
    await create_timer(.15).timeout;scene.queue_free();scene=null
    for i in 8:await process_frame
    var failed:int=checks.filter(func(v:Dictionary)->bool:return not v.passed).size()
    FileAccess.open("res://../docs/evidence/rush-rework/input.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"scope":"Native input handler / real normal-health AI rounds / entry and KO loop. Replaces obsolete regeneration-only Demo contract."},"  "))
    print("DEMO_INPUT_CHECKS ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
