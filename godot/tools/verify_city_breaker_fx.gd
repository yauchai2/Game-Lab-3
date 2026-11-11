extends SceneTree
const OUT="res://../docs/evidence/city-breaker-fx/"
var s:Node
var checks:Array=[]
var capture:AudioEffectCapture
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"name":label,"passed":ok,"detail":detail});print("KO_FX ",label," ",ok)
    if not ok:push_error(label)
func pcm(seconds:float) -> Dictionary:
    capture.clear_buffer();await create_timer(seconds).timeout
    var frames:=capture.get_buffer(capture.get_frames_available())
    var peak:=0.0;var energy:=0.0;var stereo:=0.0
    for f in frames:
        peak=maxf(peak,maxf(absf(f.x),absf(f.y)));energy+=f.length_squared();stereo+=absf(f.x-f.y)
    return {"frames":frames.size(),"peak":peak,"rms":sqrt(energy/maxi(1,frames.size()*2)),"stereo":stereo/maxi(1,frames.size())}
func run() -> void:
    s=preload("res://scenes/combat/street_fight.tscn").instantiate();s.preferences_path="";s.progression_path="/tmp/ko-fx-growth.cfg"
    root.add_child(s);s.set_process(false);s.set_physics_process(false);s.reduced_effects=false
    s.audio.music_level=0;s.audio.muted=false
    await process_frame;await process_frame
    s.start_match(false);s.sim.ai_enabled=false;s.sim.phase="fight";s.sim.fighters[1].health=0;s._combat_step()
    var c=s.city_breaker
    check("full presentation and score are both five seconds",c.DURATION==5.0 and absf(c.score_player.stream.get_length()-5.0)<.03)
    check("audio retains original pitch",c.score_player.pitch_scale==1.0)
    check("KO card holds for at least 0.9 seconds",c.DURATION-c.playback_time(c.CUTS[7])>=.9)
    var monotonic:=true;var last:float=-1
    for frame in 301:
        var wall:float=frame/60.0
        var authored:float=c.source_time(wall)
        monotonic=monotonic and authored>=last and absf(c.playback_time(authored)-wall)<.0001
        last=authored
    check("time mapping has no reversal and covers five seconds",monotonic and is_equal_approx(c.source_time(5),10))
    check("main airburst retains a deliberate slow accent",c.source_time(3.72)-c.source_time(3.55)<.17)
    check("real KO owns lens and synchronized score",c.active() and c.lens.visible and c.score_player.playing)
    var bus:=AudioServer.get_bus_index("Afterhours SFX")
    capture=AudioEffectCapture.new();capture.buffer_length=2.0
    var capture_index:=AudioServer.get_bus_effect_count(bus);AudioServer.add_bus_effect(bus,capture)
    var audible:Dictionary=await pcm(.34)
    check("actual engine KO mixer produces bounded stereo PCM",audible.frames>1000 and audible.peak>.005 and audible.peak<.9 and audible.stereo>.0001,audible)
    c.sample(.83)
    check("impact enables bounded high contrast / lens impulse",c.impact_strength>.5 and c.blur_strength>0 and c.blur_strength<=.08)
    check("camera recoil remains below fourteen degree roll",absf(s.camera.rotation.z)<=deg_to_rad(14.01) and s.camera.fov>45)
    c.sample(2.4);check("street rush uses edge speed lines",c.speed_strength>=.7 and c.blur_strength>.02)
    c.sample(9.7);check("last KO frame settles for readability",c.speed_strength==0 and c.blur_strength<.01)
    s.pause_game();s._process(0.0)
    var stopped:float=c.score_player.get_playback_position();var t:float=c.age
    await create_timer(.12).timeout
    check("pause freezes score and cinematic clock",c.score_player.stream_paused and absf(c.score_player.get_playback_position()-stopped)<.03 and c.age==t)
    s.resume_game();s._process(0.0)
    check("resume unpauses existing score without starting combat",not c.score_player.stream_paused and s.screen=="result")
    s.audio.muted=true;c.advance(0.0,false)
    await create_timer(.06).timeout
    var muted:Dictionary=await pcm(.14)
    check("global mute silences KO bus",muted.peak<.0001,muted)
    s.audio.muted=false;s.audio.effects_level=0;c.advance(0.0,false)
    var zero:Dictionary=await pcm(.14)
    check("zero SFX level silences dedicated score",zero.peak<.0001,zero)
    s.audio.effects_level=.85;c.advance(0.0,false)
    check("sound setting changes preserve playback instance",c.score_player.playing and c.score_player.volume_db> -30)
    s.skip_city_breaker()
    check("skip clears postprocessing / sound / music duck",not c.lens.visible and not c.score_player.playing and s.audio.cinematic_duck==0 and c.blur_strength==0)
    await create_timer(.08).timeout
    var skipped:Dictionary=await pcm(.12)
    check("no score tail leaks after skip",skipped.peak<.0001,skipped)
    s.start_match(false);s.sim.ai_enabled=false;s.sim.phase="fight";s.sim.fighters[0].health=0;s._combat_step()
    c.sample(6.5);s.reduced_effects=true;s._process(.01)
    check("F2 clears lens and sound together",not c.active() and not c.lens.visible and not c.score_player.playing)
    s.reduced_effects=false;s.start_match(false);s.sim.ai_enabled=false;s.sim.phase="fight";s.sim.fighters[1].health=0;s._combat_step()
    s.return_to_title()
    check("title exit releases all FX ownership",not c.active() and not c.lens.visible and not c.score_player.playing and s.audio.cinematic_duck==0)
    AudioServer.remove_bus_effect(bus,capture_index);capture=null
    s.audio.set_process(false);s.audio.music.stop();s.audio.fading_music.stop()
    for i in 8:await process_frame
    s.queue_free();s=null
    for i in 8:await process_frame
    var failed:int=checks.filter(func(v:Dictionary)->bool:return not v.passed).size()
    FileAccess.open(OUT+"verification.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"passed":checks.size()-failed,"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),"driver":AudioServer.get_driver_name(),"scope":"Actual engine PCM and native renderer, no hardware speaker / Mac performance claim"},"  "))
    print("KO_FX_CHECKS ",checks.size()-failed,"/",checks.size());quit(1 if failed else 0)
