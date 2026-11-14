extends RefCounted
## Bundled user-supplied motions; environment overrides remain available for development.
const BASE="res://assets/animations/quaternius_combat.json"
const DEFAULT_PATH="res://assets/animations/mixamo_fighters.json"
const LEGACY_EXTENSION="res://.godot/private_animation/mixamo_fighters.json"
const REQUIRED=["MX_AirKick","MX_KnockedOut","MX_GetUp","MX_Jab","MX_Cross","MX_Hook","MX_BodyPunch","MX_Idle","MX_HushJab","MX_HushElbow","MX_Elbow","MX_Block","MX_Dodge","MX_StickHorizontal","MX_StickDown","MX_StickBack","MX_Roundhouse","MX_Roundhouse_Mirror","MX_Hurricane","MX_Hurricane_Mirror","MX_HeadHit","MX_BodyHit","MX_Walking"]
static var data:Dictionary={}
static var checked:=false
static func available() -> bool:
    if checked:return not data.is_empty()
    checked=true
    var path:String=OS.get_environment("GAME_LAB_MOTION_LIBRARY")
    if path.is_empty():path=DEFAULT_PATH
    data=_read(path)
    if data.is_empty():return false
    # Preserve the separately installed Mac backwalk without replacing bundled get-up/KO.
    if path==DEFAULT_PATH:merge_optional(data,_read(LEGACY_EXTENSION))
    return true
static func merge_optional(base:Dictionary,extension:Dictionary) -> void:
    if extension.is_empty() or not extension.clips.has("MX_WalkBack"):return
    base.clips["MX_WalkBack"]=extension.clips.MX_WalkBack
    base.markers["MX_WalkBack"]=extension.markers.MX_WalkBack
static func _read(path:String) -> Dictionary:
    if not FileAccess.file_exists(path):return {}
    var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
    if not parsed is Dictionary:return {}
    if parsed.get("schema",0)!=1 or parsed.get("kind","")!="mixamo_fighters":return {}
    if parsed.get("base_sha256","")!=FileAccess.get_sha256(BASE):return {}
    var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE))
    if not parsed.get("clips",null) is Dictionary or not parsed.get("markers",null) is Dictionary:return {}
    if parsed.clips.is_empty():return {}
    for required in REQUIRED:
        if not parsed.clips.has(required) or not parsed.markers.has(required):return {}
    for key in parsed.clips:
        if not str(key).begins_with("MX_") or not parsed.markers.has(key):return {}
        var clip:Variant=parsed.clips[key]
        if not clip is Dictionary or not clip.get("tracks",null) is Dictionary:return {}
        if clip.tracks.is_empty():return {}
        var duration:float=float(clip.get("duration",0))
        if not is_finite(duration) or duration<=0 or duration>15:return {}
        var marker:Variant=parsed.markers[key]
        if not marker is Dictionary:return {}
        var contact:float=float(marker.get("contact",-1))
        if not is_finite(contact) or contact<0 or contact>1:return {}
        for index in clip.tracks:
            if not str(index).is_valid_int() or int(index)<0 or int(index)>=base.nodes.size():return {}
            var track:Variant=clip.tracks[index]
            if not track is Dictionary:return {}
            for channel in track:
                if channel not in ["rotation","translation"]:return {}
                var curve:Variant=track[channel]
                if not curve is Dictionary:return {}
                if not curve.get("times",null) is Array or not curve.get("values",null) is Array:return {}
                if curve.times.size()<2 or curve.times.size()!=curve.values.size():return {}
                var previous:float=-1.0
                for i in curve.times.size():
                    var time:float=float(curve.times[i])
                    if not is_finite(time) or time<0 or time<=previous or time>duration+.001:return {}
                    previous=time
                    var value:Variant=curve.values[i]
                    if not value is Array or value.size()!=(4 if channel=="rotation" else 3):return {}
                    for component in value:
                        if not component is float and not component is int:return {}
                        if not is_finite(float(component)):return {}
                    if channel=="rotation":
                        var norm:float=Vector4(value[0],value[1],value[2],value[3]).length_squared()
                        if not is_finite(norm) or norm<.5 or norm>1.5:return {}
    return parsed
static func install_into(library:Dictionary) -> void:
    if not available():return
    library.clips.merge(data.clips)
    library.street_markers.merge(data.markers)
    library.clips["Death01"]=data.clips.MX_KnockedOut
