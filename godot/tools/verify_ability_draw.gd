extends SceneTree
var s:Node
var checks:Array=[]
var output:=OUT
const OUT="res://../docs/evidence/ability-draw/entry-v2/"
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("ABILITY_DRAW ",label," ",ok)
    if not ok:push_error(label)
func step(n:=1) -> void:
    for i in n:s._physics_process(1.0/60);s._process(1.0/60)
func has_corner_in_frame(node:Node3D) -> bool:
    if node is MeshInstance3D and node.is_visible_in_tree():
        var bounds:AABB=node.get_aabb()
        for i in 8:
            var world:Vector3=node.to_global(bounds.get_endpoint(i))
            if s.camera.is_position_behind(world):continue
            var uv:Vector2=s.camera.unproject_position(world)/s.get_viewport().get_visible_rect().size
            if Rect2(0,0,1,1).has_point(uv):return true
    for child in node.get_children():
        if child is Node3D and has_corner_in_frame(child):return true
    return false

func fixture() -> void:
    s.start_match(false);s.reduced_effects=false;s.round_theatre.clear();s.sim.round_number=2;s.sim.wins=[1,1];s.sim.phase="round_over";s.sim.winner=0;s.screen="result";s.result_clock=2.0
func press(code:int) -> void:
    var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;s._unhandled_key_input(e)
func click_action() -> void:
    var point:Vector2=s.ability_draw.action.get_global_rect().get_center()
    for down in [true,false]:
        var e:=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down
        root.push_input(e,true);await process_frame

