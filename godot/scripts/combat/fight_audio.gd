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
var contact_budget := 0.0
var contact_layers_played := 0
var duck_time := 0.0
var cinematic_duck := 0.0
const OPEN := "res://audio/open/"
const SFX := "res://audio/sfx/"
# All music is cut from one supplied playlist (tools/build_playlist_music.py). music.json has each file's intro/loop timing.
const MUSIC_DIR:="res://audio/music/"
const MENU_TRACK:="res://audio/music/menu.ogg"
const FIGHT_POOL:Array[String]=["res://audio/music/fight_a.ogg","res://audio/music/fight_b.ogg","res://audio/music/fight_c.ogg"]
const RESULT_TRACK:="res://audio/music/result.ogg"
const MUSIC_STATE_PATH:="user://neon_lab/music.cfg"
var music_meta:Dictionary={}
var intro_seen:=false # the menu build-up plays only until it has been heard once; later launches start inside the loop
var fight_index:=0
var fight_pick:String=FIGHT_POOL[0]
var last_context:="title"
var match_over:=false # set by the session when a result screen ends the whole match (not just a round)
var ui_last:Dictionary={}
const IMPACT_KINDS:=["hit","heavy","slam","ko","launch","release","guard_break","block","parry"]
const BIG_KINDS:=["heavy","slam","ko","release","guard_break"]
# Pacing: "heat" rises with impacts and cools while nothing lands. A cool fight sits back (darker, quieter) and a hot one opens up.
const HEAT_BUMP:={"block":.05,"hit":.10,"parry":.14,"launch":.2,"heavy":.22,"guard_break":.3,"slam":.34,"release":.4,"ko":.5}
const HEAT_COOL_PER_SECOND:=.085
const CALM_CUTOFF_HZ:=1500.0
const OPEN_CUTOFF_HZ:=20000.0
const CALM_GAIN_DB:=-7.0 # calm sits this far under the hot level (round 3: wider swing)
const MENU_CUTOFF_HZ:=7500.0
const RESULT_CUTOFF_HZ:=5200.0
const PAUSE_CUTOFF_HZ:=1400.0
var heat:=0.25
var music_cutoff_hz:=OPEN_CUTOFF_HZ
var duck_db:=4.0 # how far the music dips under the last impact (bigger for finishers)
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
    # Combat SFX: real CC0 recordings (BigSoundBank) layered with synthetic low end, see godot/audio/sfx/SOURCES.md.
    # Procedural-only kinds come from tools/build_combat_sfx.py. Kenney CC0 impacts stay as fallback.
    var files := {
        "hit":["hit_0","hit_1","hit_2","hit_3","hit_4"], "heavy":["heavy_0","heavy_1","heavy_2"],
        "block":["block_0","block_1"], "parry":["parry_0"], "guard_break":["guard_break_0"],
        "swing":["swing_0","swing_1","swing_2"], "dash":["dash_0"], "step":["step_0","step_1"],
        "land":["land_0"], "jump":["jump_0"], "release":["release_0"], "ko":["ko_0"],
        "charge":["charge_0"], "slam":["slam_0","slam_1"], "launch":["launch_0"], "chase":["chase_0"],
        "rally":["rally_0"], "sub":["sub_0"],
        "ui_move":["ui_move_0"], "ui_confirm":["ui_confirm_0"], "ui_back":["ui_back_0"], "ui_toggle":["ui_toggle_0"], "ui_pause":["ui_pause_0"]}
    var fallback := {
        "hit":["impactPunch_medium_000","impactPunch_medium_001"], "heavy":["impactPunch_heavy_000"],
        "block":["impactMetal_light_000"], "parry":["impactBell_heavy_003"], "guard_break":["impactGlass_heavy_000"],
        "swing":["impactSoft_medium_001"], "dash":["impactSoft_heavy_000"], "step":["footstep_concrete_000"],
        "land":["footstep_concrete_003"], "jump":["footstep_concrete_000"], "release":["impactTin_medium_001"], "ko":["impactMetal_heavy_003"]}
    for kind in files:
        sounds[kind] = []
        for filename in files[kind]:
            var path:String=SFX+filename+".ogg"
            if ResourceLoader.exists(path):sounds[kind].append(load(path))
        if sounds[kind].is_empty() and fallback.has(kind):
            for filename in fallback[kind]:sounds[kind].append(load(OPEN+filename+".ogg"))
        if sounds[kind].is_empty():sounds[kind].append(_tone(.2,120.0,40.0,.1))
    sounds["ink_snap"]=[_tone(.045,1700.0,260.0,.32)]
    sounds["ink_scrape"]=[_tone(.09,480.0,110.0,.48)]
    for character in 4:
        sounds["fighter_%d"%character]=[_fighter_tone(character)]
    for i in 10:
        var voice := AudioStreamPlayer.new()
        add_child(voice)
        voice.bus="Afterhours SFX"
        voice.volume_db = -3.0
        voices.append(voice)
    music = AudioStreamPlayer.new()
    music.name = "BackgroundMusic"
    # Long tracks must stream on Web instead of decoding entire 192kHz songs as samples.
    if OS.has_feature("web"):music.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
    music.bus="Afterhours Music"
    _load_music_state()
    current_track=MENU_TRACK
    music.stream = music_stream(current_track)
    music.volume_db = -19.0+music_trim_db
    add_child(music)
    fading_music=AudioStreamPlayer.new()
    fading_music.name="MusicCrossfade"
    if OS.has_feature("web"):fading_music.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
    fading_music.bus="Afterhours Music"
    fading_music.volume_db=-80.0
    fading_music.stream=music_stream(FIGHT_POOL[0])
    fading_track=FIGHT_POOL[0]
    music_credit=credit_for(MENU_TRACK)
    add_child(fading_music)

