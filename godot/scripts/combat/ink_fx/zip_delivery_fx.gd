extends RefCounted
## Reference-derived local cels. No fullscreen overlay or gameplay authority.
const Motion=preload("res://scripts/combat/last_service/zip_delivery.gd")
const Shapes=preload("res://scripts/combat/ink_fx/zip_express_fx.gd")
const CYAN=Color("17f5cf")
const PAPER=Color("f6fffd")
static func contact(canvas:Control,session:Node,effect:Dictionary,time:float) -> void:
    var stage:int=effect.get("delivery_stage",0)
    var reduced:bool=session.reduced_effects
    Shapes.burst(canvas,session,effect.at,effect.face,time,stage==2,reduced)
    if reduced or time>=1:return
    var alpha:float=1.0-smoothstep(.45,1.0,time)
    # The final receipt is a forward fan, distinct from Express's round needles.
    for i in (13 if stage==2 else 5):
        var angle:float=-1.15+float(i)*(2.3/(12.0 if stage==2 else 4.0))
        var axis:=Vector2(cos(angle),sin(angle));var side:=axis.orthogonal()
        var length:float=(1.65 if stage==2 else .65)*(1.0+float((i*3)%5)*.12)*(1.0-time*.30)
        var center:=axis*.10
        Shapes.polygon(canvas,session,effect.at,[center-side*.07,axis*length,center+side*.07],effect.face,Color(CYAN,alpha))
        Shapes.polygon(canvas,session,effect.at,[center-side*.025,axis*length*.88,center+side*.025],effect.face,Color(PAPER,alpha))
    if stage==2:
        Shapes.polygon(canvas,session,effect.at,[Vector2(-.25,0),Vector2(2.0,.15),Vector2(2.5,0),Vector2(1.6,-.12)],effect.face,Color(PAPER,alpha))
static func draw(canvas:Control,session:Node,effect:Dictionary) -> bool:
    if not effect.get("zip_delivery",false):return false
    var time:float=clampf(effect.age/effect.life,0,1)
    if effect.kind=="hit":
        contact(canvas,session,effect,.12 if effect.get("held",false) else time)
        return true
    if effect.kind in ["release","charge","cannon_charge"]:return true
    if effect.kind!="swing":return false
    if session.reduced_effects:return true
    var f:Dictionary=session.presentation_pose(effect.owner)
    var move:Dictionary=session.sim.move_for(f,"overdrive")
    var beat:Dictionary=Motion.segment(f,move)
    var age:float=float(f.frame)-float(beat.hit)
    if age< -6.0 or age>(26.0 if beat.stage==0 else 20.0):return true
    var limb:String="LeftFoot" if beat.mirrored else "RightFoot"
    var socket:Vector3=session.fighters[effect.owner].fx_socket(limb)
    var tip:=Vector2(socket.x,socket.y)
    var origin:=Vector2(f.x,f.y+.85)
    var radius:float=1.10 if beat.stage==0 else 1.25
    var sweep:float=clampf((age+6.0)/12.0,0,1)
    Shapes.blade(canvas,session,origin,effect.face,-.9,lerpf(-.5,.32,sweep),radius,.14,CYAN)
    Shapes.blade(canvas,session,origin,effect.face,-.9,lerpf(-.5,.32,sweep),radius,.035,PAPER)
    if beat.stage==2 and age>=-2.0:
        var opacity:float=1.0-smoothstep(5.0,18.0,age)
        # Three long curved shoe/leg smears end at the actual striking shoe.
        var heel:=Vector2((tip.x-f.x)*f.face,tip.y-f.y)
        for i in 3:
            var offset:float=(float(i)-1.0)*.14
            var start:=Vector2(-.24,.98+offset)
            var middle:=heel*.55+Vector2(-.10,.26+offset)
            var end:=heel+Vector2(.18,offset*.15)
            Shapes.polygon(canvas,session,Vector2(f.x,f.y),[start,middle+Vector2(0,.095),end,middle-Vector2(0,.075)],effect.face,Color(CYAN,opacity*.45))
            Shapes.polygon(canvas,session,Vector2(f.x,f.y),[start,middle+Vector2(0,.08),end,middle-Vector2(0,.06)],effect.face,Color(PAPER,opacity*(.85-float(i)*.15)))
    return true
