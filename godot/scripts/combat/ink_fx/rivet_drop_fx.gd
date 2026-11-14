extends RefCounted
## Two-stage heated gauntlets and a descending impact fan; no gameplay writes.
const Shapes=preload("res://scripts/combat/ink_fx/zip_express_fx.gd")
const ORANGE=Color("ff8d16")
const GOLD=Color("ffd53b")
const CORE=Color("fff9da")
static func draw(canvas:Control,session:Node,effect:Dictionary) -> bool:
    if not effect.get("rivet_drop",false):return false
    var t:float=clampf(effect.age/effect.life,0,1)
    var reduced:bool=session.reduced_effects
    var tier:int=effect.get("preload",0)
    if effect.kind=="release":return true
    if effect.kind=="hit":
        if t>=.999:return true
        var impact:=Vector2(effect.at.x,maxf(.12,effect.at.y-1.0))
        var alpha:float=1.0-smoothstep(.25,1.0,t)
        var size:float=(.8+t*.9)*(1.0+tier*.18)*(.40 if reduced else 1.0)
        for i in (5 if reduced else 13):
            var angle:float=.12+float(i)*PI/13.0
            var axis:=Vector2(cos(angle),sin(angle))
            var side:=axis.orthogonal()
            var length:float=size*(.65+float((i*7)%9)*.11)
            polygon(canvas,session,impact,[side*.12,axis*length,-side*.12],effect.face,Color(ORANGE,alpha))
            polygon(canvas,session,impact,[side*.045,axis*length*.82,-side*.045],effect.face,Color(CORE,alpha))
        return true
    if effect.kind not in ["swing","charge"]:return false
    var f:Dictionary=session.presentation_pose(effect.owner)
    var move:Dictionary=session.sim.move_for(f,"special")
    var age:float=float(f.frame)-float(move.startup)
    tier=f.service.preload
    if effect.kind=="charge":
        if tier==0 or reduced:return true
        var power:float=float(tier)/2.0
        for limb in ["LeftHand","RightHand"]:
            var socket:Vector3=session.fighters[effect.owner].fx_socket(limb)
            var at:=Vector2(socket.x,socket.y)
            for i in 6:
                var angle:float=float(i)*TAU/6.0+float(f.service.preload_age)*.045
                var axis:=Vector2(cos(angle),sin(angle))
                var side:=axis.orthogonal()
                var pulse:float=.7+.3*sin(float(f.service.preload_age)*.36+float(i))
                var radius:float=.18+power*.17
                polygon(canvas,session,at,[axis*radius-side*.045,axis*(radius+.12*power*pulse),axis*radius+side*.045],1,ORANGE)
                polygon(canvas,session,at,[axis*radius*.65-side*.035,axis*radius*1.05,axis*radius*.65+side*.035],1,GOLD)
        return true
    if age< -5.0 or age>27.0:return true
    var origin:=Vector2(f.x,f.y+1.12)
    if age<4.0 and not reduced:
        var sweep:float=smoothstep(-5.0,2.0,age)
        # Tall overhead orange arc follows the downward fist, never a straight jab.
        Shapes.blade(canvas,session,origin,f.face,2.3,lerpf(2.1,-.9,sweep),1.05,.22,ORANGE)
        Shapes.blade(canvas,session,origin,f.face,2.3,lerpf(2.1,-.9,sweep),1.05,.065,CORE)
    if age>=0 and not reduced:
        var ground:=Vector2(f.x+f.face*.88,f.y+.03)
        var decay:float=1.0-smoothstep(3.0,27.0,age)
        if decay<.001:return true
        var spread:float=.30+age*.055
        # Ground dust/cracks belong to the slam even on whiff; contact stars above
        # are exclusively actual hit events. No invented opponent reaction.
        for side in [-1,1]:
            polygon(canvas,session,ground,[Vector2(0,0),Vector2(side*spread,.08),Vector2(side*(spread+.35),.01),Vector2(side*spread,-.025)],1,Color(GOLD,decay*.8))
        for i in 8:
            var horizontal:float=(float(i)-3.5)*.14
            var rise:float=maxf(0.0,age*.055-age*age*.0018)*(1.0+float(i%3)*.35)
            var at:Vector2=ground+Vector2(horizontal*(1.0+age*.09),rise)
            var chip:float=(.04+float(i%3)*.012)*decay
            polygon(canvas,session,at,[Vector2(-chip,0),Vector2(0,chip*1.5),Vector2(chip,0),Vector2(0,-chip)],1,Color("443a36",decay))
    return true

static func polygon(canvas:Control,session:Node,origin:Vector2,points:Array,face:float,color:Color) -> void:
    var projected:=PackedVector2Array()
    for point:Vector2 in points:
        var p:Vector2=session.project(origin+Vector2(point.x*face,point.y))
        if projected.is_empty() or projected[-1]!=p:projected.append(p)
    if projected.size()>2 and projected[0]==projected[-1]:projected.remove_at(projected.size()-1)
    # Pixel projection can collapse the final fading chip to a line or point.
    if projected.size()<3 or Geometry2D.triangulate_polygon(projected).is_empty():return
    canvas.draw_colored_polygon(projected,color)