func credit_for(path:String) -> String:
    if path.begins_with(MUSIC_DIR):return "Breakbeat playlist (supplied) / "+path.get_file().get_basename().replace("_"," ")
    if path==BERLIN:return "Berlin"
    if path==GROOVE:return "Starjunk 95 / Groove District"
    return "Juhani Junkala / Level 1 (CC0)"

func _load_music_state() -> void:
    if FileAccess.file_exists(MUSIC_DIR+"music.json"):
        var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(MUSIC_DIR+"music.json"))
        if parsed is Dictionary:music_meta=parsed
    var cfg:=ConfigFile.new()
    if cfg.load(MUSIC_STATE_PATH)==OK:intro_seen=bool(cfg.get_value("music","intro_seen",false))

func _save_music_state() -> void:
    DirAccess.make_dir_recursive_absolute(MUSIC_STATE_PATH.get_base_dir())
    var cfg:=ConfigFile.new()
    cfg.set_value("music","intro_seen",intro_seen)
    cfg.save(MUSIC_STATE_PATH)

func _meta(path:String) -> Dictionary:
    return music_meta.get(path.get_file().get_basename(),{})

## Where a track starts. The menu build-up is heard once; afterwards the menu starts at a random bar inside its loop.
func start_position(path:String) -> float:
    var info:=_meta(path)
    if path!=MENU_TRACK or info.is_empty():return 0.0
    var offset:float=float(info.get("intro_seconds",0.0))
    if not intro_seen:
        intro_seen=true;_save_music_state()
        return 0.0
    var bars:int=maxi(1,roundi(float(info.get("loop_seconds",0.0))/float(info.get("bar_seconds",1.0))))
    return offset+float(randi()%bars)*float(info.get("bar_seconds",0.0))

## Settings action: forget that the intro was heard and play it again now if the menu track is playing.
func replay_intro() -> void:
    intro_seen=false;_save_music_state()
    if current_track==MENU_TRACK and is_instance_valid(music):
        intro_seen=true;_save_music_state()
        music.seek(0.0)

func music_stream(path: String) -> AudioStreamOggVorbis:
    var selected:=path if ResourceLoader.exists(path,"AudioStreamOggVorbis") else OPEN+"level1.ogg"
    var source:=load(selected) as AudioStreamOggVorbis
    if source==null:
        selected=OPEN+"level1.ogg"
        source=load(selected) as AudioStreamOggVorbis
    music_trim_db=0.0
    music_credit=credit_for(selected)
    var track: AudioStreamOggVorbis=source.duplicate(true)
    track.loop=true
    var info:=_meta(selected)
    if not info.is_empty():track.loop_offset=float(info.get("intro_seconds",0.0))
    return track

