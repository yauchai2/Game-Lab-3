extends RefCounted
## Original comic staging. Visual clock only; never changes collision or damage.
var impact_word := ""
var mode := ""
var age := 1.0
var duration := 0.0
var tier := 1
var owner := 0
var focus := Vector2.ZERO
var kick_age := 1.0
var kick := 0.0
var generation := 0

func clear() -> void:
    impact_word=""
    mode=""
    age=1.0
    duration=0.0
    kick_age=1.0
    kick=0.0
    generation+=1

func trigger(kind: String, side: int, point: Vector2, level := 1) -> void:
    owner=clampi(side,0,1)
    focus=point
    tier=clampi(level,1,4)
    mode=kind
    age=0.0
    duration={"charge":.30,"contact":.26,"burst":.38,"finish":.82}.get(kind,.3)
    if kind in ["burst","finish"]:
        kick_age=0.0
        kick=.45 if kind=="finish" else .12+tier*.06

func tag_move(move: String) -> void:
    impact_word={"overdrive":"MAX OUT!","meteor":"SLAM!","launcher":"RISE!","special":"BURST!","air_counter":"REVERSE!"}.get(move,"")

func advance(delta: float, paused: bool) -> void:
    if paused:return
    age+=delta
    kick_age+=delta
    if age>=duration:mode=""

func camera_punch(reduced: bool) -> float:
    if reduced or kick_age>.36:return 0.0
    return kick*exp(-kick_age*13.0)*cos(kick_age*18.0)

func draw(canvas: Control, session: Node3D) -> void:
    var rally=session.sim.rally
    var held: bool=rally.active() and rally.phase=="compress"
    var finishing: bool=session.screen=="result" and session.result_clock<session.FINISH_SECONDS
    if not held and mode=="" and not finishing:return
    var reduced: bool=session.reduced_effects
    var at: Vector2=session.project(focus)
    var color: Color=session.COLORS[owner]
    var ink:=Color("101b32")
    var paper:=Color("fff5db")
    var fade:=clampf(1.0-age/maxf(duration,.001),0,1)
    if held:
        at=session.project(Vector2((session.sim.fighters[0].x+session.sim.fighters[1].x)*.5,1.2))
        color=session.COLORS[rally.owner]
        var amount: float=float(rally.age)/rally.HOLDS[rally.tier-1]
        var radius:=lerpf(115.0,28.0,amount)
        if not reduced:
            _border(canvas,color,.3+rally.tier*.08)
            for i in 10:
                var direction:=Vector2.from_angle(i*TAU/10+.14)
                var outer:=at+direction*(radius+40)
                _wedge(canvas,outer,at+direction*radius,3,color)
        canvas.draw_arc(at,30.0 if reduced else radius,0,TAU,12,color,3)
        for i in rally.tier:
            var mark:=at+Vector2(-18+i*12,42)
            canvas.draw_colored_polygon(PackedVector2Array([mark,mark+Vector2(5,-5),mark+Vector2(10,0),mark+Vector2(5,5)]),paper)
        return
    if reduced:return
    if finishing:
        color=session.COLORS[maxi(0,session.sim.winner)]
        var progress:=clampf(session.result_clock/session.FINISH_SECONDS,0,1)
        _border(canvas,color,(1.0-progress)*.85)
        # A center-free radial composition: fighters remain visible in the opening.
        for i in 18:
            var direction:=Vector2.from_angle(i*TAU/18+.08)
            var reach:=Vector2(850,520)*direction
            _wedge(canvas,Vector2(640,340)+reach,Vector2(640,340)+reach*.68,12,color)
        var offset:=maxf(0,.14-session.result_clock)*1800
        var points:=PackedVector2Array([Vector2(275-offset,155),Vector2(992-offset,155),Vector2(954-offset,234),Vector2(246-offset,234)])
        canvas.draw_colored_polygon(points,ink)
        var text: String=session.hud.tr_text("draw" if session.sim.winner<0 else "finish_stamp") if session.final_ko() else "ROUND CLEAR"
        var font: Font=session.hud.bold
        var extent:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,54)
        canvas.draw_string(font,Vector2(640-extent.x*.5-offset,215),text,HORIZONTAL_ALIGNMENT_LEFT,-1,54,paper)
        return
    if mode=="charge":
        _border(canvas,color,fade*.6)
        # Upper-corner cut-in leaves the fight lane and health bars clear.
        var slide:=minf(1,age/.07)
        var left:=lerpf(1320,825,slide)
        canvas.draw_colored_polygon(PackedVector2Array([Vector2(left,167),Vector2(1280,167),Vector2(1280,248),Vector2(left-35,248)]),ink)
        canvas.draw_line(Vector2(left,167),Vector2(1280,167),color,4)
        canvas.draw_string(session.hud.bold,Vector2(left+8,215),session.hud.tr_text("overdrive_stamp"),HORIZONTAL_ALIGNMENT_LEFT,-1,35,color)
    elif mode in ["burst","contact"]:
        if impact_word!="" and age<.18:
            var x:=845.0 if owner==0 else 65.0
            var slide:=maxf(0,.035-age)*1100
            var plate:=PackedVector2Array([Vector2(x+slide,166),Vector2(x+305+slide,166),Vector2(x+283+slide,232),Vector2(x-18+slide,232)])
            canvas.draw_colored_polygon(plate,ink)
            canvas.draw_line(plate[0],plate[1],color,4)
            canvas.draw_string(session.hud.bold,Vector2(x+8+slide,215),impact_word,HORIZONTAL_ALIGNMENT_LEFT,-1,45,paper)
        _border(canvas,color,fade*(.4+tier*.1))
        var count:=12 if tier<3 else 20
        for i in count:
            var direction:=Vector2.from_angle(i*TAU/count+.12)
            var edge:=at+direction*Vector2(900,600)
            var tip:=at+direction*(210.0+age*420)
            _wedge(canvas,edge,tip,(3.0+tier)*fade,Color(color,fade*.65))
        if mode=="burst" and age<.16:
            var radius:=50.0+age*700
            for i in 8:
                var angle:=i*TAU/8
                canvas.draw_arc(at,radius,angle,angle+.42,4,Color(paper,fade),3)

func _wedge(canvas: Control, base: Vector2, tip: Vector2, width: float, color: Color) -> void:
    var tangent: Vector2=(tip-base).normalized().orthogonal()*width
    canvas.draw_colored_polygon(PackedVector2Array([base-tangent,tip,base+tangent]),color)

func _border(canvas: Control, color: Color, strength: float) -> void:
    var ink:=Color("0a152a")
    canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(1280,0),Vector2(1280,112),Vector2(1000,92),Vector2(230,92),Vector2(0,126)]),Color(ink,strength*.65))
    canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,720),Vector2(1280,720),Vector2(1280,654),Vector2(980,678),Vector2(250,678),Vector2(0,646)]),Color(ink,strength*.65))
    for side in [0,1]:
        for i in 12:
            var x:=float(i%3)*7 if side==0 else 1280-float(i%3)*7
            var y:=225.0+i*22
            canvas.draw_circle(Vector2(x,y),2.0+strength*3,Color(color,strength*.65))
