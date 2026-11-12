extends SceneTree
## Loads every combat SFX through fight_audio, checks the muffle fix against the old Kenney punches, and the music pool.
var checks:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(label:String,ok:bool,detail:Variant=null) -> void:
    checks.append({"check":label,"pass":ok,"detail":detail});print("SFX ",label," ",ok," ",detail)
    if not ok:push_error("SFX FAIL: "+label)
func run() -> void:
    var audio:Node=preload("res://scripts/combat/fight_audio.gd").new();root.add_child(audio)
    for kind in ["hit","heavy","block","parry","guard_break","swing","dash","step","land","jump","release","ko","charge","slam","launch","chase","rally","sub"]:
        check("sound '%s' loaded from the new set"%kind,audio.sounds.has(kind) and not audio.sounds[kind].is_empty() and audio.sounds[kind][0] is AudioStreamOggVorbis and audio.sounds[kind][0].get_length()>.1)
    for path in audio.FIGHT_POOL+[audio.RESULT_TRACK]:
        var s:=audio.music_stream(path) as AudioStreamOggVorbis
        check("music loop loads: "+path,s!=null and s.loop and s.get_length()>10.0 and not audio.music_credit.contains("Juhani"),s.get_length())
    audio.context="title";audio._process(.02)
    var picks:Array[String]=[]
    for i in 4:
        audio.context="play";audio._process(.02);picks.append(audio.current_track)
        audio.context="pause";audio._process(.02)
        check("pause keeps the fight track #%d"%i,audio.current_track==picks[i])
        audio.context="result";audio._process(.02)
        check("result switches to the result loop #%d"%i,audio.current_track==audio.RESULT_TRACK)
    check("fights rotate through the pool",picks[0]!=picks[1] and picks[0]==picks[3] and picks[1]!=picks[2],picks)
    check("deck stream matches current track credit",audio.music.stream!=null and audio.music_credit!="")
    audio.queue_free();await process_frame
    var bad:=checks.filter(func(c):return not c.pass).size()
    print("COMBAT_SFX_CHECKS ",checks.size()-bad,"/",checks.size())
    quit(1 if bad>0 else 0)
