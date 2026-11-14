extends SceneTree
## Corrupt optional files must fail closed to the existing public clips.
const Data=preload("res://scripts/combat/mixamo_motion_library.gd")
func _initialize() -> void:
    if not Data.available():push_error("Install valid private data first");quit(2);return
    var good:Dictionary=Data.data.duplicate(true)
    var original:String=OS.get_environment("GAME_LAB_MOTION_LIBRARY")
    var path:String=OS.get_user_data_dir().path_join("mixamo-invalid-test.json")
    var checks:Array=[]
    for kind in ["schema","base","missing_clip","missing_marker","zero_duration","empty_tracks","index","times","values","nan","quaternion"]:
        var invalid:Dictionary=good.duplicate(true)
        var clip:Dictionary=invalid.clips.MX_Jab
        var index:String=clip.tracks.keys()[0]
        match kind:
            "schema":invalid.schema=99
            "base":invalid.base_sha256="invalid"
            "missing_clip":invalid.clips.erase("MX_Roundhouse")
            "missing_marker":invalid.markers.erase("MX_Hook")
            "zero_duration":clip.duration=0
            "empty_tracks":clip.tracks={}
            "index":clip.tracks["9999"]=clip.tracks[index]
            "times":clip.tracks[index].rotation.times[1]=0
            "values":clip.tracks[index].rotation.values[0]=[0,0]
            "nan":clip.tracks[index].rotation.values[0]=[1e100,0,0,1]
            "quaternion":clip.tracks[index].rotation.values[0]=[0,0,0,0]
        var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(invalid));file.close()
        OS.set_environment("GAME_LAB_MOTION_LIBRARY",path);Data.checked=false;Data.data={}
        checks.append({"name":kind,"ok":not Data.available()})
    DirAccess.remove_absolute(path)
    OS.set_environment("GAME_LAB_MOTION_LIBRARY",path);Data.checked=false;Data.data={}
    checks.append({"name":"missing_file","ok":not Data.available()})
    OS.set_environment("GAME_LAB_MOTION_LIBRARY",original);Data.checked=false;Data.data={}
    checks.append({"name":"valid_reload","ok":Data.available()})
    var passed:=0
    for item in checks:
        if item.ok:passed+=1
        else:push_error(item.name)
    var args:PackedStringArray=OS.get_cmdline_user_args()
    if not args.is_empty():FileAccess.open(args[0],FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":passed,"total":checks.size()},"  "))
    print("MIXAMO_LIBRARY ",passed,"/",checks.size())
    quit(0 if passed==checks.size() else 1)
