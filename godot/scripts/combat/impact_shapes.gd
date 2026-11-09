extends RefCounted
## Original opaque vector cels. Coordinates are local HUD pixels, never hitboxes.
const PAPER := Color("fff8dc")
const INK := Color("111a32")
const PROFILES := {
    "overdrive":Vector3(96,32,0),
    "air_counter":Vector3(76,24,.4),
    "air_jab":Vector3(43,13,-.15),"air_kick":Vector3(64,22,.4),
    "air_finisher":Vector3(75,24,.65),"meteor":Vector3(82,27,1.3),
    "grab": Vector3(32,8,0),
    "jab": Vector3(39,12,0), "cross": Vector3(49,15,-.12),
    "finisher": Vector3(59,19,.20), "heavy": Vector3(71,24,.12),
    "launcher": Vector3(63,21,-.85), "special": Vector3(82,27,0)
}
func build(kind: String, move: String, phase: float, tint: Color, face: float, reduced: bool, character := 0) -> Array[Dictionary]:
    var shapes: Array[Dictionary]=[]
    var frame:=clampi(int(clampf(phase,0,.9999)*6),0,5)
    var profile: Vector3=PROFILES.get(move,PROFILES.jab)
    var radius:=profile.x*(.62 if reduced else 1.0)
    if kind=="swing":
        if frame<3:
            var extent:=Vector2(1.0,.75 if move=="heavy" else 1.0)
            _crescent(shapes,radius,profile.y*(1.0-frame*.19),profile.z,extent,tint)
            if not reduced:_crescent(shapes,radius-5,profile.y*.35,profile.z,extent,PAPER)
        else:
            for i in (2 if reduced else 4):
                var angle:float=-1.2+i*.72+profile.z
                var center:=Vector2.from_angle(angle)*radius*(1.0+(frame-3)*.06)
                _diamond(shapes,center,Vector2(13.0-(frame-3)*4,3.0),angle,tint)
    elif kind=="hit":
        radius=(12.0+profile.x*.18)*(.72 if reduced else 1.0)+(1 if frame%2 else 0)
        _star(shapes,radius+5,4 if reduced else 8,frame*.11,INK)
        _star(shapes,radius,4 if reduced else 8,frame*.11,tint)
        _star(shapes,radius*.48,4,0,PAPER)
    elif kind=="release":
        var progress:=float(frame)/5.0
        radius=radius*(.50+progress*.55)
        var width:=maxf(2,7-frame)
        if frame<2 and not reduced:_star(shapes,radius*.8,4,profile.z,PAPER)
        var count:=4 if reduced else 8
        for i in count:
            if frame>=3 and i%2:continue
            var angle:=i*TAU/count
            _ring_piece(shapes,radius,width,angle,angle+TAU/count*.64,Vector2(.66,1) if move=="launcher" else Vector2(1,.65),tint)
        if not reduced and frame>=2:
            for i in 5:
                var angle:=i*TAU/5+.17
                var center:=Vector2.from_angle(angle)*(radius+8+frame*3)
                _diamond(shapes,center,Vector2(9-frame,3),angle,PAPER if i%2 else tint)
    if move in ["special","overdrive"] and kind in ["swing","release"]:
        shapes.clear()
        var pulse:float=[.72,1.0,1.12,1.2,1.26,1.30][frame]
        var w:float=maxf(2.0,profile.y*(1.0-frame*.14))
        var color:Color=Color(["ff6a00","4acfe0","e05aaf","d7f400"][clampi(character,0,3)])
        radius*=pulse
        match character:
            1:
                for angle in [-.45,.45]:
                    _crescent(shapes,radius,w,angle,Vector2(1,.86),color)
                    if frame<3:_crescent(shapes,radius-4,w*.28,angle,Vector2(1,.86),PAPER)
            2:
                for i in 3:
                    _ring_piece(shapes,radius+i*13,maxf(2,w*.4),-PI*.9,PI*.15,Vector2(1,.6),color if i%2==0 else PAPER)
            3:
                var points:=PackedVector2Array([Vector2(-radius,.18*radius),Vector2(-radius*.3,-radius*.14),Vector2(-radius*.4,radius*.03),Vector2(radius*.6,-radius*.35),Vector2(radius*.3,-radius*.03),Vector2(radius,0),Vector2(radius*.15,radius*.27),Vector2(radius*.3,radius*.07),Vector2(-radius*.5,radius*.34)])
                _poly(shapes,points,color)
                if frame<3:_diamond(shapes,Vector2(radius*.1,0),Vector2(radius*.65,4),-.12,PAPER)
            _:
                _star(shapes,radius*.62,4,0,color)
                _star(shapes,radius*.30,4,0,PAPER)
                for side in [-1,1]:_diamond(shapes,Vector2(-radius*.7,side*radius*.3),Vector2(radius*.55,3),-.1*side,color)
    if face<0:
        for shape in shapes:
            var points: PackedVector2Array=shape.points
            for i in points.size():points[i].x=-points[i].x
            shape.points=points
    return shapes

func _poly(shapes: Array[Dictionary], points: PackedVector2Array, color: Color) -> void:
    shapes.append({"points":points,"color":color})
func _diamond(shapes: Array[Dictionary], at: Vector2, extent: Vector2, angle: float, color: Color) -> void:
    var points:=PackedVector2Array()
    for point in [Vector2(-extent.x,0),Vector2(0,-extent.y),Vector2(extent.x,0),Vector2(0,extent.y)]:points.append(at+point.rotated(angle))
    _poly(shapes,points,color)
func _star(shapes: Array[Dictionary], radius: float, rays: int, angle: float, color: Color) -> void:
    var points:=PackedVector2Array()
    for i in rays*2:
        points.append(Vector2.from_angle(i*PI/rays+angle)*(radius if i%2==0 else radius*.30))
    _poly(shapes,points,color)
func _ring_piece(shapes: Array[Dictionary], radius: float, width: float, start: float, end: float, extent: Vector2, color: Color) -> void:
    var points:=PackedVector2Array()
    for i in 4:points.append(Vector2.from_angle(lerpf(start,end,i/3.0))*radius*extent)
    for i in range(3,-1,-1):points.append(Vector2.from_angle(lerpf(start,end,i/3.0))*(radius-width)*extent)
    _poly(shapes,points,color)
func _crescent(shapes: Array[Dictionary], radius: float, width: float, angle: float, extent: Vector2, color: Color) -> void:
    var points:=PackedVector2Array()
    for i in 13:
        points.append((Vector2.from_angle(lerpf(-1.4,1.4,i/12.0))*radius*extent).rotated(angle))
    for i in range(12,-1,-1):
        var inner:=radius-width*(.18+.82*sin(i/12.0*PI))
        points.append((Vector2.from_angle(lerpf(-1.4,1.4,i/12.0))*inner*extent).rotated(angle))
    _poly(shapes,points,color)
