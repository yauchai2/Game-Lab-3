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
    var frame:int=preload("res://scripts/combat/ink_fx/fx_recipes.gd").cel(clampf(phase,0,.9999))
    var profile: Vector3=PROFILES.get(move,PROFILES.jab)
    var gain:float={"heavy":1.35,"launcher":1.45,"finisher":1.35,"meteor":1.55,"air_finisher":1.45,"special":1.8,"overdrive":2.15}.get(move,1.0)
    var radius:=profile.x*(.62 if reduced else gain)
    if kind=="swing":
        radius*=.65 if move in ["jab","cross","air_jab"] else .82
        var extent:=Vector2(1.0,.76 if move in ["heavy","cross"] else 1.0)
        var angle:float=profile.z+[-.25,-.12,.04,.16,.25,.30][frame]
        if character==2:
            if frame<4:
                _diamond(shapes,Vector2(radius*.15,0),Vector2(radius,2.5 if reduced else 4.0),angle,PAPER)
                _diamond(shapes,Vector2(-radius*.40,8),Vector2(radius*.24,2),angle,tint)
        else:
            var pieces:=2 if reduced else (4 if character==3 else 3)
            for i in pieces:
                if frame>=4 and i%2==1:continue
                var start:float=-1.35+float(i)*2.5/pieces+frame*.04
                var end:float=start+(2.5/pieces)*(.60 if character==3 else .82)
                var thickness:float=profile.y*(.62 if character==1 else .38)*[.65,1.0,.80,.53,.32,.12][frame]
                _arc_cel(shapes,radius,thickness,start,end,angle,extent,tint)
                if frame<3 and not reduced:_arc_cel(shapes,radius-2,2.5,start+.08,end-.04,angle,extent,PAPER)
        if not reduced and frame>=2:
            for i in (2 if character==2 else 4):
                var a:float=-1.2+i*.71+profile.z
                var center:=Vector2.from_angle(a)*radius*(1.0+(frame-2)*.10)
                _diamond(shapes,center,Vector2(maxf(1,9-frame),2),a,tint)
    elif kind=="hit":
        radius=(10.0+profile.x*.14)*(.65 if reduced else 1.0)*[.76,1.0,.78,.54,.30,.10][frame]
        var angle:float=profile.z
        var stretch:=Vector2(1.20,.62) if move in ["jab","cross","air_jab"] else Vector2(1.0,.85)
        if character==1:stretch*=Vector2(1.15,1.15)
        if character==2:stretch=Vector2(1.60,.42)
        _burst(shapes,radius+3,angle,stretch,INK)
        _burst(shapes,radius,angle,stretch,tint)
        if frame<3:_burst(shapes,radius*.48,angle,stretch,PAPER)
    elif kind=="release":
        # Directional wedges and staggered debris, instead of a full concentric ring.
        var progress:float=[.10,.23,.39,.58,.78,1.0][frame]
        radius*=.40+progress*.44
        var count:=3 if reduced else (4 if character==2 else 6)
        for i in count:
            if frame>=4 and i%2:continue
            var angle:float=profile.z+(float(i)/maxf(1,count-1)-.5)*2.9
            var center:=Vector2.from_angle(angle)*radius
            var size:=Vector2(maxf(1,(14.0-float(i%3)*2)*(1.0-progress)),maxf(1,3.5*(1.0-progress)))
            _diamond(shapes,center,size,angle,PAPER if i%3==0 and frame<3 else tint)
        if frame<2 and not reduced:_diamond(shapes,Vector2.ZERO,Vector2(radius*.50,2),profile.z,PAPER)
    if move in ["special","overdrive"] and kind in ["swing","release"]:
        shapes.clear()
        var pulse:float=[.72,1.0,1.12,1.2,1.26,1.30][frame]
        var w:float=maxf(2.0,profile.y*(1.0-frame*.14))
        var color:Color=tint
        radius*=pulse
        match character:
            0:
                for angle in [-.45,.45]:
                    for piece in 3:
                        var a:float=-1.4+piece*.94
                        _arc_cel(shapes,radius,w*.55,a,a+.70,angle,Vector2(1,.86),color)
                        if frame<3:_arc_cel(shapes,radius-4,w*.16,a+.08,a+.60,angle,Vector2(1,.86),PAPER)
            1:
                for side in [-1,1]:
                    var y:float=side*radius*.18
                    _poly(shapes,PackedVector2Array([Vector2(-radius*.85,y-w*.4),Vector2(radius*.6,y-w*.4),Vector2(radius*.8,y),Vector2(radius*.6,y+w*.4),Vector2(-radius*.85,y+w*.4)]),color)
                if frame<3:_diamond(shapes,Vector2.ZERO,Vector2(radius*.65,5),0,PAPER)
            2:
                _diamond(shapes,Vector2.ZERO,Vector2(radius,4),-.08,PAPER)
                for side in [-1,1]:
                    var at:=Vector2(side*radius*.65,0)
                    _poly(shapes,PackedVector2Array([at+Vector2(-7,-w),at+Vector2(6,-w),at+Vector2(6,w),at+Vector2(-7,w)]),color)
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

func _arc_cel(shapes:Array[Dictionary],radius:float,width:float,start:float,end:float,angle:float,extent:Vector2,color:Color) -> void:
    var points:=PackedVector2Array()
    for i in 7:
        var a:float=lerpf(start,end,i/6.0)
        points.append((Vector2.from_angle(a)*radius*extent).rotated(angle))
    for i in range(6,-1,-1):
        var a:float=lerpf(start,end,i/6.0)
        points.append((Vector2.from_angle(a)*(radius-width*(.18+.82*sin(i/6.0*PI)))*extent).rotated(angle))
    _poly(shapes,points,color)
func _burst(shapes:Array[Dictionary],radius:float,angle:float,extent:Vector2,color:Color) -> void:
    var points:=PackedVector2Array()
    for i in 12:
        var a:float=i*TAU/12.0+.08
        var length:float=radius*([1.38,.24,.82,.30,1.0,.23,1.16,.32,.72,.22,.92,.28][i])
        points.append((Vector2.from_angle(a)*length*extent).rotated(angle))
    _poly(shapes,points,color)
