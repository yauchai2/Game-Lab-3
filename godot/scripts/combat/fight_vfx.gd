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
        "service_pulse":
            var a:Vector2=session.project(Vector2(effect.low,.10))
            var b:Vector2=session.project(Vector2(effect.high,.10))
            var up:=Vector2(0,-35.0*(1-time))
            canvas.draw_colored_polygon(PackedVector2Array([a,b,b+up,a+up]),tint)
            canvas.draw_line(a+up,b+up,Color.WHITE,3)
        "cannon_charge":
            var fighter:Dictionary=session.sim.fighters[effect.owner]
            at=session.project(Vector2(fighter.x-face*.35,fighter.y+session.fighters[effect.owner].model_scale*.6))
            var radius:float=95.0*(1-time)+18
            if not reduced:
                for i in 8:
                    var direction:=Vector2.from_angle(i*TAU/8+stage)
                    canvas.draw_line(at+direction*radius,at+direction*(radius+25),tint,4)
            canvas.draw_arc(at,radius,0,TAU,8,tint,3)
            canvas.draw_arc(at,16+time*14,0,TAU,6,paper,5)
        "cannon_blast":
            var source:Dictionary=session.sim.fighters[effect.attacker]
            var muzzle:Vector2=session.project(Vector2(source.x+face*.6,source.y+session.fighters[effect.attacker].model_scale*.60))
            var direction:Vector2=(at-muzzle).normalized()
            if direction.length_squared()<.01:direction=Vector2(face,0)
            var width:float=(12 if reduced else 45)*(1-time)
            var tangent:Vector2=direction.orthogonal()
            var front:Vector2=at+direction*(80 if reduced else 220)*(1-time*.4)
            canvas.draw_colored_polygon(PackedVector2Array([muzzle-tangent*width*.5,front-tangent*width*.3,front+direction*70,front+tangent*width*.3,muzzle+tangent*width*.5]),tint)
            canvas.draw_line(muzzle,front,paper,maxf(2,width*.45))
            if not reduced:
                for i in 4:canvas.draw_arc(at,40+time*140+i*12,-1.3,1.3,7,paper if i%2 else tint,3)
        "meteor_streak":
            if reduced:return
            for side in [-1,1]:
                var base:=at+Vector2(side*22,-155*(1-time))
                canvas.draw_colored_polygon(PackedVector2Array([base,at+Vector2(side*14,72*time),base+Vector2(side*18,32)]),paper if side>0 else tint)
        "slam_crater":
            for i in (4 if reduced else 8):
                var angle:=i*TAU/8
                var direction:=Vector2(cos(angle),sin(angle)*.34)
                var radius:=22+time*155
                var tangent:=direction.orthogonal()*8*(1-time)
                var tip:=at+direction*(radius+24)
                canvas.draw_colored_polygon(PackedVector2Array([at+direction*radius-tangent,tip,at+direction*radius+tangent]),tint)
            if not reduced:canvas.draw_arc(at,24+time*100,0,TAU,10,Color(paper,1-time),4)
        "chase_path":
            if reduced:return
            var p: Array=effect.get("points",[])
            if p.size()!=4:return
            for i in 12:
                if i%3==int(time*3)%3:continue
                var points:=PackedVector2Array()
                for t in [float(i)/12.0,float(i+1)/12.0]:
                    var world: Vector2=p[0]*pow(1-t,3)+p[1]*3*pow(1-t,2)*t+p[2]*3*(1-t)*t*t+p[3]*t*t*t
                    points.append(session.project(world+Vector2(0,.9)))
                canvas.draw_line(points[0],points[1],tint,5.0 if time<.5 else 2.0)
        "echo":
            if reduced:return
            for bone in effect.get("bones",[]):
                var a: Vector2=session.camera.unproject_position(bone.a)*Vector2(1280,720)/session.get_viewport().get_visible_rect().size
                var b: Vector2=session.camera.unproject_position(bone.b)*Vector2(1280,720)/session.get_viewport().get_visible_rect().size
                var tangent: Vector2=(b-a).normalized().orthogonal()*bone.width*(80.0 if effect.get("rush",false) else 55.0)*(1.0-time*.5)
                var drift:=Vector2(-face*time*24,0)
                canvas.draw_colored_polygon(PackedVector2Array([a-tangent+drift,b-tangent+drift,b+tangent+drift,a+tangent+drift]),Color(tint,(1.0-time)*(.55 if effect.get("rush",false) else .30)))
        "ground_ring":
            if reduced:return
            var radius:=.3+time*2.0
            for i in 12:
                if i%3==1:continue
                var a:=i*TAU/12
                var b:=(i+.7)*TAU/12
                var points:=PackedVector2Array()
                for angle in [a,b]:
                    var world:=Vector3(effect.at.x+cos(angle)*radius,.06,session.FIGHT_Z+sin(angle)*radius*.5)
                    points.append(session.camera.unproject_position(world)*Vector2(1280,720)/session.get_viewport().get_visible_rect().size)
                canvas.draw_line(points[0],points[1],Color(tint,1-time),maxf(1,5*(1-time)))
        "surge_arc":
            var level: int=effect.get("tier",1)
            var radius: float=(48+level*14)*(0.55 if reduced else 1.0)*(1.0+time*.55)
            _crescent(canvas,at,radius,12*(1-time)+2,face,ink)
            _crescent(canvas,at,radius-4,10*(1-time)+2,face,tint)
            if not reduced:_crescent(canvas,at,radius-9,4*(1-time)+1,face,paper)
        "rally_core","air_counter_core":
            var level: int=effect.get("tier",1)
            var radius:=18.0+level*4
            canvas.draw_circle(at,radius,ink)
            _star(canvas,at,radius*(1.0 if reduced else 1.15),4,tint)
            canvas.draw_circle(at,5,paper)
        "swing","hit","release","clash","wall":
            var phase: float = 0.12 if effect.kind in ["hit","clash"] and effect.get("held",false) else time
            var shapes: Array[Dictionary] = impact_shapes.build("hit" if effect.kind=="clash" else ("release" if effect.kind=="wall" else effect.kind),effect.get("move","jab"),phase,tint,face,reduced,effect.get("character",0))
            var pixels_per_meter: float = (session.project(effect.at+Vector2(1,0))-at).length()
            var perspective_scale := clampf(pixels_per_meter/56.0,.45,1.35)*(1.28 if effect.get("rush",false) and effect.get("move","") in ["meteor","launcher","special","air_kick"] and not reduced else 1.0)
            for shape in shapes:
                var points: PackedVector2Array=shape.points.duplicate()
                for i in points.size(): points[i]=at+points[i]*perspective_scale
                canvas.draw_colored_polygon(points,shape.color)
        "grab_tell":
            var radius:=18.0+stage*6.0
            for side in [-1,1]:
                var center:=at+Vector2(side*12.0,0)
                canvas.draw_arc(center,radius,(-PI*.5 if side>0 else PI*.5),(PI*.5 if side>0 else PI*1.5),6,tint,3)
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
            var perfect:bool=effect.kind=="parry"
            var radius:float=(24.0 if not perfect else 34.0)*(1.0+minf(time*2,.5))*(.75 if reduced else 1.0)
            if perfect:
                for i in (3 if reduced else 6):
                    if time>.65 and i%2:continue
                    var direction:=Vector2.from_angle(i*TAU/6+.18)
                    var center:=at+direction*radius
                    var tangent:=direction.orthogonal()*(3.5 if time<.35 else 1.5)
                    canvas.draw_colored_polygon(PackedVector2Array([center-tangent,center+direction*(17*(1-time)+2),center+tangent,center-direction*3]),paper if time<.20 else tint)
                if time<.35:canvas.draw_circle(at,4,paper)
            else:
                for i in 3:
                    var angle:float=-1.0+i*.67
                    var points:=PackedVector2Array()
                    for a in [angle,angle+.48]:points.append(at+Vector2(cos(a)*face,sin(a))*radius)
                    canvas.draw_line(points[0],points[1],ink,6 if not reduced else 3)
                    canvas.draw_line(points[0],points[1],tint,3 if not reduced else 2)
                if time<.35:canvas.draw_line(at+Vector2(-4,-9),at+Vector2(5,9),paper,2)
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
