extends Node
## User supplied music, CC0 impacts and explicit recoverable output routing.
var muted := false
var music_muted := false
var music_level := 0.75
var effects_level := 0.85
var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var voice_index := 0
var music: AudioStreamPlayer
var context := "title"
var duck_time := 0.0
var cinematic_duck := 0.0
const OPEN := "res://audio/open/"
const BERLIN := "res://audio/user-tracks/berlin.ogg"
const GROOVE := "res://audio/user-tracks/groove_district.ogg"
var current_track := ""
var fading_music: AudioStreamPlayer
var fading_track := ""
var crossfade := 1.0
var music_gain_db := -19.0
const CROSSFADE_SECONDS := 1.2
const WEV := "res://audio/wev/family_ties_game.ogg"
var music_credit := ""
var music_trim_db := 0.0

func _ready() -> void:
    _ensure_buses()
    var files := {
        "hit":["impactPunch_medium_000","impactPunch_medium_001","impactPunch_medium_002"],
        "heavy":["impactPunch_heavy_000","impactPunch_heavy_001"],
        "block":["impactMetal_light_000"], "parry":["impactBell_heavy_003"],
        "guard_break":["impactGlass_heavy_000"], "swing":["impactSoft_medium_001"],
        "dash":["impactSoft_heavy_000"], "step":["footstep_concrete_000","footstep_concrete_003"],
        "land":["footstep_concrete_003"], "jump":["footstep_concrete_000"],
        "release":["impactTin_medium_001"], "ko":["impactMetal_heavy_003"]}
    for kind in files:
        sounds[kind] = []
        for filename in files[kind]: sounds[kind].append(load(OPEN+filename+".ogg"))
    sounds["charge"] = [_tone(0.28,65.0,120.0,0.08)]
    sounds["slam"] = [_tone(.25,120.0,32.0,.24)]
    sounds["launch"] = [_tone(.15,140.0,700.0,.08)]
    sounds["chase"] = [_tone(.16,180.0,540.0,.05)]
    sounds["rally"] = [_tone(0.14,360.0,105.0,0.10)]
    sounds["sub"] = [_tone(0.17,100.0,30.0,0.20)]
    for i in 10:
        var voice := AudioStreamPlayer.new()
        add_child(voice)
        voice.bus="Afterhours SFX"
        voice.volume_db = -4.0
        voices.append(voice)
    music = AudioStreamPlayer.new()
    music.name = "BackgroundMusic"
    # Long tracks must stream on Web instead of decoding entire 192kHz songs as samples.
    if OS.has_feature("web"):music.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
    music.bus="Afterhours Music"
    current_track=BERLIN
    music.stream = music_stream(current_track)
    music.volume_db = -19.0+music_trim_db
    add_child(music)
    fading_music=AudioStreamPlayer.new()
    fading_music.name="MusicCrossfade"
    if OS.has_feature("web"):fading_music.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
    fading_music.bus="Afterhours Music"
    fading_music.volume_db=-80.0
    fading_music.stream=music_stream(GROOVE)
    fading_track=GROOVE
    music_credit="Berlin"
    add_child(fading_music)

func music_stream(path: String) -> AudioStreamOggVorbis:
    var selected:=path if ResourceLoader.exists(path,"AudioStreamOggVorbis") else OPEN+"level1.ogg"
    var source:=load(selected) as AudioStreamOggVorbis
    if source==null:
        selected=OPEN+"level1.ogg"
        source=load(selected) as AudioStreamOggVorbis
    music_trim_db=0.0
    music_credit="Berlin" if selected==BERLIN else ("Starjunk 95 / Groove District" if selected==GROOVE else "Juhani Junkala / Level 1 (CC0)")
    var track: AudioStreamOggVorbis=source.duplicate(true)
    track.loop=true
    return track

func _process(delta: float) -> void:
    duck_time = maxf(0.0,duck_time-delta)
    if not is_instance_valid(music): return
    # Keep a fight track across pause/settings; switch only when entering title/play.
    var desired:String=GROOVE if context=="play" else (BERLIN if context=="title" else current_track)
    if desired!=current_track:_switch_track(desired)
    # Navigation never pauses the transport. Explicit mute/zero volume silence it.
    if not music.playing:music.play()
    music.stream_paused=false
    fading_music.stream_paused=false
    var target_db:float=(-4.0 if context=="play" else (-15.0 if context in ["pause","help"] else -7.0))-(4.0 if duck_time>0 else 0.0)-cinematic_duck*8.0
    if muted or music_muted or music_level<=0:target_db=-80.0
    else:target_db+=linear_to_db(maxf(.001,music_level))
    music_gain_db=lerpf(music_gain_db,target_db,1.0-exp(-delta*7.0))
    crossfade=minf(1.0,crossfade+delta/CROSSFADE_SECONDS)
    music.volume_db=music_gain_db+linear_to_db(maxf(.0001,sin(crossfade*PI*.5)))
    fading_music.volume_db=music_gain_db+linear_to_db(maxf(.0001,cos(crossfade*PI*.5)))
    if crossfade>=1.0 and fading_music.playing:fading_music.stop()

