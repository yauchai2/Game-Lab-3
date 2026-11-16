extends SceneTree
## A scheduled mixer audition, not a recording of human gameplay.
var audio:Node
var transitions:Array=[]
func _initialize() -> void:call_deferred("run")
func section(context:String,seconds:float,impacts:=false) -> void:
    audio.context=context
    var until:int=Time.get_ticks_msec()+roundi(seconds*1000)
    var next_hit:int=Time.get_ticks_msec()+150
    var previous:String=audio.current_track
    var hit:=0
    while Time.get_ticks_msec()<until:
        if impacts and Time.get_ticks_msec()>=next_hit:
            audio.play_sound("heavy" if hit%4==3 else "hit",1.0,-6)
            audio.play_sound("swing",1.0,-9)
            next_hit+=300;hit+=1
        if previous!=audio.current_track:
            transitions.append({"context":context,"from":previous,"to":audio.current_track,"outgoing_position":audio.fading_music.get_playback_position()})
            previous=audio.current_track
        await create_timer(.025).timeout
func run() -> void:
    var args:=OS.get_cmdline_user_args()
    audio=preload("res://scripts/combat/fight_audio.gd").new();root.add_child(audio)
    audio.music.seek(10.9)
    var capture:=AudioEffectCapture.new();capture.buffer_length=30
    AudioServer.add_bus_effect(0,capture)
    await section("title",2)
    await section("city",2)
    await section("play",9,true)
    await section("pause",1)
    await section("play",2,true)
    await section("draw",1.5)
    await section("ko",2)
    audio.match_over=true
    await section("result",1.5)
    var samples:=capture.get_buffer(capture.get_frames_available())
    var data:=PackedByteArray();data.resize(samples.size()*4)
    var peak:=0.0;var clipped:=0
    for i in samples.size():
        peak=maxf(peak,maxf(absf(samples[i].x),absf(samples[i].y)))
        if absf(samples[i].x)>=1 or absf(samples[i].y)>=1:clipped+=1
        data.encode_s16(i*4,roundi(clampf(samples[i].x,-1,1)*32767))
        data.encode_s16(i*4+2,roundi(clampf(samples[i].y,-1,1)*32767))
    var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS
    stream.stereo=true;stream.mix_rate=roundi(AudioServer.get_mix_rate());stream.data=data
    stream.save_to_wav(args[0])
    FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify({"frames":samples.size(),"peak":peak,"clipped":clipped,"transitions":transitions,"scope":"Scheduled runtime mixer audition, not human gameplay or hardware listening."},"  "))
    AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
    audio.stop_all();audio.queue_free();await create_timer(.2).timeout
    quit(0 if samples.size()>1000 and clipped==0 else 1)
