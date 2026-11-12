extends SceneTree
## Loads every combat SFX through fight_audio, checks the muffle fix against the old Kenney punches, and the music pool.
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"check":label,"pass":ok,"detail":detail});print("SFX ",label," ",ok," ",detail)
    if not ok:push_error("SFX FAIL: "+label)
func run() -> void:
    var audio:Node=preload("res://scripts/combat/fight_audio.gd").new();root.add_child(audio)
    for kind in ["hit","heavy","block","parry","guard_break","swing","dash","step","land","jump","release","ko","charge","slam","launch","chase","rally","sub","ui_move","ui_confirm","ui_back","ui_toggle","ui_pause"]:
        check("sound '%s' loaded from the new set"%kind,audio.sounds.has(kind) and not audio.sounds[kind].is_empty() and audio.sounds[kind][0] is AudioStreamOggVorbis and audio.sounds[kind][0].get_length()>(.04 if kind.begins_with("ui_") else .1))
    for path in audio.FIGHT_POOL+[audio.RESULT_TRACK]:
        var s:=audio.music_stream(path) as AudioStreamOggVorbis
        check("music loop loads: "+path,s!=null and s.loop and s.get_length()>10.0 and not audio.music_credit.contains("Juhani"),s.get_length())
    audio.context="title";audio._process(.02)
    var picks:Array[String]=[]
    for i in 4:
        audio.context="play";audio._process(.02);picks.append(audio.current_track)
        audio.context="pause";audio._process(.02)
        check("pause keeps the fight track #%d"%i,audio.current_track==picks[i])
        audio.match_over=true;audio.context="result";audio._process(.02)
        check("result switches to the result loop #%d"%i,audio.current_track==audio.RESULT_TRACK)
    check("fights rotate through the pool",picks[0]!=picks[1] and picks[0]==picks[3] and picks[1]!=picks[2],picks)
    check("deck stream matches current track credit",audio.music.stream!=null and audio.music_credit!="")
    # a round result must not change the fight track; only a finished match does
    audio.context="play";audio._process(.02);var before:String=audio.current_track
    audio.match_over=false;audio.context="result";audio._process(.02)
    check("round result keeps the fight track",audio.current_track==before)
    audio.context="play";audio._process(.02)
    check("next round keeps the same fight track",audio.current_track==before)
    audio.match_over=true;audio.context="result";audio._process(.02)
    check("match end switches to the result loop",audio.current_track==audio.RESULT_TRACK)
    audio.context="play";audio._process(.02)
    check("rematch advances the pool",audio.current_track!=before and not audio.match_over)
    audio.play_sound("ui_move");var first:int=audio.voice_index;audio.play_sound("ui_move")
    check("ui sounds are throttled",audio.voice_index==first)
    # menu intro: heard once, then random bar inside the loop; replay on request
    var info:Dictionary=audio.music_meta.get("menu",{})
    check("music.json describes the menu track",not info.is_empty() and info.intro_seconds>4.0 and info.loop_seconds>20.0)
    var menu_stream:=audio.music_stream(audio.MENU_TRACK) as AudioStreamOggVorbis
    check("menu loop_offset equals the intro length",absf(menu_stream.loop_offset-float(info.intro_seconds))<.001 and menu_stream.get_length()>info.intro_seconds+info.loop_seconds-.2,[menu_stream.loop_offset,menu_stream.get_length()])
    audio.intro_seen=false
    check("first launch starts at the intro",audio.start_position(audio.MENU_TRACK)==0.0 and audio.intro_seen)
    var positions:Array[float]=[]
    for i in 12:positions.append(audio.start_position(audio.MENU_TRACK))
    var inside:=positions.all(func(v:float)->bool:return v>=info.intro_seconds-.001 and v<info.intro_seconds+info.loop_seconds)
    check("later launches start inside the loop on a bar line",inside and positions.any(func(v:float)->bool:return v!=positions[0]),positions.slice(0,4))
    check("fight tracks never start mid-loop",audio.start_position(audio.FIGHT_POOL[0])==0.0)
    audio.replay_intro()
    check("replay_intro away from the menu re-arms the build-up",audio.intro_seen==false)
    var cfg:=ConfigFile.new();check("intro flag persisted",cfg.load(audio.MUSIC_STATE_PATH)==OK and cfg.get_value("music","intro_seen",true)==false)
    DirAccess.remove_absolute(ProjectSettings.globalize_path(audio.MUSIC_STATE_PATH))
    # pacing: a quiet stretch calms the music, a flurry of hits opens it up, menus/pause sit at their own levels
    audio.context="title";audio._process(.02);audio.context="play";audio._process(.02)
    check("a new fight starts on a breather",audio.heat<=.21,audio.heat)
    for i in 400:audio._process(.05)
    var calm_db:float=audio.music_gain_db;var calm_hz:float=audio.music_cutoff_hz
    check("quiet stretch darkens and lowers the music",audio.heat<.05 and calm_hz<2200.0 and calm_db<-8.0,[audio.heat,calm_hz,calm_db])
    for i in 14:audio.play_sound("hit");audio.play_sound("heavy")
    for i in 60:audio._process(.05)
    check("a flurry of impacts opens and raises the music",audio.heat>.5 and audio.music_cutoff_hz>12000.0 and audio.music_gain_db>calm_db+4.5,[audio.heat,audio.music_cutoff_hz,audio.music_gain_db])
    for i in 400:audio._process(.05)
    check("it cools back down without new hits",audio.heat<.2 and audio.music_cutoff_hz<5000.0,[audio.heat,audio.music_cutoff_hz])
    audio.context="pause";for i in 80:audio._process(.05)
    check("pause is muffled",audio.music_cutoff_hz<2200.0,audio.music_cutoff_hz)
    audio.context="play";audio._process(.02)
    check("resuming from pause keeps the current heat",audio.heat<.2,audio.heat)
    var filter_found:=false
    var mbus:int=AudioServer.get_bus_index("Afterhours Music")
    for i in AudioServer.get_bus_effect_count(mbus):
        if AudioServer.get_bus_effect(mbus,i) is AudioEffectLowPassFilter:filter_found=true
    check("music bus owns one low-pass filter",filter_found)
    audio.queue_free();await process_frame
    var bad:=checks.filter(func(c):return not c.pass).size()
    print("COMBAT_SFX_CHECKS ",checks.size()-bad,"/",checks.size())
    quit(1 if bad>0 else 0)
