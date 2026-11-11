extends RefCounted
## Small, validated local preferences; no player data or telemetry.
const DEFAULTS := {"muted":false,"retro_pixels":true,"music_muted":false,"reduced_effects":false,"scene_edges":false,"difficulty":1,"partner_mode":0,"language":"en","training_details":false,"music_level":0.75,"effects_level":0.85,"player_character":0,"rival_character":1,"p1_device":0,"p2_device":0}
func read_options(path: String) -> Dictionary:
    var values := DEFAULTS.duplicate()
    if path.is_empty(): return values
    var file := ConfigFile.new()
    if file.load(path)!=OK: return values
    for key in DEFAULTS:
        var value: Variant = file.get_value("options",key,DEFAULTS[key])
        if typeof(value)==typeof(DEFAULTS[key]): values[key]=value
    values.difficulty = clampi(values.difficulty,0,2)
    values.partner_mode = clampi(values.partner_mode,0,2)
    for key in ["player_character","rival_character"]:values[key]=clampi(values[key],0,3)
    for key in ["p1_device","p2_device"]:values[key]=clampi(values[key],0,2)
    values.language=values.language if values.language in ["zh","en"] else "zh"
    values.music_level=clampf(values.music_level,0,1)
    values.effects_level=clampf(values.effects_level,0,1)
    return values
func write_options(path: String, values: Dictionary) -> Error:
    if path.is_empty(): return OK
    var file := ConfigFile.new()
    for key in DEFAULTS:
        var value: Variant = values.get(key,DEFAULTS[key])
        if typeof(value)!=typeof(DEFAULTS[key]): value=DEFAULTS[key]
        if key in ["difficulty","partner_mode","p1_device","p2_device"]: value=clampi(value,0,2)
        if key in ["player_character","rival_character"]:value=clampi(value,0,3)
        if key=="language" and value not in ["zh","en"]:value="zh"
        if key in ["music_level","effects_level"]:value=clampf(value,0,1)
        file.set_value("options",key,value)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
    return file.save(path)
