extends RefCounted
## Small, validated local preferences; no player data or telemetry.
const DEFAULTS := {"muted":false,"music_muted":false,"reduced_effects":false,"scene_edges":false,"difficulty":1,"partner_mode":0}
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
    return values
func write_options(path: String, values: Dictionary) -> Error:
    if path.is_empty(): return OK
    var file := ConfigFile.new()
    for key in DEFAULTS:
        var value: Variant = values.get(key,DEFAULTS[key])
        if typeof(value)!=typeof(DEFAULTS[key]): value=DEFAULTS[key]
        if key in ["difficulty","partner_mode"]: value=clampi(value,0,2)
        file.set_value("options",key,value)
    return file.save(path)
