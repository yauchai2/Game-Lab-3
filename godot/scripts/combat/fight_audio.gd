extends Node
## User-approved wev music, CC0 impacts and original energy layers.
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
const OPEN := "res://audio/open/"
const BERLIN := "res://audio/user-tracks/berlin.ogg"
const GROOVE := "res://audio/user-tracks/groove_district.ogg"
var current_track := ""
const WEV := "res://audio/wev/family_ties_game.ogg"
var music_credit := ""
var music_trim_db := 0.0

func _ready() -> void:
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
        voice.volume_db = -8.0
        voices.append(voice)
    music = AudioStreamPlayer.new()
    music.name = "BackgroundMusic"
    current_track=BERLIN
    music.stream = music_stream(current_track)
    music.volume_db = -19.0+music_trim_db
    add_child(music)

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
    if desired!=current_track:
        music.stop()
        current_track=desired
        music.stream=music_stream(current_track)
    var pause_requested := muted or music_muted or music_level<=0 or context in ["pause","help"]
    # An idle AudioStreamPlayer does not retain stream_paused: use the requested
    # state when deciding to start, then pause/resume an existing playback.
    if not pause_requested and not music.playing: music.play()
    music.stream_paused = pause_requested
    var target_db := (-13.0 if context=="play" else -19.0) - (4.0 if duck_time>0 else 0.0) + music_trim_db + linear_to_db(maxf(.001,music_level))
    music.volume_db = lerpf(music.volume_db,target_db,1.0-exp(-delta*9.0))

func play_sound(kind: String, pitch := 1.0, level_db := 0.0) -> void:
    if muted or effects_level<=0 or not sounds.has(kind): return
    var voice: AudioStreamPlayer = voices[voice_index % voices.size()]
    var variants: Array = sounds[kind]
    voice.stop()
    voice.stream = variants[voice_index % variants.size()]
    voice_index += 1
    voice.volume_db = -8.0+level_db+linear_to_db(maxf(.001,effects_level))
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
