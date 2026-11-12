extends SceneTree
const OUT="res://../docs/evidence/neon-facets/"
var s:Node
var checks:Array=[]
var seen:Dictionary={}
func _initialize() -> void:call_deferred("run")
func check(label:String,passed:bool,detail:Variant=null) -> void:
    checks.append({"check":label,"pass":passed,"detail":detail})
    print("NEON ",label," ",passed," ",detail)
func render() -> void:
    await process_frame
    await RenderingServer.frame_post_draw
func shot(label:String) -> void:
    s.hud.queue_redraw();await render()
    root.get_texture().get_image().save_png(OUT+label+".png")
func create_scene(neon:bool) -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate()
    s.neon_enabled=neon;s.preferences_path=""
    root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.audio.muted=true
    s.set_character(0,3);s.set_character(1,2)
    s.start_match(true);s.backdrop.freeze_for_capture()
    s.sim.fighters[0].x=-1.0;s.sim.fighters[1].x=1.0
    s.base_camera=Vector3(0,1.7,12.0);s.camera_focus=Vector3(0,2.1,3)
    s._process(0.0)
    await render()
func destroy_scene() -> void:
    s.queue_free();await process_frame;await render()
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    await create_scene(false)
    await shot("baseline-neutral")
    await destroy_scene()
    await create_scene(true)
    await shot("neon-neutral")
    check("Lab profile enabled with bounded FX",s.neon_enabled and s.neon_profile.effect_limit==24)
    check("Whole viewport is 640x360",root.get_texture().get_size()==Vector2(640,360))
    check("Environment styled before static batching",s.backdrop.static_batch_stats.source_boxes>100 and s.backdrop.active_toon.resource_path.ends_with("neon_environment.gdshader"),s.backdrop.static_batch_stats)
    var textured:=true
    for f in s.fighters:
        for material in f.materials:
            textured=textured and material.shader.resource_path.ends_with("neon_actor.gdshader") and material.get_shader_parameter("neon_silhouette")==0.0
    check("Normal actors retain textured materials",textured)
    for row in [{"name":"parry","event":{"kind":"parry","target":0,"attacker":1}},
        {"name":"charge","event":{"kind":"swing","move":"overdrive","target":0}},
        {"name":"release","event":{"kind":"hit","move":"overdrive","target":1,"attacker":0,"strength":1.0}}]:
        s.effects.clear();s._clear_impacts();s._handle_event(row.event);s._process(.02)
        await shot("neon-"+row.name)
        check(row.name+" owns a brief poster stage",s.neon.stage() and not s.backdrop.visible)
        s._process(.35)
        check(row.name+" restores world and actor texture",s.backdrop.visible and s.fighters[0].materials[0].get_shader_parameter("neon_silhouette")==0.0)
    s.neon.clear();s._handle_event({"kind":"parry","target":0,"attacker":1});s._process(.02)
    var age:float=s.neon.age
    s.pause_game();s._process(.2)
    check("Pause freezes director",s.neon.age==age)
    s.resume_game();s.reduced_effects=true;s._process(.02)
    check("F2 clears poster and silhouette",not s.neon.active() and s.backdrop.visible and s.camera.environment==null and s.fighters[0].materials[0].get_shader_parameter("neon_silhouette")==0.0)
    s.reduced_effects=false
    s.return_to_title();await shot("neon-title")
    check("Title clears stage owner",not s.neon.active())
    # Isolated director precedence, recovery and KO ownership (explicit fixtures).
    var director=preload("res://scripts/combat/neon/neon_effect_director.gd").new()
    director.trigger({"kind":"ko","winner":1},s.sim.fighters)
    director.trigger({"kind":"parry","target":0},s.sim.fighters)
    check("KO owns the winner and cannot be replaced by parry",director.mode=="K.O." and director.owner==1)
    director.advance(.66,false,false)
    director.trigger({"kind":"swing","move":"overdrive","target":0},s.sim.fighters)
    check("Recovery prevents immediate next full-screen",not director.active() and director.suppressed==2)
    var path:="user://neon_lab/verification-options.cfg"
    check("Lab preferences create their own directory",s.preferences.write_options(path,{"music_level":.6})==OK and s.preferences.read_options(path).music_level==.6)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    # Seeded genuine free-fight. Fixed wall steps, not a staged combo or real-time perf test.
    seed(4242);s.start_demo();s.backdrop.frozen=false
    s.combat_event.connect(func(e:Dictionary):seen[e.kind]=seen.get(e.kind,0)+1)
    var poster_frames:=0;var max_effects:=0;var max_roll:=0.0
    var modes:Dictionary={}
    for tick in 1800:
        s._physics_process(1.0/60.0);s._process(1.0/60.0)
        max_effects=maxi(max_effects,s.effects.size());max_roll=maxf(max_roll,absf(s.camera.rotation.z))
        if s.neon.stage():poster_frames+=1
        if s.neon.active():modes[s.neon.mode]=modes.get(s.neon.mode,0)+1
        if tick in [300,900,1500]:await shot("demo-"+str(tick))
    check("Finite-health AI reaches a valid live or result state and both sides hit",s.screen in ["play","result"] and s.demo!=null and s.demo.hits[0]>0 and s.demo.hits[1]>0,s.demo.hits)
    check("Strong poster duty stays below 20 percent",float(poster_frames)/1800.0<=.2,float(poster_frames)/1800.0)
    check("Effect pool bound",max_effects<=24,max_effects)
    check("Camera roll bound",max_roll<=deg_to_rad(s.neon_profile.signature_roll_degrees+.01),rad_to_deg(max_roll))
    var stats:={"events":seen,"poster_frames":poster_frames,"wall_steps":1800,"modes":modes,"accepted":s.neon.accepted,"suppressed":s.neon.suppressed,"simulation_tick":s.sim.tick_count}
    s.return_to_title();await destroy_scene()
    check("Material retirement queue drained",preload("res://scripts/combat/fighter_visual.gd").retired_materials.is_empty())
    var all_passed:bool=checks.all(func(row:Dictionary)->bool:return row.pass)
    FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"demo":stats,"scope":"Linux Compatibility renders; state fixtures for neutral/parry/charge/release, seeded real AI for 1800 wall steps; not target Mac performance or human playtest."},"  "))
    director=null
    await process_frame
    quit(0 if all_passed else 1)
