extends SceneTree
const OUT="res://../docs/evidence/compact-hud/"
var s:Node
var checks:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("COMPACT_HUD ",label," ",ok)
    if not ok:push_error(label)
func frames() -> void:
    for i in 3:await process_frame
    await RenderingServer.frame_post_draw
func shot(name:String) -> void:
    s._present(0);s.hud.queue_redraw();await frames()
    root.get_texture().get_image().save_png(OUT+name+".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path=""
    root.add_child(s);s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    s.set_character(0,0);s.set_character(1,3);s.start_match(false)
    s.sim.phase="fight";s.sim.ai_enabled=false;s.round_theatre.clear()
    var hud:Node=s.hud
    for notice in ["DOUBLE JUMP","CHASE","ROUTE +1","SAMPLE READY","PRELOAD 2 / 2","RICOCHET x2 / FLOOR","NICE BLOCK","SPECIAL NEEDS 50 ENERGY"]:
        hud.notice=notice;hud.notice_time=1
        check("formal HUD suppresses routine notice "+notice,not hud.notice_visible())
    for notice in ["FIGHT!","PERFECT GUARD","COUNTER SUCCESS","GUARD BREAK"]:
        hud.notice=notice;check("formal HUD retains meaningful outcome "+notice,hud.notice_visible())
    s.practice=true;hud.notice="CHASE NEEDS 20"
    check("training keeps explanatory notices",hud.notice_visible());s.practice=false
    hud.notice="";hud.notice_time=0
    s._handle_event({"kind":"double_jump","target":0})
    check("double jump uses immediate local feedback without text",hud.notice=="" and s.effects.any(func(e:Dictionary)->bool:return e.kind=="surge_arc"))
    s._handle_event({"kind":"no_meter","target":0,"cost":75})
    check("unfunded skill warns only its own resource bar",hud.resource_warning[0]>0 and hud.resource_warning[1]==0 and not hud.notice_visible())
    s.screen="pause";var saved:float=hud.resource_warning[0];hud._process(.1)
    check("pause freezes resource feedback",hud.resource_warning[0]==saved)
    s.screen="play";hud._process(.5)
    check("resource warning clears after one brief pulse",hud.resource_warning==[0.0,0.0])
    check("compact pause retains a readable label and tooltip",hud.pause_button.text=="II" and hud.pause_button.tooltip_text.contains("Esc"))
    await frames()
    for pressed in [true,false]:
        var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
        event.position=root.get_screen_transform()*hud.pause_button.get_global_rect().get_center();event.global_position=event.position
        Input.parse_input_event(event);await frames()
    check("compact pause target still works",s.screen=="pause")
    s.resume_game();s.sim.exchange.pressure=52;s.sim.wins=[1,0]
    s.sim.fighters[0].service.routes=2;s.sim.fighters[0].service.route_ttl=180
    hud.notice_time=0;s.effects.clear();s.surge_pulse=0
    var snapshot:Array=s.sim.fighters.duplicate(true)
    await shot("fight")
    check("HUD draw leaves real resources unchanged",s.sim.fighters==snapshot and s.sim.exchange.pressure==52)
    s._handle_event({"kind":"no_meter","target":0,"cost":75});hud.notice_time=0
    await shot("energy-warning")
    s.start_demo();s.sim.phase="fight";s.round_theatre.clear();s.sim.exchange.pressure=52;s.surge_pulse=0
    hud.notice_time=0;await shot("demo")
    s.return_to_title();s.start_match(false)
    check("restart clears transient resource feedback",hud.resource_warning==[0.0,0.0])
    s.return_to_title();s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    # Let the audio mixer consume stop commands after rapid intro/demo fixtures.
    await create_timer(.1).timeout
    s.queue_free();s=null
    for i in 8:await process_frame
    await create_timer(.3).timeout
    var failed:int=checks.filter(func(row:Dictionary)->bool:return not row.passed).size()
    FileAccess.open(OUT+"verification.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"engine":Engine.get_version_info().string,"scope":"Native rendering, injected pointer pause, UI policy and real-state preservation; not human usability validation."},"  "))
    quit(1 if failed else 0)
