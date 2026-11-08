extends RefCounted
## Original hard-edged, staged canvas effects projected from the shared fight world.
var impact_shapes = preload("res://scripts/combat/impact_shapes.gd").new()
func draw_effect(canvas: Control, session: Node3D, effect: Dictionary) -> void:
    var at: Vector2 = session.project(effect.at)
    var time: float = clampf(effect.age/effect.life,0,1)
    var stage := floorf(time*6.0)/6.0
    var tint: Color = effect.color
    var strength: float = effect.strength
    var face: float = effect.get("face",1)
    var reduced: bool = session.reduced_effects
    var paper := Color("fff8dc")
    var ink := Color("111a32")
    match effect.kind:
        "swing","hit","release","clash":
            var phase: float = fmod(effect.age,0.15)/0.15 if effect.kind in ["hit","clash"] and effect.get("held",false) else time
            var shapes: Array[Dictionary] = impact_shapes.build("hit" if effect.kind=="clash" else effect.kind,effect.get("move","jab"),phase,tint,face,reduced)
            var pixels_per_meter: float = (session.project(effect.at+Vector2(1,0))-at).length()
            var perspective_scale := clampf(pixels_per_meter/56.0,.65,1.3)
            for shape in shapes:
                var points: PackedVector2Array=shape.points.duplicate()
                for i in points.size(): points[i]=at+points[i]*perspective_scale
                canvas.draw_colored_polygon(points,shape.color)
        "dust":
            for i in (3 if reduced else 6):
                var spread := Vector2((i-2.5)*17.0*(time+0.3),-sin(time*PI)*13.0)
                var extent := (1.0-stage)*7.0
                canvas.draw_colored_polygon(PackedVector2Array([at+spread+Vector2(-extent,extent),at+spread+Vector2(-extent*0.5,-extent),at+spread+Vector2(extent,-extent*0.6),at+spread+Vector2(extent*1.4,extent)]),tint)
        "speed","trail":
            if reduced: return
            for i in 4:
                var y := (i-1.5)*10.0
                var length := (45.0+i*12.0)*(1.0-stage)
                var start := at+Vector2(-face*10.0,y)
                canvas.draw_colored_polygon(PackedVector2Array([start,start+Vector2(-face*length,-2),start+Vector2(-face*length*0.8,3)]),tint)
        "charge":
            var radius := lerpf(80.0,22.0,stage)
            canvas.draw_arc(at,radius,0,TAU,12,tint,3)
            if not reduced:
                for i in 6:
                    var direction := Vector2.from_angle(i*TAU/6+stage*0.7)
                    canvas.draw_line(at+direction*(radius+20),at+direction*radius,paper,3)
        "wave":
            var target: Vector2 = session.project(effect.at+Vector2(face*2.8,0))
            var reach := target-at
            var progress := minf(1.0,time*3.5)
            var tip := at+reach*progress
            var height := 30.0*(1.0-stage)
            canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(0,-height),tip,at+Vector2(0,height),at+Vector2(-face*25,0)]),tint)
            if not reduced:
                canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(0,-height*0.4),tip,at+Vector2(0,height*0.4)]),paper)
        "block","parry":
            var radius := (45.0+stage*35.0)*(1.2 if effect.kind=="parry" else 1.0)
            var points := PackedVector2Array()
            for i in 7: points.append(at+Vector2.from_angle(i*TAU/6)*radius)
            canvas.draw_polyline(points,tint,5.0*(1.0-time)+1)
            if effect.kind=="parry":
                _star(canvas,at,radius*1.4,4,paper)
                canvas.draw_arc(at,radius*0.65,0,TAU,12,paper,3)
            else:
                canvas.draw_line(at+Vector2(-10,-28)*(1-time),at+Vector2(12,28)*(1-time),paper,5)
        "guard_break":
            for i in 6:
                var direction := Vector2.from_angle(i*TAU/6)
                var center := at+direction*(25.0+time*90.0)
                var tangent := direction.orthogonal()
                canvas.draw_colored_polygon(PackedVector2Array([center+direction*18,center-direction*12+tangent*9,center-direction*7-tangent*8]),tint if i%2==0 else paper)
        _:
            var radius := (38.0+stage*100.0)*(0.7+strength*0.55)
            if strength>=0.65 and time<0.32 and not reduced:
                canvas.draw_circle(at,22.0,ink)
                _star(canvas,at,radius*1.15,4,paper)
            _star(canvas,at,radius,4 if reduced else 10,tint)
            canvas.draw_arc(at,radius*0.7,0,TAU,16,paper,3.0*(1.0-time)+1)
            if time<0.55: canvas.draw_circle(at,15.0*(1.0-time),paper)
            if not reduced:
                canvas.draw_arc(at,radius*1.05,0,TAU,16,tint,2)

func _star(canvas: Control, at: Vector2, radius: float, rays: int, tint: Color) -> void:
    for i in rays:
        var direction := Vector2.from_angle(i*TAU/rays+0.17)
        var tangent := direction.orthogonal()
        var length := radius*(1.2 if i%2==0 else 0.7)
        canvas.draw_colored_polygon(PackedVector2Array([at+direction*8+tangent*6,at+direction*length,at+direction*8-tangent*6]),tint)

func _crescent(canvas: Control, at: Vector2, radius: float, width: float, face: float, tint: Color) -> void:
    var points := PackedVector2Array()
    for i in 13:
        var angle := lerpf(-1.45,1.45,float(i)/12.0)
        points.append(at+Vector2(cos(angle)*face,sin(angle))*radius)
    for i in range(12,-1,-1):
        var angle := lerpf(-1.45,1.45,float(i)/12.0)
        var inner := radius-width*sin(float(i)/12.0*PI)
        points.append(at+Vector2(cos(angle)*face,sin(angle))*inner)
    canvas.draw_colored_polygon(points,tint)