func _process(delta: float) -> void:
    contact_budget=maxf(0.0,contact_budget-delta)
    duck_time = maxf(0.0,duck_time-delta)
    if not is_instance_valid(music): return
    # Keep a fight track across pause/settings; switch only when entering title/play.
    # A new match (title/result -> play) advances through the fight pool; pause/help/rounds keep the track.
    if context=="play" and (last_context=="title" or (last_context=="result" and match_over)):
        fight_pick=FIGHT_POOL[fight_index%FIGHT_POOL.size()];fight_index+=1;match_over=false
    if context=="play" and last_context!="play" and last_context!="pause" and last_context!="help":heat=.2 # every new fight starts on a breather
    last_context=context
    if context=="play":heat=maxf(0.0,heat-HEAT_COOL_PER_SECOND*delta)
    var desired:String=fight_pick if context=="play" else (MENU_TRACK if context=="title" else (RESULT_TRACK if context=="result" and match_over else current_track))
    if desired!=current_track:_switch_track(desired)
    # Navigation never pauses the transport. Explicit mute/zero volume silence it.
    if not music.playing:music.play(start_position(current_track))
    music.stream_paused=false
    fading_music.stream_paused=false
    var calm:=1.0-smoothstep(.05,.55,heat)
    var base_db:float=-3.0+CALM_GAIN_DB*calm if context=="play" else (-15.0 if context in ["pause","help"] else (-8.5 if context=="title" else -8.0))
    var target_db:float=base_db-(duck_db if duck_time>0 else 0.0)-cinematic_duck*8.0
    if muted or music_muted or music_level<=0:target_db=-80.0
    else:target_db+=linear_to_db(maxf(.001,music_level))
    music_gain_db=lerpf(music_gain_db,target_db,1.0-exp(-delta*(7.0 if context!="play" else 2.2)))
    _update_music_filter(calm,delta)
    crossfade=minf(1.0,crossfade+delta/CROSSFADE_SECONDS)
    music.volume_db=music_gain_db+linear_to_db(maxf(.0001,sin(crossfade*PI*.5)))
    fading_music.volume_db=music_gain_db+linear_to_db(maxf(.0001,cos(crossfade*PI*.5)))
    if crossfade>=1.0 and fading_music.playing:fading_music.stop()

## Calm stretches roll the highs off the music bus; heat opens them again. Menus sit in between, pause is muffled.
func _update_music_filter(calm:float,delta:float) -> void:
    var wanted:float=lerpf(OPEN_CUTOFF_HZ,CALM_CUTOFF_HZ,calm) if context=="play" else (PAUSE_CUTOFF_HZ if context in ["pause","help"] else (MENU_CUTOFF_HZ if context=="title" else RESULT_CUTOFF_HZ))
    var rate:=(3.0 if wanted>music_cutoff_hz else 1.4)*delta # opens quickly on action, closes slowly during a lull
    music_cutoff_hz=exp(lerpf(log(music_cutoff_hz),log(wanted),clampf(rate,0.0,1.0)))
    var bus:int=AudioServer.get_bus_index("Afterhours Music")
    if bus<0:return
    for i in AudioServer.get_bus_effect_count(bus):
        var effect:=AudioServer.get_bus_effect(bus,i)
        if effect is AudioEffectLowPassFilter:(effect as AudioEffectLowPassFilter).cutoff_hz=music_cutoff_hz

func _switch_track(path:String) -> void:
    if fading_music.playing and path==fading_track:
        var reversal_deck:AudioStreamPlayer=music
        music=fading_music;fading_music=reversal_deck
        var old:String=current_track;current_track=fading_track;fading_track=old
        crossfade=1.0-crossfade
        music_credit=credit_for(current_track)
        return
    fading_music.stop() # Already silent when starting a new two-song transition.
    var swap:AudioStreamPlayer=music
    music=fading_music;fading_music=swap
    fading_track=current_track;current_track=path
    # The incoming deck loads the new loop; the outgoing deck keeps playing its own until the crossfade ends.
    music.stream=music_stream(path)
    music_credit=credit_for(path)
    music.volume_db=-80.0
    music.play(start_position(path))
    crossfade=0.0

