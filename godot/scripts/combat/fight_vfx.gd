extends RefCounted
## Original hard-edged, staged canvas effects projected from the shared fight world.
var impact_shapes = preload("res://scripts/combat/impact_shapes.gd").new()
var sprites = preload("res://scripts/combat/sprite_fx.gd").new()
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
            sprites.converge(canvas,at,time,tint,95.0*(1-time)+18,4 if reduced else 8)
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
            if not reduced:sprites.hit_spark(canvas,at+direction*(40+time*120),time,paper,direction.angle(),150.0)
        "meteor_streak":
            if reduced:return
            for side in [-1,1]:
                var base:=at+Vector2(side*22,-155*(1-time))
                canvas.draw_colored_polygon(PackedVector2Array([base,at+Vector2(side*14,72*time),base+Vector2(side*18,32)]),paper if side>0 else tint)
        "slam_crater":
            sprites.ground_shock(canvas,at,time,Color(.80,.76,.88),4 if reduced else 6,150.0)
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
            sprites.ground_shock(canvas,at,time,Color(tint.lerp(Color(.85,.82,.92),.55)),5,(.3+2.0)*58.0)
        "surge_arc":
            var level: int=effect.get("tier",1)
            var radius: float=(48+level*14)*(0.55 if reduced else 1.0)*(1.0+time*.55)
            _crescent(canvas,at,radius,12*(1-time)+2,face,ink)
            _crescent(canvas,at,radius-4,10*(1-time)+2,face,tint)
            if not reduced:_crescent(canvas,at,radius-9,4*(1-time)+1,face,paper)
        "rally_core","air_counter_core":
            var level: int=effect.get("tier",1)
            sprites.converge(canvas,at,time,tint,(30.0+level*6.0)*(1.0-time*.4),4 if reduced else 7)
            sprites.hit_spark(canvas,at,.15+.3*fposmod(time*2.0,1.0),paper,-0.8,56.0+level*10.0)
        "swing":
            var move: String = effect.get("move","jab")
            var profile: Vector3 = impact_shapes.PROFILES.get(move,impact_shapes.PROFILES.jab)
            sprites.slash(canvas,at,time,tint,face,profile.z>.6)
            if move in ["special","overdrive","meteor","air_finisher"] and not reduced:sprites.slash(canvas,at+Vector2(0,-24),minf(1.0,time+.2),Color("fff8dc"),face,profile.z>.6)
        "grab_tell":
            sprites.converge(canvas,at,stage,tint,26.0*(1.0-stage*.5),3 if reduced else 5)
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
            sprites.converge(canvas,at,stage,tint,lerpf(80.0,22.0,stage),3 if reduced else 6)
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
                sprites.hit_spark(canvas,at,time,tint,-0.6,(120.0 if reduced else 190.0)*(1.0+time*.3))
            else:
                sprites.hit_spark(canvas,at,time,tint,PI if face<0 else 0.0,(120.0 if not reduced else 84.0)*(1.0+time*.3))
        "guard_break":
            sprites.hit_spark(canvas,at,time,Color("eaf078"),-0.35,300.0*(0.7 if reduced else 1.0))
            if not reduced:sprites.hit_spark(canvas,at+Vector2(face*18,6),minf(1.0,time+.12),paper,PI+0.35,170.0)
        _:
            var size := (150.0+stage*60.0)*(0.7+strength*0.55)
            sprites.hit_spark(canvas,at,time,tint,0.0,size*(0.7 if reduced else 1.0))

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