func _switch_track(path:String) -> void:
    if fading_music.playing and path==fading_track:
        var reversal_deck:AudioStreamPlayer=music
        music=fading_music;fading_music=reversal_deck
        var old:String=current_track;current_track=fading_track;fading_track=old
        crossfade=1.0-crossfade
        music_credit="Berlin" if current_track==BERLIN else "Starjunk 95 / Groove District"
        return
    fading_music.stop() # Already silent when starting a new two-song transition.
    var swap:AudioStreamPlayer=music
    music=fading_music;fading_music=swap
    fading_track=current_track;current_track=path
    # Each song keeps its dedicated stream; navigation reuses it.
    music_credit="Berlin" if path==BERLIN else "Starjunk 95 / Groove District"
    music.volume_db=-80.0
    music.play()
    crossfade=0.0

func play_sound(kind: String, pitch := 1.0, level_db := 0.0) -> void:
    if muted or effects_level<=0 or not sounds.has(kind): return
    var voice: AudioStreamPlayer = voices[voice_index % voices.size()]
    var variants: Array = sounds[kind]
    voice.stop()
    voice.stream = variants[voice_index % variants.size()]
    voice_index += 1
    voice.volume_db = -4.0+minf(0.0,level_db)+linear_to_db(maxf(.001,effects_level))
    voice.pitch_scale = clampf(pitch,0.65,1.55)
    voice.play()
    if kind in ["hit","heavy","parry","guard_break","rally","release"]: duck_time = 0.18

func stop_all() -> void:
    for voice in voices: voice.stop()

func _exit_tree() -> void:
    for voice in voices:
        voice.stream_paused = false
        if voice.has_stream_playback(): voice.get_stream_playback().stop()
        voice.stop()
        voice.stream = null
    if is_instance_valid(fading_music):
        fading_music.stream_paused=false
        if fading_music.has_stream_playback():fading_music.get_stream_playback().stop()
        fading_music.stop()
        fading_music.stream=null
    if is_instance_valid(music):
        music.stream_paused = false
        if music.has_stream_playback(): music.get_stream_playback().stop()
        music.stop()
        music.stream = null

func _tone(duration: float, start: float, end: float, noise: float) -> AudioStreamWAV:
    var rate := 22050
    var count := int(duration * rate)
    var data := PackedByteArray()
    data.resize(count * 2)
    var phase := 0.0
    var rng := RandomNumberGenerator.new()
    rng.seed = 73
    for i in count:
        var t := float(i) / count
        phase += TAU * lerpf(start, end, t) / rate
        var envelope := minf(1.0, t * 80.0) * pow(1.0 - t, 2.0)
        var sample := (sin(phase) * 0.65 + sin(phase * 2.7) * 0.12 + rng.randf_range(-noise, noise)) * envelope
        data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 26000))
    var result := AudioStreamWAV.new()
    result.format = AudioStreamWAV.FORMAT_16_BITS
    result.mix_rate = rate
    result.data = data
    return result

func _ensure_buses() -> void:
    for label in ["Afterhours Music","Afterhours SFX"]:
        if AudioServer.get_bus_index(label)<0:
            AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,label)
            AudioServer.set_bus_send(AudioServer.bus_count-1,"Master")

    var sfx_bus:int=AudioServer.get_bus_index("Afterhours SFX")
    var has_limiter:=false
    for i in AudioServer.get_bus_effect_count(sfx_bus):
        if AudioServer.get_bus_effect(sfx_bus,i) is AudioEffectLimiter:has_limiter=true
    if not has_limiter:
        var limiter:=AudioEffectLimiter.new()
        limiter.ceiling_db=-6.0
        limiter.threshold_db=-6.0
        AudioServer.add_bus_effect(sfx_bus,limiter)

func silent_settings() -> bool:
    for label in ["Afterhours Music","Afterhours SFX"]:
        var index:int=AudioServer.get_bus_index(label)
        if index>=0 and (AudioServer.is_bus_mute(index) or AudioServer.get_bus_volume_db(index)<=-60):return true
    return muted or music_muted or music_level<=0 or effects_level<=0 or AudioServer.is_bus_mute(0) or AudioServer.get_bus_volume_db(0)<=-60

func restore_output() -> void:
    muted=false;music_muted=false;music_level=.8;effects_level=.9
    for label in ["Master","Afterhours Music","Afterhours SFX"]:
        var index:int=AudioServer.get_bus_index(label)
        if index>=0:AudioServer.set_bus_mute(index,false);AudioServer.set_bus_volume_db(index,0.0)
    _process(.02)
    play_sound("parry",1.0,-3)

func status_text() -> String:
    if AudioServer.get_driver_name()=="Dummy":return "No audio output device / use a real audio driver"
    if muted:return "Sound muted / restore to hear music and effects"
    if AudioServer.is_bus_mute(0):return "Output muted / restore sound"
    if music_muted or music_level<=0:return "Music off / effects level %d%%"%roundi(effects_level*100)
    return "Music %d%% / Effects %d%%"%[roundi(music_level*100),roundi(effects_level*100)]
