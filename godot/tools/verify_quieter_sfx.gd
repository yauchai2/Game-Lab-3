extends SceneTree
var checks:Array=[]
var measurements:Dictionary={}
var capture:AudioEffectCapture
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool) -> void:
    checks.append({"name":label,"passed":ok})
    print("QUIETER_SFX ",label," ",ok)
func measure(label:String,action:Callable) -> void:
    capture.clear_buffer()
    action.call()
    await create_timer(1.0).timeout
    var samples:=capture.get_buffer(capture.get_frames_available())
    var peak:=0.0
    var squares:=0.0
    for sample in samples:
        peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
        squares+=float(sample.x)*sample.x+float(sample.y)*sample.y
    measurements[label]={"frames":samples.size(),"peak":peak,"rms":sqrt(squares/maxi(1,samples.size()*2))}
    check(label+" produces real non-clipping PCM",samples.size()>1000 and peak>0.00001 and peak<1.0)
func run() -> void:
    var args:=OS.get_cmdline_user_args()
    var baseline:bool="baseline" in args
    var session=preload("res://scenes/combat/street_fight.tscn").instantiate()
    session.preferences_path="";session.city_save_path=""
    root.add_child(session);session.set_process(false);session.set_physics_process(false)
    var audio:Node=session.audio
    audio.set_process(false);audio.music.stop();audio.fading_music.stop()
    audio.effects_level=.85;audio.music_muted=true
    var sfx:int=AudioServer.get_bus_index("Afterhours SFX")
    var before:int=AudioServer.get_bus_effect_count(sfx)
    audio._ensure_buses();audio._ensure_buses()
    check("repeated setup does not stack bus effects",AudioServer.get_bus_effect_count(sfx)==before)
    if not baseline:
        var trims:=0
        for i in AudioServer.get_bus_effect_count(sfx):
            var effect:AudioEffect=AudioServer.get_bus_effect(sfx,i)
            if effect is AudioEffectCompressor:check("compressor adds no makeup gain",effect.gain==0)
            if effect is AudioEffectAmplify:
                trims+=1
                check("shared trim is last and lowers every saved SFX setting",effect.volume_db==-10 and i==before-1)
        check("one shared mix calibration",trims==1)
    capture=AudioEffectCapture.new();capture.buffer_length=2.0
    AudioServer.add_bus_effect(0,capture)
    await create_timer(.15).timeout
    await measure("heavy",func():audio.play_sound("heavy",1.0,-6))
    audio.stop_all();await create_timer(.3).timeout
    await measure("ten_overlapping_impacts",func():
        for i in 10:audio.play_sound("heavy",1.0,-6))
    audio.stop_all();await create_timer(.3).timeout
    await measure("ui_confirm",func():audio.play_sound("ui_confirm",1.0,-6))
    audio.stop_all();await create_timer(.3).timeout
    var opening:Node=session.story_opening
    opening.begin(true);opening.score.stop()
    await create_timer(.3).timeout
    await measure("opening_case_landing",func():opening.score.play(1.3))
    if not baseline:
        check("opening uses lower cue gain and the shared SFX bus",opening.score.bus=="Afterhours SFX" and is_equal_approx(opening.score.volume_db,-5+linear_to_db(.85)))
        audio.effects_level=0;opening._sync_audio()
        check("opening still respects effects mute",opening.score.volume_db<=-80)
        audio.effects_level=.25;opening._sync_audio()
        check("saved low effects slider remains low",is_equal_approx(opening.score.volume_db,-5+linear_to_db(.25)))
    opening.clear();audio.stop_all()
    if not baseline:
        audio.restore_output();audio.stop_all();audio.music.stop();audio.fading_music.stop()
        var trim:AudioEffect=AudioServer.get_bus_effect(sfx,before-1)
        check("Restore Sound keeps mix calibration",trim is AudioEffectAmplify and trim.volume_db==-10)
    AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
    session.queue_free()
    for i in 8:await process_frame
    var failed:int=checks.filter(func(c:Dictionary)->bool:return not c.passed).size()
    FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"measurements":measurements},"  "))
    quit(1 if failed else 0)
