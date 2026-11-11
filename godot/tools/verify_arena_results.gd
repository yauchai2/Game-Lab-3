extends SceneTree
const OUT="res://../docs/evidence/arena-box/"
var s:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("ARENA_RESULT ",label," ",ok)
    if not ok:push_error(label)
func step(n:int=1) -> void:
    for i in n:s._physics_process(1.0/60);s._process(1.0/60)
func actions() -> Array:
    return s.hud.menu_stack.get_children().filter(func(n:Node)->bool:return n is Button and n.is_visible_in_tree() and not n.disabled)
func key(code:int) -> void:
    var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;s._unhandled_key_input(e)
func ko(side:int,deciding:bool) -> void:
    s.start_match(false);s.sim.ai_enabled=false;s.sim.phase="fight"
    if deciding:s.sim.wins[side]=1
    s.sim.fighters[1-side].health=0;s._combat_step()
func shot(label:String) -> void:
    await process_frame;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(OUT+label+".png")
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/arena-results-growth.cfg"
    root.add_child(s);s.set_process(false);s.set_physics_process(false);s.audio.muted=true;s.reduced_effects=false
    await process_frame;await process_frame
    for side in 2:
        ko(side,false)
        check("intermediate round has no city destruction %d"%side,s.sim.phase=="round_over" and not s.city_breaker.active() and not s.final_ko())
        step(88)
        check("short round result exposes real controls %d"%side,s.finish_menu_open and s.hud.menu.visible and actions().size()>=2)
        if side==0:await shot("round-result")
        var next:Button=actions()[0];next.pressed.emit()
        check("pointer next-round action starts entry %d"%side,s.screen=="play" and s.sim.round_number==2 and s.round_theatre.intro)
        ko(side,true)
        check("deciding round alone starts full KO %d"%side,s.sim.phase=="match_over" and s.city_breaker.active() and not s.hud.menu.visible)
        # Cross the exact animation end via ordinary process steps, without skip.
        step(493)
        check("automatic cinematic end shows result controls %d"%side,not s.city_breaker.active() and s.finish_menu_open and s.hud.menu.visible and actions().size()>=2)
        if side==0:await shot("match-result")
        var first:Button=actions()[0]
        check("result action remains within native viewport %d"%side,s.hud.menu.get_global_rect().encloses(first.get_global_rect()) and first.get_global_rect().has_area())
        first.pressed.emit()
        check("pointer rematch returns to playable entry %d"%side,s.screen=="play" and s.round_theatre.intro and s.sim.wins==[0,0])
    ko(0,true);step(200);key(KEY_ESCAPE);var elapsed:float=s.city_breaker.playback_elapsed;step(60)
    check("pause holds final KO without exposing a result page",s.screen=="pause" and s.city_breaker.playback_elapsed==elapsed)
    key(KEY_ESCAPE);step(500)
    check("resume reaches an actionable result",s.screen=="result" and s.hud.menu.visible and actions().size()>=2)
    ko(0,true);s.reduced_effects=true;step(100)
    check("F2 exits final KO into an actionable result",not s.city_breaker.active() and s.hud.menu.visible and actions().size()>=2)
    s.reduced_effects=false;ko(0,true);key(KEY_SPACE);step(1)
    check("skip exposes result controls immediately",not s.city_breaker.active() and s.hud.menu.visible and actions().size()>=2)
    s.start_run();s.sim.ai_enabled=false;s.sim.phase="fight";s.sim.fighters[1].health=0;s._combat_step()
    check("Street Run early stop uses a short result",not s.city_breaker.active())
    s.advance_run();s.advance_run();s.sim.ai_enabled=false;s.sim.phase="fight";s.sim.fighters[1].health=0;s._combat_step()
    check("Street Run final stop has full KO",s.run_stage==3 and s.city_breaker.active())
    s.return_to_title();s.start_match(false);s.sim.phase="fight";s.round_theatre.clear();s.sim.ai_enabled=false
    var health:int=s.sim.fighters[1].health;s.sim.fighters[0].x=0;s.sim.fighters[1].x=1
    s.pending={"attack":"launcher"}
    var framed:=true;var flight_frames:=0
    for tick in 150:
        step()
        if s.sim.fighters.any(func(f:Dictionary)->bool:return s.Simulation.ArenaBox.active(f)):
            flight_frames+=1
            for f in s.sim.fighters:
                for y in [0.0,2.4]:
                    var uv:Vector2=s.camera.unproject_position(Vector3(f.x,f.y+y,s.FIGHT_Z))/root.get_visible_rect().size
                    framed=framed and uv.y>=.239 and uv.y<=.821 and uv.x>=.099 and uv.x<=.901
    check("fast ricochets keep both complete bodies clear of HUD",framed and flight_frames>15)
    check("formal battle has real wire-cage and bounded impact meshes",s.arena_cage.visible and s.arena_cage.impacts.size()==4 and s.arena_cage.get_child_count()==16)
    check("reduced effects never disables physical boundaries",s.sim.box_active())
    s.return_to_title()
    check("title clears all cage flashes and temporary lenses",s.arena_cage.impacts.all(func(v:Dictionary)->bool:return not v.node.visible) and not s.round_theatre.lens.visible and not s.city_breaker.active())
    s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await create_timer(.35).timeout;s.queue_free();s=null
    for i in 8:await process_frame
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(OUT+"results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"scope":"Native rendered result pages, button callbacks and explicit intermediate/deciding KO fixtures; not a human playtest"},"  "))
    print("ARENA_RESULT_CHECKS ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
