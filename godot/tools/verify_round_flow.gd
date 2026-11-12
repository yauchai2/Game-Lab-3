extends SceneTree
const OUT="res://../docs/evidence/round-flow/"
var s:Node
var checks:Array=[]
var phases:Array=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("ROUND_FLOW ",label," ",ok)
    if not ok:push_error(label)
func step(n:int=1) -> void:
    for i in n:s._physics_process(1.0/60);s._process(1.0/60)
func key(code:int) -> void:
    var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true;s._unhandled_key_input(event)
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/round-flow-growth.cfg"
    root.add_child(s);s.set_process(false);s.set_physics_process(false);s.audio.muted=true;s.reduced_effects=false
    await process_frame;await process_frame
    s.start_match(false)
    check("formal FIGHT begins with a real entry",s.round_theatre.intro and s.sim.phase=="ready")
    var snapshot:Array=s.sim.fighters.duplicate(true);var countdown:int=s.sim.countdown
    step(60)
    check("entry never consumes life / resources / countdown",s.sim.fighters==snapshot and s.sim.countdown==countdown)
    key(KEY_J);check("entry rejects buffered combat commands",s.pending.is_empty())
    s.pause_game();var age:float=s.round_theatre.age;step(30)
    check("pause freezes entry score and camera time",s.round_theatre.age==age and s.round_theatre.score.stream_paused)
    s.resume_game();key(KEY_SPACE)
    check("Space skips entry without a jump",not s.round_theatre.intro and s.sim.fighters[0].y==0)
    step(50);check("normal countdown then enters actual fight",s.sim.phase=="fight")
    var entries_ok:=true
    for character in 4:
        s.return_to_title();s.set_character(0,character);s.set_character(1,(character+1)%4)
        s.start_match(false);step(43)
        entries_ok=entries_ok and s.fighters[0].character_index==character and s.fighters[0].visible and not s.fighters[1].visible
        step(43)
        entries_ok=entries_ok and not s.fighters[0].visible and s.fighters[1].visible
        s.round_theatre.clear()
        entries_ok=entries_ok and s.fighters[0].visible and s.fighters[1].visible and is_equal_approx(s.camera.near,.1)
    check("all four current roster models enter and restore visibility",entries_ok)
    s.return_to_title();s.set_character(0,0);s.set_character(1,1)
    s.start_run();var run_entry:bool=s.round_theatre.intro and s.sim.phase=="ready"
    s.advance_run()
    check("Street Run first and subsequent stops have an entry",run_entry and s.round_theatre.intro and s.run_stage==2 and s.sim.phase=="ready")
    s.return_to_title()
    s.start_match(true);check("practice starts playable without an entry lock",not s.round_theatre.intro and s.sim.phase=="fight")
    s.start_demo();seed(4242);var initial_round:int=s.presentation_round()
    check("demo uses normal finite health rather than practice regeneration",s.demo!=null and not s.sim.training and not s.sim.endless and not s.practice)
    var last:="";var complete_ko:=0;var winner_exits:=0;var safe:=true;var intros:=0;var lens_frames:=0;var equip_seen:=false
    var growth_before:Dictionary=s.growth.records.duplicate(true)
    for tick in 18000:
        # Exercise real engine frames: draw confirmations reject two actions in one frame.
        if tick%120==0:await process_frame
        step()
        # Demo accepts manual confirmation before its automatic countdown.
        if s.ability_draw.active() and s.ability_draw.input_armed:key(KEY_ENTER)
        if s.ability_draw.active() and s.ability_draw.state=="equip":equip_seen=true
        var label:String="entry" if s.round_theatre.intro else ("winner" if s.city_breaker.active() and s.city_breaker.playback_elapsed>=5 else ("ko" if s.city_breaker.active() else s.screen+"/"+s.sim.phase))
        if label!=last:
            phases.append({"seconds":tick/60.0,"phase":label,"round":s.presentation_round(),"health":[s.sim.fighters[0].health,s.sim.fighters[1].health]})
            if label=="entry":intros+=1
            if label=="ko":complete_ko+=1;check("KO %d has a real defeated fighter"%complete_ko,s.sim.phase=="match_over" and s.sim.winner>=0 and s.sim.fighters[1-s.sim.winner].health<=0)
            if label=="winner":winner_exits+=1
            last=label
        if s.round_theatre.lens.visible and not s.round_theatre.intro:
            lens_frames+=1
            safe=safe and s.round_theatre.safe_framing()
        if s.demo.rounds_finished>=3:break
    check("demo reserves full KO for the deciding round",complete_ko>=1 and s.demo.seen.get("ko",0)>=3)
    check("every deciding KO includes the winner exit",winner_exits==complete_ko)
    # Current equip contract deliberately replaces the third-round intro. Still
    # require real equipment and the fresh entry of the next completed match.
    check("rounds loop with real equipment and a fresh next-match entry",s.demo.rounds_finished>=3 and s.presentation_round()==initial_round+3 and s.round_theatre.intro and intros>=3 and equip_seen)
    check("two-win match completion also loops",s.demo.matches_finished>=1)
    check("both autonomous sides land actual hits",s.demo.hits[0]>0 and s.demo.hits[1]>0)
    check("looping demo never grants progression rewards",s.growth.records==growth_before)
    check("combat fisheye retains both fighters and HUD margins",safe and s.round_theatre.close_count>0 and lens_frames>0)
    check("ambient smoke and dust have fixed bounds",s.backdrop.smoke.ambient.size()==18 and s.backdrop.smoke.impacts.size()==12)
    check("KO has substantial bounded smoke clouds",s.city_breaker.smoke_clouds.size()==64)
    key(KEY_ESCAPE);var paused_round:int=s.demo.rounds_finished;var paused_intro:float=s.round_theatre.age;step(90)
    check("pause cannot advance the demo loop",s.demo.rounds_finished==paused_round and s.round_theatre.age==paused_intro)
    key(KEY_ESCAPE);s.reduced_effects=true;step(2)
    check("F2 releases entry lens and score",not s.round_theatre.intro and not s.round_theatre.score.playing)
    key(KEY_F12)
    check("F12 exits demo and clears every temporary lens",s.demo==null and s.screen=="title" and not s.round_theatre.lens.visible and not s.city_breaker.active())
    s.reduced_effects=false;s.start_match(false);s.return_to_title()
    check("title exit cleans entry score and camera near plane",not s.round_theatre.score.playing and is_equal_approx(s.camera.near,.1))
    s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    await create_timer(.15).timeout;s.queue_free();s=null
    for i in 8:await process_frame
    var failed:int=checks.filter(func(v:Dictionary)->bool:return not v.passed).size()
    FileAccess.open(OUT+"verification.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"phases":phases,"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),"scope":"Normal-health autonomous commands and real KO transitions; no injected damage or health fixtures in the looping-demo portion"},"  "))
    print("ROUND_FLOW_CHECKS ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
