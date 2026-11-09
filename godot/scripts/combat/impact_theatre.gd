extends RefCounted
## Original red-stage staging. Rendering clock only, independent of gameplay.
var mode:=""
var age:=1.0
var duration:=0.0
var owner:=0
var generation:=0
func clear() -> void:
    mode="";age=1.0;duration=0.0;generation+=1
func begin(kind:String,side:int) -> void:
    if mode=="ko" and active():return
    if mode=="break" and active() and kind!="ko":return
    mode=kind;owner=clampi(side,0,1);age=0.0
    duration={"skill":1.0,"impact":.65,"break":1.1,"ko":1.2}.get(kind,.65)
    generation+=1
func active() -> bool:return mode!="" and age<duration
func advance(delta:float,paused:bool) -> void:
    if paused:return
    age+=delta
    if age>=duration:mode=""
func draw(canvas:Control,session:Node3D) -> void:
    if not active() or session.reduced_effects or session.screen not in ["play","result"]:return
    var ink:=Color("201223")
    var paper:=Color("fff0ca")
    var yellow:=Color("ffd83e")
    var center:Vector2=session.project(Vector2((session.sim.fighters[0].x+session.sim.fighters[1].x)*.5,(session.sim.fighters[0].y+session.sim.fighters[1].y)*.5+1.0))
    if mode=="ko":
        var victim:Dictionary=session.sim.fighters[1-owner]
        center=session.project(Vector2(victim.x-victim.face*.45,victim.y+session.fighters[1-owner].model_scale*.68))
    center.x=clampf(center.x,240,1040);center.y=clampf(center.y,150,560)
    var phase:=floorf(age*12.0)/12.0
    if mode=="skill":
        var close:float=clampf(age/.25,0,1)
        canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,120),Vector2(700*close,145),Vector2(610*close,224),Vector2(0,198)]),ink)
        canvas.draw_string(session.hud.bold,Vector2(42,187),"OVERDRIVE",HORIZONTAL_ALIGNMENT_LEFT,-1,40,yellow)
        for i in 4:
            var radius:float=80+i*42-age*65
            if radius>15:canvas.draw_arc(center,radius,-.5,4.3,8,Color(yellow,.75-i*.12),4)
    for i in 18:
        var direction:=Vector2.from_angle(i*TAU/18+.04)
        var outer:=center+direction*Vector2(1050,760)
        var tip:=center+direction*(120+fmod(phase*200,150))
        var tangent:=direction.orthogonal()*(6.0 if i%3 else 18.0)
        canvas.draw_colored_polygon(PackedVector2Array([outer-tangent,tip,outer+tangent]),Color(ink,.55))
    if mode in ["ko","impact","break"] and age<.48:
        var star:=PackedVector2Array()
        var radius:float=(120 if mode=="break" else 82)+age*70
        for i in 16:star.append(center+Vector2.from_angle(i*PI/8+.15)*(radius if i%2==0 else radius*.12))
        canvas.draw_colored_polygon(star,yellow)
    if age<.075:
        for side in [-1,1]:
            var at:=center+Vector2(side*145,-80)
            canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(-side*130,-8),at,at+Vector2(-side*110,20)]),yellow)
    if mode in ["ko","break"]:
        canvas.draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(1280,0),Vector2(1280,52),Vector2(1040,36),Vector2(240,36),Vector2(0,58)]),ink)
        canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,664),Vector2(240,680),Vector2(1040,680),Vector2(1280,664),Vector2(1280,720),Vector2(0,720)]),ink)
        var word:="K.O." if mode=="ko" else "BREAK!"
        var slide:=maxf(0,.10-age)*1000
        canvas.draw_string(session.hud.bold,Vector2(68-slide,638),word,HORIZONTAL_ALIGNMENT_LEFT,-1,94,paper)