func run() -> void:
    if "--expanded-pool" in OS.get_cmdline_user_args():output="res://../docs/evidence/ability-draw/expanded-pool/"
    if "--rhythm-ui" in OS.get_cmdline_user_args():output="res://../docs/evidence/ability-draw/rhythm-ui/"
    if "--tripo-models" in OS.get_cmdline_user_args():output="res://../docs/evidence/ability-draw/tripo-models/"
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/ability-growth.cfg";root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    await process_frame;await process_frame
    fixture();s.sim.round_number=1;s.advance_round();check("round one advances without a draw",not s.ability_draw.active() and s.sim.round_number==2)
    fixture();s.sim.phase="match_over";check("2-0 match completion is ineligible",s.ability_draw_boundary().is_empty())
    fixture();s.advance_round()
    check("1-1 result enters real 3D draw before next round",s.ability_draw.active() and s.sim.round_number==2)
    check("all fighters and shadows hidden",s.fighters.all(func(a):return not a.visible) and s.silhouettes.all(func(a):return not a.visible))
    check("real street selects a nonzero entrance instead of stationary fallback",s.ability_draw.entry_offset.length()>5)
    check("NPC starts completely outside camera",not has_corner_in_frame(s.ability_draw.actors.dealer))
    check("machine starts completely outside camera",not has_corner_in_frame(s.ability_draw.actors.machine))
    var first_position:Vector3=s.ability_draw.actors.machine.position
    var first_wheel:float=s.ability_draw.actors.wheels[0].rotation.x
    var snapshot:Array=s.sim.fighters.duplicate(true);step(30)
    check("cast actually travels in and wheels rotate",s.ability_draw.actors.machine.position.distance_to(first_position)>1 and absf(s.ability_draw.actors.wheels[0].rotation.x-first_wheel)>1)
    check("presentation does not tick combat or mutate fighters",snapshot==s.sim.fighters)
    s.pause_game();var time:float=s.ability_draw.age;step(20)
    check("pause freezes draw and all voice positions",s.screen=="pause" and s.ability_draw.age==time and s.ability_draw.arrival.stream_paused)
    s.resume_game();press(KEY_SPACE)
    check("skip arrival stops at offer without rolling",s.ability_draw.state=="offer" and s.ability_draw.result.is_empty())
    Input.action_press("ui_accept");step(90)
    check("held accept cannot arm or auto roll",not s.ability_draw.input_armed and s.ability_draw.state=="offer")
    Input.action_release("ui_accept");step(12)
    check("offer has visible native action",s.ability_draw.action.visible)
    check("button uses the shared game display font",s.ability_draw.action.get_theme_font("font")==preload("res://scripts/combat/ui/ui_theme.gd").DISPLAY)
    await process_frame
    await click_action()
    check("native button locks a random result once",s.ability_draw.state=="spin" and s.draw_rewards.results.size()==1)
    step(18);await process_frame;press(KEY_ENTER)
    check("repeated Enter cannot skip the spin",s.ability_draw.state=="spin")
    var result:Dictionary=s.ability_draw.result.duplicate();var count:int=s.ability_draw.rolled_count
    step(20);await process_frame;press(KEY_SPACE);step(12)
    check("skip spin retains exactly the same reward",s.ability_draw.state=="result" and s.ability_draw.result==result and s.ability_draw.rolled_count==count)
    check("claim page is stable and lens is released",not s.ability_draw.lens.visible and s.ability_draw.action.visible)
    await process_frame;await click_action()
    check("claim starts round three and applies real modifier",not s.ability_draw.active() and s.sim.round_number==3 and s.sim.fighters[0].get("draw_core","")==result.id)
    check("claim cannot apply twice",not s.draw_rewards.apply_once(s.sim,result))
    check("all fighter visibility and camera near restore",s.fighters.all(func(a):return a.visible) and is_equal_approx(s.camera.near,.1))
    var rng_rewards=preload("res://scripts/combat/ability_draw/rewards.gd").new()
    check("seed and boundary results are stable",rng_rewards.roll("test",42)==rng_rewards.roll("test",999))
    var sim=preload("res://scripts/combat/fight_simulation.gd").new();sim.arcade_enabled=true;sim.training=true;sim.ai_enabled=false;sim.phase="fight"
    sim.tick({"axis":1.0});var speed:float=sim.fighters[0].vx;sim.fighters[0]["draw_core"]="speed";sim.tick({"axis":1.0})
    check("speed core changes actual movement +20%",is_equal_approx(sim.fighters[0].vx,speed*1.2))
    sim.fighters[0].guard=20;sim.fighters[0]["draw_core"]="guard";var old_guard:float=sim.fighters[0].guard;sim.tick()
    check("guard core changes actual regeneration +35%",is_equal_approx(sim.fighters[0].guard-old_guard,.30*1.35))
    sim.reset_round();var energy:float=sim.fighters[0].meter
    var reward:Dictionary={"id":"charge","boundary":"energy"};rng_rewards.apply_once(sim,reward)
    check("charge core adds at most twenty starting meter",is_equal_approx(sim.fighters[0].meter,minf(100,energy+20)))
    sim.reset_round();check("temporary core never survives reset",not sim.fighters[0].has("draw_core"))
    fixture();s.advance_round();step(80)
    var slap:float=s.ability_draw.source_age
    step(5)
    check("slap has a brief authored hold",s.ability_draw.source_age>=slap and s.ability_draw.source_age<=1.43)
    s.ability_draw.skip();step(12);await process_frame;s.ability_draw.confirm();step(63)
    var reel0:float=s.ability_draw.actors.reels[0].rotation.x
    var reel2:float=s.ability_draw.actors.reels[2].rotation.x
    step(8)
    check("first reel locks while last reel is still turning",is_equal_approx(reel0,s.ability_draw.actors.reels[0].rotation.x) and not is_equal_approx(reel2,s.ability_draw.actors.reels[2].rotation.x))
    step(20)
    check("all reels lock before prize reveal",s.ability_draw.state=="spin" and not s.ability_draw.reveal_started and not s.ability_draw.actors.reward.visible)
    step(8)
    check("reveal follows the quiet stop",s.ability_draw.reveal_started and s.ability_draw.actors.reward.visible)
    step(45)
    check("result settles after 2.2 seconds",s.ability_draw.state=="result" and not s.ability_draw.lens.visible)
    step(600)
    check("result waits without automatic claim",s.ability_draw.state=="result" and s.sim.round_number==2)
    for reduced in [false,true]:
        fixture();s.reduced_effects=reduced;s.advance_round();step(140)
        check("F2 offer stays usable %s"%reduced,s.ability_draw.state=="offer" and s.ability_draw.action.visible)
        await process_frame;s.ability_draw.confirm();step(140)
        check("full playback reaches stable result %s"%reduced,s.ability_draw.state=="result" and not s.ability_draw.lens.visible)
        s.return_to_title();check("title clears score / lens / hidden fighters %s"%reduced,not s.ability_draw.active() and not s.ability_draw.arrival.playing and not s.ability_draw.spin.playing and s.fighters.all(func(a):return a.visible))
    fixture();s.advance_round();step(15);press(KEY_R)
    check("restart cancels draw and clears pending reward",not s.ability_draw.active() and s.draw_rewards.results.is_empty())
    s.start_run();s.run_stage=2;s.screen="result";s.sim.winner=0;s.advance_run()
    check("Street Run stop two win enters shared draw",s.ability_draw.active() and s.run_stage==2 and s.ability_draw.continuation=="run")
    s.ability_draw.skip();step(12);await process_frame;s.ability_draw.confirm();s.ability_draw.skip();step(12);await process_frame;s.ability_draw.confirm()
    check("Street Run claim advances to stop three",s.run_stage==3 and s.sim.fighters[0].has("draw_core"))
    s.return_to_title();s.start_run();s.run_stage=2;s.screen="result";s.sim.winner=1
    check("Street Run defeat cannot award a draw",s.ability_draw_boundary().is_empty())
    s.return_to_title();s.start_match(true);check("practice never awards a draw",s.ability_draw_boundary().is_empty())
    var growth:Dictionary=s.growth.records.duplicate(true)
    s.return_to_title();s.start_demo();s.round_theatre.clear();s.sim.round_number=2;s.sim.wins=[1,1];s.sim.phase="round_over";s.sim.winner=0;s.screen="result";s.result_clock=2
    s._advance_demo_round();check("Demo uses same intermission",s.ability_draw.active())
    s.ability_draw.skip();step(177);await process_frame
    check("Demo holds offer for almost three seconds",s.ability_draw.state=="offer" and s.ability_draw.result.is_empty())
    s.pause_game();var demo_wait:float=s.ability_draw.age;step(180)
    check("Demo pause freezes automatic draw countdown",s.ability_draw.age==demo_wait and s.ability_draw.state=="offer")
    s.resume_game();Input.action_press("ui_accept");step(8);await process_frame
    check("Demo automatically draws after three seconds",s.ability_draw.state=="spin" and not s.ability_draw.result.is_empty())
    step(140);await process_frame
    check("Demo reaches the same stable reward page",s.ability_draw.state=="result" and s.sim.round_number==2)
    step(180);await process_frame
    check("Demo displays reward for at least three seconds",s.ability_draw.state=="result" and s.sim.round_number==2)
    s.pause_game();demo_wait=s.ability_draw.age;step(120)
    check("Demo pause freezes automatic claim countdown",s.ability_draw.age==demo_wait and s.ability_draw.state=="result")
    s.resume_game();step(30);await process_frame
    Input.action_release("ui_accept")
    check("Demo automatically claims after 3.5 seconds even with a held key",not s.ability_draw.active() and s.sim.round_number==3 and s.sim.fighters[0].has("draw_core"))
    check("Demo does not grant permanent growth",s.growth.records==growth)
    s.return_to_title()
    var profile=preload("res://scripts/combat/ability_draw/stage_profile.gd").new()
    profile.anchor=Vector3(2,0,4);profile.heading_degrees=32;profile.entry_offset=Vector3(4,0,-.5);profile.collision_mask=1<<18
    fixture();s.ability_draw_stage=profile;s.advance_round();step(5)
    check("another stage anchor and orientation transform the same cast",s.ability_draw.global_position.is_equal_approx(profile.anchor) and is_equal_approx(s.ability_draw.rotation.y,deg_to_rad(32)))
    check("alternate entry side is used without negative scale",s.ability_draw.entry_offset.x>0 and s.ability_draw.scale==Vector3.ONE)
    check("actors remain excluded at alternate stage",s.fighters.all(func(a):return not a.visible) and not s.backdrop.living.visible)
    var camera_before:Dictionary=s.ability_draw.saved.duplicate()
    s.ability_draw.clear()
    check("clear restores saved camera exactly",s.camera.transform==camera_before.transform and s.camera.fov==camera_before.fov and s.camera.near==camera_before.near)
    check("clear restores background actors and music duck",s.backdrop.living.visible and s.audio.cinematic_duck==camera_before.duck)
    var restored:int=s.ability_draw.restore_count;s.ability_draw.clear()
    check("clear is idempotent",s.ability_draw.restore_count==restored)
    s.return_to_title()
    var wall:=StaticBody3D.new();wall.collision_layer=1<<19
    var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(1,3,2);collision.shape=box;wall.add_child(collision);root.add_child(wall);wall.position=Vector3(-3,1.5,3)
    await physics_frame;await physics_frame
    profile=preload("res://scripts/combat/ability_draw/stage_profile.gd").new();profile.collision_mask=1<<19
    fixture();s.ability_draw_stage=profile;s.advance_round()
    check("obstructed main lane chooses swept-volume backup",s.ability_draw.use_backup and s.ability_draw.entry_offset.x>0)
    s.ability_draw.clear()
    var other_wall:=StaticBody3D.new();other_wall.collision_layer=1<<19
    var other_collision:=CollisionShape3D.new();other_collision.shape=box;other_wall.add_child(other_collision);root.add_child(other_wall);other_wall.position=Vector3(3,1.5,3)
    await physics_frame;await physics_frame
    fixture();s.ability_draw_stage=profile;s.advance_round()
    check("both blocked lanes choose explicit animated compact reveal",s.ability_draw.compact_entry)
    check("compact reveal never exposes a newly spawned cast",not s.ability_draw.actors.machine.visible and not s.ability_draw.actors.dealer.visible)
    step(45)
    check("compact reveal releases cast after the covering wipe",s.ability_draw.actors.machine.visible and s.ability_draw.actors.dealer.visible)
    s.ability_draw.clear();wall.queue_free();other_wall.queue_free();await process_frame
    s.ability_draw_stage=null
    fixture();s.advance_round();s.audio.muted=true;step(1)
    check("draw respects explicit mute",s.ability_draw.arrival.volume_db<=-79)
    s.audio.muted=false;s.audio.effects_level=0;step(1)
    check("draw respects zero effects volume",s.ability_draw.arrival.volume_db<=-79)
    s.audio.effects_level=.8;step(1)
    check("effects volume restores without restarting timeline",s.ability_draw.arrival.volume_db>-30 and s.ability_draw.age>0)
    press(KEY_F1);step(1)
    check("settings pauses draw with visible controls",s.screen=="pause" and s.hud.menu.visible and not s.ability_draw.action.visible)
    s.hud.close_page();s.resume_game()
    press(KEY_F2);step(1)
    check("live F2 disables lens without losing draw",s.ability_draw.active() and not s.ability_draw.lens.visible)
    s.return_to_title();s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await create_timer(.1).timeout;s.queue_free();s=null
    for i in 8:await process_frame
    var failed:int=checks.filter(func(c):return not c.passed).size()
    FileAccess.open(output+"verification.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Explicit 1-1 / Street Run boundary fixtures; actual runtime transition, native callbacks, deterministic rules, no claim of natural-match coverage here","engine":Engine.get_version_info().string},"  "))
    print("ABILITY_DRAW_CHECKS ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
