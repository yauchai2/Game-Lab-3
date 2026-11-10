extends RefCounted
## Orbit with explicit two-fighter projection checks, including roll and HUD margins.
var last_iterations:=0
var last_weight:=0.0
func apply(camera:Camera3D,session:Node3D) -> void:
    var director:RefCounted=session.neon
    var weight:float=director.camera_weight()
    last_weight=weight;last_iterations=0
    if weight<=0.0:return
    var a:Dictionary=session.sim.fighters[0]
    var b:Dictionary=session.sim.fighters[1]
    var normal_position:=camera.position
    var normal_rotation:=camera.quaternion
    var normal_fov:=camera.fov
    var center:=Vector3((a.x+b.x)*.5,(minf(a.y,b.y)+maxf(a.y,b.y)+2.4)*.5,session.FIGHT_Z)
    var progress:float=director.age/director.duration
    var direction:=1.0 if director.owner==0 else -1.0
    var orbit:float=direction*lerpf(-.28,.40,smoothstep(0.0,1.0,progress))
    if director.mode=="RELEASE":orbit=direction*lerpf(.28,-.36,progress)
    var desired_fov:=36.0 if director.mode=="CHARGE" else 41.0
    var distance:=maxf(5.2,camera.position.distance_to(center)*.76)
    for iteration in 12:
        camera.position=center+Vector3(sin(orbit)*distance,.30,cos(orbit)*distance)
        camera.look_at(center)
        camera.rotation.z=director.camera_roll()
        camera.fov=desired_fov
        last_iterations=iteration+1
        if fits(camera,session):break
        distance*=1.12
    var target_position:=camera.position
    var target_rotation:=camera.quaternion
    camera.position=normal_position.lerp(target_position,weight)
    camera.quaternion=normal_rotation.slerp(target_rotation,weight)
    camera.fov=lerpf(normal_fov,desired_fov,weight)
    # Blending between two safe cameras is not itself guaranteed to remain safe.
    for iteration in 8:
        if fits(camera,session):break
        camera.position=center+(camera.position-center)*1.10
func fits(camera:Camera3D,session:Node3D) -> bool:
    var viewport_size:Vector2=session.get_viewport().get_visible_rect().size
    for f in session.sim.fighters:
        for x in [-.55,.55]:
            for y in [0.0,2.35]:
                var point:=Vector3(f.x+x,f.y+y,session.FIGHT_Z)
                if camera.is_position_behind(point):return false
                var screen:Vector2=camera.unproject_position(point)/viewport_size
                if screen.x<.04 or screen.x>.96 or screen.y<.18 or screen.y>.84:return false
    return true
