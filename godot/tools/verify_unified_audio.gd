extends SceneTree
## Real engine mixer samples, with Dummy output. Does not prove a hardware speaker.
const OUT="res://../docs/evidence/unified-pixel/"
var checks:Array[Dictionary]=[]
var audio:Node
var capture:AudioEffectCapture
func _initialize() -> void:call_deferred("run")
func check(label:String,passed:bool,detail:Variant=null) -> void:
    checks.append({"check":label,"pass":passed,"detail":detail})
    print("AUDIO ",label," ",passed," ",detail)
func sample(seconds:float) -> Dictionary:
    capture.clear_buffer()
    await create_timer(seconds).timeout
    var samples:=capture.get_buffer(capture.get_frames_available())
    var peak:=0.0;var sum:=0.0;var clipped:=0
    for frame in samples:
        peak=maxf(peak,maxf(absf(frame.x),absf(frame.y)))
        sum+=frame.length_squared()
        if absf(frame.x)>=1.0 or absf(frame.y)>=1.0:clipped+=1
    return {"frames":samples.size(),"peak":peak,"rms":sqrt(sum/maxi(1,samples.size()*2)),"clipped":clipped}
func run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    audio=preload("res://scripts/combat/fight_audio.gd").new();root.add_child(audio)
    capture=AudioEffectCapture.new();capture.buffer_length=2.0;AudioServer.add_bus_effect(0,capture)
    await create_timer(.6).timeout
    var music:Dictionary=await sample(.5)
    check("Menu music reaches Master",music.peak>.01 and music.clipped==0,music)
    audio.music_muted=true
    await create_timer(1.5).timeout
    var silence:Dictionary=await sample(.2)
    audio.play_sound("hit")
    var sfx:Dictionary=await sample(.2)
    check("Music mute preserves effects",silence.peak<.001 and sfx.peak>.01,{"silence":silence,"sfx":sfx})
    audio.muted=true;audio.music_level=0;audio.effects_level=0;AudioServer.set_bus_mute(0,true)
    check("Silent settings detected",audio.silent_settings())
    audio.restore_output()
    await create_timer(.5).timeout
    var restored:Dictionary=await sample(.4)
    check("Restore recovers zero levels and muted Master",not audio.silent_settings() and restored.peak>.01,restored)
    audio.context="play";await create_timer(1.5).timeout
    var position_before:float=audio.music.get_playback_position()
    audio.context="pause";await create_timer(.4).timeout
    check("Pause keeps music transport advancing",audio.music.playing and not audio.music.stream_paused and audio.music.get_playback_position()>position_before,{"before":position_before,"after":audio.music.get_playback_position()})
    audio.context="play";await create_timer(.5).timeout
    audio.play_sound("heavy")
    var fight:Dictionary=await sample(.3)
    check("Fight mix stays nonzero without clipping",fight.peak>.01 and fight.clipped==0,fight)
    var report={"driver":AudioServer.get_driver_name(),"engine":Engine.get_version_info().string,"scope":"Actual engine PCM mixer, no hardware output or listening test","checks":checks}
    var file:=FileAccess.open(OUT+"audio-checks.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
    AudioServer.remove_bus_effect(0,0);audio.queue_free();await create_timer(.2).timeout;capture=null
    var failed:=false
    for row in checks:if not row.pass:failed=true
    quit(1 if failed else 0)
