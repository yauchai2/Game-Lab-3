extends RefCounted
## Presentation only: finite local silhouettes, transformed once at the real socket.
const NAMES := ["zip_route", "rivet_stamp", "hush_cut", "loop_signal"]
const CAMERAS := [Vector4(-.34,.42,39,.45),Vector4(-.08,.10,43,-.15),Vector4(-.035,.035,40,.25),Vector4(-.16,.18,46,.65)]
const ROLL := [.70,.25,.08,.35]
static func camera_profile(character:int) -> Vector4:
    if character<0 or character>3:return Vector4(-.28,.40,36,.30)
    return CAMERAS[character]
static func marks(character:int,kind:String,time:float,strength:float,reduced:bool) -> Array:
    var result:Array=[]
    var travel:bool=kind in ["swing","charge","cannon_charge","cannon_blast"]
    var reach:float=(24.0+strength*24.0)*(1.0-time*.55)*(.55 if reduced else 1.0)
    if travel:reach*=1.3
    match character:
        0:
            # Two staggered route arrows read with the alternating kick chain.
            for i in (1 if reduced else 2):
                var x:float=reach*(float(i)*.65-.4+time*.3)
                result.append({"points":PackedVector2Array([Vector2(x-reach*.5,-reach*.7),Vector2(x+reach*.5,0),Vector2(x-reach*.5,reach*.7)]),"width":3.0,"closed":false})
        1:
            # A dense rectangular punch stamp with two compression bars.
            result.append({"points":PackedVector2Array([Vector2(-reach*.65,-reach*.65),Vector2(reach*.65,-reach*.65),Vector2(reach*.65,reach*.65),Vector2(-reach*.65,reach*.65)]),"width":6.0,"closed":true})
            if not reduced:
                for y in [-.28,.28]:result.append({"points":PackedVector2Array([Vector2(-reach*1.2,reach*y),Vector2(-reach*.8,reach*y)]),"width":5.0,"closed":false})
        2:
            # One dry incision and a separated short witness mark, no radial burst.
            result.append({"points":PackedVector2Array([Vector2(-reach,-reach*.22),Vector2(reach,reach*.22)]),"width":2.0,"closed":false})
            if not reduced:result.append({"points":PackedVector2Array([Vector2(reach*.22,-reach*.48),Vector2(reach*.32,-reach*.25)]),"width":2.0,"closed":false})
        3:
            # Orthogonal signal step, terminated by two small square nodes.
            result.append({"points":PackedVector2Array([Vector2(-reach,reach*.35),Vector2(-reach*.3,reach*.35),Vector2(-reach*.3,-reach*.35),Vector2(reach,-reach*.35)]),"width":3.0,"closed":false})
            if not reduced:
                for point in [Vector2(-reach,reach*.35),Vector2(reach,-reach*.35)]:
                    var d:=Vector2(4,4)
                    result.append({"points":PackedVector2Array([point-d,point+Vector2(d.x,-d.y),point+d,point+Vector2(-d.x,d.y)]),"width":2.0,"closed":true})
    return result
static func draw(canvas:Control,at:Vector2,effect:Dictionary,reduced:bool) -> bool:
    var character:int=effect.get("character",-1)
    if character<0 or character>3 or effect.kind not in ["hit","release","wall","swing","charge","cannon_charge","cannon_blast","parry","guard_break"]:return false
    var time:float=clampf(effect.age/effect.life,0,1)
    if effect.kind=="hit" and effect.get("held",false):time=.12
    if time>=1:return true
    var tint:Color=effect.color
    tint.a*=1.0-time
    var face:float=effect.get("face",1)
    for mark in marks(character,effect.kind,time,effect.get("strength",.5),reduced):
        var points:=PackedVector2Array()
        for point in mark.points:points.append(at+Vector2(point.x*face,point.y))
        if mark.closed:points.append(points[0])
        canvas.draw_polyline(points,Color("111a32"),mark.width+3.0)
        canvas.draw_polyline(points,tint,mark.width)
    return true