func play_sound(kind: String, pitch := 1.0, level_db := 0.0) -> void:
    if HEAT_BUMP.has(kind) and context=="play":heat=minf(1.0,heat+float(HEAT_BUMP[kind]))
    if muted or effects_level<=0 or not sounds.has(kind): return
    if kind.begins_with("ui_"):
        var now:=Time.get_ticks_msec()
        if now-int(ui_last.get(kind,-1000))<55: return
        ui_last[kind]=now
    var voice: AudioStreamPlayer = voices[voice_index % voices.size()]
    var variants: Array = sounds[kind]
    voice.stop()
    voice.stream = variants[voice_index % variants.size()]
    voice_index += 1
    # Impacts keep most of their level: call sites ask for -6..-12 dB, which made hits sit under the music.
    var impact:bool=kind in IMPACT_KINDS
    voice.volume_db = (-2.0 if impact else -3.0)+minf(0.0,level_db*(.6 if impact else 1.0))+linear_to_db(maxf(.001,effects_level))
    voice.pitch_scale = clampf(pitch,0.65,1.55)
    voice.play()
    if kind in ["hit","heavy","parry","guard_break","rally","release","slam","ko","launch"]:
        duck_time = 0.34 if kind in BIG_KINDS else 0.18
        duck_db = 7.0 if kind in BIG_KINDS else 4.0

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

    var music_bus:int=AudioServer.get_bus_index("Afterhours Music")
    var has_filter:=false
    for i in AudioServer.get_bus_effect_count(music_bus):
        if AudioServer.get_bus_effect(music_bus,i) is AudioEffectLowPassFilter:has_filter=true
    if not has_filter:
        var filter:=AudioEffectLowPassFilter.new()
        filter.cutoff_hz=OPEN_CUTOFF_HZ;filter.resonance=.6
        AudioServer.add_bus_effect(music_bus,filter)
    var sfx_bus:int=AudioServer.get_bus_index("Afterhours SFX")
    var has_limiter:=false
    for i in AudioServer.get_bus_effect_count(sfx_bus):
        if AudioServer.get_bus_effect(sfx_bus,i) is AudioEffectLimiter:has_limiter=true
    var has_compressor:=false
    for i in AudioServer.get_bus_effect_count(sfx_bus):
        if AudioServer.get_bus_effect(sfx_bus,i) is AudioEffectCompressor:has_compressor=true
    if not has_compressor:
        var compressor:=AudioEffectCompressor.new()
        compressor.threshold=-12.0;compressor.ratio=3.0;compressor.attack_us=1500.0;compressor.release_ms=120.0;compressor.gain=3.0
        AudioServer.add_bus_effect(sfx_bus,compressor,0)
    if not has_limiter:
        var limiter:=AudioEffectLimiter.new()
        limiter.ceiling_db=-2.0
        limiter.threshold_db=-3.0
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

## Short authored material layer. Existing CC0 body hit and SFX limiter stay owners.
func play_contact_layer(character:int,move:String,strength:float) -> void:
    if contact_budget>0 or muted or effects_level<=0:return
    contact_budget=.075
    if character<0 or character>3:
        var scrape:bool=move in ["meteor","heavy","air_kick","air_counter"]
        play_sound("ink_scrape" if scrape else "ink_snap",.92,-17.0 if strength<.55 else -12.0)
        contact_layers_played+=1
        return
    var family:String="fighter_%d"%character
    play_sound(family,.94 if move in ["heavy","overdrive"] else 1.0,-13.0 if strength<.55 else -8.0)
    contact_layers_played+=1

## Original deterministic material accents; CC0 recorded body impact remains beneath.
func _fighter_tone(character:int) -> AudioStreamWAV:
    var rate:=22050
    var duration:float=[.11,.19,.055,.14][character]
    var count:=int(duration*rate)
    var data:=PackedByteArray();data.resize(count*2)
    var rng:=RandomNumberGenerator.new();rng.seed=170+character
    var phase:=0.0
    var previous:=0.0
    for i in count:
        var t:float=float(i)/rate
        var u:float=float(i)/count
        var noise:float=rng.randf_range(-1.0,1.0)
        var sample:=0.0
        match character:
            0:
                phase+=TAU*lerpf(2600,650,u)/rate
                sample=(noise-previous)*.24+sin(phase)*.18
            1:
                phase+=TAU*lerpf(140,48,u)/rate
                sample=sin(phase)*.65+sin(phase*3.13)*.18+noise*.08
            2:sample=(noise-previous)*.45*exp(-u*7.0)
            3:
                sample=(sin(TAU*740*t)+sin(TAU*1190*t)*.4)*.32
                if u>.32 and u<.48:sample=0.0
        previous=noise
        sample*=minf(1.0,u*100.0)*pow(1.0-u,2.0)
        data.encode_s16(i*2,int(clampf(sample,-.95,.95)*28000))
    var stream:=AudioStreamWAV.new()
    stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=rate;stream.data=data
    return stream
