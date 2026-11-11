extends SceneTree
const OUT := "res://../docs/evidence/city-breaker/"
var s: Node
var checks: Array[Dictionary] = []
func _initialize() -> void: call_deferred("run")
func check(label: String, passed: bool) -> void:
    checks.append({"name":label,"passed":passed})
    print("CITY_BREAKER ", label, " ", passed)
    if not passed: push_error(label)
func fixture(side: int) -> void:
    s.start_match(false); s.sim.ai_enabled = false; s.sim.phase = "fight"
    s.sim.fighters[0].health = 90 if side == 0 else 0
    s.sim.fighters[1].health = 90 if side == 1 else 0
    s._combat_step()
func run() -> void:
    s = preload("res://scenes/combat/street_fight.tscn").instantiate()
    s.preferences_path = ""; s.progression_path = "/tmp/ko-verification-growth.cfg"
    root.add_child(s); s.set_process(false); s.set_physics_process(false); s.audio.muted = true
    s.reduced_effects = false
    await process_frame; await process_frame
    var plane_transform: Transform3D = s.backdrop.plane.transform
    var plane_visible: bool = s.backdrop.plane.visible
    for side in 2:
        for character in 4:
            s.return_to_title()
            s.set_character(1-side,character)
            await process_frame; await process_frame
            fixture(side)
            var c = s.city_breaker
            check("real KO begins current fighter %d / winning side %d"%[character,side],c.active() and c.victim==1-side and s.screen=="result")
            check("uses current model, no hardcoded replacement %d/%d"%[character,side],s.fighters[c.victim].character_index==character)
            var snapshot: Array = s.sim.fighters.duplicate(true)
            var round_count: int = s.sim.round_number
            for t in [.2,1.0,2.0,3.5,5.0,6.3,7.1,8.6,9.8]:
                c.sample(t)
                check("finite 3D camera at %.1f %d/%d"%[t,character,side],s.camera.position.is_finite() and s.camera.basis.determinant()>.9)
            check("presentation leaves health / round / resources immutable",s.sim.fighters==snapshot and s.sim.round_number==round_count)
            check("building and aircraft genuinely split into 3D pieces",c.pieces.size()>200 and c.plane_copy.get_child_count()>40)
            c.sample(1.1)
            check("victim is clearly airborne",s.fighters[1-side].position.y>7 and s.fighters[1-side].visible)
            s.pause_game(); var time: float = c.age
            s._process(.4)
            check("pause holds cinematic time and path",s.screen=="pause" and c.age==time and s.fighters[1-side].position.is_equal_approx(c.victim_path(time)))
            s.resume_game()
            check("resume returns to result, never combat",s.screen=="result")
            s.skip_city_breaker()
            check("skip shows result without advancing round",not c.active() and s.finish_menu_open and s.sim.round_number==round_count)
            check("skip restores live aircraft",s.backdrop.plane.transform.is_equal_approx(plane_transform) and s.backdrop.plane.visible==plane_visible and not s.backdrop.frozen)
            var restored := true
            for group in c.batches:
                for entry in group.entries:
                    restored = restored and group.node.multimesh.get_instance_transform(entry.index).is_equal_approx(entry.transform)
            check("every modified static batch instance restored",restored)
    fixture(0); s.city_breaker.sample(3.3); s.advance_round()
    check("next round cleans all destruction",not s.city_breaker.active() and not s.city_breaker.container.visible and s.screen=="play")
    fixture(1); s.city_breaker.sample(6.9); s.start_match(false)
    check("restart during explosion restores stage",not s.city_breaker.active() and not s.backdrop.frozen)
    fixture(0); s.reduced_effects=true; s._process(.02)
    check("F2 immediately exits long cinematic",not s.city_breaker.active() and s.finish_menu_open)
    s.reduced_effects=false; fixture(0); s.city_breaker.sample(5.1); s.return_to_title()
    check("return to title cleans camera and stage",not s.city_breaker.active() and s.screen=="title" and s.camera.environment==null)
    s.start_match(false);s.sim.ai_enabled=false;s.sim.phase="fight";s.sim.remaining=0
    s.sim.fighters[0].health=70;s.sim.fighters[1].health=40;s._combat_step()
    check("timeout does not launch a living loser",not s.city_breaker.active() and s.screen=="result")
    s.reduced_effects=true;fixture(0)
    check("reduced effects KO keeps short original result",not s.city_breaker.active() and s.finish_seconds()==s.FINISH_SECONDS)
    s.reduced_effects=false;fixture(0)
    var c=s.city_breaker
    for i in 600:s._process(1.0/60)
    s._process(.02)
    check("natural completion ends at ten seconds",not c.active() and s.finish_menu_open and not s.backdrop.frozen)
    check("original source nodes remain alive",c.hidden_sources.all(func(v:Dictionary)->bool:return is_instance_valid(v.node) and v.node.visible==v.visible))
    s.return_to_title();s.set_character(0,0);s.start_match(false)
    s.sim.ai_enabled=false;s.sim.phase="fight";s.sim.fighters[0].x=-.5;s.sim.fighters[1].x=.5
    s.sim.fighters[0].meter=100;s.sim.fighters[1].health=7
    s.pending={"attack":"special"}
    for i in 600:
        s._physics_process(1.0/60);s._process(1.0/60)
        if s.screen=="result":break
    check("normal paid attack triggers cinematic through a real damage KO",s.city_breaker.active() and s.sim.winner==0 and s.sim.fighters[1].health<=0)
    var key:=InputEventKey.new();key.keycode=KEY_ENTER;key.physical_keycode=KEY_ENTER;key.pressed=true
    var round_before:int=s.sim.round_number
    s._unhandled_key_input(key)
    check("first Enter skips, never advances round",not s.city_breaker.active() and s.sim.round_number==round_before and s.screen=="result")
    s._unhandled_key_input(key)
    check("second Enter enters next round",s.screen=="play" and s.sim.round_number==round_before+1)
    fixture(0);s.city_breaker.sample(3.0)
    var space:=InputEventKey.new();space.keycode=KEY_SPACE;space.physical_keycode=KEY_SPACE;space.pressed=true
    s._unhandled_key_input(space)
    check("Space also skips without a combat jump",not s.city_breaker.active() and s.screen=="result" and s.sim.fighters[0].y==0)
    s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    for i in 8:await process_frame
    s.queue_free()
    for i in 8:await process_frame
    var failures := checks.filter(func(v: Dictionary) -> bool: return not v.passed).size()
    FileAccess.open(OUT+"verification.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failures,"passed":checks.size()-failures,"engine":Engine.get_version_info().string,"display":DisplayServer.get_name()},"  "))
    print("CITY_BREAKER_CHECKS ",checks.size()-failures,"/",checks.size())
    quit(1 if failures else 0)
