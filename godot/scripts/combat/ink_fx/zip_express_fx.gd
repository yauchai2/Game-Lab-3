extends RefCounted
## Hand-authored world-projected geometry: mint blade, white core, directed shards.
## Only true contact effects draw a burst. Swing crescents can also occur on whiff.
const Motion=preload("res://scripts/combat/last_service/zip_express.gd")
const MINT=Color("00edae")
const WHITE=Color("f7fff9")
static func polygon(canvas:Control,session:Node,origin:Vector2,points:Array,face:float,color:Color) -> void:
    var projected:=PackedVector2Array()
    for point:Vector2 in points:projected.append(session.project(origin+Vector2(point.x*face,point.y)))
    if projected.size()>=3:canvas.draw_colored_polygon(projected,color)
static func blade(canvas:Control,session:Node,origin:Vector2,face:float,start:float,end:float,radius:float,width:float,color:Color) -> void:
    # Small convex quads avoid concave crescent triangulation failures.
    for i in 24:
        var a:float=lerpf(start,end,float(i)/24.0)
        var b:float=lerpf(start,end,float(i+1)/24.0)
        var wa:float=width*sin(PI*float(i)/24.0)
        var wb:float=width*sin(PI*float(i+1)/24.0)
        polygon(canvas,session,origin,[Vector2(cos(a),sin(a))*radius,Vector2(cos(b),sin(b))*radius,Vector2(cos(b),sin(b))*(radius-wb),Vector2(cos(a),sin(a))*(radius-wa)],face,color)
static func burst(canvas:Control,session:Node,at:Vector2,face:float,t:float,second:bool,reduced:bool) -> void:
    if t>=1:return
    var radius:float=(.58 if second else .34)*(.70+minf(t*5.0,1.0)*.4)
    if reduced:radius*=.40
    var alpha:float=1.0-smoothstep(.5,1.0,t)
    var color:=Color(MINT,alpha)
    var paper:=Color(WHITE,alpha)
    # Unequal needle lengths, strongest forward, with isolated outer splinters.
    for i in (7 if reduced else 15):
        var angle:float=float(i)*2.39996
        var axis:=Vector2(cos(angle),sin(angle))
        var tangent:=axis.orthogonal()
        var reach:float=radius*(.75+float((i*7)%9)*.12)*(1.30 if axis.x>0 else .85)
        var base:Vector2=axis*radius*.12
        polygon(canvas,session,at,[base-tangent*radius*.16,axis*reach,base+tangent*radius*.16],face,color)
        polygon(canvas,session,at,[base-tangent*radius*.075,axis*reach*.80,base+tangent*radius*.075],face,paper)
        if not reduced and t>.18:
            var center:Vector2=axis*reach*(1.0+t*.65)
            polygon(canvas,session,at,[center,center+axis*radius*.28,center+tangent*radius*.055],face,color)
    polygon(canvas,session,at,[Vector2(-radius*.25,0),Vector2(0,radius*.30),Vector2(radius*.65,0),Vector2(0,-radius*.26)],face,paper)
static func draw(canvas:Control,session:Node,effect:Dictionary) -> bool:
    if not effect.get("zip_express",false):return false
    var time:float=clampf(effect.age/effect.life,0,1)
    if effect.kind=="hit":
        if effect.get("held",false):time=.12
        burst(canvas,session,effect.at,effect.face,time,effect.get("zip_second",false),session.reduced_effects)
        return true
    # Release must not replay a second fake contact star.
    if effect.kind in ["release","charge"]:return true
    if effect.kind!="swing":return false
    if session.reduced_effects:return true
    var f:Dictionary=session.presentation_pose(effect.owner)
    var move:Dictionary=session.sim.move_for(f,"special")
    var second:bool=Motion.second(f,move)
    var hit:float=Motion.second_contact(f,move) if second else float(move.startup)
    var frame:float=f.frame
    var origin:=Vector2(f.x+f.face*.10,f.y+.95)
    if frame<hit-5.0:return true
    if not second:
        if frame>hit+5.0:return true
        var t:float=clampf((frame-hit+5.0)/10.0,0,1)
        blade(canvas,session,origin,f.face,-.65,lerpf(-.4,.25,t),1.10,.15,Color(MINT,1.0-t*.6))
        blade(canvas,session,origin,f.face,-.65,lerpf(-.4,.25,t),1.10,.045,WHITE)
    else:
        var age:float=frame-hit
        if age<4.0:
            blade(canvas,session,origin,f.face,-.25,.38,1.23,.19,MINT)
            blade(canvas,session,origin,f.face,-.25,.38,1.23,.05,WHITE)
        else:
            var t:float=clampf((age-4.0)/23.0,0,1)
            var alpha:float=1.0-smoothstep(.62,1.0,t)
            var end:float=lerpf(.15,-1.48,minf(1.0,t*2.0))
            blade(canvas,session,origin,f.face,1.85,end,1.12,.31*(1.0-t*.75),Color(MINT,alpha))
            blade(canvas,session,origin,f.face,1.85,end,1.12,.065,Color(WHITE,alpha))
            blade(canvas,session,origin+Vector2(-f.face*.10,0),f.face,1.60,end,1.20,.035,Color(MINT,alpha*.65))
    return true
