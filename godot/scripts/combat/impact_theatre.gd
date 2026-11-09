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
    duration={"skill":.16,"impact":.14,"break":.32,"ko":.64}.get(kind,.14)
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
    var center:Vector2=session.project(Vector2((session.sim.fighters[0].x+session.sim.fighters[1].x)*.5,1.3))
    if mode=="ko":
        var victim:Dictionary=session.sim.fighters[1-owner]
        center=session.project(Vector2(victim.x-victim.face*.45,victim.y+1.43))
    center.x=clampf(center.x,240,1040);center.y=clampf(center.y,150,560)
    var phase:=floorf(age*24.0)/24.0
    for i in 18:
        var direction:=Vector2.from_angle(i*TAU/18+.04)
        var outer:=center+direction*Vector2(1050,760)
        var tip:=center+direction*(170+phase*180)
        var tangent:=direction.orthogonal()*(6.0 if i%3 else 18.0)
        canvas.draw_colored_polygon(PackedVector2Array([outer-tangent,tip,outer+tangent]),Color(ink,.55))
    if mode=="ko" and age<.36:
        var star:=PackedVector2Array()
        var radius:float=68+age*55
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
