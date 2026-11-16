extends SceneTree
var checks:Array=[]
var metrics:Dictionary={}
var audio:Node
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok});print("AUDIO_DIRECTION ",label," ",ok)
func advance(seconds:float) -> void:
    for i in roundi(seconds/.05):audio._process(.05)
func run() -> void:
    var args:=OS.get_cmdline_user_args()
    var baseline:bool="baseline" in args
    audio=preload("res://scripts/combat/fight_audio.gd").new();root.add_child(audio);audio.set_process(false)
    if not baseline:
        check("louder battle masters are attenuated, sparse beds are preserved",audio.track_mix_trim_db(audio.FIGHT_POOL[0])==-3 and audio.track_mix_trim_db(audio.FIGHT_POOL[2])==-4 and audio.track_mix_trim_db(audio.CITY_TRACK)==0 and audio.track_mix_trim_db(audio.RESULT_TRACK)==0)
        audio.context="play";audio._process(.05);audio.crossfade=1;audio.heat=1
        audio.adaptive_hold=2;audio._process(.05)
        check("fresh bouts keep a minimum quiet phrase",audio.current_track==audio.QUIET_FIGHT_TRACK and audio.pending_track=="")
        audio.adaptive_hold=0;audio.music.seek(.7);audio.heat=1;audio._process(.05)
        check("heat change schedules the next bar instead of cutting mid-phrase",audio.pending_track==audio.fight_pick and audio.pending_music_wait>0 and audio.current_track==audio.QUIET_FIGHT_TRACK)
        audio.context="pause";var hold:float=audio.adaptive_hold;audio._process(.5)
        check("pause does not advance combat hold or pause normal music",audio.adaptive_hold==hold and not audio.music.stream_paused)
        audio.context="play";audio.heat=1;audio.adaptive_hold=0;audio.pending_track=audio.fight_pick;audio.pending_music_wait=.02;audio._process(.05)
        check("scheduled battle transition uses a short beat fade",audio.current_track==audio.fight_pick and audio.fade_seconds>=.35 and audio.fade_seconds<=.65)
        audio.combat_resume_positions[audio.QUIET_FIGHT_TRACK]=11.7
        check("returning combat loop resumes on a saved bar",is_equal_approx(audio._combat_start_position(audio.QUIET_FIGHT_TRACK),9.6))
        audio.heat=0;audio.adaptive_hold=0;audio.crossfade=1;audio.music.seek(.7);audio._process(.05)
        check("cooling schedules a return",audio.pending_track==audio.QUIET_FIGHT_TRACK)
        audio.heat=1;audio._process(.05)
        check("renewed action cancels stale cooling",audio.pending_track=="" and audio.current_track==audio.fight_pick)
        audio.context="draw";audio._process(.05)
        check("Dealer bypasses adaptive waiting",audio.current_track==audio.DRAW_TRACK and audio.pending_track=="" and is_equal_approx(audio.fade_seconds,.45))
        audio.context="ko";audio._process(.05)
        check("KO music starts promptly and remains one-shot",audio.current_track==audio.KO_TRACK and not audio.music.stream.loop and is_equal_approx(audio.fade_seconds,.12))
        audio.context="result";audio.match_over=true;audio._process(.05)
        check("match result settles with a longer fade",audio.current_track==audio.RESULT_TRACK and is_equal_approx(audio.fade_seconds,1.5))
        audio.context="play";audio.practice_music=true;audio._process(.05)
        check("training retains its steady bed",audio.current_track==audio.TRAINING_TRACK)
        audio.stop_all();var start:int=audio.voice_index
        for i in 10:audio.play_sound("heavy")
        check("same-frame heavy pile-up becomes one clear accent",audio.voice_index==start+1)
        advance(.05);audio.play_sound("heavy")
        check("a later heavy remains audible",audio.voice_index==start+2)
        audio.stop_all()
        for i in 10:audio.play_sound("ko")
        start=audio.voice_index;audio.play_sound("step")
        check("footsteps cannot steal a critical cue",audio.voice_index==start)
        audio.play_sound("parry")
        check("a parry can replace a busy critical slot",audio.voice_index==start+1)
        audio.stop_all();audio.play_sound("step")
        var step_voice:AudioStreamPlayer=audio.voices.filter(func(v:AudioStreamPlayer)->bool:return v.playing)[0]
        var step_db:float=step_voice.volume_db
        audio.play_sound("hit")
        var contact:AudioStreamPlayer=audio.voices.filter(func(v:AudioStreamPlayer)->bool:return v.playing and v!=step_voice)[0]
        check("small movement sounds sit below the main contact",contact.volume_db-step_db>=5)
        audio.stop_all();audio.play_sound("heavy");audio._process(.05)
        check("music duck attacks quickly within its smaller budget",audio.duck_gain_db>2 and audio.duck_gain_db<=3.5)
        audio.stop_all();advance(1)
        check("reset clears ducking and repeat gates",audio.duck_gain_db==0 and audio.sfx_last.is_empty())
        audio.context="title";audio._switch_track(audio.MENU_TRACK);advance(2)
        audio.context="city";audio._switch_track(audio.CITY_TRACK);audio._process(.15)
        var old_weights:Vector2=audio._deck_weights()
        var old_position:float=audio.fading_music.get_playback_position()
        audio.context="title";audio._switch_track(audio.MENU_TRACK)
        check("reversing a fade preserves both instantaneous deck gains",audio._deck_weights().distance_to(Vector2(old_weights.y,old_weights.x))<.0001)
        check("reversing does not restart the returning song",absf(audio.music.get_playback_position()-old_position)<.05)
        advance(2);audio.context="city";audio._switch_track(audio.CITY_TRACK);audio._process(.1)
        old_weights=audio._deck_weights();audio.context="draw";audio._switch_track(audio.DRAW_TRACK)
        check("a third destination preserves the dominant outgoing gain",absf(audio._deck_weights().y-maxf(old_weights.x,old_weights.y))<.0001)
        var bounded:=true
        for i in 30:
            audio._process(.05);bounded=bounded and audio._deck_weights().length()<=1.00001
        check("interrupted fade never exceeds unit energy",bounded)
    var capture:=AudioEffectCapture.new();capture.buffer_length=2
    AudioServer.add_bus_effect(0,capture)
    audio.muted=false;audio.music_muted=false;audio.practice_music=false;audio.music_level=.75
    for path in audio.FIGHT_POOL:
        audio.stop_all();audio.context="play";audio.fight_pick=path;audio.heat=1;audio._switch_track(path)
        for i in 80:audio.heat=1;audio._process(.05)
        audio.fading_music.stop();audio.music.seek(8)
        await create_timer(.15).timeout;capture.clear_buffer()
        await create_timer(1).timeout
        var frames:=capture.get_buffer(capture.get_frames_available());var peak:=0.0;var squares:=0.0
        for frame in frames:
            peak=maxf(peak,maxf(absf(frame.x),absf(frame.y)));squares+=frame.length_squared()
        metrics[path.get_file()]={"frames":frames.size(),"rms":sqrt(squares/maxi(1,frames.size()*2)),"peak":peak,"deck_db":audio.music.volume_db}
        check("real PCM remains audible without clipping "+path,frames.size()>1000 and peak>.00001 and peak<1)
    AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
    audio.stop_all();audio.queue_free();await create_timer(.2).timeout
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"metrics":metrics},"  "))
    quit(1 if failed else 0)
