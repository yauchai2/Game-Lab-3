extends SceneTree
var checks: Array[Dictionary]=[]
var audio: Node
func _initialize() -> void:call_deferred("run")
func check(label: String, value: bool) -> void:
    checks.append({"name":label,"passed":value})
    if not value:push_error("WEV AUDIO FAIL: "+label)
func run() -> void:
    audio=preload("res://scripts/combat/fight_audio.gd").new()
    root.add_child(audio)
    check("wev game derivative loads and loops",audio.music.stream is AudioStreamOggVorbis and audio.music.stream.loop)
    check("full official track retained",absf(audio.music.stream.get_length()-225.78)<.2)
    check("credit names actual artist and track",audio.music_credit=="wev / family ties (wev edit)")
    var fallback=audio.music_stream("res://audio/wev/missing.ogg")
    check("missing optional track uses retained CC0 fallback",fallback!=null and fallback.loop and audio.music_credit.contains("Juhani"))
    audio.music.stream=audio.music_stream(audio.WEV)
    check("loading music never alters source import loop flag",not (load(audio.WEV) as AudioStreamOggVorbis).loop)
    check("source loop flag is isolated from playback copy",audio.music.stream.loop)
    audio.context="title"
    await create_timer(.15).timeout
    check("title starts native playback",audio.music.playing and not audio.music.stream_paused)
    var identity: int=audio.music.get_instance_id()
    var before: float=audio.music.get_playback_position()
    audio.context="play"
    await create_timer(.15).timeout
    check("title to fight retains one playback head",audio.music.get_instance_id()==identity and audio.music.get_playback_position()>=before)
    audio.play_sound("heavy")
    check("heavy contact ducks music without stopping it",audio.duck_time>0 and audio.music.playing)
    audio._process(.3)
    check("duck recovers after bounded interval",audio.duck_time==0)
    audio.context="pause"
    audio._process(.01)
    before=audio.music.get_playback_position()
    await create_timer(.15).timeout
    check("pause preserves playhead",audio.music.stream_paused and absf(audio.music.get_playback_position()-before)<.08)
    audio.context="play";audio._process(.01)
    check("resume keeps same player",not audio.music.stream_paused and audio.music.get_instance_id()==identity)
    audio.music_muted=true;audio._process(.01)
    check("independent music mute retains effect setting",audio.music.stream_paused and not audio.muted and audio.effects_level==.85)
    audio.music_muted=false;audio.music_level=0;audio._process(.01)
    check("music volume zero pauses playback",audio.music.stream_paused)
    audio.music_level=.75;audio._process(.01)
    check("restoring volume resumes",not audio.music.stream_paused)
    audio.muted=true;audio._process(.01)
    check("master mute pauses music",audio.music.stream_paused)
    audio.muted=false;audio._process(.01)
    for i in 20:
        for context in ["title","play","pause","play","result"]:
            audio.context=context;audio._process(.02)
    check("twenty navigation cycles never stack players",audio.get_child_count()==11 and audio.music.get_instance_id()==identity)
    check("effect voices stay bounded and original effects retained",audio.voices.size()==10 and audio.sounds.has("parry") and audio.sounds.has("chase"))
    audio.context="play"
    audio.music.seek(audio.music.stream.get_length()-.06)
    await create_timer(.25).timeout
    check("full-song endpoint wraps on the existing player",audio.music.playing and audio.music.get_playback_position()<1.0 and audio.music.get_instance_id()==identity)
    var peak:=0.0
    var frames:=0
    var capture:=AudioEffectCapture.new()
    AudioServer.add_bus_effect(0,capture)
    audio.context="play"
    audio.play_sound("heavy")
    await create_timer(.25).timeout
    frames=capture.get_frames_available()
    for sample in capture.get_buffer(frames):peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
    AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
    # Dummy audio is permitted to skip mixing; do not turn silence into listening evidence.
    check("captured output if available stays below clipping",frames==0 or peak<1.0)
    var passed:=checks.filter(func(c:Dictionary)->bool:return c.passed).size()
    var report:={"checks":checks,"passed":passed,"capture_frames":frames,"capture_peak":peak,"scope":"Godot runtime playback/control checks; Dummy audio is not a human listening or hardware mix acceptance."}
    var path:="res://../docs/evidence/wev-integration/runtime.json"
    FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    audio.queue_free()
    await process_frame
    await process_frame
    await create_timer(.12).timeout
    capture=null
    fallback=null
    audio=null
    print("WEV_AUDIO_CHECKS ",passed,"/",checks.size()," capture_frames=",frames)
    call_deferred("quit",0 if passed==checks.size() else 1)
