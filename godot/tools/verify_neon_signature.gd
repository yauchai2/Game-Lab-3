extends SceneTree
const OUT="res://../docs/evidence/neon-signature/"
var s:Node
var checks:Array=[]
var timeline:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,passed:bool,detail:Variant=null) -> void:
    checks.append({"check":label,"pass":passed,"detail":detail});print("SIGNATURE ",label," ",passed," ",detail)
func render() -> void:await process_frame;await RenderingServer.frame_post_draw
func shot(label:String) -> void:
    s.hud.queue_redraw();await render();root.get_texture().get_image().save_png(OUT+label+".png")
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    DirAccess.make_dir_recursive_absolute("/tmp/neon-signature-frames")
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";root.add_child(s)
    s.set_process(false);s.set_physics_process(false);s.audio.muted=true;s.backdrop.freeze_for_capture()
    # Real paid attack for all four actors; no fabricated hit event or bonus damage.
    for character in 4:
        s.return_to_title();s.set_character(0,character);s.start_match(true);s.sim.training=false
        s.sim.fighters[0].meter=100;s.sim.fighters[0].x=-1.0;s.sim.fighters[1].x=1.0
        var start_health:float=s.sim.fighters[1].health
        var phases:Dictionary={};var rates:Dictionary={};var max_roll:=0.0;var min_fov:=48.0;var fit:=true
        var charge_frames:=0;var hit_seen:=false
        s._handle_event({"kind":"fight"})
        s.pending={"attack":"overdrive"}
        for tick in 260:
            s._physics_process(1.0/60.0);s._process(1.0/60.0);s.hud._process(1.0/60.0)
            if s.neon.active() and s.neon.signature:
                var phase:String=s.neon.signature_phase()
                if phase not in phases:
                    phases[phase]=tick
                    await shot("actor%d-%s"%[character,phase])
                if s.neon.mode=="CHARGE":charge_frames+=1
                if s.neon.camera_weight()>.01:fit=fit and s.signature_camera.fits(s.camera,s)
                max_roll=maxf(max_roll,absf(s.camera.rotation.z));min_fov=minf(min_fov,s.camera.fov)
            rates[s.rhythm.rate_now]=true
            hit_seen=hit_seen or s.sim.fighters[1].health<start_health
            if character==0:
                timeline.append({"wall_seconds":tick/60.0,"sim_tick":s.sim.tick_count,"phase":s.neon.signature_phase(),"rate":s.rhythm.rate_now,"roll":rad_to_deg(s.camera.rotation.z),"fov":s.camera.fov,"health":s.sim.fighters[1].health})
                if tick%2==0 and "--no-movie" not in OS.get_cmdline_user_args():
                    await render();root.get_texture().get_image().save_png("/tmp/neon-signature-frames/%04d.png"%floori(tick/2.0))
        check("Actor %d real paid overdrive hits"%character,hit_seen and s.sim.fighters[0].meter<100)
        check("Actor %d has five-stage signature choreography"%character,["gather","open","aim","drive","settle"].all(func(phase:String)->bool:return phases.has(phase)),phases)
        check("Actor %d longer charge and slow time"%character,charge_frames>=50 and rates.has(.22),charge_frames/60.0)
        check("Actor %d stronger roll and close lens"%character,max_roll>deg_to_rad(8) and max_roll<=deg_to_rad(14.01) and min_fov<=38, {"roll":rad_to_deg(max_roll),"fov":min_fov})
        check("Actor %d cinematic keeps both body bounds in view"%character,fit)
    # Projection safety grid uses explicit state fixtures, including corners and air height gap.
    var grid_fit:=true
    for pair in [[-6.5,6.5,0,0],[-6,-3,0,4],[3,6,5,0],[-.7,.7,4,4]]:
        s.sim.fighters[0].x=pair[0];s.sim.fighters[1].x=pair[1];s.sim.fighters[0].y=pair[2];s.sim.fighters[1].y=pair[3]
        s.neon.clear();s.neon.trigger({"kind":"swing","move":"overdrive","target":0},s.sim.fighters)
        for age in [.18,.45,.90,1.28]:
            s.neon.age=age;s._present(1.0/60.0)
            grid_fit=grid_fit and s.signature_camera.fits(s.camera,s)
    check("Corner/air/separation camera grid keeps both bodies",grid_fit)
    s.sim.fighters[0].state="attack";s.sim.fighters[0].move="overdrive"
    s.neon.clear();s.neon.trigger({"kind":"swing","move":"overdrive","target":0},s.sim.fighters)
    s._handle_event({"kind":"hit","target":0,"attacker":1,"move":"jab","strength":.2})
    check("Armor hit does not cancel a still-active real charge",s.neon.signature and s.neon.mode=="CHARGE")
    s.sim.fighters[0].state="stun"
    s._handle_event({"kind":"hit","target":0,"attacker":1,"move":"jab","strength":.2})
    check("Actual attack interruption cancels cinematic",not s.neon.signature)
    s.neon.clear();s.neon.trigger({"kind":"swing","move":"overdrive","target":0},s.sim.fighters)
    s._handle_event({"kind":"parry","target":1,"attacker":0,"move":"overdrive"})
    check("True parry transfers cinematic ownership to defender",not s.neon.signature and s.neon.mode=="PARRY" and s.neon.owner==1)
    s.neon.clear();s.neon.trigger({"kind":"break_finish","attacker":0},s.sim.fighters);s.neon.age=.25
    check("Non-signature heavy effects retain six-degree limit",absf(s.neon.camera_roll())<=deg_to_rad(6.01))
    s.neon.clear()
    s.neon.trigger({"kind":"swing","move":"overdrive","target":0},s.sim.fighters);s._process(.1)
    var age_before:float=s.neon.age;s.pause_game();s._process(.3)
    check("Pause freezes long choreography",s.neon.age==age_before)
    s.resume_game();s.reduced_effects=true;s._process(.016)
    check("F2 cancels long camera and signature",not s.neon.active() and is_zero_approx(s.camera.rotation.z) and s.backdrop.visible)
    s.return_to_title();check("Title resets camera",is_zero_approx(s.camera.rotation.z) and not s.neon.active())
    FileAccess.open(OUT+"checks.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info().string,"checks":checks,"timeline":timeline,"scope":"Four actual paid overdrive attacks; separate projection/interruption fixtures. Linux software Compatibility rendering, not target hardware performance."},"  "))
    s.queue_free();s=null;await process_frame;await render()
    await process_frame
    quit(0 if checks.all(func(row:Dictionary)->bool:return row.pass) else 1)
