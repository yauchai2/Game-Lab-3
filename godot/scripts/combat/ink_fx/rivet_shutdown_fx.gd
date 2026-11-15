extends RefCounted
## 04: furnace gauntlet, pressure disc and contact-bound tracer. No projectile.
const Shapes=preload("res://scripts/combat/ink_fx/rivet_drop_fx.gd")
const ORANGE=Color("ff8414")
const GOLD=Color("ffd43d")
const WHITE=Color("fff8dc")
static func disc(canvas:Control,session:Node,at:Vector2,face:float,radius:float,alpha:float) -> void:
    for i in 28:
        var a:float=TAU*float(i)/28.0
        var b:float=TAU*float(i+1)/28.0
        var u:=Vector2(cos(a)*.65,sin(a))
        var v:=Vector2(cos(b)*.65,sin(b))
        Shapes.polygon(canvas,session,at,[Vector2.ZERO,u*radius*.83,v*radius*.83],face,Color(GOLD,alpha*.18))
        Shapes.polygon(canvas,session,at,[u*radius,v*radius,v*radius*.86,u*radius*.86],face,Color(ORANGE,alpha))
        Shapes.polygon(canvas,session,at,[u*radius*.87,v*radius*.87,v*radius*.83,u*radius*.83],face,Color(WHITE,alpha))
static func burst(canvas:Control,session:Node,at:Vector2,face:float,t:float,reduced:bool) -> void:
    if t>=.99:return
    var alpha:float=1.0-smoothstep(.35,1.0,t)
    var size:float=(.55+t*.65)*(.40 if reduced else 1.0)
    for i in (6 if reduced else 18):
        var angle:float=float(i)*2.39996
        var axis:=Vector2(cos(angle),sin(angle))
        var side:=axis.orthogonal()
        var length:float=size*(.85+float((i*7)%8)*.16)
        Shapes.polygon(canvas,session,at,[-side*.08,axis*length,side*.08],face,Color(ORANGE,alpha))
        Shapes.polygon(canvas,session,at,[-side*.025,axis*length*.86,side*.025],face,Color(WHITE,alpha))
static func draw(canvas:Control,session:Node,e:Dictionary) -> bool:
    if not e.get("rivet_shutdown",false):return false
    var reduced:bool=session.reduced_effects
    var t:float=clampf(e.age/e.life,0,1)
    if e.kind=="hit":
        burst(canvas,session,e.at,e.face,t,reduced)
        return true
    if e.kind in ["release","charge"]:return true
    if e.kind=="rivet_wall":
        burst(canvas,session,e.at,e.face,minf(1.0,t*2.0),reduced)
        if reduced:return true
        var alpha:float=1.0-smoothstep(.65,1.0,t)
        # Bounded graphic crack: first real side-wall contact only, never a decal
        # placed on arbitrary buildings or a fake extra hit/damage event.
        for i in 11:
            var axis:=Vector2(cos(float(i)*2.39996),sin(float(i)*2.39996))
            var tangent:=axis.orthogonal()
            var end:Vector2=axis*(.55+float(i%4)*.14)
            var bend:Vector2=end*.55+tangent*.10
            Shapes.polygon(canvas,session,e.at,[Vector2.ZERO,bend+tangent*.022,end,bend-tangent*.022],1,Color("201b24",alpha))
            var chip:Vector2=end*(1.0+t*.7)+Vector2(0,-t*t*.35)
            Shapes.polygon(canvas,session,e.at,[chip,chip+axis*.10,chip+tangent*.045],1,Color(ORANGE,alpha))
        return true
    if e.kind=="rivet_link":
        if reduced or e.get("wall_done",false):return true
        var attacker:Dictionary=session.presentation_pose(e.owner)
        if attacker.health<=0 or attacker.state!="attack" or attacker.service.serial!=e.serial:return true
        var victim:Dictionary=session.sim.fighters[e.victim]
        if e.victim_id>=0:
            if not session.sim.squad_enabled or e.victim_id>=session.sim.squad_members.size():return true
            victim=session.sim.squad_members[e.victim_id]
        victim=session.presentation_pose_for(victim,e.victim)
        var socket:Vector3=session.fighters[e.owner].fx_socket("RightHand")
        var start:=Vector2(socket.x,socket.y)
        var end:=Vector2(victim.x,victim.y+1.0)
        var delta:Vector2=end-start
        if delta.length()<.05 or delta.length()>20:return true
        var side:Vector2=delta.normalized().orthogonal()
        var alpha:float=1.0-smoothstep(.45,1.0,t)
        Shapes.polygon(canvas,session,start,[-side*.11,delta+side*.035,delta-side*.035,side*.11],1,Color(ORANGE,alpha))
        Shapes.polygon(canvas,session,start,[-side*.035,delta+side*.012,delta-side*.012,side*.035],1,Color(WHITE,alpha))
        return true
    if e.kind not in ["swing","charge","cannon_charge"]:return false
    var f:Dictionary=session.presentation_pose(e.owner)
    var move:Dictionary=session.sim.move_for(f,"overdrive")
    var age:float=float(f.frame)-float(move.startup)
    var hand_socket:Vector3=session.fighters[e.owner].fx_socket("RightHand")
    var fist:=Vector2(hand_socket.x,hand_socket.y)
    if e.kind in ["charge","cannon_charge"]:
        if reduced:return true
        var power:float=smoothstep(2.0,float(move.startup)-6.0,float(f.frame))
        disc(canvas,session,fist,f.face,.20+power*.15,power*.9)
        for i in 6:
            var axis:=Vector2(cos(float(i)*TAU/6.0+float(f.frame)*.05),sin(float(i)*TAU/6.0+float(f.frame)*.05))
            var side:=axis.orthogonal()
            Shapes.polygon(canvas,session,fist,[axis*.30-side*.025,axis*(.35+power*.18),axis*.30+side*.025],1,Color(GOLD,power))
        return true
    if reduced or age< -6 or age>26:return true
    var swing_alpha:float=1.0-smoothstep(10.0,26.0,age)
    var origin:=Vector2(f.x,f.y+1.12)
    var sweep_end:=Vector2((fist.x-origin.x)*f.face,fist.y-origin.y)
    # Tapered local punch smear survives a whiff; pressure disc is a fist wave,
    # while tracer and wall burst require the actual hit and wall events above.
    Shapes.polygon(canvas,session,origin,[Vector2(-.35,.15),Vector2(-.20,-.10),sweep_end+Vector2(.20,-.07),sweep_end+Vector2(.20,.07)],f.face,Color(ORANGE,swing_alpha*.8))
    if age>=0:
        disc(canvas,session,fist+Vector2(f.face*.18,0),f.face,.62+minf(age,10.0)*.015,swing_alpha)
        disc(canvas,session,fist+Vector2(f.face*.18,0),f.face,.42,swing_alpha*.6)
    return true
