extends RefCounted
## Private source curves are deliberately absent from the public repository.
const DEFAULT_PATH="res://.godot/private_animation/mixamo_shoulder_throw.json"
static var data:Dictionary={}
static var checked:=false
static func available() -> bool:
    if checked:return not data.is_empty()
    checked=true
    var path:String=OS.get_environment("GAME_LAB_THROW_LIBRARY")
    if path.is_empty():path=DEFAULT_PATH
    if not FileAccess.file_exists(path):return false
    var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
    if not parsed is Dictionary or parsed.get("schema",0)!=1:return false
    if parsed.get("first",0)!=61 or parsed.get("last",0)!=121 or parsed.get("fps",0)!=30:return false
    for role in ["aggressor","victim"]:
        var actor:Dictionary=parsed.get("actors",{}).get(role,{})
        if actor.get("frames",[]).size()!=61 or actor.get("bones",[]).size()!=65:return false
        for frame in actor.frames:
            if frame.get("rotations",[]).size()!=65 or frame.get("hip",[]).size()!=3:return false
    data=parsed
    return true
static func vector(a:Array) -> Vector3:
    return Vector3(a[0],a[1],a[2])
static func quat(a:Array) -> Quaternion:
    return Quaternion(a[0],a[1],a[2],a[3]).normalized()
static func sample(role:String,source_frame:float) -> Dictionary:
    var index:float=clampf(source_frame-61.0,0,60)
    var lo:int=floori(index)
    var frames:Array=data.actors[role].frames
    return {"a":frames[lo],"b":frames[mini(lo+1,60)],"weight":index-float(lo)}
static func hip(role:String,source_frame:float) -> Vector3:
    var s:Dictionary=sample(role,source_frame)
    return vector(s.a.hip).lerp(vector(s.b.hip),s.weight)
static func offset(role:String,source_frame:float,face:float) -> Vector3:
    var p:Vector3=(hip(role,source_frame)-hip("aggressor",61))*float(data.get("planar_scale",1.0))
    return Vector3(-p.x*face,hip(role,source_frame).z*1.15,p.y*face)
