extends SceneTree
var scene:Node
var checks:Array=[]
const OUT="res://../docs/evidence/double-jump/"
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("DOUBLE_INPUT ",label," ",ok)
    if not ok:push_error(label)
func key(down:bool,echo:=false) -> void:
    var event=InputEventKey.new()
    event.keycode=KEY_SPACE;event.physical_keycode=KEY_SPACE;event.pressed=down;event.echo=echo
    Input.parse_input_event(event)
    await process_frame;await process_frame
func step(count:=1) -> void:
    for i in count:
        scene._physics_process(1.0/60);scene._process(1.0/60)
func snapshot(name:String) -> void:
    scene.hud.queue_redraw()
    await process_frame;await RenderingServer.frame_post_draw
    var img=root.get_texture().get_image()
    img.resize(640,360,Image.INTERPOLATE_NEAREST)
    img.save_png(OUT+name+".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    scene=preload("res://scenes/combat/street_fight.tscn").instantiate()
    scene.preferences_path="";root.add_child(scene);current_scene=scene
    scene.set_process(false);scene.set_physics_process(false);scene.audio.muted=true
    scene.start_match(false);scene.sim.phase="fight";scene.sim.ai_enabled=false
    # Formal FIGHT with ordinary inputs; no training-only movement fixture.
    scene.sim.fighters[1].x=4.0
    check("formal FIGHT uses shared air motion",not scene.practice and scene.sim.is_aerial())
    await key(true);step(10)
    check("first press starts a ground jump",scene.sim.fighters[0].y>0 and not scene.sim.fighters[0].air.double_used)
    await key(true,true);step()
    check("OS key repeat cannot spend double jump",not scene.sim.fighters[0].air.double_used)
    await key(false);await key(true);step();await key(false)
    check("released and repressed Space spends one jump",scene.sim.fighters[0].air.double_used and scene.sim.fighters[0].vy>9)
    check("second jump has readable local feedback",scene.hud.notice=="DOUBLE JUMP" and scene.effects.any(func(e:Dictionary)->bool:return e.kind=="surge_arc"))
    check("existing pooled chase voice provides audio",scene.audio.sounds.has("chase") and not scene.audio.sounds.chase.is_empty())
    await snapshot("double-takeoff")
    var frozen:Array=scene.sim.fighters.duplicate(true)
    scene.pause_game();step(10)
    check("pause freezes double-jump budgets",scene.sim.fighters==frozen)
    await key(true);await key(false);scene.resume_game();step()
    check("paused Space cannot queue a new jump",scene.sim.fighters[0].jump_buffer==0)
    step(22);scene._present(0)
    await snapshot("double-apex")
    var framing:=true
    for i in 2:
        var f:Dictionary=scene.sim.fighters[i]
        for y_offset in [.1,2.2]:
            var point=Vector3(f.x,f.y+y_offset,scene.FIGHT_Z)
            var screen_at:Vector2=scene.camera.unproject_position(point)
            var size:Vector2=root.get_visible_rect().size
            if scene.camera.is_position_behind(point) or screen_at.x<0 or screen_at.x>size.x or screen_at.y<0 or screen_at.y>size.y:framing=false
    check("both fighters fit the double-jump camera",framing)
    scene.reduced_effects=true
    step(120)
    await key(true);step(10);await key(false);await key(true);step();await key(false)
    check("reduced effects retains double jump",scene.sim.fighters[0].air.double_used and scene.hud.notice=="DOUBLE JUMP")
    await snapshot("double-reduced")
    scene.start_match(false)
    check("restart clears effects and used jump",not scene.sim.fighters[0].air.double_used and scene.effects.is_empty() and scene.pending.is_empty())
    scene.return_to_title();scene.queue_free();scene=null
    for i in 8:await process_frame
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"input.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"scope":"Godot 4.6.3 Linux Compatibility native rendering; injected InputEvents, Dummy audio, not human/GPU/audio-device validation."},"  "))
    print("DOUBLE_INPUT_CHECKS ",checks.size()-failed,"/",checks.size())
    quit(1 if failed else 0)
